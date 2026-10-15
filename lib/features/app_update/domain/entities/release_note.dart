import 'package:dependencies/dependencies.dart';

/// Kategori butir catatan (ADR-039 §3.3). [slug] adalah nilai di berkas
/// catatan; label dan emoji dipetakan di presentasi.
enum NoteCategory {
  /// Kemampuan atau layar baru yang terlihat.
  newFeature('new'),

  /// Lebih cepat; hanya bila terukur.
  faster('faster'),

  /// Sesuatu yang salah kini benar.
  fixed('fixed'),

  /// Perlindungan data atau akses, konkret.
  security('security');

  const NoteCategory(this.slug);

  /// Nilai di berkas catatan.
  final String slug;

  /// Kategori dari [slug], atau `null` bila tak dikenal (mis. dari versi
  /// aplikasi yang lebih baru).
  static NoteCategory? fromSlug(String slug) {
    for (final category in values) {
      if (category.slug == slug) return category;
    }
    return null;
  }
}

/// Satu butir catatan dalam dua bahasa.
final class LocalizedNote extends Equatable {
  /// Membuat [LocalizedNote].
  const LocalizedNote({required this.id, required this.en});

  /// Teks bahasa Indonesia.
  final String id;

  /// Teks bahasa Inggris.
  final String en;

  /// Teks untuk bahasa aktif; Inggris sebagai cadangan.
  String text({required bool english}) => english ? en : (id.isEmpty ? en : id);

  @override
  List<Object?> get props => [id, en];
}

/// Butir-butir satu kategori. [category] `null` = kategori tak dikenal:
/// tampil tanpa label dan emoji.
final class NoteGroup extends Equatable {
  /// Membuat [NoteGroup].
  const NoteGroup({required this.category, required this.notes});

  /// Kategori, atau `null`.
  final NoteCategory? category;

  /// Butir, urutan tampil.
  final List<LocalizedNote> notes;

  @override
  List<Object?> get props => [category, notes];
}

/// Kunci entri catatan: build dan nomor pembaruan kecil (0 = rilis toko).
typedef ReleaseKey = ({int build, int patch});

/// Catatan satu rilis toko atau satu pembaruan kecil.
final class ReleaseNote extends Equatable {
  /// Membuat [ReleaseNote].
  const ReleaseNote({required this.build, required this.patch, required this.version, required this.groups});

  /// Nomor build.
  final int build;

  /// Nomor pembaruan kecil; 0 untuk rilis toko.
  final int patch;

  /// Nama versi, mis. `0.6.0`.
  final String version;

  /// Kelompok per kategori, urutan tampil.
  final List<NoteGroup> groups;

  /// Kunci entri.
  ReleaseKey get key => (build: build, patch: patch);

  /// Jumlah butir seluruh kelompok.
  int get noteCount => groups.fold(0, (sum, group) => sum + group.notes.length);

  /// Tanpa butir sama sekali.
  bool get isEmpty => noteCount == 0;

  @override
  List<Object?> get props => [build, patch, version, groups];
}

/// Urutan kunci: build dulu, lalu pembaruan kecil. Negatif bila [a] < [b].
int compareReleaseKeys(ReleaseKey a, ReleaseKey b) {
  final byBuild = a.build.compareTo(b.build);
  return byBuild != 0 ? byBuild : a.patch.compareTo(b.patch);
}
