import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dapur_flow/main.dart';
import 'package:dapur_flow/providers/locale_provider.dart';
import 'package:dapur_flow/providers/task_provider.dart';
import 'package:dapur_flow/services/settings_service.dart';

void main() {
  testWidgets('App initializes', (WidgetTester tester) async {
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

    expect(find.byType(AturAjahApp), findsOneWidget);
  });
}
