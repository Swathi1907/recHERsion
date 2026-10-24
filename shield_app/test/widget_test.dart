
import 'package:flutter_test/flutter_test.dart';
import 'package:shield_app/main.dart';

void main() {
  testWidgets('SHIELD home screen renders', (tester) async {
    await tester.pumpWidget(const ShieldApp());

    expect(find.text('SHIELD'), findsOneWidget);
    expect(find.text('Your safety, your control'), findsOneWidget);
    expect(find.text('Need help?'), findsOneWidget);
    expect(find.text('SOS'), findsOneWidget);
  });

  testWidgets('SOS button displays prototype disclaimer', (tester) async {
    await tester.pumpWidget(const ShieldApp());

    await tester.tap(find.text('Emergency'));
    await tester.pumpAndSettle();

    expect(find.text('Emergency SOS'), findsOneWidget);
    expect(find.textContaining('This is a prototype'), findsOneWidget);
  });
}
