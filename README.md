# AturAjah - Daily Task and Schedule Manager

Aplikasi Manajemen Tugas Harian dan Jadwal Praktis 100% Offline
Berbasis Matriks Prioritas Eisenhower (4 Kuadran) dan Pengingat Alarm Presisi.

[![Download Android](https://img.shields.io/badge/Download-Android%20(APK)-orange?style=for-the-badge)](https://github.com/<USERNAME>/<REPO>/releases/latest/download/AturAjah.apk)
[![Download iOS](https://img.shields.io/badge/Download-iOS%20(TestFlight%20/%20Build)-blue?style=for-the-badge)](#panduan-instalasi-dan-build-di-ios)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge)](https://flutter.dev)
[![Offline](https://img.shields.io/badge/Database-100%25%20Offline-green?style=for-the-badge)](#arsitektur-offline)
[![Size](https://img.shields.io/badge/APK%20Size-~18%20MB-brightgreen?style=for-the-badge)](#unduh-aplikasi)

---

## Unduh Aplikasi

Pilih tautan unduhan sesuai perangkat Anda:

* **[Download Android (APK Versi Stabil Terbaru)](https://github.com/<USERNAME>/<REPO>/releases/latest/download/AturAjah.apk)**
  * Unduh langsung file APK rilis stabil terbaru (arsitektur 64-bit modern, ukuran ~18.8 MB).
  * Pengguna Android dapat langsung membuka file hasil unduhan untuk memasang aplikasi.
* **[Download Android (APK Universal - Semua Perangkat)](https://github.com/<USERNAME>/<REPO>/releases/latest/download/AturAjah-universal.apk)**
  * Versi universal yang mendukung seluruh jenis arsitektur prosesor Android (ukuran ~53.5 MB).
* **[Download iOS (TestFlight / Panduan Build)](#panduan-instalasi-dan-build-di-ios)**
  * Ikuti instruksi pemasangan untuk iPhone / iPad melalui Apple TestFlight atau kompilasi via Xcode.
* **[Website Unduhan (Vercel)](download.html)**
  * Halaman portal unduhan siap pasang di Vercel dengan tombol unduh otomatis.

---

## Sekilas Tentang AturAjah

AturAjah adalah aplikasi manajemen jadwal dan to-do list harian yang dirancang untuk produktivitas maksimal, ringan, dan 100% offline tanpa membutuhkan akun login, koneksi internet, maupun dependensi layanan cloud eksternal.

Aplikasi dikembangkan menggunakan Flutter (Dart) dengan fokus performa 60fps yang stabil dan penggunaan memori yang efisien bahkan pada perangkat keras berusia 7 tahun ke atas.

### Fitur Utama

* **100% Offline dan Privat:** Seluruh data tugas dan jadwal tersimpan lokal di perangkat menggunakan SQLite (sqflite). Tidak ada data pengguna yang dikirim ke server luar.
* **Matriks Prioritas Eisenhower (4 Kuadran):**
  * **[1] Kerjakan Dahulu (Mendesak & Penting):** Tugas utama yang wajib diselesaikan segera.
  * **[2] Jadwalkan (Tidak Mendesak & Penting):** Perencanaan fokus harian jangka menengah.
  * **[3] Delegasikan (Mendesak & Tidak Penting):** Tugas operasional cepat.
  * **[4] Nanti (Tidak Mendesak & Tidak Penting):** Catatan tugas cadangan berprioritas rendah.
* **Full CRUD:** Menambah tugas baru, menandai selesai atau belum selesai, mengedit rincian tugas sewaktu-waktu, dan menghapus tugas dengan dialog konfirmasi.
* **Tampilan Jadwal Berdasarkan Kategori:** Tab Jadwal mengelompokkan tugas secara kronologis berdasarkan 4 kuadran prioritas lengkap dengan jam target dan durasi pengerjaan.
* **Alarm Tepat Waktu dengan Nada Dering Sistem:** Alarm menggunakan nada dering alarm standar bawaan sistem ponsel (content://settings/system/alarm_alert).
* **Mesin Getaran Hardware Responsif:** Getaran mengontrol driver hardware Android Vibrator / VibratorManager secara langsung melalui Kotlin MethodChannel, menjamin respons instan pada pengujian beruntun (spam testing) serta mati total saat fitur getar dinonaktifkan.
* **Pengingat Layar Penuh dan Tunda (Snooze):** Dialog pengingat interaktif saat waktu tiba dengan pilihan tunda 5, 10, atau 15 menit.
* **Layar Pembuka Instan:** Konfigurasi native splash Android mencegah munculnya layar kosong (blank screen) saat aplikasi pertama kali dibuka.
* **Dukungan Dua Bahasa (Bilingual):** Bahasa Indonesia sebagai bahasa utama dan English (US), dapat dialihkan secara instan tanpa perlu memulai ulang aplikasi.
* **Ukuran Sangat Ringan:** Hanya ~18.8 MB pada build rilis ARM64.

---

## Panduan Instalasi di Android

### Cara 1: Unduh dan Pasang Langsung File APK (Direkomendasikan)
1. Buka tautan **[Download Android (APK)](https://github.com/<USERNAME>/<REPO>/releases/latest/download/AturAjah.apk)** melalui peramban (browser) di ponsel Android Anda.
2. Tunggu hingga proses unduhan selesai, lalu ketuk notifikasi unduhan atau buka aplikasi **Pengelola File (File Manager)** pada folder **Download**.
3. Ketuk file **AturAjah.apk**.
4. Jika muncul peringatan keamanan sistem Android:
   * Pilih **Setelan (Settings)**.
   * Aktifkan opsi **Izinkan dari sumber ini (Allow from this source)**.
   * Kembali ke menu pemasangan lalu pilih **Pasang (Install)** atau **Perbarui (Update)**.
5. Aplikasi AturAjah siap digunakan secara penuh.

### Cara 2: Pasang via ADB (Developer / Power User)
Sambungkan ponsel Android ke komputer dengan USB Debugging aktif, kemudian jalankan:
```bash
adb install -r AturAjah.apk
```

---

## Panduan Instalasi dan Build di iOS

Kebijakan keamanan sistem operasi Apple iOS tidak mengizinkan instalasi file biner mentah (.ipa) secara langsung dari peramban web tanpa sertifikat terdaftar. Pemasangan pada perangkat iOS dapat dilakukan melalui dua jalur berikut:

### Jalur 1: Menggunakan Apple TestFlight (Rekomendasi untuk Pengguna Biasa)
1. Daftarkan akun pengembang di Apple Developer Program.
2. Buat build rilis iOS dengan perintah:
   ```bash
   flutter build ipa --release
   ```
3. Unggah arsip build ke App Store Connect dan aktifkan pengujian publik via TestFlight.
4. Bagikan tautan publik TestFlight kepada pengguna (contoh: `https://testflight.apple.com/join/xxxxxx`). Pengguna cukup mengetuk link tersebut di iPhone untuk langsung memasang aplikasi.

### Jalur 2: Build Manual Melalui Xcode (Developer / Pengujian Pribadi)

#### Prasyarat:
* Komputer Mac (macOS Monterey atau versi lebih baru)
* Xcode 14+ terpasang
* CocoaPods (`sudo gem install cocoapods`)
* Akun Apple ID (dapat menggunakan akun personal gratis)

#### Langkah Pengerjaan:
1. Unduh atau clone repositori proyek:
   ```bash
   git clone https://github.com/<USERNAME>/<REPO>.git
   cd <REPO>
   ```
2. Pasang dependensi aplikasi dan CocoaPods:
   ```bash
   flutter pub get
   cd ios
   pod install
   cd ..
   ```
3. Buka workspace di Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
4. Di Xcode:
   * Pilih target **Runner** pada panel sebelah kiri.
   * Masuk ke tab **Signing & Capabilities**.
   * Pada dropdown **Team**, pilih akun Apple ID Anda.
   * Pastikan **Bundle Identifier** unik.
5. Sambungkan perangkat iPhone atau pilih salah satu iOS Simulator.
6. Tekan tombol **Run** (Command + R) pada Xcode atau jalankan via terminal:
   ```bash
   flutter run -d ios
   ```

---

## Panduan Pengembang (Build dari Source Code)

### Prasyarat Lingkungan Kerja
* Flutter SDK: Versi >= 3.10.0
* Dart SDK: Versi >= 3.0.0 < 4.0.0
* Java: OpenJDK 17
* Android SDK: minSdkVersion 24 (Android 7.0+), compileSdkVersion 34

### Perintah Pembangunan Proyek

1. **Mengambil dependensi proyek:**
   ```bash
   flutter pub get
   ```

2. **Menjalankan analisis sintaks dan kualitas kode:**
   ```bash
   flutter analyze
   ```

3. **Menjalankan aplikasi dalam mode pengembangan:**
   ```bash
   flutter run
   ```

4. **Membangun APK Rilis Terpisah Per Arsitektur (Sangat Ringan):**
   ```bash
   flutter build apk --release --split-per-abi
   ```
   File keluaran:
   * `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (~18.8 MB)
   * `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (~16.4 MB)

5. **Membangun APK Rilis Universal (Mendukung Seluruh Perangkat):**
   ```bash
   flutter build apk --release
   ```
   File keluaran:
   * `build/app/outputs/flutter-apk/app-release.apk` (~53.5 MB)

---

## Struktur Direktori

```text
ToDoApp/
├── android/
│   └── app/src/main/
│       ├── kotlin/.../MainActivity.kt <-- Akses native Android Vibrator
│       └── AndroidManifest.xml       <-- Label: AturAjah, Izin alarm & getar
├── ios/                              <-- Runner Xcode & Info.plist iOS
├── lib/
│   ├── constants/
│   │   ├── app_colors.dart           <-- Palet warna tema terang
│   │   └── app_theme.dart            <-- Konfigurasi tema Light 60fps
│   ├── l10n/
│   │   └── app_localizations.dart    <-- Kamus bilingual (Indonesia & English)
│   ├── models/
│   │   ├── priority_quadrant.dart    <-- Model 4 Kuadran Prioritas
│   │   └── task_model.dart           <-- Entitas tugas SQLite
│   ├── providers/
│   │   ├── locale_provider.dart      <-- State manajemen bahasa
│   │   └── task_provider.dart        <-- State manajemen CRUD tugas
│   ├── services/
│   │   ├── database_helper.dart      <-- Pengelola database SQLite offline
│   │   ├── notification_service.dart <-- Pengelola dual-channel alarm sistem
│   │   ├── settings_service.dart     <-- Pengelola durasi alarm & opsi getar
│   │   └── vibration_service.dart    <-- Layanan pemicu getar hardware native
│   ├── screens/
│   │   ├── splash_screen.dart        <-- Layar pembuka instan tanpa blank screen
│   │   ├── daily_dashboard_screen.dart<-- Dasbor tugas & checklist progres
│   │   ├── schedule_timeline_screen.dart<-- Jadwal per kategori kuadran
│   │   ├── task_input_screen.dart    <-- Form input tugas & pengeditan
│   │   ├── settings_screen.dart      <-- Setelan durasi alarm & uji getar
│   │   └── task_reminder_modal.dart  <-- Modal pengingat layar penuh
│   └── main.dart                     <-- Titik masuk aplikasi (AturAjahApp)
├── download.html                     <-- Portal unduhan web siap pasang di Vercel
├── README.md                         <-- Dokumentasi proyek
└── pubspec.yaml                      <-- Konfigurasi dependensi aplikasi
```

---

## Lisensi

Didistribusikan di bawah lisensi **MIT License**. Bebas digunakan, dipelajari, dan dikembangkan kembali untuk kebutuhan pribadi maupun organisasi.
