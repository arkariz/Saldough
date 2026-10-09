import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Bilah tindakan yang menempel di dasar layar (`tk-sticky-action`): latar
/// `surface`, garis atas 1px `line` (`shadow-bar`), jarak 12/16/16.
class AppStickyBar extends StatelessWidget {
  /// Membuat [AppStickyBar].
  const AppStickyBar({required this.child, super.key});

  /// Isi bilah, biasanya satu tombol `expand` atau baris tombol.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space3,
            AppSpacing.space4,
            AppSpacing.space4,
          ),
          child: child,
        ),
      ),
    );
  }
}
