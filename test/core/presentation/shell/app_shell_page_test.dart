import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/shell/app_shell_page.dart';

void main() {
  group('AppShellPage', () {
    testWidgets('menampilkan lima tujuan navigasi dengan CATAT di tengah', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppShellPage()));

      expect(find.byType(NavigationDestination), findsNWidgets(5));
      final labels = tester.widgetList<NavigationDestination>(find.byType(NavigationDestination)).map((d) => d.label);
      expect(
        labels,
        [
          t.appShell.homeTabLabel,
          t.appShell.budgetTabLabel,
          t.appShell.recordAction,
          t.appShell.transactionsTabLabel,
          t.appShell.walletsTabLabel,
        ],
      );
    });

    testWidgets('Beranda tampil sebagai tab awal', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppShellPage()));

      expect(find.widgetWithText(AppBar, t.appShell.homeTabLabel), findsOneWidget);
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(nav.selectedIndex, 0);
    });

    testWidgets('menekan tujuan Dompet berpindah ke tab Dompet, melompati CATAT', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppShellPage()));

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.walletsTabLabel));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, t.appShell.walletsTabLabel), findsOneWidget);
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(nav.selectedIndex, 4);
    });

    testWidgets('menekan tujuan Transaksi berpindah ke tab Transaksi', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppShellPage()));

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.transactionsTabLabel));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, t.appShell.transactionsTabLabel), findsOneWidget);
    });

    testWidgets('menekan CATAT membuka lembar, TIDAK mengganti tab aktif', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppShellPage()));

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.recordAction));
      await tester.pumpAndSettle();

      // Lembar CATAT terbuka...
      expect(find.text(t.appShell.recordAction), findsWidgets);
      expect(find.text(t.appShell.comingSoonMessage), findsWidgets);

      // ...dan tab yang aktif di baliknya tetap Beranda (tab awal), bukan
      // CATAT -- CATAT tidak pernah jadi tab "terpilih" yang persisten.
      final nav = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(nav.selectedIndex, 0);
    });

    testWidgets('menutup lembar CATAT kembali ke tab yang sebelumnya aktif', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppShellPage()));

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.budgetTabLabel));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(NavigationDestination, t.appShell.recordAction));
      await tester.pumpAndSettle();

      // Tutup lembar dengan tap di luar (barrier).
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, t.appShell.budgetTabLabel), findsOneWidget);
    });
  });
}
