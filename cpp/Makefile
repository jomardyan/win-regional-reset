# Makefile for Windows Regional Settings Reset - C++ Edition
# Supports multiple compilers: MSVC, MinGW-w64, Clang

# Compiler detection
ifeq ($(OS),Windows_NT)
    # Windows environment
    ifeq ($(CXX),)
        # Try to detect available compiler
        CXX := $(shell where cl.exe 2>nul && echo cl || where g++.exe 2>nul && echo g++ || echo g++)
    endif
    
    # Set compiler-specific flags
    ifeq ($(CXX),cl)
        # MSVC
        CXXFLAGS = /std:c++17 /W4 /EHsc /O2 /DWIN32_LEAN_AND_MEAN /DNOMINMAX /D_WIN32_WINNT=0x0600
        LDFLAGS = /link advapi32.lib kernel32.lib user32.lib shell32.lib
        OUTPUT_FLAG = /Fe:
        OBJ_EXT = .obj
        EXE_EXT = .exe
        COMPILE_CMD = $(CXX) $(CXXFLAGS) /c $< /Fo:$@
        LINK_CMD = $(CXX) $(OBJECTS) $(LDFLAGS) $(OUTPUT_FLAG)$@
    else
        # MinGW/GCC/Clang
        CXXFLAGS = -std=c++17 -Wall -Wextra -O2 -DWIN32_LEAN_AND_MEAN -DNOMINMAX -D_WIN32_WINNT=0x0600
        LDFLAGS = -ladvapi32 -lkernel32 -luser32 -lshell32 -static-libgcc -static-libstdc++
        OUTPUT_FLAG = -o 
        OBJ_EXT = .o
        EXE_EXT = .exe
        COMPILE_CMD = $(CXX) $(CXXFLAGS) -c $< -o $@
        LINK_CMD = $(CXX) $(OBJECTS) $(LDFLAGS) $(OUTPUT_FLAG)$@
    endif
    
    RM = del /Q
    MKDIR = mkdir
    TARGET = RegionalSettingsReset$(EXE_EXT)
else
    # Non-Windows (for testing/demo)
    CXX ?= g++
    CXXFLAGS = -std=c++17 -Wall -Wextra -O2 -DDEMO_MODE
    LDFLAGS = 
    OUTPUT_FLAG = -o 
    OBJ_EXT = .o
    EXE_EXT = 
    COMPILE_CMD = $(CXX) $(CXXFLAGS) -c $< -o $@
    LINK_CMD = $(CXX) $(OBJECTS) $(LDFLAGS) $(OUTPUT_FLAG)$@
    RM = rm -f
    MKDIR = mkdir -p
    TARGET = RegionalSettingsReset$(EXE_EXT)
endif

# Source files
SOURCES = RegionalSettingsReset.cpp
OBJECTS = $(SOURCES:.cpp=$(OBJ_EXT))

# Build directories
BUILD_DIR = build
BIN_DIR = bin

.PHONY: all clean debug release run install help

# Default target
all: release

# Release build
release: CXXFLAGS += -DNDEBUG
release: $(BIN_DIR)/$(TARGET)

# Debug build  
debug: CXXFLAGS += -DDEBUG -g
debug: $(BIN_DIR)/$(TARGET)

# Create directories
$(BUILD_DIR):
	$(MKDIR) $(BUILD_DIR)

$(BIN_DIR):
	$(MKDIR) $(BIN_DIR)

# Compile source files
%$(OBJ_EXT): %.cpp | $(BUILD_DIR)
	$(COMPILE_CMD)

# Link executable
$(BIN_DIR)/$(TARGET): $(OBJECTS) | $(BIN_DIR)
	$(LINK_CMD)

# Run the application
run: $(BIN_DIR)/$(TARGET)
ifeq ($(OS),Windows_NT)
	cd $(BIN_DIR) && ./$(TARGET)
else
	@echo "Note: Running in demo mode on non-Windows platform"
	cd $(BIN_DIR) && ./$(TARGET)
endif

# Install (Windows only)
install: $(BIN_DIR)/$(TARGET)
ifeq ($(OS),Windows_NT)
	@echo Installing to C:\Program Files\RegionalSettingsReset\
	@echo Note: This requires administrator privileges
	$(MKDIR) "C:\Program Files\RegionalSettingsReset" 2>nul || echo Directory may already exist
	copy $(BIN_DIR)\$(TARGET) "C:\Program Files\RegionalSettingsReset\"
	copy README.md "C:\Program Files\RegionalSettingsReset\" 2>nul || echo README not found
else
	@echo Install target only supported on Windows
endif

# Clean build artifacts
clean:
ifeq ($(OS),Windows_NT)
	-$(RM) *$(OBJ_EXT) 2>nul
	-$(RM) $(BIN_DIR)\* 2>nul
	-$(RM) $(BUILD_DIR)\* 2>nul
else
	$(RM) *$(OBJ_EXT)
	$(RM) $(BIN_DIR)/*
	$(RM) $(BUILD_DIR)/*
endif

# Help target
help:
	@echo Windows Regional Settings Reset - C++ Edition v2.0
	@echo Build System Help
	@echo.
	@echo Available targets:
	@echo   all      - Build release version (default)
	@echo   release  - Build optimized release version
	@echo   debug    - Build debug version with symbols
	@echo   run      - Build and run the application
	@echo   clean    - Remove build artifacts
	@echo   install  - Install to system (Windows only, requires admin)
	@echo   help     - Show this help message
	@echo.
	@echo Examples:
	@echo   make release          # Build optimized version
	@echo   make debug            # Build debug version
	@echo   make run              # Build and run
	@echo   make CXX=clang++      # Use specific compiler
	@echo.
	@echo Supported compilers:
	@echo   - MSVC (cl.exe)       # Microsoft Visual C++
	@echo   - MinGW-w64 (g++)     # GCC for Windows
	@echo   - Clang (clang++)     # LLVM Clang
	@echo.
ifeq ($(OS),Windows_NT)
	@echo Current environment: Windows
	@echo Detected compiler: $(CXX)
else
	@echo Current environment: $(shell uname -s)
	@echo Note: Demo mode only on non-Windows platforms
endif