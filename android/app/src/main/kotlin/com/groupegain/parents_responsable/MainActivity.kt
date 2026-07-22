package com.groupegain.parents_responsable

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.os.Build
import android.view.WindowInsets
import android.view.View
import android.graphics.Color

import androidx.core.view.WindowCompat

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Affichage bord-à-bord compatible Android 15+ (SDK 35)
        WindowCompat.setDecorFitsSystemWindows(window, false)
        
        // Rend les barres système transparentes
        // Note: ces API sont marquées obsolètes à partir du SDK 35,
        // mais restent nécessaires pour la rétrocompatibilité sur les versions antérieures.
        @Suppress("DEPRECATION")
        window.statusBarColor = Color.TRANSPARENT
        @Suppress("DEPRECATION")
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            @Suppress("DEPRECATION")
            window.navigationBarDividerColor = Color.TRANSPARENT
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
