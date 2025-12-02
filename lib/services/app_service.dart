import '../common/failure.dart';
import '../models/app_info.dart';
import 'adb_executor.dart';

/// [AppService] 处理应用安装、卸载与查询。
class AppService {
  /// [executor] 执行 adb 命令的帮助器。
  final AdbExecutor executor;

  /// 构造 [AppService]，注入命令执行器。
  AppService(this.executor);

  /// [listPackages] 列出应用包名，可筛选用户应用。
  Future<List<AppInfo>> listPackages({
    required String deviceId,
    bool userOnly = false,
  }) async {
    final args = <String>['-s', deviceId, 'shell', 'pm', 'list', 'packages'];
    if (userOnly) {
      args.add('-3');
    }
    final result = await executor.run(args);
    if (!result.isOk) {
      throw Failure('获取应用列表失败: ${result.stderr}');
    }
    return result.stdout
        .split('\n')
        .where((line) => line.startsWith('package:'))
        .map((line) => line.replaceFirst('package:', '').trim())
        .where((pkg) => pkg.isNotEmpty)
        .map((pkg) => AppInfo(
              packageName: pkg,
              userApp: userOnly,
            ))
        .toList();
  }

  /// [installApk] 安装或替换 APK。
  Future<void> installApk(String deviceId, String apkPath,
      {bool replace = true}) async {
    final args = <String>[
      '-s',
      deviceId,
      'install',
      if (replace) '-r',
      apkPath,
    ];
    final result = await executor.run(args);
    if (!result.isOk) {
      throw Failure('安装 APK 失败: ${result.stderr}');
    }
  }

  /// [uninstall] 卸载指定包名，可选择保留数据。
  Future<void> uninstall(String deviceId, String packageName,
      {bool keepData = false}) async {
    final args = <String>['-s', deviceId, 'uninstall'];
    if (keepData) {
      args.add('-k');
    }
    args.add(packageName);
    final result = await executor.run(args);
    if (!result.isOk) {
      throw Failure('卸载失败: ${result.stderr}');
    }
  }

  /// [startActivity] 启动组件，例如 `pkg/.MainActivity`。
  Future<void> startActivity(String deviceId, String componentName) async {
    final result = await executor.run(
        ['-s', deviceId, 'shell', 'am', 'start', '-n', componentName]);
    if (!result.isOk) {
      throw Failure('启动 Activity 失败: ${result.stderr}');
    }
  }

  /// [forceStop] 强行停止应用。
  Future<void> forceStop(String deviceId, String packageName) async {
    final result =
        await executor.run(['-s', deviceId, 'shell', 'am', 'force-stop', packageName]);
    if (!result.isOk) {
      throw Failure('强停应用失败: ${result.stderr}');
    }
  }
}
