#include "random.h"

namespace random
{
    namespace
    {

        constant unsigned int primes[] = {
            2, 3, 5, 7, 11, 13, 17, 19, 23, 29, 31, 37, 41, 43, 47, 53,
        };

        constant unsigned int kNPrimes = 16;

        // Returns the i'th element of the Halton sequence using the d'th prime number as a
        // base. The Halton sequence is a "low discrepency" sequence: the values appear
        // random but are more evenly distributed then a purely random sequence. Each random
        // value used to render the image should use a different independent dimension 'd',
        // and each sample (frame) should use a different index 'i'. To decorrelate each
        // pixel, a random offset can be applied to 'i'.
        inline float halton(unsigned int i, unsigned int d)
        {
            unsigned int b = primes[d];

            float f = 1.0f;
            float invB = 1.0f / b;

            float r = 0;

            while (i > 0)
            {
                f = f * invB;
                r = r + f * (i % b);
                i = i * invB;
            }

            return r;
        }

    } // namespace

    thread RandomNumberGenerator::RandomNumberGenerator(const unsigned int startingI, const unsigned int dimension) : i(startingI), d(dimension % kNPrimes)
    {
    }

    thread float RandomNumberGenerator::randomFloat()
    {
        return randomFloat(0);
    }

    thread float RandomNumberGenerator::randomFloat(float min, float max)
    {
        return randomFloat(0, min, max);
    }

    thread float RandomNumberGenerator::randomFloat(unsigned int const incrementDimension)
    {
        return halton(++i, (d + incrementDimension) % kNPrimes);
    }

    thread float RandomNumberGenerator::randomFloat(unsigned int incrementDimension, float min, float max)
    {
        // Returns a random real in [min, max).
        return min + (max - min) * randomFloat(incrementDimension);
    }

    thread float3 RandomNumberGenerator::randomFloat3()
    {
        return { randomFloat(0), randomFloat(1), randomFloat(2) };
    }

    thread float3 RandomNumberGenerator::randomFloat3(float min, float max)
    {
        return { randomFloat(0, min, max), randomFloat(1, min, max), randomFloat(2, min, max) };
    }

} // namespace random
