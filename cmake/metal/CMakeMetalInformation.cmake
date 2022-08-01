# Load compiler-specific information.
if(CMAKE_Metal_COMPILER_ID)
    include(Compiler/${CMAKE_Metal_COMPILER_ID}-Metal OPTIONAL)

    if(CMAKE_SYSTEM_PROCESSOR)
        include(Platform/${CMAKE_EFFECTIVE_SYSTEM_NAME}-${CMAKE_Metal_COMPILER_ID}-Metal-${CMAKE_SYSTEM_PROCESSOR}
                OPTIONAL)
    endif()
    include(Platform/${CMAKE_EFFECTIVE_SYSTEM_NAME}-${CMAKE_Metal_COMPILER_ID}-Metal OPTIONAL)
endif()

include(CMakeCommonLanguageInclude)

#[[
now define the following rules:
CMAKE_Metal_CREATE_SHARED_LIBRARY
CMAKE_Metal_CREATE_SHARED_MODULE
CMAKE_Metal_ARCHIVE_CREATE
CMAKE_Metal_ARCHIVE_APPEND
CMAKE_Metal_ARCHIVE_FINISH
CMAKE_Metal_COMPILE_OBJECT
#]]

# Create a shared library.
if(NOT CMAKE_Metal_CREATE_SHARED_LIBRARY)
    set(CMAKE_Metal_CREATE_SHARED_LIBRARY "${CMAKE_Metallib_COMPILER} <OBJECTS> -o <TARGET>")
endif()

# Create a shared module, copy the shared library rule by default.
if(NOT CMAKE_Metal_CREATE_SHARED_MODULE)
    set(CMAKE_Metal_CREATE_SHARED_MODULE ${CMAKE_Metal_CREATE_SHARED_LIBRARY})
endif()

# Create an static archive incrementally for large object file counts. If CMAKE_Metal_CREATE_STATIC_LIBRARY is set it
# will override these.
if(NOT DEFINED CMAKE_Metal_ARCHIVE_CREATE)
    set(CMAKE_Metal_ARCHIVE_CREATE "${CMAKE_Metal_AR} r <TARGET> <OBJECTS>")
endif()
if(NOT DEFINED CMAKE_Metal_ARCHIVE_APPEND)
    set(CMAKE_Metal_ARCHIVE_APPEND ${CMAKE_Metal_ARCHIVE_CREATE})
endif()
if(NOT DEFINED CMAKE_Metal_ARCHIVE_FINISH)
    set(CMAKE_Metal_ARCHIVE_FINISH "${CMAKE_Metal_AR} t <TARGET>")
endif()

# Compile objects.
if(NOT CMAKE_Metal_COMPILE_OBJECT)
    set(CMAKE_Metal_COMPILE_OBJECT
        "<CMAKE_Metal_COMPILER> ${_CMAKE_Metal_EXTRA_FLAGS} <DEFINES> <INCLUDES> <FLAGS> ${_CMAKE_COMPILE_AS_Metal_FLAG} -c <SOURCE> -o <OBJECT>"
    )
endif()

set(CMAKE_Metal_INFORMATION_LOADED 1)
