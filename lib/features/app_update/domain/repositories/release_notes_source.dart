import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/app_update/domain/entities/app_version.dart';
import 'package:saldough/features/app_update/domain/entities/release_note.dart';

/// Catatan yang sudah dikenal aplikasi pada satu saat.
final class ReleaseNotesSnapshot extends Equatable {
  /// Membuat [ReleaseNotesSnapshot].
  const ReleaseNotesSnapshot({this.entries = const {}, this.serverRead = false});

  /// Belum ada apa-apa.
  static const empty = ReleaseNotesSnapshot();

  /// Entri menurut kunci.
  final Map<ReleaseKey, ReleaseNote> entries;

  /// Server sudah pernah berhasil dibaca (bukan hanya salinan lokal), jadi
  /// entri yang tidak ada berarti memang tidak ada (ADR-039 §3.3 butir 5).
  final bool serverRead;

  @override
  List<Object?> get props => [entries, serverRead];
}

/// Sumber catatan Apa yang baru (ADR-039 §3.3): Remote Config dengan salinan
/// lokal. Kegagalan dikembalikan sebagai `Left`; pemanggil menganggapnya
/// "belum ada data", tidak pernah galat ke UI.
abstract interface class ReleaseNotesSource {
  /// Memuat catatan. [refresh] true mencoba mengambil dari server dulu (tunduk
  /// pada batas frekuensi SDK); false hanya nilai yang sudah ada di perangkat.
  /// Hanya entri sampai [running] yang disalin ke penyimpanan lokal, supaya
  /// catatan rilis gagal tidak ikut tersimpan.
  Future<Either<Failure, ReleaseNotesSnapshot>> load({required AppVersion running, bool refresh = true});

  /// Sinyal nilai baru diaktifkan saat aplikasi terbuka (`onConfigUpdated`).
  Stream<void> get changes;
}
