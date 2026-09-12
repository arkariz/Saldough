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

/// Tombol "Catat Jam Kerja" ditekan — pindah ke layar `worklog`
/// (pencatatan freelance per jam, T-3.x, dipisah dari layar ini sejak
/// desain D-3.x).
final class WorklogEntryPointTapped extends IncomeSourceEvent {
  /// Membuat [WorklogEntryPointTapped].
  const WorklogEntryPointTapped({this.sourceId});

  /// Sumber freelance yang langsung dipilih di layar `worklog`, kalau
  /// ditekan dari tombol milik satu sumber tertentu (bukan ikon generik di
  /// app bar, yang selalu mengirim `null`).
  final String? sourceId;
}
