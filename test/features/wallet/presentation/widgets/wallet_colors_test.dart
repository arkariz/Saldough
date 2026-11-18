import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Warna kartu pilihan pemilik (T-30.15) menimpa warna otomatis tanpa
/// menggeser warna dompet lain.
void main() {
  final scheme = DsThemePresets.all.first.light;
  Wallet wallet(String id, {String? colorKey}) =>
      Wallet(id: id, name: id, iconKey: 'walletBank', initialBalance: 0, currentBalance: 0, colorKey: colorKey);

  test('memberi warna satu dompet tidak menggeser warna dompet lain', () {
    final before = walletColorsDs(scheme, [wallet('a'), wallet('b'), wallet('c')]);
    final after = walletColorsDs(scheme, [wallet('a', colorKey: 'teal'), wallet('b'), wallet('c')]);

    expect(after['a'], scheme.categories.teal.color);
    expect(after['b'], before['b']);
    expect(after['c'], before['c']);
  });
}
