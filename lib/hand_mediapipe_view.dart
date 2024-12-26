import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 用于嵌入 Android 端 MediaPipe 的自定义 PlatformView
class HandMediapipeView extends StatefulWidget {

  final void Function(String data)? onLandmarkData; // 回调函数

// 需要传递一个函数
  const HandMediapipeView({super.key, this.onLandmarkData});

  @override
  // ignore: library_private_types_in_public_api
  _HandMediapipeViewState createState() => _HandMediapipeViewState();
}

class _HandMediapipeViewState extends State<HandMediapipeView> {
  static const eventChannel = EventChannel('com.xbin/hand_landmarks');
  String _landmarkData = 'No data received';

  @override
  void initState() {
    super.initState();
    _listenToEventChannel();
  }

  void _listenToEventChannel() {
    eventChannel.receiveBroadcastStream().listen(
      (data) {
        setState(() {
          _landmarkData = "$data";
          // 对传过来的手势进行判断
          widget.onLandmarkData?.call(_landmarkData);
        });
      },
      onError: (error) {
        setState(() {
          _landmarkData = "Error: ${error.message}";
          widget.onLandmarkData?.call(_landmarkData);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
     if (defaultTargetPlatform == TargetPlatform.android) {
      return const AndroidView(
        viewType: 'hand_mediapipe_view',
        layoutDirection: TextDirection.ltr,
        creationParams: {}, // 可选参数传递
        creationParamsCodec: StandardMessageCodec(),
      );
    } else {
      return const Center(
        child: Text('HandMediapipeView is only supported on Android.'),
      );
  }
}
}
