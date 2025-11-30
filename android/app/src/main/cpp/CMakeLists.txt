cmake_minimum_required(VERSION 3.10)
project(face_align_lib VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Build type default
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

# -----------------------------
# Android-specific optimizations
# -----------------------------
if(ANDROID)
    if(CMAKE_BUILD_TYPE STREQUAL "Release")
        add_compile_options(
            -O3
            -ffast-math
            -fno-exceptions
            -fno-rtti
            -fvisibility=hidden
        )

        # Enable NEON SIMD
        if(ANDROID_ABI STREQUAL "armeabi-v7a")
            add_compile_options(-mfpu=neon -mfloat-abi=softfp)
        elseif(ANDROID_ABI STREQUAL "arm64-v8a")
            add_compile_options(-march=armv8-a)
        endif()
    endif()
endif()

# -----------------------------
# Source files
# -----------------------------
set(FACE_ALIGN_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/face_align.cpp
)

# Create shared library
add_library(face_align SHARED ${FACE_ALIGN_SOURCES})

# Include dirs
target_include_directories(face_align
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}
        ${CMAKE_CURRENT_SOURCE_DIR}/include
)

# Warnings
if(MSVC)
    target_compile_options(face_align PRIVATE /W4)
else()
    target_compile_options(face_align PRIVATE 
        -Wall 
        -Wextra 
        -Wno-unused-parameter
    )
endif()

# -----------------------------
# Android Linking
# -----------------------------
if(ANDROID)
    find_library(log-lib log)
    find_library(android-lib android)

    target_link_libraries(face_align
        ${log-lib}
        ${android-lib}
    )
endif()

# Strip symbols for small library size
if(ANDROID AND CMAKE_BUILD_TYPE STREQUAL "Release")
    set_target_properties(face_align PROPERTIES
        LINK_FLAGS_RELEASE "-s"
    )
endif()

# -----------------------------
# OUTPUT DIRECTORY FIX (IMPORTANT)
# Avoid path bugs & guarantee correct jniLibs placement
# -----------------------------
if(ANDROID)
    # Resolve correct absolute path to jniLibs
    get_filename_component(JNI_OUTPUT "${CMAKE_CURRENT_SOURCE_DIR}/../jniLibs/${ANDROID_ABI}" ABSOLUTE)

    file(MAKE_DIRECTORY ${JNI_OUTPUT})

    set_target_properties(face_align PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY ${JNI_OUTPUT}
        RUNTIME_OUTPUT_DIRECTORY ${JNI_OUTPUT}
        ARCHIVE_OUTPUT_DIRECTORY ${JNI_OUTPUT}
    )
endif()
