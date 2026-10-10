import 'package:api_storage/api_storage.dart';
import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memory_storage/memory_storage.dart';
import 'package:saldough/core/financial_month/financial_month.dart';

/// Jadwal bulan keuangan berriwayat (ADR-038 §3.1–3.2, FINANCIAL_PERIOD
/// P-1–P-3, contoh A–C).
void main() {
  T read<T>(Either<Failure, T> result) => result.getOrElse((_) => throw StateError('expected Right'));
  FinancialMonthSchedule single(int day) => FinancialMonthSchedule.single(FinancialMonthStart.day(day));
  FinancialPeriod period(DateTime start, DateTime end, {bool transition = false}) =>
      FinancialPeriod(start: start, end: end, isTransition: transition);
  final allStarts = [
    for (var d = FinancialMonthStart.minDay; d <= FinancialMonthStart.maxDay; d++) FinancialMonthStart.day(d),
    FinancialMonthStart.lastDay,
  ];

  group('financialPeriodOf tanpa perubahan', () {
    test('mulai tanggal 1: bulan kalender, label nama bulan', () {
      final range = financialPeriodOf(DateTime(2026, 10, 2, 9), single(1));
      expect(range, period(DateTime(2026, 10), DateTime(2026, 11)));
      expect(range.days, 31);
      expect(range.label, 'Oktober 2026');
    });

    test('mulai tanggal 25: 3 Nov ada di 25 Okt – 24 Nov; 25 Nov sudah bulan berikutnya', () {
      final range = financialPeriodOf(DateTime(2026, 11, 3), single(25));
      expect(range, period(DateTime(2026, 10, 25), DateTime(2026, 11, 25)));
      expect(range.lastDay, DateTime(2026, 11, 24));
      expect(range.label, '25 Okt – 24 Nov');
      expect(financialPeriodOf(DateTime(2026, 11, 25), single(25)).start, DateTime(2026, 11, 25));
      expect(range.contains(DateTime(2026, 11, 24, 23)), isTrue);
      expect(range.contains(DateTime(2026, 11, 25)), isFalse);
    });

    test('Februari dan pergantian tahun', () {
      final feb = financialPeriodOf(DateTime(2027, 2, 27), single(28));
      expect(feb, period(DateTime(2027, 1, 28), DateTime(2027, 2, 28)));
      expect(feb.days, 31);
      expect(financialPeriodOf(DateTime(2027, 1, 5), single(25)).start, DateTime(2026, 12, 25));
    });

    test('hari terakhir bulan: 31 Okt, 30 Nov, 28 Feb 2027, 29 Feb 2028', () {
      final last = FinancialMonthSchedule.single(FinancialMonthStart.lastDay);
      expect(financialPeriodOf(DateTime(2026, 11, 10), last), period(DateTime(2026, 10, 31), DateTime(2026, 11, 30)));
      expect(financialPeriodOf(DateTime(2026, 10, 31), last).start, DateTime(2026, 10, 31));
      expect(financialPeriodOf(DateTime(2027, 2, 28), last), period(DateTime(2027, 2, 28), DateTime(2027, 3, 31)));
      expect(financialPeriodOf(DateTime(2027, 2, 27), last), period(DateTime(2027, 1, 31), DateTime(2027, 2, 28)));
      expect(financialPeriodOf(DateTime(2028, 2, 29), last).start, DateTime(2028, 2, 29));
      expect(financialPeriodOf(DateTime(2028, 2, 28), last), period(DateTime(2028, 1, 31), DateTime(2028, 2, 29)));
    });
  });

  group('periode peralihan (P-3)', () {
    test('A: 25 → 1 pada 10 Okt: peralihan 25 Sep – 31 Okt (37 hari), lalu 1 – 30 Nov', () {
      final before = single(25);
      final after = before.changedOn(DateTime(2026, 10, 10), FinancialMonthStart.first);
      final current = financialPeriodOf(DateTime(2026, 10, 10), after);
      expect(current, period(DateTime(2026, 9, 25), DateTime(2026, 11), transition: true));
      expect(current.days, 37);
      expect(current.label, '25 Sep – 31 Okt');
      expect(after.nextOf(current), period(DateTime(2026, 11), DateTime(2026, 12)));
      // Periode September 25 Agt – 24 Sep tidak berubah (P-2).
      expect(after.previousOf(current), period(DateTime(2026, 8, 25), DateTime(2026, 9, 25)));
      expect(after.entries.last, (effectiveFrom: DateTime(2026, 9, 25), start: FinancialMonthStart.first));
    });

    test('B: 1 → 25 pada 10 Okt: peralihan 1 – 24 Okt (24 hari), lalu 25 Okt – 24 Nov', () {
      final after = single(1).changedOn(DateTime(2026, 10, 10), const FinancialMonthStart.day(25));
      final current = financialPeriodOf(DateTime(2026, 10, 10), after);
      expect(current, period(DateTime(2026, 10), DateTime(2026, 10, 25), transition: true));
      expect(current.days, 24);
      expect(after.nextOf(current), period(DateTime(2026, 10, 25), DateTime(2026, 11, 25)));
      expect(after.previousOf(current), period(DateTime(2026, 9), DateTime(2026, 10)));
    });

    test('C: 1 → 25 pada 28 Okt: peralihan 1 – 24 Okt sudah selesai, berjalan 25 Okt – 24 Nov', () {
      final after = single(1).changedOn(DateTime(2026, 10, 28), const FinancialMonthStart.day(25));
      expect(financialPeriodOf(DateTime(2026, 10, 28), after), period(DateTime(2026, 10, 25), DateTime(2026, 11, 25)));
      expect(
        financialPeriodOf(DateTime(2026, 10, 10), after),
        period(DateTime(2026, 10), DateTime(2026, 10, 25), transition: true),
      );
      expect(financialPeriodOf(DateTime(2026, 9, 30), after), period(DateTime(2026, 9), DateTime(2026, 10)));
    });

    test('seri di sekitar Februari tetap dihitung ulang persis dari entri', () {
      // 15 → 1: diubah 20 Jan (seri 1 Feb/1 Mar → yang lebih akhir) dan
      // 20 Feb menghasilkan batas akhir yang sama, 1 Mar, tetapi peralihan
      // berbeda.
      final january = single(15).changedOn(DateTime(2027, 1, 20), FinancialMonthStart.first);
      final february = single(15).changedOn(DateTime(2027, 2, 20), FinancialMonthStart.first);
      expect(
        financialPeriodOf(DateTime(2027, 1, 20), january),
        period(DateTime(2027, 1, 15), DateTime(2027, 3), transition: true),
      );
      expect(financialPeriodOf(DateTime(2027, 1, 20), january).days, 45);
      expect(
        financialPeriodOf(DateTime(2027, 2, 20), february),
        period(DateTime(2027, 2, 15), DateTime(2027, 3), transition: true),
      );
      expect(financialPeriodOf(DateTime(2027, 2, 20), february).days, 14);
    });

    test('batas baru sama dengan batas lama (28 → hari terakhir di Februari): bukan peralihan', () {
      final after = single(28).changedOn(DateTime(2027, 2, 10), FinancialMonthStart.lastDay);
      expect(financialPeriodOf(DateTime(2027, 2, 10), after), period(DateTime(2027, 1, 28), DateTime(2027, 2, 28)));
      expect(financialPeriodOf(DateTime(2027, 3, 10), after), period(DateTime(2027, 2, 28), DateTime(2027, 3, 31)));
    });

    test('memilih tanggal yang sama: tidak ada perubahan', () {
      final schedule = single(25);
      expect(schedule.changedOn(DateTime(2026, 10, 10), const FinancialMonthStart.day(25)), same(schedule));
    });

    test('diubah lagi di periode peralihan: entri diganti; kembali ke tanggal lama di peralihan: entri dihapus', () {
      final first = single(25).changedOn(DateTime(2026, 10, 10), FinancialMonthStart.first);
      final again = first.changedOn(DateTime(2026, 10, 12), const FinancialMonthStart.day(10));
      expect(again.entries, hasLength(2));
      // Dihitung dari periode lama 25 Sep – 24 Okt: batas 10 Okt (15 hari)
      // lebih dekat dari 10 Nov (16 hari), dan sudah lewat pada 12 Okt.
      expect(
        financialPeriodOf(DateTime(2026, 10), again),
        period(DateTime(2026, 9, 25), DateTime(2026, 10, 10), transition: true),
      );
      expect(financialPeriodOf(DateTime(2026, 10, 12), again), period(DateTime(2026, 10, 10), DateTime(2026, 11, 10)));
      // Masih di dalam peralihan (1 Okt): kembali ke 25 menghapus entri.
      expect(first.changedOn(DateTime(2026, 10), const FinancialMonthStart.day(25)), single(25));
      // Peralihan 25 Sep – 9 Okt sudah selesai pada 12 Okt: kembali ke 25
      // menambah entri baru, periode yang selesai tidak berubah (P-2).
      final back = again.changedOn(DateTime(2026, 10, 12), const FinancialMonthStart.day(25));
      expect(back.entries, hasLength(3));
      expect(
        financialPeriodOf(DateTime(2026, 10), back),
        period(DateTime(2026, 9, 25), DateTime(2026, 10, 10), transition: true),
      );
    });

    test('perubahan kedua di periode normal sesudahnya menambah entri; peralihan pertama tetap', () {
      final first = single(25).changedOn(DateTime(2026, 10, 10), FinancialMonthStart.first);
      final second = first.changedOn(DateTime(2026, 12, 5), const FinancialMonthStart.day(20));
      expect(second.entries, hasLength(3));
      expect(
        financialPeriodOf(DateTime(2026, 10, 10), second),
        period(DateTime(2026, 9, 25), DateTime(2026, 11), transition: true),
      );
      expect(financialPeriodOf(DateTime(2026, 11, 10), second), period(DateTime(2026, 11), DateTime(2026, 12)));
      expect(
        financialPeriodOf(DateTime(2026, 12, 5), second),
        period(DateTime(2026, 12), DateTime(2026, 12, 20), transition: true),
      );
    });

    test('semua pasangan tanggal mulai 2026–2028: peralihan 13–46 hari, tanpa celah, periode lampau tetap', () {
      for (final old in allStarts) {
        final before = FinancialMonthSchedule.single(old);
        for (var p = before.periodOf(DateTime(2026)); p.start.isBefore(DateTime(2029)); p = before.nextOf(p)) {
          // Peralihan hanya bergantung pada periode berjalan, bukan harinya.
          for (final today in [p.lastDay]) {
            for (final next in allStarts) {
              if (next == old) continue;
              final after = before.changedOn(today, next);
              final changed = after.periodOf(p.start);
              final reason = '$old → $next pada $today';
              expect(changed.start, p.start, reason: reason);
              if (changed.isTransition) {
                expect(changed.days, inInclusiveRange(13, 46), reason: reason);
              } else {
                expect(changed, p, reason: reason);
              }
              final following = after.nextOf(changed);
              expect(following.start, changed.end, reason: reason);
              expect(following.isTransition, isFalse, reason: reason);
              expect(next.floor(following.start), following.start, reason: reason);
              final earlier = before.previousOf(p);
              expect(after.previousOf(changed), earlier, reason: reason);
              expect(after.periodOf(earlier.start), earlier, reason: reason);
            }
          }
        }
      }
    });
  });

  group('preferensi', () {
    const legacyKey = StorageKey(namespace: 'settings', name: 'financial_month_start');
    const scheduleKey = StorageKey(namespace: 'settings', name: 'financial_month_schedule');

    test('bawaan tanggal 1', () async {
      final repository = FinancialMonthPreferenceRepositoryImpl(storage: InMemoryKeyValueStorage());
      expect(read(await repository.load()), FinancialMonthSchedule.initial);
    });

    test('migrasi: preferensi lama satu angka menjadi satu entri sejak awal', () async {
      final storage = InMemoryKeyValueStorage();
      await storage.write(legacyKey.value, '{"schemaVersion":1,"startDay":25}');
      final repository = FinancialMonthPreferenceRepositoryImpl(storage: storage);
      final schedule = read(await repository.load());
      expect(schedule, single(25));
      expect(schedule.entries.single.effectiveFrom, FinancialMonthSchedule.origin);
      await storage.write(legacyKey.value, '{"schemaVersion":1,"startDay":31}');
      expect(read(await repository.load()), FinancialMonthSchedule.initial);
    });

    test('riwayat tersimpan dan dibaca kembali utuh, termasuk hari terakhir', () async {
      final storage = InMemoryKeyValueStorage();
      final repository = FinancialMonthPreferenceRepositoryImpl(storage: storage);
      final schedule = single(15)
          .changedOn(DateTime(2027, 1, 20), FinancialMonthStart.first)
          .changedOn(DateTime(2027, 4, 3), FinancialMonthStart.lastDay);
      await repository.save(schedule);
      expect(read(await repository.load()), schedule);
      // Preferensi baru mengalahkan yang lama.
      await storage.write(legacyKey.value, '{"schemaVersion":1,"startDay":25}');
      expect(read(await repository.load()), schedule);
    });

    test('entri tidak sah dilewati', () async {
      final storage = InMemoryKeyValueStorage();
      await storage.write(
        scheduleKey.value,
        '{"schemaVersion":1,"entries":[{"effectiveFrom":"0001-01-01","startDay":25},'
        '{"effectiveFrom":"2026-09-25","startDay":31},{"effectiveFrom":"bukan","startDay":1}]}',
      );
      final repository = FinancialMonthPreferenceRepositoryImpl(storage: storage);
      expect(read(await repository.load()), single(25));
    });
  });
}
