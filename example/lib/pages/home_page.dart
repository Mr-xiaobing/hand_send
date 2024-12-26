import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hand_transmit/main.dart';
import 'package:hand_transmit/pages/camera_page.dart';
import 'package:hand_transmit/service/server.dart';
import 'package:open_file/open_file.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomePageState();
  }
}

class _HomePageState extends State<HomePage> {
  // 用于存储选择的图片和视频文件
  List<AssetEntity> _selectedAssets = MyApp.selectedAssets;

  List<AcceptFile> _acceptFile = [];

  FileServer? fileServer;

  String homeProgress = "";

  double opacity = 1;

  int _selectedIndex = 0; // 当前页索引

  // 自定义文本代理，强制显示中文
  final AssetPickerTextDelegate _customTextDelegate =
      const AssetPickerTextDelegate();

  @override
  void initState() {
    super.initState();
    _initializeData();
    fileServer?.startServer();
  }

  void _initializeData() async {
    fileServer = FileServer(updateAcception, updateServerProgress);
  }

  void updateCameraProgress(String progress) {
    setState(() {
      homeProgress = progress;
    });
  }

  void clearHomeSelectFile() {
    setState(() {
      _selectedAssets = [];
      MyApp.selectedAssets = [];
    });
  }

  // 打开图片和视频选择器
  Future<void> _pickAssets() async {
    final List<AssetEntity>? pickedAssets = await AssetPicker.pickAssets(
      context, // 同时选择图片和视频
      pickerConfig: AssetPickerConfig(
        maxAssets: 9,
        requestType: RequestType.common,
        textDelegate: _customTextDelegate,
      ),
    );

    if (pickedAssets != null) {
      MyApp.selectedAssets = pickedAssets;
      setState(() {
        _selectedAssets = pickedAssets;
      });
    }
  }

  void updateServerProgress(String progress) {
    setState(() {
      homeProgress = progress;
    });
  }

  void updateAcception(List<AcceptFile> acceptFiles) {
    setState(() {
      _acceptFile = acceptFiles;
    });
  }

  // 使用系统播放器打开视频
  Future<void> _openVideoWithSystemPlayer(String filePath) async {
    await OpenFile.open(filePath);
  }

  Future<void> _openAssetsVideoWithSystemPlayer(AssetEntity asset) async {
    final file = await asset.file; // 获取文件
    if (file != null) {
      final filePath = file.path;
      await OpenFile.open(filePath);
    }
  }

