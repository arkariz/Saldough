import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/shared/auth/auth.dart';

/// Avatar akun bulat: foto Google kalau ada, inisial kalau tidak, ikon akun
/// maskot tanuki clay yang tidur kalau belum masuk.
class AccountAvatar extends StatelessWidget {
  /// Membuat [AccountAvatar].
  const AccountAvatar({required this.user, this.size = 40, super.key});

  /// Pengguna yang masuk, atau `null`.
  final AppUser? user;

  /// Sisi avatar dalam piksel logis.
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final user = this.user;
    final initial = (user?.displayName ?? user?.email ?? '').trim();
    final fallback = user == null || initial.isEmpty
        ? SvgPicture.asset(ClayIcons.mascotSleeping, width: size * 0.78, height: size * 0.78)
        : Text(
            initial.characters.first.toUpperCase(),
            style: TextStyle(fontSize: size * 0.45, fontWeight: FontWeight.w700, color: c.onActionPrimary),
          );
    final photoUrl = user?.photoUrl;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: user == null || initial.isEmpty ? c.surfaceSunken : c.actionPrimary,
        border: Border.all(color: c.outlineSubtle),
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

/// Tombol akun di app bar Beranda: maskot saat belum masuk, avatar saat
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
        return Tooltip(
          message: t.account.title,
          child: DsPressable(
            onPressed: widget.onPressed,
            semanticLabel: t.account.title,
            builder: (context, _) => SizedBox.square(
              dimension: DsSpacing.minTapTarget,
              child: Center(child: AccountAvatar(user: user, size: 32)),
            ),
          ),
        );
      },
    );
  }
}

/// Membangun anak dari pengguna yang sedang masuk (atau `null`), mengikuti
/// perubahan status masuk. Dipakai Beranda untuk sapaan bernama tanpa tahu
/// soal akun ([AccountAvatarButton] memakai sumber yang sama).
class AccountUserBuilder extends StatefulWidget {
  /// Membuat [AccountUserBuilder].
  const AccountUserBuilder({required this.builder, super.key});

  /// Membangun anak dari [user].
  final Widget Function(BuildContext context, AppUser? user) builder;

  @override
  State<AccountUserBuilder> createState() => _AccountUserBuilderState();
}

class _AccountUserBuilderState extends State<AccountUserBuilder> {
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
      builder: (context, snapshot) => widget.builder(context, snapshot.data),
    );
  }
}
