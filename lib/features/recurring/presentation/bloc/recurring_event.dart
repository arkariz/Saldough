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
