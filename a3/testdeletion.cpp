#include "constants.h"
#include "errors.h"
#include "file_manager.h"
#include <algorithm>
#include <cassert>
#include <climits>
#include <cstring>
#include <fstream>
#include <functional>
#include <iostream>
#include <map>
#include <random>
#include <set>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

/* #define NDEBUG */

/* A simple class which writes records to an output file,
 * This class keeps at most one page in the buffer all time
 */
template <typename T> class SimpleWriter {
  public:
    SimpleWriter(FileManager &fm, const char *filename) {
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

bool empty_file(FileManager &);
bool empty_file2(FileManager &);
bool full_page(FileManager &);
bool random_small(FileManager &);
bool corner(FileManager &);
bool random_medium(FileManager &);

std::random_device rd;
std::default_random_engine rng(rd());

int main() {
    FileManager fm;

    std::vector<pair<std::string, std::function<bool(FileManager &)>>> tests = {
        {"Empty File", empty_file},
        {"Empty File 2", empty_file2},
        {"Full Page", full_page},
        {"Small random", random_small},
        {"Corner", corner},
        {"Medium random", random_medium}};

    for (auto &test : tests) {
        cout << "Running test : " << test.first << endl;
        bool result = test.second(fm);
        if (!result) {
            cout << "Test FAILED" << endl;
            return -1;
        }
    }
    cout << "ALL TESTS PASSED" << endl;
}

bool empty_file(FileManager &fm) {
    fm.DestroyFile("search_input");
    fm.DestroyFile("search_query");
    fm.DestroyFile("output");
    FileHandler input1 = fm.CreateFile("search_input");
    fm.CloseFile(input1);

    std::ofstream query("search_query");
    query << "DELETE " << INT_MAX << endl;
    query << "DELETE " << INT_MIN << endl;
    query.close();

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./deletion", "./deletion", "search_input", "search_query",
                   (char *)NULL) == -1) {
            perror("exec error");
            exit(-1);
        }
    } else {
        int retval;
        waitpid(pid, &retval, 0);
        if (retval != 0) {
            /* Not a clean exit, some error occured in the program */
            return false;
        }

        // Clean exit, so now check output
        FileHandler output = fm.OpenFile("search_input");

        try {
            PageHandler temp = output.LastPage();
            if (temp.GetPageNum() != -1) {
                cout << "Output should be empty" << endl;
                return false;
            }
            output.UnpinPage(temp.GetPageNum());
            return true;
        } catch (InvalidPageException &e) {
            return true;
        }
    }
    return false;
}

bool empty_file2(FileManager &fm) {
    fm.DestroyFile("search_input");
    fm.DestroyFile("search_query");
    fm.DestroyFile("output");
    SimpleWriter<int> input1(fm, "search_input");
    input1.write(0);
    input1.fill(INT_MIN);
    input1.close(fm);

    std::ofstream query("search_query");
    query << "DELETE " << INT_MAX << endl;
    query << "DELETE " << 0 << endl;
    query.close();

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./deletion", "./deletion", "search_input", "search_query",
                   (char *)NULL) == -1) {
            perror("exec error");
            exit(-1);
        }
    } else {
        int retval;
        waitpid(pid, &retval, 0);
        if (retval != 0) {
            /* Not a clean exit, some error occured in the program */
            return false;
        }

        // Clean exit, so now check output
        FileHandler output = fm.OpenFile("search_input");

        try {
            PageHandler temp = output.LastPage();
            if (temp.GetPageNum() != -1) {
                cout << "Output should be empty" << endl;
                return false;
            }
            output.UnpinPage(temp.GetPageNum());
            return true;
        } catch (InvalidPageException &e) {
            return true;
        }
    }
    return true;
}

