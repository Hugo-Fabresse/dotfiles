cmake_minimum_required(VERSION 3.19)
project(caelestia-blobs LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Qml Quick ShaderTools)
qt_standard_project_setup(REQUIRES 6.9)

qt_add_qml_module(caelestia-blobs
    URI Caelestia.Blobs
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Caelestia/Blobs
    SOURCES
        Caelestia/Blobs/blobgroup.cpp
        Caelestia/Blobs/blobgroup.hpp
        Caelestia/Blobs/blobshape.cpp
        Caelestia/Blobs/blobshape.hpp
        Caelestia/Blobs/blobrect.cpp
        Caelestia/Blobs/blobrect.hpp
        Caelestia/Blobs/blobinvertedrect.cpp
        Caelestia/Blobs/blobinvertedrect.hpp
        Caelestia/Blobs/blobmaterial.cpp
        Caelestia/Blobs/blobmaterial.hpp
)

target_link_libraries(caelestia-blobs PRIVATE Qt6::Core Qt6::Qml Qt6::Quick)

# Le générateur d'enregistrement des types QML inclut les headers via
# __has_include(<blobgroup.hpp>) (chemin non préfixé) — il faut donc que le
# dossier des sources soit directement sur le chemin d'inclusion.
target_include_directories(caelestia-blobs PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/Caelestia/Blobs
)

qt_add_shaders(caelestia-blobs "blob_shaders"
    BATCHABLE OPTIMIZED NOHLSL NOMSL
    GLSL "300es,330"
    PREFIX "/"
    BASE "${CMAKE_CURRENT_SOURCE_DIR}/Caelestia/Blobs"
    FILES
        Caelestia/Blobs/shaders/blob.frag
        Caelestia/Blobs/shaders/blob.vert
)
