import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';

/// Pemilih kategori Catat (prototipe `Catat.dc.html`, `cat-pick`): petak
/// berisi kategori teratas ([frequentIds] di depan) dengan tile ikonnya, dan
/// "Semua kategori" yang membuka sheet daftar lengkap
/// (design system Sheet pemilih) berisi "Tanpa kategori" dan -- kalau
/// [onCreate] diberikan -- "Tambah kategori".
///
/// Jumlah kolom mengikuti lebar ([columnsFor]): empat di layar 360–430dp,
/// lima di layar lebar, supaya label seperti "Transportasi" tidak pernah
/// dipotong di tengah kata (QA PR #43 F3). Kategori terpilih yang tidak
/// termasuk yang teratas ikut tampil, menggantikan yang terakhir. Kategori
/// terarsip yang terpilih (menyunting transaksi lama) tetap tampil, tetapi
/// tidak ditawarkan di sheet.
class RecordCategoryField extends StatelessWidget {
  /// Membuat [RecordCategoryField].
  const RecordCategoryField({
    required this.value,
    required this.onChanged,
    required this.categoryKind,
    this.frequentIds = const [],
    this.onCreate,
    this.title,
    super.key,
  });

  /// Id kategori terpilih, atau `null`.
  final String? value;

  /// Dipanggil dengan id kategori baru (atau `null` untuk "Tanpa kategori").
  final ValueChanged<String?> onChanged;

  /// Jenis kategori yang ditawarkan.
  final CategoryKind categoryKind;

  /// Id kategori yang paling sering dipakai, ditawarkan paling depan (UX-3).
  final List<String> frequentIds;

  /// Membuat kategori bernama tertentu dengan ikon pilihan (`null` = ditebak
  /// dari nama); `null` berarti tanpa "Tambah kategori".
  final Future<Category?> Function(String name, String? iconKey)? onCreate;

  /// Judul transaksi (catatan), memilih varian ikon ("kopi").
  final String? title;

  /// Lebar minimum satu kolom petak.
  static const minColumnWidth = 80.0;

  /// Jumlah kolom petak (termasuk "Semua kategori") untuk lebar [width].
  static int columnsFor(double width) => (width / minColumnWidth).floor().clamp(4, 5);

  Future<void> _create(BuildContext context) async {
    final create = onCreate;
    if (create == null) return;
    // Formulir yang sama dengan layar Kategori: nama dan ikon.
    final result = await showCategoryFormSheet(context, title: t.category.addTitle);
    if (result == null) return;
    final created = await create(result.name, result.icon?.name);
    if (created != null) onChanged(created.id);
  }

  Future<void> _openAll(BuildContext context, List<Category> options) async {
    final picked = await showAppSheet<_Pick>(
      context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => _CategorySheet(
        options: options,
        selectedId: value,
        canCreate: onCreate != null,
      ),
    );
    if (picked == null || !context.mounted) return;
    switch (picked) {
      case _PickCategory(:final id):
        onChanged(id);
      case _PickCreate():
        await _create(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = ActiveCategories.byId(value);
    final options = ActiveCategories.selectable(
      categoryKind,
      frequentIds: frequentIds,
    );
    return Semantics(
      container: true,
      label: t.record.categorySectionLabel,
      child: LayoutBuilder(builder: (context, constraints) => _grid(context, options, selected, constraints.maxWidth)),
    );
  }

  Widget _grid(BuildContext context, List<Category> options, Category? selected, double width) {
    final visibleCount = columnsFor(width) - 1;
    final visible = options.take(visibleCount).toList();
    if (selected != null && !visible.any((c) => c.id == selected.id)) {
      if (visible.length == visibleCount) visible.removeLast();
      visible.insert(0, selected);
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < visibleCount; i++)
          Expanded(
            child: i < visible.length
                ? _Option(
                    key: ValueKey('category-${visible[i].id}'),
                    icon: categoryIcon(visible[i], title: title),
                    label: visible[i].name,
                    selected: visible[i].id == value,
                    // Ketuk lagi yang terpilih: kembali tanpa kategori.
                    onTap: () => onChanged(
                      visible[i].id == value ? null : visible[i].id,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        Expanded(
          child: _Option(
            key: const ValueKey('category-all'),
            icon: IconKey.categoryOther,
            label: t.record.allCategories,
            selected: false,
            onTap: () => _openAll(context, options),
          ),
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final IconKey icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.space1,
            horizontal: 2,
          ),
          child: Column(
            children: [
              AppIconTile(icon, size: 44, selected: selected),
              const SizedBox(height: AppSpacing.space1),
              _OptionLabel(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: selected ? colors.ink : colors.ink2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label petak: paling banyak dua baris, dibungkus di antara kata. Kata yang
/// lebih lebar dari petak (nama buatan pengguna, teks diperbesar) tidak
/// dipecah di tengah: labelnya satu baris berelipsis.
class _OptionLabel extends StatelessWidget {
  const _OptionLabel(this.label, {required this.style});

  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wordTooWide = label.split(RegExp(r'\s+')).any((word) {
          final painter = TextPainter(
            text: TextSpan(text: word, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          final tooWide = painter.width > constraints.maxWidth;
          painter.dispose();
          return tooWide;
        });
        return Text(
          label,
          maxLines: wordTooWide ? 1 : 2,
          softWrap: !wordTooWide,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: style,
        );
      },
    );
  }
}

sealed class _Pick {
  const _Pick();
}

final class _PickCategory extends _Pick {
  const _PickCategory(this.id);

  final String? id;
}

final class _PickCreate extends _Pick {
  const _PickCreate();
}

/// Sheet pemilih kategori (design system Sheet, varian pemilih): judul di
/// tengah, daftar baris dengan centang pada yang terpilih.
class _CategorySheet extends StatelessWidget {
  const _CategorySheet({
    required this.options,
    required this.selectedId,
    required this.canCreate,
  });

  final List<Category> options;
  final String? selectedId;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget check({required bool on}) =>
        on ? AppIcon(IconKey.check, color: colors.brand) : const SizedBox(width: AppSize.icon);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          t.record.allCategories,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.space2),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              AppListRow(
                title: t.record.categoryNoneLabel,
                leading: const AppIconTile(IconKey.categoryOther),
                trailing: check(on: selectedId == null),
                onTap: () => Navigator.of(context).pop(const _PickCategory(null)),
              ),
              for (final category in options)
                AppListRow(
                  key: ValueKey('category-sheet-${category.id}'),
                  title: category.name,
                  leading: AppIconTile(categoryIcon(category)),
                  trailing: check(on: category.id == selectedId),
                  onTap: () => Navigator.of(context).pop(_PickCategory(category.id)),
                ),
              if (canCreate)
                AppListRow(
                  title: t.record.categoryAddLabel,
                  leading: const AppIconTile(IconKey.add, tint: TileTint.slate),
                  onTap: () => Navigator.of(context).pop(const _PickCreate()),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
