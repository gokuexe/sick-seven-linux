import 'package:flutter_test/flutter_test.dart';

import 'package:sick_seven/main.dart';

void main() {
  testWidgets('muestra la pantalla de título', (WidgetTester tester) async {
    await tester.pumpWidget(const SickSevenApp());
    await tester.pump();

    expect(find.text('LA ÚLTIMA\nMANO'), findsOneWidget);
    expect(find.text('SENTARSE A LA MESA'), findsOneWidget);
  });
}
