# AturAjah — Daily Task & Schedule Manager

<p align="center">
  <img src="android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" width="96" height="96" alt="AturAjah Logo" />
  <br>
  <strong>Aplikasi Manajemen Tugas Harian & Jadwal Praktis 100% Offline</strong>
  <br>
  <em>Berbasis Matriks Prioritas Eisenhower (4 Kuadran) & Pengingat Alarm Presisi</em>
</p>

<p align="center">
  <a href="#-tautan-unduh-otomatis-versi-terbaru"><img src="https://img.shields.io/badge/Download-Latest%20APK-orange?style=for-the-badge&logo=android" alt="Download APK" /></a>
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-blue?style=for-the-badge" alt="Platform" />
  <img src="https://img.shields.io/badge/100%25-Offline-success?style=for-the-badge" alt="Offline" />
  <img src="https://img.shields.io/badge/APK%20Size-~18%20MB-brightgreen?style=for-the-badge" alt="Size" />
</p>

---

## 🚀 Sekilas Tentang AturAjah

**AturAjah** adalah aplikasi pengatur jadwal dan to-do list harian yang dirancang untuk produktivitas maksimal, ringan, dan **100% offline** tanpa memerlukan login, internet, maupun layanan pihak ketiga (bebas analitik dan pelacak).

Dibangun menggunakan **Flutter (Dart)** dengan fokus pada performa tinggi (60fps mulus pada ponsel berusia 7+ tahun) dan memori rendah.

### ✨ Fitur Unggulan
* **100% Offline & Privat:** Semua data tugas dan jadwal disimpan secara lokal di perangkat Anda menggunakan SQLite (`sqflite`). Tidak ada data yang keluar dari ponsel Anda.
* **Matriks Prioritas Eisenhower (4 Kuadran):**
  - 🔴 **Kerjakan Dahulu** (*Mendesak & Penting*): Prioritas utama yang harus diselesaikan segera.
  - 🔵 **Jadwalkan** (*Tidak Mendesak & Penting*): Rencana kerja fokus harian.
  - 🟡 **Delegasikan** (*Mendesak & Tidak Penting*): Tugas operasional singkat.
  - ⚪ **Nanti** (*Tidak Mendesak & Tidak Penting*): Catatan cadangan prioritas rendah.
* **Full CRUD:** Tambah tugas baru, tandai selesai/belum selesai, edit isi tugas sewaktu-waktu, dan hapus tugas dengan dialog konfirmasi.
* **Tampilan Jadwal Berdasarkan Kategori:** Tab Jadwal mengelompokkan tugas secara rapi berdasarkan 4 kategori prioritas lengkap dengan jam target dan durasi.
* **Alarm Tepat Waktu & Nada Dering Sistem:** Alarm menggunakan nada dering jam alarm standar bawaan HP Anda (`content://settings/system/alarm_alert`), bukan suara notifikasi biasa.
* **Mesin Getaran Hardware Responsif:** Getaran menggunakan akses hardware *Android Vibrator* langsung via Kotlin MethodChannel. Tetap bergetar presisi bahkan ketika dilakukan pengujian berulang kali secara cepat (*spam testing*), dan mati total jika opsi getar dinonaktifkan.
* **Pengingat Layar Penuh & Tunda (Snooze):** Saat target waktu tiba, muncul modal pengingat layar penuh dengan opsi tunda (+5, +10, +15 menit).
* **Buka Tanpa Blank Screen:** Dilengkapi *native splash screen* Android yang langsung merender latar dan logo sejak milidetik pertama aplikasi dibuka.
* **Dua Bahasa (Bilingual):** Bahasa Indonesia sebagai bahasa utama dan English (US), dapat diubah instan tanpa perlu memuat ulang aplikasi.
* **Ukuran Sangat Ringan:** Hanya **~18.8 MB** (arsitektur 64-bit modern), jauh lebih hemat penyimpanan dibanding aplikasi sejenis.

---

## 🔗 Tautan Unduh Otomatis Versi Terbaru

