import 'package:flutter/material.dart';

import '../../common/device_registry.dart';
import '../../models/app_info.dart';
import '../../services/app_service.dart';
import '../widgets/device_selector.dart';

/// [AppPage] 负责展示应用列表并提供安装/卸载/启动等操作。
class AppPage extends StatefulWidget {
  /// [appService] 应用相关的服务实例。
  final AppService appService;

  /// 构造 [AppPage]，注入应用服务。
  const AppPage({super.key, required this.appService});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  /// [_apkPathController] 本地 APK 路径输入。
  final TextEditingController _apkPathController = TextEditingController();

  /// [_packageController] 包名输入框。
  final TextEditingController _packageController = TextEditingController();

  /// [_appsFuture] 应用列表查询的 Future。
  Future<List<AppInfo>>? _appsFuture;

  /// [_userOnly] 是否仅显示用户应用。
  bool _userOnly = true;

  /// [_loading] 按钮加载态标记。
  bool _loading = false;

  /// [_refresh] 触发应用列表刷新。
  void _refresh() {
    final deviceId = _requireDeviceId();
    if (deviceId == null) return;
    setState(() {
      _appsFuture =
          widget.appService.listPackages(deviceId: deviceId, userOnly: _userOnly);
    });
  }

  /// [_requireDeviceId] 获取当前选中设备，没有则提示。
  String? _requireDeviceId() {
    final device = DeviceRegistry.instance.selectedDevice.value;
    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先在顶部选择设备')),
      );
      return null;
    }
    return device.id;
  }

  /// [_withLoading] 包裹长任务的简单工具方法。
  Future<void> _withLoading(Future<void> Function() task) async {
    setState(() => _loading = true);
    try {
      await task();
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DeviceSelector(label: '选择设备', onChanged: (_) => _refresh()),
              ),
              const SizedBox(width: 8),
              FilterChip(
                label: const Text('仅用户应用'),
                selected: _userOnly,
                onSelected: (value) {
                  setState(() => _userOnly = value);
                  _refresh();
                },
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loading ? null : _refresh,
                icon: const Icon(Icons.list),
                label: const Text('加载列表'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _apkPathController,
                  decoration: const InputDecoration(
                    labelText: 'APK 路径',
                    hintText: '选择本地 APK...',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading
                    ? null
                    : () => _withLoading(() async {
                          final deviceId = _requireDeviceId();
                          if (deviceId == null) return;
                          await widget.appService.installApk(
                            deviceId,
                            _apkPathController.text.trim(),
                            replace: true,
                          );
                          _refresh();
                        }),
                child: const Text('安装/覆盖'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _packageController,
                  decoration: const InputDecoration(
                    labelText: '包名',
                    hintText: 'com.example.demo',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _withLoading(() async {
                          final deviceId = _requireDeviceId();
                          if (deviceId == null) return;
                          await widget.appService.uninstall(
                            deviceId,
                            _packageController.text.trim(),
                          );
                          _refresh();
                        }),
                child: const Text('卸载'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _withLoading(() async {
                          final deviceId = _requireDeviceId();
                          if (deviceId == null) return;
                          await widget.appService.startActivity(
                            deviceId,
                            '${_packageController.text.trim()}/.MainActivity',
                          );
                        }),
                child: const Text('启动'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _withLoading(() async {
                          final deviceId = _requireDeviceId();
                          if (deviceId == null) return;
                          await widget.appService.forceStop(
                            deviceId,
                            _packageController.text.trim(),
                          );
                        }),
                child: const Text('强停'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _appsFuture == null
                ? const Center(child: Text('先输入设备序列号并加载列表'))
                : FutureBuilder<List<AppInfo>>(
                    future: _appsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('加载失败：${snapshot.error}'));
                      }
                      final apps = snapshot.data ?? [];
                      if (apps.isEmpty) {
                        return const Center(child: Text('没有应用或过滤条件为空'));
                      }
                      return ListView.builder(
                        itemCount: apps.length,
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          return ListTile(
                            dense: true,
                            leading:
                                Icon(app.userApp ? Icons.android : Icons.shield),
                            title: Text(app.packageName),
                            subtitle: Text(
                                '类型: ${app.userApp ? '用户' : '系统'} | 版本: ${app.versionName ?? '-'}'),
                            onTap: () {
                              _packageController.text = app.packageName;
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
    _apkPathController.dispose();
    _packageController.dispose();
    super.dispose();
  }
}
