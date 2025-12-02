/// [AppInfo] 表示一条安装包信息，包含版本与来源。
class AppInfo {
  /// [packageName] 应用包名，如 `com.example.demo`。
  final String packageName;

  /// [userApp] 是否为用户应用（true 表示第三方应用，false 表示系统应用）。
  final bool userApp;

  /// [versionName] 可读版本号，例如 `1.2.0`。
  final String? versionName;

  /// [versionCode] 数字版本号，可能为空。
  final String? versionCode;

  /// 构造 [AppInfo]，用于封装应用元数据。
  AppInfo({
    required this.packageName,
    required this.userApp,
    this.versionName,
    this.versionCode,
  });
}
