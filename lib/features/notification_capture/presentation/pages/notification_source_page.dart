import 'dart:async';

import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/services/built_in_notification_patterns.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_template.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/pages/notification_pattern_page.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/app_picker_sheet.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/notification_widgets.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/plus_gate.dart';
import 'package:saldough/shared/wallet/wallet.dart';
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

/// Memilih aplikasi lalu membuka halaman sumbernya (Tambah aplikasi di
/// setelan dan Aplikasi lain di Mulai cepat).
Future<void> pickAndOpenNotificationSource(BuildContext context, {required NotificationSettingsBloc bloc}) async {
  final app = await showAppPickerSheet(context, load: bloc.loadInstalledApps);
  if (app == null || !context.mounted) return;
  final existing = bloc.state.settings.sources.where((s) => s.packageName == app.packageName).firstOrNull;
  // Gratis: hanya sumber pertama (ADR-041 §3.8).
  if (existing == null && exceedsFreeSources(bloc.state.settings.sources.length)) {
    await openNotificationPaywall(context);
    return;
  }
  await openNotificationSourcePage(
    context,
    bloc: bloc,
    source:
        existing ??
        NotificationSource(packageName: app.packageName, appLabel: app.label, keywords: defaultNotificationKeywords),
    isNew: existing == null,
  );
}

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
  // Kunci stabil per aturan dompet, supaya kolom kata pengenal tidak tertukar
  // saat ada yang dihapus.
  late final List<Key> _ruleKeys = [for (final _ in widget.initial.walletRules) UniqueKey()];

  @override
  void initState() {
    super.initState();
    // Contoh hanya dimuat bila penyimpanannya menyala (ADR-042 §3.2).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final bloc = context.read<NotificationSettingsBloc>();
      if (bloc.state.settings.saveSamples) bloc.add(NotificationSamplesRequested(_source.packageName));
    });
  }

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

  void _setRule(int index, WalletRule rule) {
    final rules = [..._source.walletRules]..[index] = rule;
    setState(() => _source = _source.copyWith(walletRules: rules));
  }

  void _addRule(List<Wallet> wallets) {
    final free = wallets.where((w) => !_source.allWalletIds.contains(w.id)).firstOrNull ?? wallets.firstOrNull;
    if (free == null) return;
    _ruleKeys.add(UniqueKey());
    setState(() => _source = _source.copyWith(walletRules: [..._source.walletRules, WalletRule(walletId: free.id)]));
  }

  void _removeRule(int index) {
    _ruleKeys.removeAt(index);
    setState(() => _source = _source.copyWith(walletRules: [..._source.walletRules]..removeAt(index)));
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
                AppSectionLabel(texts.walletRulesTitle),
                const SizedBox(height: AppSpacing.space1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
                  child: Text(texts.walletRulesHint, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
                ),
                for (final (i, rule) in _source.walletRules.indexed)
                  _WalletRuleRow(
                    key: _ruleKeys[i],
                    rule: rule,
                    wallets: wallets,
                    onChanged: (value) => _setRule(i, value),
                    onRemove: () => _removeRule(i),
                  ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppButton.text(
                    small: true,
                    label: texts.walletRuleAdd,
                    onPressed: wallets.isEmpty ? null : () => _addRule(wallets),
                  ),
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

  Future<void> _toggleSamples(bool on) async {
    final bloc = context.read<NotificationSettingsBloc>();
    if (on) {
      final texts = t.notificationCapture;
      final agreed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(texts.samplesDisclosureTitle),
          content: Text(texts.samplesDisclosureBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(texts.samplesDisclosureCancel)),
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(texts.samplesDisclosureAgree)),
          ],
        ),
      );
      if (agreed != true || !mounted) return;
    }
    bloc.add(NotificationSamplesToggled(on: on));
    if (on) bloc.add(NotificationSamplesRequested(_source.packageName));
  }

  Future<void> _pickFilterPhrase(CapturedNotification sample) async {
    final phrase = await showAppSheet<String>(
      context,
      isScrollControlled: true,
      builder: (_) => _FilterPhraseSheet(sample: sample.text),
    );
    if (phrase == null || phrase.trim().isEmpty || _source.keywords.contains(phrase.trim())) return;
    setState(() => _source = _source.copyWith(keywords: [..._source.keywords, phrase.trim()]));
  }

  Future<void> _patternFromSample(CapturedNotification sample) async {
    final bloc = context.read<NotificationSettingsBloc>();
    final saved = await openNotificationPatternPage(
      context,
      packageName: _source.packageName,
      wallets: bloc.state.wallets,
      sample: sample.text,
    );
    if (saved != null) bloc.add(NotificationPatternSaved(saved));
  }

  /// Contoh notifikasi aplikasi ini (ADR-042 §3.2): bahan untuk filter cepat
  /// dan pola. Bawaan mati; menyalakannya meminta persetujuan.
  List<Widget> _samplesSection(BuildContext context, NotificationSettingsState state) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final on = state.settings.saveSamples;
    return [
      const SizedBox(height: AppSpacing.space6),
      NotificationSwitchCard(
        key: const ValueKey('notification-samples-switch'),
        label: texts.samplesToggle,
        hint: texts.samplesHint,
        value: on,
        onChanged: (value) => unawaited(_toggleSamples(value)),
      ),
      if (on) ...[
        const SizedBox(height: AppSpacing.space4),
        AppSectionLabel(texts.samplesTitle),
        const SizedBox(height: AppSpacing.space1),
        if (state.samples.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
            child: Text(texts.samplesEmpty, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
          ),
        for (final sample in state.samples.take(10))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.space2),
            child: AppCard(
              padding: const EdgeInsets.all(AppSpacing.space3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sample.text, maxLines: 4, overflow: TextOverflow.ellipsis, style: textTheme.bodySmall),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton.text(
                        small: true,
                        label: texts.samplesFilter,
                        onPressed: () => unawaited(_pickFilterPhrase(sample)),
                      ),
                      AppButton.text(
                        small: true,
                        label: texts.samplesPattern,
                        onPressed: () => unawaited(_patternFromSample(sample)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    ];
  }

  /// Ikat pola ke rutin (ADR-042 §3.4): notifikasi yang cocok dengan pola
  /// terikat dicatat sebagai kemunculan rutin itu, tanpa menebak.
  List<Widget> _bindingSection(
    BuildContext context,
    NotificationSettingsState state,
    List<NotificationPattern> patterns,
  ) {
    final rules = [
      for (final r in state.recurringRules)
        if (!r.isPaused) r,
    ];
    if (patterns.isEmpty || state.recurringRules.isEmpty) return const [];
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    return [
      const SizedBox(height: AppSpacing.space6),
      AppSectionLabel(texts.bindingTitle),
      const SizedBox(height: AppSpacing.space1),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1),
        child: Text(texts.bindingHint, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
      ),
      for (final pattern in patterns)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.space2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(pattern.label, style: textTheme.titleSmall),
              Builder(
                builder: (context) {
                  final bound = state.recurringRules
                      .where(
                        (r) =>
                            r.notificationBinding?.packageName == _source.packageName &&
                            r.notificationBinding?.patternId == pattern.id,
                      )
                      .firstOrNull;
                  return AppMenuSelectButton<String>(
                    key: ValueKey('binding-${pattern.id}'),
                    icon: IconKey.calendar,
                    label: bound?.note ?? texts.bindingNone,
                    isPlaceholder: bound == null,
                    wrapLabel: true,
                    allLabel: texts.bindingNone,
                    allIcon: IconKey.close,
                    options: [for (final r in rules) (value: r.id, label: r.note, icon: IconKey.calendar)],
                    onSelected: (id) => context.read<NotificationSettingsBloc>().add(
                      NotificationPatternBound(
                        packageName: _source.packageName,
                        patternId: pattern.id,
                        patternLabel: pattern.label,
                        ruleId: id,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
    ];
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
          AppButton.text(small: true, label: texts.addKeyword, onPressed: _addKeyword),
        ],
      ),
      if (missingDefaults)
        Align(
          alignment: Alignment.centerLeft,
          child: AppButton.text(small: true, label: texts.addDefaultKeywords, onPressed: () => setState(
              () =>
                  _source = _source.copyWith(keywords: {..._source.keywords, ...defaultNotificationKeywords}.toList()),
            )),
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
      ..._samplesSection(context, state),
      ..._bindingSection(context, state, [
        ...userPatterns,
        for (final p in builtIns)
          if (p.verified && !state.settings.disabledBuiltInPatternIds.contains(p.id)) p,
      ]),
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
        child: AppCard(
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

/// Satu aturan dompet: dompet dan kata pengenalnya (ADR-042 §3.1).
class _WalletRuleRow extends StatefulWidget {
  const _WalletRuleRow({
    required this.rule,
    required this.wallets,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final WalletRule rule;
  final List<Wallet> wallets;
  final ValueChanged<WalletRule> onChanged;
  final VoidCallback onRemove;

  @override
  State<_WalletRuleRow> createState() => _WalletRuleRowState();
}

class _WalletRuleRowState extends State<_WalletRuleRow> {
  late final _keywords = TextEditingController(text: widget.rule.keywords.join(', '));

  @override
  void dispose() {
    _keywords.dispose();
    super.dispose();
  }

  void _changed({String? walletId}) => widget.onChanged(
    widget.rule.copyWith(
      walletId: walletId,
      keywords: [
        for (final k in _keywords.text.split(','))
          if (k.trim().isNotEmpty) k.trim(),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final walletId = widget.wallets.any((w) => w.id == widget.rule.walletId) ? widget.rule.walletId : null;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.space3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WalletSelectField(
            label: texts.walletLabel,
            wallets: widget.wallets,
            selectedId: walletId,
            onSelected: (id) => _changed(walletId: id),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keywords,
                  decoration: InputDecoration(hintText: texts.walletRuleKeywordsField),
                  onChanged: (_) => _changed(),
                ),
              ),
              AppButton.text(small: true, label: texts.walletRuleRemove, onPressed: widget.onRemove),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lembar memilih frasa filter dari satu contoh notifikasi: ketuk kata untuk
/// menyusun frasa, ubah bebas di kolom, lalu tambahkan (ADR-042 §3.2).
class _FilterPhraseSheet extends StatefulWidget {
  const _FilterPhraseSheet({required this.sample});

  final String sample;

  @override
  State<_FilterPhraseSheet> createState() => _FilterPhraseSheetState();
}

class _FilterPhraseSheetState extends State<_FilterPhraseSheet> {
  final _phrase = TextEditingController();

  @override
  void dispose() {
    _phrase.dispose();
    super.dispose();
  }

  void _append(String word) {
    final current = _phrase.text.trim();
    _phrase.text = current.isEmpty ? word : '$current $word';
  }

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    // Kata berangka tidak dipakai: nominal dan nomor berubah tiap notifikasi.
    final words = {
      for (final w in NotificationTemplate.words(widget.sample))
        if (w.text.length >= 3 && !RegExp(r'\d').hasMatch(w.text)) w.text.replaceAll(RegExp(r'[,.;:!?]+$'), ''),
    }.where((w) => w.length >= 3);
    return Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space4,
          AppSpacing.space4,
          AppSpacing.space4 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(texts.samplesFilterTitle, style: textTheme.titleMedium),
            const SizedBox(height: AppSpacing.space1),
            Text(texts.samplesFilterHint, style: textTheme.bodySmall?.copyWith(color: colors.ink2)),
            const SizedBox(height: AppSpacing.space3),
            Wrap(
              spacing: AppSpacing.space1,
              runSpacing: AppSpacing.space1,
              children: [
                for (final word in words) ActionChip(label: Text(word), onPressed: () => _append(word)),
              ],
            ),
            const SizedBox(height: AppSpacing.space3),
            TextField(
              key: const ValueKey('samples-phrase'),
              controller: _phrase,
              decoration: InputDecoration(hintText: texts.keywordField),
            ),
            const SizedBox(height: AppSpacing.space3),
            AppButton(label: texts.addKeyword, onPressed: () => Navigator.of(context).pop(_phrase.text)),
          ],
        ),
    );
  }
}
