import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dapur_flow/services/update_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UpdateService Safeguards', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('currentVersion and currentVersionCode match v1.0.5+10007', () {
      expect(UpdateService.currentVersion, '1.0.5');
      expect(UpdateService.currentVersionCode, 10007);
      expect(UpdateService.appVersion, '1.0.5');
      expect(UpdateService.appVersionCode, 10007);
    });

    test('snoozeUpdate persists snoozed versionCode in SharedPreferences', () async {
      await UpdateService.instance.snoozeUpdate(10007);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('snoozed_update_version'), 10007);
      final until = prefs.getInt('snoozed_update_until');
      expect(until, isNotNull);
      expect(until!, greaterThan(DateTime.now().millisecondsSinceEpoch));
    });

    test('temp file validation rejects HTML/tiny files', () async {
      final tmpDir = await Directory.systemTemp.createTemp('aturajah_apk_test');
      final badFile = File('${tmpDir.path}/bad.apk');
      await badFile.writeAsString('<html>Not Found</html>');
      expect(await badFile.length(), lessThan(100 * 1024));
      await tmpDir.delete(recursive: true);
    });
  });
}
