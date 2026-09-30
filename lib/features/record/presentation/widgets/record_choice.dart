// `RecordChoice` tinggal di kunci rute karena fitur lain memilih jenis awal
// CATAT lewat `RecordSheetInput` (ADR-030 §3.3).
export 'package:saldough/features/record/presentation/navigation/record_route_keys.dart' show RecordChoice;

/// Nilai sentinel dikembalikan formulir pemasukan saat pemakai memilih kartu
/// Freelance (FR-FRL-005: CATAT → Catat Pemasukan → Freelance).
/// `openRecordSheet` menafsirkannya dengan menutup alur CATAT lalu membuka
/// Ikhtisar Freelance.
final class OpenFreelance {
  /// Membuat [OpenFreelance].
  const OpenFreelance();
}
