import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/services/built_in_notification_patterns.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/pages/notification_pattern_page.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/notification_widgets.dart';
import 'package:saldough/shared/wallet/wallet_presentation.dart';
import 'package:state_management/state_management.dart';

/// Membuka halaman satu sumber notifikasi (ADR-032 §3.9): didengarkan,
/// dompet, lalu filter dan pola yang terlipat. Sumber baru baru tersimpan saat Simpan ditekan.
Future<void> openNotificationSourcePage(
  BuildContext context, {
  required NotificationSettingsBloc bloc,
  required NotificationSource source,
  bool isNew = false,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: EffectListener<NotificationSettingsBloc, NotificationSettingsState>(
        child: _SourcePage(initial: source, isNew: isNew),
      ),
    ),
  ),
);

class _SourcePage extends StatefulWidget {
  const _SourcePage({required this.initial, required this.isNew});

  final NotificationSource initial;
  final bool isNew;

  @override
  State<_SourcePage> createState() => _SourcePageState();
}

class _SourcePageState extends State<_SourcePage> {
  late NotificationSource _source = widget.initial;
  final _keyword = TextEditingController();
  bool _advanced = false;

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final word = _keyword.text.trim();
    if (word.isEmpty || _source.keywords.contains(word)) return;
    setState(() => _source = _source.copyWith(keywords: [..._source.keywords, word]));
    _keyword.clear();
  }

  void _save() {
    context.read<NotificationSettingsBloc>().add(NotificationSourceSaved(_source));
    Navigator.of(context).pop();
  }

  Future<void> _remove() async {
    final bloc = context.read<NotificationSettingsBloc>();
    final confirmed = await showConfirmDelete(
      context,
      message: t.notificationCapture.removeSourceConfirm(app: _source.appLabel),
      confirmLabel: t.notificationCapture.removeSource,
    );
    if (!confirmed || !mounted) return;
    bloc.add(NotificationSourceRemoved(_source.packageName));
    Navigator.of(context).pop();
  }

  Future<void> _editPattern(NotificationPattern? pattern) async {
    final bloc = context.read<NotificationSettingsBloc>();
    final saved = await openNotificationPatternPage(
      context,
      packageName: _source.packageName,
      wallets: bloc.state.wallets,
      initial: pattern,
    );
    if (saved != null) bloc.add(NotificationPatternSaved(saved));
  }

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final noFilter = _source.keywords.every((k) => k.trim().isEmpty);
    return Scaffold(
      appBar: AppBar(title: Text(_source.appLabel)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space2, AppSpacing.space4, AppSpacing.space4),
          child: AppButton(label: texts.save, onPressed: _save),
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
          builder: (context, state) {
            final wallets = state.wallets;
            final walletId = wallets.any((w) => w.id == _source.walletId) ? _source.walletId : null;
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.space4),
              children: [
                NotificationSwitchCard(
                  label: texts.sourceEnabled,
                  value: _source.enabled,
                  onChanged: (value) => setState(() => _source = _source.copyWith(enabled: value)),
                ),
                const SizedBox(height: AppSpacing.space6),
                KeyedSubtree(
                  key: const ValueKey('notification-source-wallet'),
                  child: WalletSelectField(
                    label: texts.walletLabel,
                    wallets: wallets,
                    selectedId: walletId,
                    onSelected: (id) => setState(() => _source = _source.copyWith(walletId: () => id)),
                  ),
                ),
                const SizedBox(height: AppSpacing.space1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
                  child: Text(texts.walletHelp, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
                ),
                const SizedBox(height: AppSpacing.space6),
                // Filter dan pola jarang disentuh: terlipat, kecuali filter
                // kosong (tidak ada yang dibaca) supaya peringatannya terlihat.
                _AdvancedToggle(
                  expanded: _advanced || noFilter,
                  warning: noFilter ? texts.keywordsEmptyWarning : null,
                  onTap: () => setState(() => _advanced = !_advanced),
                ),
                if (_advanced || noFilter) ..._advancedSection(context, state),
                if (!widget.isNew) ...[
                  const SizedBox(height: AppSpacing.space8),
                  AppButton.text(label: texts.removeSource, onPressed: _remove),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  List<Widget> _advancedSection(BuildContext context, NotificationSettingsState state) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final missingDefaults = defaultNotificationKeywords.any((k) => !_source.keywords.contains(k));
    final userPatterns = [
      for (final p in state.userPatterns)
        if (p.packageName == _source.packageName) p,
    ];
    final builtIns = [
      for (final p in builtInNotificationPatterns)
        if (p.packageName == _source.packageName) p,
    ];
    return [
      const SizedBox(height: AppSpacing.space4),
      AppSectionLabel(texts.keywordsLabel),
      const SizedBox(height: AppSpacing.space1),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
        child: Text(texts.keywordsHint, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
      ),
      const SizedBox(height: AppSpacing.space2),
      Wrap(
        spacing: AppSpacing.space1,
        runSpacing: AppSpacing.space1,
        children: [
          for (final word in _source.keywords)
            InputChip(
              label: Text(word),
              onDeleted: () => setState(
                () => _source = _source.copyWith(keywords: [..._source.keywords]..remove(word)),
              ),
            ),
        ],
      ),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _keyword,
              decoration: InputDecoration(hintText: texts.keywordField),
              onSubmitted: (_) => _addKeyword(),
            ),
          ),
          TextButton(onPressed: _addKeyword, child: Text(texts.addKeyword)),
        ],
      ),
      if (missingDefaults)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => setState(
              () =>
                  _source = _source.copyWith(keywords: {..._source.keywords, ...defaultNotificationKeywords}.toList()),
            ),
            child: Text(texts.addDefaultKeywords),
          ),
        ),
      const SizedBox(height: AppSpacing.space6),
      AppSectionLabel(texts.patternsTitle),
      const SizedBox(height: AppSpacing.space1),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
        child: Text(
          userPatterns.isEmpty && builtIns.isEmpty ? texts.patternsEmpty : texts.patternsHint,
          style: textTheme.bodySmall?.copyWith(color: colors.ink2),
        ),
      ),
      const SizedBox(height: AppSpacing.space2),
      for (final pattern in userPatterns)
        _PatternRow(
          pattern: pattern,
          subtitle: pattern.template,
          onTap: () => _editPattern(pattern),
          trailing: IconButton(
            tooltip: texts.deletePattern,
            icon: const AppIcon(IconKey.delete),
            onPressed: () => context.read<NotificationSettingsBloc>().add(NotificationPatternDeleted(pattern.id)),
          ),
        ),
      for (final pattern in builtIns)
        _PatternRow(
          pattern: pattern,
          subtitle: pattern.verified ? texts.builtInVerified : texts.builtInUnverified,
          onTap: () => _editPattern(pattern.duplicateAs('user.${DateTime.now().microsecondsSinceEpoch}')),
          trailing: Switch(
            value: !state.settings.disabledBuiltInPatternIds.contains(pattern.id),
            onChanged: (enabled) => context.read<NotificationSettingsBloc>().add(
              BuiltInPatternToggled(patternId: pattern.id, enabled: enabled),
            ),
          ),
        ),
      AppButton.secondary(label: texts.newPattern, onPressed: () => _editPattern(null)),
    ];
  }
}

