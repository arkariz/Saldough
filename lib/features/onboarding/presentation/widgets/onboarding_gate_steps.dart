import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/onboarding/presentation/widgets/onboarding_scene.dart';

/// Jawaban langkah pengingat rutin (FEATURE_DISCOVERY §4.4).
enum OnboardingReminderChoice {
  /// Dinyalakan dan izin diberikan.
  on,

  /// Dicoba nyalakan, izin sistem ditolak: lanjut dengan "Izin belum diberikan".
  permissionDenied,

  /// "Tidak sekarang".
  off,
}

/// Langkah wajib **awal periode keuangan** (FEATURE_DISCOVERY §4.2): pemilih
/// tanggal 1–28 atau hari terakhir bulan. Tanggal 1 terpilih sebagai bawaan,
/// jadi tombol di `OnboardingPage` selalu aktif.
class OnboardingPeriodStep extends StatelessWidget {
  /// Membuat [OnboardingPeriodStep].
  const OnboardingPeriodStep({required this.selected, required this.onSelected, super.key});

  /// Tanggal terpilih.
  final FinancialMonthStart selected;

  /// Tanggal diketuk.
  final ValueChanged<FinancialMonthStart> onSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      key: const ValueKey('onboarding-period-step'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(header: true, child: Text(t.onboarding.periodTitle, style: textTheme.headlineSmall)),
              const SizedBox(height: AppSpacing.space2),
              Text(t.onboarding.periodBody, style: textTheme.bodyMedium),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.space4),
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.space2),
          child: AppDayGrid(selected: selected, onSelected: onSelected),
        ),
      ],
    );
  }
}

/// Langkah wajib **pengingat rutin** (FEATURE_DISCOVERY §4.4): satu layar
/// manfaat. Sesudah dijawab ([choice] terisi) status ditampilkan dan tombol
/// berganti menjadi Lanjut di `OnboardingPage`.
class OnboardingReminderStep extends StatelessWidget {
  /// Membuat [OnboardingReminderStep].
  const OnboardingReminderStep({required this.choice, super.key});

  /// Jawaban, atau `null` bila belum dijawab.
  final OnboardingReminderChoice? choice;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      key: const ValueKey('onboarding-reminder-step'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ilustrasi OB-4 yang sudah ada (selisih 7 rupa v2).
              ExcludeSemantics(
                child: Image.asset(
                  'assets/illustration/onboarding_4.png',
                  height: 120,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.none,
                  alignment: Alignment.centerLeft,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              Semantics(header: true, child: Text(t.onboarding.reminderTitle, style: textTheme.headlineSmall)),
              const SizedBox(height: AppSpacing.space2),
              Text(t.onboarding.reminderBody, style: textTheme.bodyMedium),
              if (choice case final answered?) ...[
                const SizedBox(height: AppSpacing.space3),
                _StatusRow(
                  key: const ValueKey('onboarding-reminder-status'),
                  label: t.onboarding.summaryReminder,
                  choice: answered,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.choice, super.key});

  final String label;
  final OnboardingReminderChoice choice;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
      _reminderBadge(choice),
    ],
  );
}

AppBadge _reminderBadge(OnboardingReminderChoice choice) => switch (choice) {
  OnboardingReminderChoice.on => AppBadge(t.discovery.status.on, tone: AppTone.positive),
  OnboardingReminderChoice.permissionDenied => AppBadge(
    t.discovery.status.permissionNeeded,
    tone: AppTone.warning,
    icon: IconKey.warning,
  ),
  OnboardingReminderChoice.off => AppBadge(t.discovery.status.off),
};

/// Penutup (FEATURE_DISCOVERY §4.5): ajakan dompet pertama, ringkasan dua
/// jawaban tadi (satu baris tiap jawaban), dan, hanya di Android, satu baris
/// informasi Catat dari notifikasi yang tidak dapat diketuk (§4.3).
class OnboardingFinale extends StatelessWidget {
  /// Membuat [OnboardingFinale].
  const OnboardingFinale({this.period, this.reminder, super.key});

  /// Awal periode yang dipilih sesi ini, atau `null` bila tidak ditanya.
  final FinancialMonthStart? period;

  /// Jawaban pengingat sesi ini, atau `null` bila tidak ditanya.
  final OnboardingReminderChoice? reminder;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final rows = <Widget>[
      if (period case final start?)
        AppListRow(
          key: const ValueKey('onboarding-summary-period'),
          compact: true,
          leading: AppIcon(IconKey.calendar, color: colors.ink2),
          title: t.onboarding.summaryPeriod,
          trailing: Text(
            switch (start.day) {
              final day? => t.plan.financialMonthDay(day: day),
              null => t.plan.financialMonthLastDay,
            },
            style: textTheme.bodySmall?.copyWith(color: colors.ink2),
          ),
        ),
      if (reminder case final choice?)
        AppListRow(
          key: const ValueKey('onboarding-summary-reminder'),
          compact: true,
          leading: AppIcon(IconKey.schedule, color: colors.ink2),
          title: t.onboarding.summaryReminder,
          trailing: _reminderBadge(choice),
        ),
    ];
    return SingleChildScrollView(
      key: const ValueKey('onboarding-finale'),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(
            height: 156,
            child: ExcludeSemantics(child: OnboardingScene(index: onboardingSlideCount - 1, active: true)),
          ),
          const SizedBox(height: AppSpacing.space3),
          Semantics(
            header: true,
            child: Text(t.onboarding.finalTitle, style: textTheme.headlineSmall, textAlign: TextAlign.center),
          ),
          const SizedBox(height: AppSpacing.space2),
          Text(t.onboarding.finalBody, style: textTheme.bodyMedium, textAlign: TextAlign.center),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            AppListCard(children: rows),
          ],
          if (defaultTargetPlatform == TargetPlatform.android) ...[
            const SizedBox(height: AppSpacing.space3),
            Row(
              key: const ValueKey('onboarding-notification-info'),
              children: [
                ExcludeSemantics(child: AppIcon(IconKey.notifications, color: colors.ink2)),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: Text(t.onboarding.notificationInfo, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
