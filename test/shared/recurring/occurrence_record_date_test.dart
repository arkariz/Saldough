import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/shared/recurring/recurring.dart';

/// ADR-042 §3.3: pencatatan kemunculan lebih awal memakai hari ini.
void main() {
  final now = DateTime(2026, 10, 23, 9, 45);

  test('kemunculan hari ini atau lewat: tanggal kemunculan dengan jam sekarang', () {
    expect(occurrenceRecordDate(DateTime(2026, 10, 20), now), DateTime(2026, 10, 20, 9, 45));
    expect(occurrenceRecordDate(DateTime(2026, 10, 23), now), DateTime(2026, 10, 23, 9, 45));
  });

  test('kemunculan belum tiba, berapa hari pun: hari ini', () {
    expect(occurrenceRecordDate(DateTime(2026, 10, 24), now), now);
    expect(occurrenceRecordDate(DateTime(2026, 12, 25), now), now);
  });
}
