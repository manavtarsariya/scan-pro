import 'package:flutter_test/flutter_test.dart';
import 'package:scan_pro/main.dart';

void main() {
  testWidgets('ScanProApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ScanProApp(isOnboardingComplete: true));
    expect(find.text('ScanPro'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
