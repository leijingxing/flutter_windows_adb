import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../common/device_registry.dart';
import '../../services/screen_mirror_service.dart';
import '../widgets/device_selector.dart';

/// [ScreenMirrorPage] 提供基于 adb screencap 的低延迟投屏预览。
class ScreenMirrorPage extends StatefulWidget {
  /// [screenMirrorService] 屏幕抓帧服务实例。
  final ScreenMirrorService screenMirrorService;

  /// 构造 [ScreenMirrorPage]，注入抓帧服务。
  const ScreenMirrorPage({super.key, required this.screenMirrorService});

  @override
  State<ScreenMirrorPage> createState() => _ScreenMirrorPageState();
}

class _ScreenMirrorPageState extends State<ScreenMirrorPage> {
  /// [_frameBytes] 当前展示的屏幕 PNG 数据。
  Uint8List? _frameBytes;

  /// [_mirrorSub] 镜像流订阅，用于开始/停止。
  StreamSubscription<Uint8List>? _mirrorSub;

  /// [_intervalMs] 抓帧时间间隔毫秒。
  int _intervalMs = 500;

  /// [_error] 记录最近的错误信息。
  String? _error;

  /// [_mirroring] 标记当前是否处于投屏中。
  bool get _mirroring => _mirrorSub != null;

  /// [_startMirror] 开始基于 adb 的定时抓帧。
  Future<void> _startMirror() async {
    final deviceId = _requireDeviceId();
    if (deviceId == null) return;
    _mirrorSub?.cancel();
    setState(() {
      _error = null;
      _frameBytes = null;
    });
    final stream = widget.screenMirrorService.startMirroring(
      deviceId,
      interval: Duration(milliseconds: _intervalMs),
    );
    _mirrorSub = stream.listen((frame) {
      if (!mounted) return;
      setState(() => _frameBytes = frame);
    }, onError: (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    });
  }

  /// [_stopMirror] 停止抓帧订阅。
  Future<void> _stopMirror() async {
    await _mirrorSub?.cancel();
    if (!mounted) return;
    setState(() => _mirrorSub = null);
  }

  /// [_requireDeviceId] 获取当前选中设备，没有则提示。
  String? _requireDeviceId() {
    final device = DeviceRegistry.instance.selectedDevice.value;
    if (device == null) {
      setState(() => _error = '请先选择设备');
      return null;
    }
    return device.id;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('投屏预览（基于 adb screencap，非实时视频）',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DeviceSelector(
                  label: '选择设备',
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 200,
                child: Row(
                  children: [
                    const Text('间隔(ms):'),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Slider(
                        min: 200,
                        max: 2000,
                        divisions: 18,
                        label: '$_intervalMs',
                        value: _intervalMs.toDouble(),
                        onChanged: (v) {
                          setState(() => _intervalMs = v.toInt());
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _mirroring ? null : _startMirror,
                icon: const Icon(Icons.cast),
                label: const Text('开始投屏'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _mirroring ? _stopMirror : null,
                icon: const Icon(Icons.stop),
                label: const Text('停止'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
            ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black,
              ),
              child: _frameBytes == null
                  ? const Center(
                      child: Text(
                        '点击开始投屏，预览帧将显示在这里',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : InteractiveViewer(
                      child: Image.memory(
                        _frameBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '提示：基于 adb screencap 的方案性能有限，适合预览/截图，不适合高帧率实时投屏。若需流畅投屏，可考虑集成 scrcpy 或基于 h264 流解析。',
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mirrorSub?.cancel();
    super.dispose();
  }
}
