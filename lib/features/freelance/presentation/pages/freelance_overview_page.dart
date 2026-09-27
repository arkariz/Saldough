import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
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

/// Ikhtisar Freelance (FR-FRL-005, T-5.9): satu layar tanpa tab — kartu
/// aturan, ringkasan upah & jam, lalu kartu proyek. Worklog dan pembayaran
/// satu proyek ada di rinciannya.
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.freelance.title)),
      body: SafeArea(
        child: BlocBuilder<FreelanceBloc, FreelanceState>(
          builder: (context, state) => switch (state) {
            FreelanceState(isLoading: true) => const AppSkeletonPage(),
            FreelanceState(loadFailed: true) => _LoadError(
              onRetry: () => context.read<FreelanceBloc>().add(const FreelanceStarted()),
            ),
            _ => _Overview(state: state),
          },
        ),
      ),
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

class _Overview extends StatelessWidget {
  const _Overview({required this.state});

  final FreelanceState state;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
      children: [
        FreelanceNotice(title: t.freelance.ruleTitle, body: t.freelance.ruleBody),
        const SizedBox(height: AppSpacing.md),
        if (state.projects.isEmpty)
          FreelanceEmptyState(
            badge: t.freelance.projectsEmptyBadge,
            title: t.freelance.projectsEmptyTitle,
            body: t.freelance.projectsEmpty,
            icons: const [IconKey.freelance, IconKey.worklog, IconKey.hourlyRate],
            actionLabel: t.freelance.projectAddTitle,
            onAction: () => addProject(context),
          )
        else ...[
          FreelanceSummaryCard(
            summary: state.summary,
            projectCount: state.projects.length,
            payments: state.paymentTotals,
          ),
          const SizedBox(height: AppSpacing.md),
          AppSectionLabel(t.freelance.projectsLabel),
          const SizedBox(height: AppSpacing.xs),
          AddProjectCard(onTap: () => addProject(context)),
          const SizedBox(height: AppSpacing.sm),
          for (final project in state.projectsByNextPayment) ...[
            ProjectCard(
              project: project,
              stats: state.statsOf(project.id),
              paymentStats: state.paymentStatsOf(project.id),
              onTap: () => openFreelanceProject(context, project),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ],
    );
  }
}
