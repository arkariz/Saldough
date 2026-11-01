import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_type.dart';
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
  });

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
/// `pixel_kas_tambah_dompet` dan `pixel_kas_ubah_dompet`: nama, ikon jenis,
/// saldo awal dengan pilihan cepat, dan -- saat menyunting -- saldo tercatat,
/// sakelar aktif, serta hapus.
///
/// ⚠ Saldo awal adalah pernyataan keadaan, bukan setoran: ia tidak pernah
/// menjadi transaksi. Saat menyunting, kolom saldo berarti saldo SAAT INI;
/// menggesernya dari saldo awal dikerjakan `WalletBloc`, bukan formulir ini.
/// Menyunting nama/ikon/status TIDAK mengubah saldo tercatat.
///
/// ⚠ Bagian rujukan yang sengaja tidak dibangun: "Tipe kategori" (sama dengan
/// pilihan ikon, jenis diturunkan dari ikon), "Catatan tambahan" dan subjudul
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

  bool get _editing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final wallet = widget.initial;
    if (wallet == null) return;
    _nameController.text = wallet.name;
    _iconKey = wallet.iconKey;
    _isActive = wallet.isActive;
    // Hanya saldo yang bisa ditulis utuh di kolom yang diisi; yang lain
    // dibiarkan kosong dan tidak akan dikirim kecuali disentuh.
    if (wallet.currentBalance >= 0 && isMoneyInputExact(wallet.currentBalance)) {
      _balanceController.text = wallet.currentBalance == 0 ? '' : formatMoneyInput(wallet.currentBalance);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  void _setBalance(int sen) {
    final text = sen <= 0 ? '' : formatMoneyInput(sen);
    setState(() {
      _balanceTouched = true;
      _balanceController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    });
  }

  void _save() {
    if (!_canSave) return;
    final sen = parseMoneyInput(_balanceController.text) ?? 0;
    Navigator.of(context).pop(
      WalletFormSaved(
        name: _nameController.text.trim(),
        iconKey: _iconKey,
        isActive: _isActive,
        balance: _editing && !_balanceTouched ? null : sen,
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
              // Tiga kolom sama lebar (ubin ke-4 dan ke-5 di baris kedua), bukan
              // ubin berlebar tetap yang menyisakan ruang kosong di kanan.
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = 8.0;
                  final tileWidth = (constraints.maxWidth - 2 * gap) / 3;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final choice in walletIconChoices)
                        SizedBox(
                          width: tileWidth,
                          child: _IconChoice(
                            iconKey: choice,
                            selected: walletIconKey(_iconKey) == choice,
                            onTap: () => setState(() => _iconKey = choice.name),
                          ),
                        ),
                    ],
                  );
                },
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
                          Text(
                            ActiveCurrency.value.symbol,
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
                    _QuickChip(label: t.record.clearAmountAction, onTap: () => _setBalance(0)),
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

/// Satu ubin pilihan jenis dompet: ikon clay di atas, label jenis di bawah.
/// Terpilih: bingkai dan latar warna aksi preset, ikon bergoyang.
class _IconChoice extends StatelessWidget {
  const _IconChoice({required this.iconKey, required this.selected, required this.onTap});

  final IconKey iconKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final asset = ClayIcons.forIcon(iconKey) ?? ClayIcons.walletNav;
    final label = walletTypeLabel(iconKey.name) ?? '';
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: DsPressable(
        onPressed: onTap,
        pressedScale: 0.96,
        dimWhenDisabled: false,
        builder: (context, _) => AnimatedContainer(
          duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.standard,
          constraints: const BoxConstraints(minHeight: 92),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.actionPrimary.withValues(alpha: 0.08) : c.surfaceCard,
            borderRadius: DsRadius.lgAll,
            border: Border.all(color: selected ? c.actionPrimary.withValues(alpha: 0.6) : c.outlineSubtle),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DsWiggle(
                trigger: selected ? 1 : 0,
                child: DsIconTile.asset(
                  asset: asset,
                  category: selected ? DsColorPair(c.actionPrimary, c.actionPrimary.withValues(alpha: 0.14)) : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ds.typography.labelMd.copyWith(
                  fontSize: 11,
                  letterSpacing: 0,
                  color: selected ? c.actionPrimary : c.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
