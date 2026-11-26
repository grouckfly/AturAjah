import 'package:flutter/material.dart';
import 'priority_quadrant.dart';

/// Predefined task model for MSME business starter packs based on
/// actual field interviews in the proposal (Padang restaurant, mixed rice stall,
/// fried food cart, coffee bike, and juice shop).
class MsmePresetTask {
  final String title;
  final String targetTime;
  final int durationMinutes;
  final PriorityQuadrant priorityQuadrant;
  final String? assignee;

  const MsmePresetTask({
    required this.title,
    required this.targetTime,
    required this.durationMinutes,
    required this.priorityQuadrant,
    this.assignee,
  });
}

class MsmePreset {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final List<MsmePresetTask> tasks;

  const MsmePreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.tasks,
  });

  /// The 5 MSME archetypes from the proposal's user interviews (Section 2)
  static List<MsmePreset> get presets => const [
        MsmePreset(
          id: 'padang',
          title: 'Rumah Makan Padang',
          subtitle: 'Persiapan bumbu & rendang pagi, tata display sebelum makan siang',
          icon: Icons.dinner_dining_rounded,
          accentColor: Color(0xFFD84315),
          tasks: [
            MsmePresetTask(
              title: 'Rebus rendang & ungkep ayam gulai',
              targetTime: '06:30',
              durationMinutes: 60,
              priorityQuadrant: PriorityQuadrant.doFirst,
              assignee: 'Koki',
            ),
            MsmePresetTask(
              title: 'Rebus daun singkong & uleg sambal ijo',
              targetTime: '08:00',
              durationMinutes: 40,
              priorityQuadrant: PriorityQuadrant.schedule,
              assignee: 'Asisten',
            ),
            MsmePresetTask(
              title: 'Tata lauk etalase bertingkat & piring bersih',
              targetTime: '09:30',
              durationMinutes: 30,
              priorityQuadrant: PriorityQuadrant.doFirst,
              assignee: 'Pelayan',
            ),
            MsmePresetTask(
              title: 'Layanan jam sibuk pelanggan makan siang',
              targetTime: '11:30',
              durationMinutes: 90,
              priorityQuadrant: PriorityQuadrant.doFirst,
            ),
            MsmePresetTask(
              title: 'Restok beras & cuci panci besar',
              targetTime: '14:00',
              durationMinutes: 30,
              priorityQuadrant: PriorityQuadrant.delegate,
              assignee: 'Asisten',
            ),
          ],
        ),
        MsmePreset(
          id: 'nasi_campur',
          title: 'Warung Nasi Campur',
          subtitle: 'Belanja sayur, masak lauk matang, siapkan katering & makan siang',
          icon: Icons.rice_bowl_rounded,
          accentColor: Color(0xFFEF6C00),
          tasks: [
            MsmePresetTask(
              title: 'Belanja sayuran segar & bahan harian',
              targetTime: '07:00',
              durationMinutes: 45,
              priorityQuadrant: PriorityQuadrant.schedule,
              assignee: 'Owner',
            ),
            MsmePresetTask(
              title: 'Masak nasi & lauk pauk utama',
              targetTime: '08:15',
              durationMinutes: 50,
              priorityQuadrant: PriorityQuadrant.doFirst,
              assignee: 'Koki',
            ),
            MsmePresetTask(
              title: 'Bungkus pesanan katering makan pagi',
              targetTime: '10:00',
              durationMinutes: 30,
              priorityQuadrant: PriorityQuadrant.doFirst,
              assignee: 'Staf',
            ),
            MsmePresetTask(
              title: 'Fokus layanan pelanggan makan siang',
              targetTime: '12:00',
              durationMinutes: 90,
              priorityQuadrant: PriorityQuadrant.doFirst,
            ),
            MsmePresetTask(
              title: 'Hitung kas harian & rapikan meja',
              targetTime: '14:30',
              durationMinutes: 25,
              priorityQuadrant: PriorityQuadrant.later,
              assignee: 'Owner',
            ),
          ],
        ),
        MsmePreset(
          id: 'gorengan',
          title: 'Gerobak Gorengan',
          subtitle: 'Kupas pisang/tahu, racik adonan tepung, goreng awal sebelum ramai',
          icon: Icons.bakery_dining_rounded,
          accentColor: Color(0xFFF57C00),
          tasks: [
            MsmePresetTask(
              title: 'Kupas pisang, potong tahu & tempe',
              targetTime: '08:30',
              durationMinutes: 45,
              priorityQuadrant: PriorityQuadrant.schedule,
              assignee: 'Staf',
            ),
            MsmePresetTask(
              title: 'Racik adonan tepung bumbu & sambal petis',
              targetTime: '09:45',
              durationMinutes: 35,
              priorityQuadrant: PriorityQuadrant.doFirst,
              assignee: 'Owner',
            ),
            MsmePresetTask(
              title: 'Panaskan minyak & goreng kloter awal',
              targetTime: '13:00',
              durationMinutes: 40,
              priorityQuadrant: PriorityQuadrant.doFirst,
              assignee: 'Staf',
            ),
            MsmePresetTask(
              title: 'Layanan jam ramai pembeli sore hari',
              targetTime: '16:00',
              durationMinutes: 90,
              priorityQuadrant: PriorityQuadrant.doFirst,
            ),
          ],
        ),
        MsmePreset(
          id: 'kopi',
          title: 'Kedai Kopi & Coffee Bike',
          subtitle: 'Remukkan es batu, seduh konsentrat kopi, atur cup sebelum antrean',
          icon: Icons.local_cafe_rounded,
          accentColor: Color(0xFF6D4C41),
          tasks: [
            MsmePresetTask(
              title: 'Hancurkan es batu & isi termos es',
              targetTime: '07:00',
              durationMinutes: 20,
              priorityQuadrant: PriorityQuadrant.doFirst,
              assignee: 'Barista',
            ),
            MsmePresetTask(
              title: 'Seduh konsentrat kopi espresso & susu',
              targetTime: '07:30',
              durationMinutes: 35,
              priorityQuadrant: PriorityQuadrant.schedule,
              assignee: 'Barista',
            ),
            MsmePresetTask(
              title: 'Siapkan cup, sedotan & restok cup holder',
              targetTime: '09:00',
              durationMinutes: 20,
              priorityQuadrant: PriorityQuadrant.delegate,
              assignee: 'Asisten',
            ),
            MsmePresetTask(
              title: 'Layanan jam ramai pesanan kopi',
              targetTime: '12:00',
              durationMinutes: 90,
              priorityQuadrant: PriorityQuadrant.doFirst,
            ),
          ],
        ),
        MsmePreset(
          id: 'jus',
          title: 'Toko Jus Buah Segar',
          subtitle: 'Kupas buah, porsi per bungkus, siapkan gula cair sebelum jam ramai',
          icon: Icons.local_bar_rounded,
          accentColor: Color(0xFF2E7D32),
          tasks: [
            MsmePresetTask(
              title: 'Kupas & potong buah (alpukat, mangga, naga)',
              targetTime: '08:00',
              durationMinutes: 45,
              priorityQuadrant: PriorityQuadrant.schedule,
              assignee: 'Staf',
            ),
            MsmePresetTask(
              title: 'Porsi buah plastik & blender siap pakai',
              targetTime: '09:15',
              durationMinutes: 30,
              priorityQuadrant: PriorityQuadrant.doFirst,
              assignee: 'Staf',
            ),
            MsmePresetTask(
              title: 'Buat gula cair & restok susu kental',
              targetTime: '10:15',
              durationMinutes: 20,
              priorityQuadrant: PriorityQuadrant.delegate,
              assignee: 'Asisten',
            ),
            MsmePresetTask(
              title: 'Layanan jam sibuk pembeli jus siang',
              targetTime: '12:30',
              durationMinutes: 75,
              priorityQuadrant: PriorityQuadrant.doFirst,
            ),
          ],
        ),
      ];
}
