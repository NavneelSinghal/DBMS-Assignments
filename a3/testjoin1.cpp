#include "constants.h"
#include "errors.h"
#include "file_manager.h"
#include <algorithm>
#include <cassert>
#include <climits>
#include <cstring>
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
            handler.MarkDirty(page.GetPageNum());
            handler.UnpinPage(page.GetPageNum());
            /* handler.FlushPage(page.GetPageNum()); // Write to disk and also
             */
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

bool empty_input1(FileManager &fm);
bool empty_input2(FileManager &fm);
bool full_page(FileManager &fm);
bool small_join(FileManager &fm);
bool large_join(FileManager &fm);

std::random_device rd;
std::default_random_engine rng(rd());

int main() {
    FileManager fm;

    std::vector<pair<std::string, std::function<bool(FileManager &)>>> tests = {
        {"Empty Input 1", empty_input1},
        {"Empty Input 2", empty_input2},
        {"Full Page Join", full_page},
        {"Small random join", small_join},
        {"Large random join", large_join}};

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

bool empty_input1(FileManager &fm) {
    fm.DestroyFile("join_input1");
    fm.DestroyFile("output");
    FileHandler input1 = fm.CreateFile("join_input1");
    fm.CloseFile(input1);

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./join1", "./join1", "join_input1",
                   "TestCases/TC_join1/input2_join1", "output",
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
        FileHandler output = fm.OpenFile("output");
        try {
            PageHandler temp = output.LastPage();
            if (temp.GetPageNum() != -1) {
                cout << "Output should have been empty" << endl;
                return false;
            }
            return true;
        } catch (InvalidPageException &e) {
            return true;
        }
        return false;
    }
    return true;
}

