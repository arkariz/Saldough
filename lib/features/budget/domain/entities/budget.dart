import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_status.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Rencana pengeluaran untuk satu periode, terikat pada satu dompet.
///
/// ⚠ Anggaran adalah rencana, **bukan pemesanan uang**. Membuat, menyunting,
/// atau mengarsipkannya tidak pernah mengubah saldo dompet mana pun (aturan 5
/// CLAUDE.md). Beberapa anggaran boleh aktif sekaligus, berbagi satu dompet,
/// dan berbeda periode. Lihat DOMAIN_MODEL.md bagian "Anggaran".
///
/// Nominal rencananya SELALU jumlah pos ([plannedAmount]), tidak diketik
/// terpisah — ADR-017. Anggaran tanpa pos tidak bisa melacak pengeluaran apa
/// pun (transaksi hanya bisa ditautkan ke pos), jadi formulir mewajibkan
/// minimal satu pos.
final class Budget extends Equatable {
  /// Membuat [Budget].
  const Budget({
    required this.id,
    required this.name,
    required this.walletId,
    required this.period,
    required this.startDate,
    this.items = const [],
    this.isArchived = false,
    this.templateId,
  });

  /// Identitas anggaran.
  final String id;

  /// Nama yang dipilih pemilik, misalnya `Belanja`. Data pengguna.
  final String name;

  /// Dompet sumber. **Wajib** — hanya pengeluaran dari dompet ini, dan
  /// transfer yang keluar dari dompet ini, yang terhitung ke posnya.
  final String walletId;

  /// Panjang periode.
  final BudgetPeriod period;

  /// Awal berlakunya periode. Hanya tanggalnya yang dipakai.
  final DateTime startDate;

  /// Pos-pos di dalamnya. Formulir mewajibkan minimal satu; entitas tetap
  /// menerima daftar kosong (rencana nol) supaya data lama tidak rusak.
  final List<BudgetItem> items;

  /// Nominal rencana dalam sen: `Σ item.plannedAmount`. Turunan, tidak
  /// pernah disimpan (ADR-017).
  int get plannedAmount => items.fold(0, (sum, item) => sum + item.plannedAmount);

  /// Satu-satunya bagian siklus hidup yang disimpan. Lihat [statusAt].
  final bool isArchived;

  /// Template berjadwal yang melahirkan atau menjadikan anggaran ini rutin
  /// (ADR-036 §3.1); `null` untuk anggaran biasa.
  final String? templateId;

  /// Batas akhir periode, eksklusif. Lihat [BudgetPeriod.endFrom].
  DateTime get endDate => period.endFrom(startDate);

  /// Apakah [date] berada di dalam periode: `startDate ≤ date < endDate`,
  /// hanya tanggal [startDate] yang dipakai. Transaksi hanya terhitung ke
  /// anggaran yang periodenya mencakup tanggalnya (keputusan KT-1).
  bool covers(DateTime date) =>
      !date.isBefore(DateTime(startDate.year, startDate.month, startDate.day)) && date.isBefore(endDate);

  /// Awal tiap bulan yang disentuh periode, urut naik — dokumen buku besar
  /// yang cukup dibaca untuk menghitung anggaran ini (ADR-012, KT-1).
  /// Termasuk paling banyak satu bulan tetangga sebelumnya: transaksi
  /// tertaut rutin sampai [periodAttributionDays] hari sebelum periode
  /// terhitung di sini (ADR-038 §3.5).
  List<DateTime> get months {
    final end = endDate;
    final last = DateTime(end.year, end.month, end.day - 1);
    final first = DateTime(startDate.year, startDate.month, startDate.day - periodAttributionDays);
    return [
      for (
        var month = DateTime(first.year, first.month);
        !month.isAfter(last);
        month = DateTime(month.year, month.month + 1)
      )
        month,
    ];
  }

  /// Status siklus hidup pada saat [now]. [BudgetStatus.finished] mulai
  /// berlaku tepat di [endDate].
  BudgetStatus statusAt(DateTime now) {
    if (isArchived) return BudgetStatus.archived;
    return now.isBefore(endDate) ? BudgetStatus.active : BudgetStatus.finished;
  }

  /// Fraksi periode ini yang sudah berlalu pada [now], 0.0–1.0 -- penanda
  /// laju waktu (ADR-020 §3.5/UX-10), dibandingkan dengan `progress` (fraksi
  /// rencana yang sudah terpakai) supaya pemilik tahu "apakah aku masih di
  /// jalur", bukan cuma "berapa yang sudah terpakai".
  ///
  /// Sebelum [startDate] menghasilkan 0; pada atau sesudah [endDate]
  /// menghasilkan 1. Periode sehari (`totalDays == 0`, mis. dibuat dan
  /// berakhir hari yang sama) dianggap sudah penuh berlalu.
  double elapsedRatio(DateTime now) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final totalDays = endDate.difference(start).inDays;
    if (totalDays <= 0) return 1;
    final elapsedDays = DateTime(now.year, now.month, now.day).difference(start).inDays;
    return (elapsedDays / totalDays).clamp(0.0, 1.0);
  }

  /// Salinan [Budget] dengan field yang disebutkan diganti.
  Budget copyWith({
    String? name,
    String? walletId,
    BudgetPeriod? period,
    DateTime? startDate,
    List<BudgetItem>? items,
    bool? isArchived,
    String? Function()? templateId,
  }) {
    return Budget(
      id: id,
      name: name ?? this.name,
      walletId: walletId ?? this.walletId,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      items: items ?? this.items,
      isArchived: isArchived ?? this.isArchived,
      templateId: templateId == null ? this.templateId : templateId(),
    );
  }

  @override
  List<Object?> get props => [id, name, walletId, period, startDate, items, isArchived, templateId];
}
