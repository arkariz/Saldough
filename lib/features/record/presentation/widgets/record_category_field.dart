
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
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
            icon: IconKey.moreHorizontal,
            materialIcon: Icons.more_horiz,
            label: t.record.allCategories,
            selected: false,
            onTap: () => _openAll(context, options),
          ),
        ),
      ],
    );
  }
}

class _Option extends StatefulWidget {
  const _Option({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.materialIcon,
    super.key,
  });

  final IconKey icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  /// Ikon Material untuk pilihan non-kategori ("Semua kategori").
  final IconData? materialIcon;

  @override
  State<_Option> createState() => _OptionState();
}

class _OptionState extends State<_Option> with SingleTickerProviderStateMixin {
  /// Naik tiap ketukan dan tiap berpindah ke terpilih: memutar goyangan.
  int _wiggle = 0;

  /// Riak lingkaran dari ikon (acuan `leafRipple`, 0,55 dtk).
  late final AnimationController _ripple = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );

  @override
  void didUpdateWidget(_Option oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected && !oldWidget.selected) _play();
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  void _play() {
    _wiggle++;
    if (!DsMotion.reduced(context)) _ripple.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final selected = widget.selected;
    final asset = widget.materialIcon == null ? ClayIcons.forIcon(widget.icon) : null;
    // Warna terpilih mengikuti warna aksi preset (bukan hijau pemasukan).
    final accent = DsColorPair(c.actionPrimary, c.actionPrimary.withValues(alpha: 0.14));
    final Widget tile;
    if (widget.materialIcon != null) {
      tile = DsIconTile(icon: widget.materialIcon!);
    } else if (asset != null) {
      tile = DsIconTile.asset(asset: asset, category: selected ? accent : null);
    } else {
      tile = AppIconTile(widget.icon, selected: selected);
    }
    return Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(_play);
          widget.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          // Seluruh petak yang bergoyang (acuan `animate-wiggle`), bukan hanya ikon.
          child: DsWiggle(
            trigger: _wiggle,
            child: AnimatedContainer(
              duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.standard,
              clipBehavior: Clip.hardEdge,
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              decoration: BoxDecoration(
                color: selected ? c.actionPrimary.withValues(alpha: 0.08) : c.surfaceCard,
                borderRadius: DsRadius.lgAll,
                border: Border.all(color: selected ? c.actionPrimary.withValues(alpha: 0.5) : c.outlineSubtle),
              ),
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Riak melebar dari belakang ikon lalu menghilang.
                  Positioned(
                    top: 5,
                    child: IgnorePointer(
                      child: AnimatedBuilder(
                        animation: _ripple,
                        builder: (context, _) {
                          final t = _ripple.value;
                          if (t == 0 || t == 1) return const SizedBox(width: 38, height: 38);
                          return Opacity(
                            opacity: 0.8 * (1 - t),
                            child: Transform.scale(
                              scale: 0.2 + 2.4 * t,
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      c.actionPrimary.withValues(alpha: 0.45),
                                      c.actionPrimary.withValues(alpha: 0.1),
                                      c.actionPrimary.withValues(alpha: 0),
                                    ],
                                    stops: const [0, 0.7, 1],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      AnimatedScale(
                        scale: selected ? 1.05 : 1,
                        duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.standard,
                        child: tile,
                      ),
                      const SizedBox(height: 4),
                      _OptionLabel(
                        widget.label,
                        style: ds.typography.labelSm.copyWith(
                          fontSize: 10,
                          letterSpacing: 0,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? c.actionPrimary : c.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  if (selected)
                    Positioned(
                      top: 0,
                      right: 2,
                      child: Icon(Icons.eco, size: 10, color: c.actionPrimary),
                    ),
                ],
              ),
            ),
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

Widget _leadingFor(IconKey key) {
  final asset = ClayIcons.forIcon(key);
  return asset == null ? AppIconTile(key) : DsIconTile.asset(asset: asset);
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

/// Sheet pemilih kategori: judul di tengah, daftar baris berikon clay dengan
/// centang pada yang terpilih.
class _CategorySheet extends StatelessWidget {
  const _CategorySheet({required this.options, required this.selectedId, required this.canCreate});

  final List<Category> options;
  final String? selectedId;
  final bool canCreate;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(t.record.allCategories, textAlign: TextAlign.center, style: ds.typography.headlineSm),
        ),
        const SizedBox(height: 12),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: DsFieldGroup(
              children: [
                _CategoryRow(
                  title: t.record.categoryNoneLabel,
                  tile: _leadingFor(IconKey.categoryOther),
                  selected: selectedId == null,
                  onTap: () => Navigator.of(context).pop(const _PickCategory(null)),
                ),
                for (final category in options)
                  _CategoryRow(
                    key: ValueKey('category-sheet-${category.id}'),
                    title: category.name,
                    tile: _leadingFor(categoryIcon(category)),
                    selected: category.id == selectedId,
                    onTap: () => Navigator.of(context).pop(_PickCategory(category.id)),
                  ),
                if (canCreate)
                  _CategoryRow(
                    title: t.record.categoryAddLabel,
                    tile: const DsIconTile(icon: Icons.add),
                    selected: false,
                    onTap: () => Navigator.of(context).pop(const _PickCreate()),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.title,
    required this.tile,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String title;
  final Widget tile;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Semantics(
      button: true,
      selected: selected,
      child: DsPressable(
        onPressed: onTap,
        pressedScale: 0.995,
        dimWhenDisabled: false,
        builder: (context, _) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                tile,
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: ds.typography.bodyMd.copyWith(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                ),
                if (selected) Icon(Icons.check_circle, size: 22, color: c.actionPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
