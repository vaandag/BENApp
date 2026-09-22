import 'package:flutter_test/flutter_test.dart';
import 'package:benapp/app.dart';

void main() {
  testWidgets('BENApp starts', (tester) async {
    await tester.pumpWidget(const BENApp());
    expect(find.text('BEN'), findsWidgets);
  });
}
