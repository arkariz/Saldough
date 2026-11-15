import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/entities/period_book_memory.dart';
import 'package:saldough/features/period_book/domain/services/closed_periods.dart';

/// Keadaan satu buku di Rak Buku (BP-9, BP-10).
enum ShelfStatus {
  /// Sudah pernah dibuka: terbuka selamanya, apa pun paketnya (BP-10).
  opened,

  /// Belum dibuka dan boleh (Plus atau uji coba): "Belum dibuka" (BP-9).
  unopened,

  /// Belum pernah dibuka dan paket bukan Plus: terkunci; hanya Kartu Periode.
  locked,
}

/// Satu buku di Rak Buku.
final class ShelfEntry extends Equatable {
  /// Membuat [ShelfEntry].
  const ShelfEntry({required this.period, required this.status});

  /// Periodenya.
  final ClosedPeriod period;

  /// Keadaannya.
  final ShelfStatus status;

  @override
  List<Object?> get props => [period, status];
}

/// Isi Rak Buku: semua periode tertutup (terbaru di atas) dengan keadaannya
/// (BP-3, BP-9, BP-10). Tampil untuk semua pengguna; yang terkunci hanya yang
/// belum pernah dibuka saat paket bukan Plus.
List<ShelfEntry> shelfOf({
  required List<ClosedPeriod> closed,
  required PeriodBookMemory memory,
  required bool plusActive,
}) => [
  for (final period in closed)
    ShelfEntry(
      period: period,
      status: memory.isOpened(period.id)
          ? ShelfStatus.opened
          : (plusActive ? ShelfStatus.unopened : ShelfStatus.locked),
    ),
];

/// Jenis ajakan akhir periode di Beranda (BP-2, BP-9, BP-14, BP-15).
enum InvitationKind {
  /// Plus: "Buku … siap ditutup" (ritual Tutup buku).
  book,

  /// Gratis: "Kartu periode … siap dibagikan".
  card,
}

/// Ajakan untuk satu periode.
final class PeriodInvitation extends Equatable {
  /// Membuat [PeriodInvitation].
  const PeriodInvitation({required this.period, required this.kind});

  /// Periode yang diajakkan.
  final ClosedPeriod period;

  /// Buku (Plus) atau kartu (Gratis).
  final InvitationKind kind;

  @override
  List<Object?> get props => [period, kind];
}

/// Ajakan di Beranda, atau `null` (fungsi murni).
///
/// - Hanya untuk periode **tepat sebelum** periode berjalan (BP-9), tertutup, dan
///   dengan ≥[periodCardMinTransactions] transaksi (BP-2, BP-20).
/// - Satu kartu per periode: "Nanti" (`cardDismissed`) menutupnya (BP-2).
/// - Plus yang sudah membuka bukunya tidak diajak lagi; Plus yang mematikan
///   Ajakan akhir periode tidak diajak (BP-14). Plus selain itu mendapat ajakan
///   buku; Gratis mendapat ajakan kartu.
PeriodInvitation? invitationFor({
  required List<ClosedPeriod> closed,
  required PeriodBookMemory memory,
  required bool plusActive,
  required DateTime previousPeriodStart,
}) {
  final candidate = closed.where((c) => c.period.start == previousPeriodStart).firstOrNull;
  if (candidate == null || candidate.transactionCount < periodCardMinTransactions) {
    return null;
  }
  if (memory.cardDismissed.contains(candidate.id)) {
    return null;
  }
  if (plusActive) {
    if (!memory.inviteEnabled || memory.isOpened(candidate.id)) {
      return null;
    }
    return PeriodInvitation(period: candidate, kind: InvitationKind.book);
  }
  return PeriodInvitation(period: candidate, kind: InvitationKind.card);
}
