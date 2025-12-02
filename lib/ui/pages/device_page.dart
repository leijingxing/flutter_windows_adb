import 'package:flutter/material.dart';

import '../../common/device_registry.dart';
import '../../models/device.dart';
import '../../services/device_service.dart';
import '../widgets/device_selector.dart';

/// [DevicePage] 展示设备列表与基础连接/断开操作。
class DevicePage extends StatefulWidget {
  /// [deviceService] 设备相关的服务实例。
  final DeviceService deviceService;

  /// 构造 [DevicePage]，注入设备服务。
  const DevicePage({super.key, required this.deviceService});

  @override
  State<DevicePage> createState() => _DevicePageState();
}

class _DevicePageState extends State<DevicePage> {
  /// [_devicesFuture] 用于触发与缓存 FutureBuilder 的设备列表。
  late Future<List<Device>> _devicesFuture;

  /// [_connectController] 输入框控制器，填写 ip:port。
  final TextEditingController _connectController = TextEditingController();

  /// [_loading] 按钮加载态标记。
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _devicesFuture = widget.deviceService.listDevices();
  }

  /// [_refresh] 触发重新加载设备列表。
  void _refresh() {
    setState(() {
      _devicesFuture = widget.deviceService.listDevices();
    });
  }

  /// [_handleConnect] 调用 connect 并刷新列表。
  Future<void> _handleConnect() async {
    setState(() => _loading = true);
    try {
      await widget.deviceService.connect(_connectController.text.trim());
      _refresh();
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
                child: TextField(
                  controller: _connectController,
                  decoration: const InputDecoration(
                    labelText: '输入设备 IP:端口',
                    hintText: '示例：192.168.0.10:5555',
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _loading ? null : _handleConnect,
                icon: _loading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.link),
                label: const Text('连接'),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _loading ? null : _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('刷新'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const DeviceSelector(label: '当前选中设备'),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder<List<Device>>(
              future: _devicesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('加载失败：${snapshot.error}'),
                  );
                }
                final devices = snapshot.data ?? [];
                if (devices.isEmpty) {
                  return const Center(child: Text('暂无设备，请连接或插入设备'));
                }
                    return ListView.separated(
                      itemCount: devices.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: const Icon(Icons.phone_android),
                      title: Text(device.id),
                      subtitle: Text(
                          '型号: ${device.model} | 状态: ${device.state} | 连接: ${device.transport}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.link_off),
                            onPressed: () async {
                              await widget.deviceService.disconnect(device.id);
                              _refresh();
                            },
                          ),
                          onTap: () {
                            // 点击列表项即选中该设备，供其他页面使用。
                            DeviceRegistry.instance.selectDevice(device);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('已选中设备: ${device.id}')),
                            );
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
    _connectController.dispose();
    super.dispose();
  }
}