bool full_page(FileManager &fm) {
    fm.DestroyFile("search_input");
    fm.DestroyFile("search_query");
    fm.DestroyFile("output");
    SimpleWriter<int> input1(fm, "search_input");
    std::ofstream query("search_query");
    std::vector<int> nums, query_nums;
    for (int i = 0; i < PAGE_CONTENT_SIZE / sizeof(int); i++) {
        nums.push_back(0);
    }
    std::sort(nums.begin(), nums.end());
    for (int i = 0; i < PAGE_CONTENT_SIZE / sizeof(int); i++) {
        input1.write(0);
        query_nums.push_back(0);
        query << "DELETE " << 0 << "\n";
    }
    input1.fill(INT_MIN);
    input1.close(fm);
    query.close();
    cout << "Generated input" << endl;

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./deletion", "./deletion", "search_input", "search_query",
                   (char *)NULL) == -1) {
            perror("exec error");
            exit(-1);
        }
    } else {
        int retval;
        waitpid(pid, &retval, 0);
        if (retval != 0) {
            /* Not a clean exit, some error occured in the program */
            return false;
        }

        // Clean exit, so now check output
        FileHandler output = fm.OpenFile("search_input");

        int max_per_page = PAGE_CONTENT_SIZE / sizeof(pair<int, int>);
        int max_int_per_page = PAGE_CONTENT_SIZE / sizeof(int);
        try {
            output.FirstPage().GetData();
            fm.CloseFile(output);
            return false;
        } catch (InvalidPageException &e) {
            return true;
        }
    }
    return false;
}

bool random_small(FileManager &fm) {
    fm.DestroyFile("delete_input");
    fm.DestroyFile("delete_query");
    SimpleWriter<int> input1(fm, "delete_input");
    std::ofstream query("delete_query");
    std::multiset<int> nums;

    int size = 1000;
    int querysize = 100;

    std::uniform_int_distribution<int> dist(0, 100);
    for (int i = 0; i < size; i++) {
        int num = dist(rng);
        nums.insert(num);
    }
    for (auto it = nums.begin(); it != nums.end(); it++) {
        input1.write(*it);
    }
    for (int i = 0; i < querysize; i++) {
        int num = dist(rng);
        query << "DELETE " << num << "\n";
        nums.erase(num);
    }
    query << "DELETE " << INT_MAX << "\n";
    query << "DELETE " << INT_MIN << "\n";
    input1.fill(INT_MIN);
    input1.close(fm);
    query.close();
    cout << "Generated input" << endl;

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./deletion", "./deletion", "delete_input", "delete_query",
                   (char *)NULL) == -1) {
            perror("exec error");
            exit(-1);
        }
    } else {
        int retval;
        waitpid(pid, &retval, 0);
        if (retval != 0) {
            /* Not a clean exit, some error occured in the program */
            return false;
        }

        // Clean exit, so now check output
        FileHandler output = fm.OpenFile("delete_input");

        int max_per_page = PAGE_CONTENT_SIZE / sizeof(int);
        try {
            int page = -1, offset = max_per_page;
            char *data;
            for (auto it = nums.begin(); it != nums.end(); it++) {
                if (offset == max_per_page) {
                    output.UnpinPage(page);
                    page++;
                    offset = 0;
                    data = output.PageAt(page).GetData();
                }
                int num = record_at<int>(data, offset++);
                if (num != *it) {
                    cout << "Incorrect output, expected to see " << *it
                         << " found " << num << endl;
                    return false;
                }
            }
            // Rest of the ints should be INT_MIN
            while (offset < max_per_page) {
                int num = record_at<int>(data, offset++);
                if (num != INT_MIN) {
                    cout << "File tail should be INT_MIN" << endl;
                    return false;
                }
            }
            output.UnpinPage(page);
            // There should be no futher page
            try {
                PageHandler temp = output.PageAt(page + 1);
                if (temp.GetPageNum() != -1) {
                    cout << "Extra pages found in file " << endl;
                    return false;
                }
                output.UnpinPage(temp.GetPageNum());
            } catch (InvalidPageException &e) {
            }
            fm.CloseFile(output);
            return true;
        } catch (InvalidPageException &e) {
            cout << "Ran out of pages before reading output fully!" << endl;
            return false;
        }
    }
    return false;
}

