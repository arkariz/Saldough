import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Paywall sementara (T-23.8) sampai rupa final ada (T-23.17): memberi tahu
/// bahwa fitur ini bagian dari Plus dan, untuk yang belum masuk akun,
/// mengajak masuk (Plus untuk penguji dan uji coba memerlukan akun, ADR-041
/// §3.4, §3.13). Tidak pernah mengubah data dan tidak menghalangi pencatatan.
class PaywallPage extends StatelessWidget {
  /// Membuat [PaywallPage].
  const PaywallPage({
    required this.signedIn,
    required this.onSignIn,
    super.key,
  });

  /// Pengguna sudah masuk akun.
  final bool signedIn;

  /// Membuka layar Akun untuk masuk.
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    final texts = t.premium;
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
              onAction: signedIn ? null : onSignIn,
            ),
          ],
        ),
      ),
    );
  }
}
