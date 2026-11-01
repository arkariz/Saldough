import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/account/presentation/bloc/account_bloc.dart';
import 'package:saldough/features/account/presentation/bloc/account_state.dart';
import 'package:saldough/features/account/presentation/widgets/appearance_setting.dart';
import 'package:saldough/features/account/presentation/widgets/category_setting.dart';
import 'package:saldough/features/account/presentation/widgets/currency_setting.dart';
import 'package:saldough/features/account/presentation/widgets/financial_month_setting.dart';
import 'package:saldough/features/account/presentation/widgets/hide_amounts_setting.dart';
import 'package:saldough/features/account/presentation/widgets/language_setting.dart';
import 'package:saldough/features/account/presentation/widgets/notification_capture_setting.dart';
import 'package:saldough/features/account/presentation/widgets/recurring_reminder_setting.dart';
import 'package:saldough/shared/auth/auth.dart';
import 'package:saldough/shared/auth/auth_presentation.dart';
import 'package:state_management/state_management.dart';

/// Layar Akun (ADR-023, ADR-024). Akun opsional: belum masuk menawarkan
/// Google (dan email/sandi khusus peninjau di balik tautan); sudah masuk
/// menampilkan profil, status data, keluar, dan zona bahaya hapus akun.
/// Keduanya memuat bagian "Pengaturan" (mata uang, ADR-025).
class AccountPage extends StatefulWidget {
  /// Membuat [AccountPage].
  const AccountPage({this.versionEntry, this.dataSection, this.plusSection, super.key});

  /// Baris Versi aplikasi di grup paling bawah (APP_UPDATE F4), disisipkan
  /// akar komposisi karena isinya milik fitur lain (ADR-030); `null` = tanpa
  /// grup itu.
  final Widget? versionEntry;

  /// Bagian Data kamu (ekspor, cadangkan, pulihkan; ADR-040), disisipkan akar
  /// komposisi karena isinya milik fitur lain; tampil sesudah setelan, sama
  /// untuk sudah dan belum masuk. `null` = tanpa bagian itu.
  final Widget? dataSection;

  /// Bagian Plus (status paket, kelola, pulihkan; ADR-041), disisipkan akar
  /// komposisi karena isinya milik fitur `premium`; tampil di atas setelan.
  final Widget? plusSection;

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
      appBar: AppBar(title: Text(t.account.title, style: context.ds.typography.headlineMd), centerTitle: false),
      body: SafeArea(
        child: BlocListener<AccountBloc, AccountState>(
          listenWhen: (prev, curr) => !prev.needsPassword && curr.needsPassword,
          listener: (context, _) => _promptPassword(context),
          child: BlocBuilder<AccountBloc, AccountState>(
            builder: (context, state) {
              final user = state.user;
              return TourTrigger(
                tour: TourId.account,
                ready: true,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (user == null)
                      _SignedOut(state: state, dataSection: widget.dataSection, plusSection: widget.plusSection)
                    else
                      _SignedIn(
                        state: state,
                        user: user,
                        dataSection: widget.dataSection,
                        plusSection: widget.plusSection,
                      ),
                    if (widget.versionEntry case final entry?) ...[
                      const SizedBox(height: 24),
                      DsSectionHeader(title: t.account.appSection),
                      const SizedBox(height: 8),
                      DsListCard(children: [entry]),
                    ],
                  ],
                ),
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
  const _SignedOut({required this.state, this.dataSection, this.plusSection});

  final AccountState state;
  final Widget? dataSection;
  final Widget? plusSection;

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
    final ds = context.ds;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Kartu masuk: maskot tidur di tengah, lalu teks, Google sebagai
        // tombol utama, email di bawahnya.
        DecoratedBox(
          decoration: ds.elevation.card.decoration().copyWith(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ds.colors.actionPrimary.withValues(alpha: 0.10), ds.colors.surfaceCard],
              stops: const [0, 0.55],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AccountAvatar(user: null, size: 88)),
                const SizedBox(height: 12),
                Text(
                  t.account.signedOutTitle,
                  textAlign: TextAlign.center,
                  style: ds.typography.titleMd.copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  t.account.signedOutBody,
                  textAlign: TextAlign.center,
                  style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
                ),
                const SizedBox(height: 16),
                DsButton(
                  expand: true,
                  label: _busyLabel(t.account.googleSignInAction, state, AccountAction.googleSignIn),
                  onPressed: state.isBusy
                      ? null
                      : () => context.read<AccountBloc>().add(const AccountGoogleSignInRequested()),
                ),
                const SizedBox(height: 4),
                DsButton.ghost(
                  key: const ValueKey('account-email-toggle'),
                  expand: true,
                  label: t.account.emailSignInToggle,
                  onPressed: () => setState(() => _showEmailForm = !_showEmailForm),
                ),
              ],
            ),
          ),
        ),
        if (_showEmailForm) ...[
          const SizedBox(height: 8),
          Text(t.account.emailFormHint, style: textTheme.bodySmall, textAlign: TextAlign.center),
          const SizedBox(height: 16),
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
                const SizedBox(height: 8),
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
          const SizedBox(height: 16),
          DsButton(
            label: _busyLabel(t.account.emailSignInAction, state, AccountAction.emailSignIn),
            onPressed: state.isBusy ? null : _submitEmail,
          ),
        ],
        const SizedBox(height: 24),
        _Settings(dataSection: widget.dataSection, plusSection: widget.plusSection),
      ],
    );
  }
}

