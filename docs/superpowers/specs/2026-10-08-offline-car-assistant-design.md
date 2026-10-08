# Architecture & Design Specification: Offline Hybrid Voice Assistant for BYD DiLink

**Date:** 2026-10-08  
**Target Platform:** BYD DiLink Head Unit (Android 10+, Snapdragon 665 / 6125 or equivalent, 4GB-8GB RAM)  
**Primary Language:** Arabic (Modern Standard Arabic & Iraqi Dialect)  
**Status:** Approved by User  

---

## 1. Executive Summary & Objective

The Offline Hybrid Voice Assistant is a completely on-device, zero-cloud dependent voice assistant tailored for automotive head units, specifically BYD DiLink running Android 10+. The system provides responsive hands-free vehicle control, situational awareness, conversational intelligence, and local speech synthesis while strictly respecting the hardware and thermal boundaries of automotive SoCs.

Key highlights:
- **100% Offline Operation:** No internet connectivity required for any core feature.
- **Dual-Engine Architecture:** Sub-150ms execution for vehicle hardware commands via a fast semantic router (Engine A), backed by a lightweight GGUF LLM fallback (Engine B).
- **Native Android Stability:** Foreground service audio capture with low-overhead keyword spotting (Vosk C-API), non-intrusive bottom capsule overlay, and native BYD vendor intent dispatching.
- **Strict Arabic Pipeline:** Tokenizers, Arabic text normalizers, dialect stopword support, and phonetic sanitization for Piper TTS.
- **Flexible Model Management:** User freedom to import arbitrary `.gguf` and `.onnx` models from internal storage or external USB drives.

---

## 2. High-Level System Architecture

The project employs a decoupled hybrid architecture dividing responsibilities across three critical layers:
1. **Android Native Service Layer (Kotlin):** Permanent background audio monitoring, system accessibility tree inspection, overlay window hosting, and automotive vendor broadcasts.
2. **Native C/C++ AI Engine Layer (Dart FFI):** High-performance execution of ONNX Runtime, llama.cpp, and Piper TTS via direct memory pointers and isolates.
3. **Flutter Application & Presentation Layer (Dart):** Clean Architecture implementation containing domain logic, state management, HUD capsule overlay UI, and the full settings dashboard.

```
+-----------------------------------------------------------------------------------+
|                            Android 10+ Automotive OS                              |
+-----------------------------------------------------------------------------------+
| [Microphone] -> [VoiceForegroundService] (Vosk C-API KWS / Arabic Small Model)    |
| [Display]    -> [CarAccessibilityService] (Screen Tree Node Inspector)            |
| [Vehicle]    -> [CarIntentDispatcher] (BYD Broadcast Intents & Mock Fallback)     |
| [Overlay]    -> [WindowOverlayManager] (Hosts Flutter Engine EntryPoint)          |
+----------------------------------------+------------------------------------------+
                                         | MethodChannels & EventChannels
                                         v
+-----------------------------------------------------------------------------------+
|                        Flutter Presentation & Domain (Dart)                       |
+-----------------------------------------------------------------------------------+
| - Overlay UI: Bottom Capsule Floating HUD (Waveform, Live Text, Quick Dismiss)    |
| - Settings UI: Model Manager (USB/Storage Picker), Vosk Grammar Editor, Sandbox   |
| - Normalizer: Arabic Text Normalizer (Unicode 0600-06FF, Iraqi Stopwords)        |
| - Intent Router: Orchestrates Engine A vs. Engine B based on confidence           |
| - Local DB: sqflite (UserFacts, Driver Preferences, Conversation History)        |
| - MCP Client: In-process Car Tool Dispatcher & Optional SSE Web Search client    |
+----------------------------------------+------------------------------------------+
                                         | Dart FFI (Separate Background Isolate)
                                         v
+-----------------------------------------------------------------------------------+
|                           Native C/C++ AI Engines via FFI                         |
+-----------------------------------------------------------------------------------+
| - Engine A: ONNX Runtime (Tiny Sentence Transformer, Cosine Sim >= 0.70)          |
| - Engine B: llama.cpp (.gguf dynamic loader, 2-3 CPU threads max, n_ctx=2048)     |
| - TTS:      Piper C++ (Arabic .onnx voice, text-to-pcm streaming)                 |
+-----------------------------------------------------------------------------------+
```

