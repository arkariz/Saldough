import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/utils/clamped_date.dart';
import 'package:saldough/shared/recurring/recurring.dart';

void main() {
  RecurringRule rule({
    required RecurringSchedule schedule,
    RecurringEnd end = const RecurringNeverEnds(),
  }) => RecurringRule(
    id: 'r1',
    kind: RecurringKind.expense,
    amount: 6500000,
    walletId: 'bca',
    note: 'Netflix',
    schedule: schedule,
    end: end,
  );

  group('clampedDate', () {
    test('menjepit ke hari terakhir bulan, termasuk tahun kabisat', () {
      expect(clampedDate(2027, 2, 31), DateTime(2027, 2, 28));
      expect(clampedDate(2028, 2, 31), DateTime(2028, 2, 29));
      expect(clampedDate(2026, 13, 31), DateTime(2027, 1, 31));
      expect(clampedDate(2026, 10, 15), DateTime(2026, 10, 15));
    });
  });

  group('occurrencesOf', () {
    test('patokan 31: 28 Feb lalu kembali ke 31 Mar dan 30 Apr (§7.7)', () {
      final r = rule(
        schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2027, 1, 31)),
      );
      expect(occurrencesOf(r, from: DateTime(2027), until: DateTime(2027, 5)), [
        DateTime(2027, 1, 31),
        DateTime(2027, 2, 28),
        DateTime(2027, 3, 31),
        DateTime(2027, 4, 30),
      ]);
    });

    test('berakhir setelah 12 kali sejak 10 Jul 2026: terakhir 10 Jun 2027 (§7.7)', () {
      final r = rule(
        schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 7, 10)),
        end: const RecurringEndsAfter(12),
      );
      final all = occurrencesOf(r, from: DateTime(2026), until: DateTime(2030));
      expect(all, hasLength(12));
      expect(all.last, DateTime(2027, 6, 10));
      expect(lastOccurrence(r), DateTime(2027, 6, 10));
    });

    test('berakhir pada tanggal: tanggal itu sendiri masih termasuk', () {
      final r = rule(
        schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 10, 25)),
        end: RecurringEndsOn(DateTime(2026, 12, 25)),
      );
      expect(occurrencesOf(r, from: DateTime(2026), until: DateTime(2028)), [
        DateTime(2026, 10, 25),
        DateTime(2026, 11, 25),
        DateTime(2026, 12, 25),
      ]);
      expect(lastOccurrence(r), DateTime(2026, 12, 25));
    });

    test('mingguan dengan selang 2 melintasi akhir bulan', () {
      final r = rule(
        schedule: RecurringSchedule(
          frequency: RecurringFrequency.weekly,
          interval: 2,
          anchorDate: DateTime(2026, 10),
        ),
      );
      expect(occurrencesOf(r, from: DateTime(2026, 10), until: DateTime(2026, 11, 15)), [
        DateTime(2026, 10),
        DateTime(2026, 10, 15),
        DateTime(2026, 10, 29),
        DateTime(2026, 11, 12),
      ]);
    });

    test('tahunan 29 Feb jatuh ke 28 Feb di tahun bukan kabisat', () {
      final r = rule(
        schedule: RecurringSchedule(frequency: RecurringFrequency.yearly, anchorDate: DateTime(2028, 2, 29)),
      );
      expect(occurrencesOf(r, from: DateTime(2028), until: DateTime(2033)), [
        DateTime(2028, 2, 29),
        DateTime(2029, 2, 28),
        DateTime(2030, 2, 28),
        DateTime(2031, 2, 28),
        DateTime(2032, 2, 29),
      ]);
    });

    test('rentang dimulai sesudah patokan; until eksklusif; jam diabaikan', () {
      final r = rule(
        schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 1, 1, 9, 30)),
      );
      expect(occurrencesOf(r, from: DateTime(2026, 10, 1, 23), until: DateTime(2026, 12)), [
        DateTime(2026, 10),
        DateTime(2026, 11),
      ]);
    });

    test('nextOccurrence dan rutin yang sudah berakhir', () {
      final r = rule(
        schedule: RecurringSchedule(frequency: RecurringFrequency.monthly, anchorDate: DateTime(2026, 7, 10)),
        end: const RecurringEndsAfter(3),
      );
      expect(nextOccurrence(r, DateTime(2026, 8, 11)), DateTime(2026, 9, 10));
      expect(nextOccurrence(r, DateTime(2026, 9, 11)), isNull);
      expect(lastOccurrence(rule(schedule: r.schedule)), isNull);
    });

    test('anchorDay terpisah: jadwal yang patokannya 28 Feb tetap kembali ke 31', () {
      final schedule = RecurringSchedule(
        frequency: RecurringFrequency.monthly,
        anchorDate: DateTime(2027, 2, 28),
        anchorDay: 31,
      );
      expect(schedule.occurrenceAt(1), DateTime(2027, 3, 31));
    });
  });
}
