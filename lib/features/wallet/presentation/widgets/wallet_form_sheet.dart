import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_type.dart';
import 'package:saldough/shared/transaction/transaction_presentation.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Panjang nama dompet maksimum (rujukan visual: "Maks. 24 karakter").
const walletNameMaxLength = 24;

/// Hasil formulir dompet, dikembalikan lewat `Navigator.pop`; `null` berarti
/// dibatalkan.
sealed class WalletFormResult {
  /// Membuat [WalletFormResult].
  const WalletFormResult();
}

/// Formulir disimpan.
final class WalletFormSaved extends WalletFormResult {
  /// Membuat [WalletFormSaved].
  const WalletFormSaved({
    required this.name,
    required this.iconKey,
    required this.isActive,
    required this.balance,
    this.colorKey,
  });

  /// Warna latar kartu, `null` = bawaan.
  final String? colorKey;

  /// Nama dompet.
  final String name;

  /// Kunci ikon.
  final String iconKey;

  /// Status aktif.
  final bool isActive;

  /// Saldo (sen). Mode tambah: saldo awal. Mode sunting: saldo SAAT INI yang
  /// dikehendaki, dan `null` berarti TIDAK diubah -- kolom tidak disentuh
  /// pemakai, jadi nilai tersimpannya (yang bisa saja negatif atau bersen
  /// pecahan, tak terwakili kolom rupiah utuh) tidak boleh tertimpa.
  final int? balance;
}

/// Pemakai menekan "Hapus Dompet" dan sudah mengonfirmasi.
final class WalletFormDeleted extends WalletFormResult {
  /// Membuat [WalletFormDeleted].
  const WalletFormDeleted();
}

/// Formulir tambah dan sunting dompet (FR-WAL-001/002), layar penuh lewat
/// `showFullScreenSheet`. Tata letaknya mengikuti rujukan visual
/// `pixel_kas_tambah_dompet` dan `pixel_kas_ubah_dompet`: nama, ikon,
/// saldo awal dengan pilihan cepat, dan -- saat menyunting -- saldo tercatat,
/// sakelar aktif, serta hapus.
///
/// ⚠ Saldo awal adalah pernyataan keadaan, bukan setoran: ia tidak pernah
/// menjadi transaksi. Saat menyunting, kolom saldo berarti saldo SEKARANG;
/// selisihnya dicatat `WalletBloc` sebagai penyesuaian saldo (ADR-047), dan
/// formulir ini hanya menampilkan pratinjaunya (rupa B-99). Saldo boleh
/// negatif lewat tombol ±. Menyunting nama/ikon/status TIDAK mengubah saldo.
///
/// ⚠ Dompet tidak punya jenis: pilihan ikon hanya tampilan (WEALTH_ASSETS
/// keputusan 11). Bagian rujukan yang sengaja tidak dibangun: "Tipe kategori", "Catatan tambahan" dan subjudul
/// dompet (`Wallet` tidak punya field catatan), lencana "UTAMA" dan tombol
/// "Atur Urutan" (tidak ada konsep dompet utama/urutan di domain).
class WalletFormSheet extends StatefulWidget {
  /// Membuat [WalletFormSheet]. [initial] `null` = dompet baru.
  const WalletFormSheet({this.initial, super.key});

  /// Dompet yang disunting, atau `null` untuk dompet baru.
  final Wallet? initial;

  @override
  State<WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends State<WalletFormSheet> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _iconKey = IconKey.walletBank.name;
  bool _isActive = true;
  bool _balanceTouched = false;

  /// Tanda kolom saldo; besarannya ada di [_balanceController].
  bool _negative = false;

