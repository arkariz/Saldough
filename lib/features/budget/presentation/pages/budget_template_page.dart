import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/di/budget_template_scope.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_template_bloc.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_template_state.dart';
import 'package:saldough/features/budget/presentation/budget_actions.dart';
import 'package:saldough/features/budget/presentation/budget_display.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_template_form_sheet.dart';
import 'package:state_management/state_management.dart';

/// Membuka layar Template Anggaran (T-7.2) di atas layar Anggaran, dengan
/// `BudgetTemplateScope`-nya sendiri (hidup selama layar terbuka) dan
/// `BudgetBloc` yang SAMA — memakai template menambah anggaran lewat bloc
/// itu, jadi daftar Anggaran di belakangnya langsung segar.
///
/// Kontainer induk diambil dari Navigator akar, seperti
/// `openFreelanceOverview`: `ScopeProvider` terdekat di dalam shell adalah
/// kontainer scope fitur lain.
Future<void> openBudgetTemplates(BuildContext context) {
  final budgetBloc = context.read<BudgetBloc>();
  final navigator = Navigator.of(context, rootNavigator: true);
  final parentContainer = ScopeProvider.of(navigator.context);
  return navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => ScopeWidget<BudgetTemplateScope>(
        create: () => BudgetTemplateScope(parentContainer: parentContainer),
        builder: (context, scope) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: scope.container<BudgetTemplateBloc>()),
            BlocProvider.value(value: budgetBloc),
          ],
          child: const EffectListener<BudgetTemplateBloc, BudgetTemplateState>(child: BudgetTemplatePage()),
        ),
      ),
    ),
  );
}

/// Layar Template Anggaran (FR-BUD-005), rujukan `pixel_kas_template_anggaran`:
/// penjelasan singkat, satu kartu per template (nama, jumlah pos, pos-posnya,
/// total rencana, "Gunakan template ini", Ubah, Duplikat), lalu buat template
/// baru. Template nonaktif tetap tampil tetapi tidak bisa dipakai.
class BudgetTemplatePage extends StatefulWidget {
  /// Membuat [BudgetTemplatePage].
  const BudgetTemplatePage({super.key});

  @override
  State<BudgetTemplatePage> createState() => _BudgetTemplatePageState();
}

class _BudgetTemplatePageState extends State<BudgetTemplatePage> {
  @override
  void initState() {
    super.initState();
    context.read<BudgetTemplateBloc>().add(const BudgetTemplatesStarted());
  }

  Future<void> _add() async {
    final bloc = context.read<BudgetTemplateBloc>();
    final result = await showFullScreenSheet<BudgetTemplateFormResult>(
      context,
      builder: (_) => BudgetTemplateFormSheet(wallets: bloc.state.wallets),
    );
    if (result case BudgetTemplateFormSaved(:final name, :final items)) {
      bloc.add(BudgetTemplateAdded(name: name, items: items));
    }
  }

  Future<void> _edit(BudgetTemplate template) async {
    final bloc = context.read<BudgetTemplateBloc>();
    final result = await showFullScreenSheet<BudgetTemplateFormResult>(
      context,
      builder: (_) => BudgetTemplateFormSheet(wallets: bloc.state.wallets, initial: template),
    );
    switch (result) {
      case BudgetTemplateFormSaved(:final name, :final items, :final isEnabled):
        bloc.add(BudgetTemplateEdited(template.copyWith(name: name, items: items, isEnabled: isEnabled)));
      case BudgetTemplateFormDeleted():
        bloc.add(BudgetTemplateDeleted(template));
      case null:
        break;
    }
  }

  Future<void> _use(BudgetTemplate template) async {
    final navigator = Navigator.of(context);
    // Anggaran baru muncul di daftar Anggaran di belakang layar ini.
    if (await useBudgetTemplate(context, template)) navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BudgetTemplateBloc, BudgetTemplateState>(
      builder: (context, state) {
        final colors = context.appColors;
        final textTheme = Theme.of(context).textTheme;
        final canUse = context.read<BudgetBloc>().state.activeWallets.isNotEmpty;
        return Scaffold(
          appBar: AppBar(title: Text(t.budget.templatesTitle)),
          body: SafeArea(
            child: switch (state) {
              BudgetTemplateState(isLoading: true) => const AppSkeletonPage(),
              BudgetTemplateState(loadFailed: true) => _LoadError(
                onRetry: () => context.read<BudgetTemplateBloc>().add(const BudgetTemplatesStarted()),
              ),
              _ => ListView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space2, AppSpacing.space4, AppSpacing.space8),
                children: [
                  AppCard(
                    color: colors.surface2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: AppSpacing.space2,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(t.budget.templatesInfoTitle, style: textTheme.titleMedium),
                            BudgetBadge(label: t.budget.templatesSavedBadge(count: state.templates.length)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(t.budget.templatesInfoBody, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space4),
                  if (state.templates.isEmpty)
                    _EmptyTemplates(onAdd: _add)
                  else
                    for (final template in state.templates) ...[
                      _TemplateCard(
                        template: template,
                        walletName: state.wallets.where((w) => w.id == template.schedule?.walletId).firstOrNull?.name,
                        canUse: canUse,
                        onUse: () => _use(template),
                        onEdit: () => _edit(template),
                        onDuplicate: () => context.read<BudgetTemplateBloc>().add(BudgetTemplateDuplicated(template)),
                      ),
                      const SizedBox(height: AppSpacing.space4),
                    ],
                  if (!canUse) ...[
                    Text(
                      t.budget.templateNeedsWallet,
                      textAlign: TextAlign.center,
                      style: textTheme.bodySmall?.copyWith(color: colors.warning),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                  ],
                  if (state.templates.isNotEmpty)
                    AppButton.secondary(label: t.budget.templateAddAction, onPressed: _add),
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    t.budget.templatesFooter,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                  ),
                ],
              ),
            },
          ),
        );
      },
    );
  }
}

