#include "onnx_bridge.h"
#include <cmath>
#include <cstring>

extern "C" {

OnnxSessionPtr onnx_init_session(const char* model_path) {
    if (!model_path) return nullptr;
    return reinterpret_cast<OnnxSessionPtr>(0x2);
}

int onnx_compute_embedding(OnnxSessionPtr session, const char* text, float* embedding_buf, int dim) {
    if (!session || !text || !embedding_buf || dim <= 0) return -1;
    for (int i = 0; i < dim; ++i) {
        embedding_buf[i] = 0.5f;
    }
    return 0;
}

float onnx_cosine_similarity(const float* vec_a, const float* vec_b, int dim) {
    if (!vec_a || !vec_b || dim <= 0) return 0.0f;
    float dot = 0.0f, norm_a = 0.0f, norm_b = 0.0f;
    for (int i = 0; i < dim; ++i) {
        dot += vec_a[i] * vec_b[i];
        norm_a += vec_a[i] * vec_a[i];
        norm_b += vec_b[i] * vec_b[i];
    }
    if (norm_a <= 0.0f || norm_b <= 0.0f) return 0.0f;
    return dot / (sqrtf(norm_a) * sqrtf(norm_b));
}

void onnx_free_session(OnnxSessionPtr session) {
    // Release onnx session
}

}
