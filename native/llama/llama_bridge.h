#ifndef LLAMA_BRIDGE_H
#define LLAMA_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void* LlamaContextPtr;

LlamaContextPtr llama_init_model(const char* model_path, int n_threads, int n_ctx);
int llama_generate_tokens(LlamaContextPtr ctx, const char* prompt, char* output_buf, int max_output_len);
void llama_free_model(LlamaContextPtr ctx);

#ifdef __cplusplus
}
#endif

#endif // LLAMA_BRIDGE_H