  /// Warna latar kartu; `null` = bawaan.
  String? _colorKey;

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final wallet = widget.initial;
    if (wallet == null) return;
    _nameController.text = wallet.name;
    _iconKey = wallet.iconKey;
    _isActive = wallet.isActive;
    _colorKey = wallet.colorKey;
    // Saldo negatif dan bersen pecahan tetap tampil (rupa B-99): tanda lewat
    // [_negative], dan mata uang tanpa desimal menampilkan bagian utuhnya.
    // Kolom yang tidak disentuh tidak pernah dikirim, jadi tidak mengubah
    // saldo tersimpan.
    _negative = wallet.currentBalance < 0;
    final magnitude = wallet.currentBalance.abs();
    _balanceController.text = magnitude == 0 ? '' : formatMoneyInput(magnitude);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  /// Saldo yang diisi, bertanda, dalam sen.
  int get _targetSen {
    final magnitude = parseMoneyInput(_balanceController.text) ?? 0;
    return _negative ? -magnitude : magnitude;
  }

  /// Selisih terhadap saldo tercatat bila kolom sudah diubah, selain itu 0.
  int get _difference {
    final wallet = widget.initial;
    if (wallet == null || !_balanceTouched) return 0;
    return _targetSen - wallet.currentBalance;
  }

  void _toggleSign() => setState(() {
    _negative = !_negative;
    _balanceTouched = true;
  });

