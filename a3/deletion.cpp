#include "errors.h"
#include "file_manager.h"
#include <cassert>
#include <climits>
#include <cstring>
#include <fstream>
#include <iostream>

/* #define NDEBUG */

/* Return record of type T stored in page content data at offset */
template <typename T> T record_at(char *data, int offset) {
    assert((offset + 1) * sizeof(T) <= PAGE_CONTENT_SIZE);
    T record;
    memcpy(&record, data + offset * sizeof(T), sizeof(T));
    return record;
}

void deletefromfile(FileHandler &, int);

void debugfile(std::string f) {
#define DEBUG 0
#if DEBUG
    system(("./printints " + f).c_str());
#endif
#undef DEBUG
}

int main(int argc, char **argv) {
    if (argc < 3) {
        std::cerr << "Usage : " << argv[0]
                  << " sortedinputfilename queryfilename" << std::endl;
        return -1;
    }

    std::ifstream query(argv[2]);
    if (!query.is_open()) {
        std::cerr << "Query file could not be opened!" << std::endl;
        return -1;
    }

    FileManager fm;
    FileHandler input = fm.OpenFile(argv[1]); // May throw InvalidFileException

    std::string start_marker;
    int querynum;
    while (query >> start_marker >> querynum) {
        assert(start_marker == "DELETE");
        // std::cout << "deleting " << querynum << std::endl;
        debugfile(std::string(argv[1]));
        deletefromfile(input, querynum);
    }

    debugfile(std::string(argv[1]));

    fm.CloseFile(input);
}

