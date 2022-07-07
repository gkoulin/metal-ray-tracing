/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header for scene creation functions
*/

#ifndef Scene_h
#define Scene_h

#include "metal/ShaderTypes.h"
#include <simd/simd.h>
#include <vector>

extern std::vector<vector_float3> vertices;
extern std::vector<vector_float3> normals;
extern std::vector<vector_float3> colors;
extern std::vector<uint32_t> masks;
extern std::vector<uint32_t> vertexToMaterial;
extern std::vector<Material> materials;

#define FACE_MASK_NONE 0
#define FACE_MASK_NEGATIVE_X (1 << 0)
#define FACE_MASK_POSITIVE_X (1 << 1)
#define FACE_MASK_NEGATIVE_Y (1 << 2)
#define FACE_MASK_POSITIVE_Y (1 << 3)
#define FACE_MASK_NEGATIVE_Z (1 << 4)
#define FACE_MASK_POSITIVE_Z (1 << 5)
#define FACE_MASK_ALL ((1 << 6) - 1)

void createCube(unsigned int faceMask, matrix_float4x4 transform, bool inwardNormals, unsigned int triangleMask, Material const& material);

#endif /* Scene_h */
