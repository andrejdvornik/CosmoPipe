# the compiler: gcc for C program, define as g++ for C++
CC = gcc

# compiler flags:
#  -g    adds debugging information to the executable file
#  -Wall turns on most, but not all, compiler warnings
CFLAGS  = -O3 -Wall

# define any directories containing header files other than /usr/include
# We're expecting the bjutils to be the above src directory
whereami = `pwd`
INCLUDES = -I@RUNROOT@/@SCRIPTPATH@/


# define library paths in addition to /usr/lib
LFLAGS=-L@RUNROOT@/@SCRIPTPATH@/lib -lbjutils

# define any libraries to link into executable:
LIBS = -lgsl -lgslcblas -lm

# the build target executable:
TARGET = xi2bandpow

all: $(TARGET)

$(TARGET): $(TARGET).c
	$(CC) $(TARGET).c $(CFLAGS) $(INCLUDES) $(LFLAGS) $(LIBS) -o ../bin/$(TARGET) 

clean:
	$(RM) $(TARGET)
