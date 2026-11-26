import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/update_info_model.dart';
import 'notification_service.dart';

/// In-App Auto Update & Direct APK Download Engine for AturAjah
class UpdateService {
  static final UpdateService instance = UpdateService._internal();

  static const String currentVersion = '1.0.5';
  static const int currentVersionCode = 10007;
  static const String updateMetadataUrl =
      'https://aturajah.vercel.app/version.json';
  static const String downloadPageUrl = 'https://aturajah.vercel.app/';

  static const String _snoozedVersionKey = 'snoozed_update_version';
  static const String _snoozedUntilKey = 'snoozed_update_until';

  static const MethodChannel _channel =
      MethodChannel('com.aturajah.app/vibrate');

  static String _resolvedVersion = currentVersion;
  static int _resolvedVersionCode = currentVersionCode;
  static bool _versionLoaded = false;

  static String get appVersion => _resolvedVersion;
  static int get appVersionCode => _resolvedVersionCode;

  UpdateService._internal();

  /// Read actual installed Android package versionName and versionCode once.
  Future<void> ensureVersionLoaded() async {
    if (kIsWeb || _versionLoaded) return;
    _versionLoaded = true;
    try {
      final dynamic raw = await _channel.invokeMethod('getAppVersion');
      if (raw is Map) {
        final vName = raw['versionName'] as String?;
        final vCode = raw['versionCode'] as int?;
        if (vName != null && vName.isNotEmpty) {
          _resolvedVersion = vName;
        }
        if (vCode != null && vCode > 0) {
          _resolvedVersionCode = vCode;
        }
      }
    } catch (_) {}
  }

  /// Snooze automatic update prompts for [versionCode] for 24 hours.
  Future<void> snoozeUpdate(int versionCode) async {
    try {
      await NotificationService.instance.cancelUpdateNotification();
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      final untilMs =
          DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch;
      await prefs.setInt(_snoozedVersionKey, versionCode);
      await prefs.setInt(_snoozedUntilKey, untilMs);
    } catch (_) {}
  }

  Future<bool> _isSnoozed(int versionCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final snoozedCode = prefs.getInt(_snoozedVersionKey);
      final untilMs = prefs.getInt(_snoozedUntilKey);
      if (snoozedCode == versionCode && untilMs != null) {
        if (DateTime.now().millisecondsSinceEpoch < untilMs) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Check whether a newer version exists on the server.
  /// Fails silently and safely returns null if user is offline or server unreachable.
  Future<UpdateInfoModel?> checkForUpdate({bool ignoreSnooze = false}) async {
    if (kIsWeb) return null;
    try {
      await ensureVersionLoaded();
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final cacheBuster = DateTime.now().millisecondsSinceEpoch;
      final request = await client
          .getUrl(Uri.parse('$updateMetadataUrl?t=$cacheBuster'));
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      final response =
          await request.close().timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(responseBody);
        final updateInfo = UpdateInfoModel.fromJson(data);

        if (updateInfo.versionCode > _resolvedVersionCode) {
          if (!ignoreSnooze && await _isSnoozed(updateInfo.versionCode)) {
            return null;
          }
          return updateInfo;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Update check error: $e');
      }
    }
    return null;
  }

  /// Get local cache file path for update APK
  Future<String> getDownloadPath() async {
    if (kIsWeb) return '';
    try {
      final String? path = await _channel.invokeMethod('getDownloadPath');
      if (path != null && path.isNotEmpty) {
        return path;
      }
    } catch (_) {}
    return '/data/user/0/com.dapurflow.dapur_flow/cache/AturAjah-update.apk';
  }

  /// Check Android 8+ install-unknown-apps permission.
  Future<bool> canRequestPackageInstalls() async {
    if (kIsWeb) return false;
    try {
      final bool? result =
          await _channel.invokeMethod('canRequestPackageInstalls');
      return result ?? true;
    } catch (_) {
      return true;
    }
  }

  /// Open Android system settings to grant install-unknown-apps permission.
  Future<bool> openInstallPermissionSettings() async {
    if (kIsWeb) return false;
    try {
      final bool? result =
          await _channel.invokeMethod('openInstallPermissionSettings');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Open the official download page in the system browser as fallback.
  Future<bool> openDownloadPage() async {
    if (kIsWeb) return false;
    try {
      final bool? result = await _channel.invokeMethod('openUrl', {
        'url': downloadPageUrl,
      });
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Verify that a downloaded file is a real APK archive (ZIP PK header & > 100 KB).
  Future<bool> _isValidApkFile(File file) async {
    try {
      if (!await file.exists()) return false;
      final length = await file.length();
      if (length < 100 * 1024) return false;
      final header = await file.openRead(0, 4).first;
      return header.length >= 2 && header[0] == 0x50 && header[1] == 0x4B;
    } catch (_) {
      return false;
    }
  }

  /// Download APK with real-time stream progress, then trigger system package installer
  Future<void> downloadAndInstall({
    required String apkUrl,
    required void Function(double progress, int receivedBytes, int totalBytes)
        onProgress,
    required void Function(String error) onError,
    required void Function() onSuccess,
    void Function()? onPermissionNeeded,
  }) async {
    if (kIsWeb) {
      onError('Unduhan APK hanya didukung pada perangkat Android.');
      return;
    }
    HttpClient? client;
    IOSink? sink;
    try {
      final localPath = await getDownloadPath();
      final file = File(localPath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);

      final request = await client.getUrl(Uri.parse(apkUrl));
      final response =
          await request.close().timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        onError('Gagal mengunduh: Kode status HTTP ${response.statusCode}');
        return;
      }

      final totalBytes = response.contentLength;
      int receivedBytes = 0;

      sink = file.openWrite();

      await for (final chunk in response) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
          onProgress(progress, receivedBytes, totalBytes);
        }
      }

      await sink.flush();
      await sink.close();
      sink = null;

      if (!await _isValidApkFile(file)) {
        try {
          await file.delete();
        } catch (_) {}
        onError('Berkas unduhan bukan paket APK yang valid. Silakan unduh lewat browser.');
        return;
      }

      onSuccess();

      final canInstall = await canRequestPackageInstalls();
      if (!canInstall) {
        onPermissionNeeded?.call();
        await openInstallPermissionSettings();
        return;
      }

      // Trigger native Android package installer
      final success = await installApk(localPath);
      if (!success) {
        onError('Gagal membuka paket instalasi.');
      }
    } catch (e) {
      if (sink != null) {
        try {
          await sink.close();
        } catch (_) {}
      }
      onError('Terjadi kesalahan unduhan: $e');
    } finally {
      client?.close();
    }
  }

  /// Trigger Android system PackageInstaller via FileProvider
  Future<bool> installApk(String filePath) async {
    if (kIsWeb) return false;
    try {
      final bool? result = await _channel.invokeMethod('installApk', {
        'filePath': filePath,
      });
      return result ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('installApk error: $e');
      }
      return false;
    }
  }

  /// Show a high-priority system notification alerting user of an available update
  Future<void> showUpdateNotification(UpdateInfoModel updateInfo) async {
    try {
      await NotificationService.instance.triggerUpdateNotification(
        title: 'Pembaruan AturAjah Tersedia (v${updateInfo.version})',
        body: 'Ketuk untuk mengunduh dan memperbarui ke versi terbaru.',
      );
    } catch (_) {}
  }
}
