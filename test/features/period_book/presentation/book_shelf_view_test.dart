import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/period_book/domain/entities/closed_period.dart';
import 'package:saldough/features/period_book/domain/services/period_book_shelf.dart';
import 'package:saldough/features/period_book/presentation/period_book_settings_access.dart';
import 'package:saldough/features/period_book/presentation/period_book_shelf_access.dart';
import 'package:saldough/features/period_book/presentation/widgets/book_shelf_view.dart';
import 'package:saldough/features/period_book/presentation/widgets/invite_switch_entry.dart';

import '../../../helpers/reduced_motion.dart';

final class _Shelf implements PeriodBookShelfAccess {
  _Shelf(this.entries);
  List<ShelfEntry> entries;
  int loads = 0;

  @override
  Future<List<ShelfEntry>> shelf() async {
    loads++;
    return entries;
  }
}

ShelfEntry _entry(int month, ShelfStatus status, {FinancialMonthSchedule? schedule}) => ShelfEntry(
  period: ClosedPeriod(
    period: financialPeriodOf(DateTime(2026, month, 15), schedule ?? FinancialMonthSchedule.initial),
    transactionCount: 5,
  ),
  status: status,
);

Widget _host(Widget child) => MaterialApp(
  theme: DsTheme.light,
  builder: reducedMotion,
  home: Scaffold(body: child),
);

void main() {
  setUp(() => LocaleSettings.setLocaleSync(AppLocale.id));

  testWidgets('kosong: ajakan lembut tanpa tombol', (tester) async {
    await tester.pumpWidget(_host(BookShelfView(access: _Shelf([]), onOpenBook: (_) async {})));
    await tester.pumpAndSettle();
    expect(find.text(t.book.shelf.empty), findsOneWidget);
    expect(find.text(t.book.shelf.emptyHint), findsOneWidget);
    expect(find.byType(DsButton), findsNothing);
  });

  testWidgets('tiga keadaan: Baru, sudah dibuka, terkunci; tanpa hitungan "n buku menunggu"', (tester) async {
    final shelf = _Shelf([_entry(10, ShelfStatus.unopened), _entry(9, ShelfStatus.opened), _entry(8, ShelfStatus.locked)]);
    await tester.pumpWidget(_host(BookShelfView(access: shelf, onOpenBook: (_) async {})));
    await tester.pumpAndSettle();
    expect(find.text(t.book.shelf.fresh.toUpperCase()), findsOneWidget, reason: 'pita hanya di yang belum dibuka');
    expect(find.text(t.book.shelf.unopened), findsOneWidget);
    expect(find.text(t.book.shelf.opened), findsOneWidget);
    expect(find.text(t.book.shelf.locked), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget, reason: 'gembok hanya di yang terkunci');
    expect(find.textContaining('menunggu'), findsNothing);
  });

  testWidgets('ketuk buku yang boleh dibuka memanggil rute lalu memuat ulang rak', (tester) async {
    final shelf = _Shelf([_entry(10, ShelfStatus.unopened)]);
    final opened = <String>[];
    await tester.pumpWidget(_host(BookShelfView(access: shelf, onOpenBook: (id) async => opened.add(id))));
    await tester.pumpAndSettle();
    final loadsBefore = shelf.loads;
    await tester.tap(find.text('Oktober').last);
    await tester.pumpAndSettle();
    expect(opened, ['2026-10-01']);
    expect(shelf.loads, loadsBefore + 1);
  });

  testWidgets('ketuk buku terkunci: pesan lembut, bukan paywall, dan rute tidak dibuka', (tester) async {
    final shelf = _Shelf([_entry(8, ShelfStatus.locked)]);
    final opened = <String>[];
    await tester.pumpWidget(_host(BookShelfView(access: shelf, onOpenBook: (id) async => opened.add(id))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agustus').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(t.book.shelf.lockedToast), findsOneWidget);
    expect(opened, isEmpty);
  });

  testWidgets('periode peralihan: baris status berawalan "Periode peralihan"', (tester) async {
    final entry = ShelfEntry(
      period: ClosedPeriod(
        period: FinancialPeriod(start: DateTime(2026, 10, 10), end: DateTime(2026, 11, 25), isTransition: true),
        transactionCount: 4,
      ),
      status: ShelfStatus.unopened,
    );
    expect(entry.period.period.isTransition, isTrue);
    await tester.pumpWidget(_host(BookShelfView(access: _Shelf([entry]), onOpenBook: (_) async {})));
    await tester.pumpAndSettle();
    expect(find.textContaining('Periode peralihan'), findsOneWidget);
  });

  group('sakelar Ajakan akhir periode', () {
    testWidgets('dimuat dari ingatan, disimpan saat diubah (BP-14)', (tester) async {
      final access = _Settings(value: false);
      await tester.pumpWidget(_host(InviteSwitchEntry(access: access)));
      await tester.pumpAndSettle();
      expect(find.text(t.book.setting.label), findsOneWidget);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isFalse);
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(access.value, isTrue);
      expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
    });
  });
}

final class _Settings implements PeriodBookSettingsAccess {
  _Settings({required this.value});
  bool value;

  @override
  Future<bool> inviteEnabled() async => value;

  @override
  Future<void> setInviteEnabled({required bool enabled}) async => value = enabled;
}
