/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Implementation for platform independent renderer class
*/

#import <MetalPerformanceShaders/MetalPerformanceShaders.h>
#import <simd/simd.h>

#import "Renderer.h"
#import "Scene.h"
#import "Transforms.h"
#import "metal/ShaderTypes.h"

using namespace simd;

static const NSUInteger maxFramesInFlight = 3;
static const size_t alignedUniformsSize = (sizeof(Uniforms) + 255) & ~255;

static const size_t rayStride = 48;
static const size_t intersectionStride = sizeof(MPSIntersectionDistancePrimitiveIndexCoordinates);

@implementation Renderer
{
    MTKView* _view;
    id<MTLDevice> _device;
    id<MTLCommandQueue> _queue;
    id<MTLLibrary> _library;

    MPSTriangleAccelerationStructure* _accelerationStructure;
    MPSRayIntersector* _intersector;

    id<MTLBuffer> _vertexPositionBuffer;
    id<MTLBuffer> _vertexNormalBuffer;
    id<MTLBuffer> _vertexToMaterialBuffer;
    id<MTLBuffer> _materialBuffer;
    id<MTLBuffer> _rayBuffer;
    id<MTLBuffer> _shadowRayBuffer;
    id<MTLBuffer> _intersectionBuffer;
    id<MTLBuffer> _uniformBuffer;
    id<MTLBuffer> _triangleMaskBuffer;

    id<MTLComputePipelineState> _rayPipeline;
    id<MTLComputePipelineState> _shadePipeline;
    id<MTLComputePipelineState> _shadowPipeline;
    id<MTLComputePipelineState> _accumulatePipeline;
    id<MTLRenderPipelineState> _copyPipeline;

    id<MTLTexture> _renderTargets[2];
    id<MTLTexture> _accumulationTargets[2];
    id<MTLTexture> _randomTexture;

    dispatch_semaphore_t _sem;
    CGSize _size;
    NSUInteger _uniformBufferOffset;
    NSUInteger _uniformBufferIndex;

    unsigned int _frameIndex;
}

- (nonnull instancetype)initWithMetalKitView:(nonnull MTKView*)view;
{
    self = [super init];

    if (self)
    {
        // Metal device was created by platform-specific support code. See iOS/GameViewController.m
        // and macOS/GameViewController.m
        _view = view;
        _device = view.device;

        NSLog(@"Metal device: %@", _device.name);

        _sem = dispatch_semaphore_create(maxFramesInFlight);

        [self loadMetal];
        [self createPipelines];
        [self createScene];
        [self createBuffers];
        [self createIntersector];
    }

    return self;
}

- (void)loadMetal
{
    // Configure view
    _view.colorPixelFormat = MTLPixelFormatRGBA16Float;
    _view.sampleCount = 1;
    _view.drawableSize = _view.frame.size;

    // Create Metal shader library and command queue. Commands will be executed by GPU from this command queue.
    _library = [_device newDefaultLibrary];
    _queue = [_device newCommandQueue];
}

- (void)createPipelines
{
    NSError* error = NULL;

    // Create compute pipelines will will execute code on the GPU
    MTLComputePipelineDescriptor* computeDescriptor = [[MTLComputePipelineDescriptor alloc] init];

    // Set to YES to allow compiler to make certain optimizations
    computeDescriptor.threadGroupSizeIsMultipleOfThreadExecutionWidth = YES;

    // Generates rays according to view/projection matrices
    computeDescriptor.computeFunction = [_library newFunctionWithName:@"rayKernel"];

    _rayPipeline = [_device newComputePipelineStateWithDescriptor:computeDescriptor options:0 reflection:nil error:&error];

    if (!_rayPipeline)
        NSLog(@"Failed to create pipeline state: %@", error);

    // Consumes ray/scene intersection test results to perform shading
    computeDescriptor.computeFunction = [_library newFunctionWithName:@"shadeKernel"];

    _shadePipeline = [_device newComputePipelineStateWithDescriptor:computeDescriptor options:0 reflection:nil error:&error];

    if (!_shadePipeline)
        NSLog(@"Failed to create pipeline state: %@", error);

    // Consumes shadow ray intersection tests to update the output image
    computeDescriptor.computeFunction = [_library newFunctionWithName:@"shadowKernel"];

    _shadowPipeline = [_device newComputePipelineStateWithDescriptor:computeDescriptor options:0 reflection:nil error:&error];

    if (!_shadowPipeline)
        NSLog(@"Failed to create pipeline state: %@", error);

    // Averages the current frame's output image with all previous frames
    computeDescriptor.computeFunction = [_library newFunctionWithName:@"accumulateKernel"];

    _accumulatePipeline = [_device newComputePipelineStateWithDescriptor:computeDescriptor options:0 reflection:nil error:&error];

    if (!_accumulatePipeline)
        NSLog(@"Failed to create pipeline state: %@", error);

    // Copies rendered scene into the MTKView
    MTLRenderPipelineDescriptor* renderDescriptor = [[MTLRenderPipelineDescriptor alloc] init];
    renderDescriptor.sampleCount = _view.sampleCount;
    renderDescriptor.vertexFunction = [_library newFunctionWithName:@"copyVertex"];
    renderDescriptor.fragmentFunction = [_library newFunctionWithName:@"copyFragment"];
    renderDescriptor.colorAttachments[0].pixelFormat = _view.colorPixelFormat;

    _copyPipeline = [_device newRenderPipelineStateWithDescriptor:renderDescriptor error:&error];

    if (!_copyPipeline)
        NSLog(@"Failed to create pipeline state, error %@", error);
}

