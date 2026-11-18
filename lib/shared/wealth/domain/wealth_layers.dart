import 'package:dependencies/dependencies.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Total aset per lapisan keuangan (ADR-050 §3.1). Setiap dompet masuk tepat
/// satu lapis, jadi tidak ada hitung ganda. Semua nilai dalam sen.
final class WealthLayers extends Equatable {
  /// Membuat [WealthLayers].
  const WealthLayers({
    required this.operational,
    required this.savings,
    this.investment = 0,
    this.operationalCount = 0,
    this.savingsCount = 0,
  });

  /// Lapisan dari [wallets]: dompet aktif milik tujuan ([goalWalletIds]) masuk
  /// Tabungan, dompet aktif lainnya Dana operasional; dompet nonaktif tidak
  /// dihitung. [investment] = nilai pasar instrumen (Fase 31).
  factory WealthLayers.of(Iterable<Wallet> wallets, {Set<String> goalWalletIds = const {}, int investment = 0}) {
    var operational = 0;
    var savings = 0;
    var operationalCount = 0;
    var savingsCount = 0;
    for (final wallet in wallets) {
      if (!wallet.isActive) continue;
      if (goalWalletIds.contains(wallet.id)) {
        savings += wallet.currentBalance;
        savingsCount++;
      } else {
        operational += wallet.currentBalance;
        operationalCount++;
      }
    }
    return WealthLayers(
      operational: operational,
      savings: savings,
      investment: investment,
      operationalCount: operationalCount,
      savingsCount: savingsCount,
    );
  }

  /// Dana operasional: dompet harian. Boleh negatif (mis. kartu).
  final int operational;

  /// Tabungan: dompet milik tujuan.
  final int savings;

  /// Investasi: nilai pasar instrumen.
  final int investment;

  /// Jumlah dompet operasional aktif.
  final int operationalCount;

  /// Jumlah dompet tabungan (tujuan) aktif.
  final int savingsCount;

  /// Total aset: jumlah ketiga lapis.
  int get total => operational + savings + investment;

  /// Apakah lapis Tabungan perlu ditampilkan (sudah ada tujuan).
  bool get hasSavings => savingsCount > 0;

  /// Bagian positif tiap lapis untuk batang proporsi (lapis negatif = 0).
  List<int> get positiveParts => [operational, savings, investment].map((v) => v < 0 ? 0 : v).toList();

  @override
  List<Object?> get props => [operational, savings, investment, operationalCount, savingsCount];
}
