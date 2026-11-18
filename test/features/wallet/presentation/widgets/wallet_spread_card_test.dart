import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/wallet/presentation/wallet_shares.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_spread_card.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Kartu sebaran membatasi butir: lebih dari [spreadMaxItems] digabung menjadi
/// "Lainnya (n)" (umpan balik pemilik 17 Nov 2026).
void main() {
  List<Wallet> wallets(int n) => [
    for (var i = 0; i < n; i++)
      Wallet(
        id: 'w$i',
        name: 'Dompet $i',
        iconKey: 'walletBank',
        initialBalance: 0,
        currentBalance: (i + 1) * 1000,
      ),
  ];

  Future<void> pump(WidgetTester tester, List<Wallet> list) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PixelTheme.light,
        home: Scaffold(
          body: WalletSpreadCard(
            wallets: list,
            shares: walletShares(list),
            colors: {for (final w in list) w.id: Colors.blue},
            total: list.fold(0, (sum, w) => sum + w.currentBalance),
            activeCount: list.length,
            onSelected: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('tujuh dompet: empat terbesar tampil, tiga terkecil digabung jadi Lainnya (3)', (tester) async {
    await pump(tester, wallets(7));
    expect(find.textContaining(t.wallet.spreadOthers(n: 3)), findsOneWidget);
    for (final name in ['Dompet 6', 'Dompet 5', 'Dompet 4', 'Dompet 3']) {
      expect(find.textContaining(name), findsOneWidget);
    }
    for (final name in ['Dompet 0', 'Dompet 1', 'Dompet 2']) {
      expect(find.textContaining(name), findsNothing);
    }
    expect(find.text('7'), findsOneWidget, reason: 'lencana kepala tetap menyebut semua butir');
  });

  testWidgets('lima dompet atau kurang: semua tampil tanpa Lainnya', (tester) async {
    await pump(tester, wallets(5));
    expect(find.textContaining(t.wallet.spreadOthers(n: 1).split(' ').first), findsNothing);
    expect(find.textContaining('Dompet 0'), findsOneWidget);
  });
}
