import '../common/failure.dart';
import '../models/command_result.dart';
import 'adb_executor.dart';

/// [ShellControlService] 处理 Shell、重启、截屏等进阶控制。
class ShellControlService {
  /// [executor] 执行 adb 命令的帮助器。
  final AdbExecutor executor;

  /// 构造 [ShellControlService]，注入执行器。
  ShellControlService(this.executor);

  /// [exec] 执行单次 shell 命令。
  Future<CommandResult> exec(String deviceId, String cmd) {
    return executor.run(['-s', deviceId, 'shell', cmd]);
  }

  /// [reboot] 重启设备，可指定模式。
  Future<void> reboot(String deviceId, {String? mode}) async {
    final args = <String>['-s', deviceId, 'reboot'];
    if (mode != null) args.add(mode);
    final result = await executor.run(args);
    if (!result.isOk) {
      throw Failure('重启失败: ${result.stderr}');
    }
  }

  /// [screencap] 截图并保存到本地路径。
  Future<String> screencap(String deviceId, String saveTo) async {
    final result = await executor.run(
        ['-s', deviceId, 'exec-out', 'screencap', '-p', '>', saveTo]);
    if (!result.isOk) {
      throw Failure('截图失败: ${result.stderr}');
    }
    return saveTo;
  }

  /// [screenrecord] 录屏，简单占位实现。
  Future<void> screenrecord(String deviceId,
      {required String saveTo, Duration? duration}) async {
    final args = <String>[
      '-s',
      deviceId,
      'shell',
      'screenrecord',
      if (duration != null) '--time-limit=${duration.inSeconds}',
      '/sdcard/demo_record.mp4',
    ];
    final result = await executor.run(args);
    if (!result.isOk) {
      throw Failure('录屏失败: ${result.stderr}');
    }
    // 此处示例未实现 pull，可结合 FileLogService.pull 将录屏拉取到 saveTo。
  }

  /// [portForward] 设置端口转发。
  Future<void> portForward(String deviceId, String local, String remote) async {
    final result =
        await executor.run(['-s', deviceId, 'forward', local, remote]);
    if (!result.isOk) {
      throw Failure('端口转发失败: ${result.stderr}');
    }
  }

  /// [portReverse] 设置反向端口转发。
  Future<void> portReverse(String deviceId, String remote, String local) async {
    final result =
        await executor.run(['-s', deviceId, 'reverse', remote, local]);
    if (!result.isOk) {
      throw Failure('反向转发失败: ${result.stderr}');
    }
  }
}
