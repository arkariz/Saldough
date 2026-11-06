import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/features/notification_capture/domain/entities/captured_notification.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_source.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_template.dart';
import 'package:saldough/features/notification_capture/presentation/bloc/notification_settings_bloc.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/app_picker_sheet.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/plus_gate.dart';
import 'package:saldough/features/notification_capture/presentation/widgets/source_app_tile.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wallet/wallet_presentation.dart';
import 'package:state_management/state_management.dart';

/// Membuka halaman satu sumber notifikasi (ADR-032 §3.9), tampilan v2:
/// identitas dan sakelar didengarkan, dompet bawaan, aturan dompet, lalu filter
/// dan contoh yang terlipat. Sumber baru baru tersimpan saat Simpan ditekan.
/// [icon] ikon asli aplikasi bila sudah diketahui (sumber yang baru dipilih).
Future<void> openNotificationSourcePage(
  BuildContext context, {
  required NotificationSettingsBloc bloc,
  required NotificationSource source,
  bool isNew = false,
  Uint8List? icon,
}) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    builder: (_) => BlocProvider.value(
      value: bloc,
      child: EffectListener<NotificationSettingsBloc, NotificationSettingsState>(
        child: _SourcePage(initial: source, isNew: isNew, icon: icon),
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
    icon: app.icon == null ? null : Uint8List.fromList(app.icon!),
  );
}

class _SourcePage extends StatefulWidget {
  const _SourcePage({required this.initial, required this.isNew, this.icon});

  final NotificationSource initial;
  final bool isNew;
  final Uint8List? icon;

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
    setState(
      () => _source = _source.copyWith(
        walletRules: [
          ..._source.walletRules,
          WalletRule(walletId: free.id),
        ],
      ),
    );
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

