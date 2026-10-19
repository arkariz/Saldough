import 'package:dependencies/dependencies.dart';

/// Fitur yang pintunya dibuka permanen oleh Fase 21 (FEATURE_DISCOVERY §5).
enum DiscoveredFeature {
  /// Catat dari notifikasi (ADR-032), Android saja.
  notification,

  /// Pengingat transaksi rutin (ADR-035 §3.8).
  reminder,
}

/// Keadaan sebuah fitur terhadap pengguna (FEATURE_DISCOVERY P-1, P-2, P-7).
enum FeatureState {
  /// Platform tidak mendukung; tidak ada pintu yang ditampilkan.
  unsupported,

  /// Belum disetel: belum ada aplikasi sumber (hanya Catat dari notifikasi).
  unset,

  /// Sakelar mati.
  off,

  /// Sakelar nyala, tetapi izin sistem belum ada atau dicabut.
  permissionNeeded,

  /// Sakelar nyala dan izin ada.
  active,
}

/// Keadaan fitur beserta jumlah sumber aktifnya.
final class FeatureStatus extends Equatable {
  /// Membuat [FeatureStatus].
  const FeatureStatus(this.state, {this.activeCount = 0});

  /// Platform tidak mendukung fitur.
  static const unsupported = FeatureStatus(FeatureState.unsupported);

  /// Keadaan fitur.
  final FeatureState state;

  /// Jumlah aplikasi sumber aktif (Catat dari notifikasi); 0 untuk fitur lain.
  final int activeCount;

  /// Fitur benar-benar bekerja: sakelar nyala dan izin ada. Pintu permanen
  /// tampil selama ini `false` dan platformnya mendukung.
  bool get isEffective => state == FeatureState.active;

  /// Platform mendukung fitur ini.
  bool get isSupported => state != FeatureState.unsupported;

  @override
  List<Object?> get props => [state, activeCount];
}
