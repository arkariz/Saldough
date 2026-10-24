import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/financial_month/financial_period.dart';
import 'package:saldough/core/foundation/entitlement/entitlement.dart';

/// Panjang uji coba (ADR-041 §3.4, FREEMIUM_PAYWALL §8.1) dan jangkarnya
/// (§3.13 butir 5).
void main() {
  final from25 = FinancialMonthSchedule.single(
    const FinancialMonthStart.day(25),
  );
  final calendar = FinancialMonthSchedule.initial;

  group('trialEndsOn', () {
    test('contoh FREEMIUM §8.1: periode mulai tanggal 25', () {
      expect(
        trialEndsOn(DateTime(2026, 11), from25),
        DateTime(2026, 11, 24),
      );
      expect(
        trialEndsOn(DateTime(2026, 11, 15), from25),
        DateTime(2026, 12, 24),
      );
    });

    test(
      'batas 14 hari: sisa tepat 14 tetap di periode berjalan, 13 pindah ke berikutnya',
      () {
        expect(
          trialEndsOn(DateTime(2026, 11, 11), from25),
          DateTime(2026, 11, 24),
          reason: '11–24 Nov = 14 hari',
        );
        expect(
          trialEndsOn(DateTime(2026, 11, 12), from25),
          DateTime(2026, 12, 24),
          reason: '12–24 Nov = 13 hari',
        );
        expect(
          trialEndsOn(DateTime(2026, 10, 18), calendar),
          DateTime(2026, 10, 31),
        );
        expect(
          trialEndsOn(DateTime(2026, 10, 19), calendar),
          DateTime(2026, 11, 30),
        );
      },
    );

    test('jam di tanggal mulai tidak berpengaruh', () {
      expect(
        trialEndsOn(DateTime(2026, 11, 11, 23, 59), from25),
        DateTime(2026, 11, 24),
      );
    });

    test('minDays dari Remote Config dipakai', () {
      expect(
        trialEndsOn(DateTime(2026, 11, 15), from25, minDays: 10),
        DateTime(2026, 11, 24),
      );
    });

    test('periode peralihan: akhir uji coba mengikuti jadwal berriwayat', () {
      final changed = calendar.changedOn(
        DateTime(2026, 10, 10),
        const FinancialMonthStart.day(25),
      );
      final start = DateTime(2026, 10, 10);
      final period = financialPeriodOf(start, changed);
      expect(period.isTransition, isTrue);
      final ends = trialEndsOn(start, changed);
      expect(
        ends == period.lastDay || ends == changed.nextOf(period).lastDay,
        isTrue,
      );
    });

    test(
      'sifat untuk semua hari setahun dan beberapa jadwal: 14 hari sampai ±46 hari, berakhir di hari terakhir periode',
      () {
        final schedules = [
          calendar,
          from25,
          FinancialMonthSchedule.single(FinancialMonthStart.lastDay),
          calendar.changedOn(
            DateTime(2026, 3, 10),
            const FinancialMonthStart.day(20),
          ),
        ];
        for (final schedule in schedules) {
          for (
            var d = DateTime(2026);
            d.year == 2026;
            d = DateTime(d.year, d.month, d.day + 1)
          ) {
            final ends = trialEndsOn(d, schedule);
            final days =
                DateTime.utc(
                  ends.year,
                  ends.month,
                  ends.day,
                ).difference(DateTime.utc(d.year, d.month, d.day)).inDays +
                1;
            expect(days, inInclusiveRange(14, 77), reason: '$d → $ends');
            expect(
              financialPeriodOf(ends, schedule).lastDay,
              ends,
              reason: '$d → $ends bukan hari terakhir periode',
            );
          }
        }
      },
    );
  });

  group('trialAnchor', () {
    final launch = DateTime(2026, 12, 1, 10);

    test('pra-peluncuran: tidak ada uji coba', () {
      expect(
        trialAnchor(
          launchAt: null,
          accountCreatedAt: DateTime(2026, 12, 5),
          firstSeenLocal: DateTime(2026, 12, 5),
        ),
        isNull,
      );
    });

    test('akun baru sesudah peluncuran: hari pembuatan akun dari server', () {
      expect(
        trialAnchor(
          launchAt: launch,
          accountCreatedAt: DateTime(2026, 12, 9, 8),
          firstSeenLocal: DateTime(2026, 12, 20),
        ),
        DateTime(2026, 12, 9),
      );
      expect(
        trialAnchor(
          launchAt: launch,
          accountCreatedAt: DateTime(2026, 12, 1, 7),
          firstSeenLocal: null,
        ),
        DateTime(2026, 12),
        reason: 'hari yang sama dengan peluncuran dihitung akun baru',
      );
    });

    test('akun lama: hari pertama masuk di perangkat sesudah peluncuran', () {
      expect(
        trialAnchor(
          launchAt: launch,
          accountCreatedAt: DateTime(2026, 9, 29),
          firstSeenLocal: DateTime(2026, 12, 14, 21),
        ),
        DateTime(2026, 12, 14),
      );
      expect(
        trialAnchor(
          launchAt: launch,
          accountCreatedAt: DateTime(2026, 9, 29),
          firstSeenLocal: null,
        ),
        isNull,
      );
    });

    test('catatan lokal sebelum peluncuran dinaikkan ke hari peluncuran', () {
      expect(
        trialAnchor(
          launchAt: launch,
          accountCreatedAt: null,
          firstSeenLocal: DateTime(2026, 11, 20),
        ),
        DateTime(2026, 12),
      );
    });
  });
}
