cmake_minimum_required(VERSION 3.16)
project(RegionalSettingsReset VERSION 2.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Platform-specific settings
if(WIN32)
    # Windows-specific settings
    add_definitions(-DWIN32_LEAN_AND_MEAN)
    add_definitions(-DNOMINMAX)
    add_definitions(-DUNICODE -D_UNICODE)
    
    # Enable Windows Vista+ features
    add_definitions(-D_WIN32_WINNT=0x0600)
    
    # MSVC specific settings
    if(MSVC)
        # Enable parallel compilation
        add_compile_options(/MP)
        
        # Set warning level
        add_compile_options(/W4)
        
        # Disable specific warnings
        add_compile_options(/wd4996) # Disable deprecated function warnings
        
        # Enable security features
        add_compile_options(/GS /sdl)
        
        # Release optimizations
        if(CMAKE_BUILD_TYPE STREQUAL "Release")
            add_compile_options(/O2 /Ob2 /DNDEBUG)
            set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${CMAKE_EXE_LINKER_FLAGS_RELEASE} /OPT:REF /OPT:ICF")
        endif()
    endif()
    
    # MinGW specific settings
    if(MINGW)
        add_compile_options(-Wall -Wextra)
        if(CMAKE_BUILD_TYPE STREQUAL "Release")
            add_compile_options(-O3 -DNDEBUG)
        endif()
    endif()
else()
    # Non-Windows platforms (for cross-compilation testing)
    message(WARNING "This application is designed for Windows. Building for demonstration purposes only.")
    add_compile_options(-Wall -Wextra -Wpedantic)
    
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        add_compile_options(-O3 -DNDEBUG)
    endif()
endif()

# Source files
set(SOURCES
    RegionalSettingsReset.cpp
)

# Create executable
add_executable(RegionalSettingsReset ${SOURCES})

# Link libraries
if(WIN32)
    target_link_libraries(RegionalSettingsReset
        advapi32    # Registry functions
        kernel32    # Core Windows API
        user32      # User interface functions
        shell32     # Shell functions (admin check)
    )
else()
    # Mock libraries for non-Windows platforms
    message(STATUS "Building demo version for non-Windows platform")
endif()

# Set target properties
set_target_properties(RegionalSettingsReset PROPERTIES
    OUTPUT_NAME "RegionalSettingsReset"
    DEBUG_POSTFIX "_d"
)

# Installation
if(WIN32)
    install(TARGETS RegionalSettingsReset
        RUNTIME DESTINATION bin
    )
    
    # Install additional files
    install(FILES 
        "${CMAKE_CURRENT_SOURCE_DIR}/README.md"
        DESTINATION .
    )
    
    # Create installer package
    set(CPACK_PACKAGE_NAME "Windows Regional Settings Reset")
    set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
    set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
    set(CPACK_PACKAGE_DESCRIPTION_SUMMARY "Windows Regional Settings Reset - C++ Edition")
    set(CPACK_PACKAGE_VENDOR "Windows Regional Settings Reset Team")
    set(CPACK_RESOURCE_FILE_LICENSE "${CMAKE_CURRENT_SOURCE_DIR}/../LICENSE")
    
    if(MSVC)
        set(CPACK_GENERATOR "ZIP;NSIS")
    else()
        set(CPACK_GENERATOR "ZIP")
    endif()
    
    include(CPack)
endif()

# Custom targets for development
add_custom_target(run
    COMMAND $<TARGET_FILE:RegionalSettingsReset>
    DEPENDS RegionalSettingsReset
    WORKING_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}
    COMMENT "Running Regional Settings Reset"
)

add_custom_target(clean-all
    COMMAND ${CMAKE_COMMAND} --build ${CMAKE_BINARY_DIR} --target clean
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/bin
    COMMAND ${CMAKE_COMMAND} -E remove_directory ${CMAKE_BINARY_DIR}/lib
    COMMENT "Cleaning all build artifacts"
)