#include "include/face_align.h"
#include <cmath>
#include <algorithm>

/**
 * High-accuracy face alignment using similarity transform with bilinear interpolation
 * Optimized for ArcFace/MobileFaceNet (112x112 output)
 */

static const int OUT_SIZE = 112;

// ArcFace landmark template (5 points: left_eye, right_eye, nose, left_mouth, right_mouth)
static const float TEMPLATE[10] = {
    38.2946f, 51.6963f,  // left eye
    73.5318f, 51.5014f,  // right eye
    56.0252f, 71.7366f,  // nose
    41.5493f, 92.3655f,  // left mouth
    70.7299f, 92.2041f   // right mouth
};

struct Mat2x3 {
    float m[6];
};

// Compute inverse similarity transform (dst -> src mapping for accurate warping)
static Mat2x3 estimate_inverse_transform(const float* src_pts) {
    // Calculate means
    float src_mean_x = 0, src_mean_y = 0;
    float dst_mean_x = 0, dst_mean_y = 0;
    
    for (int i = 0; i < 5; i++) {
        src_mean_x += src_pts[i * 2];
        src_mean_y += src_pts[i * 2 + 1];
        dst_mean_x += TEMPLATE[i * 2];
        dst_mean_y += TEMPLATE[i * 2 + 1];
    }
    
    src_mean_x /= 5.0f;
    src_mean_y /= 5.0f;
    dst_mean_x /= 5.0f;
    dst_mean_y /= 5.0f;
    
    // Center the points
    float src_centered[10], dst_centered[10];
    for (int i = 0; i < 5; i++) {
        src_centered[i * 2] = src_pts[i * 2] - src_mean_x;
        src_centered[i * 2 + 1] = src_pts[i * 2 + 1] - src_mean_y;
        dst_centered[i * 2] = TEMPLATE[i * 2] - dst_mean_x;
        dst_centered[i * 2 + 1] = TEMPLATE[i * 2 + 1] - dst_mean_y;
    }
    
    // Compute scale
    float src_norm = 0, dst_norm = 0;
    for (int i = 0; i < 5; i++) {
        src_norm += src_centered[i * 2] * src_centered[i * 2] + 
                    src_centered[i * 2 + 1] * src_centered[i * 2 + 1];
        dst_norm += dst_centered[i * 2] * dst_centered[i * 2] + 
                    dst_centered[i * 2 + 1] * dst_centered[i * 2 + 1];
    }
    
    float scale = sqrtf(dst_norm / src_norm);
    
    // Compute rotation angle using cross and dot products
    float num = 0, den = 0;
    for (int i = 0; i < 5; i++) {
        float xs = src_centered[i * 2];
        float ys = src_centered[i * 2 + 1];
        float xd = dst_centered[i * 2];
        float yd = dst_centered[i * 2 + 1];
        
        num += xs * yd - ys * xd;  // cross product
        den += xs * xd + ys * yd;  // dot product
    }
    
    float theta = atan2f(num, den);
    float cos_theta = cosf(theta);
    float sin_theta = sinf(theta);
    
    // Build forward transform: src -> dst
    float a = scale * cos_theta;
    float b = -scale * sin_theta;
    float c = scale * sin_theta;
    float d = scale * cos_theta;
    float tx = dst_mean_x - (a * src_mean_x + b * src_mean_y);
    float ty = dst_mean_y - (c * src_mean_x + d * src_mean_y);
    
    // Compute inverse transform: dst -> src (for backward mapping)
    // For similarity transform: inv = [1/scale * R^T, -1/scale * R^T * t]
    float det = a * d - b * c;
    
    Mat2x3 inv;
    inv.m[0] = d / det;
    inv.m[1] = -b / det;
    inv.m[2] = (b * ty - d * tx) / det;
    inv.m[3] = -c / det;
    inv.m[4] = a / det;
    inv.m[5] = (c * tx - a * ty) / det;
    
    return inv;
}

// Bilinear interpolation for higher quality
static inline void bilinear_sample(
    const uint8_t* src,
    int width,
    int height,
    float x,
    float y,
    uint8_t* out
) {
    // Clamp to valid range
    if (x < 0 || y < 0 || x >= width - 1 || y >= height - 1) {
        out[0] = out[1] = out[2] = 0;
        return;
    }
    
    int x0 = (int)x;
    int y0 = (int)y;
    int x1 = x0 + 1;
    int y1 = y0 + 1;
    
    float dx = x - x0;
    float dy = y - y0;
    float dx1 = 1.0f - dx;
    float dy1 = 1.0f - dy;
    
    const uint8_t* p00 = src + (y0 * width + x0) * 3;
    const uint8_t* p01 = src + (y0 * width + x1) * 3;
    const uint8_t* p10 = src + (y1 * width + x0) * 3;
    const uint8_t* p11 = src + (y1 * width + x1) * 3;
    
    for (int c = 0; c < 3; c++) {
        float val = p00[c] * dx1 * dy1 +
                    p01[c] * dx * dy1 +
                    p10[c] * dx1 * dy +
                    p11[c] * dx * dy;
        out[c] = (uint8_t)std::min(255.0f, std::max(0.0f, val + 0.5f));
    }
}

