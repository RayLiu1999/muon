import 'package:flutter_test/flutter_test.dart';
import 'package:muon/core/utils/duration_formatter.dart';

void main() {
  group('DurationFormatter', () {
    test('格式化秒數 — 短時間顯示 mm:ss', () {
      expect(DurationFormatter.format(const Duration(seconds: 0)), '00:00');
      expect(DurationFormatter.format(const Duration(seconds: 5)), '00:05');
      expect(DurationFormatter.format(const Duration(seconds: 65)), '01:05');
      expect(
        DurationFormatter.format(const Duration(minutes: 3, seconds: 45)),
        '03:45',
      );
    });

    test('格式化秒數 — 長時間顯示 h:mm:ss', () {
      expect(
        DurationFormatter.format(const Duration(hours: 1)),
        '1:00:00',
      );
      expect(
        DurationFormatter.format(
          const Duration(hours: 2, minutes: 5, seconds: 30),
        ),
        '2:05:30',
      );
    });

    test('formatMs 將毫秒轉為格式化字串', () {
      expect(DurationFormatter.formatMs(180000), '03:00');
      expect(DurationFormatter.formatMs(3661000), '1:01:01');
    });
  });
}
