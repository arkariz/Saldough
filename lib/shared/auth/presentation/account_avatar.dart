import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/auth/auth.dart';

/// Avatar akun berbingkai pixel: foto Google kalau ada, inisial kalau tidak,
/// ikon akun kalau belum masuk.
class AccountAvatar extends StatelessWidget {
  /// Membuat [AccountAvatar].
  const AccountAvatar({required this.user, this.size = 40, super.key});

  /// Pengguna yang masuk, atau `null`.
  final AppUser? user;

  /// Sisi avatar dalam piksel logis.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = this.user;
    final initial = (user?.displayName ?? user?.email ?? '').trim();
    final fallback = user == null || initial.isEmpty
        ? AppIcon(IconKey.account, size: size * 0.55, color: colors.textMuted)
        : Text(
            initial.characters.first.toUpperCase(),
            style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.w700, color: colors.onAccent),
          );
    final photoUrl = user?.photoUrl;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: user == null ? colors.cardBackground : colors.accent,
        border: Border.all(color: colors.edge, width: 2),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      alignment: Alignment.center,
      child: photoUrl == null
          ? fallback
          : Image.network(
              photoUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
    );
  }
}

/// Tombol akun di app bar Beranda: ikon akun saat belum masuk, avatar saat
/// sudah masuk (ADR-024). Mendengarkan [AuthRepository] langsung dari
/// kontainer akar supaya Beranda tidak perlu tahu soal akun.
class AccountAvatarButton extends StatefulWidget {
  /// Membuat [AccountAvatarButton]; [onPressed] membuka layar Akun (milik
  /// fitur `account`, jadi disuntikkan pemakai lewat kunci rutenya).
  const AccountAvatarButton({required this.onPressed, super.key});

  /// Membuka layar Akun.
  final VoidCallback onPressed;

  @override
  State<AccountAvatarButton> createState() => _AccountAvatarButtonState();
}

class _AccountAvatarButtonState extends State<AccountAvatarButton> {
  late final AuthRepository _auth;
  late final Stream<AppUser?> _changes;

  @override
  void initState() {
    super.initState();
    final rootContext = Navigator.of(context, rootNavigator: true).context;
    _auth = ScopeProvider.of(rootContext)<AuthRepository>();
    _changes = _auth.authStateChanges();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: _changes,
      initialData: _auth.currentUser,
      builder: (context, snapshot) {
        final user = snapshot.data;
        return IconButton(
          tooltip: t.account.title,
          onPressed: widget.onPressed,
          icon: user == null ? const AppIcon(IconKey.account) : AccountAvatar(user: user, size: 28),
        );
      },
    );
  }
}
