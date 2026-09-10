import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/worklog/domain/entities/work_log_entry.dart';

/// Satu periode tagihan freelance — kumpulan entri dari satu penanda
/// `startsNewBook` sampai penanda berikutnya. Lihat DOMAIN_MODEL.md bagian
/// "Catatan jam dan buku jam".
final class BillingBook extends Equatable {
  /// Membuat [BillingBook].
  const BillingBook({
    required this.id,
    required this.sourceId,
    required this.startDate,
    required this.entries,
    this.endDate,
    this.netPayAmount,
    this.injectedCycleId,
    this.injectedIncomeLineId,
  });

  /// Buku baru kosong untuk sumber ber-`id` [sourceId], dimulai dari [entry].
  factory BillingBook.startWith({required String id, required String sourceId, required WorkLogEntry entry}) {
    return BillingBook(id: id, sourceId: sourceId, startDate: entry.date, entries: [entry]);
  }

  /// Identitas buku.
  final String id;

  /// Rujukan ke `IncomeSource` bertipe freelance.
  final String sourceId;

  /// Tanggal entri pertama.
  final DateTime startDate;

  /// Tanggal entri terakhir. Null selama buku masih terbuka.
  final DateTime? endDate;

  /// Entri dalam periode ini.
  final List<WorkLogEntry> entries;

  /// Gaji bersih hasil `CalculateNetPay` saat buku ditutup, dalam sen. Null
  /// selama buku masih terbuka.
  final int? netPayAmount;

  /// Siklus tujuan penyuntikan (T-3.9). Null kalau belum disuntikkan.
  final String? injectedCycleId;

  /// Baris pemasukan tujuan di siklus itu. Null kalau belum disuntikkan.
  final String? injectedIncomeLineId;

  /// True kalau buku sudah ditutup ([endDate] terisi).
  bool get isClosed => endDate != null;

  /// True kalau gaji bersihnya sudah disuntikkan ke sebuah siklus.
  bool get isInjected => injectedCycleId != null;

  /// Jumlah jam pada seluruh [entries].
  int get totalHours => entries.fold(0, (sum, e) => sum + e.hours);

  /// Salinan [BillingBook] dengan [entry] ditambahkan di akhir — hanya sah
  /// untuk buku yang masih terbuka (dijaga oleh `WorklogRepository`, bukan
  /// entitas ini).
  BillingBook withEntry(WorkLogEntry entry) => copyWith(entries: [...entries, entry]);

  /// Salinan [BillingBook] yang ditutup dengan gaji bersih [netPayAmount].
  BillingBook close({required int netPayAmount}) {
    return BillingBook(
      id: id,
      sourceId: sourceId,
      startDate: startDate,
      entries: entries,
      endDate: entries.last.date,
      netPayAmount: netPayAmount,
    );
  }

  /// Salinan [BillingBook] yang ditandai sudah disuntikkan ke
  /// [incomeLineId] pada siklus [cycleId].
  BillingBook markInjected({required String cycleId, required String incomeLineId}) {
    return BillingBook(
      id: id,
      sourceId: sourceId,
      startDate: startDate,
      entries: entries,
      endDate: endDate,
      netPayAmount: netPayAmount,
      injectedCycleId: cycleId,
      injectedIncomeLineId: incomeLineId,
    );
  }

  /// Salinan [BillingBook] dengan field yang disebutkan diganti.
  BillingBook copyWith({List<WorkLogEntry>? entries}) {
    return BillingBook(
      id: id,
      sourceId: sourceId,
      startDate: startDate,
      entries: entries ?? this.entries,
      endDate: endDate,
      netPayAmount: netPayAmount,
      injectedCycleId: injectedCycleId,
      injectedIncomeLineId: injectedIncomeLineId,
    );
  }

  @override
  List<Object?> get props =>
      [id, sourceId, startDate, endDate, entries, netPayAmount, injectedCycleId, injectedIncomeLineId];
}
