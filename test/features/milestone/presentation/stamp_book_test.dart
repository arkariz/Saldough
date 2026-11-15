import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';
import 'package:saldough/features/milestone/presentation/pages/stamp_book_page.dart';
import 'package:saldough/features/milestone/presentation/stamp_book_access.dart';
import 'package:saldough/features/milestone/presentation/widgets/stamp_account_entries.dart';

import '../../../helpers/reduced_motion.dart';

final class _Access implements MilestoneBookAccess {
  _Access(MilestoneLedger initial) : _ledger = ValueNotifier(initial);
  final ValueNotifier<MilestoneLedger> _ledger;
  int markedSeen = 0;

  @override
  ValueListenable<MilestoneLedger> get ledger => _ledger;

  @override
  Future<void> markAllSeen() async => markedSeen++;

  @override
  Future<void> setCelebrationEnabled({required bool enabled}) async =>
      _ledger.value = _ledger.value.copyWith(celebrationEnabled: enabled);
}

MilestoneLedger _ledger(List<String> ids, {bool seen = false}) => MilestoneLedger(
  earned: {for (final id in ids) id: EarnedMilestone(id: id, earnedAt: DateTime(2026, 10, 25), seen: seen)},
  seeded: true,
  introShown: true,
);

Widget _host(Widget child) => MaterialApp(theme: DsTheme.light, builder: reducedMotion, home: child);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.id));
  _kayaMain();

  testWidgets('kosong: Tanuki tidur dan ajakan lembut, tanpa daftar', (tester) async {
    await tester.pumpWidget(_host(StampBookPage(access: _Access(MilestoneLedger.empty))));
    expect(find.text(t.stamps.empty.title), findsOneWidget);
    expect(find.text(t.stamps.names.wallet_first), findsNothing);
  });

  testWidgets('sebagian: yang diraih bertanggal, yang belum menampilkan cara mendapatkannya; tanpa hitungan', (tester) async {
    await tester.pumpWidget(_host(StampBookPage(access: _Access(_ledger(['wallet_first', 'record_first'])))));
    expect(find.text('Diraih 25 Okt'), findsNWidgets(2));
    await tester.scrollUntilVisible(find.text(t.stamps.how.backup_first), 200);
    expect(find.text(t.stamps.how.backup_first), findsOneWidget);
    expect(find.textContaining(' dari '), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.lock), findsNothing);
  });

  testWidgets('tonggak tersembunyi hanya tampil bila diraih (KT-G3)', (tester) async {
    await tester.pumpWidget(_host(StampBookPage(access: _Access(_ledger(['wallet_first'])))));
    expect(find.text(t.stamps.names.inbox_clear), findsNothing);
    expect(find.text(t.stamps.names.freelance_paid), findsNothing);
    await tester.pumpWidget(_host(StampBookPage(access: _Access(_ledger(['wallet_first', 'inbox_clear'])))));
    expect(find.text(t.stamps.names.inbox_clear), findsOneWidget);
  });

  testWidgets('semua diraih: kalimat penutup; ketuk membuka detail; menutup layar menandai dilihat', (tester) async {
    final all = _ledger([
      'wallet_first',
      'record_first',
      'period_tidy',
      'recurring_clear',
      'inbox_clear',
      'backup_first',
      'budget_first',
      'freelance_paid',
    ]);
    final access = _Access(all);
    await tester.pumpWidget(_host(StampBookPage(access: access)));
    await tester.scrollUntilVisible(find.text(t.stamps.allDone), 300);
    expect(find.text(t.stamps.allDone), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.stamps.names.wallet_first));
    await tester.pumpAndSettle();
    expect(find.text(t.stamps.detail.close), findsOneWidget);
    await tester.tap(find.text(t.stamps.detail.close));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
    expect(access.markedSeen, 1);
  });

  testWidgets('Akun: sakelar mati menyembunyikan baris Buku Stempel dan mengganti keterangan (G-8)', (tester) async {
    final access = _Access(_ledger(['wallet_first'], seen: true));
    await tester.pumpWidget(
      _host(Scaffold(body: ListView(children: stampAccountEntries(access)))),
    );
    expect(find.text(t.stamps.account.entryTitle), findsOneWidget);
    expect(find.text(t.stamps.account.switchHintOn), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text(t.stamps.account.entryTitle), findsNothing);
    expect(find.text(t.stamps.account.switchHintOff), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text(t.stamps.account.entryTitle), findsOneWidget);
  });
}

void _kayaMain() {
  testWidgets('Kaya: balon Tanuki berbicara dan berkomentar saat stempel diketuk', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.id);
    await tester.pumpWidget(_host(StampBookPage(access: _Access(_ledger(['wallet_first'])))));
    expect(find.text(t.stamps.kaya.idle), findsOneWidget);
    await tester.tap(find.text(t.stamps.names.wallet_first));
    await tester.pumpAndSettle();
    expect(find.text(t.stamps.kaya.tapEarned(name: t.stamps.names.wallet_first)), findsOneWidget);
    expect(find.text(t.stamps.detail.close), findsOneWidget);
    expect(find.textContaining('Cap lagi'), findsNothing, reason: 'tanpa "Cap lagi" (G-3)');
  });

  testWidgets('Kaya: stempel belum diraih dikomentari tanpa menekan', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.id);
    await tester.pumpWidget(_host(StampBookPage(access: _Access(_ledger(['wallet_first'])))));
    await tester.scrollUntilVisible(find.text(t.stamps.names.backup_first), 200);
    await tester.tap(find.text(t.stamps.names.backup_first));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.stamps.detail.close));
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, 2000));
    await tester.pumpAndSettle();
    expect(find.text(t.stamps.kaya.tapLocked(name: t.stamps.names.backup_first)), findsOneWidget);
  });

  testWidgets('Kaya gerak penuh: daun, kilap, napas, miring 3D, konfeti tanpa galat; bersih saat ditutup', (tester) async {
    LocaleSettings.setLocaleSync(AppLocale.id);
    await tester.pumpWidget(
      MaterialApp(theme: DsTheme.light, home: StampBookPage(access: _Access(_ledger(['wallet_first', 'record_first'])))),
    );
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 400));
    }
    await tester.tap(find.text(t.stamps.names.wallet_first));
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
    // Geser di atas segel besar: miring 3D lalu kembali.
    final gesture = await tester.startGesture(tester.getCenter(find.text(t.stamps.detail.close)) - const Offset(0, 200));
    await gesture.moveBy(const Offset(30, 10));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text(t.stamps.detail.close));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
