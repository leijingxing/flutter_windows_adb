import 'dart:async';
import 'dart:typed_data';

import '../common/failure.dart';
import 'adb_executor.dart';

/// [ScreenMirrorService] 负责获取屏幕帧并形成流，用于投屏预览。
class ScreenMirrorService {
  /// [executor] ADB 命令执行器。
  final AdbExecutor executor;

  /// 构造 [ScreenMirrorService]，注入执行器。
  ScreenMirrorService(this.executor);

  /// [captureFrame] 抓取单帧屏幕 PNG 字节。
  Future<Uint8List> captureFrame(String deviceId) async {
    final bytes = await executor.runBinary(
      ['-s', deviceId, 'exec-out', 'screencap', '-p'],
      timeout: const Duration(seconds: 5),
    );
    if (bytes.isEmpty) {
      throw Failure('未收到屏幕图像数据');
    }
    return bytes;
  }

  /// [startMirroring] 创建一个定时抓帧的流，供 UI 订阅。
  Stream<Uint8List> startMirroring(String deviceId,
      {Duration interval = const Duration(milliseconds: 500)}) async* {
    while (true) {
      final Uint8List frame = await captureFrame(deviceId);
      yield frame;
      await Future<void>.delayed(interval);
    }
  }
}
