import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/app/milestone/stamp_remote_switch.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_catalog.dart';

void main() {
  test('kunci belum pernah diambil: semua menyala', () {
    expect(stampDisabledIds(), isEmpty);
  });

  test('stamps_enabled false atau 0 mematikan seluruh katalog', () {
    final all = {for (final d in milestoneCatalog) d.id};
    expect(stampDisabledIds(enabledRaw: 'false'), all);
    expect(stampDisabledIds(enabledRaw: ' FALSE '), all);
    expect(stampDisabledIds(enabledRaw: '0'), all);
    expect(stampDisabledIds(enabledRaw: 'true'), isEmpty);
  });

  test('stamps_disabled_ids: daftar koma, spasi dan id asing diabaikan', () {
    expect(stampDisabledIds(disabledRaw: 'period_tidy, backup_first ,tidak_ada,'), {'period_tidy', 'backup_first'});
  });

  test('peristiwa stempel: nama dan parameter, id hanya kosakata tetap, tanpa nominal', () {
    expect(MilestoneEvents.earned(id: 'wallet_first', quiet: false), const AnalyticsEvent('milestone_earned', {'id': 'wallet_first', 'quiet': 'false'}));
    expect(MilestoneEvents.earned(id: 'wallet_first', quiet: true).parameters['quiet'], 'true');
    expect(MilestoneEvents.earned(id: 'nama pengguna', quiet: false).parameters['id'], 'unknown');
    expect(MilestoneEvents.bookViewed('account'), const AnalyticsEvent('stamp_book_viewed', {'source': 'account'}));
    expect(MilestoneEvents.settingChanged(enabled: false), const AnalyticsEvent('celebration_setting_changed', {'enabled': 'false'}));
    expect(MilestoneEvents.celebrationShown(2), const AnalyticsEvent('milestone_celebration_shown', {'count': 2}));
    expect({for (final d in milestoneCatalog) d.id}, MilestoneEvents.ids, reason: 'kosakata analitik = katalog');
  });
}
