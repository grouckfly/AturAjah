# Laporan QA & Perbaikan — AturAjah vs Proposal "Strengthening MSME Operational Efficiency through Task Prioritization and Scheduling"

Tanggal: 18 November 2026
Branch: `testing` (dibuat dari `main` @ `33d03d4`)

Status akhir: **semua gap proposal ditutup dan bug notifikasi/dering diperbaiki serta
diverifikasi di emulator Android 15.**

---

## 1. Ringkasan hasil

| Verifikasi | Hasil |
|---|---|
| `flutter analyze` | 0 error (hanya info deprecation `flutter/material.dart` dari Flutter 3.50) |
| `flutter test` (unit + widget) | **84 tes lulus**, 0 gagal |
| `flutter test integration_test/...` di emulator | **2 tes E2E lulus** |
| `flutter build apk --debug` | Berhasil (APK debug ~104 MB) |
| Uji alarm nyata di emulator (jam 21:31 WIB) | **Berhasil** — alarm tercatat tepat waktu, notifikasi berbunyi dengan `USAGE_ALARM` |

---

## 2. Bug utama: notifikasi & dering tidak berbunyi pada jam yang dijadwalkan

### Akar masalah
`tz.initializeTimeZones()` dari paket `timezone` **mereset `tz.local` menjadi UTC**
(lihat `timezone-0.9.4/lib/src/env.dart`: `_local = _UTC;`). Plugin
`flutter_local_notifications` mengirim *wall clock* + nama zona ke Android, lalu Android
membangun `ZonedDateTime` di zona tersebut. Karena `tz.local` = UTC, tugas jam **12:00
didaftarkan sebagai 12:00 UTC = 19:00 WIB** — jadi alarm tidak pernah berbunyi pada jam
yang diminta (selisih 7 jam pada WIB).

Masalah kedua: bila izin *exact alarm* belum diberikan pengguna, pemanggilan
`zonedSchedule(exactAllowWhileIdle...)` melempar `PlatformException` yang ditelan oleh
`catch` sehingga **tidak ada alarm sama sekali**, tanpa pesan apa pun.

### Perbaikan (semua di `lib/services/notification_service.dart`, `lib/providers/task_provider.dart`)
1. `ensureTimeZones()` — memanggil `tz.initializeTimeZones()` lalu
   `tz.setLocalLocation(resolveLocationForOffset(DateTime.now().timeZoneOffset))`,
   sehingga zona yang dipakai benar-benar sesuai offset perangkat (tetap 100% offline,
   tanpa plugin tambahan).
2. `_scheduleWithFallback()` — mencoba exact alarm, dan bila ditolak OS otomatis
   mengulang dengan `inexactAllowWhileIdle` supaya pengingat tetap berbunyi (mendekati jam
   target) alih-alih hilang.
3. Pengingat in-app: `TaskProvider` memasang timer untuk tugas terdekat; saat waktunya tiba
   modal pengingat terbuka dan dering loop (`MediaPlayer` native) berbunyi selama aplikasi
   terbuka.
4. Alarm didaftarkan ulang setiap aplikasi kembali ke foreground
   (`WidgetsBindingObserver` di `MainNavigationScreen`), sehingga alarm tidak hilang setelah
   perangkat reboot / battery saver.
5. `USE_FULL_SCREEN_INTENT` dideklarasikan di `AndroidManifest.xml` (sebelumnya
   `fullScreenIntent: true` dipakai tanpa izin).

### Bukti verifikasi di emulator (Android 15, zona Asia/Jakarta)
Tugas dibuat untuk **21:31 WIB**, aplikasi diletakkan di background:

```
dumpsys alarm:
  RTC_WAKEUP #5: Alarm{... origWhen 1795012260000 ... com.dapurflow.dapur_flow}
  tag=*walarm*:...ScheduledNotificationReceiver
  type=RTC_WAKEUP origWhen=2026-11-18 21:31:00.000 window=0 exactAllowReason=policy_permission

dumpsys notification:
  pkg=com.dapurflow.dapur_flow id=1 importance=5
  channel=flow_alarm_v4_with_vibration
  flags=INSISTENT|AUTO_CANCEL|HIGH_PRIORITY category=alarm
  when=1795012260018            (21:31:00.018 WIB)

dumpsys audio:
  21:31:00.784 requestAudioFocus ... usage=USAGE_ALARM
  21:31:01.488 player piid:95 event:started  (MediaPlayer, usage=USAGE_ALARM, berulang)
```

Screenshot notifikasi: "AturAjah: QA: alarm tepat waktu — Waktunya mengerjakan: 21:31 • 15 menit".

Sebelum perbaikan, alarm yang sama akan terjadwal pada 04:31 WIB keesokan harinya
(21:31 UTC) — persis keluhan "tidak bekerja jika jamnya sesuai".

