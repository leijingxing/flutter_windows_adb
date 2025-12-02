import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../common/device_registry.dart';
import '../../models/log_entry.dart';
import '../../services/file_log_service.dart';
import '../widgets/device_selector.dart';

/// [LogcatPage] 专注实时日志展示，类似 Android Studio logcat。
class LogcatPage extends StatefulWidget {
  /// [fileLogService] 用于启动 logcat 流的服务。
  final FileLogService fileLogService;

  /// 构造 [LogcatPage]，注入服务。
  const LogcatPage({super.key, required this.fileLogService});

  @override
  State<LogcatPage> createState() => _LogcatPageState();
}

class _LogcatPageState extends State<LogcatPage> {
  /// [_logs] 保存滚动展示的日志列表。
  final List<LogEntry> _logs = [];

  /// [_filterController] 过滤关键词输入。
  final TextEditingController _filterController = TextEditingController();

  /// [_logSub] 日志流订阅，便于停止。
  StreamSubscription<LogEntry>? _logSub;

  /// [_scrollController] 控制自动滚动到底部。
  final ScrollController _scrollController = ScrollController();

  /// [_fontSize] 日志文字大小。
  double _fontSize = 12;

  /// [_showTimestamp] 是否显示时间戳。
  bool _showTimestamp = true;

  /// [_levelFilter] 日志级别过滤，ALL 表示不过滤。
  String _levelFilter = 'ALL';

  /// [_keyword] 当前关键词过滤，来源于输入框。
  String get _keyword => _filterController.text.trim();

  /// [_autoScrollEnabled] 是否自动跟随滚动到底部。
  bool _autoScrollEnabled = true;

  /// [_loading] 标记是否正在读取。
  bool _loading = false;

  /// [_startLog] 开始订阅 logcat。
  Future<void> _startLog() async {
    final device = _requireDeviceId();
    if (device == null) return;
    await _logSub?.cancel();
    setState(() {
      _logs.clear();
      _loading = true;
    });
    final stream = widget.fileLogService.tailLogcat(
      device,
      filter: _filterController.text.trim().isEmpty
          ? null
          : _filterController.text.trim(),
      clearFirst: true,
    );
    _logSub = stream.listen((entry) {
      if (!mounted) return;
      setState(() {
        _logs.add(entry);
      });
      _scrollToBottom();
    }, onError: (error) {
      if (!mounted) return;
      setState(() {
        _logs.add(LogEntry(
          timestamp: DateTime.now(),
          pid: '-',
          tag: 'ERROR',
          level: 'E',
          message: error.toString(),
        ));
        _loading = false;
      });
      _scrollToBottom();
    }, onDone: () {
      if (!mounted) return;
      setState(() => _loading = false);
    });
  }

