import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/foundation/review/review_service.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/account/presentation/widgets/setting_row.dart';
import 'package:url_launcher/url_launcher.dart';

/// Halaman Tanukonomy di aplikasi Play Store (pembuka langsung).
final Uri playStoreAppUri = Uri.parse('market://details?id=com.arkarizdev.tanukonomy');

/// Halaman Tanukonomy di peramban, cadangan bila Play Store tidak bisa dibuka.
final Uri playStoreWebUri = Uri.parse('https://play.google.com/store/apps/details?id=com.arkarizdev.tanukonomy');

/// Membuka halaman toko: aplikasi Play Store dulu, lalu peramban. `false`
/// bila keduanya gagal.
Future<bool> openPlayStorePage() async {
  for (final uri in [playStoreAppUri, playStoreWebUri]) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
    } on Object {
      // Coba alamat berikutnya.
    }
  }
  return false;
}

/// Meminta ulasan: lembar Play dalam aplikasi dulu, jatuh ke halaman toko
/// bila tidak tersedia atau tidak ditampilkan (jatah Play habis).
Future<bool> requestReviewOrOpenStore() => ReviewPrompt.requestFromUser(openStore: openPlayStorePage);

/// Baris "Beri nilai di Play Store" di Akun. Hanya dipasang di Android.
/// Memakai `in_app_review` (plugin native: perlu rilis toko, tidak bisa lewat
/// pembaruan kecil Shorebird).
class RateAppSettingEntry extends StatelessWidget {
  /// Membuat [RateAppSettingEntry].
  const RateAppSettingEntry({this.opener = requestReviewOrOpenStore, super.key});

  /// Pembuka ulasan/toko; diganti saat uji.
  final Future<bool> Function() opener;

  Future<void> _open(BuildContext context) async {
    AppAnalytics.log(ActivationEvents.rateAppTapped);
    final messenger = ScaffoldMessenger.of(context);
    final opened = await opener();
    if (opened) return;
    messenger.showAppSnackBar(SnackBar(content: Text(t.account.rateApp.openFailed)));
  }

  @override
  Widget build(BuildContext context) => SettingRow(
    icon: IconKey.openInNew,
    title: t.account.rateApp.title,
    subtitle: t.account.rateApp.body,
    onTap: () => _open(context),
  );
}