bool corner(FileManager &fm) {
    fm.DestroyFile("search_input");
    fm.DestroyFile("search_query");
    fm.DestroyFile("output");
    SimpleWriter<int> input1(fm, "search_input");
    std::ofstream query("search_query");
    std::multiset<int> nums;

    for (int i = 0; i < 3; ++i) {
        input1.write(2);
        nums.insert(2);
    }
    for (int i = 0; i < 5; ++i) {
        input1.write(3);
        nums.insert(3);
    }
    for (int i = 0; i < 4; ++i) {
        input1.write(4);
        nums.insert(4);
    }
    query << "DELETE " << 3 << "\n";
    nums.erase(3);
    input1.fill(INT_MIN);
    input1.close(fm);
    query.close();
    cout << "Generated input" << endl;

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./deletion", "./deletion", "search_input", "search_query",
                   (char *)NULL) == -1) {
            perror("exec error");
            exit(-1);
        }
    } else {
        int retval;
        waitpid(pid, &retval, 0);
        if (retval != 0) {
            /* Not a clean exit, some error occured in the program */
            return false;
        }

        // Clean exit, so now check output
        FileHandler output = fm.OpenFile("search_input");

        int max_per_page = PAGE_CONTENT_SIZE / sizeof(int);
        try {
            int page = -1, offset = max_per_page;
            char *data;
            for (auto it = nums.begin(); it != nums.end(); it++) {
                if (offset == max_per_page) {
                    output.UnpinPage(page);
                    page++;
                    offset = 0;
                    data = output.PageAt(page).GetData();
                }
                int num = record_at<int>(data, offset++);
                if (num != *it) {
                    cout << "Incorrect output, expected to see " << *it
                         << " found " << num << endl;
                    return false;
                }
            }
            // Rest of the ints should be INT_MIN
            while (offset < max_per_page) {
                int num = record_at<int>(data, offset++);
                if (num != INT_MIN) {
                    cout << "File tail should be INT_MIN" << endl;
                    return false;
                }
            }
            output.UnpinPage(page);
            // There should be no futher page
            try {
                PageHandler temp = output.PageAt(page + 1);
                if (temp.GetPageNum() != -1) {
                    cout << "Extra pages found in file " << endl;
                    return false;
                }
                output.UnpinPage(temp.GetPageNum());
            } catch (InvalidPageException &e) {
            }
            fm.CloseFile(output);
            return true;
        } catch (InvalidPageException &e) {
            cout << "Ran out of pages before reading output fully!" << endl;
            return false;
        }
    }
    return false;
}

bool random_medium(FileManager &fm) {
    fm.DestroyFile("delete_input");
    fm.DestroyFile("delete_query");
    SimpleWriter<int> input1(fm, "delete_input");
    std::ofstream query("delete_query");
    std::multiset<int> nums;

    int size = 100000;
    int querysize = 10;

    std::uniform_int_distribution<int> dist(-10, 10);
    for (int i = 0; i < size; i++) {
        int num = dist(rng);
        nums.insert(num);
    }
    for (auto it = nums.begin(); it != nums.end(); it++) {
        input1.write(*it);
    }
    for (int i = 0; i < querysize; i++) {
        int num = dist(rng);
        query << "DELETE " << num << "\n";
        nums.erase(num);
    }
    query << "DELETE " << INT_MAX << "\n";
    query << "DELETE " << INT_MIN << "\n";
    input1.fill(INT_MIN);
    input1.close(fm);
    query.close();
    cout << "Generated input" << endl;

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./deletion", "./deletion", "delete_input", "delete_query",
                   (char *)NULL) == -1) {
            perror("exec error");
            exit(-1);
        }
    } else {
        int retval;
        waitpid(pid, &retval, 0);
        if (retval != 0) {
            /* Not a clean exit, some error occured in the program */
            return false;
        }

        // Clean exit, so now check output
        FileHandler output = fm.OpenFile("delete_input");

        int max_per_page = PAGE_CONTENT_SIZE / sizeof(int);
        try {
            int page = -1, offset = max_per_page;
            char *data;
            for (auto it = nums.begin(); it != nums.end(); it++) {
                if (offset == max_per_page) {
                    output.UnpinPage(page);
                    page++;
                    offset = 0;
                    data = output.PageAt(page).GetData();
                }
                int num = record_at<int>(data, offset++);
                if (num != *it) {
                    cout << "Incorrect output, expected to see " << *it
                         << " found " << num << endl;
                    return false;
                }
            }
            // Rest of the ints should be INT_MIN
            while (offset < max_per_page) {
                int num = record_at<int>(data, offset++);
                if (num != INT_MIN) {
                    cout << "File tail should be INT_MIN" << endl;
                    return false;
                }
            }
            output.UnpinPage(page);
            // There should be no futher page
            try {
                PageHandler temp = output.PageAt(page + 1);
                if (temp.GetPageNum() != -1) {
                    cout << "Extra pages found in file " << endl;
                    return false;
                }
                output.UnpinPage(temp.GetPageNum());
            } catch (InvalidPageException &e) {
            }
            fm.CloseFile(output);
            return true;
        } catch (InvalidPageException &e) {
            cout << "Ran out of pages before reading output fully!" << endl;
            return false;
        }
    }
    return false;
}

