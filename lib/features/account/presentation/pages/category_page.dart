import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
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
      appBar: AppBar(title: Text(t.category.title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space2, AppSpacing.space4, AppSpacing.space4),
          child: AppButton(label: t.category.addAction, onPressed: () => _add(context)),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<CategoryManagerBloc, CategoryManagerState>(
          builder: (context, state) {
            final lists = state.ofKind(_kind);
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                AppSegmentedControl<CategoryKind>(
                  options: [
                    (CategoryKind.expense, t.category.expenseTab),
                    (CategoryKind.income, t.category.incomeTab),
                  ],
                  selected: _kind,
                  onChanged: (kind) => setState(() => _kind = kind),
                ),
                const SizedBox(height: AppSpacing.space4),
                if (!state.isLoading && lists.active.isEmpty) Text(t.category.emptyActive),
                for (final category in lists.active) _CategoryRow(category: category),
                if (lists.archived.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space6),
                  AppSectionLabel(t.category.archivedSection),
                  const SizedBox(height: AppSpacing.space1),
                  Text(t.category.archivedHint, style: TextStyle(color: context.appColors.ink2)),
                  const SizedBox(height: AppSpacing.space1),
                  for (final category in lists.archived) _CategoryRow(category: category),
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
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: AppTappable(
        label: category.name,
        onTap: () => _edit(context),
        child: AppCard(
          child: Row(
            children: [
              AppIconTile(categoryIcon(category)),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(color: category.isArchived ? colors.ink2 : colors.ink),
                ),
              ),
              AppButton.text(small: true, label: category.isArchived ? t.category.restoreAction : t.category.archiveAction, onPressed: () => context.read<CategoryManagerBloc>().add(CategoryManagerArchiveToggled(category))),
            ],
          ),
        ),
      ),
    );
  }
}
