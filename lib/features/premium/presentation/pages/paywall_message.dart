import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/features/premium/domain/paywall_trigger.dart';

/// Judul dan satu kalimat paywall untuk satu pemicu (FREEMIUM_PAYWALL §9,
/// design README "Paywall Plus"): hanya dua teks ini yang berganti, dan
/// selalu menyebut yang tetap gratis.
final class PaywallMessage {
  const PaywallMessage._(this.title, this.body, {required this.hasKicker});

  /// Pesan paywall untuk [trigger]. Pemicu tanpa pesan sendiri memakai pesan umum.
  factory PaywallMessage.of(PaywallTrigger trigger) {
    final m = t.premium.paywall.messages;
    return switch (trigger) {
      PaywallTrigger.analysisHistory => PaywallMessage._(
        m.analysis.title,
        m.analysis.body,
        hasKicker: true,
      ),
      PaywallTrigger.notificationSource => PaywallMessage._(
        m.notification.title,
        m.notification.body,
        hasKicker: true,
      ),
      PaywallTrigger.recurringAutomation => PaywallMessage._(
        m.auto.title,
        m.auto.body,
        hasKicker: true,
      ),
      PaywallTrigger.templateLimit => PaywallMessage._(
        m.template.title,
        m.template.body,
        hasKicker: true,
      ),
      PaywallTrigger.projectLimit => PaywallMessage._(
        m.project.title,
        m.project.body,
        hasKicker: true,
      ),
      PaywallTrigger.forecast => PaywallMessage._(
        m.forecast.title,
        m.forecast.body,
        hasKicker: true,
      ),
      PaywallTrigger.smartQuota || PaywallTrigger.askQuota => PaywallMessage._(
        m.reading.title(
          n: ActivePlan.limits.value.freeAllowance(
            PlusFeature.smartInterpretation,
          ),
        ),
        m.reading.body,
        hasKicker: true,
      ),
      _ => PaywallMessage._(m.general.title, m.general.body, hasKicker: false),
    };
  }

  /// Judul.
  final String title;

  /// Satu kalimat.
  final String body;

  /// Lencana "Tanukonomy Plus" di atas judul (semua pemicu selain umum).
  final bool hasKicker;
}
