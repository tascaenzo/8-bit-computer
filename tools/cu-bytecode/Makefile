CC ?= cc
# Flag severi: ogni warning viene trattato come errore per mantenere pulito il C.
CFLAGS ?= -std=c99 -Wall -Wextra -Wpedantic -Werror
CPPFLAGS ?= -Iinclude

# Tutti gli artefatti generati rimangono nella cartella ignorata build/.
BUILD_DIR := build
TARGET := $(BUILD_DIR)/cpu8microcode
TEST_TARGET := $(BUILD_DIR)/test_microcode

SRCS := src/main.c src/microcode.c src/output.c
OBJS := $(SRCS:src/%.c=$(BUILD_DIR)/%.o)
CONFIG_OBJ := $(BUILD_DIR)/control_signals.o

.PHONY: all generate test clean

all: $(TARGET)

# Link dell'eseguibile principale.
$(TARGET): $(OBJS) $(CONFIG_OBJ)
	$(CC) $(CFLAGS) $(OBJS) $(CONFIG_OBJ) -o $@

# Regola generica: trasforma src/nome.c in build/nome.o.
$(BUILD_DIR)/%.o: src/%.c config/control_signals.h config/architecture.h
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# La configurazione e un modulo separato per essere leggibile da IntelliSense.
$(CONFIG_OBJ): config/control_signals.c config/control_signals.h include/microcode.h
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) -c $< -o $@

# I test collegano direttamente motore e configurazione, senza il main del tool.
$(TEST_TARGET): tests/test_microcode.c src/microcode.c config/control_signals.c config/control_signals.h config/architecture.h
	@mkdir -p $(BUILD_DIR)
	$(CC) $(CPPFLAGS) $(CFLAGS) tests/test_microcode.c src/microcode.c config/control_signals.c -o $@

generate: $(TARGET)
	$(TARGET)

test: $(TEST_TARGET)
	$(TEST_TARGET)

clean:
	rm -rf $(BUILD_DIR)
