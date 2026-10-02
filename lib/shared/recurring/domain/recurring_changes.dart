import 'dart:async';

/// Sinyal "rutin berubah": sebuah `RecurringRule` baru saja dibuat,
/// disunting, dilewati, atau dihapus, jadi layar yang menampilkan rutin dan
/// kemunculannya perlu memuat ulang. Polanya sama dengan `LedgerChanges`
/// (ADR-030 §3.4): dipancarkan penulis sesudah dokumennya tertulis, tidak
/// pernah oleh repository, dan membawa sumbernya.
///
/// Satu instans di kontainer akar, dijembatani ke scope yang membutuhkannya.
final class RecurringChanges {
  final _controller = StreamController<Object?>.broadcast();

  /// Satu kejadian per unit kerja yang berhasil, berisi sumbernya.
  Stream<Object?> get changes => _controller.stream;

  /// Kejadian yang BUKAN dipancarkan [self].
  Stream<void> from(Object self) => changes.where((source) => !identical(source, self));

  /// Memberi tahu pelanggan bahwa rutin berubah karena [source].
  void notifyChanged({Object? source}) => _controller.add(source);
}