// Warp using inverse mapping (dst -> src) with bilinear interpolation
static void warp_affine(
    const uint8_t* src,
    uint8_t* dst,
    int width,
    int height,
    const Mat2x3& inv_tf
) {
    for (int y = 0; y < OUT_SIZE; y++) {
        for (int x = 0; x < OUT_SIZE; x++) {
            // Map destination pixel to source coordinates
            float src_x = inv_tf.m[0] * x + inv_tf.m[1] * y + inv_tf.m[2];
            float src_y = inv_tf.m[3] * x + inv_tf.m[4] * y + inv_tf.m[5];
            
            uint8_t* out_pixel = dst + (y * OUT_SIZE + x) * 3;
            bilinear_sample(src, width, height, src_x, src_y, out_pixel);
        }
    }
}

extern "C" uint8_t* align_face(
    const uint8_t* src,
    int width,
    int height,
    const float* landmarks
) {
    if (!src || !landmarks || width <= 0 || height <= 0) {
        return nullptr;
    }
    
    uint8_t* result = new uint8_t[OUT_SIZE * OUT_SIZE * 3];
    
    // Compute inverse transform for backward mapping
    Mat2x3 inv_tf = estimate_inverse_transform(landmarks);
    
    // Perform warping with bilinear interpolation
    warp_affine(src, result, width, height, inv_tf);
    
    return result;
}

// Free aligned face memory
extern "C" void free_aligned_face(uint8_t* aligned) {
    delete[] aligned;
}

// Get output size
extern "C" int get_aligned_face_size(void) {
    return OUT_SIZE;
}

// Get output size in bytes
extern "C" size_t get_aligned_face_bytes(void) {
    return OUT_SIZE * OUT_SIZE * 3;
}

// Custom alignment with configurable output size
extern "C" uint8_t* align_face_custom(
    const uint8_t* src,
    int width,
    int height,
    const float* landmarks,
    int out_size,
    const float* template_pts
) {
    if (!src || !landmarks || width <= 0 || height <= 0 || out_size <= 0) {
        return nullptr;
    }
    
    // Use provided template or default
    const float* tmpl = template_pts ? template_pts : TEMPLATE;
    
    uint8_t* result = new uint8_t[out_size * out_size * 3];
    
    // Scale template to output size if different from 112
    float scale_factor = (float)out_size / OUT_SIZE;
    float scaled_template[10];
    if (scale_factor != 1.0f) {
        for (int i = 0; i < 10; i++) {
            scaled_template[i] = tmpl[i] * scale_factor;
        }
        tmpl = scaled_template;
    }
    
    // Compute transform using scaled template
    float src_mean_x = 0, src_mean_y = 0;
    float dst_mean_x = 0, dst_mean_y = 0;
    
    for (int i = 0; i < 5; i++) {
        src_mean_x += landmarks[i * 2];
        src_mean_y += landmarks[i * 2 + 1];
        dst_mean_x += tmpl[i * 2];
        dst_mean_y += tmpl[i * 2 + 1];
    }
    
    src_mean_x /= 5.0f;
    src_mean_y /= 5.0f;
    dst_mean_x /= 5.0f;
    dst_mean_y /= 5.0f;
    
    float src_centered[10], dst_centered[10];
    for (int i = 0; i < 5; i++) {
        src_centered[i * 2] = landmarks[i * 2] - src_mean_x;
        src_centered[i * 2 + 1] = landmarks[i * 2 + 1] - src_mean_y;
        dst_centered[i * 2] = tmpl[i * 2] - dst_mean_x;
        dst_centered[i * 2 + 1] = tmpl[i * 2 + 1] - dst_mean_y;
    }
    
    float src_norm = 0, dst_norm = 0;
    for (int i = 0; i < 5; i++) {
        src_norm += src_centered[i * 2] * src_centered[i * 2] + 
                    src_centered[i * 2 + 1] * src_centered[i * 2 + 1];
        dst_norm += dst_centered[i * 2] * dst_centered[i * 2] + 
                    dst_centered[i * 2 + 1] * dst_centered[i * 2 + 1];
    }
    
    float scale = sqrtf(dst_norm / src_norm);
    
    float num = 0, den = 0;
    for (int i = 0; i < 5; i++) {
        num += src_centered[i * 2] * dst_centered[i * 2 + 1] - 
               src_centered[i * 2 + 1] * dst_centered[i * 2];
        den += src_centered[i * 2] * dst_centered[i * 2] + 
               src_centered[i * 2 + 1] * dst_centered[i * 2 + 1];
    }
    
    float theta = atan2f(num, den);
    float cos_theta = cosf(theta);
    float sin_theta = sinf(theta);
    
    float a = scale * cos_theta;
    float b = -scale * sin_theta;
    float c = scale * sin_theta;
    float d = scale * cos_theta;
    float tx = dst_mean_x - (a * src_mean_x + b * src_mean_y);
    float ty = dst_mean_y - (c * src_mean_x + d * src_mean_y);
    
    float det = a * d - b * c;
    Mat2x3 inv;
    inv.m[0] = d / det;
    inv.m[1] = -b / det;
    inv.m[2] = (b * ty - d * tx) / det;
    inv.m[3] = -c / det;
    inv.m[4] = a / det;
    inv.m[5] = (c * tx - a * ty) / det;
    
    // Warp with custom size
    for (int y = 0; y < out_size; y++) {
        for (int x = 0; x < out_size; x++) {
            float src_x = inv.m[0] * x + inv.m[1] * y + inv.m[2];
            float src_y = inv.m[3] * x + inv.m[4] * y + inv.m[5];
            
            uint8_t* out_pixel = result + (y * out_size + x) * 3;
            bilinear_sample(src, width, height, src_x, src_y, out_pixel);
        }
    }
    
    return result;
}