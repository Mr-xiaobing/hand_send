import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hand_transmit/main.dart';
import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

class AcceptFile {
  // 接收到的文件名称
  String filename;
  // 文件路径  用于展示
  String filePath;
  // 文件类型 用于判断展示类型
  FileType fileType;
  // 文件接收时间
  String accepTime;

  AcceptFile(this.filename, this.filePath, this.fileType, this.accepTime);
}

class FileServer {
  final Function(List<AcceptFile> uploadedFiles) receiveFileCallback;

  Function(String progress) updateHomeProgress;

  FileServer(this.receiveFileCallback, this.updateHomeProgress) {
    startServer();
  }

  /// 启动服务器，监听指定的端口
  Future<void> startServer() async {
    // 创建一个路由器
    final router = Router();
    // 定义文件上传的POST路由
    router.post('/upload', (Request request) async {
      // 用于保存接收到的文件信息
      List<AcceptFile> uploadedFiles = [];
      try {
        // 获取 multipart 请求的Content-Type
        var contentType = request.headers['Content-Type'];
        if (contentType == null ||
            !contentType.contains('multipart/form-data')) {
          return Response.badRequest(
              body: 'Content-Type must be multipart/form-data');
        }
        updateHomeProgress("正在接收");
        // 获取分隔符
        var boundary = contentType.split('boundary=')[1];
        var transformer = MimeMultipartTransformer(boundary);
        var parts = await transformer.bind(request.read()).toList();
        // 遍历每一个部分，处理文件上传
        for (var part in parts) {
          var contentDisposition = part.headers['content-disposition'];
          var fileName = _getFileNameFromDisposition(contentDisposition);

          if (fileName != null) {
            // 获取外部公共目录（如 Download）
            String? docPath;
            if (Platform.isAndroid) {
              // 目标路径为外部公共目录 - 下载目录
              docPath = "/storage/emulated/0/Download/Hand";
              var dir = Directory(docPath);
              if (!dir.existsSync()) {
                dir.createSync(recursive: true);
              }
            } else {
              // 对于 iOS 或其他平台，使用临时目录
              docPath = (await getDownloadsDirectory())?.path;
              docPath = docPath?.replaceFirst("Library/Caches", "Documents/");
            }
            if (docPath == null) {
              print("无法获取有效的目录路径");
            }
            String filePath = '$docPath/$fileName';
            var file = File(filePath);
            // 创建上传目录（如果不存在的话）
            await file.create(recursive: true);
            // 写入文件数据
            await file.writeAsBytes(await part.fold<List<int>>(
                [], (previous, element) => previous..addAll(element)));
            // 根据文件扩展名判断文件类型（示例）
            FileType fileType = _getFileType(fileName);
            // 创建 AcceptFile 对象来存储文件信息
            String currentTime = DateTime.now().toIso8601String();
            AcceptFile acceptFile =
                AcceptFile(fileName, filePath, fileType, currentTime);
            // 将文件信息添加到文件列表中
            uploadedFiles.add(acceptFile);
          }
        }

        // 调用回调函数，传递已上传的文件列表
        receiveFileCallback(uploadedFiles);
        updateHomeProgress("文件接收完成");

        // 返回成功的响应
        return Response.ok('File upload successful');
      } catch (e) {
        print('Exception occurred: $e');
        updateHomeProgress("文件接收失败");
        return Response.internalServerError(
            body: 'Error during file upload: $e');
      }
    });

    // 创建 HTTP 服务器并监听指定端口
    var handler =
        const Pipeline().addMiddleware(logRequests()).addHandler(router);

    var server = await shelf_io.serve(handler, '0.0.0.0', 0);
    MyApp.port = server.port;
    print('Server running on http://${server.address.host}:${server.port}');
  }

  /// 从 Content-Disposition 头部获取文件名
  String? _getFileNameFromDisposition(String? contentDisposition) {
    if (contentDisposition == null) return null;
    final regex = RegExp(r'filename="(.+)"');
    final match = regex.firstMatch(contentDisposition);
    return match?.group(1);
  }

  /// 根据文件扩展名获取文件类型（示例）
  FileType _getFileType(String filename) {
    String extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return FileType.image;
      case 'mp4':
      case 'avi':
      case 'mkv':
        return FileType.video;
      default:
        return FileType.custom;
    }
  }
}
