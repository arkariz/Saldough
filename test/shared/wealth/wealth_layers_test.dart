import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wealth/wealth.dart';

/// ADR-050 §3.1: setiap dompet tepat satu lapis, nonaktif tidak dihitung.
void main() {
  Wallet wallet(String id, int balance, {bool active = true}) =>
      Wallet(id: id, name: id, iconKey: 'walletBank', initialBalance: 0, currentBalance: balance, isActive: active);

  test('dompet tujuan masuk Tabungan, sisanya Dana operasional; nonaktif tidak dihitung; total tanpa hitung ganda', () {
    final layers = WealthLayers.of(
      [wallet('bca', 500), wallet('kartu', -200), wallet('lama', 999, active: false), wallet('goal-g', 300)],
      goalWalletIds: const {'goal-g'},
    );
    expect((layers.operational, layers.savings, layers.investment, layers.total), (300, 300, 0, 600));
    expect((layers.operationalCount, layers.savingsCount, layers.hasSavings), (2, 1, true));
  });

  test('investasi ikut total; batang proporsi hanya bagian positif', () {
    final layers = WealthLayers.of([wallet('kartu', -100)], investment: 400);
    expect(layers.total, 300);
    expect(layers.positiveParts, [0, 0, 400]);
    expect(layers.hasSavings, isFalse);
  });
}
