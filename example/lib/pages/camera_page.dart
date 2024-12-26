import 'package:flutter/material.dart';
import 'package:hand_mediapipe_plugin/hand_mediapipe_view.dart';
import 'package:hand_transmit/main.dart';
import 'package:hand_transmit/service/discover.dart';

// ignore: must_be_immutable
class CameraPage extends StatefulWidget {
  void Function(String progress) updateProgress;

  void Function() clearSelectFile;

  CameraPage(
      {super.key, required this.updateProgress, required this.clearSelectFile});

  @override
  State<CameraPage> createState() => _HomePageState();
}

class _HomePageState extends State<CameraPage> {
  String landmarkData = "Waiting for data...";

  @override
  void initState() {
    super.initState();
    // 初始化数据]
  }

  DeviceDiscovery deviceDiscovery = DeviceDiscovery();
  String name = "chengxiaobin";
  bool isCooldown = false; // 标志位，用于表示是否在冷却中
  void handleLandmarkData(String data) {
    if (isCooldown) return; // 如果处于冷却中，则直接返回

    setState(() {
      landmarkData = data; // 更新手势数据

      if (landmarkData == "take") {
        isCooldown = true; // 设置冷却开始
        if (MyApp.selectedAssets.isEmpty) {
          widget.updateProgress.call("请放入文件");
          // 没有选择文件，弹出提示
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(content: Text('请先选择文件!')),
          // );
        } else {
          widget.updateProgress.call("文件就绪，准备发送");
          // 开启监听
          deviceDiscovery.startListening((deviceName, ipAddress, progress) {
            widget.updateProgress.call(progress);
            if (progress == "发送成功") {
              widget.clearSelectFile.call();
            }
          }, name);
        }
      } else if (landmarkData == "put") {
        isCooldown = true; // 设置冷却开始
        widget.updateProgress.call("等待其他手机发送文件");
        deviceDiscovery.startBroadcast(name);
      }
    });

    // 冷却结束后重置标志位
    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        isCooldown = false; // 重置冷却状态
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      SizedBox(
          width: 10,
          height: 10,
          child: Opacity(
            opacity: 0,
            child: HandMediapipeView(
              onLandmarkData: handleLandmarkData,
            ),
          )),
    ]);
  }
}
