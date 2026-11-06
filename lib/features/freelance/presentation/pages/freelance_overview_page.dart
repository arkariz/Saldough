import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_bloc.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/features/freelance/presentation/freelance_actions.dart';
import 'package:saldough/features/freelance/presentation/pages/freelance_project_page.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_cards.dart';
import 'package:saldough/features/freelance/presentation/widgets/project_widgets.dart';
import 'package:state_management/state_management.dart';

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
      appBar: AppBar(
        title: Text(t.freelance.title),
        actions: const [TutorialInfoButton(tour: TourId.freelance)],
      ),
      body: SafeArea(
        child: BlocBuilder<FreelanceBloc, FreelanceState>(
          builder: (context, state) => switch (state) {
            FreelanceState(isLoading: true) => const _OverviewSkeleton(),
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

class _OverviewSkeleton extends StatelessWidget {
  const _OverviewSkeleton();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsSkeleton(height: 200, radius: DsRadius.lgAll),
        SizedBox(height: 24),
        DsSkeleton(height: 20, width: 120),
        SizedBox(height: 12),
        DsSkeleton(height: 72, radius: DsRadius.lgAll),
        SizedBox(height: 12),
        DsSkeleton(height: 72, radius: DsRadius.lgAll),
      ],
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      DsErrorState(title: t.freelance.loadErrorTitle, retryLabel: t.common.retry, onRetry: onRetry);
}

class _Overview extends StatelessWidget {
  const _Overview({required this.state});

  final FreelanceState state;

  @override
  Widget build(BuildContext context) {
    // TR-FREELANCE (ADR-021 §3.4): proyek pertama, begitu ada proyek.
    return TourTrigger(
      tour: TourId.freelance,
      ready: state.projects.isNotEmpty,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          if (state.projects.isEmpty)
            FreelanceEmptyState(
              title: t.freelance.projectsEmptyTitle,
              body: t.freelance.projectsEmpty,
              actionLabel: t.freelance.projectAddTitle,
              onAction: () => addProject(context),
            )
          else ...[
            FreelanceSummaryCard(
              summary: state.summary,
              projectCount: state.projects.length,
              payments: state.paymentTotals,
              unbilledHours: state.projects.fold(0, (sum, p) => sum + state.statsOf(p.id).unbilledHours),
              unbilledAmount: state.projects.fold(0, (sum, p) => sum + state.statsOf(p.id).unbilledAmount),
            ),
            const SizedBox(height: 24),
            DsSectionHeader(title: t.freelance.projectsLabel),
            const SizedBox(height: 8),
            DsListCard(
              children: [
                for (final (i, project) in state.projectsByNextPayment.indexed)
                  SpotlightTarget(
                    spotlightKey: i == 0 ? SpotlightKey.freelanceProject : null,
                    child: ProjectCard(
                      project: project,
                      stats: state.statsOf(project.id),
                      paymentStats: state.paymentStatsOf(project.id),
                      onTap: () => openFreelanceProject(context, project),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AddProjectCard(
              onTap: () => addProject(context),
              limited: state.projects.length >= ActivePlan.limits.value.freeProjects,
            ),
          ],
        ],
      ),
    );
  }
}
