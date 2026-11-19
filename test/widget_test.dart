import 'package:dapur_flow/main.dart';
import 'package:dapur_flow/providers/locale_provider.dart';
import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/screens/main_navigation_screen.dart';
import 'package:dapur_flow/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Smoke test: the real app boots from the splash screen into the two-tab
/// shell (Hari Ini / Jadwal) without throwing.
void main() {
  testWidgets('App initializes and reaches the main navigation', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LocaleProvider()),
          ChangeNotifierProvider(create: (_) => TaskProvider()),
          ChangeNotifierProvider.value(value: SettingsService.instance),
        ],
        child: const AturAjahApp(),
      ),
    );

    // Splash screen frame.
    await tester.pump();
    expect(find.byType(AturAjahApp), findsOneWidget);
    expect(find.text('AturAjah'), findsWidgets);

    // Services finish initialising, splash hands over to the main shell.
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(MainNavigationScreen), findsOneWidget);
    expect(find.text('Hari Ini'), findsOneWidget);
    expect(find.text('Jadwal'), findsOneWidget);
  });
}
