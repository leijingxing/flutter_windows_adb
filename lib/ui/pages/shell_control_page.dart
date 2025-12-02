import 'package:flutter/material.dart';

import '../../common/device_registry.dart';
import '../../services/shell_control_service.dart';
import '../widgets/device_selector.dart';

/// [ShellControlPage] 提供 shell 命令、重启、端口映射等操作入口。
class ShellControlPage extends StatefulWidget {
  /// [shellControlService] Shell 控制服务实例。
  final ShellControlService shellControlService;

  /// 构造 [ShellControlPage]，注入服务。
  const ShellControlPage({super.key, required this.shellControlService});

  @override
  State<ShellControlPage> createState() => _ShellControlPageState();
}

class _ShellControlPageState extends State<ShellControlPage> {
  /// [_cmdController] Shell 命令输入。
  final TextEditingController _cmdController =
      TextEditingController(text: 'getprop ro.product.model');

  /// [_presets] 常用命令预设，包含描述与命令字符串。
  final List<Map<String, String>> _presets = [
    {'label': '列出包名', 'cmd': 'pm list packages'},
    {'label': '列出第三方包', 'cmd': 'pm list packages -3'},
    {'label': '查看设备信息', 'cmd': 'getprop ro.product.model'},
    {'label': '当前 Activity', 'cmd': 'dumpsys activity activities | head -n 20'},
    {'label': '内存信息', 'cmd': 'dumpsys meminfo'},
    {'label': 'CPU 占用', 'cmd': 'top -n 1 -m 10'},
    {'label': '查看端口占用', 'cmd': 'netstat -an'},
    {'label': '应用进程', 'cmd': 'ps -A | grep your.package'},
    {'label': '清理日志', 'cmd': 'logcat -c'},
    {'label': '拉起主界面', 'cmd': 'am start -a android.intent.action.MAIN -c android.intent.category.LAUNCHER'},
  ];

  /// [_output] 上一次命令的输出。
  String _output = '';

  /// [_loading] 按钮加载态标记。
  bool _loading = false;

  /// [_withLoading] 包裹长任务。
  Future<void> _withLoading(Future<void> Function() task) async {
    setState(() => _loading = true);
    try {
      await task();
    } finally {
      setState(() => _loading = false);
    }
  }

  /// [_runCommand] 执行 shell 命令并展示输出。
  Future<void> _runCommand() async {
    final device = _requireDeviceId();
    if (device == null) return;
    final cmd = _cmdController.text.trim();
    await _withLoading(() async {
      final result = await widget.shellControlService.exec(device, cmd);
      setState(() {
        _output = result.isOk ? result.stdout : result.stderr;
      });
    });
  }

  /// [_requireDeviceId] 获取当前选中设备，没有则提示。
  String? _requireDeviceId() {
    final device = DeviceRegistry.instance.selectedDevice.value;
    if (device == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择设备')),
      );
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
          Row(
            children: [
              Expanded(
                child: DeviceSelector(
                  label: '选择设备',
                  onChanged: (_) {},
                ),
              ),
              const SizedBox(width: 8),
              DropdownMenu<String>(
                width: 200,
                dropdownMenuEntries: const [
                  DropdownMenuEntry(value: 'reboot', label: '普通重启'),
                  DropdownMenuEntry(value: 'recovery', label: 'Recovery'),
                  DropdownMenuEntry(value: 'bootloader', label: 'Bootloader'),
                ],
                label: const Text('重启模式'),
                onSelected: (mode) {
                  if (mode == null) return;
                  _withLoading(() async {
                    final deviceId = _requireDeviceId();
                    if (deviceId == null) return;
                    await widget.shellControlService.reboot(
                        deviceId, mode: mode == 'reboot' ? null : mode);
                  });
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _withLoading(() async {
                          final deviceId = _requireDeviceId();
                          if (deviceId == null) return;
                          await widget.shellControlService.portForward(
                            deviceId,
                            'tcp:8000',
                            'tcp:8000',
                          );
                        }),
                child: const Text('端口转发 8000→8000'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _loading
                    ? null
                    : () => _withLoading(() async {
                          final deviceId = _requireDeviceId();
                          if (deviceId == null) return;
                          await widget.shellControlService.portReverse(
                            deviceId,
                            'tcp:9000',
                            'tcp:9000',
                          );
                        }),
                child: const Text('反向转发 9000→9000'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cmdController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Shell 命令',
              hintText: '例如：pm list packages',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: '选择常用命令'),
                  items: _presets
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item['cmd'],
                          child: Text('${item['label']} (${item['cmd']})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _cmdController.text = value;
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: () {
                  _cmdController.clear();
                },
                child: const Text('清空命令'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _loading ? null : _runCommand,
            icon: const Icon(Icons.play_arrow),
            label: const Text('执行'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: SingleChildScrollView(
                child: Text(
                  _output.isEmpty ? '命令输出将显示在这里' : _output,
                  style: const TextStyle(fontFamily: 'Consolas', fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _cmdController.dispose();
    super.dispose();
  }
}
