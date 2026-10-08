import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_bloc.dart';
import 'package:saldough/features/freelance/presentation/bloc/freelance_state.dart';
import 'package:saldough/features/freelance/presentation/freelance_actions.dart';
import 'package:saldough/features/freelance/presentation/pages/freelance_project_page.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_cards.dart';
import 'package:saldough/features/freelance/presentation/widgets/freelance_notice.dart';
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
        padding: const EdgeInsets.all(AppSpacing.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t.freelance.loadErrorTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.space4),
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
    // TR-FREELANCE (ADR-021 §3.4): proyek pertama, begitu ada proyek.
    return TourTrigger(
      tour: TourId.freelance,
      ready: state.projects.isNotEmpty,
      child: ListView(
      padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space6),
      children: [
        FreelanceNotice(title: t.freelance.ruleTitle, body: t.freelance.ruleBody),
        const SizedBox(height: AppSpacing.space4),
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
          const SizedBox(height: AppSpacing.space4),
          AppSectionLabel(t.freelance.projectsLabel),
          const SizedBox(height: AppSpacing.space1),
          AddProjectCard(onTap: () => addProject(context)),
          const SizedBox(height: AppSpacing.space2),
          for (final (i, project) in state.projectsByNextPayment.indexed) ...[
            SpotlightTarget(
              spotlightKey: i == 0 ? SpotlightKey.freelanceProject : null,
              child: ProjectCard(
                project: project,
                stats: state.statsOf(project.id),
                paymentStats: state.paymentStatsOf(project.id),
                onTap: () => openFreelanceProject(context, project),
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
          ],
        ],
      ],
      ),
    );
  }
}
