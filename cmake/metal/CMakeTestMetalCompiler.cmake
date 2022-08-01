if(CMAKE_Metal_COMPILER_FORCED)
    # The compiler configuration was forced by the user. Assume the user has configured all compiler information.
    set(CMAKE_Metal_COMPILER_WORKS TRUE)
    return()
endif()

include(CMakeTestCompilerCommon)

# Remove any cached result from an older CMake version. We now store this in CMakeMetalCompiler.cmake.
unset(CMAKE_Metal_COMPILER_WORKS CACHE)

# This file is used by EnableLanguage in cmGlobalGenerator to determine that the selected C++ compiler can actually
# compile and link the most basic of programs.   If not, a fatal error is set and cmake stops processing commands and
# will not generate any makefiles or projects.
if(NOT CMAKE_Metal_COMPILER_WORKS)
    PrintTestCompilerStatus("Metal")
    file(WRITE ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/main.metal
         "kernel void mainKernel(uint2 tid [[thread_position_in_grid]]){}\n")
    # Clear result from normal variable.
    unset(CMAKE_Metal_COMPILER_WORKS)

    # Make sure we try to compile as a STATIC_LIBRARY
    set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
    __testcompiler_settrycompiletargettype()

    # Puts test result in cache variable.
    try_compile(
        CMAKE_Metal_COMPILER_WORKS ${CMAKE_BINARY_DIR}
        ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeTmp/main.metal
        OUTPUT_VARIABLE __CMAKE_Metal_COMPILER_OUTPUT)
    # Move result from cache to normal variable.
    set(CMAKE_Metal_COMPILER_WORKS ${CMAKE_Metal_COMPILER_WORKS})
    unset(CMAKE_Metal_COMPILER_WORKS CACHE)
    set(Metal_TEST_WAS_RUN 1)

    __testcompiler_restoretrycompiletargettype()
endif()

if(NOT CMAKE_Metal_COMPILER_WORKS)
    printtestcompilerresult(CHECK_FAIL "broken")
    file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeError.log
         "Determining if the Metal compiler works failed with "
         "the following output:\n${__CMAKE_Metal_COMPILER_OUTPUT}\n\n")
    string(
        REPLACE "\n"
                "\n  "
                _output
                "${__CMAKE_Metal_COMPILER_OUTPUT}")
    message(
        FATAL_ERROR
            "The Metal compiler\n  \"${CMAKE_Metal_COMPILER}\"\n"
            "is not able to compile a simple test program.\nIt fails "
            "with the following output:\n  ${_output}\n\n"
            "CMake will not be able to correctly generate this project.")
else()
    if(Metal_TEST_WAS_RUN)
        printtestcompilerresult(CHECK_PASS "works")
        file(APPEND ${CMAKE_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/CMakeOutput.log
             "Determining if the Metal compiler works passed with "
             "the following output:\n${__CMAKE_Metal_COMPILER_OUTPUT}\n\n")
    endif()

    # Unlike C and CXX we do not yet detect any information about the Metal ABI. However, one of the steps done for C
    # and CXX as part of that detection is to initialize the implicit include directories.  That is relevant here.
    set(CMAKE_Metal_IMPLICIT_INCLUDE_DIRECTORIES "${_CMAKE_Metal_IMPLICIT_INCLUDE_DIRECTORIES_INIT}")

    # Re-configure to save learned information.
    configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeMetalCompiler.cmake.in
                   ${CMAKE_PLATFORM_INFO_DIR}/CMakeMetalCompiler.cmake @ONLY)
    include(${CMAKE_PLATFORM_INFO_DIR}/CMakeMetalCompiler.cmake)
endif()

unset(__CMAKE_Metal_COMPILER_OUTPUT)
