# Add default Metal shaders lib
add_library(defaultShaderLib SHARED Shaders.metal random.metal)
set_target_properties(defaultShaderLib PROPERTIES OUTPUT_NAME "default")
