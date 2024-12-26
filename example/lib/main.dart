import 'package:flutter/material.dart';
import 'package:hand_transmit/pages/home_page.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  static List<AssetEntity> selectedAssets = [];

  static int port = 54011;

   List<AssetEntity> getSelectedAssets(){
    return selectedAssets;
   }


  Future<void> checkAndRequestPermissions() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }

  if (await Permission.manageExternalStorage.isDenied) {
    await Permission.manageExternalStorage.request();
  }
}

  @override
  Widget build(BuildContext context) {
    checkAndRequestPermissions();
    return MaterialApp(
      title: '手势传输',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatelessWidget {

  const MyHomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      title: 'MediaPipe Hand Tracking',
      home: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(border:Border.all(width: 1)),
          child:  HomePage()
      ),
    );
  }
}