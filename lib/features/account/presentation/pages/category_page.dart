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
      builder: (_) => PixelTheme(
        child: BlocProvider.value(
          value: bloc,
          child: const EffectListener<CategoryManagerBloc, CategoryManagerState>(child: CategoryPage()),
        ),
      ),
    ),
  );
}

/// Layar Kategori (ADR-026 §3.6): kategori pengeluaran dan pemasukan, tambah,
/// ganti nama (ketuk), arsipkan dan pulihkan. Tidak ada hapus — transaksi lama
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
    final name = await showCategoryNameDialog(context, title: t.category.addTitle);
    if (name != null) bloc.add(CategoryManagerAdded(kind: _kind, name: name));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.category.title)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: AppButton(label: t.category.addAction, onPressed: () => _add(context)),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<CategoryManagerBloc, CategoryManagerState>(
          builder: (context, state) {
            final lists = state.ofKind(_kind);
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AppSegmented<CategoryKind>(
                  options: [
                    (CategoryKind.expense, t.category.expenseTab),
                    (CategoryKind.income, t.category.incomeTab),
                  ],
                  selected: _kind,
                  onChanged: (kind) => setState(() => _kind = kind),
                ),
                const SizedBox(height: AppSpacing.md),
                if (!state.isLoading && lists.active.isEmpty) Text(t.category.emptyActive),
                for (final category in lists.active) _CategoryRow(category: category),
                if (lists.archived.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  AppSectionLabel(t.category.archivedSection),
                  const SizedBox(height: AppSpacing.xs),
                  Text(t.category.archivedHint, style: TextStyle(color: context.appColors.textMuted)),
                  const SizedBox(height: AppSpacing.xs),
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

  Future<void> _rename(BuildContext context) async {
    final bloc = context.read<CategoryManagerBloc>();
    final name = await showCategoryNameDialog(context, title: t.category.renameTitle, initial: category.name);
    if (name != null && name != category.name) bloc.add(CategoryManagerRenamed(category: category, name: name));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppTappable(
        label: category.name,
        onTap: () => _rename(context),
        child: AppHardCard(
          child: Row(
            children: [
              AppIcon(categoryIcon(category)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(color: category.isArchived ? colors.textMuted : colors.textPrimary),
                ),
              ),
              TextButton(
                onPressed: () => context.read<CategoryManagerBloc>().add(CategoryManagerArchiveToggled(category)),
                child: Text(category.isArchived ? t.category.restoreAction : t.category.archiveAction),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
