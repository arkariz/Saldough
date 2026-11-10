import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/account/presentation/widgets/appearance_setting.dart';

/// Tile aksi cepat **Warna** di Beranda: membuka lembar pilihan preset warna
/// yang sama dengan Akun › Tampilan. Disisipkan akar komposisi karena Beranda
/// tidak boleh mengimpor fitur Akun (ADR-030).
class AppearanceQuickAction extends StatelessWidget {
  /// Membuat [AppearanceQuickAction].
  const AppearanceQuickAction({super.key});

  @override
  Widget build(BuildContext context) => DsQuickActionTile(
    key: const ValueKey('home-action-appearance'),
    tile: DsIconTile.asset(asset: ClayIcons.palette),
    label: t.home.actionAppearance,
    onPressed: () => showAppearancePresetPicker(context),
  );
}