/// Setelan dalam dua kelompok baris (prototipe `Akun.dc.html`): Pencatatan
/// dan Tampilan. Sama untuk sudah dan belum masuk -- setelan tidak butuh
/// akun.
class _Settings extends StatelessWidget {
  const _Settings({this.dataSection, this.plusSection});

  /// Bagian Data kamu, sesudah kelompok Tampilan (prototipe `AkunData.dc.html`).
  final Widget? dataSection;
  final Widget? plusSection;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (plusSection case final section?) ...[section, const SizedBox(height: 24)],
        DsSectionHeader(title: t.account.recordingSection),
        const SizedBox(height: 8),
        DsListCard(
          children: [
            const CategorySettingEntry(),
            if (defaultTargetPlatform == TargetPlatform.android) const NotificationCaptureSettingEntry(),
            // Baris status yang disorot sekali saat Akun pertama dibuka
            // (T-21.6); ada di Android dan iOS.
            const SpotlightTarget(
              spotlightKey: SpotlightKey.accountStatus,
              child: RecurringReminderSettingEntry(),
            ),
            const FinancialMonthSettingEntry(),
          ],
        ),
        const SizedBox(height: 24),
        DsSectionHeader(title: t.account.displaySection),
        const SizedBox(height: 8),
        const DsListCard(
          children: [
            LanguageSettingEntry(),
            AppearanceModeEntry(),
            AppearancePresetEntry(),
            CurrencySettingSection(),
            HideAmountsSettingEntry(),
          ],
        ),
        if (dataSection case final section?) ...[const SizedBox(height: 24), section],
      ],
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.state, required this.user, this.dataSection, this.plusSection});

  final Widget? dataSection;
  final Widget? plusSection;

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
    final ds = context.ds;
    final name = user.displayName;
    final method = switch (user.method) {
      SignInMethod.google => t.account.methodGoogle,
      SignInMethod.password => t.account.methodPassword,
      null => null,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: ds.elevation.card.decoration().copyWith(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [ds.colors.actionPrimary.withValues(alpha: 0.10), ds.colors.surfaceCard],
              stops: const [0, 0.55],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                AccountAvatar(user: user, size: 72),
                const SizedBox(height: 12),
                if (name != null && name.isNotEmpty)
                  Text(name, textAlign: TextAlign.center, style: ds.typography.titleMd.copyWith(fontSize: 20)),
                if (user.email != null)
                  Text(
                    user.email!,
                    textAlign: TextAlign.center,
                    style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary),
                  ),
                if (method != null) ...[
                  const SizedBox(height: 10),
                  DsBadge(label: method, tone: DsBadgeTone.income),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        DsButton.secondary(
          expand: true,
          icon: Icons.logout,
          label: _busyLabel(t.account.signOutAction, state, AccountAction.signOut),
          onPressed: state.isBusy ? null : () => context.read<AccountBloc>().add(const AccountSignOutRequested()),
        ),
        const SizedBox(height: 24),
        _Settings(dataSection: dataSection, plusSection: plusSection),
        const SizedBox(height: 32),
        DsSectionHeader(title: t.account.dangerTitle),
        const SizedBox(height: 4),
        Text(t.account.dangerBody, style: ds.typography.bodySm.copyWith(color: ds.colors.textSecondary)),
        const SizedBox(height: 16),
        DsButton.danger(
          key: const ValueKey('account-delete'),
          expand: true,
          label: _busyLabel(t.account.deleteAction, state, AccountAction.delete),
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
          const SizedBox(height: 16),
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
        DsButton.ghost(label: t.common.cancel, onPressed: () => Navigator.pop(context)),
        DsButton.danger(label: t.account.deleteAction, onPressed: () => Navigator.pop(context, _controller.text)),
      ],
    );
  }
}