- (void)createScene
{
    float4x4 transform = matrix4x4_translation(0.0f, 1.0f, 0.0f) * matrix4x4_scale(0.5f, 1.98f, 0.5f);

    float3 const grey{ 0.725f, 0.71f, 0.68f };
    float3 const azure{ 0.70f, 0.85f, 1.f };
    float3 const cambridgeBlue{ 164 / 255.f, 194 / 255.f, 168 / 255.f };
    float3 const forestGreen{ 41 / 255.f, 63 / 255.f, 20 / 255.f };
    float3 const amber{ 255 / 255.f, 125 / 255.f, 0 / 255.f };
    float3 const cadet{ 79 / 255.f, 109 / 255.f, 122 / 255.f };
    float3 const russianViolet{ 47 / 255.f, 24 / 255.f, 71 / 255.f };
    float3 const white{ 1.f, 1.f, 1.f };

    // Light source
    createCube(FACE_MASK_POSITIVE_Y, transform, true, TriangleMask::Light, { Material::Type::Lambertian, white });

    transform = matrix4x4_translation(0.0f, 1.0f, 0.0f) * matrix4x4_scale(2.0f, 2.0f, 2.0f);

    // Top, bottom, and back walls
    createCube(FACE_MASK_NEGATIVE_Y | FACE_MASK_POSITIVE_Y | FACE_MASK_NEGATIVE_Z, transform, true, TriangleMask::Geometry, { Material::Type::Lambertian, grey });

    // Left wall
    createCube(FACE_MASK_NEGATIVE_X, transform, true, TriangleMask::Geometry, { Material::Type::Mirror, white, 0.f });

    // Right wall
    createCube(FACE_MASK_POSITIVE_X, transform, true, TriangleMask::Geometry, { Material::Type::Lambertian, forestGreen });

    transform = matrix4x4_translation(0.3275f, 0.3f, 0.3725f) * matrix4x4_rotation(-0.3f, vector3(0.0f, 1.0f, 0.0f)) * matrix4x4_scale(0.6f, 0.6f, 0.6f);

    // Short box
    createCube(FACE_MASK_ALL, transform, false, TriangleMask::Glass, { Material::Type::Dielectric, amber, 0.f, 1.5f });

    { // small boxes loose pillar
        transform = matrix4x4_translation(0.3275f, 0.8f, 0.3725f) * matrix4x4_rotation(-0.7f, vector3(1.0f, 1.0f, 1.0f)) * matrix4x4_scale(0.2f, 0.2f, 0.2f);
        createCube(FACE_MASK_ALL, transform, false, TriangleMask::Glass, { Material::Type::Dielectric, white, 0.f, 1.8f });

        transform = matrix4x4_translation(0.3275f, 1.1f, 0.3725f) * matrix4x4_rotation(1.3f, vector3(1.0f, 0.0f, 1.0f)) * matrix4x4_scale(0.13f, 0.13f, 0.13f);
        createCube(FACE_MASK_ALL, transform, false, TriangleMask::Glass, { Material::Type::Dielectric, russianViolet, 0.f, 1.8f });

        transform = matrix4x4_translation(0.3275f, 1.35f, 0.3725f) * matrix4x4_rotation(1.3f, vector3(1.0f, 1.0f, 0.0f)) * matrix4x4_scale(0.1f, 0.1f, 0.1f);
        createCube(FACE_MASK_ALL, transform, false, TriangleMask::Glass, { Material::Type::Dielectric, cadet, 0.f, 1.8f });
    }

    transform = matrix4x4_translation(-0.335f, 0.6f, -0.29f) * matrix4x4_rotation(0.3f, vector3(0.0f, 1.0f, 0.0f)) * matrix4x4_scale(0.6f, 1.2f, 0.6f);

    // Tall box
    // createCube(FACE_MASK_ALL, transform, false, TriangleMask::Geometry, { Material::Type::Metallic, russianViolet, 0.03 });
    createCube(FACE_MASK_ALL, transform, false, TriangleMask::Glass, { Material::Type::Dielectric, white, 0.03, 1.5f });
}

