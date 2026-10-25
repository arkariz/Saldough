import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/features/premium/domain/offering_policy.dart';
import 'package:saldough/features/premium/domain/purchase_models.dart';

/// Pemilihan offering (ADR-041 §3.5, KT-P12).
void main() {
  final founderEnd = DateTime(2027, 3, 1, 23, 59);

  OfferingId pick(
    DateTime now, {
    DateTime? founderUntil,
    DateTime? trialEndsOn,
    int hours = 48,
  }) => selectOffering(
    now: now,
    founderUntil: founderUntil,
    trialEndsOn: trialEndsOn,
    postTrialHours: hours,
  );

  test('tanpa jendela apa pun: harga biasa', () {
    expect(pick(DateTime(2026, 12, 10)), OfferingId.standard);
    expect(OfferingId.standard.id, 'default');
    expect(OfferingId.founder.id, 'founder');
    expect(OfferingId.postTrial.id, 'post_trial');
  });

  test('Harga Pendiri sampai batas jendela, lalu biasa', () {
    expect(
      pick(DateTime(2027, 2), founderUntil: founderEnd),
      OfferingId.founder,
    );
    expect(
      pick(founderEnd, founderUntil: founderEnd),
      OfferingId.founder,
      reason: 'batas inklusif',
    );
    expect(
      pick(
        founderEnd.add(const Duration(minutes: 1)),
        founderUntil: founderEnd,
      ),
      OfferingId.standard,
    );
  });

  group('penawaran sesudah uji coba', () {
    final trialLastDay = DateTime(2026, 12, 24);

    test('mulai tengah malam sesudah hari terakhir, selama 48 jam', () {
      expect(
        pick(DateTime(2026, 12, 24, 23, 59), trialEndsOn: trialLastDay),
        OfferingId.standard,
        reason: 'masih uji coba',
      );
      expect(
        pick(DateTime(2026, 12, 25), trialEndsOn: trialLastDay),
        OfferingId.postTrial,
      );
      expect(
        pick(DateTime(2026, 12, 26, 23, 59), trialEndsOn: trialLastDay),
        OfferingId.postTrial,
      );
      expect(
        pick(DateTime(2026, 12, 27), trialEndsOn: trialLastDay),
        OfferingId.standard,
        reason: 'tepat 48 jam',
      );
    });

    test('lama jendela dari Remote Config', () {
      expect(
        pick(DateTime(2026, 12, 27, 5), trialEndsOn: trialLastDay, hours: 72),
        OfferingId.postTrial,
      );
      expect(
        pick(DateTime(2026, 12, 25, 1), trialEndsOn: trialLastDay, hours: 0),
        OfferingId.standard,
      );
    });

    test('Pendiri didahulukan atas penawaran sesudah uji coba', () {
      expect(
        pick(
          DateTime(2026, 12, 25),
          founderUntil: founderEnd,
          trialEndsOn: trialLastDay,
        ),
        OfferingId.founder,
      );
    });
  });

  test(
    'PlusPlanKind: id sama dengan identifier package dan tidak dikenal = null',
    () {
      expect(PlusPlanKind.fromId('yearly_founder'), PlusPlanKind.yearlyFounder);
      expect(PlusPlanKind.fromId('monthly'), PlusPlanKind.monthly);
      expect(PlusPlanKind.fromId('lifetime'), isNull);
      expect(
        PlusPlanKind.values.map((k) => k.id).toSet(),
        hasLength(PlusPlanKind.values.length),
      );
    },
  );

  test('PlusPlanKind.fromId: id kita dan package bawaan RevenueCat', () {
    expect(PlusPlanKind.fromId('yearly_founder'), PlusPlanKind.yearlyFounder);
    expect(PlusPlanKind.fromId(r'$rc_monthly'), PlusPlanKind.monthly);
    expect(PlusPlanKind.fromId(r'$rc_annual'), PlusPlanKind.yearly);
    expect(PlusPlanKind.fromId(r'$rc_weekly'), isNull);
  });
}
