cmake_minimum_required(VERSION 3.0.0)
project(MetalRayTracing VERSION 0.1.0)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

# Enable custom Metal language support
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake/metal")
enable_language(Metal)

# Enable custom InterfaceBuilder language support
list(APPEND CMAKE_MODULE_PATH
     "${CMAKE_CURRENT_SOURCE_DIR}/cmake/interfaceBuilder")
enable_language(InterfaceBuilder)

set(CMAKE_OSX_DEPLOYMENT_TARGET 10.15)

add_subdirectory(src)
