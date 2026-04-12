package com.hush.hush_app

import android.os.Bundle
import android.view.SurfaceView
import android.view.ViewGroup
import android.view.ViewTreeObserver
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.hush.app/screenshot"
    private var isScreenshotAllowed = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // MUST BE BEFORE super.onCreate
        window.setFlags(
            WindowManager.LayoutParams.FLAG_SECURE,
            WindowManager.LayoutParams.FLAG_SECURE
        )
        super.onCreate(savedInstanceState)

        // Aggressively bind to the layout state so the moment Flutter inserts its SurfaceView, we lock it immediately before SmartClip can hook.
        window.decorView.rootView.viewTreeObserver.addOnGlobalLayoutListener(object : ViewTreeObserver.OnGlobalLayoutListener {
            override fun onGlobalLayout() {
                val viewGroup = window.decorView.rootView as? ViewGroup
                if (viewGroup != null) {
                    setSurfaceViewSecure(viewGroup, !isScreenshotAllowed)
                }
            }
        })
    }

    private fun setSurfaceViewSecure(viewGroup: ViewGroup, secure: Boolean) {
        for (i in 0 until viewGroup.childCount) {
            val child = viewGroup.getChildAt(i)
            if (child is SurfaceView) {
                if (secure) {
                    child.setSecure(true)
                } else {
                    child.setSecure(false)
                }
            } else if (child is ViewGroup) {
                setSurfaceViewSecure(child, secure)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "enableScreenshotPrevention") {
                isScreenshotAllowed = false
                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                val viewGroup = window.decorView.rootView as? ViewGroup
                if (viewGroup != null) setSurfaceViewSecure(viewGroup, true)
                result.success(true)
            } else if (call.method == "disableScreenshotPrevention") {
                isScreenshotAllowed = true
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
