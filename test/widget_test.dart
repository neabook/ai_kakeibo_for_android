import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ai_kakeibo/main.dart';

void main() {
  testWidgets('Dashboard screen loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: AiKakeiboApp(),
      ),
    );

    // Wait for the app to load
    await tester.pumpAndSettle();

    // Verify that the app title is displayed
    expect(find.text('AI家計簿'), findsOneWidget);

    // Verify that the FAB is displayed
    expect(find.text('支出を追加'), findsOneWidget);
  });
}
