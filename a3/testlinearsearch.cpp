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
bool random_large(FileManager &);

std::random_device rd;
std::default_random_engine rng(rd());

int main() {
    FileManager fm;

    std::vector<pair<std::string, std::function<bool(FileManager &)>>> tests = {
        {"Empty File", empty_file},
        {"Empty File 2", empty_file2},
        {"Full Page", full_page},
        {"Small random", random_small},
        {"Large random", random_large}
    };

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
    query << "SEARCH " << INT_MAX << endl;
    query << "SEARCH " << INT_MIN << endl;
    query.close();

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./linearsearch", "./linearsearch", "search_input",
                   "search_query", "output", (char *)NULL) == -1) {
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
        FileHandler output = fm.OpenFile("output");

        int max_per_page = PAGE_CONTENT_SIZE / sizeof(int);
        try {
            PageHandler temp = output.LastPage();
            output.UnpinPage(temp.GetPageNum());
            // if (temp.GetPageNum() != 0) {
            //     cout << "Output should contain only 1 page" << endl;
            //     return false;
            // }
            // if (record_at<pair<int, int>>(temp.GetData(), 0) !=
            //     make_pair(-1, -1)) {
            //     cout << "Query for INT_MAX wrong" << endl;
            //     return false;
            // }
            // if (record_at<pair<int, int>>(temp.GetData(), 1) !=
            //     make_pair(-1, -1)) {
            //     cout << "Query for INT_MIN wrong" << endl;
            //     return false;
            // }
            // for (int i = 4; i < max_per_page; i++) {
            //     if (record_at<int>(temp.GetData(), i) != INT_MIN) {
            //         cout << "Page should be all INT_MIN" << endl;
            //         return false;
            //     }
            // }
            output.FlushPage(temp.GetPageNum());
        } catch (InvalidPageException &e) {
            cout << "No pages found in output!" << endl;
            return false;
        }
        return true;
    }
    return true;
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
    query << "SEARCH " << INT_MAX << endl;
    query << "SEARCH " << INT_MIN << endl;
    query.close();
    // cout<<"YOYO"<<endl;

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./linearsearch", "./linearsearch", "search_input",
                   "search_query", "output", (char *)NULL) == -1) {
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
        FileHandler output = fm.OpenFile("output");

        int max_per_page = PAGE_CONTENT_SIZE / sizeof(int);
        try {
            PageHandler temp = output.LastPage();
            output.UnpinPage(temp.GetPageNum());
            // cout<<temp.GetPageNum()<<endl;
            // if (temp.GetPageNum() != 0) {
            //     cout << "Output should contain only 1 page" << endl;
            //     return false;
            // }
            // if (record_at<pair<int, int>>(temp.GetData(), 0) !=
            //     make_pair(-1, -1)) {
            //     cout << "Query for INT_MAX wrong" << endl;
            //     return false;
            // }
            // if (record_at<pair<int, int>>(temp.GetData(), 1) !=
            //     make_pair(-1, -1)) {
            //     cout << "Query for INT_MIN wrong" << endl;
            //     return false;
            // }
            // for (int i = 4; i < max_per_page; i++) {
            //     if (record_at<int>(temp.GetData(), i) != INT_MIN) {
            //         cout << "Page should be all INT_MIN" << endl;
            //         return false;
            //     }
            // }
            output.FlushPage(temp.GetPageNum());
        } catch (InvalidPageException &e) {
            cout << "No pages found in output!" << endl;
            return false;
        }
        return true;
    }
    return true;
}

bool full_page(FileManager &fm) {
    fm.DestroyFile("search_input");
    fm.DestroyFile("search_query");
    fm.DestroyFile("output");
    SimpleWriter<int> input1(fm, "search_input");
    std::ofstream query("search_query");
    std::map<int, int> input_nums;
    std::vector<int> nums, query_nums;
    for (int i = 0; i < PAGE_CONTENT_SIZE / sizeof(int); i++) {
        nums.push_back(0);
    }
    // std::sort(nums.begin(), nums.end());
    for (int i = 0; i < PAGE_CONTENT_SIZE / sizeof(int); i++) {
        input_nums[0]++;
        input1.write(0);
        query_nums.push_back(0);
        query << "SEARCH " << 0 << "\n";
    }
    query_nums.push_back(INT_MAX);
    query << "SEARCH " << INT_MAX << "\n";
    query_nums.push_back(INT_MIN);
    query << "SEARCH " << INT_MIN << "\n";
    input1.fill(INT_MIN);
    input1.close(fm);
    query.close();
    cout << "Generated input" << endl;

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./linearsearch", "./linearsearch", "search_input",
                   "search_query", "output", (char *)NULL) == -1) {
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
        FileHandler output = fm.OpenFile("output");

        int max_per_page = PAGE_CONTENT_SIZE / sizeof(pair<int, int>);
        int max_int_per_page = PAGE_CONTENT_SIZE / sizeof(int);
        try {
            int page = 0, offset = 0;
            char *data = output.FirstPage().GetData();
            pair<int, int> end_pair({-1, -1});
            for (int query : query_nums) {
                // cout<<"query"<<" "<<query<<endl;
                int cnt = 0;
                while (true) {
                    if (offset >= max_per_page) {
                        output.UnpinPage(page);
                        data = output.PageAt(++page).GetData();
                        offset = 0;
                    }
                    pair<int, int> record =
                        record_at<pair<int, int>>(data, offset++);
                    if (record == end_pair) {
                        break;
                    }
                    int index = record.first * max_int_per_page + record.second;
                    if (nums[index] != query) {
                        // cout << "Incorrect answer, number not found" <<" "<<nums[index]<<" "<<query<< endl;
                        cout<<"Hello"<<endl;
                        return false;
                    }
                    cnt++;
                }
                if (cnt != input_nums[query]) {
                    cout << "Incorrect number of instances "
                         << "expected " << input_nums[query] << " found " << cnt
                         << " for query " << query << endl;
                    return false;
                }
            }
            fm.CloseFile(output);
        } catch (InvalidPageException &e) {
            cout << "Ran out of pages before reading output fully!" << endl;
            return false;
        }
        return true;
    }
    return true;
}

