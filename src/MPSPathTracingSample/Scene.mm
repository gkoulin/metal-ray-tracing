/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation for scene creation functions
*/

#import "Scene.h"

using namespace simd;

std::vector<vector_float3> vertices;
std::vector<vector_float3> normals;
std::vector<uint32_t> masks;
std::vector<uint32_t> vertexToMaterial;
std::vector<Material> materials;

float3 getTriangleNormal(float3 v0, float3 v1, float3 v2)
{
    float3 e1 = normalize(v1 - v0);
    float3 e2 = normalize(v2 - v0);

    return cross(e1, e2);
}

void createCubeFace(std::vector<float3>& vertices,
                    std::vector<float3>& normals,
                    float3* cubeVertices,
                    uint32_t i0,
                    uint32_t i1,
                    uint32_t i2,
                    uint32_t i3,
                    bool inwardNormals,
                    uint32_t triangleMask,
                    uint32_t materialIndex)
{
    float3 v0 = cubeVertices[i0];
    float3 v1 = cubeVertices[i1];
    float3 v2 = cubeVertices[i2];
    float3 v3 = cubeVertices[i3];

    float3 n0 = getTriangleNormal(v0, v1, v2);
    float3 n1 = getTriangleNormal(v0, v2, v3);

    if (inwardNormals)
    {
        n0 = -n0;
        n1 = -n1;
    }

    vertices.push_back(v0);
    vertices.push_back(v1);
    vertices.push_back(v2);
    vertices.push_back(v0);
    vertices.push_back(v2);
    vertices.push_back(v3);

    for (int i = 0; i < 3; i++)
        normals.push_back(n0);

    for (int i = 0; i < 3; i++)
        normals.push_back(n1);

    for (int i = 0; i < 6; i++)
    {
        vertexToMaterial.push_back(materialIndex);
    }

    for (int i = 0; i < 2; i++)
        masks.push_back(triangleMask);
}

bool equals(vector_float3 const& lhs, vector_float3 const& rhs)
{
    return lhs[0] == rhs[0] && lhs[1] == rhs[1] && lhs[2] == rhs[2];
}

bool operator==(Material const& lhs, Material const& rhs)
{
    return lhs.type == rhs.type && equals(lhs.albedo, rhs.albedo) && lhs.roughness == rhs.roughness && lhs.refractiveIndex == rhs.refractiveIndex &&
           lhs.transparency == rhs.transparency;
}

uint32_t addMaterial(Material const& material)
{
    auto findIt = std::find(materials.begin(), materials.end(), material);
    if (findIt != materials.end())
    {
        return std::distance(materials.begin(), findIt);
    }

    materials.push_back(material);
    return materials.size() - 1;
}

void createCube(uint32_t faceMask, matrix_float4x4 transform, bool inwardNormals, uint32_t triangleMask, Material const& material)
{
    auto const materialIndex = addMaterial(material);

    float3 cubeVertices[] = {
        vector3(-0.5f, -0.5f, -0.5f), vector3(0.5f, -0.5f, -0.5f), vector3(-0.5f, 0.5f, -0.5f), vector3(0.5f, 0.5f, -0.5f),
        vector3(-0.5f, -0.5f, 0.5f),  vector3(0.5f, -0.5f, 0.5f),  vector3(-0.5f, 0.5f, 0.5f),  vector3(0.5f, 0.5f, 0.5f),
    };

    for (auto& vertex : cubeVertices)
    {
        float4 transformedVertex = vector4(vertex.x, vertex.y, vertex.z, 1.0f);
        transformedVertex = transform * transformedVertex;

        vertex = transformedVertex.xyz;
    }

    if (faceMask & FACE_MASK_NEGATIVE_X)
        createCubeFace(vertices, normals, cubeVertices, 0, 4, 6, 2, inwardNormals, triangleMask, materialIndex);

    if (faceMask & FACE_MASK_POSITIVE_X)
        createCubeFace(vertices, normals, cubeVertices, 1, 3, 7, 5, inwardNormals, triangleMask, materialIndex);

    if (faceMask & FACE_MASK_NEGATIVE_Y)
        createCubeFace(vertices, normals, cubeVertices, 0, 1, 5, 4, inwardNormals, triangleMask, materialIndex);

    if (faceMask & FACE_MASK_POSITIVE_Y)
        createCubeFace(vertices, normals, cubeVertices, 2, 6, 7, 3, inwardNormals, triangleMask, materialIndex);

    if (faceMask & FACE_MASK_NEGATIVE_Z)
        createCubeFace(vertices, normals, cubeVertices, 0, 2, 3, 1, inwardNormals, triangleMask, materialIndex);

    if (faceMask & FACE_MASK_POSITIVE_Z)
        createCubeFace(vertices, normals, cubeVertices, 4, 5, 7, 6, inwardNormals, triangleMask, materialIndex);
}
