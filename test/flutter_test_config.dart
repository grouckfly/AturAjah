import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'qa/support/test_harness.dart';

/// Runs before every test file in `test/`.
///
/// The app is Android/iOS-first, so the host VM has no sqflite plugin and no
/// notification plugin. This hook:
///  * boots sqflite on sqlite3 (own database directory per test isolate),
///  * fakes the platform channels (notifications, native alarm bridge),
///  * loads a real text font, because the default test font (Ahem) is a
///    square-glyph font that makes every label far wider than on a phone and
///    produces layout overflows that never happen on a real device.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await configureTestDatabase();
  SharedPreferences.setMockInitialValues(<String, Object>{});
  installMockPlatformChannels();
  await _loadPhoneFont();

  await testMain();
}

const List<String> _fontCandidates = [
  '/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',
  '/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf',
];

Future<void> _loadPhoneFont() async {
  for (final path in _fontCandidates) {
    final file = File(path);
    if (!file.existsSync()) continue;

    final bytes = await file.readAsBytes();
    final data = ByteData.sublistView(Uint8List.fromList(bytes));
    // Android maps the Material default family to "Roboto"; styles that leave
    // the family unset fall back to the engine default font, which flutter_test
    // provides as the square-glyph "Ahem". Register the real font for both so
    // every label is measured like on a device.
    for (final family in const ['Roboto', 'Ahem']) {
      final loader = FontLoader(family)..addFont(Future.value(data));
      await loader.load();
    }
    return;
  }
}
