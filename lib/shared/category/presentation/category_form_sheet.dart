import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/category/presentation/category_display.dart';

/// Hasil formulir kategori: nama, dan ikon bila pengguna memilihnya
/// (`null` = tidak disentuh).
typedef CategoryFormResult = ({String name, IconKey? icon});

/// Membuka formulir kategori (QA PR #43 F12): nama dan pemilih ikon
/// [categoryIconChoices]. [icon] ikon yang sedang dipakai; tanpa [icon]
/// (kategori baru) ikon ditebak dari nama yang diketik sampai pengguna
/// memilih sendiri. `null` bila ditutup tanpa menyimpan.
Future<CategoryFormResult?> showCategoryFormSheet(
  BuildContext context, {
  required String title,
  String initialName = '',
  IconKey? icon,
}) {
  return showModalBottomSheet<CategoryFormResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _CategoryFormSheet(title: title, initialName: initialName, icon: icon),
  );
}

class _CategoryFormSheet extends StatefulWidget {
  const _CategoryFormSheet({required this.title, required this.initialName, required this.icon});

  final String title;
  final String initialName;
  final IconKey? icon;

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late final _controller = TextEditingController(text: widget.initialName);
  IconKey? _picked;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _name => _controller.text.trim();

  IconKey get _shown => _picked ?? widget.icon ?? categoryIconFor(_name);

  void _submit() {
    if (_name.isEmpty) return;
    Navigator.of(context).pop((name: _name, icon: _picked));
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final shown = _shown;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpacing.space4, 0, AppSpacing.space4, AppSpacing.space4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.title, textAlign: TextAlign.center, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.space4),
            Row(
              children: [
                AppIconTile(shown),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: TextField(
                    key: const ValueKey('category-form-name'),
                    controller: _controller,
                    autofocus: widget.initialName.isEmpty,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(hintText: t.category.nameHint),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
            AppSectionLabel(t.category.iconLabel),
            const SizedBox(height: AppSpacing.space2),
            Wrap(
              spacing: AppSpacing.space1,
              runSpacing: AppSpacing.space1,
              children: [
                for (final (i, icon) in categoryIconChoices.indexed)
                  Semantics(
                    button: true,
                    selected: icon == shown,
                    label: t.category.iconOption(n: i + 1),
                    onTap: () => setState(() => _picked = icon),
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: ValueKey('category-icon-${icon.name}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _picked = icon),
                      child: SizedBox.square(
                        dimension: AppSize.touch,
                        child: Center(child: AppIconTile(icon, selected: icon == shown)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.space6),
            AppButton(
              key: const ValueKey('category-form-save'),
              label: t.common.save,
              expand: true,
              onPressed: _name.isEmpty ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
