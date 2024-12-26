import 'package:flutter_test/flutter_test.dart';
import 'package:hand_mediapipe_plugin/hand_mediapipe_plugin.dart';
import 'package:hand_mediapipe_plugin/hand_mediapipe_plugin_platform_interface.dart';
import 'package:hand_mediapipe_plugin/hand_mediapipe_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHandMediapipePluginPlatform
    with MockPlatformInterfaceMixin
    implements HandMediapipePluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final HandMediapipePluginPlatform initialPlatform = HandMediapipePluginPlatform.instance;

  test('$MethodChannelHandMediapipePlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelHandMediapipePlugin>());
  });

  test('getPlatformVersion', () async {
    MockHandMediapipePluginPlatform fakePlatform = MockHandMediapipePluginPlatform();
    HandMediapipePluginPlatform.instance = fakePlatform;

    expect(await HandMediapipePlugin.getPlatformVersion(), '42');
  });
}