- (void)createBuffers
{
    // Uniform buffer contains a few small values which change from frame to frame. We will have up to 3
    // frames in flight at once, so allocate a range of the buffer for each frame. The GPU will read from
    // one chunk while the CPU writes to the next chunk. Each chunk must be aligned to 256 bytes on macOS
    // and 16 bytes on iOS.
    NSUInteger uniformBufferSize = alignedUniformsSize * maxFramesInFlight;

    // Vertex data should be stored in private or managed buffers on discrete GPU systems (AMD, NVIDIA).
    // Private buffers are stored entirely in GPU memory and cannot be accessed by the CPU. Managed
    // buffers maintain a copy in CPU memory and a copy in GPU memory.
    MTLResourceOptions options = 0;

#if !TARGET_OS_IPHONE
    options = MTLResourceStorageModeManaged;
#else
    options = MTLResourceStorageModeShared;
#endif

    _uniformBuffer = [_device newBufferWithLength:uniformBufferSize options:options];

    // Allocate buffers for vertex positions, colors, and normals. Note that each vertex position is a
    // float3, which is a 16 byte aligned type.
    _vertexPositionBuffer = [_device newBufferWithLength:vertices.size() * sizeof(decltype(vertices)::value_type) options:options];
    _vertexToMaterialBuffer = [_device newBufferWithLength:vertexToMaterial.size() * sizeof(decltype(vertexToMaterial)::value_type) options:options];
    _materialBuffer = [_device newBufferWithLength:materials.size() * sizeof(decltype(materials)::value_type) options:options];
    _vertexNormalBuffer = [_device newBufferWithLength:normals.size() * sizeof(decltype(normals)::value_type) options:options];
    _triangleMaskBuffer = [_device newBufferWithLength:masks.size() * sizeof(decltype(masks)::value_type) options:options];

    // Copy vertex data into buffers
    memcpy(_vertexPositionBuffer.contents, vertices.data(), _vertexPositionBuffer.length);
    memcpy(_vertexToMaterialBuffer.contents, vertexToMaterial.data(), _vertexToMaterialBuffer.length);
    memcpy(_materialBuffer.contents, materials.data(), _materialBuffer.length);
    memcpy(_vertexNormalBuffer.contents, normals.data(), _vertexNormalBuffer.length);
    memcpy(_triangleMaskBuffer.contents, masks.data(), _triangleMaskBuffer.length);

    // When using managed buffers, we need to indicate that we modified the buffer so that the GPU
    // copy can be updated
    [_vertexPositionBuffer didModifyRange:NSMakeRange(0, _vertexPositionBuffer.length)];
    [_vertexToMaterialBuffer didModifyRange:NSMakeRange(0, _vertexToMaterialBuffer.length)];
    [_materialBuffer didModifyRange:NSMakeRange(0, _materialBuffer.length)];
    [_vertexNormalBuffer didModifyRange:NSMakeRange(0, _vertexNormalBuffer.length)];
    [_triangleMaskBuffer didModifyRange:NSMakeRange(0, _triangleMaskBuffer.length)];
}

- (void)createIntersector
{
    // Create a raytracer for our Metal device
    _intersector = [[MPSRayIntersector alloc] initWithDevice:_device];

    _intersector.rayDataType = MPSRayDataTypeOriginMaskDirectionMaxDistance;
    _intersector.rayStride = rayStride;
    _intersector.rayMaskOptions = MPSRayMaskOptionPrimitive;

    // Create an acceleration structure from our vertex position data
    _accelerationStructure = [[MPSTriangleAccelerationStructure alloc] initWithDevice:_device];

    _accelerationStructure.vertexBuffer = _vertexPositionBuffer;
    _accelerationStructure.maskBuffer = _triangleMaskBuffer;
    _accelerationStructure.triangleCount = vertices.size() / 3;

    [_accelerationStructure rebuild];
}

