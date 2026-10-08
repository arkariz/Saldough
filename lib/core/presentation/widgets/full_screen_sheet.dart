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
    builder: builder,
  );
}

/// Bentuk lembar setinggi layar -- dipakai juga rute lembar
/// (`RouteNodeRouteExt`, ADR-030 §3.3) supaya keduanya identik.
const fullScreenSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
);
