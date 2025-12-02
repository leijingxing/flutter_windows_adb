import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../common/adb_config.dart';
import '../common/failure.dart';
import '../models/command_result.dart';

/// [AdbExecutor] 负责实际执行 ADB 命令，统一超时与错误处理。
class AdbExecutor {
  /// [config] 保存 adb 路径与超时设置。
  final AdbConfig config;

  /// 构造 [AdbExecutor]，可注入自定义配置。
  AdbExecutor(this.config);

  /// [run] 执行一次 adb 命令，自动拼接 adb 可执行文件。
  Future<CommandResult> run(List<String> arguments,
      {String? workingDirectory, Duration? timeout}) async {
    final Duration effectiveTimeout =
        timeout ?? Duration(seconds: config.defaultTimeoutSeconds);

    try {
      final Process process = await Process.start(
        config.adbPath,
        arguments,
        workingDirectory: workingDirectory,
        runInShell: true,
      );

      final StringBuffer stdoutBuffer = StringBuffer();
      final StringBuffer stderrBuffer = StringBuffer();

      process.stdout.transform(utf8.decoder).listen(stdoutBuffer.write);
      process.stderr.transform(utf8.decoder).listen(stderrBuffer.write);

      final int exitCode = await process.exitCode
          .timeout(effectiveTimeout, onTimeout: () => -1);

      if (exitCode == -1) {
        process.kill();
        throw Failure('ADB 命令超时，已中断');
      }

      return CommandResult(
        exitCode: exitCode,
        stdout: stdoutBuffer.toString(),
        stderr: stderrBuffer.toString(),
      );
    } on ProcessException catch (error) {
      throw Failure('无法启动 adb，请检查 PATH 或 adb 路径', cause: error);
    }
  }

  /// [runBinary] 执行需要获取二进制输出的命令，如 `exec-out screencap -p`。
  Future<Uint8List> runBinary(List<String> arguments,
      {String? workingDirectory, Duration? timeout}) async {
    final Duration effectiveTimeout =
        timeout ?? Duration(seconds: config.defaultTimeoutSeconds);

    try {
      final Process process = await Process.start(
        config.adbPath,
        arguments,
        workingDirectory: workingDirectory,
        runInShell: true,
      );

      final BytesBuilder stdoutBuilder = BytesBuilder();
      final Future<String> stderrFuture =
          process.stderr.transform(utf8.decoder).join();

      // 收集二进制 stdout。
      final Future<void> stdoutFuture =
          process.stdout.forEach(stdoutBuilder.add);

      final int exitCode = await process.exitCode
          .timeout(effectiveTimeout, onTimeout: () => -1);

      if (exitCode == -1) {
        process.kill();
        throw Failure('ADB 命令超时，已中断');
      }

      await stdoutFuture;
      final String stderrText = await stderrFuture;

      if (exitCode != 0) {
        throw Failure('ADB 命令失败: $stderrText');
      }

      return stdoutBuilder.takeBytes();
    } on ProcessException catch (error) {
      throw Failure('无法启动 adb，请检查 PATH 或 adb 路径', cause: error);
    }
  }
}