---

## 3. Directory & Folder Structure (Clean Architecture)

```
offline_car_assistant/
├── android/
│   └── app/src/main/kotlin/com/byd/assistant/
│       ├── services/
│       │   ├── VoiceForegroundService.kt      # Wake-word monitoring via Vosk C-API
│       │   └── CarAccessibilityService.kt    # Screen content & app package extraction
│       ├── bridge/
│       │   ├── CarIntentDispatcher.kt         # Dispatches com.byd.intent broadcasts
│       │   ├── WindowOverlayManager.kt        # TYPE_APPLICATION_OVERLAY window manager
│       │   └── NativeChannelsPlugin.kt        # MethodChannel & EventChannel handlers
│       └── MainActivity.kt                    # Main entry point for Android
├── native/                                    # C/C++ FFI Shared Libraries & C Wrappers
│   ├── llama/
│   │   ├── llama_bridge.h
│   │   └── llama_bridge.cpp                   # C API wrapper over llama.cpp
│   ├── onnx/
│   │   ├── onnx_bridge.h
│   │   └── onnx_bridge.cpp                    # Embeddings extractor & cosine similarity
│   └── piper/
│       ├── piper_bridge.h
│       └── piper_bridge.cpp                   # Synthesizes raw audio PCM from Arabic text
├── assets/
│   ├── grammar/
│   │   └── default_grammar.json               # Arabic wake words & car command grammar
│   └── mock/
│       └── car_capabilities.json              # Simulated BYD car capabilities
└── lib/
    ├── core/
    │   ├── constants/
    │   │   ├── app_constants.dart             # Thresholds, timeouts, intent actions
    │   │   └── arabic_stopwords.dart          # Dialect stopwords ("شنو", "شغل", "وين", etc.)
    │   ├── ffi/
    │   │   ├── ffi_bindings.dart              # DynamicLibrary loader & FFI signatures
    │   │   └── isolate_worker.dart            # Offloads heavy AI inference from UI thread
    │   ├── errors/
    │   │   └── exceptions.dart                # Failure definitions & hardware timeouts
    │   └── utils/
    │       ├── arabic_normalizer.dart         # Normalizes Alef, Taa Marbuta, diacritics
    │       └── tts_sanitizer.dart             # Converts "%", "°C", strips Markdown & emojis
    ├── data/
    │   ├── datasources/
    │   │   ├── local_db/
    │   │   │   ├── app_database.dart          # sqflite database factory & schema
    │   │   │   └── user_facts_dao.dart        # CRUD for lightweight RAG context
    │   │   └── native_bridge/
    │   │       ├── native_voice_channel.dart  # EventChannel stream for wake word & STT
    │   │       ├── car_control_channel.dart   # MethodChannel for BYD intents & fallback
    │   │       └── accessibility_channel.dart # MethodChannel for screen context
    │   └── repositories/
    │       ├── car_action_repository_impl.dart
    │       └── memory_repository_impl.dart
    ├── domain/
    │   ├── entities/
    │   │   ├── car_command.dart               # Domain action: AirConditioner, Windows, Seats
    │   │   ├── intent_match.dart              # Engine A output: command + confidence
    │   │   ├── user_fact.dart                 # RAG fact entity (key, value, category)
    │   │   └── voice_state.dart               # Listening, Thinking, Speaking, Idle
    │   └── usecases/
    │       ├── process_voice_query_usecase.dart
    │       ├── execute_car_command_usecase.dart
    │       └── query_rag_memory_usecase.dart
    ├── engines/
    │   ├── engine_a_semantic/
    │   │   ├── semantic_router.dart           # Compares input embedding with car intent vector
    │   │   └── intent_catalog.dart            # Predefined Arabic canonical car phrases
    │   ├── engine_b_llm/
    │   │   ├── llama_engine.dart              # Manages GGUF model lifecycle & generation
    │   │   └── prompt_builder.dart            # Injects dynamic screen context, location, RAG
    │   ├── tts/
    │   │   ├── piper_tts_engine.dart          # Manages Piper FFI & audio stream player
    │   │   └── audio_output_stream.dart       # High-performance low-latency PCM playback
    │   └── mcp/
    │       ├── car_mcp_client.dart            # In-process tools: read_screen, get_car_status
    │       └── external_mcp_client.dart       # Optional SSE client for web search
    ├── presentation/
    │   ├── hud/
    │   │   ├── bottom_capsule_overlay.dart    # Compact Siri/CarPlay style floating capsule
    │   │   ├── wave_visualizer.dart           # Smooth 60fps audio waveform animation
    │   │   └── hud_controller.dart            # Riverpod/Bloc state holder for overlay
    │   └── settings/
    │       ├── settings_screen.dart           # Main dashboard
    │       ├── model_manager_screen.dart      # Storage/USB picker for .gguf & .onnx
    │       ├── wake_word_screen.dart          # Custom wake-word & grammar updater
    │       └── sandbox_screen.dart            # Test BYD intents with live visual feedback
    ├── main.dart                              # Fullscreen entry point (Settings & Setup)
    └── overlay_main.dart                      # Lightweight entry point for HUD overlay
```

