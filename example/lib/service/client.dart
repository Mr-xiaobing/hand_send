import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class StartUpFile {
  // 成功还是失败
  bool isStart;

  String filePath;

  String fileName;

  StartUpFile(this.isStart, this.filePath, this.fileName);
}

class FileUploader {
  // 开始文件传输回调
  Function(StartUpFile result) startUpFile;

  Function(bool bool) endUpFile;

  FileUploader(this.startUpFile, this.endUpFile);
  // 传入 ip地址 和 端口号 发起请求
  Future<void> uploadFile(
      File selectFile, String serverIp, int serverPort) async {
    try {
      bool isStart = false;
      String filePath = selectFile.path;
      String fileName = selectFile.uri.pathSegments.last;
      startUpFile(StartUpFile(isStart, filePath, fileName));
      final uri = Uri.parse('http://$serverIp:$serverPort/upload');
      final request = http.MultipartRequest('POST', uri);
      request.files
          .add(await http.MultipartFile.fromPath('file', selectFile.path));
      final response = await request.send();

      if (response.statusCode == 200) {
        endUpFile(true);
      } else {
        endUpFile(false);
      }
    } catch (e) {
      endUpFile(false);
    }
  }

  Future<void> batchuPloadFiles(
      List<AssetEntity> selectedAssets, String serverIp, int serverPort) async {
    try {
      bool isStart = false;
      List<String> filePaths = [];
      List<String> fileNames = [];
      // 获取文件路径和文件名
      for (var asset in selectedAssets) {
        // 获取文件路径
        final file = await asset.file;
        if (file != null) {
          filePaths.add(file.path);
          fileNames.add(file.uri.pathSegments.last);
        }
      }
      // 上传前的文件处理
      for (int i = 0; i < selectedAssets.length; i++) {
        startUpFile(StartUpFile(isStart, filePaths[i], fileNames[i]));
      }
      final uri = Uri.parse('http://$serverIp:$serverPort/upload');
      final request = http.MultipartRequest('POST', uri);
      // 添加每个文件到 MultipartRequest
      for (var asset in selectedAssets) {
        final file = await asset.file;
        if (file != null) {
          request.files
              .add(await http.MultipartFile.fromPath('file', file.path));
        }
      }
      final response = await request.send();
      if (response.statusCode == 200) {
        // 上传成功
        for (int i = 0; i < selectedAssets.length; i++) {
          endUpFile(true);
        }
      } else {
        // 读取和打印 response 内容
        final responseBody = await response.stream.bytesToString();
        // 上传失败
        for (int i = 0; i < selectedAssets.length; i++) {
          endUpFile(false);
        }
      }
    } catch (e) {
      // 捕获异常
      for (int i = 0; i < selectedAssets.length; i++) {
        endUpFile(false);
      }
    }
  }
}
