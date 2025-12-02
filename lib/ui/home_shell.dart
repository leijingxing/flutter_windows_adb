import 'package:flutter/material.dart';

import '../common/adb_config.dart';
import '../services/adb_executor.dart';
import '../services/app_service.dart';
import '../services/device_service.dart';
import '../services/file_log_service.dart';
import '../services/shell_control_service.dart';
import '../services/screen_mirror_service.dart';
import 'pages/logcat_page.dart';
import 'pages/app_page.dart';
import 'pages/device_page.dart';
import 'pages/file_log_page.dart';
import 'pages/shell_control_page.dart';
import 'pages/screen_mirror_page.dart';

/// [HomeShell] 为应用入口容器，提供侧边导航与模块注入。
class HomeShell extends StatefulWidget {
  /// [HomeShell] 构造函数，无额外入参。
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  /// [_selectedIndex] 当前选中的导航索引。
  int _selectedIndex = 0;

  /// [_config] ADB 配置，包含路径与超时。
  late final AdbConfig _config;

  /// [_executor] ADB 命令执行器。
  late final AdbExecutor _executor;

  /// [_deviceService] 设备管理服务。
  late final DeviceService _deviceService;

  /// [_appService] 应用管理服务。
  late final AppService _appService;

  /// [_fileLogService] 文件与日志服务。
  late final FileLogService _fileLogService;

  /// [_shellControlService] Shell/控制服务。
  late final ShellControlService _shellControlService;

  /// [_screenMirrorService] 屏幕投屏服务。
  late final ScreenMirrorService _screenMirrorService;

  /// [_pages] 需要展示的页面组件列表。
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _config = AdbConfig(); // 默认使用环境变量中的 adb。
    _executor = AdbExecutor(_config);
    _deviceService = DeviceService(_executor);
    _appService = AppService(_executor);
    _fileLogService = FileLogService(_executor);
    _shellControlService = ShellControlService(_executor);
    _screenMirrorService = ScreenMirrorService(_executor);
    _pages = [
      DevicePage(deviceService: _deviceService),
      AppPage(appService: _appService),
      FileLogPage(fileLogService: _fileLogService),
      LogcatPage(fileLogService: _fileLogService),
      ShellControlPage(shellControlService: _shellControlService),
      ScreenMirrorPage(screenMirrorService: _screenMirrorService),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.devices),
                label: Text('设备管理'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.apps),
                label: Text('App 管理'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.folder),
                label: Text('文件与日志'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.list_alt),
                label: Text('实时日志'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.terminal),
                label: Text('Shell / 控制'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.cast),
                label: Text('投屏预览'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _pages[_selectedIndex]),
        ],
      ),
    );
  }
}
