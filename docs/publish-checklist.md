# Checklist Kesiapan Publish — AturAjah (branch `testing`)

Diperiksa: 19 November 2026 · Flutter 3.50.0 · AGP 9.1.1 · targetSdk 36 · minSdk 24

## 1. Status build & kualitas

| Item | Status | Bukti |
|---|---|---|
| `flutter analyze` | OK | 41 issue, semuanya info `deprecated_member_use` (framework) |
| `flutter test` | OK | 84 tes lulus |
| `flutter test integration_test/` (emulator) | OK | 2 tes E2E lulus |
| `flutter build apk --debug` | OK | APK terpasang, seluruh layar diperiksa |
| `flutter build apk --release` | **GAGAL** | `Keystore file 'android/app/aturajah-release.keystore' not found` |
| APK release (uji dengan kunci sementara) | OK | 29,2 MB, terpasang, dashboard/tugas/alarm/cek-update berjalan |
| `flutter build appbundle` | belum diuji | ikut terblokir keystore |

## 2. Metadata aplikasi

| Item | Nilai |
|---|---|
| applicationId | `com.dapurflow.dapur_flow` |
| label launcher | AturAjah |
| versi sekarang | `1.0.3+10005` (sama dengan yang sudah beredar) |
| minSdk / targetSdk | 24 (Android 7.0) / 36 (Android 16) |
| ikon | ada di semua densitas (48–192 px), **belum adaptive icon** |
| izin | INTERNET, REQUEST_INSTALL_PACKAGES, POST_NOTIFICATIONS, SCHEDULE/USE_EXACT_ALARM, USE_FULL_SCREEN_INTENT, RECEIVE_BOOT_COMPLETED, VIBRATE, WAKE_LOCK |

## 3. Jalur update

- `version.json` di https://aturajah.vercel.app/version.json → 200, isi `1.0.3 / 10005`
- APK di https://aturajah.vercel.app/AturAjah.apk → 200, 27,9 MB, versionCode 10005
- `AturAjah-arm64.apk` → 200
- Cek pembaruan di aplikasi (release) → snackbar "Aplikasi sudah dalam versi terbaru (v1.0.3)"

## 4. Blocker sebelum publish

1. **Keystore rilis tidak ada.**
   APK 1.0.3 ditandatangani sertifikat
   `SHA-256 88851982b3c5c5c1cfc3339e587ec7ee1766b2c64b203101bd19d482659a6afe`
   (CN=AturAjah, O=AturAjah, L=Jakarta, C=ID).
   Rilis berikutnya **wajib** memakai kunci yang sama; kalau tidak, pengguna 1.0.3 harus
   uninstall dulu dan auto-update mereka gagal dengan "Aplikasi tidak terpasang".

2. **Versi belum dinaikkan.**
   `pubspec.yaml` masih `1.0.3+10005` dan `UpdateService.currentVersion/currentVersionCode`
   masih `1.0.3/10005`. Kalau APK baru diunggah dengan nomor yang sama, tidak ada pengguna
   yang ditawari pembaruan. Naikkan ke `1.0.4+10006` di tiga tempat sekaligus:
   `pubspec.yaml`, `lib/services/update_service.dart`, dan `version.json` di hosting.

3. **Kredensial signing hardcoded** di `android/app/build.gradle.kts`
   (sudah ada jalur `android/key.properties` + contoh `key.properties.example`;
   nilai lama dipertahankan hanya sebagai fallback).

## 5. Catatan (bukan blocker)

- Ikon belum adaptive (Android 8+ menampilkan ikon lama dengan padding putih).
- `print()` di beberapa service; sebagian sudah dibungkus `kDebugMode`.
- Google Play: kombinasi `USE_EXACT_ALARM` + `REQUEST_INSTALL_PACKAGES` (self-update)
  berisiko ditolak kebijakan. Distribusi via situs sendiri (kondisi sekarang) aman.
- Audio & getar alarm belum bisa diverifikasi di emulator — perlu HP fisik.

## 6. Langkah publish (setelah keystore tersedia)

```bash
# 1. taruh keystore di android/app/aturajah-release.keystore
#    (atau isi android/key.properties, lihat key.properties.example)

# 2. naikkan versi
#    pubspec.yaml: version: 1.0.4+10006
#    lib/services/update_service.dart: currentVersion / currentVersionCode

# 3. build
flutter build apk --release            # universal
flutter build apk --release --split-per-abi   # arm64 untuk AturAjah-arm64.apk

# 4. unggah APK + version.json ke aturajah.vercel.app
#    version.json: versionCode harus > 10005 agar pengguna lama ditawari update

# 5. verifikasi tanda tangan sebelum unggah
apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
#    SHA-256 harus 88851982b3c5c5c1cfc3339e587ec7ee1766b2c64b203101bd19d482659a6afe
```
