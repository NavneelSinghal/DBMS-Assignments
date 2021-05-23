sampleobjects = buffer_manager.o file_manager.o sample_run.o
submission = linearsearch binarysearch deletion join1 join2
extras = printints printpairs testjoin1 testbinarysearch testlinearsearch testjoin2 testdeletion

submission: $(submission)

extras: $(extras)

$(submission): % : %.o buffer_manager.o file_manager.o
	g++ -std=c++11 -Wall -o $@ $^

$(addsuffix .o, $(submission)): %.o : %.cpp constants.h
	g++ -O3 -std=c++11 -Wall -o $@ -c $<

$(extras): % : %.o constants.h buffer_manager.o file_manager.o
	g++ -std=c++11 -Wall -o $@ $^

$(addsuffix .o, $(extras)): %.o : %.cpp
	g++ -O3 -std=c++11 -Wall -o $@ -c $<

submission_name := 2018CS10383_2018CS10365_2018CS10360
zip:
	rm -rf $(submission_name) $(submission_name).zip
	mkdir $(submission_name)
	cp Makefile README.* $(addsuffix .cpp, $(submission)) $(submission_name)/
	zip -rm $(submission_name).zip $(submission_name)/

sample_run : $(sampleobjects)
	g++ -std=c++11 -o sample_run $(sampleobjects)

sample_run.o : sample_run.cpp constants.h
	g++ -std=c++11 -c sample_run.cpp

buffer_manager.o : buffer_manager.cpp constants.h
	g++ -std=c++11 -c buffer_manager.cpp

file_manager.o : file_manager.cpp constants.h
	g++ -std=c++11 -c file_manager.cpp

clean :
	rm -f *.o
	rm -f sample_run
	rm -f $(submission)
	rm -f $(extras)

linear_test:
	rm -f ./TestCases/TC_search/my_output_search
	./linearsearch ./TestCases/TC_search/sorted_input  ./TestCases/TC_search/query_search.txt ./TestCases/TC_search/my_output_search
