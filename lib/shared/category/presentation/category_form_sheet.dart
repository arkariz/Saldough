import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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
  return showAppSheet<CategoryFormResult>(
    context,
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

  /// Tile ikon kategori: clay bila ada, ikon lama bila belum.
  Widget _tile(IconKey icon, {required bool selected}) {
    final asset = ClayIcons.forIcon(icon);
    if (asset == null) return AppIconTile(icon, selected: selected);
    final c = context.ds.colors;
    return DsIconTile.asset(
      asset: asset,
      category: selected ? DsColorPair(c.actionPrimary, c.actionPrimary.withValues(alpha: 0.14)) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final shown = _shown;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(DsSpacing.md, 0, DsSpacing.md, DsSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(widget.title, textAlign: TextAlign.center, style: ds.typography.headlineSm),
            ),
            const SizedBox(height: DsSpacing.md),
            Row(
              children: [
                DsWiggle(trigger: shown.index, child: _tile(shown, selected: true)),
                const SizedBox(width: 12),
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
            const SizedBox(height: DsSpacing.md),
            Text(
              t.category.iconLabel,
              style: ds.typography.pixelCaption.copyWith(color: c.textMuted, fontSize: 10),
            ),
            const SizedBox(height: DsSpacing.sm),
            Wrap(
              spacing: 4,
              runSpacing: 4,
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
                        dimension: 48,
                        child: Center(child: _tile(icon, selected: icon == shown)),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: DsSpacing.lg),
            DsButton(
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
