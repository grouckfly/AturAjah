# AturAjah - Daily Task and Schedule Manager

Aplikasi Manajemen Tugas Harian dan Jadwal Praktis 100% Offline
Berbasis 4 Kategori Prioritas Praktis dan Pengingat Alarm Presisi.

[![Website Vercel](https://img.shields.io/badge/Website-aturajah.vercel.app-black?style=for-the-badge)](https://aturajah.vercel.app)
[![Download Android](https://img.shields.io/badge/Download-Android%20(APK)-orange?style=for-the-badge)](https://aturajah.vercel.app)
[![Download iPhone iOS](https://img.shields.io/badge/Download-iPhone%20(iOS)-blue?style=for-the-badge)](#panduan-instalasi-di-iphone-ios)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20(iPhone)-lightgrey?style=for-the-badge)](https://flutter.dev)
[![Offline](https://img.shields.io/badge/Database-100%25%20Offline-green?style=for-the-badge)](#sekilas-tentang-aturajah)
[![Size](https://img.shields.io/badge/APK%20Size-~18%20MB-brightgreen?style=for-the-badge)](#unduh-aplikasi)

---

## Unduh Aplikasi

Kunjungi portal web resmi atau pilih tautan unduhan sesuai perangkat Anda:

* **[Website Resmi & Portal Unduhan Vercel](https://aturajah.vercel.app)**
  * Akses laman web langsung dari ponsel Android atau iPhone untuk memasang aplikasi.
* **[Download Android (APK Versi Stabil Terbaru)](https://aturajah.vercel.app/AturAjah.apk)**
  * Unduh langsung file APK rilis stabil terbaru (arsitektur 64-bit modern, ukuran ringan ~18.8 MB).
  * Pengguna Android dapat langsung membuka file hasil unduhan untuk memasang aplikasi.
* **[Download Android (APK Universal - Semua Perangkat)](https://aturajah.vercel.app/AturAjah-universal.apk)**
  * Versi universal yang mendukung seluruh jenis arsitektur prosesor Android (ukuran ~53.5 MB).
* **[Panduan Pemasangan di iPhone (iOS)](#panduan-instalasi-di-iphone-ios)**
  * Panduan bagi pemilik iPhone untuk memasang aplikasi via Apple TestFlight (tanpa komputer) atau via Sideloadly (laptop Windows).

---

## Sekilas Tentang AturAjah

AturAjah adalah aplikasi manajemen jadwal dan to-do list harian yang dirancang untuk produktivitas maksimal, ringan, dan 100% offline tanpa membutuhkan akun login, koneksi internet, maupun dependensi layanan cloud eksternal.

Aplikasi dikembangkan menggunakan Flutter (Dart) dengan fokus performa 60fps yang stabil dan penggunaan memori yang efisien bahkan pada perangkat keras berusia 7 tahun ke atas.

### Fitur Utama

* **100% Offline dan Privat:** Seluruh data tugas dan jadwal tersimpan lokal di perangkat menggunakan SQLite (sqflite). Tidak ada data pengguna yang dikirim ke server luar.
* **Sistem Pembagian Tugas yang Praktis (4 Kategori):**
  Memudahkan Anda memilah mana tugas yang harus diselesaikan sekarang dan mana yang bisa ditunda tanpa pusing:
  * **[1] Kerjakan Sekarang (Paling Mendesak & Sangat Penting):**
    Tugas darurat atau paling genting hari ini yang tidak bisa ditunda sama sekali. Wajib Anda selesaikan paling pertama (contoh: pesanan yang harus dikirim siang ini, masalah peralatan mati mendadak, menyelesaikan deadline penting hari ini).
  * **[2] Jadwalkan Nanti (Penting, tapi Masih Ada Waktu):**
    Rencana kerja penting untuk masa depan yang tidak perlu buru-buru, tapi harus dijadwalkan agar tidak terlupakan (contoh: belanja stok bahan mingguan, menyusun rencana kerja besok, evaluasi berkala).
  * **[3] Minta Bantuan / Bagi Tugas (Mendesak, tapi Bisa Dikerjakan Orang Lain):**
    Tugas yang butuh diselesaikan cepat, tapi sebenarnya tidak harus Anda sendiri yang mengerjakannya (contoh: mencuci piring, merapikan meja, membalas pesan konfirmasi pelanggan).
  * **[4] Simpan Dulu (Santai & Tidak Mendesak):**
    Pekerjaan ringan atau ide tambahan yang sifatnya santai dan opsional. Hanya dikerjakan jika semua tugas penting lainnya sudah selesai (contoh: merapikan arsip lama, mencoba ide dekorasi baru).
* **Full CRUD:** Menambah tugas baru, menandai selesai atau belum selesai, mengedit rincian tugas sewaktu-waktu, dan menghapus tugas dengan dialog konfirmasi.
* **Tampilan Jadwal Berdasarkan Kategori:** Tab Jadwal mengelompokkan tugas secara kronologis berdasarkan 4 kategori di atas lengkap dengan jam target dan durasi pengerjaan.
* **Alarm Tepat Waktu dengan Nada Dering Sistem:** Alarm menggunakan nada dering alarm standar bawaan sistem ponsel (content://settings/system/alarm_alert).
* **Mesin Getaran Hardware Responsif:** Getaran mengontrol driver hardware Android Vibrator / VibratorManager secara langsung melalui Kotlin MethodChannel, menjamin respons instan pada pengujian beruntun (spam testing) serta mati total saat fitur getar dinonaktifkan.
* **Pengingat Layar Penuh dan Tunda (Snooze):** Dialog pengingat interaktif saat waktu tiba dengan pilihan tunda 5, 10, atau 15 menit.
* **Layar Pembuka Instan:** Konfigurasi native splash Android mencegah munculnya layar kosong (blank screen) saat aplikasi pertama kali dibuka.
* **Dukungan Dua Bahasa (Bilingual):** Bahasa Indonesia sebagai bahasa utama dan English (US), dapat dialihkan secara instan tanpa perlu memulai ulang aplikasi.
* **Ukuran Sangat Ringan:** Hanya ~18.8 MB pada build rilis ARM64.

---

## Panduan Instalasi di Android

### Cara 1: Unduh dan Pasang Langsung dari Web Vercel (Direkomendasikan)
1. Buka laman **[aturajah.vercel.app](https://aturajah.vercel.app)** melalui peramban (browser) di ponsel Android Anda.
2. Ketuk tombol **Download Android (APK)**.
3. Tunggu hingga proses unduhan selesai, lalu ketuk notifikasi unduhan atau buka aplikasi **Pengelola File (File Manager)** pada folder **Download**.
4. Ketuk file **AturAjah.apk**.
5. Jika muncul peringatan keamanan sistem Android:
   * Pilih **Setelan (Settings)**.
   * Aktifkan opsi **Izinkan dari sumber ini (Allow from this source)**.
   * Kembali ke menu pemasangan lalu pilih **Pasang (Install)** atau **Perbarui (Update)**.
6. Aplikasi AturAjah siap digunakan secara penuh.

### Cara 2: Pasang via ADB (Developer / Power User)
Sambungkan ponsel Android ke komputer dengan USB Debugging aktif, kemudian jalankan:
```bash
adb install -r AturAjah.apk
```

---

## Panduan Instalasi di iPhone (iOS)

Bagi pengguna atau penguji yang memegang perangkat iPhone dan ingin memasang aplikasi AturAjah secara langsung, terdapat dua cara praktis tanpa mengharuskan Anda memiliki komputer Mac:

### Cara 1: Melalui Apple TestFlight (Paling Mudah - Langsung di iPhone)
Ini adalah jalur resmi yang paling mudah bagi siapa saja yang ingin mencoba aplikasi di iPhone tanpa menyambungkan kabel atau komputer:
1. Buka App Store di iPhone Anda, cari dan pasang aplikasi gratis bernama **TestFlight**.
2. Buka tautan publik TestFlight AturAjah melalui peramban Safari di iPhone Anda (tautan tersedia di portal [aturajah.vercel.app](https://aturajah.vercel.app) setelah sesi beta dibuka).
3. Ketuk **Accept (Terima)** lalu ketuk **Install (Pasang)**.
4. Ikon AturAjah akan langsung muncul di layar utama (Home Screen) iPhone Anda dan siap dibuka layaknya aplikasi App Store biasa.

### Cara 2: Pasang File IPA Menggunakan Laptop Windows (Sideloading Gratis)
Jika pengembang menyediakan file paket aplikasi iOS (`AturAjah.ipa`), Anda dapat memasangnya ke iPhone Anda menggunakan laptop/PC Windows:
1. Unduh aplikasi gratis **Sideloadly** (sideloadly.io) di komputer Windows Anda.
2. Pastikan iTunes atau driver Apple terpasang di Windows Anda.
3. Sambungkan iPhone ke laptop Windows menggunakan kabel Lightning atau USB-C.
4. Buka Sideloadly, pilih perangkat iPhone Anda, lalu seret (drag-and-drop) file **AturAjah.ipa** ke dalam jendela Sideloadly.
5. Masukkan Apple ID pribadi Anda (hanya digunakan untuk menandatangani sertifikat pengujian gratis dari Apple).
6. Klik **Start**. Tunggu beberapa saat hingga proses transfer selesai.
7. Di iPhone Anda:
   * Masuk ke **Pengaturan (Settings)** -> **Umum (General)** -> **VPN & Manajemen Perangkat (VPN & Device Management)**.
   * Ketuk akun Apple ID Anda, lalu pilih **Percayai (Trust)**.
8. Aplikasi AturAjah siap dijalankan di iPhone Anda.

---

## Panduan Khusus Pengembang iOS (Membangun File Build)

Bagian ini ditujukan bagi pengembang yang ingin mengompilasi kode sumber Flutter menjadi file iOS:

### Jalur A: Build Otomatis di Cloud via GitHub Actions (Bisa dari Laptop Windows)
Anda tidak wajib memiliki komputer Mac fisik untuk membuat build iOS. Anda dapat memanfaatkan fitur **GitHub Actions** (runner macOS gratis dari GitHub) untuk mengompilasi kode menjadi file `.ipa` secara otomatis setiap kali Anda membuat rilis di GitHub.

### Jalur B: Build Manual Menggunakan Komputer Mac dan Xcode

#### Prasyarat:
* Komputer Mac (macOS Monterey atau versi lebih baru)
* Xcode 14+ terpasang
* CocoaPods (`sudo gem install cocoapods`)
* Akun Apple ID (bisa akun personal gratis)

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
5. Sambungkan perangkat iPhone fisik atau pilih salah satu iOS Simulator.
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
│   └── app_localizations.dart        <-- Kamus bilingual (Indonesia & English)
│   ├── models/
│   │   ├── priority_quadrant.dart    <-- Model 4 Kategori Prioritas
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
├── index.html                        <-- Portal unduhan web utama di Vercel
├── download.html                     <-- Portal unduhan cadangan
├── README.md                         <-- Dokumentasi proyek
└── pubspec.yaml                      <-- Konfigurasi dependensi aplikasi
```

---

## Lisensi

Didistribusikan di bawah lisensi **MIT License**. Bebas digunakan, dipelajari, dan dikembangkan kembali untuk kebutuhan pribadi maupun organisasi.
