import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// AppLocalizations handles instant runtime switching between
/// Bahasa Indonesia (default) and English without restarting the app.
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('id', 'ID'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('id', 'ID'),
    Locale('en', 'US'),
  ];

  static final Map<String, Map<String, String>> _localizedValues = {
    'id': {
      'app_title': 'AturAjah',
      'splash_subtitle': 'Daily Task & Schedule Manager',
      'tab_today': 'Hari Ini',
      'tab_schedule': 'Jadwal',
      
      // Live Status Banner
      'live_quiet_hours': 'LIVE STATUS: Jam Tenang (Quiet Hours) — Waktu terbaik persiapan hingga 11:00',
      'live_peak_hours': 'LIVE STATUS: Jam Sibuk (Peak Hours) — Fokus layanan pelanggan hingga 14:00',
      'live_standard_hours': 'LIVE STATUS: Jam Operasional Standar',

      // Dashboard
      'today_tasks': 'Tugas Hari Ini',
      'done': 'selesai',
      'all_completed': 'Semua tugas selesai untuk hari ini!',
      'no_tasks_today': 'Belum ada tugas hari ini. Ketuk tombol (+) untuk menambahkan.',
      'add_new_task': 'Tambah Tugas Harian',
      'minutes_short': 'mnt',
      'hours_short': 'j',
      'seconds_short': 'detik',

      // Priority Quadrants
      'q1_title': 'Kerjakan Dahulu',
      'q1_subtitle': 'Mendesak & Penting',
      'q1_desc': 'Fokus utama dan harus diselesaikan segera',
      
      'q2_title': 'Jadwalkan',
      'q2_subtitle': 'Tidak Mendesak & Penting',
      'q2_desc': 'Pekerjaan persiapan yang terencana',
      
      'q3_title': 'Delegasikan',
      'q3_subtitle': 'Mendesak & Tidak Penting',
      'q3_desc': 'Tugas operasional rutin dan cepat',
      
      'q4_title': 'Nanti',
      'q4_subtitle': 'Tidak Mendesak & Tidak Penting',
      'q4_desc': 'Prioritas rendah, selesaikan saat senggang',

      // Task Input & Edit Screen (Full CRUD)
      'input_screen_title': 'Tugas Baru',
      'edit_screen_title': 'Edit Tugas',
      'task_name_label': 'Nama Tugas',
      'task_name_hint': 'Contoh: Potong sayuran & siapkan kaldu',
      'target_time_label': 'Target Waktu',
      'duration_label': 'Durasi (Menit)',
      'priority_matrix_title': 'Matriks Prioritas (Eisenhower)',
      'save_task_cta': '✓ Simpan Tugas',
      'update_task_cta': '✓ Simpan Perubahan',
      'error_title_empty': 'Nama tugas tidak boleh kosong',
      'error_duration_invalid': 'Durasi harus lebih dari 0 menit',

      // Schedule Screen
      'schedule_screen_title': 'Jadwal Hari Ini',
      'planned_duration': 'direncanakan',
      'quiet_hours_header': 'Jam Tenang (Quiet Hours)',
      'quiet_hours_window': '09:00 - 11:00 • Waktu Persiapan',
      'peak_hours_header': 'Jam Sibuk (Peak Hours)',
      'peak_hours_window': '12:00 - 14:00 • Tetap fokus',
      'peak_service_notice': 'Layanan Pelanggan — Tidak ada tugas persiapan dijadwalkan',
      'peak_warning_task': 'Peringatan: Tugas persiapan jatuh pada jam sibuk layanan',
      'transition_tasks_header': 'Tugas Antara & Operasional Siang',
      'test_reminder_cta': 'Pratinjau Pengingat Alarm',
      'no_tasks_in_block': 'Tidak ada tugas pada rentang waktu ini',

      // Reminder Modal
      'reminder_modal_title': 'PENGINGAT TUGAS TIBA',
      'reminder_quiet_note': 'Direncanakan untuk jam tenang • Estimasi: %s menit',
      'reminder_peak_note': 'Peringatan: Jadwal jatuh pada jam sibuk layanan',
      'reminder_standard_note': 'Waktu pengerjaan tugas operasional • %s menit',
      'mark_done_cta': '✓ Tandai Selesai',
      'snooze_reschedule_cta': 'Zz Tunda / Jadwal Ulang',
      'snoozed_times_label': 'Ditunda: %s kali',

      // Snooze Bottom Sheet
      'snooze_sheet_title': 'Tunda atau Jadwalkan Ulang',
      'snooze_5m': '+5 Menit',
      'snooze_10m': '+10 Menit',
      'snooze_15m': '+15 Menit',
      'pick_new_time': 'Pilih Waktu Baru',
      'snooze_success': 'Tugas ditunda selama %s menit. Alarm pengulang aktif.',
      'reschedule_success': 'Tugas dijadwalkan ulang ke jam %s',

      // Settings Screen
      'settings_title': 'Pengaturan',
      'alarm_section': 'Pengaturan Alarm',
      'alarm_duration': 'Lama Bunyi Alarm',
      'alarm_duration_desc': 'Tentukan berapa lama alarm akan berbunyi saat waktu tugas tiba',
      'alarm_always_until_stopped': 'Selalu Bunyi (Hingga Dihentikan)',
      'stop_alarm_btn': 'Hentikan Alarm & Getar',
      'stop': 'Hentikan',
      'vibration_section': 'Pengaturan Getar',
      'vibration_enabled': 'Getar Saat Alarm Berbunyi',
      'vibration_intensity': 'Pola Getaran',
      'vibrate_short': 'Pendek',
      'vibrate_medium': 'Sedang (Standar)',
      'vibrate_long': 'Panjang / Kuat',
      'test_alarm_btn': 'Uji Coba Alarm & Getar',
      'test_alarm_success': 'Alarm dan getaran berhasil diuji coba!',

      // App Update
      'update_available_title': 'Pembaruan Tersedia',
      'current_version_prefix': 'Saat ini',
      'release_notes_label': 'Catatan Pembaruan',
      'default_update_notes': 'Peningkatan stabilitas dan pembaruan performa aplikasi.',
      'downloading': 'Mengunduh...',
      'download_complete_install_prompt': 'Unduhan selesai! Membuka paket instalasi...',
      'later_btn': 'Nanti',
      'update_now_btn': 'Perbarui Sekarang',
      'downloading_btn': 'Mengunduh...',
      'install_now_btn': 'Pasang Sekarang',
      'check_update_section': 'Pembaruan Aplikasi',
      'check_update_btn': 'Periksa Pembaruan',
      'app_is_up_to_date': 'Aplikasi sudah dalam versi terbaru (v%s)',
      'update_check_failed': 'Tidak dapat memeriksa pembaruan. Periksa koneksi internet.',
      'checking_update': 'Memeriksa pembaruan...',

      // General
      'language_switch': 'Bahasa',
      'close': 'Tutup',
      'cancel': 'Batal',
      'confirm': 'Konfirmasi',
      'delete_task': 'Hapus Tugas',
      'delete_task_confirm': 'Apakah Anda yakin ingin menghapus tugas ini?',
    },
    'en': {
      'app_title': 'AturAjah',
      'splash_subtitle': 'Daily Task & Schedule Manager',
      'tab_today': 'Today',
      'tab_schedule': 'Schedule',

      // Live Status Banner
      'live_quiet_hours': 'LIVE STATUS: Quiet Hours — Optimal prep time until 11:00',
      'live_peak_hours': 'LIVE STATUS: Peak Hours — Focus on customer service until 14:00',
      'live_standard_hours': 'LIVE STATUS: Standard Operational Hours',

      // Dashboard
      'today_tasks': 'Today\'s Tasks',
      'done': 'done',
      'all_completed': 'All tasks completed for today!',
      'no_tasks_today': 'No tasks scheduled for today. Tap (+) to add.',
      'add_new_task': 'Add Daily Task',
      'minutes_short': 'min',
      'hours_short': 'h',
      'seconds_short': 'sec',

      // Priority Quadrants
      'q1_title': 'Do First',
      'q1_subtitle': 'Urgent & Important',
      'q1_desc': 'Immediate priority, finish promptly',

      'q2_title': 'Schedule',
      'q2_subtitle': 'Not Urgent & Important',
      'q2_desc': 'Planned prep & organizational work',

      'q3_title': 'Delegate',
      'q3_subtitle': 'Urgent & Not Important',
      'q3_desc': 'Quick operational routine tasks',

      'q4_title': 'Later',
      'q4_subtitle': 'Not Urgent & Not Important',
      'q4_desc': 'Low priority, address when free',

      // Task Input & Edit Screen (Full CRUD)
      'input_screen_title': 'New Task',
      'edit_screen_title': 'Edit Task',
      'task_name_label': 'Task Name',
      'task_name_hint': 'e.g., Chop vegetables & prepare broth',
      'target_time_label': 'Target Time',
      'duration_label': 'Duration (Minutes)',
      'priority_matrix_title': 'Priority Matrix (Eisenhower)',
      'save_task_cta': '✓ Save Task',
      'update_task_cta': '✓ Save Changes',
      'error_title_empty': 'Task name cannot be empty',
      'error_duration_invalid': 'Duration must be greater than 0 minutes',

      // Schedule Screen
      'schedule_screen_title': 'Today\'s Schedule',
      'planned_duration': 'planned',
      'quiet_hours_header': 'Quiet Hours (Prep Time)',
      'quiet_hours_window': '09:00 - 11:00 • Prep Window',
      'peak_hours_header': 'Peak Hours (Rush Time)',
      'peak_hours_window': '12:00 - 14:00 • Stay focused',
      'peak_service_notice': 'Customer Service — No prep tasks scheduled',
      'peak_warning_task': 'Warning: Prep task scheduled during peak service window',
      'transition_tasks_header': 'Mid-day & Operational Tasks',
      'test_reminder_cta': 'Test Reminder Alert',
      'no_tasks_in_block': 'No tasks scheduled in this window',

      // Reminder Modal
      'reminder_modal_title': 'SCHEDULED TASK ALERT',
      'reminder_quiet_note': 'Planned for quiet hours • Est: %s min',
      'reminder_peak_note': 'Warning: Scheduled during busy customer service peak',
      'reminder_standard_note': 'Operational task window • %s min',
      'mark_done_cta': '✓ Mark as Done',
      'snooze_reschedule_cta': 'Zz Snooze / Reschedule',
      'snoozed_times_label': 'Snoozed: %s times',

      // Snooze Bottom Sheet
      'snooze_sheet_title': 'Snooze or Reschedule',
      'snooze_5m': '+5 Minutes',
      'snooze_10m': '+10 Minutes',
      'snooze_15m': '+15 Minutes',
      'pick_new_time': 'Pick New Time',
      'snooze_success': 'Task snoozed for %s minutes. Repeating alarm set.',
      'reschedule_success': 'Task rescheduled to %s',

      // Settings Screen
      'settings_title': 'Settings',
      'alarm_section': 'Alarm Settings',
      'alarm_duration': 'Alarm Ring Duration',
      'alarm_duration_desc': 'Configure how long the alarm rings when task time arrives',
      'alarm_always_until_stopped': 'Always Ring (Until Stopped)',
      'stop_alarm_btn': 'Stop Alarm & Vibration',
      'stop': 'Stop',
      'vibration_section': 'Vibration Settings',
      'vibration_enabled': 'Vibrate When Alarm Rings',
      'vibration_intensity': 'Vibration Pattern',
      'vibrate_short': 'Short',
      'vibrate_medium': 'Medium (Default)',
      'vibrate_long': 'Long / Strong',
      'test_alarm_btn': 'Test Alarm & Vibration',
      'test_alarm_success': 'Test alarm and vibration triggered!',

      // App Update
      'update_available_title': 'Update Available',
      'current_version_prefix': 'Current',
      'release_notes_label': 'Release Notes',
      'default_update_notes': 'Stability improvements and performance optimizations.',
      'downloading': 'Downloading...',
      'download_complete_install_prompt': 'Download complete! Opening package installer...',
      'later_btn': 'Later',
      'update_now_btn': 'Update Now',
      'downloading_btn': 'Downloading...',
      'install_now_btn': 'Install Now',
      'check_update_section': 'App Updates',
      'check_update_btn': 'Check for Updates',
      'app_is_up_to_date': 'App is already up to date (v%s)',
      'update_check_failed': 'Could not check for updates. Check internet connection.',
      'checking_update': 'Checking for updates...',

      // General
      'language_switch': 'Language',
      'close': 'Close',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'delete_task': 'Delete Task',
      'delete_task_confirm': 'Are you sure you want to delete this task?',
    },
  };

  String translate(String key, [List<String>? args]) {
    final lang = locale.languageCode;
    String text = _localizedValues[lang]?[key] ??
        _localizedValues['id']?[key] ??
        key;

    if (args != null && args.isNotEmpty) {
      for (final arg in args) {
        text = text.replaceFirst('%s', arg);
      }
    }
    return text;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['id', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension LocalizationExtension on BuildContext {
  String tr(String key, [List<String>? args]) {
    return AppLocalizations.of(this).translate(key, args);
  }
}
