include(${CMAKE_ROOT}/Modules/CMakeDetermineCompiler.cmake)

# Local system-specific compiler preferences for this language.
include(Platform/${CMAKE_SYSTEM_NAME}-Determine-Metal OPTIONAL)
include(Platform/${CMAKE_SYSTEM_NAME}-Metal OPTIONAL)
if(NOT CMAKE_Metal_COMPILER_NAMES)
  set(CMAKE_Metal_COMPILER_NAMES metal)
endif()

# TODO: Support XCode generator
#[[
if("${CMAKE_GENERATOR}" STREQUAL "Xcode")
  if(XCODE_VERSION VERSION_LESS 6.1)
    message(
      FATAL_ERROR "Metal language not supported by Xcode ${XCODE_VERSION}")
  endif()
  set(CMAKE_Metal_COMPILER_XCODE_TYPE sourcecode.metal)
  _cmake_find_compiler_path(Metal)
#]]
if("${CMAKE_GENERATOR}" MATCHES "^Ninja")
  if(CMAKE_Metal_COMPILER)
    _cmake_find_compiler_path(Metal)
  else()
    set(CMAKE_Metal_COMPILER_INIT NOTFOUND)

    if(NOT $ENV{METALC} STREQUAL "")
      get_filename_component(CMAKE_Metal_COMPILER_INIT $ENV{METALC} PROGRAM
                             PROGRAM_ARGS CMAKE_Metal_FLAGS_ENV_INIT)
      if(CMAKE_Metal_FLAGS_ENV_INIT)
        set(CMAKE_Metal_COMPILER_ARG1
            "${CMAKE_Metal_FLAGS_ENV_INIT}"
            CACHE STRING "Arguments to the Metal compiler")
      endif()
      if(NOT EXISTS ${CMAKE_Metal_COMPILER_INIT})
        message(
          FATAL_ERROR
            "Could not find compiler set in environment variable METALC\n$ENV{METALC}.\n${CMAKE_Metal_COMPILER_INIT}"
        )
      endif()
    endif()

    if(NOT CMAKE_Metal_COMPILER_INIT)
      set(CMAKE_Metal_COMPILER_LIST metal ${_CMAKE_TOOLCHAIN_PREFIX}metal)
    endif()

    _cmake_find_compiler(Metal)
  endif()
  mark_as_advanced(CMAKE_Metal_COMPILER)
else()
  message(
    FATAL_ERROR
      "Metal language not supported by \"${CMAKE_GENERATOR}\" generator")
endif()

# Find additional tools
get_filename_component(_metal_directory ${CMAKE_Metal_COMPILER} DIRECTORY)
find_program(CMAKE_Metallib_COMPILER metallib ${_metal_directory} REQUIRED)
find_program(CMAKE_Metal_AR metal-ar ${_metal_directory} REQUIRED)
unset(_metal_directory)

# Identify the compiler.
if(NOT CMAKE_Metal_COMPILER_ID_RUN)
  set(CMAKE_Metal_COMPILER_ID_RUN 1)

  execute_process(
    COMMAND "${CMAKE_Metal_COMPILER}" --version
    OUTPUT_VARIABLE _output
    ERROR_VARIABLE _output
    RESULT_VARIABLE result
    TIMEOUT 10)

  # Try to identify the compiler.
  if(_output MATCHES [[(.*) metal version ([0-9]+\.[0-9]+(\.[0-9]+)?)]])
    set(CMAKE_Metal_COMPILER_ID "${CMAKE_MATCH_1}")
    set(CMAKE_Metal_COMPILER_VERSION "${CMAKE_MATCH_2}")
  endif()

  unset(_output)
endif()

if(NOT _CMAKE_TOOLCHAIN_LOCATION)
  get_filename_component(_CMAKE_TOOLCHAIN_LOCATION "${CMAKE_Metal_COMPILER}"
                         PATH)
endif()

set(_CMAKE_PROCESSING_LANGUAGE "Metal")
include(CMakeFindBinUtils)
unset(_CMAKE_PROCESSING_LANGUAGE)

# configure variables set in this file for fast reload later on
configure_file(${CMAKE_CURRENT_LIST_DIR}/CMakeMetalCompiler.cmake.in
               ${CMAKE_PLATFORM_INFO_DIR}/CMakeMetalCompiler.cmake @ONLY)

set(CMAKE_Metal_COMPILER_ENV_VAR "METALC")
