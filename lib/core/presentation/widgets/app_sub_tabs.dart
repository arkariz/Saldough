import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Sub-tab navigasi di bawah app bar (PLAN_TAB_LAYOUT §3.2, KT-L7): lebar
/// penuh, label huruf biasa, label aktif `ink` dengan penanda `brand` 40×4
/// di bawahnya, label lain `ink2`.
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
    // Sub-tab prototipe Rencana (`rencana.css` `.tk-subtabs`): label `label`
    // huruf biasa, aktif `ink` dengan penanda `brand` 40×4 di tengah bawah,
    // garis `line` di bawah seluruh baris.
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: colors.line))),
      child: SizedBox(
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
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              label,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: value == selected ? colors.ink : colors.ink2,
                              ),
                            ),
                          ),
                        ),
                        if (value == selected)
                          Positioned(bottom: 0, child: Container(width: 40, height: 4, color: colors.brand)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
