import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'hand_mediapipe_plugin_platform_interface.dart';

/// An implementation of [HandMediapipePluginPlatform] that uses method channels.
class MethodChannelHandMediapipePlugin extends HandMediapipePluginPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('hand_mediapipe_plugin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
