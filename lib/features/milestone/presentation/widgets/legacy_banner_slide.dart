import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';

/// Id slide banner pengguna lama di papan status Beranda.
const legacyBannerStatusId = 'milestone_intro';

/// Banner pengguna lama (rupa buku-stempel §4.3, G-6): sekali, di papan status
/// Beranda. [onSee] membuka Buku Stempel dan [onDismiss] menutup; keduanya
/// menandai pengenalan selesai di pemanggil. Tidak ada perayaan satu per satu.
DsStatusSlideData legacyBannerSlide({required VoidCallback onSee, required VoidCallback onDismiss}) {
  final texts = t.stamps.legacyBanner;
  return DsStatusSlideData(
    id: legacyBannerStatusId,
    icon: Icons.verified_outlined,
    title: texts.eyebrow,
    subtitle: texts.body,
    actionLabel: texts.action,
    onAction: onSee,
    dismissLabel: texts.dismiss,
    onDismiss: onDismiss,
    order: 5,
  );
}
