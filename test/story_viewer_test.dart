import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:benapp/models/memory.dart';
import 'package:benapp/screens/home_screen.dart';
import 'package:benapp/screens/memory_fullscreen_viewer.dart';
import 'package:benapp/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Memory story;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    story = Memory(
      id: 'story-test-1',
      ownerId: 2,
      ownerUsername: 'story-user',
      type: MemoryType.text,
      text: 'Story içeriği',
      postType: 'story',
      expiresAt: DateTime.now().add(const Duration(hours: 23)),
      createdAt: DateTime.now(),
    );
  });

  tearDown(() {
    AuthService.currentUser = null;
  });

  Future<void> openStory(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: HomeScreen(
            memories: const [],
            connectionMemories: [story],
            currentUser: const BenUser(
              id: 1,
              username: 'reader',
              email: 'reader@example.invalid',
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('story-user'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('Story opens its memory on a center tap', (tester) async {
    await openStory(tester);
    expect(find.text('STORY • 24 SAAT'), findsOneWidget);

    await tester.tapAt(const Offset(400, 300));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(MemoryFullscreenViewer), findsOneWidget);
  });

  testWidgets('Story closes after its six-second progress duration', (tester) async {
    await openStory(tester);
    expect(find.text('STORY • 24 SAAT'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('STORY • 24 SAAT'), findsNothing);
  });

  testWidgets('A vertical swipe dismisses the Story viewer', (tester) async {
    await openStory(tester);
    expect(find.text('STORY • 24 SAAT'), findsOneWidget);

    await tester.dragFrom(const Offset(400, 300), const Offset(0, 220));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('STORY • 24 SAAT'), findsNothing);
  });
}
