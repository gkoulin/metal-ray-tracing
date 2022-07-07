#pragma once

#include <metal_stdlib>

namespace numeric
{

    inline bool nearZero(float3 p)
    {
        // Return true if the vector is close to zero in all dimensions.
        const auto s = 1e-8;
        return (metal::abs(p[0]) < s) && (metal::abs(p[1]) < s) && (metal::abs(p[2]) < s);
    }

    inline float3 reflect(float3 v, float3 n)
    {
        return v - 2 * metal::dot(v, n) * n;
    }

    inline float3 refract(float3 uv, float3 n, float refractionRatio)
    {
        auto const cosTheta = metal::min(metal::dot(-uv, n), 1.0);
        float3 rOutPerp = refractionRatio * (uv + cosTheta * n);
        float3 rOutParallel = -metal::sqrt(metal::abs(1.0 - metal::length_squared(rOutPerp))) * n;
        return rOutPerp + rOutParallel;
    }

    // Schlick's approximation for reflectance.
    float reflectance(float cosine, float refIdx)
    {
        auto r0 = (1 - refIdx) / (1 + refIdx);
        r0 = r0 * r0;
        return r0 + (1 - r0) * metal::pow((1 - cosine), 5);
    }

} // namespace numeric
