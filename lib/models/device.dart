/// [Device] 表示一台通过 ADB 可见的设备/模拟器。
class Device {
  /// [id] 设备序列号，例如 `emulator-5554` 或 `192.168.0.10:5555`。
  final String id;

  /// [model] 设备型号名称，用于展示友好信息。
  final String model;

  /// [state] 当前状态，如 `device`、`offline`、`unauthorized`。
  final String state;

  /// [transport] 连接类型，例如 `usb` 或 `tcpip`。
  final String transport;

  /// [ip] 当为网络连接时可选的 IP 地址。
  final String? ip;

  /// 构造 [Device]，所有关键字段均在此初始化。
  Device({
    required this.id,
    required this.model,
    required this.state,
    required this.transport,
    this.ip,
  });

  @override
  bool operator ==(Object other) {
    return other is Device && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
