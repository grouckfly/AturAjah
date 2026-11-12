/// Model representing remote version update metadata
class UpdateInfoModel {
  final String version;
  final int versionCode;
  final String releaseDate;
  final String releaseNotes;
  final String releaseNotesEn;
  final String apkUrl;
  final String? arm64ApkUrl;

  const UpdateInfoModel({
    required this.version,
    required this.versionCode,
    required this.releaseDate,
    required this.releaseNotes,
    required this.releaseNotesEn,
    required this.apkUrl,
    this.arm64ApkUrl,
  });

  factory UpdateInfoModel.fromJson(Map<String, dynamic> json) {
    return UpdateInfoModel(
      version: json['version'] as String? ?? '1.0.0',
      versionCode: json['versionCode'] as int? ?? 1,
      releaseDate: json['releaseDate'] as String? ?? '',
      releaseNotes: json['releaseNotes'] as String? ?? '',
      releaseNotesEn: json['releaseNotesEn'] as String? ?? '',
      apkUrl: json['apkUrl'] as String? ?? '',
      arm64ApkUrl: json['arm64ApkUrl'] as String?,
    );
  }
}
