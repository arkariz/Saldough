import 'package:di/di.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/account/di/account_scope.dart';
import 'package:saldough/features/account/presentation/bloc/account_bloc.dart';
import 'package:saldough/features/account/presentation/bloc/account_state.dart';
import 'package:saldough/features/account/presentation/widgets/account_avatar.dart';
import 'package:saldough/features/account/presentation/widgets/currency_setting.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:state_management/state_management.dart';

/// Membuka layar Akun sebagai layar penuh, lengkap dengan [AccountScope]
/// sendiri — pola yang sama seperti `openFreelanceOverview` (ADR-023).
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

/// Layar Akun (ADR-023, ADR-024). Akun opsional: belum masuk menawarkan
/// Google (dan email/sandi khusus peninjau di balik tautan); sudah masuk
/// menampilkan profil, status data, keluar, dan zona bahaya hapus akun.
/// Keduanya memuat bagian "Pengaturan" (mata uang, ADR-025).
class AccountPage extends StatefulWidget {
  /// Membuat [AccountPage].
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  void initState() {
    super.initState();
    context.read<AccountBloc>().add(const AccountStarted());
  }

  Future<void> _promptPassword(BuildContext context) async {
    final password = await showDialog<String>(context: context, builder: (_) => const _PasswordDialog());
    if (password == null || password.isEmpty || !context.mounted) return;
    context.read<AccountBloc>().add(AccountDeletionRequested(password: password));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(t.account.title)),
      body: SafeArea(
        child: BlocListener<AccountBloc, AccountState>(
          listenWhen: (prev, curr) => !prev.needsPassword && curr.needsPassword,
          listener: (context, _) => _promptPassword(context),
          child: BlocBuilder<AccountBloc, AccountState>(
            builder: (context, state) {
              final user = state.user;
              return ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  if (user == null) _SignedOut(state: state) else _SignedIn(state: state, user: user),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

String _busyLabel(String label, AccountState state, AccountAction action) =>
    state.pending == action ? '$label…' : label;

class _SignedOut extends StatefulWidget {
  const _SignedOut({required this.state});

  final AccountState state;

  @override
  State<_SignedOut> createState() => _SignedOutState();
}

class _SignedOutState extends State<_SignedOut> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  var _showEmailForm = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitEmail() {
    if (widget.state.isBusy) return;
    context.read<AccountBloc>().add(
      AccountEmailSignInRequested(email: _emailController.text.trim(), password: _passwordController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppHardCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(child: AccountAvatar(user: null, size: 64)),
              const SizedBox(height: AppSpacing.md),
              Text(t.account.signedOutTitle, style: textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.sm),
              Text(t.account.signedOutBody, style: textTheme.bodyMedium, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _busyLabel(t.account.googleSignInAction, state, AccountAction.googleSignIn),
                onPressed: state.isBusy
                    ? null
                    : () => context.read<AccountBloc>().add(const AccountGoogleSignInRequested()),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: AppButton.tertiary(
            key: const ValueKey('account-email-toggle'),
            label: t.account.emailSignInToggle,
            onPressed: () => setState(() => _showEmailForm = !_showEmailForm),
          ),
        ),
        if (_showEmailForm) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(t.account.emailFormHint, style: textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  autocorrect: false,
                  decoration: InputDecoration(labelText: t.account.emailLabel),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onSubmitted: (_) => _submitEmail(),
                  decoration: InputDecoration(labelText: t.account.passwordLabel),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: _busyLabel(t.account.emailSignInAction, state, AccountAction.emailSignIn),
            onPressed: state.isBusy ? null : _submitEmail,
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        const CurrencySettingSection(),
      ],
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.state, required this.user});

  final AccountState state;
  final AppUser user;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showConfirmDelete(
      context,
      title: t.account.deleteConfirmTitle,
      message: t.account.deleteConfirmBody,
      confirmLabel: t.account.deleteAction,
    );
    if (!confirmed || !context.mounted) return;
    context.read<AccountBloc>().add(const AccountDeletionRequested());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final name = user.displayName;
    final method = switch (user.method) {
      SignInMethod.google => t.account.methodGoogle,
      SignInMethod.password => t.account.methodPassword,
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppHardCard(
          child: Row(
            children: [
              AccountAvatar(user: user, size: 56),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (name != null && name.isNotEmpty)
                      Text(name, style: textTheme.titleMedium, overflow: TextOverflow.ellipsis),
                    if (user.email != null)
                      Text(user.email!, style: textTheme.bodyMedium, overflow: TextOverflow.ellipsis),
                    if (method != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(method, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppSectionLabel(t.account.dataTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(t.account.dataBody, style: textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.lg),
        AppButton.secondary(
          label: _busyLabel(t.account.signOutAction, state, AccountAction.signOut),
          onPressed: state.isBusy ? null : () => context.read<AccountBloc>().add(const AccountSignOutRequested()),
        ),
        const SizedBox(height: AppSpacing.lg),
        const CurrencySettingSection(),
        const SizedBox(height: AppSpacing.xl),
        Divider(color: colors.divider),
        const SizedBox(height: AppSpacing.md),
        AppSectionLabel(t.account.dangerTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(t.account.dangerBody, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
        const SizedBox(height: AppSpacing.md),
        AppButton.secondary(
          key: const ValueKey('account-delete'),
          label: _busyLabel(t.account.deleteAction, state, AccountAction.delete),
          textColor: colors.expense,
          onPressed: state.isBusy ? null : () => _confirmDelete(context),
        ),
      ],
    );
  }
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog();

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.account.deletePasswordTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(t.account.deletePasswordBody),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _controller,
            obscureText: true,
            autofocus: true,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (value) => Navigator.pop(context, value),
            decoration: InputDecoration(labelText: t.account.passwordLabel),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.common.cancel)),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: TextButton.styleFrom(foregroundColor: context.appColors.expense),
          child: Text(t.account.deleteAction),
        ),
      ],
    );
  }
}
