package com.groupegain.parents_responsable

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.View
import android.graphics.Color

import androidx.core.view.WindowCompat

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Setup modern edge-to-edge display (resolves Android 15 / SDK 35 warnings)
        WindowCompat.setDecorFitsSystemWindows(window, false)
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
