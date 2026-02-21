import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';

/// 自動判斷是否需要跑馬燈的文字元件
///
/// 若文字渲染寬度大於可用寬度，則使用 [Marquee] 跑馬燈顯示，
/// 否則置中顯示普通的 [Text]。
class AutoScrollText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;

  const AutoScrollText({
    super.key,
    required this.text,
    this.style,
    this.textAlign = TextAlign.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 使用 TextPainter 計算文字實際寬度
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
        )..layout(minWidth: 0, maxWidth: double.infinity);

        // 如果文字寬度加上一點緩衝大於容器寬度，就啟用跑馬燈
        if (textPainter.width > constraints.maxWidth - 4) {
          return Marquee(
            text: text,
            style: style,
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.center,
            blankSpace: 40.0,
            velocity: 30.0,
            pauseAfterRound: const Duration(seconds: 2),
            startPadding: 0.0,
            accelerationDuration: const Duration(milliseconds: 500),
            accelerationCurve: Curves.easeIn,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          );
        } else {
          // 否則顯示普通文字即可
          return Align(
            alignment: Alignment.center,
            child: Text(
              text,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.visible,
              textAlign: textAlign,
            ),
          );
        }
      },
    );
  }
}
