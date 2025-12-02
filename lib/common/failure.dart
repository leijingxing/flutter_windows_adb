/// [Failure] 用于包装可预期的业务错误，便于 UI 展示。
class Failure implements Exception {
  /// [message] 具体的错误信息。
  final String message;

  /// [cause] 可能的底层异常或错误对象。
  final Object? cause;

  /// 构造 [Failure]，带有可选的底层原因。
  Failure(this.message, {this.cause});

  @override
  String toString() => 'Failure: $message';
}
