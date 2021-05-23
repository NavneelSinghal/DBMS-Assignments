#include "errors.h"
#include "file_manager.h"
#include <cassert>
#include <climits>
#include <cstring>
#include <fstream>
#include <iostream>

int main(int argc, char **argv) {

    if (argc < 2) {
        std::cout << "Usage : " << argv[0] << " filename" << std::endl;
        return -1;
    }

    FileManager fm;
    FileHandler input = fm.OpenFile(argv[1]);
    PageHandler page = input.FirstPage();
    PageHandler last = input.LastPage();
    int max_per_page = PAGE_CONTENT_SIZE / sizeof(std::pair<int, int>);

    std::pair<int, int> content[max_per_page];

    while (page.GetPageNum() < last.GetPageNum()) {

        std::cout << "Page = " << page.GetPageNum() << std::endl;

        memcpy(content, page.GetData(), PAGE_CONTENT_SIZE);

        for (int i = 0; i < max_per_page; i++) {
            std::cout << content[i].first << " " << content[i].second
                      << std::endl;
        }

        input.FlushPage(page.GetPageNum());
        page = input.PageAt(page.GetPageNum() + 1);
        std::cout << std::endl;
    }

    memcpy(content, page.GetData(), PAGE_CONTENT_SIZE);

    for (int i = 0; i < max_per_page; i++) {
        std::cout << content[i].first << " " << content[i].second << std::endl;
    }

    fm.CloseFile(input);
}
