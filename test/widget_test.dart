import 'package:flutter_test/flutter_test.dart';

import 'package:cadence/main.dart';

void main() {
  testWidgets('Cadence app shows the drafts title', (WidgetTester tester) async {
    await tester.pumpWidget(const CadenceApp());

    expect(find.text('DRAFTS'), findsOneWidget);
  });
}
