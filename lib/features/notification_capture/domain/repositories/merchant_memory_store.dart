import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';

/// Penyimpanan ingatan pedagang (ADR-044 §3.1, E1/B-85): kunci
/// `paket|catatan ternormalisasi` → id kategori yang dikonfirmasi pengguna.
/// Urutan sisip dipertahankan (yang tertua dibuang lebih dulu).
abstract interface class MerchantMemoryStore {
  /// Seluruh ingatan.
  Future<Either<Failure, Map<String, String>>> load();

  /// Mengganti seluruh ingatan.
  Future<Either<Failure, Unit>> save(Map<String, String> memory);
}
