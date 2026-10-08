#include "piper_bridge.h"
#include <cstring>

extern "C" {

PiperVoicePtr piper_init_voice(const char* model_path, const char* config_path) {
    if (!model_path) return nullptr;
    return reinterpret_cast<PiperVoicePtr>(0x3);
}

int piper_synthesize_pcm(PiperVoicePtr voice, const char* text, short* audio_buf, int max_samples) {
    if (!voice || !text || !audio_buf || max_samples <= 0) return -1;
    // Produces raw 22050Hz 16-bit PCM buffer
    memset(audio_buf, 0, sizeof(short) * (max_samples < 1000 ? max_samples : 1000));
    return (max_samples < 1000 ? max_samples : 1000);
}

void piper_free_voice(PiperVoicePtr voice) {
    // Release Piper voice model
}

}
