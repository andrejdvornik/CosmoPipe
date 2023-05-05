#!/bin/bash
# creates C library

libname=bjutils

# move .c into source/
# move .h into include/

cd source/
LB=" -lgsl -lgslcblas"
LB=" -lgsl -lgslcblas"
INC='@INCLUDEPATH@'
INC='-L/opt/local/include/gsl -I/opt/local/include/'
# create static library
gcc $INC -c *.c
ar rs lib${libname}.a *.o

# create shared library
gcc $INC -c -fpic *.c
#gcc $INC -shared ${LB} -o lib${libname}.so *.o
gcc $INC -shared ${LB} -o lib${libname}.so *.o

mv lib${libname}.a ../lib/
mv lib${libname}.so ../lib/

