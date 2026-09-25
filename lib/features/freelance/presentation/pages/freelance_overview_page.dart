import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/freelance/di/freelance_scope.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_bloc.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/features/freelance/presentation/freelance_actions.dart';
import 'package:saldough/features/freelance/presentation/pages/freelance_project_page.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_cards.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_notice.dart';
import 'package:saldough/features/freelance/presentation/widgets/project_widgets.dart';
import 'package:state_management/state_management.dart';

/// Membuka Ikhtisar Freelance sebagai layar penuh, lengkap dengan
/// `FreelanceScope`-nya sendiri.
///
/// Titik masuk (FR-FRL-005) — semuanya mendarat di layar yang SAMA:
/// CATAT → Catat Pemasukan → kartu Freelance (`openRecordSheet`), dan
/// ringkasan freelance di Beranda (Fase 6). Freelance bukan tujuan navigasi
/// bawah, jadi lingkupnya hidup selama layar ini terbuka saja.
///
/// Pemanggil yang memegang bloc dompet/transaksi/anggaran menyegarkannya
/// sesudah `Future` ini selesai, karena mencatat pembayaran diterima
/// menambah saldo.
///
/// Kontainer induk diambil dari context Navigator akar, bukan dari
/// [context]: di dalam shell, `ScopeProvider` terdekat adalah kontainer scope
/// fitur lain (mis. `RecordScope`) yang tidak membawa `FreelanceRepository`.
/// Navigator akar berada tepat di bawah `ScopeProvider` akar (`app.dart`).
Future<void> openFreelanceOverview(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final parentContainer = ScopeProvider.of(navigator.context);
  return navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => PixelTheme(
        child: ScopeWidget<FreelanceScope>(
          create: () => FreelanceScope(parentContainer: parentContainer),
          builder: (context, scope) => BlocProvider.value(
            value: scope.container<FreelanceBloc>(),
            child: const EffectListener<FreelanceBloc, FreelanceState>(child: FreelanceOverviewPage()),
          ),
        ),
      ),
    ),
  );
}

/// Satu tab Ikhtisar Freelance: label (dengan jumlah) dan isinya.
typedef _FreelanceTab = ({String label, Widget Function(FreelanceState state) build});

/// Ikhtisar Freelance (T-5.6, FR-FRL-005): tab Worklog (bawaan) dan
/// Pembayaran.
///
/// Daftar tab dibangun dari [_tabsFor], dan `DefaultTabController`
/// mengikuti panjangnya — tab Template (T-7.7) cukup ditambahkan sebagai
/// satu entri lagi, tanpa membongkar layar ini.
class FreelanceOverviewPage extends StatefulWidget {
  /// Membuat [FreelanceOverviewPage].
  const FreelanceOverviewPage({super.key});

  @override
  State<FreelanceOverviewPage> createState() => _FreelanceOverviewPageState();
}

class _FreelanceOverviewPageState extends State<FreelanceOverviewPage> {
  @override
  void initState() {
    super.initState();
    context.read<FreelanceBloc>().add(const FreelanceStarted());
  }

  List<_FreelanceTab> _tabsFor(FreelanceState state) => [
    (label: t.freelance.worklogTab(count: state.entries.length), build: (s) => _WorklogTab(state: s)),
    (label: t.freelance.paymentsTab(count: state.payments.length), build: (s) => _PaymentsTab(state: s)),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FreelanceBloc, FreelanceState>(
      builder: (context, state) {
        final tabs = _tabsFor(state);
        return DefaultTabController(
          length: tabs.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(t.freelance.title),
              bottom: state.isLoading || state.loadFailed
                  ? null
                  : TabBar(tabs: [for (final tab in tabs) Tab(text: tab.label)]),
            ),
            body: SafeArea(
              child: switch (state) {
                FreelanceState(isLoading: true) => const AppSkeletonPage(),
                FreelanceState(loadFailed: true) => _LoadError(
                  onRetry: () => context.read<FreelanceBloc>().add(const FreelanceStarted()),
                ),
                _ => TabBarView(children: [for (final tab in tabs) tab.build(state)]),
              },
            ),
          ),
        );
      },
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.freelance.loadErrorTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: t.common.retry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _WorklogTab extends StatelessWidget {
  const _WorklogTab({required this.state});

  final FreelanceState state;

  @override
  Widget build(BuildContext context) {
    final hasProjects = state.projects.isNotEmpty;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
            children: [
              FreelanceNotice(title: t.freelance.ruleTitle, body: t.freelance.ruleBody),
              const SizedBox(height: AppSpacing.md),
              if (!hasProjects)
                FreelanceEmptyState(
                  badge: t.freelance.projectsEmptyBadge,
                  title: t.freelance.projectsEmptyTitle,
                  body: t.freelance.projectsEmpty,
                  icons: const [IconKey.freelance, IconKey.worklog, IconKey.hourlyRate],
                  actionLabel: t.freelance.projectAddTitle,
                  onAction: () => addProject(context),
                )
              else ...[
                FreelanceSummaryCard(summary: state.summary, projectCount: state.projects.length),
                const SizedBox(height: AppSpacing.md),
                AppSectionLabel(t.freelance.projectsLabel),
                const SizedBox(height: AppSpacing.xs),
                AddProjectCard(onTap: () => addProject(context)),
                const SizedBox(height: AppSpacing.sm),
                for (final project in state.projects) ...[
                  ProjectCard(
                    project: project,
                    stats: state.statsOf(project.id),
                    onTap: () => openFreelanceProject(context, project),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _PaymentsTab extends StatelessWidget {
  const _PaymentsTab({required this.state});

  final FreelanceState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
      children: [
        FreelanceNotice(title: t.freelance.receiveRuleTitle, body: t.freelance.paymentsRuleBody),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _TotalTile(
                  icon: IconKey.pending,
                  label: t.freelance.pendingTotalLabel,
                  amount: state.pendingNetTotal,
                  caption: t.freelance.paymentCount(count: state.pendingPayments.length),
                  color: colors.pending,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _TotalTile(
                  icon: IconKey.paid,
                  label: t.freelance.paidTotalLabel,
                  amount: state.paidNetTotal,
                  caption: t.freelance.paymentCount(count: state.paidPayments.length),
                  color: colors.income,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.payments.isEmpty)
          FreelanceEmptyState(
            badge: t.freelance.paymentsEmptyBadge,
            title: t.freelance.paymentsEmptyTitle,
            body: t.freelance.paymentsEmptyOverviewBody,
            icons: const [IconKey.invoice, IconKey.pending, IconKey.paid],
          )
        else ...[
          AppSectionLabel(t.freelance.projectsLabel),
          const SizedBox(height: AppSpacing.xs),
          for (final project in state.projectsByNextPayment) ...[
            ProjectPaymentCard(
              project: project,
              stats: state.paymentStatsOf(project.id),
              onTap: () => openFreelanceProject(context, project, showPayments: true),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}

class _TotalTile extends StatelessWidget {
  const _TotalTile({
    required this.icon,
    required this.label,
    required this.amount,
    required this.caption,
    required this.color,
  });

  final IconKey icon;
  final String label;
  final int amount;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      color: colors.tinted(color, 0.1),
      shadow: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(icon, size: 18),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label.toUpperCase(), style: transactionLabelStyle(context, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          FitStart(
            child: Text(
              AppMoneyFormatter.format(amount),
              style: PixelTypography.tabularMono(context, fontSize: 17, color: colors.textPrimary),
            ),
          ),
          Text(caption, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted)),
        ],
      ),
    );
  }
}