---

## 4. Native Android Subsystems & Bridging

### 4.1 Voice Foreground Service & Vosk KWS
- **Service Name:** `com.byd.assistant.services.VoiceForegroundService`
- **Type:** Android Foreground Service with `foregroundServiceType="microphone"`.
- **Notification:** Low-priority non-intrusive notification ("المساعد الصوتي قيد المراقبة").
- **KWS Pipeline:**
  1. Opens 16kHz 16-bit mono PCM stream via `AudioRecord`.
  2. Runs native Vosk recognizer with custom JSON grammar containing wake words and primary Arabic car keywords.
  3. When the wake word is triggered, triggers `EventChannel.success("EVENT_WAKE_WORD_DETECTED")`.
  4. Continues streaming recognized Arabic speech hypothesis until silence is detected (threshold: 700ms silence).
  5. Broadcasts final transcribed utterance and pauses audio capture while TTS is active to prevent acoustic self-triggering (Echo Cancellation Guard).

### 4.2 Window Overlay Manager (Bottom Capsule HUD)
- **Overlay Type:** `WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY`.
- **Dimensions & Gravity:**
  - Width: Match parent or centered 600dp.
  - Height: Fixed 96dp bottom capsule.
  - Gravity: `Gravity.BOTTOM | Gravity.CENTER_HORIZONTAL`.
  - Flags: `FLAG_NOT_TOUCH_MODAL | FLAG_NOT_FOCUSABLE` (Allows touch passthrough to navigation maps when not interacting with capsule).
- **Engine Binding:** Reuses FlutterEngineCache to instantiate `overlayMain` entrypoint instantly (<50ms delay).

### 4.3 BYD Hardware Intent Dispatcher & Fallback Simulator
- **Intent Pattern:**
  - Dispatches targeted implicit/explicit intents defined in BYD DiLink SDK (e.g., `com.byd.intent.action.AC_CONTROL`, `com.byd.intent.action.WINDOW_CONTROL`).
  - Extras include: `{"zone": "driver", "value": 22, "command": "set_temperature"}`.
- **Automated Fallback Simulator:**
  - Checks if BYD vendor services exist via `PackageManager.resolveActivity` or system properties.
  - If unavailable (running on emulator, tablet, or non-BYD test unit), logs the simulated intent to Android Logcat (`TAG: BYD_SIMULATOR`), delivers a subtle Toast, and responds with a simulated success payload to Flutter.

### 4.4 Car Accessibility Service (Dynamic Screen Context)
- **Service Name:** `CarAccessibilityService`.
- **Extraction:** When requested by Flutter via `MethodChannel("com.byd.assistant/accessibility")`:
  - Inspects active root window node.
  - Retrieves current foreground package name (e.g., `com.google.android.apps.maps`).
  - Extracts visible text fragments (e.g., navigation destination or song title).
  - Serializes to JSON and sends to Engine B for contextual reasoning.

