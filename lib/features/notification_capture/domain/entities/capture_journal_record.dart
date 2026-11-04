import 'package:dependencies/dependencies.dart';

/// Satu entri jurnal native notifikasi bertindak (ADR-044 §3.5, T-26.10), apa
/// adanya dari kanal. [payload] adalah JSON yang dibuat mesin tanpa layar
/// (draf yang diselesaikan dan kemunculan rutin yang cocok); native tidak
/// menafsirkannya.
final class CaptureJournalRecord extends Equatable {
  /// Membuat [CaptureJournalRecord].
  const CaptureJournalRecord({
    required this.id,
    required this.decision,
    required this.resolvedAt,
    required this.payload,
  });

  /// Id tangkapan.
  final String id;

  /// `record`, `dismiss`, atau `null` bila pengguna belum (atau tidak jadi) memutuskan.
  final String? decision;

  /// Kapan mesin tanpa layar menyelesaikan tangkapan.
  final DateTime resolvedAt;

  /// JSON muatan.
  final String payload;

  @override
  List<Object?> get props => [id, decision, resolvedAt, payload];
}
