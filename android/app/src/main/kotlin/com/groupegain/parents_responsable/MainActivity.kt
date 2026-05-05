package com.groupegain.parents_responsable

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.View
import android.graphics.Color

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Enable edge-to-edge display for Android 15+ (SDK 35) and backward compatibility
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            // For Android 11+ (R) and above
            window.setDecorFitsSystemWindows(false)
            
            // Set system bar colors to transparent for edge-to-edge
            window.statusBarColor = Color.TRANSPARENT
            window.navigationBarColor = Color.TRANSPARENT
            
            // Configure system UI visibility
            val controller = window.insetsController
            controller?.let {
                it.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE)
                it.show(WindowInsets.Type.systemBars())
            }
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            // For Android 5.0+ (LOLLIPOP) to Android 10
            window.statusBarColor = Color.TRANSPARENT
            window.navigationBarColor = Color.TRANSPARENT
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                )
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Setup method channel for communication with Flutter
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "flutter/native_theme")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getSystemUIPadding" -> {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            val insets = window.decorView.rootWindowInsets
                            val systemBars = insets?.getInsets(WindowInsets.Type.systemBars())
                            if (systemBars != null) {
                                result.success(mapOf(
                                    "top" to systemBars.top,
                                    "bottom" to systemBars.bottom,
                                    "left" to systemBars.left,
                                    "right" to systemBars.right
                                ))
                            } else {
                                result.success(mapOf(
                                    "top" to 0,
                                    "bottom" to 0,
                                    "left" to 0,
                                    "right" to 0
                                ))
                            }
                        } else {
                            // Fallback for older Android versions
                            result.success(mapOf(
                                "top" to 0,
                                "bottom" to 0,
                                "left" to 0,
                                "right" to 0
                            ))
                        }
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
