import 'dart:async';

import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/foundation/navigation/route_navigation.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/plan/active_plan.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/features/budget/di/budget_template_scope.dart';
import 'package:saldough/features/budget/domain/entities/budget_period.dart';
import 'package:saldough/features/budget/domain/entities/budget_template.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_bloc.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_template_bloc.dart';
import 'package:saldough/features/budget/presentation/bloc/budget_template_state.dart';
import 'package:saldough/features/budget/presentation/budget_actions.dart';
import 'package:saldough/features/budget/presentation/widgets/budget_template_form_sheet.dart';
import 'package:saldough/features/premium/presentation/navigation/premium_route_keys.dart';
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

  /// Gratis: template ke-2 dan seterusnya (termasuk gandakan) membuka paywall;
  /// yang sudah ada tetap dipakai (ADR-041 §3.8). Semua template dihitung.
  bool _limited(BudgetTemplateBloc bloc) =>
      !ActivePlan.isPlus && bloc.state.templates.length >= ActivePlan.limits.value.freeBudgetTemplates;

  Future<void> _paywall() =>
      context.pushRoute(PremiumRouteKeys.paywall, const PaywallInput(PaywallTrigger.templateLimit));

  Future<void> _add() async {
    final bloc = context.read<BudgetTemplateBloc>();
    if (_limited(bloc)) {
      await _paywall();
      return;
    }
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
        final ds = context.ds;
        final c = ds.colors;
        final canUse = context.read<BudgetBloc>().state.activeWallets.isNotEmpty;
        return Scaffold(
          appBar: AppBar(title: Text(t.budget.templatesTitle, style: ds.typography.headlineMd), centerTitle: false),
          body: SafeArea(
            child: switch (state) {
              BudgetTemplateState(isLoading: true) => const AppSkeletonPage(),
              BudgetTemplateState(loadFailed: true) => _LoadError(
                onRetry: () => context.read<BudgetTemplateBloc>().add(const BudgetTemplatesStarted()),
              ),
              _ => ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                children: [
                  DsCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DsIconTile.asset(asset: ClayIcons.clipboard, size: DsIconTileSize.sm),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(t.budget.templatesInfoTitle, style: ds.typography.titleMd),
                                  DsBadge(
                                    label: t.budget.templatesSavedBadge(count: state.templates.length),
                                    tone: DsBadgeTone.neutral,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t.budget.templatesInfoBody,
                                style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                        onDuplicate: () {
                          final bloc = context.read<BudgetTemplateBloc>();
                          if (_limited(bloc)) {
                            unawaited(_paywall());
                          } else {
                            bloc.add(BudgetTemplateDuplicated(template));
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  if (!canUse) ...[
                    Text(
                      t.budget.templateNeedsWallet,
                      textAlign: TextAlign.center,
                      style: ds.typography.bodySm.copyWith(color: c.warning),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (state.templates.isNotEmpty)
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        DsButton.secondary(label: t.budget.templateAddAction, expand: true, onPressed: _add),
                        PositionedDirectional(
                          top: -8,
                          end: 12,
                          child: IgnorePointer(
                            child: PlusBadge(when: () => _limited(context.read<BudgetTemplateBloc>())),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    t.budget.templatesFooter,
                    textAlign: TextAlign.center,
                    style: ds.typography.bodySm.copyWith(color: c.textSecondary),
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
    final ds = context.ds;
    final c = ds.colors;
    final enabled = template.isEnabled;
    return Opacity(
      opacity: enabled ? 1 : 0.7,
      child: DsCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                DsIconTile.asset(asset: ClayIcons.clipboard, size: DsIconTileSize.sm),
                const SizedBox(width: 12),
                Expanded(child: Text(template.name, style: ds.typography.titleMd.copyWith(fontSize: 18))),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                DsBadge(
                  label: t.budget.templateItemCount(count: template.items.length),
                  tone: DsBadgeTone.neutral,
                ),
                if (!enabled) DsBadge(label: t.budget.templateInactiveBadge, tone: DsBadgeTone.warning),
                if (template.schedule case final schedule? when schedule.isActive)
                  DsBadge(
                    label: switch (schedule.period) {
                      BudgetPeriod.monthly => t.budget.templateScheduledMonthly(wallet: walletName ?? '—'),
                      BudgetPeriod.weekly => t.budget.templateScheduledWeekly(wallet: walletName ?? '—'),
                    },
                    tone: DsBadgeTone.income,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.budget.templateItemsLabel, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                    const SizedBox(height: 4),
                    Text(template.items.map((item) => item.name).join(' · '), style: ds.typography.bodyMd),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(t.budget.templateTotalLabel, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                const SizedBox(width: 8),
                // `Expanded` + rata kanan: nominal menempel ke tepi kanan dan
                // mengecil kalau tidak muat, bukan berhenti di tengah.
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(
                      AppMoneyFormatter.format(template.plannedAmount),
                      style: ds.typography.amount.copyWith(fontSize: 22, height: 28 / 22),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DsButton(label: t.budget.templateUseAction, expand: true, onPressed: enabled && canUse ? onUse : null),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: DsButton.secondary(label: t.budget.templateEditAction, expand: true, onPressed: onEdit),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DsButton.secondary(
                    label: t.budget.templateDuplicateAction,
                    expand: true,
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
    final ds = context.ds;
    return DsCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          DsBadge(label: t.budget.templatesEmptyBadge, tone: DsBadgeTone.warning),
          const SizedBox(height: 16),
          DsIconTile.asset(asset: ClayIcons.clipboard, size: DsIconTileSize.lg),
          const SizedBox(height: 12),
          Text(t.budget.templatesEmptyTitle, textAlign: TextAlign.center, style: ds.typography.titleMd),
          const SizedBox(height: 4),
          Text(
            t.budget.templatesEmptyBody,
            textAlign: TextAlign.center,
            style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
          ),
          const SizedBox(height: 20),
          DsButton(label: t.budget.templateAddAction, expand: true, onPressed: onAdd),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) =>
      DsErrorState(title: t.budget.templatesLoadError, retryLabel: t.common.retry, onRetry: onRetry);
}
