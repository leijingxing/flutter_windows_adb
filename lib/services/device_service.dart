import '../common/failure.dart';
import '../common/device_registry.dart';
import '../models/device.dart';
import 'adb_executor.dart';

/// [DeviceService] 封装设备相关 ADB 调用。
class DeviceService {
  /// [executor] 用于执行 adb 命令。
  final AdbExecutor executor;

  /// 构造 [DeviceService]，依赖注入执行器。
  DeviceService(this.executor);

  /// [listDevices] 查询当前可用设备列表。
  Future<List<Device>> listDevices() async {
    final result = await executor.run(['devices', '-l']);
    if (!result.isOk) {
      throw Failure('列出设备失败: ${result.stderr}');
    }
    // 简易解析示例，实际应更健壮。
    final List<Device> devices = [];
    for (final raw in result.stdout.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('List of devices')) continue;
      // adb devices -l 行示例：
      // emulator-5554 device product:sdk_gphone model:sdk_gphone_x86 device:generic_x86
      final parts = line.split(RegExp(r'\s+'));
      if (parts.isEmpty) continue;
      final id = parts.first;
      final state = parts.length > 1 ? parts[1] : 'unknown';
      final modelPart =
          parts.firstWhere((p) => p.startsWith('model:'), orElse: () => '');
      final model = modelPart.isNotEmpty ? modelPart.split(':').last : '未知';
      devices.add(Device(
        id: id,
        model: model,
        state: state,
        transport: id.contains(':') ? 'tcpip' : 'usb',
        ip: id.contains(':') ? id.split(':').first : null,
      ));
    }
    // 刷新全局设备注册表，供其他页面选择。
    DeviceRegistry.instance.updateDevices(devices);
    return devices;
  }

  /// [connect] 通过 ip:port 连接设备。
  Future<void> connect(String hostPort) async {
    final result = await executor.run(['connect', hostPort]);
    if (!result.isOk) {
      throw Failure('连接设备失败: ${result.stderr}');
    }
  }

  /// [disconnect] 断开指定 ip:port。
  Future<void> disconnect(String hostPort) async {
    final result = await executor.run(['disconnect', hostPort]);
    if (!result.isOk) {
      throw Failure('断开设备失败: ${result.stderr}');
    }
  }

  /// [enableTcpip] 将 USB 设备切换为 TCPIP 模式。
  Future<void> enableTcpip(String deviceId, int port) async {
    final result = await executor.run(['-s', deviceId, 'tcpip', '$port']);
    if (!result.isOk) {
      throw Failure('开启 TCPIP 模式失败: ${result.stderr}');
    }
  }
}
