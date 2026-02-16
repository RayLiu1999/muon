import 'package:flutter_test/flutter_test.dart';
import 'package:muon/app.dart';
import 'helpers/pump_app.dart';

void main() {
  testWidgets('MuonApp 啟動並顯示標題', (WidgetTester tester) async {
    await tester.pumpWidget(
      createTestApp(child: const MuonApp()),
    );

    // 驗證 App 可以正常啟動
    expect(find.text('Muon'), findsWidgets);
  });
}