/// Kepala bagian lipat "Filter dan pola".
class _AdvancedToggle extends StatelessWidget {
  const _AdvancedToggle({required this.expanded, required this.onTap, this.warning});

  final bool expanded;
  final String? warning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return AppTappable(
      key: const ValueKey('notification-source-advanced'),
      label: texts.advancedTitle,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1, vertical: AppSpacing.space1),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(texts.advancedTitle, style: textTheme.titleSmall),
                  Text(
                    warning ?? texts.advancedHint,
                    style: textTheme.bodySmall?.copyWith(color: warning == null ? colors.ink2 : colors.danger),
                  ),
                ],
              ),
            ),
            AppIcon(expanded ? IconKey.expandLess : IconKey.expandMore, color: colors.ink2),
          ],
        ),
      ),
    );
  }
}

class _PatternRow extends StatelessWidget {
  const _PatternRow({required this.pattern, required this.subtitle, required this.onTap, required this.trailing});

  final NotificationPattern pattern;
  final String subtitle;
  final VoidCallback onTap;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.space2),
      child: AppTappable(
        label: pattern.label,
        onTap: onTap,
        child: AppHardCard(
          padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space2, AppSpacing.space1, AppSpacing.space2),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${pattern.label} · ${patternKindLabel(pattern.kind)}', style: textTheme.titleSmall),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(color: context.appColors.ink2),
                    ),
                  ],
                ),
              ),
              trailing,
            ],
          ),
        ),
      ),
    );
  }
}
