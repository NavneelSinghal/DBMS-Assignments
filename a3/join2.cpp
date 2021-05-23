#include "constants.h"
#include "errors.h"
#include "file_manager.h"
#include <algorithm>
#include <cassert>
#include <climits>
#include <cstring>
#include <iostream>
#include <vector>

using namespace std;

/* #define NDEBUG */

/* A simple class which writes records to an output file,
 * This class keeps at most one page in the buffer all time
 */
template <typename T> class SimpleWriter {
  public:
    SimpleWriter(FileManager &fm, char *filename) {
        handler = fm.CreateFile(filename);
        page = handler.NewPage();
        max_per_page = PAGE_CONTENT_SIZE / sizeof(T);
        assert(PAGE_CONTENT_SIZE % sizeof(T) == 0);
        offset = 0;
    }

    void write(T record) {
        if (offset >= max_per_page) {
            // Page is full
            handler.MarkDirty(page.GetPageNum());
            handler.UnpinPage(page.GetPageNum());
            // handler.FlushPage(page.GetPageNum());
            page = handler.NewPage();
            offset = 0;
        }
        memcpy(page.GetData() + sizeof(T) * (offset++), &record, sizeof(T));
    }

    void fill(T record) {
        // fill the rest of the page with this record
        if (offset == 0) {
            // The entire page is empty so just dispose it
            handler.DisposePage(page.GetPageNum());
            return;
        }
        while (offset < max_per_page) {
            memcpy(page.GetData() + sizeof(T) * (offset++), &record, sizeof(T));
        }
    }

    void close(FileManager &fm) {
        // Flush all pages (closing file auto flushes)
        fm.CloseFile(handler);
    }

  private:
    FileHandler handler;
    PageHandler page;
    int offset, max_per_page;
};

/* Return record of type T stored in page content data at offset */
template <typename T> T record_at(char *data, int offset) {
    assert((offset + 1) * sizeof(T) <= PAGE_CONTENT_SIZE);
    T record;
    memcpy(&record, data + offset * sizeof(T), sizeof(T));
    return record;
}
void join2(FileHandler &input1, FileHandler &input2, SimpleWriter<int> &output);

int main(int argc, char **argv) {
    if (argc < 4) {
        std::cerr << "Usage : " << argv[0]
                  << " inputfile1 inputfile2 outputfilename" << std::endl;
        return -1;
    }

    FileManager fm;
    FileHandler input1 = fm.OpenFile(argv[1]); // May throw InvalidFileException
    FileHandler input2 = fm.OpenFile(argv[2]); // May throw InvalidFileException
    SimpleWriter<int> writer(fm, argv[3]);

    join2(input1, input2, writer);

    writer.fill(INT_MIN);
    writer.close(fm);

    fm.CloseFile(input1);
    fm.CloseFile(input2);
}

int bin_search(FileHandler &input2, int num, int right_last, int low) {
    /* Returns the page number of first page between [low, right_last] which has
     * at least one occurence of num.
     */
    PageHandler page;
    int lastpage = right_last;
    int max_per_page = PAGE_CONTENT_SIZE / sizeof(int);
    int lo = low - 1, hi = lastpage + 1;

    while (lo < hi - 1) {
        /* Invariant :
         *      Each page in [low -> lo] has no number >= num (Base case would
         *      need to be guranteed by caller)
         *      Each page in [hi -> lastpage] has at least one number >= num
         *      (Base case would need to be guranteed by caller)
         */
        int mid = (lo + hi) / 2;
        page = input2.PageAt(mid);
        assert(mid >= low && mid <= right_last);

        char *data = page.GetData();

        int firstnum = record_at<int>(data, 0),
            lastnum = record_at<int>(data, max_per_page - 1);
        if (mid == lastpage) {
            /* Last page is allowed to be not completely full */
            int i = max_per_page - 1;
            while (i > 0 && lastnum == INT_MIN) {
                lastnum = record_at<int>(data, --i);
            }
        }
        input2.UnpinPage(mid);

        if (lastnum >= num) {
            // This page has at least one number >= num
            hi = mid;
            if (firstnum < num) {
                // this is the page we are looking for, early stop
                break;
            }
        } else {
            lo = mid;
        }
    }
    return hi;
}

void join2(FileHandler &input1, FileHandler &input2,
           SimpleWriter<int> &output) {
    /* SimpleWriter will use 1 slot in buffer, that leaves BUFFER_SIZE-1 slots
     * input2 should use at most 1 slot in buffer, that leaves BUFFER_SIZE-2
     * slots.
     * input1 will use all the remaining slots
     */
    assert(BUFFER_SIZE > 2);

    int max_per_page = PAGE_CONTENT_SIZE / sizeof(int);

    int left_first = 0, left_last;
    int right_first = 0, right_last;
    try {
        PageHandler temp = input1.LastPage();
        left_last = temp.GetPageNum();
        input1.FlushPage(left_last);

        temp = input2.LastPage();
        right_last = temp.GetPageNum();
        input2.FlushPage(right_last);
    } catch (const InvalidPageException &e) {
        // Either input1 or input2 was empty
        // In either case join is meaningless
        return;
    }
    // cout<<left_last<<" "<<right_last<<endl;

    if (left_last == -1 or right_last == -1)
        return;

    std::vector<int> left;                          // Store ints from input1
    left.reserve(max_per_page * (BUFFER_SIZE - 2)); // only these many ints

    for (int left_curr = left_first; left_curr <= left_last;
         left_curr += BUFFER_SIZE - 2) {
        for (int i = 0; i < BUFFER_SIZE - 2; i++) {
            if (left_curr + i > left_last)
                break;
            char *data = input1.PageAt(left_curr + i).GetData();
            for (int i = 0; i < max_per_page; i++) {
                int num = record_at<int>(data, i);
                if (num == INT_MIN)
                    break;
                left.push_back(num);
            }
        }
        std::sort(left.begin(), left.end());
        // cout<<"Hey2 "<<left.size()<<endl;
        int size_arr = left.size();

        int prev_pagenum = right_first;
        for (int index = 0; index < size_arr;) {
            int val = left[index];
            index++;
            int count = 1;
            while (index < size_arr && val == left[index]) {
                count++;
                index++;
            }
            // cout<<val<<" "<<count<<endl;
            int page_num = bin_search(input2, val, right_last, prev_pagenum);
            if (page_num == right_last + 1)
                continue;

            for (; page_num <= right_last; page_num++) {
                PageHandler page = input2.PageAt(page_num);
                char *data = page.GetData();
                for (int j = 0; j < max_per_page; j++) {
                    int temp = record_at<int>(data, j);
                    if (temp < val)
                        continue;
                    if (temp == val) {
                        for (int k = 0; k < count; k++) {
                            output.write(val);
                        }
                    } else
                        goto stopreading;
                }
                input2.UnpinPage(page_num);
                continue;
            stopreading:
                input2.UnpinPage(page_num);
                break;
            }

            prev_pagenum = page_num;
        }

        /* Flush all pages from input 2 to make room in buffer */
        left.clear();
        for (int i = 0; i < BUFFER_SIZE - 2; i++) {
            if (left_curr + i > left_last)
                break;
            input1.UnpinPage(left_curr + i);
        }
    }
}
