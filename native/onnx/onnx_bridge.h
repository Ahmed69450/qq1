#ifndef ONNX_BRIDGE_H
#define ONNX_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void* OnnxSessionPtr;

OnnxSessionPtr onnx_init_session(const char* model_path);
int onnx_compute_embedding(OnnxSessionPtr session, const char* text, float* embedding_buf, int dim);
float onnx_cosine_similarity(const float* vec_a, const float* vec_b, int dim);
void onnx_free_session(OnnxSessionPtr session);

#ifdef __cplusplus
}
#endif

#endif // ONNX_BRIDGE_H
