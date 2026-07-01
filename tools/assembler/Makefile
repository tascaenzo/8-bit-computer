CC ?= cc
CFLAGS ?= -std=c99 -Wall -Wextra -Wpedantic -Werror
CPPFLAGS ?= -Iinclude

BUILD_DIR := build
SRC_DIR := src
TARGET := $(BUILD_DIR)/cpu8asm

SRCS := \
	$(SRC_DIR)/main.c \
	$(SRC_DIR)/assembler.c \
	$(SRC_DIR)/errors.c \
	$(SRC_DIR)/isa.c \
	$(SRC_DIR)/output.c \
	$(SRC_DIR)/parser.c

OBJS := $(SRCS:$(SRC_DIR)/%.c=$(BUILD_DIR)/%.o)

.PHONY: all clean test

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) $(OBJS) -o $@

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

test: $(TARGET)
	$(TARGET) --help

clean:
	rm -rf $(BUILD_DIR)

