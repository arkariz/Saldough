import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/notification_capture/domain/entities/notification_pattern.dart';
import 'package:saldough/features/notification_capture/domain/services/notification_template.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Nama jenis pola untuk tampilan.
String patternKindLabel(NotificationPatternKind kind) => switch (kind) {
  NotificationPatternKind.expense => t.notificationCapture.kindExpense,
  NotificationPatternKind.income => t.notificationCapture.kindIncome,
  NotificationPatternKind.transferOut => t.notificationCapture.kindTransferOut,
  NotificationPatternKind.transferIn => t.notificationCapture.kindTransferIn,
};

/// Membuka pembuat pola (ADR-032 §3.3): dari [sample] (teks notifikasi asli)
/// dengan menandai kata, atau menyunting [initial]. Mengembalikan pola yang
/// disimpan, atau `null`.
Future<NotificationPattern?> openNotificationPatternPage(
  BuildContext context, {
  required String packageName,
  required List<Wallet> wallets,
  NotificationPattern? initial,
  String sample = '',
}) => Navigator.of(context).push(
  MaterialPageRoute<NotificationPattern>(
    builder: (_) =>
        NotificationPatternPage(packageName: packageName, wallets: wallets, initial: initial, sample: sample),
  ),
);

/// Pembuat pola (ADR-032 §3.9): pilih penanda (Nominal/Catatan/Abaikan),
/// lalu ketuk kata. Templat dibentuk otomatis; templat mentah terlipat.
class NotificationPatternPage extends StatefulWidget {
  /// Membuat [NotificationPatternPage].
  const NotificationPatternPage({
    required this.packageName,
    required this.wallets,
    this.initial,
    this.sample = '',
    super.key,
  });

  /// Paket aplikasi sumber.
  final String packageName;

  /// Dompet aktif (untuk lawan transfer).
  final List<Wallet> wallets;

  /// Pola yang disunting, atau `null` untuk pola baru.
  final NotificationPattern? initial;

  /// Teks contoh.
  final String sample;

  @override
  State<NotificationPatternPage> createState() => _NotificationPatternPageState();
}

class _NotificationPatternPageState extends State<NotificationPatternPage> {
  late final _sample = TextEditingController(text: widget.sample);
  late final _template = TextEditingController(text: widget.initial?.template ?? '');
  late final _label = TextEditingController(text: widget.initial?.label ?? '');
  late NotificationPatternKind _kind = widget.initial?.kind ?? NotificationPatternKind.expense;
  late String? _categoryId = widget.initial?.categoryId;
  late String? _transferWalletId = widget.initial?.transferWalletId;
  final _roles = <int, TemplateWordRole>{};
  TemplateWordRole _brush = TemplateWordRole.amount;
  String? _markError;
  // Templat mentah hanya untuk yang paham; terbuka bila tidak ada contoh
  // (menyunting pola lama).
  late bool _showTemplate = widget.sample.trim().isEmpty;

  @override
  void dispose() {
    _sample.dispose();
    _template.dispose();
    _label.dispose();
    super.dispose();
  }

  /// Memberi kata ke-[index] peran [_brush]; ketuk lagi dengan penanda yang
  /// sama menghapusnya. Sesudah nominal ditandai, penanda pindah ke Catatan.
  void _mark(int index, String word) {
    final brush = _brush;
    if (brush == TemplateWordRole.amount && !NotificationTemplate.isAmountWord(word)) {
      setState(() => _markError = t.notificationCapture.patternNotAmount(word: word));
      return;
    }
    setState(() {
      _markError = null;
      if (_roles[index] == brush) {
        _roles.remove(index);
      } else {
        if (brush == TemplateWordRole.amount) {
          _roles.removeWhere((_, role) => role == TemplateWordRole.amount);
          _brush = TemplateWordRole.note;
        }
        _roles[index] = brush;
      }
      _template.text = NotificationTemplate.fromSample(_sample.text, _roles) ?? '';
    });
  }

