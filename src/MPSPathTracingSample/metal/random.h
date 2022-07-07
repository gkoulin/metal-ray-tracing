#pragma once

#include <metal_stdlib>

namespace random
{

    /// Random number generator in thread address space. Uses the Halton sequence pseudo-random numbers. The Halton sequence is a "low discrepency" sequence:
    /// the values appear random but are more evenly distributed then a purely random sequence. Each random value used to render the image should use a
    /// different independent dimension 'd', and each sample (frame) should use a different index 'i'. To decorrelate each pixel, a random offset can be applied
    /// to 'i'.
    class RandomNumberGenerator
    {
    public:
        /// Constructor.
        ///
        /// \param startingI Starting index to query.
        /// \param dimension Zero-th dimension.
        /// \return thread
        thread RandomNumberGenerator(const unsigned int startingI, const unsigned int dimension);

        /// Generate a random float in the set [0,1).
        ///
        /// \return Random float.
        thread float randomFloat();

        /// Generate a random float in the set [min,max).
        ///
        /// \param min Minimum limit.
        /// \param max Maximum limit.
        /// \return float Random number.
        thread float randomFloat(float min, float max);

        /// Generate a random float3 in the set [0,1).
        ///
        /// \return float3 Random vector.
        thread float3 randomFloat3();

        /// Generate a random float3 in the set [min,max).
        ///
        /// \param min Minimum limit.
        /// \param max Maximum limit.
        /// \return float3 Random vector.
        thread float3 randomFloat3(float min, float max);

    private:
        thread unsigned int i, d;

        thread float randomFloat(unsigned int const incrementDimension);

        thread float randomFloat(unsigned int incrementDimension, float min, float max);
    };

    /// Generate a random vector inside a unit sphere.
    ///
    /// \param rng Random number generator to use.
    /// \return float3 Random vector.
    inline float3 randomInUnitSphere(thread RandomNumberGenerator& rng)
    {
        while (true)
        {
            auto const p = rng.randomFloat3(-1.f, 1.f);
            if (metal::length_squared(p) >= 1)
            {
                continue;
            }

            return p;
        }
    }

    /// Generate a random unit vector.
    ///
    /// \param rng Random number generator to use.
    /// \return float3 Random vector.
    inline float3 randomUnitVector(thread RandomNumberGenerator& rng)
    {
        return metal::normalize(randomInUnitSphere(rng));
    }

} // namespace random
