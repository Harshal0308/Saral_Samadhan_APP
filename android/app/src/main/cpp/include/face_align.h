/**
 * face_align.h
 * 
 * High-performance offline face alignment for ArcFace/MobileFaceNet
 * Uses similarity transform with bilinear interpolation
 * Output: 112x112 RGB uint8 image
 */

 #ifndef FACE_ALIGN_H
#define FACE_ALIGN_H
#pragma once

#include <stdint.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Aligns a face image using similarity transform (rotation + scale + translation).
 * 
 * This function takes facial landmarks and warps the input image to a standard
 * 112x112 aligned face suitable for ArcFace or MobileFaceNet recognition models.
 * 
 * Features:
 * - Bilinear interpolation for smooth output
 * - Inverse transform mapping (no holes)
 * - Optimized for mobile (ARM NEON compatible)
 * - Thread-safe
 * 
 * @param src       Pointer to source RGB image (width * height * 3 bytes)
 *                  Format: R,G,B,R,G,B,... (no padding, row-major)
 * @param width     Width of source image in pixels (must be > 0)
 * @param height    Height of source image in pixels (must be > 0)
 * @param landmarks Array of 10 floats representing 5 facial landmarks:
 *                  [left_eye_x, left_eye_y,
 *                   right_eye_x, right_eye_y,
 *                   nose_x, nose_y,
 *                   left_mouth_x, left_mouth_y,
 *                   right_mouth_x, right_mouth_y]
 *                  Coordinates are in pixel space of the source image
 * 
 * @return          Pointer to newly allocated 112x112x3 RGB image (37,632 bytes)
 *                  Returns NULL on error (invalid input parameters)
 *                  Caller must free using free_aligned_face() or delete[]
 * 
 * @note   This function allocates memory. Always free the result when done.
 * @note   Thread-safe: no shared state, can be called from multiple threads
 * 
 * Example:
 * @code
 *   float landmarks[10] = {
 *     120.5f, 150.2f,  // left eye
 *     180.3f, 148.9f,  // right eye
 *     150.0f, 180.5f,  // nose
 *     130.2f, 210.8f,  // left mouth corner
 *     170.1f, 209.5f   // right mouth corner
 *   };
 *   uint8_t* aligned = align_face(rgb_data, 640, 480, landmarks);
 *   if (aligned) {
 *     // Use aligned face for recognition...
 *     free_aligned_face(aligned);
 *   }
 * @endcode
 */
uint8_t* align_face(
    const uint8_t* src,
    int width,
    int height,
    const float* landmarks
);

/**
 * Frees memory allocated by align_face().
 * 
 * @param aligned Pointer returned by align_face(), or NULL
 * 
 * @note Safe to call with NULL pointer
 */
void free_aligned_face(uint8_t* aligned);

/**
 * Get the output size of aligned faces.
 * 
 * @return Size in pixels (always 112 for ArcFace standard)
 */
int get_aligned_face_size(void);

/**
 * Get the memory size of an aligned face in bytes.
 * 
 * @return Size in bytes (112 * 112 * 3 = 37,632)
 */
size_t get_aligned_face_bytes(void);

/**
 * Align face with custom output size (advanced usage).
 * 
 * @param src        Source RGB image
 * @param width      Source image width
 * @param height     Source image height
 * @param landmarks  5-point facial landmarks (10 floats)
 * @param out_size   Desired output size (e.g., 128, 224)
 * @param template_pts Custom landmark template (10 floats), or NULL for default
 * 
 * @return Newly allocated aligned image of size out_size x out_size x 3
 * 
 * @note Only use if you need non-standard alignment. For ArcFace, use align_face()
 */
uint8_t* align_face_custom(
    const uint8_t* src,
    int width,
    int height,
    const float* landmarks,
    int out_size,
    const float* template_pts
);

#ifdef __cplusplus
}
#endif

#endif /* FACE_ALIGN_H */