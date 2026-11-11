import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'constants/app_theme.dart';
import 'l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'providers/task_provider.dart';
import 'screens/splash_screen.dart';
import 'services/settings_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider.value(value: SettingsService.instance),
      ],
      child: const AturAjahApp(),
    ),
  );
}

class AturAjahApp extends StatelessWidget {
  const AturAjahApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'AturAjah',
      debugShowCheckedModeBanner: false,

      // Strictly Light Theme ONLY to preserve memory and legacy GPU performance
      themeMode: ThemeMode.light,
      theme: AppTheme.lightTheme,

      // Dynamic locale management (id_ID default, en_US secondary)
      locale: localeProvider.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Loading Splash Screen when app opens
      home: const SplashScreen(),
    );
  }
}