---

## 3. Gap proposal yang sudah ditutup

| # | Sebelumnya | Perbaikan | Bukti |
|---|---|---|---|
| G1 | Jam sibuk/sepi tidak bisa diatur pengguna | Bagian **Jam Operasional** di Pengaturan: 4 pemilih jam (mulai/selesai jam tenang & jam sibuk), validasi urutan, tersimpan di `SharedPreferences`, dibaca lagi saat splash | `proposal_conformance_test.dart`, `shift_schedule_test.dart` |
| G2 | Tidak ada saran memindahkan tugas persiapan dari jam sibuk | Kartu saran di form tugas: "Jadwal ini jatuh di jam sibuk" + tombol **Pindahkan ke HH:MM** (satu ketuk) | `proposal_conformance_test.dart` |
| G3 | Tab Jadwal tidak menampilkan jendela waktu | Ringkasan **Jam Operasional** di atas tab Jadwal (jumlah tugas per jam tenang/transisi/sibuk) + `LiveStatusBanner` dipasang di dashboard | `proposal_conformance_test.dart` |
| G4 | Penugasan ke karyawan dihapus dari UI | Field **"Ditugaskan Kepada (opsional)"** di form, chip nama di kartu tugas & timeline jadwal, ikut tersimpan di template berulang | `proposal_conformance_test.dart`, E2E |
| G5 | Tidak ada tugas berulang (daftar kosong tiap hari) | Tabel `task_templates` (skema DB v2) + sakelar **"Ulangi setiap hari"**; tugas otomatis dibuat sekali per hari; layar **Tugas Berulang** untuk aktif/nonaktif & hapus | `recurring_and_weekly_test.dart` |
| G6 | Tidak ada ringkasan mingguan/statistik | Tab **Mingguan**: 7 hari terakhir, total tugas, selesai, pernah ditunda, progres per hari | `recurring_and_weekly_test.dart`, E2E |
| G7 | `fullScreenIntent` tanpa izin | `USE_FULL_SCREEN_INTENT` dideklarasikan dan terverifikasi ada di APK (`aapt2 dump permissions`) | build APK |
| G10 | `rescheduleTask` menaikkan `snooze_count`; jam tidak divalidasi; rawan duplikasi tugas berulang | `moveTask()` terpisah (tidak dihitung snooze), validasi urutan jam saat simpan & saat load, *unique index* `(template_id, created_at)`, load tasks diserialisasi (tidak dobel saat pull-to-refresh) | `task_provider_crud_test.dart`, `shift_schedule_test.dart` |

---

## 3b. Perbaikan tambahan dari QA lanjutan (pemeriksaan layar di emulator)

| Temuan | Perbaikan |
|---|---|
| Subjudul kartu prioritas "Nanti" terpotong ellipsis ("Tidak Mendesak & Tidak Pe…") di HP 1080×2400 | Kartu matrix diberi tinggi minimum 104 dan subjudul boleh 2 baris (`priority_matrix_selector.dart`) — keempat kartu kini menampilkan teks penuh dan tetap sejajar |
| Tab **Mingguan** menampilkan angka basi setelah pengguna mencentang/menghapus tugas (IndexedStack menyimpan state) | Layar berlangganan `TaskProvider` dan memuat ulang rekap di `didChangeDependencies` |
| Banner fase di dashboard & ringkasan jam di tab Jadwal tidak berubah setelah jam operasional diedit | `ShiftScheduleService` kini `ChangeNotifier`; banner dan ringkasan dibungkus `ListenableBuilder` sehingga langsung ikut berubah |
| Tugas hasil template yang dihapus muncul lagi saat pull-to-refresh | Tabel `template_skips` (skema DB v3) menandai kemunculan yang dihapus pada hari itu sehingga tidak dibuat ulang |
| Zona waktu alarm bisa terpilih acak (mis. `Antarctica/Davis` untuk +7) | `resolveLocationForOffset` memprioritaskan zona Indonesia/Asia bebas DST (`Asia/Jakarta` untuk WIB) sebelum fallback pemindaian |
| Tes alarm rapuh dijalankan dekat tengah malam | Helper `futureToday()`/`pastToday()` memilih jam yang valid pada hari berjalan, dengan penanda skip hanya pada jendela 2 menit sebelum tengah malam |
| Label tombol modal pengingat menduplikasi simbol ikon (ikon centang + teks "✓ Tandai Selesai", ikon snooze + "Zz …") | Teks dirapikan menjadi "Tandai Selesai" dan "Tunda / Jadwal Ulang" (ikon tetap ada) |
| Banner fase transisi memakai kalimat "Fokus layanan pelanggan" (menyesatkan sebelum jam sibuk) | Ditambah teks khusus transisi: "Siapkan bahan sebelum pelanggan datang" |

