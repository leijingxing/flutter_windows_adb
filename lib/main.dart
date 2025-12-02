import 'package:flutter/material.dart';
import 'ui/home_shell.dart';

void main() {
  runApp(const AdbDesktopApp());
}

/// [AdbDesktopApp] 是桌面 ADB 工具的根组件，负责注入主题与导航。
class AdbDesktopApp extends StatelessWidget {
  /// [AdbDesktopApp] 构造函数，无额外入参。
  const AdbDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter ADB 桌面工具',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF5F7FA),
      ),
      home: const HomeShell(),
    );
  }
}
