# Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
# file Copyright.txt or https://cmake.org/licensing for details.

include(${CMAKE_ROOT}/Modules/CMakeDetermineCompiler.cmake)

# Local system-specific compiler preferences for this language.
include(Platform/${CMAKE_SYSTEM_NAME}-Determine-InterfaceBuilder OPTIONAL)
include(Platform/${CMAKE_SYSTEM_NAME}-InterfaceBuilder OPTIONAL)
if(NOT CMAKE_InterfaceBuilder_COMPILER_NAMES)
  set(CMAKE_InterfaceBuilder_COMPILER_NAMES ibtool)
endif()

# TODO: Support XCode generator
#[[
if("${CMAKE_GENERATOR}" STREQUAL "Xcode")
  if(XCODE_VERSION VERSION_LESS 6.1)
    message(
      FATAL_ERROR "InterfaceBuilder language not supported by Xcode ${XCODE_VERSION}")
  endif()
  set(CMAKE_InterfaceBuilder_COMPILER_XCODE_TYPE sourcecode.interfacebuilder)
  _cmake_find_compiler_path(InterfaceBuilder)
#]]
if("${CMAKE_GENERATOR}" MATCHES "^Ninja")
  if(CMAKE_InterfaceBuilder_COMPILER)
    _cmake_find_compiler_path(InterfaceBuilder)
  else()
    set(CMAKE_InterfaceBuilder_COMPILER_INIT NOTFOUND)

    if(NOT $ENV{INTERFACEBUILDERC} STREQUAL "")
      get_filename_component(
        CMAKE_InterfaceBuilder_COMPILER_INIT $ENV{INTERFACEBUILDERC} PROGRAM
        PROGRAM_ARGS CMAKE_InterfaceBuilder_FLAGS_ENV_INIT)
      if(CMAKE_InterfaceBuilder_FLAGS_ENV_INIT)
        set(CMAKE_InterfaceBuilder_COMPILER_ARG1
            "${CMAKE_InterfaceBuilder_FLAGS_ENV_INIT}"
            CACHE STRING "Arguments to the InterfaceBuilder compiler")
      endif()
      if(NOT EXISTS ${CMAKE_InterfaceBuilder_COMPILER_INIT})
        message(
          FATAL_ERROR
            "Could not find compiler set in environment variable INTERFACEBUILDERC\n$ENV{INTERFACEBUILDERC}.\n${CMAKE_InterfaceBuilder_COMPILER_INIT}"
        )
      endif()
    endif()

    if(NOT CMAKE_InterfaceBuilder_COMPILER_INIT)
      set(CMAKE_InterfaceBuilder_COMPILER_LIST ibtool)
    endif()

    _cmake_find_compiler(InterfaceBuilder)
  endif()
  mark_as_advanced(CMAKE_InterfaceBuilder_COMPILER)
else()
  message(
    FATAL_ERROR
      "InterfaceBuilder language not supported by \"${CMAKE_GENERATOR}\" generator"
  )
endif()

# Don't bother identifying it

# configure variables set in this file for fast reload later on
configure_file(
  ${CMAKE_CURRENT_LIST_DIR}/CMakeInterfaceBuilderCompiler.cmake.in
  ${CMAKE_PLATFORM_INFO_DIR}/CMakeInterfaceBuilderCompiler.cmake @ONLY)

set(CMAKE_InterfaceBuilder_COMPILER_ENV_VAR "INTERFACEBUILDERC")