void deletefromfile(FileHandler &input, int num) {
    if (num == INT_MIN)
        return;
    PageHandler page;
    int lastpage;
    const int MAX_PER_PAGE = PAGE_CONTENT_SIZE / sizeof(int);
    try {
        page = input.LastPage();
        lastpage = page.GetPageNum();
        input.UnpinPage(lastpage);
    } catch (const InvalidPageException &e) {
        return;
    }

    if (lastpage == -1) {
        return;
    }

    /*
     * binary search for the first position of the number, if it exists
     */

    int lo = -1, hi = lastpage + 1;

    while (lo < hi - 1) {
        /* Invariant :
         *      Each page in [0 -> lo] has no number >= num
         *      Each page in [hi -> lastpage] has at least one number >= num
         */
        int mid = (lo + hi) / 2;
        page = input.PageAt(mid);
        assert(mid >= 0 && mid <= lastpage);

        char *data = page.GetData();

        int firstnum = record_at<int>(data, 0),
            lastnum = record_at<int>(data, MAX_PER_PAGE - 1);
        if (mid == lastpage) {
            /* Last page is allowed to be not completely full */
            int i = MAX_PER_PAGE - 1;
            while (i > 0 && lastnum == INT_MIN) {
                lastnum = record_at<int>(data, --i);
            }
        }
        input.UnpinPage(mid);

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

    if (hi == lastpage + 1) {
        // all numbers in input are smaller than num
        return;
    }
    // page hi has at least number >= num
    // the first occurrence (if exists) is on this page
    // format for pair: {page, offset}
    std::pair<int, int> first_occurrence = {-1, -1};
    std::pair<int, int> last_occurrence = {-1, -1};
    for (int i = hi; i <= lastpage; i++) {
        page = input.PageAt(i);
        char *data = page.GetData();
        for (int j = 0; j < MAX_PER_PAGE; j++) {
            int temp = record_at<int>(data, j);
            if (temp < num)
                continue;
            if (temp == num) {
                if (first_occurrence.first == -1)
                    first_occurrence = {i, j};
                last_occurrence = {i, j};
            } else
                goto stopreading;
        }
        input.UnpinPage(i);
        continue;
    stopreading:
        input.UnpinPage(i);
        break;
    }

    // now it is guaranteed that (if there is indeed an occurrence):
    //  1. the first occurrence has position coordinates in first_occurrence
    //  2. the last occurrence has position coordinates in last_occurrence

    if (first_occurrence.first == -1) {
        return;
    }

    assert(first_occurrence.first != -1);
    assert(first_occurrence.second != -1);
    assert(last_occurrence.first != -1);
    assert(last_occurrence.second != -1);

    // find location of the position to start replacing stuff from
    // this is the location just after the last occurrence

    std::pair<int, int> start_reading = last_occurrence;
    start_reading.second++;
    if (start_reading.second == MAX_PER_PAGE) {
        start_reading.second = 0;
        start_reading.first++;
    }

    if (start_reading.first == lastpage + 1) {
        // this case is equivalent to having the last page filled up to the
        // brim with this element
        page = input.PageAt(first_occurrence.first);
        // first subcase: we have to remove everything including this page,
        // so we prepare for deletion by reducing the lower bound of the
        // pages to be deleted by 1
        if (first_occurrence.second == 0)
            first_occurrence.first--;
        else {
            // we don't need to delete this page, so we fill the part of
            // this page occupied by the element to be deleted by INT_MIN
            char *data = page.GetData();
            while (first_occurrence.second < MAX_PER_PAGE) {
                // std::cerr << "deleting" << std::endl;
                int record = INT_MIN;
                memcpy(data + sizeof(int) * (first_occurrence.second++),
                       &record, sizeof(int));
            }
            // mark it dirty so that written stuff is actually written back
            // to the file
            input.MarkDirty(page.GetPageNum());
        }

        // flush the last page anyway
        input.UnpinPage(page.GetPageNum());

        // dispose all pages with indices in
        // (first_occurrence.first, lastpage]
        while (lastpage > first_occurrence.first) {
            input.DisposePage(lastpage);
            lastpage--;
        }

        // flush all pages
        input.FlushPages();

        return;
        // Summary:
        // this handles the case when the file is packed to the end
        // with this number
        // just delete after the end of the page and fill the
        // remaining part of the current page with INT_MIN
    }

    // start replacing things

    // we are now guaranteed that the part of the file whose stuff needs to
    // be copied is non-empty
    std::pair<int, int> right_ptr = start_reading;
    std::pair<int, int> left_ptr = first_occurrence;

    // Note: we shall handle the case of both being on the same page by not
    // unpinning the page if it is the same page as the input
    int prev_write_page = -1;
    int prev_read_page = -1;

    PageHandler write_page, read_page;

    while (true) {
        // to terminate, we only need to check if the current page is beyond
        // the last page or has INT_MIN on the current location

        // Invariant: at this point, we can have the following scenarios:
        //
        // 1. this is the first iteration, and write_page, read_page are not
        // initialized, and prev_write_page, prev_read_page are both -1
        //
        // 2. both are in fact initialized, and the write_page is dirty and
        // pinned, and the read page is pinned and not dirty, and the next
        // location to read data from is at right_ptr and the next location
        // to copy data from is at left_ptr

        if (prev_write_page < left_ptr.first) {
            if (prev_write_page != -1) {
                assert(write_page.GetPageNum() == prev_write_page);
                input.UnpinPage(write_page.GetPageNum());
            }
            prev_write_page = left_ptr.first;
            write_page = input.PageAt(prev_write_page);
            input.MarkDirty(prev_write_page);
        }

        if (prev_read_page < right_ptr.first) {
            if (prev_read_page != -1) {
                assert(read_page.GetPageNum() == prev_read_page);
                // avoid unpinning the page where we write
                // TODO: test - already tested with small frequencies
                if (read_page.GetPageNum() != write_page.GetPageNum())
                    input.UnpinPage(read_page.GetPageNum());
            }
            prev_read_page = right_ptr.first;
            read_page = input.PageAt(prev_read_page);
        }

        // read number from the reading position - this is always valid
        // since we always have something to read in this loop
        int number = record_at<int>(read_page.GetData(), right_ptr.second);

        // when do we exactly terminate?
        // look at the position of the right pointer.
        //
        // if we reach INT_MIN: instead of incrementing the left_ptr after
        // copying the INT_MIN here, we can just stop. TODO: test - already
        // tested in the given test
        //
        // if we reach the last location in the file: we still need to copy
        // this element to the position, and after that we can just do the
        // usual stuff. TODO: test - done

        if (number == INT_MIN) {
            break;
        }

        memcpy(write_page.GetData() + sizeof(int) * (left_ptr.second++),
               &number, sizeof(int));
        if (left_ptr.second == MAX_PER_PAGE) {
            left_ptr.second = 0;
            left_ptr.first++;
        }

        right_ptr.second++;
        if (right_ptr.second == MAX_PER_PAGE) {
            right_ptr.first++;
            right_ptr.second = 0;
        }

        if (right_ptr.first > lastpage) {
            break;
        }
    }

    // since the loop has ended at this point, it implies that the right
    // pointer is now beyond the end of non-garbage input. so we can deduce
    // that everything from and including left_ptr needs to be cleared out.
    // if it is the first in its page, we just clear it out normally. else
    // we fill the rest of the page with INT_MIN and clear out the remaining
    // pages by disposing them off.

    if (left_ptr.second == 0)
        left_ptr.first--; // prepare the current for deletion
    else {
        int record = INT_MIN;
        while (left_ptr.second < MAX_PER_PAGE) {
            memcpy(write_page.GetData() + sizeof(int) * (left_ptr.second++),
                   &record, sizeof(int));
        }
    }

    input.UnpinPage(write_page.GetPageNum());
    input.UnpinPage(read_page.GetPageNum());

    while (lastpage > left_ptr.first) {
        assert(input.DisposePage(lastpage));
        lastpage--;
    }

    input.FlushPages();

    // Summary:
    // when the right pointer reaches INT_MIN or goes beyond the end of
    // the file, fill everything from left pointer + 1 to the end of the
    // page with INT_MIN and dispose off the other pages
}
