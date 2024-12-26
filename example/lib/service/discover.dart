import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:hand_transmit/main.dart';
import 'package:hand_transmit/service/client.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:udp/udp.dart';

class DeviceDiscovery {
  UDP? udpReceiver;

  static const int broadcastPort = 56122;
  /// 发送广播信息
  Future<void> startBroadcast(String deviceName) async {
    final udpSender =
        await UDP.bind(Endpoint.any(port: const Port(broadcastPort)));

    final message = jsonEncode({
      'deviceName': deviceName,
      'port': MyApp.port, // 文件接收服务的端口
    });

    udpSender.send(
      Uint8List.fromList(message.codeUnits),
      Endpoint.broadcast(port: const Port(broadcastPort)),
    );

    await Future.delayed(const Duration(seconds: 10));
    udpSender.close();
  }

  Future<void> startListening(
      Function(String deviceName, String ipAddress,String progress) onDeviceFound,
      String name) async {
    udpReceiver = await UDP.bind(Endpoint.any(port: const Port(broadcastPort)));

    udpReceiver!.asStream().listen((datagram) async {
      if (datagram != null) {
        final message = utf8.decode(datagram.data);
        final Map<String, dynamic> payload = jsonDecode(message);
        final deviceName = payload['deviceName'];
        final port = payload['port'];
        final ipAddress = datagram.address.address;
        String progress = "等待发送";
        final localIpAddress = await getLocalIPAddress();
        bool end  =false;
        if (deviceName == name  && ipAddress != localIpAddress) {
          progress = "正在发送";
          onDeviceFound(deviceName, ipAddress,progress);
          FileUploader fileUploader = FileUploader((StartUpFile result){
          }, (bool tempEnd){
            end = tempEnd;
          });
          await fileUploader.batchuPloadFiles(MyApp.selectedAssets,ipAddress,port);
          stopListening();
          if(end){
            progress = "发送成功";
          }else{
             progress = "发送失败";
          }
          onDeviceFound(deviceName, ipAddress,progress);
        }
      }
    });
  }

// 关闭监听
  Future<void> stopListening() async {
    if (udpReceiver != null) {
      udpReceiver!.close();
      udpReceiver = null;
    }
  }

  Future<String> _getLocalIpAddress() async {
  // 获取本地设备的 IP 地址（一般是局域网 IP）
  final interfaces = await NetworkInterface.list();
  for (var interface in interfaces) {
    for (var address in interface.addresses) {
      if (address.type == InternetAddressType.IPv4) {
        return address.address;
      }
    }
  }
  return ""; // 如果无法获取本地 IP，则返回空字符串
}

  Future<String?> getLocalIPAddress() async {
    final info = NetworkInfo();
    final ipAddress = await info.getWifiIP();
    return ipAddress;
  }
}
