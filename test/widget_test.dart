import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:benapp/app.dart';
import 'package:benapp/screens/ben_particle_splash_screen.dart';

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

  testWidgets('BENApp shows branded splash on startup', (tester) async {
    await tester.pumpWidget(const BENApp());

    expect(find.byType(MaterialApp), findsOneWidget);

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'BEN');

    expect(find.byType(BENParticleSplashScreen), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
