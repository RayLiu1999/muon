import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:muon/presentation/providers/audio_provider.dart';

part 'sleep_timer_provider.g.dart';

/// 睡眠定時狀態
///
/// 儲存剩餘秒數。null 表示未啟用定時器，0 表示時間到。
@Riverpod(keepAlive: true)
class SleepTimer extends _$SleepTimer {
  Timer? _timer;

  @override
  int? build() {
    // 當 Provider 被銷毀時取消計時器
    ref.onDispose(() {
      _timer?.cancel();
    });
    return null; // 預設未啟用
  }

  /// 啟動睡眠定時器
  ///
  /// [minutes] 倒數分鐘數
  void start(int minutes) {
    _timer?.cancel();
    state = minutes * 60; // 轉換為秒

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = state;
      if (remaining == null || remaining <= 0) {
        cancel();
        // 時間到，暫停播放
        ref.read(audioHandlerProvider).pause();
        state = null;
        return;
      }
      state = remaining - 1;
    });
  }

  /// 取消睡眠定時器
  void cancel() {
    _timer?.cancel();
    _timer = null;
    state = null;
  }
}
