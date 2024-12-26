import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'hand_mediapipe_plugin_method_channel.dart';

abstract class HandMediapipePluginPlatform extends PlatformInterface {
  /// Constructs a HandMediapipePluginPlatform.
  HandMediapipePluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static HandMediapipePluginPlatform _instance = MethodChannelHandMediapipePlugin();

  /// The default instance of [HandMediapipePluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelHandMediapipePlugin].
  static HandMediapipePluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HandMediapipePluginPlatform] when
  /// they register themselves.
  static set instance(HandMediapipePluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
