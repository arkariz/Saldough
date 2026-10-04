import 'dart:async';

/// Sinyal "buku besar berubah" (ADR-030 §3.4): transaksi atau saldo dompet
/// baru saja ditulis, jadi layar yang menampilkannya perlu memuat ulang.
///
/// Dipancarkan **sekali per unit kerja, sesudah semua dokumennya tertulis**
/// -- oleh `RecordTransaction`, `WalletBloc`, dan kelahiran anggaran rutin
/// (`RecurringBudgetHost`, ADR-036 §3.2), tidak pernah oleh repository. Transaksi ditulis lebih dulu dan saldo dompet menyusul
/// (ADR-012); memancar di antaranya membuat pelanggan memuat saldo lama.
///
/// Tiap kejadian membawa **sumbernya** (`null` kalau tidak disebut). Bloc
/// yang menulis sendiri sudah memuat ulang dirinya sesudah menulis, jadi ia
/// mengabaikan kejadian dari dirinya ([from]); kalau tidak, muatan ulang
/// kedua berjalan bersamaan dengan emisi pesan berhasil dan bisa
/// menimpanya.
///
/// Satu instans di kontainer akar, dijembatani ke scope yang membutuhkannya.
final class LedgerChanges {
  final _controller = StreamController<Object?>.broadcast();

  /// Satu kejadian per unit kerja yang berhasil, berisi sumbernya.
  Stream<Object?> get changes => _controller.stream;

  /// Kejadian yang BUKAN dipancarkan [self] -- yang dipakai bloc pelanggan.
  Stream<void> from(Object self) => changes.where((source) => !identical(source, self));

  /// Memberi tahu pelanggan bahwa buku besar berubah karena [source].
  void notifyChanged({Object? source}) => _controller.add(source);
}