  // 跳转到指定 URL
  // 跳转函数
  Future<void> _launchURL(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  // 左右箭头点击事件
  void _onPageChanged(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    final Uri bilibiliUrl = Uri.parse('bilibili://space/13798521');
    final Uri xiaohongshu =
        Uri.parse('xhsdiscover://user/5f479d190000000001007bbc');

    final Uri douyinUrl =
        Uri.parse('snssdk1128://user/profile/1354209176853277');
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "手势传输",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 7, 132, 234),
        toolbarHeight: 40.0,
        leading: Container(
          margin: const EdgeInsets.all(3),
          child: Image.asset("assets/logo.png"),
        ),
      ),
      body: Container(
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.all(5),
        child: ListView(
          children: [
            // 发送区域
            Column(
              children: [
                const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "发送区域",
                      style: TextStyle(
                          fontSize: 18.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (_selectedAssets.isNotEmpty)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        child: PageView.builder(
                          itemCount: _selectedAssets.length,
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) {
                            final asset = _selectedAssets[index];
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // 判断图片或视频
                                if (asset.type == AssetType.image)
                                  Image(
                                    image: AssetEntityImageProvider(asset),
                                    width: screenWidth * 0.8,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  )
                                else if (asset.type == AssetType.video)
                                  GestureDetector(
                                      onTap: () {
                                        _openAssetsVideoWithSystemPlayer(
                                            asset); // 点击时调用打开视频的函数
                                      },
                                      child: Column(
                                        children: [
                                          const Center(
                                            child: Icon(
                                              Icons.videocam,
                                              size: 50,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              asset.title ?? '',
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )),
                              ],
                            );
                          },
                        ),
                      ),

                      // 左右箭头按钮
                      Positioned(
                        left: 10,
                        child: IconButton(
                          icon: Icon(Icons.arrow_left, color: Colors.green),
                          onPressed: _selectedIndex > 0
                              ? () {
                                  setState(() {
                                    _selectedIndex--;
                                  });
                                }
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 10,
                        child: IconButton(
                          icon: Icon(Icons.arrow_right, color: Colors.green),
                          onPressed: _selectedIndex < _selectedAssets.length - 1
                              ? () {
                                  setState(() {
                                    _selectedIndex++;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: screenWidth * 0.8,
                    height: 200,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Text(
                      "无图片/视频",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                const SizedBox(height: 15),
                InkWell(
                  onTap: _pickAssets,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.image, size: 24),
                        SizedBox(width: 8),
                        Text('选择图片/视频'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // 接收区域

            Column(
              children: [
                const Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8.0),
                    child: Text(
                      "接收区域",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 0),
                if (_acceptFile.isNotEmpty)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        height: 200,
                        child: PageView.builder(
                          itemCount: _acceptFile.length,
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) {
                            final asset = _acceptFile[index];
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (asset.fileType == FileType.image)
                                  Image.file(
                                    File(asset.filePath),
                                    width: screenWidth * 0.8,
                                    height: 200,
                                    fit: BoxFit.cover,
                                  )
                                else if (asset.fileType == FileType.video)
                                  GestureDetector(
                                      onTap: () {
                                        _openVideoWithSystemPlayer(
                                            asset.filePath); // 打开接收到的视频
                                      },
                                      child: Column(
                                        children: [
                                          const Center(
                                            child: Icon(
                                              Icons.videocam,
                                              size: 50,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              asset.filename,
                                              style: const TextStyle(
                                                color: Colors.red,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )),
                                // 显示文件名（包括后缀）
                              ],
                            );
                          },
                        ),
                      ),
                      // 左右箭头按钮
                      Positioned(
                        left: 10,
                        child: IconButton(
                          icon: Icon(Icons.arrow_left, color: Colors.green),
                          onPressed: _selectedIndex > 0
                              ? () {
                                  setState(() {
                                    _selectedIndex--;
                                  });
                                }
                              : null,
                        ),
                      ),
                      Positioned(
                        right: 10,
                        child: IconButton(
                          icon: Icon(Icons.arrow_right, color: Colors.green),
                          onPressed: _selectedIndex < _acceptFile.length - 1
                              ? () {
                                  setState(() {
                                    _selectedIndex++;
                                  });
                                }
                              : null,
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    width: screenWidth * 0.8,
                    height: 200,
                    color: Colors.grey[300],
                    alignment: Alignment.center,
                    child: const Text(
                      "无图片/视频",
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                CameraPage(
                    updateProgress: updateCameraProgress,
                    clearSelectFile: clearHomeSelectFile),
                Text(
                  "状态:$homeProgress",
                  style: const TextStyle(fontSize: 20),
                ),
                // const SizedBox(height: 5),
                // Text('使用方法(关注我，分享更多有趣的想法)'),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // 提示文字
                // B站主页按钮
                ElevatedButton(
                  onPressed: () => _launchURL(bilibiliUrl),
                  child: Text('B站'),
                ),
                SizedBox(width: 5), // 按钮间的间距
                // 微信公众号按钮
                ElevatedButton(
                  onPressed: () => _launchURL(xiaohongshu),
                  child: Text('小红书'),
                ),
                SizedBox(width: 5), // 按钮间的间距
                // 抖音主页按钮
                ElevatedButton(
                  onPressed: () => _launchURL(douyinUrl),
                  child: Text('抖音'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
