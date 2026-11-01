import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/financial_month/financial_month.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/onboarding/presentation/widgets/onboarding_widgets.dart';

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
    return ListView(
      key: const ValueKey('onboarding-period-step'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        OnboardingStepHeader(
          asset: ClayIcons.dateCalendar,
          title: t.onboarding.periodTitle,
          body: t.onboarding.periodBody,
        ),
        const SizedBox(height: 20),
        DsCard(
          padding: const EdgeInsets.all(8),
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
    return ListView(
      key: const ValueKey('onboarding-reminder-step'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        OnboardingStepHeader(
          asset: ClayIcons.alarm,
          title: t.onboarding.reminderTitle,
          body: t.onboarding.reminderBody,
          footer: choice == null
              ? null
              : DsCard(
                  child: _StatusRow(
                    key: const ValueKey('onboarding-reminder-status'),
                    label: t.onboarding.summaryReminder,
                    choice: choice!,
                  ),
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
      Expanded(child: Text(label, style: context.ds.typography.bodyMd)),
      _reminderBadge(choice),
    ],
  );
}

Widget _reminderBadge(OnboardingReminderChoice choice) => switch (choice) {
  OnboardingReminderChoice.on => DsBadge(label: t.discovery.status.on, tone: DsBadgeTone.income),
  OnboardingReminderChoice.permissionDenied => DsBadge(
    label: t.discovery.status.permissionNeeded,
    tone: DsBadgeTone.warning,
  ),
  OnboardingReminderChoice.off => DsBadge(label: t.discovery.status.off, tone: DsBadgeTone.neutral),
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
    final ds = context.ds;
    final c = ds.colors;
    final rows = <Widget>[
      if (period case final start?)
        DsSettingRow(
          key: const ValueKey('onboarding-summary-period'),
          leading: DsIconTile.asset(asset: ClayIcons.dateCalendar),
          title: t.onboarding.summaryPeriod,
          badge: Text(
            switch (start.day) {
              final day? => t.plan.financialMonthDay(day: day),
              null => t.plan.financialMonthLastDay,
            },
            style: ds.typography.bodySm.copyWith(color: c.textSecondary),
          ),
        ),
      if (reminder case final choice?)
        DsSettingRow(
          key: const ValueKey('onboarding-summary-reminder'),
          leading: DsIconTile.asset(asset: ClayIcons.alarm),
          title: t.onboarding.summaryReminder,
          badge: _reminderBadge(choice),
        ),
    ];
    return SingleChildScrollView(
      key: const ValueKey('onboarding-finale'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _FinaleMascot(),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(
              t.onboarding.finalTitle,
              textAlign: TextAlign.center,
              style: ds.typography.headlineMd.copyWith(fontSize: 24),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.onboarding.finalBody,
            textAlign: TextAlign.center,
            style: ds.typography.bodyMd.copyWith(color: c.textSecondary),
          ),
          if (rows.isNotEmpty) ...[const SizedBox(height: 20), DsListCard(children: rows)],
          if (defaultTargetPlatform == TargetPlatform.android) ...[
            const SizedBox(height: 12),
            DecoratedBox(
              key: const ValueKey('onboarding-notification-info'),
              decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.lgAll),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    DsIconTile.asset(asset: ClayIcons.bell, size: DsIconTileSize.sm),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        t.onboarding.notificationInfo,
                        style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Maskot penutup: membal masuk, melayang pelan, dan konfeti sekali saat
/// tiba. Diam bila gerak dikurangi.
class _FinaleMascot extends StatefulWidget {
  const _FinaleMascot();

  @override
  State<_FinaleMascot> createState() => _FinaleMascotState();
}

class _FinaleMascotState extends State<_FinaleMascot> with SingleTickerProviderStateMixin {
  late final AnimationController _in = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
  final GlobalKey _key = GlobalKey();
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (DsMotion.reduced(context)) {
      _in.value = 1;
      return;
    }
    _in.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final box = _key.currentContext?.findRenderObject() as RenderBox?;
      if (!mounted || box == null || !box.hasSize) return;
      final origin = box.localToGlobal(box.size.center(Offset.zero));
      Future<void>.delayed(const Duration(milliseconds: 380), () {
        if (mounted) DsCelebration.burst(context, origin: origin, count: 28);
      });
    });
  }

  @override
  void dispose() {
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    return ExcludeSemantics(
      child: SizedBox(
        height: 170,
        child: Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: _in, curve: Curves.elasticOut),
            child: DsIdleMotion(
              kind: DsIdleKind.float,
              child: DecoratedBox(
                key: _key,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [c.actionPrimary.withValues(alpha: 0.2), c.actionPrimary.withValues(alpha: 0.03)],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SvgPicture.asset(ClayIcons.mascot, width: 110, height: 110),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
