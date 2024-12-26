
import 'dart:async';

import 'hand_mediapipe_plugin_platform_interface.dart';
import 'package:flutter/services.dart';

class HandMediapipePlugin {

  static const MethodChannel _channel = MethodChannel('hand_mediapipe_plugin');

  static Future<String?> getPlatformVersion() {
    return HandMediapipePluginPlatform.instance.getPlatformVersion();
  }
}
