import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/account/di/account_scope.dart';
import 'package:saldough/features/account/presentation/bloc/account_bloc.dart';
import 'package:saldough/features/account/presentation/bloc/account_state.dart';
import 'package:state_management/state_management.dart';

/// Membuka layar Akun sebagai layar penuh, lengkap dengan [AccountScope]
/// sendiri — pola yang sama seperti `openFreelanceOverview` (ADR-023).
///
/// Akun bukan tujuan navigasi bawah: identitas opsional, tidak ada
/// pencatatan inti yang membutuhkannya (aturan #8 CLAUDE.md).
Future<void> openAccountPage(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  final parentContainer = ScopeProvider.of(navigator.context);
  return navigator.push(
    MaterialPageRoute<void>(
      builder: (_) => PixelTheme(
        child: ScopeWidget<AccountScope>(
          create: () => AccountScope(parentContainer: parentContainer),
          builder: (context, scope) => BlocProvider.value(
            value: scope.container<AccountBloc>(),
            child: const EffectListener<AccountBloc, AccountState>(child: AccountPage()),
          ),
        ),
      ),
    ),
  );
}

/// Layar Akun (ADR-023): masuk dengan Google atau email/sandi, keluar, dan
/// hapus akun. Belum menampilkan data dompet/transaksi/anggaran apa pun —
/// murni identitas.
class AccountPage extends StatefulWidget {
  /// Membuat [AccountPage].
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _showEmailForm = false;

  @override
  void initState() {
    super.initState();
    context.read<AccountBloc>().add(const AccountStarted());
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.account.deleteConfirmTitle),
        content: Text(t.account.deleteConfirmBody),
        actions: [
          AppButton.tertiary(label: t.common.cancel, onPressed: () => Navigator.pop(dialogContext, false)),
          AppButton.secondary(
            label: t.account.deleteAction,
            textColor: context.appColors.expense,
            onPressed: () => Navigator.pop(dialogContext, true),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      if (!context.mounted) return;
      context.read<AccountBloc>().add(const AccountDeletionRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.account.title)),
      body: SafeArea(
        child: BlocBuilder<AccountBloc, AccountState>(
          builder: (context, state) {
            final user = state.user;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: user == null
                  ? _signedOutContent(context, state)
                  : _signedInContent(context, state, user.displayName ?? user.email ?? user.uid),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _signedOutContent(BuildContext context, AccountState state) {
    return [
      Text(t.account.signedOutBody, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: AppSpacing.lg),
      AppButton(
        label: t.account.googleSignInAction,
        onPressed: state.isBusy ? null : () => context.read<AccountBloc>().add(const AccountGoogleSignInRequested()),
      ),
      const SizedBox(height: AppSpacing.md),
      AppButton.tertiary(
        label: t.account.emailSignInToggle,
        onPressed: () => setState(() => _showEmailForm = !_showEmailForm),
      ),
      if (_showEmailForm) ...[
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: t.account.emailLabel),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: InputDecoration(labelText: t.account.passwordLabel),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: t.account.emailSignInAction,
          onPressed: state.isBusy
              ? null
              : () => context.read<AccountBloc>().add(
                    AccountEmailSignInRequested(email: _emailController.text.trim(), password: _passwordController.text),
                  ),
        ),
      ],
    ];
  }

  List<Widget> _signedInContent(BuildContext context, AccountState state, String label) {
    return [
      Text(label, style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: AppSpacing.lg),
      AppButton.secondary(
        label: t.account.signOutAction,
        onPressed: state.isBusy ? null : () => context.read<AccountBloc>().add(const AccountSignOutRequested()),
      ),
      const SizedBox(height: AppSpacing.md),
      AppButton.secondary(
        label: t.account.deleteAction,
        textColor: context.appColors.expense,
        onPressed: state.isBusy ? null : () => _confirmDelete(context),
      ),
    ];
  }
}
