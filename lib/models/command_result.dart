/// [CommandResult] 封装一次 ADB/进程执行的结果。
class CommandResult {
  /// [exitCode] 进程退出码，0 表示成功。
  final int exitCode;

  /// [stdout] 标准输出文本。
  final String stdout;

  /// [stderr] 错误输出文本。
  final String stderr;

  /// 构造 [CommandResult]，用于统一返回值。
  CommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  /// [isOk] 快捷判断命令是否成功。
  bool get isOk => exitCode == 0;
}
