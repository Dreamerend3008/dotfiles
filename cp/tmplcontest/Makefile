# Compiler settings
CXX      := g++
CXXFLAGS := -std=c++17 -O2 -Wall -Wextra -DONLINE_JUDGE

# Detect all cpp files (A.cpp -> A, etc.)
SRCS := $(wildcard *.cpp)
BINS := $(SRCS:.cpp=)

# Declare all executables as phony so they always rebuild
.PHONY: $(BINS) clean

# Rule: make A (compiles, runs, compares output)
$(BINS):
	@echo "Compiling $@.cpp..."
	@$(CXX) $(CXXFLAGS) $@.cpp -o $@
	@if [ -f input.txt ]; then \
		echo "Running $@ with input.txt..."; \
		./$@ < input.txt > output.txt; \
	else \
		echo "Running $@ without input.txt..."; \
		./$@ > output.txt; \
	fi
	@echo "=== Program Output ==="
	@cat output.txt
	@if [ -f expected.txt ]; then \
		echo ""; \
		echo "=== Comparing with expected.txt ==="; \
		if diff -q output.txt expected.txt > /dev/null; then \
			echo "✅ Output matches expected.txt"; \
		else \
			echo "❌ Output differs from expected.txt"; \
			diff -u expected.txt output.txt || true; \
		fi \
	else \
		echo "⚠️ No expected.txt file found, skipping check."; \
	fi

# Clean binaries and outputs
clean:
	rm -f $(BINS) *.out output.txt
