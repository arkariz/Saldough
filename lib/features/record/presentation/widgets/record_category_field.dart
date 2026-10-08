import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';

/// Nilai internal item "Tambah kategori" di menu -- BUKAN id kategori, hanya
/// penanda untuk membuka dialog nama. Memuat karakter kontrol supaya mustahil
/// bertabrakan dengan id kategori.
const _addSentinel = '\u0000add';

/// Pemilih kategori lewat dropdown [AppMenuSelectButton] -- tombol dan menu
/// yang sama dengan penyaring kategori di layar Transaksi (ADR-026 §3.6).
///
/// Pilihannya kategori aktif berjenis [categoryKind] ([frequentIds] di atas),
/// "Tanpa kategori" (kategori opsional), dan -- kalau [onCreate] diberikan --
/// "Tambah kategori" yang membuat kategori baru lalu langsung memilihnya.
/// Kategori terarsip yang sedang terpilih (menyunting transaksi lama) tetap
/// tampil di tombol, tetapi tidak ditawarkan di menu.
class RecordCategoryField extends StatelessWidget {
  /// Membuat [RecordCategoryField].
  const RecordCategoryField({
    required this.value,
    required this.onChanged,
    required this.categoryKind,
    this.frequentIds = const [],
    this.onCreate,
    super.key,
  });

  /// Id kategori terpilih, atau `null`.
  final String? value;

  /// Dipanggil dengan id kategori baru (atau `null` untuk "Tanpa kategori").
  final ValueChanged<String?> onChanged;

  /// Jenis kategori yang ditawarkan.
  final CategoryKind categoryKind;

  /// Id kategori yang paling sering dipakai, ditawarkan paling atas (UX-3).
  final List<String> frequentIds;

  /// Membuat kategori bernama tertentu; `null` berarti tanpa "Tambah kategori".
  final Future<Category?> Function(String name)? onCreate;

  Future<void> _onSelected(BuildContext context, String? selected) async {
    if (selected != _addSentinel) {
      onChanged(selected);
      return;
    }
    final create = onCreate;
    if (create == null) return;
    final name = await showCategoryNameDialog(context, title: t.category.addTitle);
    if (name == null) return;
    final created = await create(name);
    if (created != null) onChanged(created.id);
  }

  @override
  Widget build(BuildContext context) {
    final selected = ActiveCategories.byId(value);
    final options = ActiveCategories.selectable(categoryKind, frequentIds: frequentIds);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionLabel(t.record.categorySectionLabel, hint: t.record.optionalHint),
        const SizedBox(height: AppSpacing.space1),
        AppMenuSelectButton<String>(
          icon: selected != null ? categoryIcon(selected) : IconKey.categoryOther,
          label: selected?.name ?? t.record.categoryPlaceholder,
          isPlaceholder: selected == null,
          wrapLabel: true,
          allLabel: t.record.categoryNoneLabel,
          allIcon: IconKey.close,
          options: [
            for (final category in options) (value: category.id, label: category.name, icon: categoryIcon(category)),
            if (onCreate != null) (value: _addSentinel, label: t.record.categoryAddLabel, icon: IconKey.add),
          ],
          onSelected: (selected) => _onSelected(context, selected),
        ),
      ],
    );
  }
}
