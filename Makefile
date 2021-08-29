# RULES:
# make             -> Build executable.
# make run         -> Build executable then run it.
# make clean       -> Remove the executable.

# compiler and flags
CC := gcc
CFLAGS := -Wa,--64,--fatal-warnings,-f -nostdlib -no-pie

SRCS := $(wildcard *.S)
EXEC := bfuc

ifeq ($(OS),Windows_NT)
EXEC := $(EXEC).exe
PATH_SEP := $(subst /,\\,/)
RM := del /q /f
else
PATH_SEP := /
RM := rm -f
endif

.PHONY: all run clean
all: $(EXEC)
	@echo Building complete.

run: all
	.$(PATH_SEP)$(EXEC) $(ARGS)
	@echo Executing complete.

clean:
	$(RM) $(EXEC)
	@echo Cleaning complete.

$(EXEC): $(SRCS)
	$(CC) $(CFLAGS) \
		$(SRCS) \
		-o $(EXEC)