---

## 5. Dual-Engine Intent Processing Pipeline

### 5.1 Engine A: Fast Semantic Router (Sub-150ms)
- **Model:** Pre-quantized Arabic Sentence Transformer (e.g., MiniLM-L6 or sentence-transformers quantized to ONNX INT8, ~40MB).
- **Execution:** Runs in Dart FFI via `onnxruntime.so`.
- **Pre-computed Embeddings:** Intent catalog contains vector representations of 50+ canonical Arabic vehicular commands:
  - *"شغل التبريد"* (Turn on AC)
  - *"نزل الجامة"* / *"افتح الشباك"* (Open window)
  - *"شغل تدفئة الكشنات"* (Turn on seat heating)
  - *"علي الصوت"* (Increase volume)
- **Routing Logic:**
  - Extracts embedding of user utterance via ONNX.
  - Computes Cosine Similarity against catalog vectors:
    $$\text{similarity} = \frac{\mathbf{A} \cdot \mathbf{B}}{\|\mathbf{A}\| \|\mathbf{B}\|}$$
  - **Rule:** If $\text{score} \ge 0.70$, bypass Engine B immediately. Trigger corresponding `CarCommand` and return canned Arabic acoustic confirmation (e.g., *"صار تدلل، شغلت التبريد"*).
  - If $\text{score} < 0.70$, forward utterance to Engine B.

### 5.2 Engine B: Dynamic LLM Fallback (llama.cpp)
- **Loader:** Dynamic FFI bindings to `libllama.so`.
- **File Format:** Any user-selected `.gguf` file (Recommended default: `Qwen2.5-0.5B-Instruct-Q4_K_M.gguf`).
- **Resource Constraints (SoC Protection):**
  - Thread count: Strictly 2 or 3 threads (`n_threads = 2`).
  - Context window: 2048 tokens (`n_ctx = 2048`).
  - Offload layers: `n_gpu_layers = 0` (CPU only, avoiding OpenCL/Vulkan crashes on car GPUs).
  - Batch size: 512 tokens.
- **System Prompt Specification:**
  ```text
  أنت مساعد ذكي مدمج داخل شاشة سيارة BYD.
  القواعد الصارمة:
  1. أجب باختصار شديد (جملة أو جملتان كحد أقصى) وبلهجة عراقية/عربية واضحة تناسب السائق.
  2. لا تستخدم علامات التنسيق مثل الماركداون أو القوائم أو الإيموجي نهائياً لأن النص سيتم نطقه صوتياً.
  3. السياق الحالي للسيارة: {car_context}
  4. التطبيق الظاهر على الشاشة: {screen_context}
  5. تفضيلات السائق المسجلة: {user_facts}
  ```

---

## 6. Text Sanitization & Piper TTS Pipeline

### 6.1 Arabic Normalization & Phonetic Sanitizer (`ArabicTextSanitizer`)
All generated tokens from Engine B pass through a strict filter prior to being sent to Piper:
1. **Strip Formatting:** Removes all `*`, `#`, `_`, `~`, `>` markdown notations.
2. **Strip Visual Characters:** Removes all Emojis and surrogate pairs using regex.
3. **Symbol Expansion (Arabic spoken equivalents):**
   - `%` -> `بالمئة`
   - `°C` / `C` -> `درجة مئوية`
   - `km/h` -> `كيلومتر بالساعة`
   - `+` / `-` -> `زائد` / `ناقص`
4. **Number Formatting:** Converts Latin digits (`0-9`) into spoken Arabic phonetic words (e.g., `22` -> `اثنين وعشرين`).

### 6.2 Piper Speech Synthesis
- **Model:** Arabic ONNX voice (e.g., `ar_JO-kareem-low.onnx` or equivalent, ~20MB).
- **Execution:** Piper C++ shared library linked via Dart FFI.
- **Audio Delivery:** Synthesizes raw 22050Hz 16-bit PCM chunks streamed directly to an audio output stream buffer to minimize latency between token generation and audible voice.

