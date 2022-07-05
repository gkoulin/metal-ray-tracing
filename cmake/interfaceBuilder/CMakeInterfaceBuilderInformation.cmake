set(CMAKE_InterfaceBuilder_OUTPUT_EXTENSION c)

# Load compiler-specific information.
if(CMAKE_InterfaceBuilder_COMPILER_ID)
  include(Compiler/${CMAKE_InterfaceBuilder_COMPILER_ID}-InterfaceBuilder
          OPTIONAL)

  if(CMAKE_SYSTEM_PROCESSOR)
    include(
      Platform/${CMAKE_EFFECTIVE_SYSTEM_NAME}-${CMAKE_InterfaceBuilder_COMPILER_ID}-InterfaceBuilder-${CMAKE_SYSTEM_PROCESSOR}
      OPTIONAL)
  endif()
  include(
    Platform/${CMAKE_EFFECTIVE_SYSTEM_NAME}-${CMAKE_InterfaceBuilder_COMPILER_ID}-InterfaceBuilder
    OPTIONAL)
endif()

include(CMakeCommonLanguageInclude)

if(NOT CMAKE_InterfaceBuilder_COMPILE_OBJECT)
  set(CMAKE_InterfaceBuilder_COMPILE_OBJECT
      "<CMAKE_InterfaceBuilder_COMPILER> --compile <OBJECT> <SOURCE>")
endif()

set(CMAKE_InterfaceBuilder_INFORMATION_LOADED 1)
