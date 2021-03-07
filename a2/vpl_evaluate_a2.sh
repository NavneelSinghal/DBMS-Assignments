#!/bin/bash

# . common_script.sh

set_grade() {
    echo "#!/bin/bash" >> vpl_execution
    echo "echo '$1'" >> vpl_execution
    chmod +x vpl_execution
}

set_comment() {
    echo "#!/bin/bash" >> vpl_execution
    echo "echo 'Comment :=>> $1'" >> vpl_execution
    chmod +x vpl_execution
}

rm vpl_execution
python3 checker.py query.sql

if [ $? -ne 0 ]; then
    set_comment "File Invalid"
    exit
fi

set_grade "File Valid";