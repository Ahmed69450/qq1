import 'dart:ffi';
import 'package:ffi/ffi.dart';

typedef LlamaInitC = Pointer<Void> Function(Pointer<Utf8>, Int32, Int32);
typedef LlamaInitDart = Pointer<Void> Function(Pointer<Utf8>, int, int);

typedef LlamaGenerateC = Int32 Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, Int32);
typedef LlamaGenerateDart = int Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>, int);

typedef LlamaFreeC = Void Function(Pointer<Void>);
typedef LlamaFreeDart = void Function(Pointer<Void>);

class NativeFfiBindings {
  final DynamicLibrary _lib;

  late final LlamaInitDart llamaInit;
  late final LlamaGenerateDart llamaGenerate;
  late final LlamaFreeDart llamaFree;

  NativeFfiBindings(this._lib) {
    llamaInit = _lib.lookupFunction<LlamaInitC, LlamaInitDart>('llama_init_model');
    llamaGenerate = _lib.lookupFunction<LlamaGenerateC, LlamaGenerateDart>('llama_generate_tokens');
    llamaFree = _lib.lookupFunction<LlamaFreeC, LlamaFreeDart>('llama_free_model');
  }
}