---

## 7. Local Storage & Lightweight RAG (sqflite)

- **Database:** `car_assistant.db` via `sqflite`.
- **Tables:**
  - `user_facts`:
    - `id` INTEGER PRIMARY KEY AUTOINCREMENT
    - `category` TEXT (e.g., 'climate', 'route', 'general')
    - `fact_key` TEXT (e.g., 'preferred_temp', 'home_address')
    - `fact_value` TEXT (e.g., '22', 'المنصور')
    - `confidence` REAL
    - `updated_at` INTEGER
  - `assistant_settings`:
    - `key` TEXT PRIMARY KEY
    - `value` TEXT
- **On-Demand RAG Injection:**
  - Analyzes tokens in the user query for keywords (e.g., "البيت", "حرارة", "شغلي").
  - Queries `user_facts` for matching categories and injects top-3 relevant facts into `{user_facts}` in the prompt.
  - Zero heavy vector database overhead; purely instantaneous SQL lookups.

---

## 8. Hybrid Model Context Protocol (MCP) Client

- **Internal In-Process Client (`CarMcpClient`):**
  - Exposes car internal state as MCP Tools for the LLM:
    - `tool_get_car_status()`: Returns speed, battery/fuel, door status.
    - `tool_get_screen_context()`: Returns foreground app info.
    - `tool_save_user_fact(key, value)`: Allows the assistant to memorize driver preferences on the fly.
- **External Network Client (`ExternalMcpClient`):**
  - Optional SSE/WebSocket client active only when network connection is detected.
  - Exposes external tools (e.g., live weather, web search).

---

## 9. Presentation Layer & UI/UX

### 9.1 Floating HUD Capsule (`BottomCapsuleOverlay`)
- **Visual Design:** Floating rounded pill with dark glassmorphism styling (`Color(0xCC1A1A1A)`), subtle cyan/electric blue glow.
- **States:**
  - `Listening`: Smooth sinusoidal audio wave reacting to mic decibels.
  - `Processing`: Pulsing subtle accent glow.
  - `Speaking`: Waveform undulating according to TTS playback amplitude.
  - `Confirmation`: Displays checkmark icon and 1-line car action executed.
- **Auto-Dismiss:** Automatically hides after 3.5 seconds of silence post-TTS completion.

### 9.2 Settings Dashboard & Model Manager
- **Model Manager:** Allows the user to browse internal storage or USB mount points (`/storage/` or `/mnt/media_rw/`) to select any `.gguf` or `.onnx` file. Validates magic headers before saving.
- **Wake Word Studio:** Allows entering new Arabic wake words, generating grammar files, and live testing voice triggers.
- **BYD Intent Sandbox:** Direct action buttons (e.g., "فتح النوافذ 20%", "ضبط التبريد 21°") with live intent log output.

---

## 10. Thermal & Resource Management (Automotive SoC Guard)

1. **Thread Limiting:** llama.cpp instance is strictly bound to 2 or 3 worker threads. Big cores are preserved for car OS rendering and navigation.
2. **Memory Recycling:** Dynamic memory buffers are released immediately after generation. The KV cache is truncated or cleared on query termination.
3. **Battery & Thermal Watchdog:** Listens to `Intent.ACTION_BATTERY_CHANGED` / temperature broadcasts to throttle LLM reasoning if head unit temp exceeds 70°C.

---

## 11. Testing & Verification Plan

1. **Unit Testing:**
   - Arabic normalization suite (Alef variations, Taa Marbuta, diacritic removal).
   - TTS Sanitizer tests (symbol to Arabic conversion, Markdown removal).
   - Cosine similarity mathematical correctness.
2. **Integration Testing:**
   - `sqflite` CRUD and RAG keyword matching.
   - BYD Intent Simulator dispatch verification.
   - MCP tool invocation and response parsing.
3. **Hardware Simulation:**
   - Simulated audio stream injection for testing Vosk STT pipeline without physical microphone.
