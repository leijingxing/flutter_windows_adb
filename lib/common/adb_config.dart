/// [AdbConfig] 管理 adb 可执行路径与基础配置。
class AdbConfig {
  /// [adbPath] adb 可执行文件路径，默认为环境变量中的 `adb`。
  final String adbPath;

  /// [defaultTimeoutSeconds] 默认命令超时时间。
  final int defaultTimeoutSeconds;

  /// 构造 [AdbConfig]，可自定义 adb 路径和超时。
  AdbConfig({
    this.adbPath = 'adb',
    this.defaultTimeoutSeconds = 10,
  });
}
