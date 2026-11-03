import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/features/plan/presentation/pages/plan_page.dart';

/// Segmen pertama tab Rencana bernama Ringkasan/Overview, bukan "Bulan ini"
/// (isinya mencakup bulan depan, indikator, dan grafik saldo).
void main() {
  test('label segmen pertama: Ringkasan (id) dan Overview (en)', () async {
    expect(PlanPage.labelOf(PlanSegment.thisMonth), 'Ringkasan');
    await LocaleSettings.setLocale(AppLocale.en);
    addTearDown(() => LocaleSettings.setLocaleSync(AppLocale.id));
    expect(PlanPage.labelOf(PlanSegment.thisMonth), 'Overview');
    expect(t.tour.planTabsBody, startsWith('Overview,'));
  });
}
