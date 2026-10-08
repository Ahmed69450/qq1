#ifndef PIPER_BRIDGE_H
#define PIPER_BRIDGE_H

#ifdef __cplusplus
extern "C" {
#endif

typedef void* PiperVoicePtr;

PiperVoicePtr piper_init_voice(const char* model_path, const char* config_path);
int piper_synthesize_pcm(PiperVoicePtr voice, const char* text, short* audio_buf, int max_samples);
void piper_free_voice(PiperVoicePtr voice);

#ifdef __cplusplus
}
#endif

#endif // PIPER_BRIDGE_H
