/// [LogEntry] 表示一条 logcat 行。
class LogEntry {
  /// [timestamp] 日志时间戳。
  final DateTime timestamp;

  /// [pid] 进程标识符。
  final String pid;

  /// [tag] 日志标签。
  final String tag;

  /// [level] 日志级别，通常是 V/D/I/W/E/F。
  final String level;

  /// [message] 日志正文。
  final String message;

  /// 构造 [LogEntry]，将解析结果封装成对象。
  LogEntry({
    required this.timestamp,
    required this.pid,
    required this.tag,
    required this.level,
    required this.message,
  });
}
