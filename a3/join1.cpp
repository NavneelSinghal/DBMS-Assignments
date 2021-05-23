#include "constants.h"
#include "errors.h"
#include "file_manager.h"
#include <algorithm>
#include <cassert>
#include <climits>
#include <cstring>
#include <iostream>
#include <vector>

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

void join1(FileHandler &input1, FileHandler &input2, SimpleWriter<int> &output);

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

    join1(input1, input2, writer);

    writer.fill(INT_MIN);
    writer.close(fm);

    fm.CloseFile(input1);
    fm.CloseFile(input2);
}

void join1(FileHandler &input1, FileHandler &input2,
           SimpleWriter<int> &output) {
    /* SimpleWriter will use 1 slot in buffer, that leaves BUFFER_SIZE-1 slots
     * input1 should use at most 1 slot in buffer, that leaves BUFFER_SIZE-2
     * slots.
     * input2 will use all the remaining slots
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

    std::vector<int> right;                          // Store ints from input2
    right.reserve(max_per_page * (BUFFER_SIZE - 2)); // only these many ints

    for (int right_curr = right_first; right_curr <= right_last;
         right_curr += BUFFER_SIZE - 2) {
        /* Read N-2 pages from input 2 */
        for (int i = 0; i < BUFFER_SIZE - 2; i++) {
            if (right_curr + i > right_last)
                break;
            char *data = input2.PageAt(right_curr + i).GetData();
            for (int i = 0; i < max_per_page; i++) {
                int num = record_at<int>(data, i);
                if (num == INT_MIN)
                    break;
                right.push_back(num);
            }
        }
        std::sort(right.begin(), right.end());

        /* Read page from input1 one by one and perform join */
        for (int left_curr = left_first; left_curr <= left_last; left_curr++) {
            char *data = input1.PageAt(left_curr).GetData();
            for (int i = 0; i < max_per_page; i++) {
                int num = record_at<int>(data, i);
                if (num == INT_MIN)
                    break;
                for (auto it =
                         std::lower_bound(right.begin(), right.end(), num);
                     it != right.end(); it++) {
                    int num2 = *it;
                    if (num2 > num) {
                        break;
                    }
                    output.write(num);
                }
            }
            input1.UnpinPage(left_curr);
        }

        /* Flush all pages from input 2 to make room in buffer */
        right.clear();
        for (int i = 0; i < BUFFER_SIZE - 2; i++) {
            if (right_curr + i > right_last)
                break;
            input2.UnpinPage(right_curr + i);
        }
    }
}
