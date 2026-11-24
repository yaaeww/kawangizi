import 'package:flutter_test/flutter_test.dart';
import 'package:kawangizi_mobile/app.dart';

void main() {
  testWidgets('KawangiziApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KawangiziApp());
    expect(find.byType(KawangiziApp), findsOneWidget);
  });
}
