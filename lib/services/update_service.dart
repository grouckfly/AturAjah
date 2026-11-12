import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/update_info_model.dart';
import 'notification_service.dart';

/// In-App Auto Update & Direct APK Download Engine for AturAjah
class UpdateService {
  static final UpdateService instance = UpdateService._internal();

  static const String currentVersion = '1.0.3';
  static const int currentVersionCode = 10005;
  static const String updateMetadataUrl =
      'https://aturajah.vercel.app/version.json';

  static const MethodChannel _channel =
      MethodChannel('com.aturajah.app/vibrate');

  UpdateService._internal();

  /// Check whether a newer version exists on the server.
  /// Fails silently and safely returns null if user is offline or server unreachable.
  Future<UpdateInfoModel?> checkForUpdate() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(Uri.parse(updateMetadataUrl));
      final response =
          await request.close().timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> data = jsonDecode(responseBody);
        final updateInfo = UpdateInfoModel.fromJson(data);

        if (updateInfo.versionCode > currentVersionCode) {
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
    try {
      final String? path = await _channel.invokeMethod('getDownloadPath');
      if (path != null && path.isNotEmpty) {
        return path;
      }
    } catch (_) {}
    return '/data/user/0/com.dapurflow.dapur_flow/cache/AturAjah-update.apk';
  }

  /// Download APK with real-time stream progress, then trigger system package installer
  Future<void> downloadAndInstall({
    required String apkUrl,
    required void Function(double progress, int receivedBytes, int totalBytes)
        onProgress,
    required void Function(String error) onError,
    required void Function() onSuccess,
  }) async {
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

      onSuccess();

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
