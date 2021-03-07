#!/usr/bin/env python3

"""
Check query.sql is as per format
"""


import sys
import os
import re

import copy

TOTAL_QUESTIONS = 22

def err(*msg, do_exit = False):
    print(*msg)
    if(do_exit):
      exit(1)

def main(file):

    with open(file) as f:
        fcontents = f.read().strip()

    flines = list(map(lambda l: l.strip(), fcontents.split("\n")))
    

    error_came=0
    # int -> string
    parts_student = {}
    
    part = ""
    data= ""

    # Build parts dict
    for index_of_line_in_file in range(0, len(flines), 1):

        l = flines[index_of_line_in_file]
        m = re.match(r"--\s*(\d+|CLEANUP|PREAMBLE)\s*--", l)
        #print(l)
        if m:
            
            parts_student[part] = data#flines[index_of_line_in_file+1]
            part = m.group(1)#.lower()
            data= ""

        else:
            data+=l+"\n"

    # The last part is cleanup
    parts_student[part] = data
   # print("parts ", parts)
    del parts_student['']
    
    parts_student_orig = copy.copy(parts_student)
    
    print("  Query ids found ", list(parts_student.keys()),"\n")

    # Dump parts dict into individual files
    valid_parts = list(map(str, range(1, TOTAL_QUESTIONS + 1)))
    valid_parts += ["CLEANUP"]
    valid_parts= ["PREAMBLE"]+ valid_parts
    
    #print(valid_parts)

    for part in valid_parts:

        if part not in parts_student:
            err(
                "\nError: Section not present: %s\n"
                "Make sure you create sections for each question, even if you leave them empty. Put an empty query if you wish to not attempt that query " % part
            )
            error_came=1
        else:
                            

          
          fn = "part-%s.sql" % part
  
          # Write to separate file
          with open(fn, "w") as f:
              f.write(parts_student[part])
  
          # Remove this part from dict
          parts_student.pop(part)

    # Nothing should remain at this point
    if parts_student:
        err(
            "Error:  Extra sections present: %s \n" 
            "Remove them." % ",".join(parts_student.keys())
        )
        error_came=1
        
        
    

        
    
    if(error_came==1):
        err(
            "\n\n*************Fix the errors above*****", do_exit=1
        )


    


if __name__ == "__main__":
    main(sys.argv[1])


    