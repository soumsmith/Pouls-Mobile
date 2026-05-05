import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class SystemUIService {
  static const MethodChannel _channel = MethodChannel('flutter/native_theme');
  
  static Future<EdgeInsets> getSystemUIPadding() async {
    try {
      final Map<String, dynamic>? padding = await _channel.invokeMethod('getSystemUIPadding');
      if (padding != null) {
        return EdgeInsets.only(
          top: padding['top']?.toDouble() ?? 0.0,
          bottom: padding['bottom']?.toDouble() ?? 0.0,
          left: padding['left']?.toDouble() ?? 0.0,
          right: padding['right']?.toDouble() ?? 0.0,
        );
      }
    } catch (e) {
      print('Error getting system UI padding: $e');
    }
    
    // Return default padding if method call fails
    return EdgeInsets.zero;
  }
  
  static Future<double> getStatusBarHeight() async {
    final padding = await getSystemUIPadding();
    return padding.top;
  }
  
  static Future<double> getNavigationBarHeight() async {
    final padding = await getSystemUIPadding();
    return padding.bottom;
  }
  
  static Widget safeAreaWrapper({required Widget child}) {
    return FutureBuilder<EdgeInsets>(
      future: getSystemUIPadding(),
      builder: (context, snapshot) {
        final padding = snapshot.data ?? EdgeInsets.zero;
        return Padding(
          padding: padding,
          child: child,
        );
      },
    );
  }
}