### Cara Membagikan Tautan Otomatis ke Pengguna Lain
Setelah repositori ini diunggah ke GitHub dan Anda membuat **GitHub Release**, bagikan tautan resmi berikut kepada pengguna lain:

```text
https://github.com/<USERNAME>/<REPO>/releases/latest/download/AturAjah.apk
```
> **Catatan:** Ganti `<USERNAME>` dan `<REPO>` dengan akun GitHub dan nama repositori Anda. Tautan di atas adalah fitur resmi GitHub yang **otomatis mengunduh file APK dari rilis stabil paling baru** tanpa perlu memperbarui tautan setiap kali Anda merilis versi baru!

### Halaman Web Unduhan Siap Pakai (`download.html`)
Proyek ini juga menyertakan file [`download.html`](download.html) yang bisa langsung dibuka di browser atau di-hosting di **GitHub Pages**. Pengguna yang membuka link dengan parameter `?download=true` akan langsung memicu unduhan otomatis ke perangkat mereka.

---

## 📥 Panduan Instalasi

### 🤖 A. Instalasi di Android

#### Cara 1: Mengunduh dan Memasang File APK (Paling Mudah)
1. Unduh file **`AturAjah.apk`** (atau `AturAjah-arm64.apk` untuk HP Android modern) dari link rilis stabil di atas.
2. Buka notifikasi unduhan atau buka aplikasi **Pengelola File (File Manager)** ➔ masuk ke folder **Download**.
3. Ketuk file **`AturAjah.apk`**.
4. Jika muncul peringatan keamanan sistem Android:
   - Ketuk **Setelan (Settings)**.
   - Aktifkan tombol **"Izinkan dari sumber ini"** (*Allow from this source*).
   - Kembali dan ketuk **Pasang (Install)** / **Perbarui (Update)**.
5. Buka **AturAjah** dan aplikasi siap digunakan 100% offline!

#### Cara 2: Pasang via ADB (Khusus Pengembang / Developer)
Sambungkan ponsel Android Anda ke PC dengan kabel USB (aktifkan *USB Debugging*), lalu jalankan perintah terminal:
```bash
adb install -r AturAjah.apk
```

---

### 🍎 B. Panduan Instalasi & Build di iOS

Karena kebijakan keamanan Apple iOS tidak mengizinkan pemasangan file aplikasi mentah tanpa sertifikat pengembang, aplikasi Flutter untuk iOS harus dikompilasi menggunakan Xcode.

#### Prasyarat:
* Komputer **Mac (macOS)** dengan Xcode 14+ terpasang.
* Flutter SDK & CocoaPods (`sudo gem install cocoapods`).
* Akun Apple Developer (bisa menggunakan akun gratis untuk testing langsung di perangkat fisik).

#### Langkah-Langkah Build & Jalankan:
1. Buka terminal di direktori proyek:
   ```bash
   cd "ToDoApp"
   flutter pub get
   ```
2. Pasang dependensi Pod untuk iOS:
   ```bash
   cd ios
   pod install
   cd ..
   ```
