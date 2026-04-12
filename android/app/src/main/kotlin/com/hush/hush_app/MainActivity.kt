package com.hush.hush_app

import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.SurfaceView
import android.view.ViewGroup
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.hush.app/screenshot"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
    }

    override fun onResume() {
        super.onResume()
        // Strong mitigation for Samsung SmartClip taking Flutter's independent SurfaceView
        Handler(Looper.getMainLooper()).postDelayed({
            val viewGroup = window.decorView.rootView as? ViewGroup
            if (viewGroup != null) {
                setSurfaceViewSecure(viewGroup, true)
            }
        }, 500)
    }

    private fun setSurfaceViewSecure(viewGroup: ViewGroup, secure: Boolean) {
        for (i in 0 until viewGroup.childCount) {
            val child = viewGroup.getChildAt(i)
            if (child is SurfaceView) {
                // Must manually lock the surface buffer against SmartClip hook
                child.setSecure(secure) 
            } else if (child is ViewGroup) {
                setSurfaceViewSecure(child, secure)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "enableScreenshotPrevention") {
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                val viewGroup = window.decorView.rootView as? ViewGroup
                if (viewGroup != null) setSurfaceViewSecure(viewGroup, true)
                result.success(true)
            } else if (call.method == "disableScreenshotPrevention") {
                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                val viewGroup = window.decorView.rootView as? ViewGroup
                if (viewGroup != null) setSurfaceViewSecure(viewGroup, false)
                result.success(true)
            } else {
                result.notImplemented()
            }
        }
    }
}
