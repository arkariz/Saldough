import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/presentation/widgets/full_screen_sheet.dart';

/// Satu pilihan [showOptionSheet].
@immutable
class OptionSheetItem<T> {
  /// Membuat pilihan; [key] dipasang di barisnya (untuk uji).
  const OptionSheetItem({required this.value, required this.label, this.detail, this.leading, this.key});

  /// Nilai yang dikembalikan.
  final T value;

  /// Teks pilihan.
  final String label;

  /// Keterangan kecil di bawah teks.
  final String? detail;

  /// Ikon atau penanda di depan teks.
  final Widget? leading;

  /// Kunci baris pilihan.
  final Key? key;
}

/// Lembar pilihan satu dari beberapa (menggantikan `SimpleDialog` bawaan):
/// judul, baris pilihan bergaya v2 dengan tanda centang di yang aktif.
/// Mengembalikan nilai yang diketuk, atau `null` bila ditutup.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<OptionSheetItem<T>> options,
  required T? current,
  String? subtitle,
}) => showAppSheet<T>(
  context,
  isScrollControlled: true,
  builder: (sheetContext) => _OptionSheet<T>(title: title, subtitle: subtitle, options: options, current: current),
);

class _OptionSheet<T> extends StatelessWidget {
  const _OptionSheet({required this.title, required this.options, required this.current, this.subtitle});

  final String title;
  final String? subtitle;
  final List<OptionSheetItem<T>> options;
  final T? current;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: ds.typography.headlineMd.copyWith(fontSize: 20)),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
          ],
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final option in options) ...[
                    _Row<T>(option: option, selected: option.value == current),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row<T> extends StatelessWidget {
  const _Row({required this.option, required this.selected});

  final OptionSheetItem<T> option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      child: DsPressable(
        key: option.key,
        semanticLabel: option.label,
        onPressed: () => Navigator.of(context).pop(option.value),
        builder: (context, _) => AnimatedContainer(
          duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.standard,
          constraints: const BoxConstraints(minHeight: 56),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.actionPrimary.withValues(alpha: 0.06) : c.surfaceCard,
            borderRadius: DsRadius.lgAll,
            border: Border.all(color: selected ? c.actionPrimary : c.outlineSubtle, width: selected ? 2 : 1),
          ),
          child: Row(
            children: [
              if (option.leading != null) ...[option.leading!, const SizedBox(width: 12)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label, style: ds.typography.titleMd.copyWith(fontSize: 15)),
                    if (option.detail != null)
                      Text(option.detail!, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              if (selected) Icon(Icons.check_circle, color: c.actionPrimary),
            ],
          ),
        ),
      ),
    );
  }
}
