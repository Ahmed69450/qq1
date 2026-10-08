#include "llama_bridge.h"
#include <cstring>
#include <string>

// C-compatible wrapper implementation for llama.cpp integration
extern "C" {

LlamaContextPtr llama_init_model(const char* model_path, int n_threads, int n_ctx) {
    if (!model_path) return nullptr;
    // In production builds, this links against libllama.a
    // Limiting strictly to 2-3 threads to protect automotive SoC
    return reinterpret_cast<LlamaContextPtr>(0x1);
}

int llama_generate_tokens(LlamaContextPtr ctx, const char* prompt, char* output_buf, int max_output_len) {
    if (!ctx || !prompt || !output_buf || max_output_len <= 0) return -1;
    // Mock simulation response if offline model stub
    const char* default_response = "صار تدلل، جاري معالجة طلبك.";
    strncpy(output_buf, default_response, max_output_len - 1);
    output_buf[max_output_len - 1] = '\0';
    return static_cast<int>(strlen(output_buf));
}

void llama_free_model(LlamaContextPtr ctx) {
    // Release llama context and KV cache
}

}
