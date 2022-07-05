set(CMAKE_Metal_OUTPUT_EXTENSION .air)

# Load compiler-specific information.
if(CMAKE_Metal_COMPILER_ID)
  include(Compiler/${CMAKE_Metal_COMPILER_ID}-Metal OPTIONAL)

  if(CMAKE_SYSTEM_PROCESSOR)
    include(
      Platform/${CMAKE_EFFECTIVE_SYSTEM_NAME}-${CMAKE_Metal_COMPILER_ID}-Metal-${CMAKE_SYSTEM_PROCESSOR}
      OPTIONAL)
  endif()
  include(
    Platform/${CMAKE_EFFECTIVE_SYSTEM_NAME}-${CMAKE_Metal_COMPILER_ID}-Metal
    OPTIONAL)
endif()

set(CMAKE_INCLUDE_FLAG_Metal "-I ")

include(CMakeCommonLanguageInclude)

#[[
now define the following rules:
CMAKE_Metal_CREATE_SHARED_LIBRARY
CMAKE_Metal_CREATE_SHARED_MODULE
CMAKE_Metal_COMPILE_OBJECT
#]]

# create a shared library
if(NOT CMAKE_Metal_CREATE_SHARED_LIBRARY)
  set(CMAKE_Metal_CREATE_SHARED_LIBRARY
      "${CMAKE_Metallib_COMPILER} <OBJECTS> -o <TARGET>")
endif()

# create a shared module, copy the shared library rule by default
if(NOT CMAKE_Metal_CREATE_SHARED_MODULE)
  set(CMAKE_Metal_CREATE_SHARED_MODULE ${CMAKE_Metal_CREATE_SHARED_LIBRARY})
endif()

if(NOT CMAKE_Metal_COMPILE_OBJECT)
  set(CMAKE_Metal_COMPILE_OBJECT
      "<CMAKE_Metal_COMPILER> ${_CMAKE_Metal_EXTRA_FLAGS} <DEFINES> <INCLUDES> <FLAGS> ${_CMAKE_COMPILE_AS_Metal_FLAG} -c <SOURCE> -o <OBJECT>"
  )
endif()

set(CMAKE_Metal_INFORMATION_LOADED 1)