/// Satu template: nama (dan lencana nonaktif), jumlah pos, nama-nama pos,
/// total rencana, "Gunakan template ini", lalu Ubah dan Duplikat.
class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.walletName,
    required this.canUse,
    required this.onUse,
    required this.onEdit,
    required this.onDuplicate,
  });

  final BudgetTemplate template;

  /// Dompet jadwal anggaran rutin (ADR-036), bila berjadwal.
  final String? walletName;
  final bool canUse;
  final VoidCallback onUse;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final enabled = template.isEnabled;
    return Opacity(
      opacity: enabled ? 1 : 0.7,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(template.name, style: textTheme.titleLarge),
            const SizedBox(height: 4),
            Wrap(
              spacing: AppSpacing.space1,
              runSpacing: 4,
              children: [
                BudgetBadge(label: t.budget.templateItemCount(count: template.items.length)),
                if (!enabled) BudgetBadge(label: t.budget.templateInactiveBadge, color: colors.warning),
                if (template.schedule case final schedule? when schedule.isActive)
                  BudgetBadge(
                    label: switch (schedule.period) {
                      BudgetPeriod.monthly => t.budget.templateScheduledMonthly(wallet: walletName ?? '—'),
                      BudgetPeriod.weekly => t.budget.templateScheduledWeekly(wallet: walletName ?? '—'),
                    },
                    color: colors.brand,
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space2),
            Container(
              padding: const EdgeInsets.all(AppSpacing.space2),
              decoration: ShapeDecoration(color: colors.surface2, shape: const PixelCornerBorder.small()),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.budget.templateItemsLabel,
                    style: labelSmStyle(context, color: colors.ink2),
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Wrap(
                    spacing: AppSpacing.space1,
                    runSpacing: AppSpacing.space1,
                    children: [
                      for (final item in template.items)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            border: Border.all(color: colors.line),
                          ),
                          child: Text(item.name, style: textTheme.bodySmall),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space2),
            Row(
              children: [
                Text(t.budget.templateTotalLabel, style: textTheme.bodyMedium?.copyWith(color: colors.ink2)),
                const SizedBox(width: AppSpacing.space2),
                // `Expanded` + rata kanan: nominal menempel ke tepi kanan dan
                // mengecil kalau tidak muat, bukan berhenti di tengah.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      AppMoneyFormatter.format(template.plannedAmount),
                      style: context.numberStyles.amountLg.copyWith(color: colors.ink),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            AppButton(label: t.budget.templateUseAction, onPressed: enabled && canUse ? onUse : null),
            const SizedBox(height: AppSpacing.space2),
            Row(
              children: [
                Expanded(
                  child: AppButton.secondary(label: t.budget.templateEditAction, onPressed: onEdit),
                ),
                const SizedBox(width: AppSpacing.space2),
                Expanded(
                  child: AppButton.secondary(
                    label: t.budget.templateDuplicateAction,
                    onPressed: onDuplicate,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTemplates extends StatelessWidget {
  const _EmptyTemplates({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.space6),
      child: Column(
        children: [
          BudgetBadge(label: t.budget.templatesEmptyBadge, color: colors.warning),
          const SizedBox(height: AppSpacing.space4),
          const AppIcon(IconKey.budget, size: 72),
          const SizedBox(height: AppSpacing.space4),
          Text(t.budget.templatesEmptyTitle, textAlign: TextAlign.center, style: textTheme.titleLarge),
          const SizedBox(height: AppSpacing.space1),
          Text(
            t.budget.templatesEmptyBody,
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: colors.ink2),
          ),
          const SizedBox(height: AppSpacing.space6),
          SizedBox(
            width: double.infinity,
            child: AppButton(label: t.budget.templateAddAction, onPressed: onAdd),
          ),
        ],
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
            Text(t.budget.templatesLoadError, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.space4),
            AppButton(label: t.common.retry, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
