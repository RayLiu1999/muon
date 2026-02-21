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

  /// 將毫米格式化為 mm:ss 或 h:mm:ss
  static String formatMs(int milliseconds) {
    return format(Duration(milliseconds: milliseconds));
  }

  /// 將字串格式 mm:ss 或 h:mm:ss 解析為 Duration
  static Duration parse(String formatted) {
    final parts = formatted.split(':');
    if (parts.length == 2) {
      final m = int.tryParse(parts[0]) ?? 0;
      final s = int.tryParse(parts[1]) ?? 0;
      return Duration(minutes: m, seconds: s);
    } else if (parts.length == 3) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = int.tryParse(parts[2]) ?? 0;
      return Duration(hours: h, minutes: m, seconds: s);
    }
    return Duration.zero;
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');
}
