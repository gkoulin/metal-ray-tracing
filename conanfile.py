from conans import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake


class MetalraytracingConan(ConanFile):
    name = "metalraytracing"
    version = "0.1.0"

    generators = "cmake_paths"

    # Binary configuration
    settings = "os", "compiler", "build_type", "arch"

    # Sources are located in the same place as this recipe, copy them to the recipe
    exports_sources = "CMakeLists.txt", "src/*", "cmake/*"

    def generate(self):
        if self.settings.os != 'Macos':
            raise RuntimeError(f'Unsupported platform {self.settings.os}')

        tc = CMakeToolchain(self, generator="Ninja")
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()
