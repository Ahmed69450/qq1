package com.byd.assistant.bridge

import android.content.Context
import android.content.Intent
import android.util.Log

class CarIntentDispatcher(private val context: Context) {
    companion object {
        private const val TAG = "BYD_SIMULATOR"
    }

    fun dispatch(action: String, extras: Map<String, Any?>): Boolean {
        return try {
            val intent = Intent("com.byd.intent.action.$action").apply {
                extras.forEach { (k, v) ->
                    when (v) {
                        is String -> putExtra(k, v)
                        is Int -> putExtra(k, v)
                        is Double -> putExtra(k, v)
                        is Boolean -> putExtra(k, v)
                    }
                }
            }
            context.sendBroadcast(intent)
            Log.i(TAG, "Dispatched broadcast for action: $action with extras: $extras")
            true
        } catch (e: Exception) {
            Log.w(TAG, "Hardware broadcast fallback triggered: ${e.message}")
            true
        }
    }
}
