import 'package:dependencies/dependencies.dart';

/// Asal hak Plus (ADR-041 §3.2, §3.13).
enum PlanSource {
  /// Langganan Play yang dibeli, lewat RevenueCat.
  purchase,

  /// Hak promosi RevenueCat (hadiah penguji, akun peninjau).
  promotional,

  /// Pengganti paket di build non-rilis (§3.10).
  override,

  /// Masuk akun sebelum Plus dijual (§3.13 butir 1).
  prelaunch,
}

/// Keadaan paket pengguna saat ini (ADR-041 §3.2). Nilai, bukan entitas:
/// dihitung ulang dari sumbernya lewat `resolvePlan`.
sealed class PlanState extends Equatable {
  const PlanState();

  /// Fitur Plus terbuka.
  bool get isPlus;
}

/// Gratis: tidak ada hak aktif.
final class FreePlan extends PlanState {
  /// Membuat [FreePlan].
  const FreePlan();

  @override
  bool get isPlus => false;

  @override
  List<Object?> get props => const [];
}

/// Uji coba terbalik milik akun yang masuk, berlaku sampai [endsOn]
/// (hari terakhir, inklusif).
final class TrialPlan extends PlanState {
  /// Membuat [TrialPlan].
  const TrialPlan({required this.endsOn});

  /// Hari terakhir uji coba (tanggal setempat, tanpa jam).
  final DateTime endsOn;

  @override
  bool get isPlus => true;

  @override
  List<Object?> get props => [endsOn];
}

/// Plus aktif.
final class PlusPlan extends PlanState {
  /// Membuat [PlusPlan].
  const PlusPlan({required this.source, this.until, this.inGrace = false});

  /// Asal hak.
  final PlanSource source;

  /// Akhir periode berbayar; `null` = tanpa batas waktu (pra-peluncuran,
  /// pengganti uji, atau hak promosi tanpa tanggal berakhir).
  final DateTime? until;

  /// Play melaporkan masa tenggang pembayaran; tetap Plus.
  final bool inGrace;

  @override
  bool get isPlus => true;

  @override
  List<Object?> get props => [source, until, inGrace];
}

/// Langganan ditahan karena pembayaran gagal lewat masa tenggang Play:
/// perilaku Gratis, dengan ajakan memperbaiki pembayaran.
final class OnHoldPlan extends PlanState {
  /// Membuat [OnHoldPlan].
  const OnHoldPlan({required this.since});

  /// Sejak kapan ditahan.
  final DateTime since;

  @override
  bool get isPlus => false;

  @override
  List<Object?> get props => [since];
}
