import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/recurring/domain/recurring_rule.dart';

/// Pilihan **Ulangi** di CATAT (ADR-035 §3.3, T-15.3): bagian rutin yang
/// bukan isi transaksi. Digabung dengan isian formulir dan tanggalnya
/// (patokan) menjadi [RecurringRule] lewat [toRule].
final class RecurringPattern extends Equatable {
  /// Membuat [RecurringPattern]. Bawaannya tiap bulan, tanpa akhir, nominal
  /// tetap.
  const RecurringPattern({
    this.frequency = RecurringFrequency.monthly,
    this.interval = 1,
    this.end = const RecurringNeverEnds(),
    this.amountMode = RecurringAmountMode.fixed,
    this.paymentMode,
  }) : assert(interval >= 1, 'Selang jadwal minimal 1.');

  /// Pola [rule], untuk membuka CATAT saat mengubah rutin.
  factory RecurringPattern.of(RecurringRule rule) => RecurringPattern(
    frequency: rule.schedule.frequency,
    interval: rule.schedule.interval,
    end: rule.end,
    amountMode: rule.amountMode,
    paymentMode: rule.paymentMode,
  );

  /// Satuan selang.
  final RecurringFrequency frequency;

  /// Kelipatan satuan.
  final int interval;

  /// Kapan rutin berakhir.
  final RecurringEnd end;

  /// Pasti atau perkiraan.
  final RecurringAmountMode amountMode;

  /// Cara bayar; diabaikan untuk pemasukan.
  final RecurringPaymentMode? paymentMode;

  /// Rutin dari pola ini dengan isian transaksi dan [anchorDate] sebagai
  /// kemunculan pertama.
  RecurringRule toRule({
    required String id,
    required RecurringKind kind,
    required int amount,
    required String walletId,
    required String note,
    required DateTime anchorDate,
    String? toWalletId,
    String? categoryId,
  }) {
    return RecurringRule(
      id: id,
      kind: kind,
      amount: amount,
      amountMode: amountMode,
      walletId: walletId,
      toWalletId: kind == RecurringKind.transfer ? toWalletId : null,
      categoryId: kind == RecurringKind.transfer ? null : categoryId,
      note: note,
      schedule: RecurringSchedule(frequency: frequency, interval: interval, anchorDate: anchorDate),
      end: end,
      paymentMode: kind == RecurringKind.income ? null : paymentMode,
    );
  }

  /// Salinan dengan field yang disebutkan diganti. [paymentMode] tidak bisa
  /// dikosongkan lewat sini.
  RecurringPattern copyWith({
    RecurringFrequency? frequency,
    int? interval,
    RecurringEnd? end,
    RecurringAmountMode? amountMode,
    RecurringPaymentMode? paymentMode,
  }) {
    return RecurringPattern(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      end: end ?? this.end,
      amountMode: amountMode ?? this.amountMode,
      paymentMode: paymentMode ?? this.paymentMode,
    );
  }

  @override
  List<Object?> get props => [frequency, interval, end, amountMode, paymentMode];
}
