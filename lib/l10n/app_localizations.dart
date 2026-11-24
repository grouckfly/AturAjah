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
      'mark_done_cta': 'Tandai Selesai',
      'snooze_reschedule_cta': 'Tunda / Jadwal Ulang',
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

      // Operating Hours (propsal feature 3)
      'operational_hours_section': 'Jam Operasional',
      'operational_hours_desc':
          'Sesuaikan jam tenang (persiapan) dan jam sibuk (layanan) dengan pola pelanggan Anda',
      'quiet_hours_label': 'Jam Tenang (Persiapan)',
      'peak_hours_label': 'Jam Sibuk (Layanan)',
      'window_start': 'Mulai',
      'window_end': 'Selesai',
      'invalid_hours_error':
          'Urutan jam tidak valid: Jam Tenang harus selesai sebelum Jam Sibuk dimulai',
      'hours_saved': 'Jam operasional diperbarui',
      'banner_quiet_now': 'Waktu persiapan — selesaikan tugas persiapan sekarang',
      'banner_peak_now': 'Fokus layanan pelanggan',
      'banner_transition': 'Menuju jam sibuk',
      'banner_transition_desc': 'Siapkan bahan sebelum pelanggan datang',
      'other_tasks_header': 'Jam Lain',
      'other_tasks_window': 'di luar jam tenang & sibuk',
      'recurring_section': 'Tugas Berulang',
      'recurring_section_desc': 'Kelola tugas yang dibuat otomatis setiap hari',
      'open_recurring_btn': 'Kelola Tugas Berulang',

      // Task input extras
      'assignee_label': 'Ditugaskan Kepada (opsional)',
      'assignee_hint': 'Contoh: Sari',
      'repeat_daily_label': 'Ulangi setiap hari',
      'repeat_daily_desc': 'Tugas dibuat otomatis setiap hari saat aplikasi dibuka',
      'repeat_badge': 'Harian',

      // Quiet-hour suggestion
      'suggestion_peak_title': 'Jadwal ini jatuh di jam sibuk',
      'suggestion_peak_body':
          'Pindahkan ke jam tenang (%s) agar persiapan selesai sebelum pelanggan datang.',
      'suggestion_move_cta': 'Pindahkan ke %s',
      'task_moved_to': 'Tugas dipindahkan ke %s',

      // Schedule view switch
      'view_by_priority': 'Prioritas',
      'view_by_time': 'Waktu',
      'tasks_count': '%s tugas',

      // Recurring tasks screen
      'recurring_title': 'Tugas Berulang',
      'recurring_empty':
          'Belum ada tugas berulang. Aktifkan opsi "Ulangi setiap hari" saat membuat tugas.',
      'recurring_active': 'Aktif',
      'recurring_inactive': 'Nonaktif',
      'delete_template_confirm':
          'Hapus tugas berulang ini? Tugas hari ini tidak ikut terhapus.',

      // Weekly overview
      'tab_weekly': 'Mingguan',
      'weekly_title': 'Ringkasan Mingguan',
      'weekly_subtitle': '7 hari terakhir',
      'weekly_total_tasks': 'Total tugas',
      'weekly_completed': 'Selesai',
      'weekly_snoozed': 'Pernah ditunda',
      'weekly_no_tasks': 'Tidak ada tugas',
      'weekly_today': 'Hari ini',

      // Presets & Proposal Evaluation
      'preset_sheet_title': 'Template Usaha UMKM',
      'preset_sheet_subtitle': 'Pilih contoh jadwal operasional sesuai jenis usaha Anda',
      'preset_save_as_recurring': 'Simpan juga sebagai tugas berulang harian',
      'apply_preset_cta': 'Terapkan Template',
      'open_presets_btn': 'Template Cepat UMKM',
      'proposal_metrics_title': 'Evaluasi Kinerja Operasional',
      'proposal_target_badge': 'Target Proposal',
      'metric_quiet_prep_title': 'Persiapan Jam Tenang',
      'metric_quiet_prep_desc': 'Selesai sebelum jam sibuk',
      'metric_delay_reduction_title': 'Ketepatan Waktu Layanan',
      'metric_delay_reduction_desc': 'Tugas selesai tanpa ditunda',
      'metric_productive_hours_title': 'Waktu Produktif Selesai',
      'metric_productive_hours_desc': 'Total durasi kerja operasional',

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
      'mark_done_cta': 'Mark as Done',
      'snooze_reschedule_cta': 'Snooze / Reschedule',
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

      // Operating hours (proposal feature 3)
      'operational_hours_section': 'Operating Hours',
      'operational_hours_desc':
          'Match the quiet (prep) and peak (service) windows to your customer traffic',
      'quiet_hours_label': 'Quiet Hours (Prep)',
      'peak_hours_label': 'Peak Hours (Service)',
      'window_start': 'Start',
      'window_end': 'End',
      'invalid_hours_error':
          'Invalid order: Quiet Hours must end before Peak Hours start',
      'hours_saved': 'Operating hours updated',
      'banner_quiet_now': 'Prep time — finish preparation tasks now',
      'banner_peak_now': 'Focus on customer service',
      'banner_transition': 'Approaching peak hours',
      'banner_transition_desc': 'Prepare ingredients before customers arrive',
      'other_tasks_header': 'Other Hours',
      'other_tasks_window': 'outside quiet & peak windows',
      'recurring_section': 'Recurring Tasks',
      'recurring_section_desc': 'Manage tasks that are created automatically every day',
      'open_recurring_btn': 'Manage Recurring Tasks',

      // Task input extras
      'assignee_label': 'Assigned To (optional)',
      'assignee_hint': 'e.g. Sari',
      'repeat_daily_label': 'Repeat every day',
      'repeat_daily_desc': 'The task is created automatically each day the app opens',
      'repeat_badge': 'Daily',

      // Quiet-hour suggestion
      'suggestion_peak_title': 'This slot falls in peak hours',
      'suggestion_peak_body':
          'Move it to the quiet window (%s) so prep is done before customers arrive.',
      'suggestion_move_cta': 'Move to %s',
      'task_moved_to': 'Task moved to %s',

      // Schedule view switch
      'view_by_priority': 'Priority',
      'view_by_time': 'Time',
      'tasks_count': '%s tasks',

      // Recurring tasks screen
      'recurring_title': 'Recurring Tasks',
      'recurring_empty':
          'No recurring tasks yet. Turn on "Repeat every day" when creating a task.',
      'recurring_active': 'Active',
      'recurring_inactive': 'Inactive',
      'delete_template_confirm':
          'Delete this recurring task? Today\'s task stays untouched.',

      // Weekly overview
      'tab_weekly': 'Weekly',
      'weekly_title': 'Weekly Summary',
      'weekly_subtitle': 'Last 7 days',
      'weekly_total_tasks': 'Total tasks',
      'weekly_completed': 'Completed',
      'weekly_snoozed': 'Snoozed',
      'weekly_no_tasks': 'No tasks',
      'weekly_today': 'Today',

      // Presets & Proposal Evaluation
      'preset_sheet_title': 'MSME Business Templates',
      'preset_sheet_subtitle': 'Choose an operational schedule preset tailored to your business',
      'preset_save_as_recurring': 'Also save as daily recurring tasks',
      'apply_preset_cta': 'Apply Template',
      'open_presets_btn': 'MSME Starter Presets',
      'proposal_metrics_title': 'Operational Performance Evaluation',
      'proposal_target_badge': 'Proposal Target',
      'metric_quiet_prep_title': 'Quiet Hours Preparation',
      'metric_quiet_prep_desc': 'Completed before peak rush',
      'metric_delay_reduction_title': 'Service Punctuality',
      'metric_delay_reduction_desc': 'Tasks completed without delay',
      'metric_productive_hours_title': 'Productive Hours Completed',
      'metric_productive_hours_desc': 'Total operational work duration',

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