  void _setKind(_KindChoice choice) => setState(() {
    _kind = switch (choice) {
      _KindChoice.expense => NotificationPatternKind.expense,
      _KindChoice.income => NotificationPatternKind.income,
      _KindChoice.transfer =>
        _kind == NotificationPatternKind.income || _kind == NotificationPatternKind.transferIn
            ? NotificationPatternKind.transferIn
            : NotificationPatternKind.transferOut,
    };
  });

  bool get _isTransfer => _kind == NotificationPatternKind.transferOut || _kind == NotificationPatternKind.transferIn;

  NotificationTemplateMatch? get _preview {
    final sample = _sample.text.trim();
    if (sample.isEmpty) return null;
    return NotificationTemplate.match(_template.text.trim(), sample);
  }

  bool get _canSave {
    final template = _template.text.trim();
    if (!NotificationTemplate.isValid(template)) return false;
    return _sample.text.trim().isEmpty || _preview != null;
  }

  void _save() {
    final template = _template.text.trim();
    final label = _label.text.trim();
    Navigator.of(context).pop(
      NotificationPattern(
        id: widget.initial?.id ?? 'user.${DateTime.now().microsecondsSinceEpoch}',
        packageName: widget.packageName,
        label: label.isEmpty
            ? template.replaceAll(RegExp(r'\{[^}]*\}'), '').trim().split(RegExp(r'\s+')).take(3).join(' ')
            : label,
        template: template,
        kind: _kind,
        categoryId: _isTransfer ? null : _categoryId,
        transferWalletId: _isTransfer ? _transferWalletId : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final texts = t.notificationCapture;
    final textTheme = Theme.of(context).textTheme;
    final colors = context.appColors;
    final words = NotificationTemplate.words(_sample.text);
    final preview = _preview;
    final categoryKind = _kind == NotificationPatternKind.income ? CategoryKind.income : CategoryKind.expense;
    final categories = [
      for (final c in ActiveCategories.notifier.value)
        if (!c.isArchived && c.kind == categoryKind) c,
    ];
    final categoryId = categories.any((c) => c.id == _categoryId) ? _categoryId : null;
    final transferWalletId = widget.wallets.any((w) => w.id == _transferWalletId) ? _transferWalletId : null;
    final selectedCategory = categories.where((c) => c.id == categoryId).firstOrNull;
    final transferWallet = widget.wallets.where((w) => w.id == transferWalletId).firstOrNull;
    final kindChoice = _isTransfer
        ? _KindChoice.transfer
        : (_kind == NotificationPatternKind.income ? _KindChoice.income : _KindChoice.expense);
    return Scaffold(
      appBar: AppBar(title: Text(texts.patternTitle)),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: AppButton(label: texts.save, onPressed: _canSave ? _save : null),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            AppSectionLabel(texts.patternSampleLabel),
            const SizedBox(height: AppSpacing.xs),
            TextField(
              key: const ValueKey('pattern-sample'),
              controller: _sample,
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(hintText: texts.patternSampleHint),
              onChanged: (_) => setState(() {
                _roles.clear();
                _brush = TemplateWordRole.amount;
                _markError = null;
              }),
            ),
            if (words.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              AppSectionLabel(texts.patternMarkLabel),
              const SizedBox(height: AppSpacing.xs),
              AppSegmented<TemplateWordRole>(
                key: const ValueKey('pattern-brush'),
                options: [
                  (TemplateWordRole.amount, texts.roleAmount),
                  (TemplateWordRole.note, texts.roleNote),
                  (TemplateWordRole.ignore, texts.roleIgnore),
                ],
                selected: _brush,
                onChanged: (brush) => setState(() => _brush = brush),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(texts.patternInstructions, style: textTheme.bodySmall?.copyWith(color: colors.textMuted)),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final (i, word) in words.indexed)
                    _WordChip(word: word.text, role: _roles[i], onTap: () => _mark(i, word.text)),
                ],
              ),
              if (_markError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(_markError!, style: textTheme.bodySmall?.copyWith(color: colors.expense)),
              ],
            ],
            const SizedBox(height: AppSpacing.md),
            if (_template.text.trim().isNotEmpty && !_canSave)
              Text(texts.patternInvalid, style: textTheme.bodySmall?.copyWith(color: colors.expense))
            else if (preview != null)
              AppHardCard(
                key: const ValueKey('pattern-preview'),
                elevation: AppHardElevation.flat,
                color: Color.alphaBlend(colors.income.withValues(alpha: 0.12), colors.cardBackground),
                child: Text(
                  [
                    texts.patternPreview(amount: preview.amountText),
                    if (preview.note != null) preview.note!,
                  ].join(' · '),
                  style: textTheme.bodyMedium,
                ),
              ),
            if (!_showTemplate)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _showTemplate = true),
                  child: Text(texts.patternTemplateToggle),
                ),
              )
            else ...[
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(texts.patternsTitle),
              const SizedBox(height: AppSpacing.xs),
              TextField(
                key: const ValueKey('pattern-template'),
                controller: _template,
                minLines: 1,
                maxLines: 4,
                style: textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                onChanged: (_) => setState(() {}),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            AppSectionLabel(texts.patternKindLabel),
            const SizedBox(height: AppSpacing.xs),
            AppSegmented<_KindChoice>(
              key: const ValueKey('pattern-kind'),
              options: [
                (_KindChoice.expense, texts.kindExpense),
                (_KindChoice.income, texts.kindIncome),
                (_KindChoice.transfer, texts.kindTransfer),
              ],
              selected: kindChoice,
              onChanged: _setKind,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_isTransfer) ...[
              AppSectionLabel(texts.transferDirectionLabel),
              const SizedBox(height: AppSpacing.xs),
              AppSegmented<NotificationPatternKind>(
                options: [
                  (NotificationPatternKind.transferOut, texts.kindExpense),
                  (NotificationPatternKind.transferIn, texts.kindIncome),
                ],
                selected: _kind,
                onChanged: (kind) => setState(() => _kind = kind),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(texts.patternTransferWallet, hint: texts.advancedHint),
              const SizedBox(height: AppSpacing.xs),
              AppMenuSelectButton<String>(
                icon: transferWallet == null ? IconKey.wallets : walletIconKey(transferWallet.iconKey),
                label: transferWallet?.name ?? texts.patternTransferWalletNone,
                isPlaceholder: transferWallet == null,
                wrapLabel: true,
                allLabel: texts.patternTransferWalletNone,
                allIcon: IconKey.close,
                options: [
                  for (final w in widget.wallets) (value: w.id, label: w.name, icon: walletIconKey(w.iconKey)),
                ],
                onSelected: (id) => setState(() => _transferWalletId = id),
              ),
            ] else ...[
              AppSectionLabel(texts.patternCategory, hint: texts.advancedHint),
              const SizedBox(height: AppSpacing.xs),
              AppMenuSelectButton<String>(
                icon: selectedCategory == null ? IconKey.categoryOther : categoryIcon(selectedCategory),
                label: selectedCategory?.name ?? texts.patternNoCategory,
                isPlaceholder: selectedCategory == null,
                wrapLabel: true,
                allLabel: texts.patternNoCategory,
                allIcon: IconKey.close,
                options: [for (final c in categories) (value: c.id, label: c.name, icon: categoryIcon(c))],
                onSelected: (id) => setState(() => _categoryId = id),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _label,
              maxLength: 40,
              decoration: InputDecoration(labelText: texts.patternLabelField),
            ),
          ],
        ),
      ),
    );
  }
}

enum _KindChoice { expense, income, transfer }

class _WordChip extends StatelessWidget {
  const _WordChip({required this.word, required this.role, required this.onTap});

  final String word;
  final TemplateWordRole? role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final texts = t.notificationCapture;
    final (color, tag) = switch (role) {
      TemplateWordRole.amount => (colors.income, texts.roleAmount),
      TemplateWordRole.note => (colors.transfer, texts.roleNote),
      TemplateWordRole.ignore => (colors.textMuted, texts.roleIgnore),
      TemplateWordRole.literal || null => (null, null),
    };
    return ActionChip(
      label: Text(tag == null ? word : '$word · $tag'),
      backgroundColor: color?.withValues(alpha: 0.18),
      side: color == null ? null : BorderSide(color: color, width: 2),
      onPressed: onTap,
    );
  }
}
