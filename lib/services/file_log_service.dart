import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../common/failure.dart';
import '../models/file_entry.dart';
import '../models/log_entry.dart';
import 'adb_executor.dart';

/// [FileLogService] 处理文件浏览与 logcat 读取。
class FileLogService {
  /// [executor] 执行 adb 命令的帮助器。
  final AdbExecutor executor;

  /// 构造 [FileLogService]，注入执行器。
  FileLogService(this.executor);

  /// [listPath] 列出远程路径的文件与目录。
  Future<List<FileEntry>> listPath(String deviceId, String remotePath) async {
    final result =
        await executor.run(['-s', deviceId, 'shell', 'ls', '-l', remotePath]);
    if (!result.isOk) {
      throw Failure('读取目录失败: ${result.stderr}');
    }
    final List<FileEntry> entries = [];
    for (final line in result.stdout.split('\n')) {
      if (line.isEmpty || line.startsWith('total')) continue;
      final parts = line.split(RegExp(r'\\s+'));
      if (parts.length < 6) continue;
      final bool isDir = parts[0].startsWith('d');
      final int? size = int.tryParse(parts[4]);
      final String name = parts.sublist(5).join(' ');
      entries.add(FileEntry(path: '$remotePath/$name', isDir: isDir, size: size));
    }
    return entries;
  }

  /// [pull] 从设备拉取文件。
  Future<void> pull(String deviceId, String remotePath, String localPath) async {
    final result = await executor.run(['-s', deviceId, 'pull', remotePath, localPath]);
    if (!result.isOk) {
      throw Failure('拉取文件失败: ${result.stderr}');
    }
  }

  /// [push] 向设备推送文件。
  Future<void> push(String deviceId, String localPath, String remotePath) async {
    final result = await executor.run(['-s', deviceId, 'push', localPath, remotePath]);
    if (!result.isOk) {
      throw Failure('推送文件失败: ${result.stderr}');
    }
  }

  /// [tailLogcat] 持续读取 logcat，这里提供示例流；真实场景应使用 Process 的流。
  Stream<LogEntry> tailLogcat(String deviceId,
      {String? filter, bool clearFirst = false}) async* {
    if (clearFirst) {
      await clearLogcat(deviceId);
    }
    final List<String> args = ['-s', deviceId, 'logcat', '-v', 'time'];
    if (filter != null && filter.isNotEmpty) {
      args.add(filter);
    }

    final Process process = await Process.start(
      executor.config.adbPath,
      args,
      runInShell: true,
    );

    final StreamController<LogEntry> controller = StreamController<LogEntry>();

    // stdout 逐行解析并转换为 LogEntry。
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      controller.add(_parseLogLine(line));
    }, onError: controller.addError);

    // stderr 也输出为错误事件，便于 UI 捕获。
    process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      controller.addError(Failure(line));
    }, onError: controller.addError);

    process.exitCode.then((_) {
      if (!controller.isClosed) controller.close();
    });

    controller.onCancel = () {
      process.kill();
    };

    yield* controller.stream;
  }

  /// [clearLogcat] 清空日志缓存。
  Future<void> clearLogcat(String deviceId) async {
    final result = await executor.run(['-s', deviceId, 'logcat', '-c']);
    if (!result.isOk) {
      throw Failure('清空 logcat 失败: ${result.stderr}');
    }
  }

  /// [_parseLogLine] 尝试解析 logcat -v time 的行格式，失败时以原文输出。
  LogEntry _parseLogLine(String line) {
    final RegExp exp = RegExp(
        r'^(?<date>\d{2}-\d{2})\s+(?<time>\d{2}:\d{2}:\d{2}\.\d{3})\s+(?<pid>\d+)\s+(?<tid>\d+)\s+(?<level>[A-Z])\s+(?<tag>\S+)\s*:\s(?<msg>.*)$');
    final match = exp.firstMatch(line);
    if (match == null) {
      return LogEntry(
        timestamp: DateTime.now(),
        pid: '-',
        tag: 'LOG',
        level: 'I',
        message: line,
      );
    }
    final now = DateTime.now();
    final String datePart = match.namedGroup('date') ?? '';
    final String timePart = match.namedGroup('time') ?? '';
    DateTime timestamp = DateTime.now();
    try {
      final parts = datePart.split('-');
      final time = timePart.split(RegExp(r'[:.]'));
      if (parts.length == 2 && time.length == 4) {
        timestamp = DateTime(
          now.year,
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(time[0]),
          int.parse(time[1]),
          int.parse(time[2]),
          int.parse(time[3]) * 1000,
        );
      }
    } catch (_) {
      timestamp = DateTime.now();
    }
    return LogEntry(
      timestamp: timestamp,
      pid: match.namedGroup('pid') ?? '-',
      tag: match.namedGroup('tag') ?? 'TAG',
      level: match.namedGroup('level') ?? 'I',
      message: match.namedGroup('msg') ?? '',
    );
  }
}
