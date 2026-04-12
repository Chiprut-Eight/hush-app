package com.hush.hush_app

import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.FlutterActivityLaunchConfigs
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.hush.app/screenshot"

    override fun getBackgroundMode(): FlutterActivityLaunchConfigs.BackgroundMode {
        // Forces Flutter to use TextureView instead of SurfaceView.
        // TextureView fully obeys dynamic window.setFlags/clearFlags(FLAG_SECURE) instantly
        // even on Samsung SmartClip, and doesn't get permanently stuck in secure mode!
        return FlutterActivityLaunchConfigs.BackgroundMode.transparent
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        // Secure by default before anything draws
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
                android.widget.Toast.makeText(context, "Screenshot UNLOCKED for Admin", android.widget.Toast.LENGTH_SHORT).show()
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