- (void)mtkView:(nonnull MTKView*)view drawableSizeWillChange:(CGSize)size
{
    _size = size;

    // Handle window size changes by allocating a buffer large enough to contain one standard ray,
    // one shadow ray, and one ray/triangle intersection result per pixel
    NSUInteger rayCount = (NSUInteger) _size.width * (NSUInteger) _size.height;

    // We use private buffers here because rays and intersection results will be entirely produced
    // and consumed on the GPU
    _rayBuffer = [_device newBufferWithLength:rayStride * rayCount options:MTLResourceStorageModePrivate];
    _shadowRayBuffer = [_device newBufferWithLength:rayStride * rayCount options:MTLResourceStorageModePrivate];
    _intersectionBuffer = [_device newBufferWithLength:intersectionStride * rayCount options:MTLResourceStorageModePrivate];

    // Create a render target which the shading kernel can write to
    MTLTextureDescriptor* renderTargetDescriptor = [[MTLTextureDescriptor alloc] init];

    renderTargetDescriptor.pixelFormat = MTLPixelFormatRGBA32Float;
    renderTargetDescriptor.textureType = MTLTextureType2D;
    renderTargetDescriptor.width = size.width;
    renderTargetDescriptor.height = size.height;

    // Stored in private memory because it will only be read and written from the GPU
    renderTargetDescriptor.storageMode = MTLStorageModePrivate;

    // Indicate that we will read and write the texture from the GPU
    renderTargetDescriptor.usage = MTLTextureUsageShaderRead | MTLTextureUsageShaderWrite;

    for (NSUInteger i = 0; i < 2; i++)
    {
        _renderTargets[i] = [_device newTextureWithDescriptor:renderTargetDescriptor];
        _accumulationTargets[i] = [_device newTextureWithDescriptor:renderTargetDescriptor];
    }

    renderTargetDescriptor.pixelFormat = MTLPixelFormatR32Uint;
    renderTargetDescriptor.usage = MTLTextureUsageShaderRead;
#if !TARGET_OS_IPHONE
    renderTargetDescriptor.storageMode = MTLStorageModeManaged;
#else
    renderTargetDescriptor.storageMode = MTLStorageModeShared;
#endif

    // Generate a texture containing a random integer value for each pixel. This value
    // will be used to decorrelate pixels while drawing pseudorandom numbers from the
    // Halton sequence.
    _randomTexture = [_device newTextureWithDescriptor:renderTargetDescriptor];

    uint32_t* randomValues = (uint32_t*) malloc(sizeof(uint32_t) * size.width * size.height);

    for (NSUInteger i = 0; i < size.width * size.height; i++)
        randomValues[i] = rand() % (1024 * 1024);

    [_randomTexture replaceRegion:MTLRegionMake2D(0, 0, size.width, size.height)
                      mipmapLevel:0
                        withBytes:randomValues
                      bytesPerRow:sizeof(uint32_t) * size.width];

    free(randomValues);

    _frameIndex = 0;
}

- (void)updateUniforms
{
    // Update this frame's uniforms
    _uniformBufferOffset = alignedUniformsSize * _uniformBufferIndex;

    Uniforms* uniforms = (Uniforms*) ((char*) _uniformBuffer.contents + _uniformBufferOffset);

    uniforms->camera.position = vector3(0.0f, 1.0f, 3.38f);

    uniforms->camera.forward = vector3(0.0f, 0.0f, -1.0f);
    uniforms->camera.right = vector3(1.0f, 0.0f, 0.0f);
    uniforms->camera.up = vector3(0.0f, 1.0f, 0.0f);

    uniforms->light.position = vector3(0.0f, 1.98f, 0.0f);
    uniforms->light.forward = vector3(0.0f, -1.0f, 0.0f);
    uniforms->light.right = vector3(0.25f, 0.0f, 0.0f);
    uniforms->light.up = vector3(0.0f, 0.0f, 0.25f);
    uniforms->light.color = vector3(4.0f, 4.0f, 4.0f);

    float fieldOfView = 45.0f * (M_PI / 180.0f);
    float aspectRatio = (float) _size.width / (float) _size.height;
    float imagePlaneHeight = tanf(fieldOfView / 2.0f);
    float imagePlaneWidth = aspectRatio * imagePlaneHeight;

    uniforms->camera.right *= imagePlaneWidth;
    uniforms->camera.up *= imagePlaneHeight;

    uniforms->width = (unsigned int) _size.width;
    uniforms->height = (unsigned int) _size.height;

    uniforms->frameIndex = _frameIndex++;

#if !TARGET_OS_IPHONE
    [_uniformBuffer didModifyRange:NSMakeRange(_uniformBufferOffset, alignedUniformsSize)];
#endif

    // Advance to the next slot in the uniform buffer
    _uniformBufferIndex = (_uniformBufferIndex + 1) % maxFramesInFlight;
}