---

## 4. Masih terbuka / catatan

* **G8 (sebagian)**: saat aplikasi tertutup, dering berasal dari notifikasi `FLAG_INSISTENT`
  (terbukti berbunyi dengan `usage=USAGE_ALARM` di emulator); loop `MediaPlayer` native hanya
  aktif saat aplikasi terbuka / modal pengingat tampil. Perilaku ini wajar, tetapi volume dan
  getar sebaiknya tetap dicek di HP fisik.
* **G9**: `android/aturajah-release.keystore` tidak ada di repo, jadi APK rilis tidak bisa
  dibangun ulang dengan tanda tangan yang sama. Fitur auto-update mengharuskan APK baru
  ditandatangani dengan key yang sama — simpan keystore di tempat aman (bukan di repo).
* **Kotlin 2.4.10**: Flutter 3.50 memberi peringatan agar KGP dinaikkan ke ≥ 2.4.20
  (baru peringatan; build tetap berhasil). AGP sudah dinaikkan 9.1.0 → 9.1.1 karena Flutter
  menolak versi di bawahnya.
* Perilaku iOS dan kerasnya nada alarm/getar belum bisa diuji di mesin ini (emulator tanpa audio).

---

## 5. Cara menjalankan ulang

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
flutter pub get
flutter analyze                 # 0 error
flutter test                    # 78 tes

# E2E di emulator/perangkat Android
flutter test integration_test/proposal_flow_test.dart -d emulator-5554
```

Catatan saat menjalankan E2E: instalasi APK baru akan memunculkan dialog izin notifikasi
Android 13+; izinkan sekali (atau jalankan
`adb shell pm grant com.dapurflow.dapur_flow android.permission.POST_NOTIFICATIONS`
setelah APK terpasang).

---

## 6. Berkas QA & perubahan di branch `testing`

```
test/flutter_test_config.dart                    # boot sqflite+channel+font untuk semua tes
test/qa/support/test_harness.dart                # DB terisolasi, fake channel, recorder
test/qa/task_model_test.dart                     # model, kuadran, template
test/qa/shift_schedule_test.dart                 # klasifikasi & penyimpanan jam
test/qa/task_provider_crud_test.dart             # CRUD + snooze/reschedule + grouping
test/qa/task_input_screen_test.dart              # form input/edit/hapus
test/qa/dashboard_schedule_test.dart             # checklist harian & tab jadwal
test/qa/settings_reminder_test.dart              # alarm, modal pengingat, snooze
test/qa/notification_pipeline_test.dart          # zona waktu, exact→inexact, batal/jadwal ulang
test/qa/proposal_conformance_test.dart           # jam operasional, saran, assignee
test/qa/recurring_and_weekly_test.dart           # tugas berulang & ringkasan mingguan
test/qa/ui_shell_test.dart                       # 3 tab, modal pengingat otomatis, banner fase
test/qa/db_migration_test.dart                   # migrasi DB v1 -> v3 tanpa kehilangan data
integration_test/proposal_flow_test.dart         # E2E di Android nyata
docs/qa-laporan-proposal.md                      # laporan ini
```

Perubahan produksi:

```
lib/models/task_template.dart                    (baru)  template tugas harian
lib/models/task_model.dart                       template_id + clearAssignee
lib/providers/task_provider.dart                 materialisasi template, timer pengingat,
                                                 reschedule tanpa snooze, ringkasan mingguan
lib/services/database_helper.dart                skema v2 (task_templates, migrasi, unique index)
lib/services/notification_service.dart           perbaikan zona waktu + fallback exact alarm
lib/services/shift_schedule_service.dart         validasi + simpan jam operasional
lib/screens/task_input_screen.dart               assignee, ulangi harian, saran jam tenang
lib/screens/settings_screen.dart                 bagian Jam Operasional + akses Tugas Berulang
lib/screens/schedule_timeline_screen.dart        ringkasan jendela waktu, assignee
lib/screens/daily_dashboard_screen.dart          LiveStatusBanner
lib/screens/main_navigation_screen.dart          tab Mingguan + re-register alarm saat resume
lib/screens/recurring_tasks_screen.dart          (baru) kelola tugas berulang
lib/screens/weekly_overview_screen.dart          (baru) ringkasan mingguan
lib/widgets/live_status_banner.dart              teks dinamis sesuai jam pengguna
lib/widgets/task_card.dart                       chip assignee & penanda harian
lib/l10n/app_localizations.dart                  string baru (id/en)
android/app/src/main/AndroidManifest.xml         USE_FULL_SCREEN_INTENT
android/settings.gradle.kts                      AGP 9.1.0 → 9.1.1
pubspec.yaml                                     dev: integration_test, sqflite_common_ffi
```
