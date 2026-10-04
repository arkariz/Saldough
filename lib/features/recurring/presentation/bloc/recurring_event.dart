part of 'recurring_bloc.dart';

/// Event [RecurringBloc].
sealed class RecurringEvent {
  /// Membuat [RecurringEvent].
  const RecurringEvent();
}

/// Memuat pertama kali, dengan kerangka.
final class RecurringStarted extends RecurringEvent {
  /// Membuat [RecurringStarted].
  const RecurringStarted();
}

/// Memuat ulang tanpa kerangka (sinyal buku besar atau rutin).
final class RecurringRefreshed extends RecurringEvent {
  /// Membuat [RecurringRefreshed].
  const RecurringRefreshed();
}

/// Chip jenis dipilih; `null` = semua.
final class RecurringKindFilterChanged extends RecurringEvent {
  /// Membuat [RecurringKindFilterChanged].
  const RecurringKindFilterChanged(this.kind);

  /// Jenis terpilih.
  final RecurringKind? kind;
}

/// Lewati satu kemunculan.
final class RecurringOccurrenceSkipped extends RecurringEvent {
  /// Membuat [RecurringOccurrenceSkipped].
  const RecurringOccurrenceSkipped({required this.ruleId, required this.date});

  /// Rutinnya.
  final String ruleId;

  /// Tanggal kemunculan.
  final DateTime date;
}

/// Batalkan lewati satu kemunculan.
final class RecurringOccurrenceUnskipped extends RecurringEvent {
  /// Membuat [RecurringOccurrenceUnskipped].
  const RecurringOccurrenceUnskipped({required this.ruleId, required this.date});

  /// Rutinnya.
  final String ruleId;

  /// Tanggal kemunculan.
  final DateTime date;
}

/// Jeda atau lanjutkan rutin.
final class RecurringPauseToggled extends RecurringEvent {
  /// Membuat [RecurringPauseToggled].
  const RecurringPauseToggled(this.ruleId);

  /// Rutinnya.
  final String ruleId;
}

/// Akhiri rutin hari ini.
final class RecurringEnded extends RecurringEvent {
  /// Membuat [RecurringEnded].
  const RecurringEnded(this.ruleId);

  /// Rutinnya.
  final String ruleId;
}

/// Perbarui nominal rutin (W3).
final class RecurringAmountUpdated extends RecurringEvent {
  /// Membuat [RecurringAmountUpdated].
  const RecurringAmountUpdated({required this.ruleId, required this.amount});

  /// Rutinnya.
  final String ruleId;

  /// Nominal baru, sen.
  final int amount;
}

/// Hapus rutin. Transaksi yang sudah tercatat tidak ikut terhapus.
final class RecurringDeleted extends RecurringEvent {
  /// Membuat [RecurringDeleted].
  const RecurringDeleted(this.ruleId);

  /// Rutinnya.
  final String ruleId;
}

/// Catat satu ketuk kemunculan menunggu (rutin bernominal tetap).
final class RecurringOccurrenceRecorded extends RecurringEvent {
  /// Membuat [RecurringOccurrenceRecorded].
  const RecurringOccurrenceRecorded({required this.ruleId, required this.date, this.force = false});

  /// Rutinnya.
  final String ruleId;

  /// Tanggal kemunculan.
  final DateTime date;

  /// Catat walau ada transaksi mirip (pengguna sudah memilih "Catat baru").
  final bool force;
}

/// Catat semua kemunculan menunggu yang bisa dicatat satu ketuk.
final class RecurringPendingRecordedAll extends RecurringEvent {
  /// Membuat [RecurringPendingRecordedAll].
  const RecurringPendingRecordedAll();
}

/// Tautkan transaksi yang sudah ada ke kemunculan.
final class RecurringOccurrenceLinked extends RecurringEvent {
  /// Membuat [RecurringOccurrenceLinked].
  const RecurringOccurrenceLinked({required this.ruleId, required this.date, required this.transactionId});

  /// Rutinnya.
  final String ruleId;

  /// Tanggal kemunculan.
  final DateTime date;

  /// Transaksi yang ditautkan.
  final String transactionId;
}

/// Tautkan rutin ke pos anggaran rutin [key], atau lepas (`null`)
/// (ADR-036 §3.4).
final class RecurringBudgetLinkChanged extends RecurringEvent {
  /// Membuat [RecurringBudgetLinkChanged].
  const RecurringBudgetLinkChanged({required this.ruleId, required this.key});

  /// Rutinnya.
  final String ruleId;

  /// Kunci pos template, atau `null` untuk melepas.
  final String? key;
}

/// "Belum terjadi" pada autodebet yang belum terlihat (E3, ADR-037 §3.1):
/// label ditunda [unseenAfterDays] hari dari hari ini.
final class RecurringOccurrenceSnoozed extends RecurringEvent {
  /// Membuat [RecurringOccurrenceSnoozed].
  const RecurringOccurrenceSnoozed({required this.ruleId});

  /// Rutinnya.
  final String ruleId;
}

/// "Biarkan" pada kartu rutin menganggur (W6, ADR-037 §3.1).
final class RecurringIdleDismissed extends RecurringEvent {
  /// Membuat [RecurringIdleDismissed].
  const RecurringIdleDismissed(this.ruleId);

  /// Rutinnya.
  final String ruleId;
}

/// Nyalakan atau matikan catat otomatis satu rutin bernominal tetap
/// (ADR-037 §3.2).
final class RecurringAutoRecordToggled extends RecurringEvent {
  /// Membuat [RecurringAutoRecordToggled].
  const RecurringAutoRecordToggled({required this.ruleId, required this.enabled});

  /// Rutinnya.
  final String ruleId;

  /// Nyala atau mati.
  final bool enabled;
}

/// "Bukan rutin" pada saran Sepertinya rutin (ADR-037 §3.3).
final class RecurringSuggestionDismissed extends RecurringEvent {
  /// Membuat [RecurringSuggestionDismissed].
  const RecurringSuggestionDismissed(this.key);

  /// Kunci saran.
  final String key;
}

/// Nyalakan atau matikan pengingat satu rutin.
final class RecurringRemindersToggled extends RecurringEvent {
  /// Membuat [RecurringRemindersToggled].
  const RecurringRemindersToggled({required this.ruleId, required this.enabled});

  /// Rutinnya.
  final String ruleId;

  /// Nyala atau mati.
  final bool enabled;
}
