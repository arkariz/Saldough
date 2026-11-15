import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_action_snack_bar.dart';
import 'package:saldough/core/presentation/widgets/full_screen_sheet.dart';
import 'package:saldough/core/presentation/widgets/stamp_visuals.dart';

/// Snackbar perayaan (rupa buku-stempel §4.1, G-4): satu kalimat, segel kecil,
/// aksi Lihat. Satu stempel: "Stempel baru: nama"; beberapa digabung menjadi
/// "n stempel baru". Tenang: tanpa konfeti atau getar (gerak tampil mengikuti
/// snackbar v2). Hilang sendiri; menutupnya tidak mengubah apa pun.
SnackBar stampSnackBar(BuildContext context, {required List<String> ids, required VoidCallback onSee}) {
  final texts = t.stamps.snackbar;
  final message = ids.length == 1 ? texts.one(name: stampName(ids.first)) : texts.many(count: ids.length);
  final shown = ids.take(2).toList();
  return actionSnackBar(
    context,
    content: Row(
      children: [
        SizedBox(
          width: 34.0 + (shown.length - 1) * 22,
          height: 34,
          child: Stack(
            children: [
              for (var i = 0; i < shown.length; i++)
                Positioned(
                  left: i * 22.0,
                  child: DsStampSeal(
                    asset: stampAsset(shown[i]),
                    semanticLabel: stampName(shown[i]),
                    size: DsStampSealSize.sm,
                    rotation: stampRotation(shown[i]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(message)),
      ],
    ),
    action: SnackBarAction(label: texts.action, onPressed: onSee),
  );
}

/// Lembar pengenalan sekali, untuk stempel pertama sepanjang masa (rupa §4.2).
/// Menutupnya dengan cara apa pun menandai pengenalan selesai; stempel tidak
/// berubah. [onSettings] membuka Akun.
Future<void> showFirstStampSheet(BuildContext context, {required String id, required VoidCallback onSettings}) {
  return showAppSheet<void>(
    context,
    isScrollControlled: true,
    builder: (context) => _FirstStampSheet(
      id: id,
      onClose: () => Navigator.of(context).pop(),
      onSettings: () {
        Navigator.of(context).pop();
        onSettings();
      },
    ),
  );
}

class _FirstStampSheet extends StatelessWidget {
  const _FirstStampSheet({required this.id, required this.onClose, required this.onSettings});

  final String id;
  final VoidCallback onClose;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final texts = t.stamps.firstSheet;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DsStampSeal(
            asset: stampAsset(id),
            semanticLabel: stampName(id),
            size: DsStampSealSize.lg,
            rotation: stampRotation(id),
          ),
          const SizedBox(height: 12),
          Semantics(
            header: true,
            child: Text(texts.title, style: ds.typography.headlineSm, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 8),
          Text(
            texts.body,
            textAlign: TextAlign.center,
            style: ds.typography.bodyMd.copyWith(color: ds.colors.textSecondary),
          ),
          const SizedBox(height: 16),
          DsButton(label: texts.ok, onPressed: onClose, expand: true),
          const SizedBox(height: 4),
          DsButton.ghost(label: texts.settings, onPressed: onSettings, expand: true),
        ],
      ),
    );
  }
}
