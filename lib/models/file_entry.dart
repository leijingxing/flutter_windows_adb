/// [FileEntry] 表示设备上的一个文件或目录。
class FileEntry {
  /// [path] 绝对或相对路径。
  final String path;

  /// [isDir] 是否为目录。
  final bool isDir;

  /// [size] 文件大小（字节），目录可能为空。
  final int? size;

  /// [modified] 最后修改时间，可能为空。
  final DateTime? modified;

  /// 构造 [FileEntry]，用于文件浏览列表。
  FileEntry({
    required this.path,
    required this.isDir,
    this.size,
    this.modified,
  });
}
