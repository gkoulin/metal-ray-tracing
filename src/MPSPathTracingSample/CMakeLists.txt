if(APPLE AND UNIX)
    set(_platform_specific_dir "${CMAKE_CURRENT_SOURCE_DIR}/macOS")
    set(_platform_specific_storyboard_file ${_platform_specific_dir}/Base.lproj/Main.storyboard)
endif()

add_library(storyboard OBJECT ${_platform_specific_storyboard_file})

# Add app
add_executable(
    MPSPathTracingSample MACOSX_BUNDLE
    ${_platform_specific_dir}/AppDelegate.m
    ${_platform_specific_dir}/GameViewController.m
    ${_platform_specific_dir}/main.m
    Renderer.mm
    Scene.mm
    Transforms.mm)

set_property(TARGET MPSPathTracingSample PROPERTY CXX_STANDARD 20)

target_include_directories(MPSPathTracingSample
                           PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_link_libraries(
    MPSPathTracingSample
    PRIVATE "-framework Foundation"
            "-framework Cocoa"
            "-framework QuartzCore"
            "-framework Metal"
            "-framework MetalKit"
            "-framework MetalPerformanceShaders")

# Configure Info.plist
set(EXECUTABLE_NAME MPSPathTracingSample)
set(PRODUCT_BUNDLE_IDENTIFIER com.gkoulin.MPSPathTracingSample)
set(DEVELOPMENT_LANGUAGE en-GB)
configure_file(${_platform_specific_dir}/Info.plist.in ${CMAKE_CURRENT_BINARY_DIR}/Info.plist)

set_target_properties(MPSPathTracingSample PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_BINARY_DIR}/Info.plist)

add_subdirectory(metal)

# Install
include(deployment)

deploy_app(MPSPathTracingSample)
deploy_app_resource(APP_NAME MPSPathTracingSample TARGETS defaultShaderLib)
deploy_app_resource(APP_NAME MPSPathTracingSample FILES $<TARGET_OBJECTS:storyboard>)
