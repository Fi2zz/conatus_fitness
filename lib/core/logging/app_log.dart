import 'package:flutter/foundation.dart';

/// 终端日志门面：UI（弹窗 / 播放条）只呈现给人看的摘要，排障细节
/// （原始异常、堆栈）统一从这里经 `debugPrint` 打进 flutter run 终端，
/// Android logcat 与 Xcode 控制台同样可见。
///
/// 调用点约定：**凡是把异常收敛成一句用户文案的地方，都要先落一条日志**，
/// 否则原始异常就只活在内存里，终端无从查证。
abstract final class AppLog {
  /// 错误：异常被捕获并降级（LLM 失败、校验拒收、音源失败等）。
  static void error(
    String tag,
    Object message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => _emit('E', tag, message, error, stackTrace);

  /// 告警：可继续但已偏离预期的情形（读盘失败退回默认值、事件丢弃）。
  static void warn(
    String tag,
    Object message, [
    Object? error,
    StackTrace? stackTrace,
  ]) => _emit('W', tag, message, error, stackTrace);

  /// 信息：正常链路的关键节点。
  static void info(String tag, Object message) =>
      _emit('I', tag, message, null, null);

  /// 接管框架与未捕获异常的终端输出。
  ///
  /// 构建期的框架异常（[FlutterError]）与逃逸到事件循环的异步异常
  /// （[PlatformDispatcher]) 此前只出现在红屏或系统日志里，这里统一落终端。
  static void watchGlobalErrors() {
    final FlutterExceptionHandler? previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      error(
        'flutter',
        details.exceptionAsString(),
        details.exception,
        details.stack,
      );
      previous?.call(details); // 保留框架自带的组件树上下文
    };
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      AppLog.error('uncaught', error, error, stack);
      return true; // 已落日志，避免重复上报
    };
  }

  static void _emit(
    String level,
    String tag,
    Object message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final StringBuffer buffer = StringBuffer('[$level][$tag] $message');
    if (error != null) buffer.write('\n  $error');
    debugPrint(buffer.toString());
    if (stackTrace != null) debugPrint(stackTrace.toString());
  }
}
