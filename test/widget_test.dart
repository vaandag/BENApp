import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:benapp/app.dart';

const _secureStorageChannel =
    MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      _secureStorageChannel,
      (call) async => null,
    );
  });

  testWidgets('BENApp starts', (tester) async {
    await tester.pumpWidget(const BENApp());
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('BEN'), findsWidgets);
  });
}
