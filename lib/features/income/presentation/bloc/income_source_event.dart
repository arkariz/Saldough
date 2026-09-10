part of 'income_source_bloc.dart';

/// Event [IncomeSourceBloc].
sealed class IncomeSourceEvent {
  /// Membuat [IncomeSourceEvent].
  const IncomeSourceEvent();
}

/// Memuat daftar sumber pemasukan.
final class IncomeSourcesLoaded extends IncomeSourceEvent {
  /// Membuat [IncomeSourcesLoaded].
  const IncomeSourcesLoaded();
}

/// Menambah atau menyunting sebuah sumber.
final class IncomeSourceSaved extends IncomeSourceEvent {
  /// Membuat [IncomeSourceSaved].
  const IncomeSourceSaved(this.source);

  /// Sumber yang disimpan.
  final IncomeSource source;
}

/// Menghapus sumber ber-`id` [id].
final class IncomeSourceDeleted extends IncomeSourceEvent {
  /// Membuat [IncomeSourceDeleted].
  const IncomeSourceDeleted(this.id);

  /// Identitas sumber.
  final String id;
}
