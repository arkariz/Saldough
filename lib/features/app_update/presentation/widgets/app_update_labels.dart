import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';
import 'package:saldough/features/app_update/domain/services/update_policy.dart';

/// Teks dan ikon keadaan versi yang dipakai baris Akun dan halaman Versi
/// aplikasi (APP_UPDATE F4), supaya keduanya selalu sama.

/// "0.6.0 (7)" atau "0.6.0 (7), pembaruan 1" bila tambalan berjalan.
String versionValue(AppVersion version) => version.patch > 0
    ? t.account.version.valuePatched(version: version.name, build: version.build, patch: version.patch)
    : t.account.version.value(version: version.name, build: version.build);

/// Keterangan keadaan; `null` bila tidak bisa dicek (kosong).
String? versionStatusLabel(VersionStatus status) => switch (status) {
  VersionStatus.unknown => null,
  VersionStatus.latest => t.account.version.statusLatest,
  VersionStatus.available => t.account.version.statusAvailable,
  VersionStatus.downloading => t.account.version.statusDownloading,
  VersionStatus.downloaded => t.account.version.statusDownloaded,
  VersionStatus.patchReady => t.account.version.statusPatchReady,
};

/// Keadaan yang perlu terlihat (label tebal): semuanya kecuali terbaru dan
/// tidak diketahui.
bool versionStatusStrong(VersionStatus status) => status != VersionStatus.latest && status != VersionStatus.unknown;

/// Ikon kepala halaman Versi aplikasi menurut keadaan.
IconKey versionStatusIcon(VersionStatus status) => switch (status) {
  VersionStatus.latest => IconKey.checkCircle,
  VersionStatus.available || VersionStatus.downloaded => IconKey.systemUpdate,
  VersionStatus.downloading => IconKey.progressActivity,
  VersionStatus.patchReady => IconKey.restartAlt,
  VersionStatus.unknown => IconKey.info,
};
