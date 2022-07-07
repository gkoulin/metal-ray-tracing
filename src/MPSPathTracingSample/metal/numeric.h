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

} // namespace numeric
