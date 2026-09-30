import 'package:flutter/material.dart';
import 'package:saldough/core/theme/theme.dart';

/// Membuka lembar setinggi layar (di bawah bilah status): pemilih jenis dan
/// formulir CATAT, serta formulir dompet, tampil sebagai satu layar penuh
/// seperti rujukan visual, bukan lembar setengah tinggi. Satu fungsi bersama
/// supaya seluruh formulir bergaya lembar tampil identik.
///
/// Latar dan warna lembar berasal dari `PixelTheme` (`bottomSheetTheme`);
/// hanya bentuknya yang ditimpa -- sudut atas bulat kecil (`AppRadius.sm`)
/// alih-alih 28px bawaan Material 3, sesuai radius pixel ADR-015.
Future<T?> showFullScreenSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: fullScreenSheetShape,
    builder: builder,
  );
}

/// Bentuk lembar setinggi layar -- dipakai juga rute lembar
/// (`RouteNodeRouteExt`, ADR-030 §3.3) supaya keduanya identik.
const fullScreenSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sm)),
);
