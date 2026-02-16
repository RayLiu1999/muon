/// 時間長度格式化工具
class DurationFormatter {
  DurationFormatter._();

  /// 將 Duration 格式化為 mm:ss 或 h:mm:ss
  static String format(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${_twoDigits(minutes)}:${_twoDigits(seconds)}';
    }
    return '${_twoDigits(minutes)}:${_twoDigits(seconds)}';
  }

  /// 將毫秒格式化為 mm:ss 或 h:mm:ss
  static String formatMs(int milliseconds) {
    return format(Duration(milliseconds: milliseconds));
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
