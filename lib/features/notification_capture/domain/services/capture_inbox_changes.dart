import 'dart:async';

/// Sinyal "kotak masuk atau log tercatat otomatis berubah" (ADR-032 §3.6),
/// supaya kartu Beranda dan halaman kotak masuk memuat ulang. Satu instans di
/// akar, seperti `LedgerChanges`.
final class CaptureInboxChanges {
  final _controller = StreamController<void>.broadcast();

  /// Perubahan.
  Stream<void> get stream => _controller.stream;

  /// Memberi tahu pendengar.
  void notify() => _controller.add(null);
}
