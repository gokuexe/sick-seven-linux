import 'package:flutter_test/flutter_test.dart';

import 'package:sick_seven/main.dart';

void main() {
  testWidgets('muestra la pantalla de título', (WidgetTester tester) async {
    await tester.pumpWidget(const SickSevenApp());
    await tester.pump();

    expect(find.text('SICK SEVEN'), findsOneWidget);
    expect(find.text('Jugar contra 3 bots'), findsOneWidget);
  });
}