3. Buka proyek iOS di Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```
4. Di Xcode:
   - Pilih target **Runner** di panel kiri.
   - Buka tab **Signing & Capabilities**.
   - Pada bagian **Team**, pilih akun Apple ID / Tim Pengembang Anda.
   - Pastikan **Bundle Identifier** unik (contoh: `com.aturajah.app`).
5. Hubungkan perangkat iPhone fisik atau pilih salah satu iOS Simulator.
6. Tekan tombol **Play / Run** (`Cmd + R`) di Xcode, atau jalankan perintah Flutter di terminal:
   ```bash
   flutter run -d ios
   ```
7. **Membuat File IPA (Untuk Distribusi Ad-Hoc / TestFlight):**
   ```bash
   flutter build ipa --release
   ```
   File hasil build `.ipa` akan berada di folder `build/ios/archive/` dan siap diunggah ke Apple TestFlight atau App Store Connect.

---

## 🛠️ Membangun dari Source Code (Developer Guide)

### Prasyarat
* **Flutter SDK:** Version `>= 3.10.0`
* **Dart SDK:** Version `>= 3.0.0 < 4.0.0`
* **Java:** OpenJDK 17
* **Android SDK:** `minSdkVersion 24` (Android 7.0+), `targetSdkVersion 34`

### Perintah Kompilasi

1. **Unduh seluruh paket dependensi:**
   ```bash
   flutter pub get
   ```

2. **Jalankan pengecekan kualitas kode:**
   ```bash
   flutter analyze
   ```

3. **Jalankan di perangkat yang tersambung (Debug Mode):**
   ```bash
   flutter run
   ```

4. **Kompilasi Release APK Ringan (Split Per-ABI — Rekomendasi):**
   ```bash
   flutter build apk --release --split-per-abi
   ```
   *Hasil APK berada di `build/app/outputs/flutter-apk/`:*
   - `app-arm64-v8a-release.apk` (**~18.8 MB** — Untuk 95%+ ponsel Android modern).
   - `app-armeabi-v7a-release.apk` (**~16.4 MB** — Untuk ponsel 32-bit lama).

5. **Kompilasi Universal Release APK (Mendukung semua arsitektur dalam 1 file):**
   ```bash
   flutter build apk --release
   ```
   *Hasil APK:* `build/app/outputs/flutter-apk/app-release.apk` (**~53 MB**).

---

## 📁 Struktur Direktori

```text
ToDoApp/
├── android/                          <-- Kode native Android & Kotlin MethodChannel
│   └── app/src/main/
│       ├── kotlin/.../MainActivity.kt <-- Direct Hardware Vibrator (VibratorManager)
│       └── AndroidManifest.xml       <-- Label: AturAjah, Izin alarm & getar
├── ios/                              <-- Runner Xcode & Info.plist iOS
├── lib/
│   ├── constants/
│   │   ├── app_colors.dart           <-- Palet warna tema terang presisi
│   │   └── app_theme.dart            <-- Light Theme ONLY (Performa 60fps)
│   ├── l10n/
│   │   └── app_localizations.dart    <-- Kamus bilingual (Indonesia & English)
│   ├── models/
│   │   ├── priority_quadrant.dart    <-- Model 4 Kuadran Matriks Eisenhower
│   │   └── task_model.dart           <-- Entitas tugas SQLite
│   ├── providers/
│   │   ├── locale_provider.dart      <-- Manajemen ganti bahasa instan
│   │   └── task_provider.dart        <-- State management Full CRUD tugas
│   ├── services/
│   │   ├── database_helper.dart      <-- SQLite 100% Offline
│   │   ├── notification_service.dart <-- Dual-channel alarm ringtone sistem
│   │   ├── settings_service.dart     <-- Preferensi getar & durasi alarm
│   │   └── vibration_service.dart    <-- Layanan getar hardware instan
│   ├── screens/
│   │   ├── splash_screen.dart        <-- Layanan pembuka kilat tanpa blank screen
│   │   ├── daily_dashboard_screen.dart<-- Dasbor tugas & checklist
│   │   ├── schedule_timeline_screen.dart<-- Jadwal per 4 kategori prioritas
│   │   ├── task_input_screen.dart    <-- Form input tugas & edit tugas
│   │   ├── settings_screen.dart      <-- Pengaturan durasi alarm & uji coba getar
│   │   └── task_reminder_modal.dart  <-- Modal pengingat layar penuh
│   └── main.dart                     <-- Titik masuk aplikasi (AturAjahApp)
├── download.html                     <-- Halaman web unduh otomatis versi terbaru
├── README.md                         <-- Dokumentasi lengkap proyek
└── pubspec.yaml                      <-- Dependensi stabil
```

---

## 📄 Lisensi
Didistribusikan di bawah lisensi **MIT License**. Bebas dimodifikasi, dipelajari, dan digunakan untuk kebutuhan operasional pribadi maupun tim.
