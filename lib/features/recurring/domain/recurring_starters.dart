import 'package:saldough/core/utils/clamped_date.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// Chip pembuka rutin (J1, T-15.3): kebutuhan rutin orang Indonesia, bukan
/// template gaji dua mingguan dan tagihan kartu ala pesaing AS.
enum RecurringStarter {
  /// Gaji, tanggal 25.
  salary(RecurringKind.income, categoryKey: 'salary', day: 25),

  /// Kos atau sewa, tanggal 1.
  rent(RecurringKind.expense, categoryKey: 'bills', day: 1, paymentMode: RecurringPaymentMode.manual),

  /// Listrik: nominal berubah tiap bulan.
  electricity(RecurringKind.expense, categoryKey: 'bills', amountMode: RecurringAmountMode.estimated),

  /// Internet.
  internet(RecurringKind.expense, categoryKey: 'internet'),

  /// BPJS, tanggal 10.
  bpjs(RecurringKind.expense, categoryKey: 'health', day: 10),

  /// Cicilan: langsung "Berakhir setelah 12 kali".
  installment(RecurringKind.expense, categoryKey: 'bills', endsAfter: 12),

  /// Paylater: langsung "Berakhir setelah 3 kali".
  paylater(RecurringKind.expense, categoryKey: 'bills', endsAfter: 3),

  /// Langganan (streaming, aplikasi).
  subscription(RecurringKind.expense, categoryKey: 'entertainment', paymentMode: RecurringPaymentMode.autoDebit),

  /// Kirim ke orang tua.
  parents(RecurringKind.expense, categoryKey: 'family'),

  /// Arisan.
  arisan(RecurringKind.expense, categoryKey: 'expenseOther'),

  /// Tabungan: transfer ke dompet tabungan.
  savings(RecurringKind.transfer);

  const RecurringStarter(
    this.kind, {
    this.categoryKey,
    this.day,
    this.endsAfter,
    this.amountMode = RecurringAmountMode.fixed,
    this.paymentMode,
  });

  /// Jenis transaksi.
  final RecurringKind kind;

  /// Kunci kategori bawaan (ADR-026), tanpa awalan `builtin.`.
  final String? categoryKey;

  /// Tanggal bawaan yang lazim, bila ada.
  final int? day;

  /// Berakhir setelah N kali, untuk cicilan.
  final int? endsAfter;

  /// Nominal tetap atau kira-kira.
  final RecurringAmountMode amountMode;

  /// Cara bayar bawaan, bila lazim.
  final RecurringPaymentMode? paymentMode;

  /// Id kategori bawaan.
  String? get categoryId => categoryKey == null ? null : 'builtin.$categoryKey';

  /// Pola Ulangi yang dibuka CATAT.
  RecurringPattern get pattern => RecurringPattern(
    end: endsAfter == null ? const RecurringNeverEnds() : RecurringEndsAfter(endsAfter!),
    amountMode: amountMode,
    paymentMode: paymentMode,
  );

  /// Tanggal bawaan: kemunculan [day] berikutnya yang belum lewat dari
  /// [today]; tanpa [day], hari ini. Tombol CATAT menyebut akibatnya
  /// ("Catat & Jadwalkan" atau "Simpan Jadwal"), dan tanggalnya tetap bisa
  /// diganti.
  DateTime dateFrom(DateTime today) {
    final start = DateTime(today.year, today.month, today.day);
    final anchorDay = day;
    if (anchorDay == null) return today;
    final thisMonth = clampedDate(today.year, today.month, anchorDay);
    return thisMonth.isBefore(start) ? clampedDate(today.year, today.month + 1, anchorDay) : thisMonth;
  }
}
