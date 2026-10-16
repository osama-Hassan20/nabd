package com.koshkparmage.purexo

import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.koshkparmage.purexo/navigation_mode"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "is3ButtonNav") {
                try {
                    // 0 = 3-button, 1 = 2-button, 2 = gesture navigation
                    val mode = Settings.Secure.getInt(contentResolver, "navigation_mode", 0)
                    result.success(mode == 0)
                } catch (e: Exception) {
                    result.success(false)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
