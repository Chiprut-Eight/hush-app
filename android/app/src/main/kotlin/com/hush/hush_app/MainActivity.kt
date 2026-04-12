package com.hush.hush_app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.hush.app/screenshot"

    override fun onCreate(savedInstanceState: Bundle?) {
        // Secure by default on app launch! MUST be before super.onCreate for SurfaceView to pick it up on some Samsung devices.
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "enableScreenshotPrevention") {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                result.success(true)
            } else if (call.method == "disableScreenshotPrevention") {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
