import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/account/presentation/bloc/category_manager_bloc.dart';
import 'package:saldough/features/account/presentation/bloc/category_manager_state.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';
import 'package:state_management/state_management.dart';

/// Membuka layar Kategori dengan [bloc] milik `AccountScope` yang sedang
/// terbuka (layar ini hanya dibuka dari layar Akun).
Future<void> openCategoryPage(BuildContext context, CategoryManagerBloc bloc) {
  bloc.add(const CategoryManagerStarted());
  return Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const EffectListener<CategoryManagerBloc, CategoryManagerState>(child: CategoryPage()),
      ),
    ),
  );
}

/// Layar Kategori (ADR-026 §3.6): kategori pengeluaran dan pemasukan, tambah,
/// ubah nama dan ikon (ketuk, QA PR #43 F12), arsipkan dan pulihkan. Tidak ada hapus — transaksi lama
/// tetap menunjuk kategorinya.
class CategoryPage extends StatefulWidget {
  /// Membuat [CategoryPage].
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  CategoryKind _kind = CategoryKind.expense;

  Future<void> _add(BuildContext context) async {
    final bloc = context.read<CategoryManagerBloc>();
    final result = await showCategoryFormSheet(context, title: t.category.addTitle);
    if (result != null) bloc.add(CategoryManagerAdded(kind: _kind, name: result.name, iconKey: result.icon?.name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.category.title, style: context.ds.typography.headlineMd), centerTitle: false),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: DsButton(label: t.category.addAction, expand: true, icon: Icons.add, onPressed: () => _add(context)),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<CategoryManagerBloc, CategoryManagerState>(
          builder: (context, state) {
            final lists = state.ofKind(_kind);
            final ds = context.ds;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DsSegmentedPill<CategoryKind>(
                  segments: [
                    DsSegment(value: CategoryKind.expense, label: t.category.expenseTab),
                    DsSegment(value: CategoryKind.income, label: t.category.incomeTab),
                  ],
                  selected: _kind,
                  onChanged: (kind) => setState(() => _kind = kind),
                ),
                const SizedBox(height: 16),
                if (!state.isLoading && lists.active.isEmpty)
                  DsCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        DsIconTile.asset(asset: ClayIcons.emptyTray, size: DsIconTileSize.lg),
                        const SizedBox(height: 10),
                        Text(
                          t.category.emptyActive,
                          textAlign: TextAlign.center,
                          style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
                        ),
                      ],
                    ),
                  )
                else if (lists.active.isNotEmpty)
                  DsListCard(children: [for (final category in lists.active) _CategoryRow(category: category)]),
                if (lists.archived.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  DsSectionHeader(title: t.category.archivedSection),
                  const SizedBox(height: 4),
                  Text(
                    t.category.archivedHint,
                    style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  DsListCard(children: [for (final category in lists.archived) _CategoryRow(category: category)]),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.category});

  final Category category;

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<CategoryManagerBloc>();
    final current = categoryIcon(category);
    final result = await showCategoryFormSheet(
      context,
      title: t.category.renameTitle,
      initialName: category.name,
      icon: current,
    );
    if (result == null) return;
    final icon = result.icon;
    final iconChanged = icon != null && icon != current;
    if (result.name == category.name && !iconChanged) return;
    bloc.add(
      CategoryManagerRenamed(
        category: category,
        name: result.name,
        iconKey: iconChanged ? categoryIconKeyFor(category, icon) : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final icon = categoryIcon(category);
    final clay = ClayIcons.forIcon(icon);
    return Opacity(
      opacity: category.isArchived ? 0.65 : 1,
      child: DsPressable(
        onPressed: () => _edit(context),
        semanticLabel: category.name,
        pressedScale: 0.995,
        dimWhenDisabled: false,
        builder: (context, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              if (clay != null) DsIconTile.asset(asset: clay) else AppIconTile(icon),
              const SizedBox(width: 12),
              Expanded(
                child: Text(category.name, style: ds.typography.titleMd.copyWith(fontSize: 14, color: c.textPrimary)),
              ),
              DsButton.ghost(
                label: category.isArchived ? t.category.restoreAction : t.category.archiveAction,
                onPressed: () => context.read<CategoryManagerBloc>().add(CategoryManagerArchiveToggled(category)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
