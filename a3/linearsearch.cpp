#include "errors.h"
#include "file_manager.h"
#include <cassert>
#include <climits>
#include <cstring>
#include <fstream>
#include <iostream>

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
            handler.FlushPage(page.GetPageNum()); // Write to disk and also
                                                  // force evict from buffer
            page = handler.NewPage();
            offset = 0;
        }
        memcpy(page.GetData() + sizeof(T) * (offset++), &record, sizeof(T));
    }

    void fill(T record) {
        // fill the rest of the page with this record
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

void linearsearch(FileHandler &, SimpleWriter<int> &, int);

int main(int argc, char **argv) {
    if (argc < 4) {
        std::cerr << "Usage : " << argv[0]
                  << " inputfilename queryfilename outputfilename" << std::endl;
        return -1;
    }

    std::ifstream query(argv[2]);
    if (!query.is_open()) {
        std::cerr << "Query file could not be opened!" << std::endl;
        return -1;
    }

    FileManager fm;
    FileHandler input = fm.OpenFile(argv[1]); // May throw InvalidFileException
    SimpleWriter<int> writer(fm, argv[3]);

    std::string start_marker;
    int querynum;
    while (query >> start_marker >> querynum) {
        assert(start_marker == "SEARCH");
        linearsearch(input, writer, querynum);
    }

    writer.fill(INT_MIN);
    writer.close(fm);

    fm.CloseFile(input);
}

void linearsearch(FileHandler &input, SimpleWriter<int> &output,
                  int num) {
    // At all times we will keep at most one input page in the buffer
    PageHandler page;
    int lastpage;
    int max_per_page = PAGE_CONTENT_SIZE / sizeof(int);
    try {
        page = input.LastPage();
        lastpage = page.GetPageNum();
        input.UnpinPage(lastpage);
    } catch (const InvalidPageException &e) {
        // Input file was empty
        output.write(-1);
        output.write(-1);
        return;
    }
    if (lastpage == -1) {
        output.write(-1);
        output.write(-1);
        return;
    }
    int cur_page = 0;
    for (int i = cur_page; i <= lastpage; i++) {
        page = input.PageAt(i);
        char *data = page.GetData();
        for (int j = 0; j < max_per_page; j++) {
            int temp = record_at<int>(data, j);
            if (temp == num && num != INT_MIN)
                {
                    output.write(i);
                    output.write(j);
                }
        }
        input.UnpinPage(i);
    }
    output.write(-1);
    output.write(-1);
    return;
}