bool empty_input2(FileManager &fm) {
    fm.DestroyFile("join_input1");
    fm.DestroyFile("output");
    FileHandler input1 = fm.CreateFile("join_input1");
    fm.CloseFile(input1);

    int pid = fork();
    if (pid == 0) {
        // Run join1
        if (execlp("./join1", "./join1", "TestCases/TC_join1/input1_join1",
                   "join_input1", "output", (char *)NULL) == -1) {
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
        try {
            PageHandler temp = output.LastPage();
            if (temp.GetPageNum() != -1) {
                cout << "Output should have been empty" << endl;
                return false;
            }
            return true;
        } catch (InvalidPageException &e) {
            return true;
        }
        return false;
    }
    return true;
}

bool full_page(FileManager &fm) {
    fm.DestroyFile("join_input1");
    fm.DestroyFile("join_input2");
    fm.DestroyFile("output");
    SimpleWriter<int> input1(fm, "join_input1");
    SimpleWriter<int> input2(fm, "join_input2");

    int size = PAGE_CONTENT_SIZE/sizeof(int);
    std::map<int, int> input1_nums, input2_nums;

    for (int i = 0; i < size; i++) {
      int a1 = 0, a2 = 0;
        input1_nums[a1]++;
        input2_nums[a2]++;
        input1.write(a1);
        input2.write(a2);
    }
    input1.fill(INT_MIN);
    input2.fill(INT_MIN);
    input1.close(fm);
    input2.close(fm);

    int pid = fork();
    if (pid == 0) {
        // run join1
        if (execlp("./join1", "./join1", "join_input1", "join_input2", "output",
                   (char *)NULL) == -1) {
            perror("exec error");
            exit(-1);
        }
    } else {
        int retval;
        waitpid(pid, &retval, 0);
        if (retval != 0) {
            /* not a clean exit, some error occured in the program */
            return false;
        }

        // clean exit, so now check output
        FileHandler output = fm.OpenFile("output");
        std::map<int, int> output_nums;
        int count = 0;

        int max_per_page = PAGE_CONTENT_SIZE / sizeof(int);
        try {
            PageHandler temp = output.LastPage();
            output.UnpinPage(temp.GetPageNum());
            int last = temp.GetPageNum();
            for (int i = 0; i <= last; i++) {
                PageHandler temp = output.PageAt(i);
                char *data = temp.GetData();
                for (int j = 0; j < max_per_page; j++) {
                    int num = record_at<int>(data, j);
                    if (num == INT_MIN)
                        break;
                    output_nums[num]++;
                    count ++;
                }
                output.FlushPage(i);
            }
        } catch (InvalidPageException &e) {
            cout << "no pages found in output!" << endl;
            return false;
        }
        if (count != size * size) {
          cout << "join incorrect" << endl;
          return false;
        }
        for (int i = 0; i < 1; i++) {
            if (output_nums[i] == input1_nums[i] * input2_nums[i])
                continue;
            else {
                cout << "join incorrect of " << i << " : " << output_nums[i]
                     << " != " << input1_nums[i] << " * " << input2_nums[i]
                     << endl;
                return false;
            }
        }
        return true;
    }
    return true;
}

bool small_join(FileManager &fm) {
    fm.DestroyFile("join_input1");
    fm.DestroyFile("join_input2");
    fm.DestroyFile("output");
    SimpleWriter<int> input1(fm, "join_input1");
    SimpleWriter<int> input2(fm, "join_input2");

    int size = 1000;
    std::map<int, int> input1_nums, input2_nums;
    std::uniform_int_distribution<int> dist1(0, 200), dist2(100, 300);

    /* on average each number would be generated ~5 times in each file
     * this means in the outpute we can expect ~25 instances of each number
     * in the range [100, 200) so total 2500 nums in the output
     */
    for (int i = 0; i < size; i++) {
        int a1 = dist1(rng), a2 = dist2(rng);
        input1_nums[a1]++;
        input2_nums[a2]++;
        input1.write(a1);
        input2.write(a2);
    }
    input1.fill(INT_MIN);
    input2.fill(INT_MIN);
    input1.close(fm);
    input2.close(fm);

    int pid = fork();
    if (pid == 0) {
        // run join1
        if (execlp("./join1", "./join1", "join_input1", "join_input2", "output",
                   (char *)NULL) == -1) {
            perror("exec error");
            exit(-1);
        }
    } else {
        int retval;
        waitpid(pid, &retval, 0);
        if (retval != 0) {
            /* not a clean exit, some error occured in the program */
            return false;
        }

        // clean exit, so now check output
        FileHandler output = fm.OpenFile("output");
        std::map<int, int> output_nums;

        int max_per_page = PAGE_CONTENT_SIZE / sizeof(int);
        try {
            PageHandler temp = output.LastPage();
            output.UnpinPage(temp.GetPageNum());
            int last = temp.GetPageNum();
            for (int i = 0; i <= last; i++) {
                PageHandler temp = output.PageAt(i);
                char *data = temp.GetData();
                for (int j = 0; j < max_per_page; j++) {
                    int num = record_at<int>(data, j);
                    if (num == INT_MIN)
                        break;
                    output_nums[num]++;
                }
                output.FlushPage(i);
            }
        } catch (InvalidPageException &e) {
            cout << "no pages found in output!" << endl;
            return false;
        }
        for (int i = 0; i < 300; i++) {
            if (output_nums[i] == input1_nums[i] * input2_nums[i])
                continue;
            else {
                cout << "join incorrect of " << i << " : " << output_nums[i]
                     << " != " << input1_nums[i] << " * " << input2_nums[i]
                     << endl;
                return false;
            }
        }
        return true;
    }
    return true;
}

bool large_join(FileManager &fm) {
    fm.DestroyFile("join_input1");
    fm.DestroyFile("join_input2");
    fm.DestroyFile("output");
    SimpleWriter<int> input1(fm, "join_input1");
    SimpleWriter<int> input2(fm, "join_input2");

    int size = 100000;
    std::map<int, int> input1_nums, input2_nums;
    std::uniform_int_distribution<int> dist1(0, 10000), dist2(9000, 19000);

    /* on average each number would be generated ~10 times in each file
     * this means in the outpute we can expect ~100 instances of each number
     * in the range [9000, 10000) so total 100000 nums in the output or 16k
     * pages in the output
     */
    for (int i = 0; i < size; i++) {
        int a1 = dist1(rng), a2 = dist2(rng);
        input1_nums[a1]++;
        input2_nums[a2]++;
        input1.write(a1);
        input2.write(a2);
    }
    input1.fill(INT_MIN);
    input2.fill(INT_MIN);
    input1.close(fm);
    input2.close(fm);

    cout << "Data generation complete" << endl;

    int pid = fork();
    if (pid == 0) {
        // run join1
        if (execlp("./join1", "./join1", "join_input1", "join_input2", "output",
                   (char *)NULL) == -1) {
            perror("exec error");
            exit(-1);
        }
    } else {
        int retval;
        waitpid(pid, &retval, 0);
        if (retval != 0) {
            /* not a clean exit, some error occured in the program */
            return false;
        }

        // clean exit, so now check output
        FileHandler output = fm.OpenFile("output");
        std::map<int, int> output_nums;

        int max_per_page = PAGE_CONTENT_SIZE / sizeof(int);
        try {
            PageHandler temp = output.LastPage();
            output.UnpinPage(temp.GetPageNum());
            int last = temp.GetPageNum();
            for (int i = 0; i <= last; i++) {
                PageHandler temp = output.PageAt(i);
                char *data = temp.GetData();
                for (int j = 0; j < max_per_page; j++) {
                    int num = record_at<int>(data, j);
                    if (num == INT_MIN)
                        break;
                    output_nums[num]++;
                }
                output.FlushPage(i);
            }
        } catch (InvalidPageException &e) {
            cout << "no pages found in output!" << endl;
            return false;
        }
        for (int i = 0; i < 190000; i++) {
            if (output_nums[i] == input1_nums[i] * input2_nums[i])
                continue;
            else {
                cout << "join incorrect of " << i << " : " << output_nums[i]
                     << " != " << input1_nums[i] << " * " << input2_nums[i]
                     << endl;
                return false;
            }
        }
        return true;
    }
    return true;
}
