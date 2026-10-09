import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Membuka lembar setinggi layar (di bawah bilah status): pemilih jenis dan
/// formulir CATAT, serta formulir dompet, tampil sebagai satu layar penuh
/// seperti rujukan visual, bukan lembar setengah tinggi. Satu fungsi bersama
/// supaya seluruh formulir bergaya lembar tampil identik.
///
/// Latar, `scrim`, dan bentuk lembar mengikuti komponen Sheet design system
/// (`radius-xl` di sudut atas, `surface`, ADR-034).
Future<T?> showFullScreenSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: fullScreenSheetShape,
    builder: (context) => SheetSafeArea(child: builder(context)),
  );
}

/// Membuka lembar modal biasa (design system Sheet). Satu-satunya jalan ke
/// `showModalBottomSheet` selain [showFullScreenSheet], supaya isi setiap
/// lembar dibungkus [SheetSafeArea] (dijaga
/// `test/architecture/sheet_safe_area_test.dart`).
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = false,
  bool useSafeArea = false,
  bool showDragHandle = false,
  ShapeBorder? shape,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    showDragHandle: showDragHandle,
    shape: shape,
    builder: (context) => SheetSafeArea(child: builder(context)),
  );
}

/// Isi lembar di atas navigasi sistem. `useSafeArea` lembar modal Flutter
/// sengaja tidak menjaga sisi bawah, jadi tanpa ini tombol di dasar lembar
/// tertutup bilah navigasi Android (edge-to-edge). Saat keyboard terbuka
/// jarak bawahnya nol, dan lembar yang sudah menggeser isinya sebesar
/// `viewInsets` tetap benar.
class SheetSafeArea extends StatelessWidget {
  /// Membuat [SheetSafeArea].
  const SheetSafeArea({required this.child, super.key});

  /// Isi lembar.
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(top: false, child: child);
}

/// Bentuk lembar setinggi layar -- dipakai juga rute lembar
/// (`RouteNodeRouteExt`, ADR-030 §3.3) supaya keduanya identik.
const fullScreenSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
);