  void _setBalance(int sen, {bool resetSign = false}) {
    final text = sen <= 0 ? '' : formatMoneyInput(sen);
    setState(() {
      _balanceTouched = true;
      if (resetSign) _negative = false;
      _balanceController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _save() {
    if (!_canSave) return;
    Navigator.of(context).pop(
      WalletFormSaved(
        name: _nameController.text.trim(),
        iconKey: _iconKey,
        isActive: _isActive,
        balance: _editing && !_balanceTouched ? null : _targetSen,
        colorKey: _colorKey,
      ),
    );
  }

  Future<void> _delete() async {
    final wallet = widget.initial;
    if (wallet == null) return;
    final confirmed = await showConfirmDelete(
      context,
      title: t.wallet.deleteConfirmTitle,
      message: t.wallet.deleteConfirmMessage(name: wallet.name),
    );
    if (confirmed && mounted) Navigator.of(context).pop(const WalletFormDeleted());
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final wallet = widget.initial;
    final bigStyle = ds.typography.displayLg.copyWith(
      fontSize: 30,
      height: 1.2,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(DsSpacing.md, DsSpacing.md, DsSpacing.md, DsSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(editing: _editing, iconKey: _iconKey),
              const SizedBox(height: DsSpacing.md),
              _FieldLabel(t.wallet.nameLabel, hint: t.wallet.nameRequiredHint),
              const SizedBox(height: DsSpacing.xs),
              DsCard(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: TextField(
                  controller: _nameController,
                  autofocus: !_editing,
                  maxLength: walletNameMaxLength,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: c.actionPrimary,
                  style: ds.typography.bodyMd.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                  onChanged: (_) => setState(() {}),
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    filled: false,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: t.wallet.nameHint,
                    hintStyle: ds.typography.bodyMd.copyWith(fontSize: 15, color: c.textMuted),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, right: DsSpacing.xs),
                child: Text(
                  '${_nameController.text.characters.length}/$walletNameMaxLength · ${t.wallet.nameMaxHint}',
                  textAlign: TextAlign.end,
                  style: ds.typography.bodySm.copyWith(fontSize: 11, color: c.textMuted),
                ),
              ),
              const SizedBox(height: DsSpacing.md),
              _FieldLabel(t.wallet.iconLabel),
              const SizedBox(height: DsSpacing.xs),
              // Sama seperti pemilih ikon kategori: ubin ikon 48dp tanpa label.
              // Ikon dompet hanya tampilan, bukan jenis (WEALTH_ASSETS keputusan 11).
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (final (i, choice) in walletIconChoices.indexed)
                    _IconChoice(
                      iconKey: choice,
                      index: i,
                      selected: walletIconKey(_iconKey) == choice,
                      onTap: () => setState(() => _iconKey = choice.name),
                    ),
                ],
              ),
              const SizedBox(height: DsSpacing.md),
              _FieldLabel(t.wallet.colorLabel),
              const SizedBox(height: DsSpacing.xs),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  _ColorChoice(
                    pair: null,
                    label: t.wallet.colorDefault,
                    selected: _colorKey == null,
                    onTap: () => setState(() => _colorKey = null),
                  ),
                  for (final (i, key) in walletColorChoices.indexed)
                    _ColorChoice(
                      key: ValueKey('wallet-color-$key'),
                      pair: walletColorPair(c, key),
                      label: t.wallet.colorOption(n: i + 1),
                      selected: _colorKey == key,
                      onTap: () => setState(() => _colorKey = key),
                    ),
                ],
              ),
              const SizedBox(height: DsSpacing.md),
              _FieldLabel(_editing ? t.wallet.currentBalanceLabel : t.wallet.initialBalanceLabel),
              const SizedBox(height: DsSpacing.xs),
              DsCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: DsRadius.mdAll),
                      child: Row(
                        children: [
                          _SignToggle(negative: _negative, onTap: _toggleSign),
                          const SizedBox(width: 4),
                          Text(
                            '${_negative ? '−' : ''}${ActiveCurrency.value.symbol}',
                            style: ds.typography.headlineSm.copyWith(color: c.actionPrimary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _balanceController,
                              keyboardType: moneyKeyboardType,
                              inputFormatters: [MoneyInputFormatter()],
                              cursorColor: c.actionPrimary,
                              style: bigStyle,
                              onChanged: (_) => setState(() => _balanceTouched = true),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                filled: false,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                                hintText: '0',
                                hintStyle: bigStyle.copyWith(color: c.textMuted.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_difference != 0) ...[
                      Text(
                        t.assets.adjust.preview(amount: signedAdjustmentText(_difference)),
                        key: const ValueKey('wallet-adjust-preview'),
                        style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700, color: c.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.assets.adjust.previewHint,
                        style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                      ),
                    ] else
                      Text(
                        _editing ? t.wallet.editBalanceNote : t.wallet.initialBalanceHelp,
                        style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Satu baris horizontal: chip sama lebar berbagi lebar layar.
              Builder(
                builder: (context) {
                  final chips = <Widget>[
                    for (final amount in ActiveCurrency.value.quickAmounts(QuickAmountMultipliers.walletBalance))
                      _QuickChip(
                        label: formatQuickAmount(amount),
                        onTap: () => _setBalance((parseMoneyInput(_balanceController.text) ?? 0) + amount),
                      ),
                    _QuickChip(label: t.record.clearAmountAction, onTap: () => _setBalance(0, resetSign: true)),
                  ];
                  return Row(
                    children: [
                      for (final (i, chip) in chips.indexed) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(child: chip),
                      ],
                    ],
                  );
                },
              ),
              if (wallet != null) ...[
                const SizedBox(height: DsSpacing.md),
                DsCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.wallet.activeSwitchLabel,
                              style: ds.typography.bodyMd.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              t.wallet.activeSwitchHelp,
                              style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(value: _isActive, onChanged: (value) => setState(() => _isActive = value)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: DsSpacing.lg),
              DsButton(
                label: _editing ? t.transaction.saveChangesAction : t.wallet.saveAddAction,
                expand: true,
                onPressed: _canSave ? _save : null,
              ),
              if (wallet != null) ...[
                const SizedBox(height: DsSpacing.lg),
                DsButton.danger(label: t.wallet.deleteAction, expand: true, onPressed: _delete),
                const SizedBox(height: DsSpacing.xs),
                Text(
                  t.wallet.deleteHelp,
                  textAlign: TextAlign.center,
                  style: ds.typography.bodySm.copyWith(color: c.textSecondary),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                t.wallet.privacyNote,
                textAlign: TextAlign.center,
                style: ds.typography.bodySm.copyWith(fontSize: 11, color: c.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Label bagian formulir: huruf piksel kecil, dengan petunjuk opsional di
/// kanan.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.hint});

  final String label;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Row(
      children: [
        Expanded(
          child: Text(label, style: ds.typography.pixelCaption.copyWith(color: c.textMuted, fontSize: 10)),
        ),
        if (hint != null) Text(hint!, style: ds.typography.bodySm.copyWith(fontSize: 11, color: c.textMuted)),
      ],
    );
  }
}

/// Chip penambah saldo awal (+, Hapus).
/// Tombol ± di kiri simbol mata uang (rupa B-99): membalik tanda saldo.
/// Saldo negatif bukan kesalahan (FR-WAL-003), jadi tanpa warna bahaya.
class _SignToggle extends StatelessWidget {
  const _SignToggle({required this.negative, required this.onTap});

  final bool negative;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return Semantics(
      button: true,
      toggled: negative,
      label: t.assets.adjust.signToggle,
      excludeSemantics: true,
      child: DsPressable(
        onPressed: onTap,
        pressedScale: 0.92,
        builder: (context, _) => SizedBox.square(
          dimension: 48,
          child: Center(
            child: Container(
              key: const ValueKey('wallet-sign-toggle'),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: negative ? c.surfaceCard : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(color: c.outlineSubtle),
              ),
              child: Icon(Symbols.exposure_rounded, size: 18, color: c.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    return DsPressable(
      onPressed: onTap,
      pressedScale: 0.95,
      builder: (context, _) => Container(
        constraints: const BoxConstraints(minHeight: 40),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: DsRadius.mdAll,
          border: Border.all(color: c.outlineSubtle),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: ds.typography.labelMd.copyWith(color: c.textPrimary, fontSize: 12),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.editing, required this.iconKey});

  final bool editing;
  final String iconKey;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final asset = ClayIcons.forIcon(walletIconKey(iconKey)) ?? ClayIcons.walletNav;
    return Row(
      children: [
        DsIconButton(icon: Icons.chevron_left, label: t.common.close, onPressed: () => Navigator.of(context).pop()),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Text(
                  editing ? t.wallet.editStepLabel : t.wallet.addStepLabel,
                  textAlign: TextAlign.center,
                  style: ds.typography.pixelCaption.copyWith(color: ds.colors.actionPrimary, fontSize: 10),
                ),
                Semantics(
                  header: true,
                  child: Text(
                    editing ? t.wallet.editTitle : t.wallet.addTitle,
                    textAlign: TextAlign.center,
                    style: ds.typography.headlineSm.copyWith(fontSize: 20),
                  ),
                ),
              ],
            ),
          ),
        ),
        DsWiggle(trigger: iconKey.hashCode, child: DsIconTile.asset(asset: asset)),
      ],
    );
  }
}

/// Satu ubin pilihan ikon dompet, sama seperti pemilih ikon kategori: ikon
/// clay di kotak 48dp tanpa label; yang terpilih berwarna aksi preset.
class _IconChoice extends StatelessWidget {
  const _IconChoice({required this.iconKey, required this.index, required this.selected, required this.onTap});

  final IconKey iconKey;
  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final asset = ClayIcons.forIcon(iconKey) ?? ClayIcons.walletNav;
    return Semantics(
      button: true,
      selected: selected,
      label: t.wallet.iconOption(n: index + 1),
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('wallet-icon-${iconKey.name}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: DsIconTile.asset(
              asset: asset,
              category: selected ? DsColorPair(c.actionPrimary, c.actionPrimary.withValues(alpha: 0.14)) : null,
            ),
          ),
        ),
      ),
    );
  }
}

/// Satu pilihan warna latar kartu: lingkaran 48dp berisi warna "container"
/// palet (bawaan: warna kartu biasa); yang terpilih bercincin warna aksi dan
/// bertanda centang.
class _ColorChoice extends StatelessWidget {
  const _ColorChoice({required this.pair, required this.label, required this.selected, required this.onTap, super.key});

  final DsColorPair? pair;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final fill = pair?.container ?? c.surfaceCard;
    final edge = pair?.color ?? c.outlineSubtle;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: AnimatedContainer(
              duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.standard,
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? c.actionPrimary : edge, width: selected ? 2.5 : 1.5),
              ),
              child: selected ? Icon(Icons.check, size: 18, color: pair?.color ?? c.actionPrimary) : null,
            ),
          ),
        ),
      ),
    );
  }
}