- (void)drawInMTKView:(nonnull MTKView*)view
{
    // We are using the uniform buffer to stream uniform data to the GPU, so we need to wait until the oldest
    // GPU frame has completed before we can reuse that space in the buffer.
    dispatch_semaphore_wait(_sem, DISPATCH_TIME_FOREVER);

    // Create a command buffer which will contain our GPU commands
    id<MTLCommandBuffer> commandBuffer = [_queue commandBuffer];

    // When the frame has finished, signal that we can reuse the uniform buffer space from this frame.
    // Note that the contents of completion handlers should be as fast as possible as the GPU driver may
    // have other work scheduled on the underlying dispatch queue.
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
      dispatch_semaphore_signal(self->_sem);
    }];

    [self updateUniforms];

    NSUInteger width = (NSUInteger) _size.width;
    NSUInteger height = (NSUInteger) _size.height;

    // We will launch a rectangular grid of threads on the GPU to generate the rays. Threads are launched in
    // groups called "threadgroups". We need to align the number of threads to be a multiple of the threadgroup
    // size. We indicated when compiling the pipeline that the threadgroup size would be a multiple of the thread
    // execution width (SIMD group size) which is typically 32 or 64 so 8x8 is a safe threadgroup size which
    // should be small to be supported on most devices. A more advanced application would choose the threadgroup
    // size dynamically.
    MTLSize threadsPerThreadgroup = MTLSizeMake(8, 8, 1);
    MTLSize threadgroups = MTLSizeMake((width + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width,
                                       (height + threadsPerThreadgroup.height - 1) / threadsPerThreadgroup.height,
                                       1);

    // First, we will generate rays on the GPU. We create a compute command encoder which will be used to add
    // commands to the command buffer.
    id<MTLComputeCommandEncoder> computeEncoder = [commandBuffer computeCommandEncoder];

    // Bind buffers needed by the compute pipeline
    [computeEncoder setBuffer:_uniformBuffer offset:_uniformBufferOffset atIndex:0];
    [computeEncoder setBuffer:_rayBuffer offset:0 atIndex:1];

    [computeEncoder setTexture:_randomTexture atIndex:0];
    [computeEncoder setTexture:_renderTargets[0] atIndex:1];

    // Bind the ray generation compute pipeline
    [computeEncoder setComputePipelineState:_rayPipeline];

    // Launch threads
    [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadsPerThreadgroup];

    // End the encoder
    [computeEncoder endEncoding];

    // We will iterate over the next few kernels several times to allow light to bounce around the scene
    for (int bounce = 0; bounce < 8; bounce++)
    {
        _intersector.intersectionDataType = MPSIntersectionDataTypeDistancePrimitiveIndexCoordinates;

        // We can then pass the rays to the MPSRayIntersector to compute the intersections with our acceleration structure
        [_intersector encodeIntersectionToCommandBuffer:commandBuffer              // Command buffer to encode into
                                       intersectionType:MPSIntersectionTypeNearest // Intersection test type
                                              rayBuffer:_rayBuffer                 // Ray buffer
                                        rayBufferOffset:0                          // Offset into ray buffer
                                     intersectionBuffer:_intersectionBuffer        // Intersection buffer (destination)
                               intersectionBufferOffset:0                          // Offset into intersection buffer
                                               rayCount:width * height             // Number of rays
                                  accelerationStructure:_accelerationStructure];   // Acceleration structure
        // We launch another pipeline to consume the intersection results and shade the scene
        computeEncoder = [commandBuffer computeCommandEncoder];

        [computeEncoder setBuffer:_uniformBuffer offset:_uniformBufferOffset atIndex:0];
        [computeEncoder setBuffer:_rayBuffer offset:0 atIndex:1];
        [computeEncoder setBuffer:_shadowRayBuffer offset:0 atIndex:2];
        [computeEncoder setBuffer:_intersectionBuffer offset:0 atIndex:3];
        [computeEncoder setBuffer:_vertexToMaterialBuffer offset:0 atIndex:4];
        [computeEncoder setBuffer:_materialBuffer offset:0 atIndex:5];
        [computeEncoder setBuffer:_vertexNormalBuffer offset:0 atIndex:6];
        [computeEncoder setBuffer:_triangleMaskBuffer offset:0 atIndex:7];
        [computeEncoder setBytes:&bounce length:sizeof(bounce) atIndex:8];

        [computeEncoder setTexture:_randomTexture atIndex:0];
        [computeEncoder setTexture:_renderTargets[0] atIndex:1];

        [computeEncoder setComputePipelineState:_shadePipeline];

        [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadsPerThreadgroup];

        [computeEncoder endEncoding];

        // We intersect rays with the scene, except this time we are intersecting shadow rays. We only need
        // to know whether the shadows rays hit anything on the way to the light source, not which triangle
        // was intersected. Therefore, we can use the "any" intersection type to end the intersection search
        // as soon as any intersection is found. This is typically much faster than finding the nearest
        // intersection. We can also use MPSIntersectionDataTypeDistance, because we don't need the triangle
        // index and barycentric coordinates.
        _intersector.intersectionDataType = MPSIntersectionDataTypeDistance;

        [_intersector encodeIntersectionToCommandBuffer:commandBuffer
                                       intersectionType:MPSIntersectionTypeAny
                                              rayBuffer:_shadowRayBuffer
                                        rayBufferOffset:0
                                     intersectionBuffer:_intersectionBuffer
                               intersectionBufferOffset:0
                                               rayCount:width * height
                                  accelerationStructure:_accelerationStructure];

        // Finally, we launch a kernel which writes the color computed by the shading kernel into the
        // output image, but only if the corresponding shadow ray does not intersect anything on the way to
        // the light. If the shadow ray intersects a triangle before reaching the light source, the original
        // intersection point was in shadow.
        computeEncoder = [commandBuffer computeCommandEncoder];

        [computeEncoder setBuffer:_uniformBuffer offset:_uniformBufferOffset atIndex:0];
        [computeEncoder setBuffer:_shadowRayBuffer offset:0 atIndex:1];
        [computeEncoder setBuffer:_intersectionBuffer offset:0 atIndex:2];

        [computeEncoder setTexture:_renderTargets[0] atIndex:0];
        [computeEncoder setTexture:_renderTargets[1] atIndex:1];

        [computeEncoder setComputePipelineState:_shadowPipeline];

        [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadsPerThreadgroup];

        [computeEncoder endEncoding];

        std::swap(_renderTargets[0], _renderTargets[1]);
    }

    // The final kernel averages the current frame's image with all previous frames to reduce noise due
    // random sampling of the scene.
    computeEncoder = [commandBuffer computeCommandEncoder];

    [computeEncoder setBuffer:_uniformBuffer offset:_uniformBufferOffset atIndex:0];

    [computeEncoder setTexture:_renderTargets[0] atIndex:0];
    [computeEncoder setTexture:_accumulationTargets[0] atIndex:1];
    [computeEncoder setTexture:_accumulationTargets[1] atIndex:2];

    [computeEncoder setComputePipelineState:_accumulatePipeline];

    [computeEncoder dispatchThreadgroups:threadgroups threadsPerThreadgroup:threadsPerThreadgroup];

    [computeEncoder endEncoding];

    std::swap(_accumulationTargets[0], _accumulationTargets[1]);

    // Copy the resulting image into our view using the graphics pipeline since we can't write directly to
    // it with a compute kernel. We need to delay getting the current render pass descriptor as long as
    // possible to avoid stalling until the GPU/compositor release a drawable. The render pass descriptor
    // may be nil if the window has moved off screen.
    MTLRenderPassDescriptor* renderPassDescriptor = view.currentRenderPassDescriptor;

    if (renderPassDescriptor != nil)
    {
        // Create a render encoder
        id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];

        [renderEncoder setRenderPipelineState:_copyPipeline];

        [renderEncoder setFragmentTexture:_accumulationTargets[0] atIndex:0];

        // Draw a quad which fills the screen
        [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];

        [renderEncoder endEncoding];

        // Present the drawable to the screen
        [commandBuffer presentDrawable:view.currentDrawable];
    }

    // Finally, commit the command buffer so that the GPU can start executing
    [commandBuffer commit];

    [commandBuffer waitUntilCompleted];
}

@end
