/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Header containing types and enum constants shared between Metal shaders and Swift/ObjC source
*/

#ifndef ShaderTypes_h
#define ShaderTypes_h

#include <simd/simd.h>

enum TriangleMask
{
    Geometry = (1 << 0),
    Light = (1 << 1),
    Glass = (1 << 2),
};

enum RayMask
{
    Primary = TriangleMask::Geometry | TriangleMask::Light | TriangleMask::Glass,
    Secondary = TriangleMask::Geometry | TriangleMask::Glass,
    Shadow = TriangleMask::Geometry | TriangleMask::Glass,
};

struct Camera
{
    vector_float3 position;
    vector_float3 right;
    vector_float3 up;
    vector_float3 forward;
};

struct AreaLight
{
    vector_float3 position;
    vector_float3 forward;
    vector_float3 right;
    vector_float3 up;
    vector_float3 color;
};

struct Uniforms
{
    unsigned int width;
    unsigned int height;
    unsigned int frameIndex;
    Camera camera;
    AreaLight light;
};

/// Simple material data.
struct Material
{
    /// Enum bits.
    enum Type
    {
        Lambertian = (1 << 0),
        Metallic = (1 << 1),
        Dielectric = (1 << 2),
        Mirror = (1 << 3),
    };

    /// Material type. Can be combination of two materials where `transparency` will define the amount of each.
    Type type = Type::Lambertian;

    /// Cane be interpreted as color for lambertian material or albedo for metallic material.
    vector_float3 albedo = { 0.f, 0.f, 0.f };

    /// Roughness for metallic material.
    float roughness = 0.f;

    /// Refractive index for dielectric material.
    float refractiveIndex = 1.5f;

    /// Transparency amount. Ratio of dielectric to other.
    float transparency = 0.f;
};

#endif /* ShaderTypes_h */