  Future<void> _toggleSamples({required bool on}) async {
    final bloc = context.read<NotificationSettingsBloc>();
    if (on) {
      final agreed = await showAppSheet<bool>(
        context,
        isScrollControlled: true,
        builder: (_) => const _SamplesConsentSheet(),
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

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    final c = ds.colors;
    final noFilter = _source.keywords.every((k) => k.trim().isEmpty);
    return Scaffold(
      appBar: AppBar(title: Text(_source.appLabel, style: ds.typography.headlineMd), centerTitle: false),
      bottomNavigationBar: DsStickyBar(
        child: DsButton(label: texts.save, expand: true, onPressed: _save),
      ),
      body: SafeArea(
        child: BlocBuilder<NotificationSettingsBloc, NotificationSettingsState>(
          builder: (context, state) {
            final wallets = state.wallets;
            final walletId = wallets.any((w) => w.id == _source.walletId) ? _source.walletId : null;
            final expanded = _advanced || noFilter;
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                // 1. Identitas: ikon asli, nama, paket, dan sakelar didengarkan.
                DsCard(
                  padding: const EdgeInsets.all(16),
                  child: MergeSemantics(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => setState(() => _source = _source.copyWith(enabled: !_source.enabled)),
                      child: Row(
                        children: [
                          SourceAppTile(
                            label: _source.appLabel,
                            icon: widget.icon ?? state.appIcons[_source.packageName],
                            size: 52,
                            dimmed: !_source.enabled,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _source.appLabel,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: ds.typography.headlineSm,
                                ),
                                Text(
                                  _source.packageName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                texts.sourceEnabled,
                                style: ds.typography.labelSm.copyWith(color: c.textSecondary, letterSpacing: 0),
                              ),
                              Switch(
                                key: const ValueKey('notification-source-enabled'),
                                value: _source.enabled,
                                thumbIcon: dsSwitchThumbIcon(context),
                                onChanged: (value) => setState(() => _source = _source.copyWith(enabled: value)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // 2. Dompet bawaan.
                DsCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          DsIconTile.asset(asset: ClayIcons.walletNav, size: DsIconTileSize.sm),
                          const SizedBox(width: 10),
                          Expanded(child: Text(texts.walletDefaultTitle, style: ds.typography.titleMd)),
                          DsPill(label: texts.walletFallbackPill, tone: DsPillTone.positive),
                        ],
                      ),
                      const SizedBox(height: 12),
                      KeyedSubtree(
                        key: const ValueKey('notification-source-wallet'),
                        child: WalletSelectField(
                          label: texts.walletLabel,
                          wallets: wallets,
                          selectedId: walletId,
                          useDs: true,
                          onSelected: (id) => setState(() => _source = _source.copyWith(walletId: () => id)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(texts.walletHelp, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 3. Dompet lain di aplikasi ini (aturan dompet).
                DsCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(texts.walletRulesTitle, style: ds.typography.titleMd),
                                const SizedBox(height: 2),
                                Text(
                                  texts.walletRulesHint,
                                  style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          DsPill(label: texts.walletRulesCount(n: _source.walletRules.length)),
                        ],
                      ),
                      for (final (i, rule) in _source.walletRules.indexed)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: _WalletRuleCard(
                            key: _ruleKeys[i],
                            index: i + 1,
                            rule: rule,
                            wallets: wallets,
                            onChanged: (value) => _setRule(i, value),
                            onRemove: () => _removeRule(i),
                          ),
                        ),
                      const SizedBox(height: 12),
                      DsDashedButton(
                        label: texts.walletRuleAdd,
                        onPressed: wallets.isEmpty ? null : () => _addRule(wallets),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: c.incomeContainer.withValues(alpha: 0.5),
                          borderRadius: DsRadius.baseAll,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.verified_outlined, size: 16, color: c.actionPrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                texts.walletRulesAmbiguousNote,
                                style: ds.typography.bodySm.copyWith(color: c.onIncomeContainer, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // 4. Filter dan contoh: terlipat, kecuali filter kosong (tidak ada
                // yang dibaca) supaya peringatannya terlihat.
                DsCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        button: true,
                        label: texts.advancedTitle,
                        child: DsPressable(
                          key: const ValueKey('notification-source-advanced'),
                          onPressed: () => setState(() => _advanced = !_advanced),
                          pressedScale: 0.995,
                          dimWhenDisabled: false,
                          builder: (context, _) => Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                DsIconTile.child(
                                  size: DsIconTileSize.sm,
                                  tone: noFilter ? DsIconTileTone.warning : DsIconTileTone.solid,
                                  child: Icon(
                                    Icons.tune_rounded,
                                    size: 18,
                                    color: noFilter ? c.onWarningContainer : c.onActionPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(texts.filterCardTitle, style: ds.typography.titleMd),
                                      Text(
                                        noFilter
                                            ? texts.keywordsEmptyWarning
                                            : texts.keywordsActive(n: _source.keywords.length),
                                        style: ds.typography.bodySm.copyWith(
                                          color: noFilter ? c.error : c.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                  color: c.textSecondary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (expanded) ...[
                        Divider(height: 1, color: c.outlineSubtle),
                        Padding(padding: const EdgeInsets.all(16), child: _filterSection(context, state)),
                      ],
                    ],
                  ),
                ),
                if (!widget.isNew) ...[
                  const SizedBox(height: 20),
                  Center(
                    child: DsPressable(
                      onPressed: _remove,
                      builder: (context, _) => ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 44),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 18, color: c.error),
                            const SizedBox(width: 6),
                            Text(
                              texts.removeSource,
                              style: ds.typography.titleMd.copyWith(fontSize: 14, color: c.error),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  /// Isi bagian filter: frasa wajib, tambah frasa, dan contoh notifikasi.
  Widget _filterSection(BuildContext context, NotificationSettingsState state) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    final c = ds.colors;
    final missingDefaults = defaultNotificationKeywords.any((k) => !_source.keywords.contains(k));
    final samplesOn = state.settings.saveSamples;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(texts.keywordsLabel, style: ds.typography.titleMd.copyWith(fontSize: 14))),
            if (missingDefaults)
              DsInlineAction(
                label: texts.addDefaultKeywords,
                icon: Icons.restart_alt_rounded,
                dense: true,
                onPressed: () => setState(
                  () => _source = _source.copyWith(
                    keywords: {..._source.keywords, ...defaultNotificationKeywords}.toList(),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(texts.keywordsHint, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final word in _source.keywords)
              _KeywordChip(
                label: word,
                onRemove: () => setState(
                  () => _source = _source.copyWith(keywords: [..._source.keywords]..remove(word)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _keyword,
                decoration: InputDecoration(hintText: texts.keywordField),
                onSubmitted: (_) => _addKeyword(),
              ),
            ),
            const SizedBox(width: 8),
            DsButton.compact(label: texts.addKeyword, onPressed: _addKeyword),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.baseAll),
          child: DsSwitchRow(
            key: const ValueKey('notification-samples-switch'),
            leading: DsIconTile.child(
              size: DsIconTileSize.sm,
              child: Icon(Icons.history_toggle_off_rounded, size: 18, color: c.actionPrimary),
            ),
            title: texts.samplesToggle,
            subtitle: texts.samplesHint,
            value: samplesOn,
            onChanged: (value) => unawaited(_toggleSamples(on: value)),
          ),
        ),
        if (samplesOn) ...[
          const SizedBox(height: 14),
          Text(texts.samplesTitle, style: ds.typography.titleMd.copyWith(fontSize: 14)),
          const SizedBox(height: 8),
          if (state.samples.isEmpty)
            Text(texts.samplesEmpty, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
          for (final sample in state.samples.take(10))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.surfaceSunken,
                  borderRadius: DsRadius.baseAll,
                  border: Border.all(color: c.outlineSubtle),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sample.text, maxLines: 4, overflow: TextOverflow.ellipsis, style: ds.typography.bodySm),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: DsInlineAction(
                        label: texts.samplesFilter,
                        icon: Icons.bolt_rounded,
                        dense: true,
                        onPressed: () => unawaited(_pickFilterPhrase(sample)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Frasa filter: chip bersudut 8 dengan tombol hapus.
class _KeywordChip extends StatelessWidget {
  const _KeywordChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Container(
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: DsRadius.baseAll,
        border: Border.all(color: c.outlineSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(label, style: ds.typography.bodySm.copyWith(color: c.textPrimary)),
          ),
          Semantics(
            button: true,
            label: t.notificationCapture.removeKeywordLabel(word: label),
            child: InkResponse(
              onTap: onRemove,
              radius: 18,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.close_rounded, size: 14, color: c.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Satu aturan dompet: nomor, dompet, kata pengenalnya, dan hapus (ADR-042 §3.1).
class _WalletRuleCard extends StatefulWidget {
  const _WalletRuleCard({
    required this.index,
    required this.rule,
    required this.wallets,
    required this.onChanged,
    required this.onRemove,
    super.key,
  });

  final int index;
  final WalletRule rule;
  final List<Wallet> wallets;
  final ValueChanged<WalletRule> onChanged;
  final VoidCallback onRemove;

  @override
  State<_WalletRuleCard> createState() => _WalletRuleCardState();
}

class _WalletRuleCardState extends State<_WalletRuleCard> {
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
    final ds = context.ds;
    final c = ds.colors;
    final walletId = widget.wallets.any((w) => w.id == widget.rule.walletId) ? widget.rule.walletId : null;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: c.surfaceContainerHigh, borderRadius: BorderRadius.circular(8)),
            child: Text(
              '${widget.index}',
              style: ds.typography.labelMd.copyWith(color: c.actionPrimary, letterSpacing: 0),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WalletSelectField(
                  label: texts.walletLabel,
                  wallets: widget.wallets,
                  selectedId: walletId,
                  useDs: true,
                  onSelected: (id) => _changed(walletId: id),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _keywords,
                  decoration: InputDecoration(hintText: texts.walletRuleKeywordsField),
                  onChanged: (_) => _changed(),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: texts.walletRuleRemove,
            onPressed: widget.onRemove,
            icon: Icon(Icons.close_rounded, size: 18, color: c.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Lembar persetujuan menyimpan contoh notifikasi (ADR-042 §3.2).
class _SamplesConsentSheet extends StatelessWidget {
  const _SamplesConsentSheet();

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final ds = context.ds;
    final c = ds.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DsIconTile.child(
                child: Icon(Icons.history_toggle_off_rounded, size: 22, color: c.actionPrimary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(texts.samplesDisclosureTitle, style: ds.typography.headlineSm)),
            ],
          ),
          const SizedBox(height: 12),
          Text(texts.samplesDisclosureBody, style: ds.typography.bodyMd.copyWith(color: c.textSecondary)),
          const SizedBox(height: 20),
          DsButton(label: texts.samplesDisclosureAgree, expand: true, onPressed: () => Navigator.of(context).pop(true)),
          const SizedBox(height: 4),
          DsButton.ghost(
            label: texts.samplesDisclosureCancel,
            expand: true,
            onPressed: () => Navigator.of(context).pop(false),
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
    final ds = context.ds;
    final c = ds.colors;
    // Kata berangka tidak dipakai: nominal dan nomor berubah tiap notifikasi.
    final words = {
      for (final w in NotificationTemplate.words(widget.sample))
        if (w.text.length >= 3 && !RegExp(r'\d').hasMatch(w.text)) w.text.replaceAll(RegExp(r'[,.;:!?]+$'), ''),
    }.where((w) => w.length >= 3);
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 8, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(texts.samplesFilterTitle, style: ds.typography.headlineSm),
          const SizedBox(height: 4),
          Text(texts.samplesFilterHint, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final word in words) DsFilterChip(label: word, selected: false, onTap: () => _append(word)),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            key: const ValueKey('samples-phrase'),
            controller: _phrase,
            decoration: InputDecoration(hintText: texts.keywordField),
          ),
          const SizedBox(height: 16),
          DsButton(label: texts.addKeyword, expand: true, onPressed: () => Navigator.of(context).pop(_phrase.text)),
        ],
      ),
    );
  }
}
