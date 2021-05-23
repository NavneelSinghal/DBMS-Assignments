rm sorted_input query_delete.txt output_delete
cp ./TestCases/TC_delete/* .
make
make printints
./deletion sorted_input query_delete.txt
