import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/transaction_kind.dart';
import 'package:saldough/core/theme/theme.dart';

/// Sub-tab navigasi di bawah app bar (PLAN_TAB_LAYOUT §3.2, KT-L7): lebar
/// penuh, label kapital, label aktif bertinta `textPrimary` dengan blok
/// `accent` 4px di bawahnya, label lain `textMuted`, tanpa slab dan tanpa
/// bayangan.
///
/// Rupa ini sengaja berbeda dari `AppSegmentedControl` (pilih nilai di formulir)
/// dan chip penyaring, supaya "pindah tempat" tidak tertukar dengan "pilih"
/// atau "saring". Pindah hanya lewat ketukan; tidak ada geser (§3.3).
class AppSubTabs<T> extends StatelessWidget implements PreferredSizeWidget {
  /// Membuat [AppSubTabs].
  const AppSubTabs({required this.options, required this.selected, required this.onChanged, super.key});

  /// Pilihan beserta labelnya, sesuai urutan.
  final List<(T, String)> options;

  /// Pilihan aktif.
  final T selected;

  /// Dipanggil dengan pilihan baru.
  final ValueChanged<T> onChanged;

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // Tinggi tetap: `AppBar.bottom` tidak membatasi tinggi, dan label yang
    // membesar (skala teks) dikecilkan `FittedBox`, bukan menambah tinggi.
    return SizedBox(
      height: preferredSize.height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (value, label) in options)
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                child: GestureDetector(
                  onTap: () => onChanged(value),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1, vertical: AppSpacing.space2),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label.toUpperCase(),
                            maxLines: 1,
                            style: labelSmStyle(
                              context,
                              color: value == selected ? colors.ink : colors.ink2,
                            ).copyWith(fontSize: 12),
                          ),
                        ),
                      ),
                      Container(height: 4, color: value == selected ? colors.brand : Colors.transparent),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