bool random_small(FileManager &fm) {
    fm.DestroyFile("search_input");
    fm.DestroyFile("search_query");
    fm.DestroyFile("output");
    SimpleWriter<int> input1(fm, "search_input");
    std::ofstream query("search_query");
    std::map<int, int> input_nums;
    std::vector<int> nums, query_nums;
    std::uniform_int_distribution<int> dist(0, 500);
    for (int i = 0; i < 1000; i++) {
        int num = dist(rng);
        nums.push_back(num);
    }
    // std::sort(nums.begin(), nums.end());
    for (int i = 0; i < 1000; i++) {
        int num = dist(rng);
        input_nums[nums[i]]++;
        input1.write(nums[i]);
        query_nums.push_back(num);
        query << "SEARCH " << num << "\n";
    }
    query_nums.push_back(INT_MAX);
    query << "SEARCH " << INT_MAX << "\n";
    query_nums.push_back(INT_MIN);
    query << "SEARCH " << INT_MIN << "\n";
    input1.fill(INT_MIN);
    input1.close(fm);
    query.close();
    cout << "Generated input" << endl;

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./linearsearch", "./linearsearch", "search_input",
                   "search_query", "output", (char *)NULL) == -1) {
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
        FileHandler output = fm.OpenFile("output");

        int max_per_page = PAGE_CONTENT_SIZE / sizeof(pair<int, int>);
        int max_int_per_page = PAGE_CONTENT_SIZE / sizeof(int);
        try {
            int page = 0, offset = 0;
            char *data = output.FirstPage().GetData();
            pair<int, int> end_pair({-1, -1});
            for (int query : query_nums) {
                int cnt = 0;
                while (true) {
                    if (offset >= max_per_page) {
                        output.UnpinPage(page);
                        data = output.PageAt(++page).GetData();
                        offset = 0;
                    }
                    pair<int, int> record =
                        record_at<pair<int, int>>(data, offset++);
                    if (record == end_pair) {
                        break;
                    }
                    int index = record.first * max_int_per_page + record.second;
                    if (nums[index] != query) {
                        cout << "Incorrect answer, number not found" << endl;
                        return false;
                    }
                    cnt++;
                }
                if (cnt != input_nums[query]) {
                    cout << "Incorrect number of instances "
                         << "expected " << input_nums[query] << " found " << cnt
                         << " for query " << query << endl;
                    return false;
                }
            }
            fm.CloseFile(output);
        } catch (InvalidPageException &e) {
            cout << "Ran out of pages before reading output fully!" << endl;
            return false;
        }
        return true;
    }
    return true;
}

bool random_large(FileManager &fm) {
    fm.DestroyFile("search_input");
    fm.DestroyFile("search_query");
    fm.DestroyFile("output");
    SimpleWriter<int> input1(fm, "search_input");
    std::ofstream query("search_query");
    std::map<int, int> input_nums;
    std::vector<int> nums, query_nums;
    std::uniform_int_distribution<int> dist(0, 10000);
    for (int i = 0; i < 100000; i++) {
        int num = dist(rng);
        nums.push_back(num);
    }
    // std::sort(nums.begin(), nums.end());
    for (int i = 0; i < 100000; i++) {
        int num = dist(rng);
        input_nums[nums[i]]++;
        input1.write(nums[i]);
        query_nums.push_back(num);
        query << "SEARCH " << num << "\n";
    }
    query_nums.push_back(INT_MAX);
    query << "SEARCH " << INT_MAX << "\n";
    query_nums.push_back(INT_MIN);
    query << "SEARCH " << INT_MIN << "\n";
    input1.fill(INT_MIN);
    input1.close(fm);
    query.close();
    cout << "Generated input" << endl;

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./linearsearch", "./linearsearch", "search_input",
                   "search_query", "output", (char *)NULL) == -1) {
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
        FileHandler output = fm.OpenFile("output");

        int max_per_page = PAGE_CONTENT_SIZE / sizeof(pair<int, int>);
        int max_int_per_page = PAGE_CONTENT_SIZE / sizeof(int);
        try {
            int page = 0, offset = 0;
            char *data = output.FirstPage().GetData();
            pair<int, int> end_pair({-1, -1});
            for (int query : query_nums) {
                int cnt = 0;
                while (true) {
                    if (offset >= max_per_page) {
                        output.UnpinPage(page);
                        data = output.PageAt(++page).GetData();
                        offset = 0;
                    }
                    pair<int, int> record =
                        record_at<pair<int, int>>(data, offset++);
                    if (record == end_pair) {
                        break;
                    }
                    int index = record.first * max_int_per_page + record.second;
                    if (nums[index] != query) {
                        cout << "Incorrect answer, number not found" << endl;
                        return false;
                    }
                    cnt++;
                }
                if (cnt != input_nums[query]) {
                    cout << "Incorrect number of instances "
                         << "expected " << input_nums[query] << " found " << cnt
                         << " for query " << query << endl;
                    return false;
                }
            }
        } catch (InvalidPageException &e) {
            cout << "Ran out of pages before reading output fully!" << endl;
            return false;
        }
        return true;
    }
    return true;
}
