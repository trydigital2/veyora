import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:veyors/app.dart';
import 'package:veyors/core/providers.dart';
import 'package:veyors/core/router/main_shell.dart';
import 'package:veyors/core/storage/local_store.dart';
import 'package:veyors/features/onboarding/presentation/onboarding_screen.dart';
import 'package:veyors/features/onboarding/presentation/splash_screen.dart';

void main() {
  testWidgets('boots from splash into onboarding', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(LocalStore(prefs))],
        child: const VeyoraApp(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(OnboardingScreen), findsOneWidget);
  });

  testWidgets('demo sign-in reaches the dashboard shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStoreProvider.overrideWithValue(LocalStore(prefs))],
        child: const VeyoraApp(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('Skip'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.ensureVisible(find.text('Explore a demo account'));
    await tester.pump();
    await tester.tap(find.text('Explore a demo account'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.byType(MainShell), findsOneWidget);
  });
}
