import 'package:flutter/material.dart';

import '../../common/device_registry.dart';
import '../../models/file_entry.dart';
import '../../services/file_log_service.dart';
import '../widgets/device_selector.dart';

/// [FileLogPage] 仅用于文件浏览/推送/拉取。
class FileLogPage extends StatefulWidget {
  /// [fileLogService] 文件服务实例。
  final FileLogService fileLogService;

  /// 构造 [FileLogPage]，注入服务。
  const FileLogPage({super.key, required this.fileLogService});

  @override
  State<FileLogPage> createState() => _FileLogPageState();
}

class _FileLogPageState extends State<FileLogPage> {
  /// [_remotePathController] 输入远程路径。
  final TextEditingController _remotePathController =
      TextEditingController(text: '/sdcard/');

  /// [_localPathController] 输入本地保存路径。
  final TextEditingController _localPathController =
      TextEditingController(text: 'C:/temp/');

  /// [_listFuture] 文件列表 Future。
  Future<List<FileEntry>>? _listFuture;

  /// [_loading] 按钮加载态标记。
  bool _loading = false;

  /// [_browse] 浏览指定路径。
  void _browse() {
    final device = _requireDeviceId();
    final path = _remotePathController.text.trim();
    if (device == null || path.isEmpty) return;
    setState(() {
      _listFuture = widget.fileLogService.listPath(device, path);
    });
  }

  /// [_withLoading] 包裹长任务。
  Future<void> _withLoading(Future<void> Function() task) async {
    setState(() => _loading = true);
    try {
      await task();
    } finally {
      setState(() => _loading = false);
    }
  }

  /// [_requireDeviceId] 获取当前选中设备，没有则提示。
  String? _requireDeviceId() {
    final device = DeviceRegistry.instance.selectedDevice.value;
    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择设备')),
      );
      return null;
    }
    return device.id;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('文件浏览', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DeviceSelector(label: '选择设备', onChanged: (_) => _browse()),
          TextField(
            controller: _remotePathController,
            decoration: const InputDecoration(labelText: '远程路径'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _loading ? null : _browse,
                icon: const Icon(Icons.folder_open),
                label: const Text('列出文件'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _withLoading(() async {
                          final deviceId = _requireDeviceId();
                          if (deviceId == null) return;
                          await widget.fileLogService.pull(
                            deviceId,
                            _remotePathController.text.trim(),
                            _localPathController.text.trim(),
                          );
                        }),
                child: const Text('拉取到本地路径'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _localPathController,
            decoration:
                const InputDecoration(labelText: '本地路径（推送/保存）'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _loading
                ? null
                : () => _withLoading(() async {
                      final deviceId = _requireDeviceId();
                      if (deviceId == null) return;
                      await widget.fileLogService.push(
                        deviceId,
                        _localPathController.text.trim(),
                        _remotePathController.text.trim(),
                      );
                    }),
            child: const Text('推送本地文件到设备'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _listFuture == null
                ? const Center(child: Text('等待选择路径'))
                : FutureBuilder<List<FileEntry>>(
                    future: _listFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                            child: Text('加载失败：${snapshot.error}'));
                      }
                      final entries = snapshot.data ?? [];
                      if (entries.isEmpty) {
                        return const Center(child: Text('空目录'));
                      }
                      return ListView.builder(
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return ListTile(
                            dense: true,
                            leading: Icon(
                                entry.isDir
                                    ? Icons.folder
                                    : Icons.insert_drive_file,
                                size: 18),
                            title: Text(entry.path),
                            subtitle: Text(
                                '大小: ${entry.size ?? 0} | 目录: ${entry.isDir ? '是' : '否'}'),
                            onTap: () {
                              if (entry.isDir) {
                                _remotePathController.text = entry.path;
                                _browse();
                              }
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _remotePathController.dispose();
    _localPathController.dispose();
    super.dispose();
  }
}
