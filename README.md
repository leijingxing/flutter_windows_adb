## flutter_adb 桌面工具（Windows）

Flutter 桌面版 ADB 工具，分模块覆盖常用设备管理、应用管理、文件传输、实时日志、Shell 控制与投屏预览。

### 截图预览
1. 设备管理：img/img.png  
2. App 管理：img/img_1.png  
3. 文件浏览：img/img_2.png  
4. 实时日志：img/img_3.png  
5. Shell / 控制：img/img_4.png  
6. 投屏预览：img/img_5.png  

### 运行
```bash
flutter pub get
flutter run -d windows
```

### 模块与功能
- **设备管理**：列出设备（adb devices -l），输入 IP:Port 连接/断开，切换 TCPIP，点击列表项即可选中当前设备（全局共享）。
- **应用管理**：选择设备后，列出包名（含仅用户应用）、APK 安装/覆盖、卸载、启动组件、强停。选中列表项会填充包名输入。
- **文件浏览**：选择设备后，浏览远程路径、拉取文件到本地、推送本地文件到设备。
- **实时日志**：Android Studio 风格 logcat：
  - 设备选择、级别过滤（ALL/V/D/I/W/E/F）、关键词过滤（tag/内容子串）、隐藏时间戳。
  - 可调整字号、可选择/复制文本。
  - 自动跟随滚动，向上滚动自动暂停，显示“恢复跟随”按钮可重新追踪。
  - 开始/停止、清屏。
- **Shell / 控制**：命令输入/执行，常用命令下拉预设（pm list、getprop、meminfo 等），重启模式选择，端口转发/反向转发。
- **投屏预览**：基于 `adb exec-out screencap -p` 的低帧率预览，支持调整抓帧间隔、开始/停止。适合截图/预览，非高帧率投屏。

### 依赖与路径
- 默认使用环境中的 `adb` 可执行（可在 `common/adb_config.dart` 配置自定义路径或超时）。
- Windows 桌面端入口：`lib/main.dart`，导航壳：`lib/ui/home_shell.dart`。

### 关键目录
- `lib/models`：设备、应用、文件、日志等模型。
- `lib/services`：ADB 执行器、设备/App/文件日志/Shell/投屏服务。
- `lib/ui/pages`：对应模块页面（device/app/file_log/logcat/shell_control/screen_mirror）。
- `lib/ui/widgets`：设备选择下拉等公共组件。

### 使用提示
1. 先到“设备管理”刷新并点击目标设备，完成全局选中。
2. 其他页面的“选择设备”下拉将自动使用选中的设备，无需重复输入序列号。
3. 如果 logcat 或命令执行失败，请在终端确认 `adb devices -l` 可正常输出。