  /// [_stopLog] 停止订阅 logcat。
  Future<void> _stopLog() async {
    await _logSub?.cancel();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  /// [_clearScreen] 清空当前显示。
  void _clearScreen() {
    setState(() => _logs.clear());
    _scrollToBottom(force: true);
  }

  /// [_scrollToBottom] 自动滚动到最新。
  void _scrollToBottom({bool force = false}) {
    if (!_autoScrollEnabled && !force) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
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
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _filterController,
                  decoration: const InputDecoration(
                    labelText: '过滤 (TAG/内容子串)',
                    hintText: '如 Activity 或 your.package',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _loading ? null : _startLog,
                icon: const Icon(Icons.play_arrow),
                label: const Text('开始'),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: _loading ? _stopLog : null,
                icon: const Icon(Icons.stop),
                label: const Text('停止'),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _clearScreen,
                child: const Text('清屏'),
              ),
              const SizedBox(width: 8),
              if (!_autoScrollEnabled)
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() => _autoScrollEnabled = true);
                    _scrollToBottom(force: true);
                  },
                  icon: const Icon(Icons.playlist_add_check),
                  label: const Text('恢复跟随'),
                ),
              if (!_autoScrollEnabled) const SizedBox(width: 8),
              IconButton(
                tooltip: '调整字号',
                onPressed: _showFontSizeDialog,
                icon: const Icon(Icons.text_fields),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              DropdownButton<String>(
                value: _levelFilter,
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('全部级别')),
                  DropdownMenuItem(value: 'V', child: Text('Verbose')),
                  DropdownMenuItem(value: 'D', child: Text('Debug')),
                  DropdownMenuItem(value: 'I', child: Text('Info')),
                  DropdownMenuItem(value: 'W', child: Text('Warn')),
                  DropdownMenuItem(value: 'E', child: Text('Error')),
                  DropdownMenuItem(value: 'F', child: Text('Fatal')),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _levelFilter = value);
                },
              ),
              FilterChip(
                label: const Text('隐藏时间戳'),
                selected: !_showTimestamp,
                onSelected: (value) {
                  setState(() => _showTimestamp = !value);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black,
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        '点击开始后实时日志显示在这里',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : Builder(builder: (context) {
                      final filtered =
                          _logs.where((e) => _passFilters(e)).toList();
                      return NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is UserScrollNotification) {
                            // 用户向上滚动时暂停自动跟随。
                            if (notification.direction ==
                                ScrollDirection.reverse) {
                              if (_autoScrollEnabled) {
                                setState(() => _autoScrollEnabled = false);
                              }
                            }
                          }
                          return false;
                        },
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final entry = filtered[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 2, horizontal: 8),
                              child: SelectableText(
                                _formatEntry(entry),
                                style: TextStyle(
                                  color: _colorForLevel(entry.level),
                                  fontFamily: 'Consolas',
                                  fontSize: _fontSize,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
            ),
          ),
        ],
      ),
    );
  }

  /// [_formatEntry] 生成单行字符串。
  String _formatEntry(LogEntry entry) {
    final String timePart =
        _showTimestamp ? '${entry.timestamp.toIso8601String()} ' : '';
    return '$timePart${entry.level}/${entry.tag}(${entry.pid}): ${entry.message}';
  }

  /// [_passFilters] 同时进行级别和关键词过滤。
  bool _passFilters(LogEntry entry) {
    if (_levelFilter != 'ALL') {
      if (!_passLevel(entry.level)) return false;
    }
    if (_keyword.isNotEmpty) {
      final kw = _keyword.toLowerCase();
      final text = '${entry.tag} ${entry.message}'.toLowerCase();
      if (!text.contains(kw)) return false;
    }
    return true;
  }

  /// [_passLevel] 根据选择的级别过滤。
  bool _passLevel(String level) {
    const priority = {'V': 0, 'D': 1, 'I': 2, 'W': 3, 'E': 4, 'F': 5};
    final current = priority[level.toUpperCase()] ?? 0;
    final threshold = priority[_levelFilter] ?? 0;
    return current >= threshold;
  }

  /// [_colorForLevel] 根据日志级别选择颜色。
  Color _colorForLevel(String level) {
    switch (level.toUpperCase()) {
      case 'E':
      case 'F':
        return Colors.redAccent;
      case 'W':
        return Colors.orangeAccent;
      case 'D':
        return Colors.blueAccent;
      default:
        return Colors.white;
    }
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _filterController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// [_showFontSizeDialog] 弹出字体大小调节框。
  void _showFontSizeDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        double tempSize = _fontSize;
        return AlertDialog(
          title: const Text('调整日志字号'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Slider(
                    min: 10,
                    max: 24,
                    divisions: 14,
                    label: '${tempSize.toStringAsFixed(0)}',
                    value: tempSize,
                    onChanged: (v) {
                      setState(() => tempSize = v);
                    },
                  ),
                  Text('当前: ${tempSize.toStringAsFixed(0)}'),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _fontSize = tempSize);
                Navigator.pop(context);
              },
              child: const Text('应用'),
            ),
          ],
        );
      },
    );
  }
}
