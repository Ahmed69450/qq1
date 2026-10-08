package com.byd.assistant

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.byd.assistant.bridge.CarIntentDispatcher

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.byd.assistant/car_control"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val dispatcher = CarIntentDispatcher(applicationContext)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "dispatchCarCommand") {
                val action = call.argument<String>("action") ?: "unknown"
                val map = call.arguments as? Map<String, Any?> ?: emptyMap()
                val success = dispatcher.dispatch(action, map)
                result.success(mapOf("status" to if (success) "dispatched" else "failed"))
            } else {
                result.notImplemented()
            }
        }
    }
}
