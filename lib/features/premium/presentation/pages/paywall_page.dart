import 'package:flutter/material.dart';
import 'package:saldough/core/foundation/analytics/app_analytics.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/premium/domain/paywall_trigger.dart';

/// Paywall sementara (T-23.8) sampai rupa final ada (T-23.17): memberi tahu
/// bahwa fitur ini bagian dari Plus dan, untuk yang belum masuk akun,
/// mengajak masuk (Plus untuk penguji dan uji coba memerlukan akun, ADR-041
/// §3.4, §3.13). Tidak pernah mengubah data dan tidak menghalangi pencatatan.
///
/// Mencatat `paywall_viewed` saat dibuka dan `paywall_dismissed` saat ditutup
/// (belum ada pembelian dari halaman ini).
class PaywallPage extends StatefulWidget {
  /// Membuat [PaywallPage].
  const PaywallPage({required this.trigger, required this.signedIn, required this.onSignIn, super.key});

  /// Pemicu paywall, untuk analitik.
  final PaywallTrigger trigger;

  /// Pengguna sudah masuk akun.
  final bool signedIn;

  /// Membuka layar Akun untuk masuk.
  final VoidCallback onSignIn;

  @override
  State<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends State<PaywallPage> {
  @override
  void initState() {
    super.initState();
    AppAnalytics.log(PremiumEvents.paywallViewed(trigger: widget.trigger.analyticsName));
  }

  @override
  void dispose() {
    AppAnalytics.log(PremiumEvents.paywallDismissed(trigger: widget.trigger.analyticsName));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final texts = t.premium;
    final signedIn = widget.signedIn;
    return Scaffold(
      appBar: AppBar(title: Text(texts.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.space4),
          children: [
            AppEmptyState(
              title: signedIn ? texts.plusOnlyTitle : texts.signInTitle,
              body: signedIn ? texts.plusOnlyBody : texts.signInBody,
              actionLabel: signedIn ? null : texts.signInAction,
              onAction: signedIn ? null : widget.onSignIn,
            ),
          ],
        ),
      ),
    );
  }
}
