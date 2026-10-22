import 'dart:async';

import 'package:saldough/core/discovery/feature_status.dart';

/// Sumber tunggal "apakah fitur ini efektif" (FEATURE_DISCOVERY P-2) yang
/// dibaca Beranda, Rutin, dan Akun tanpa saling mengimpor fitur (ADR-030).
/// Implementasinya di akar komposisi, yang membaca setelan dan izin tiap
/// fitur.
abstract interface class FeatureStatuses {
  /// Membaca keadaan [feature] sekarang, termasuk izin sistem yang bisa
  /// dicabut di luar aplikasi. Tidak pernah melempar.
  Future<FeatureStatus> read(DiscoveredFeature feature);

  /// Setelan sebuah fitur berubah; pembaca membaca ulang lewat [read].
  Stream<void> get changes;
}

/// Pemancar sinyal [FeatureStatuses.changes]. Satu instans di akar, seperti
/// `LedgerChanges`; penulis setelan memanggil [notify] sesudah menyimpan.
final class FeatureStatusChanges {
  final _controller = StreamController<void>.broadcast();

  /// Perubahan.
  Stream<void> get stream => _controller.stream;

  /// Memberi tahu pendengar.
  void notify() => _controller.add(null);
}
