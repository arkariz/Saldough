import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/core/utils/formatters/rupiah_input.dart';
import 'package:saldough/features/wallet/presentation/widgets/wallet_type.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Panjang nama dompet maksimum (rujukan visual: "Maks. 24 karakter").
const walletNameMaxLength = 24;

/// Nominal cepat saldo awal (rupiah, bukan sen), sesuai rujukan visual.
const _quickAmounts = [100000, 500000, 1000000, 5000000];

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
    required this.initialBalance,
  });

  /// Nama dompet.
  final String name;

  /// Kunci ikon.
  final String iconKey;

  /// Status aktif.
  final bool isActive;

  /// Saldo awal (sen). Pada mode sunting `null` berarti TIDAK diubah -- kolom
  /// saldo awal tidak disentuh pemakai, jadi nilai tersimpannya (yang bisa
  /// saja negatif atau bersen pecahan, tak terwakili kolom rupiah utuh) tidak
  /// boleh tertimpa.
  final int? initialBalance;
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
/// menjadi transaksi. Menyunting nama/ikon/status TIDAK mengubah saldo tercatat;
/// hanya mengganti saldo awal yang menghitungnya ulang (dikerjakan
/// `WalletBloc`, bukan formulir ini).
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
    // Hanya saldo awal yang terwakili kolom rupiah utuh yang diisi; yang lain
    // dibiarkan kosong dan tidak akan dikirim kecuali disentuh.
    if (wallet.initialBalance >= 0 && wallet.initialBalance % 100 == 0) {
      _balanceController.text = wallet.initialBalance == 0 ? '' : formatRupiahInput(wallet.initialBalance ~/ 100);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  void _setBalance(int rupiah) {
    final text = rupiah <= 0 ? '' : formatRupiahInput(rupiah);
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
    final sen = (parseRupiahInput(_balanceController.text) ?? 0) * 100;
    Navigator.of(context).pop(
      WalletFormSaved(
        name: _nameController.text.trim(),
        iconKey: _iconKey,
        isActive: _isActive,
        initialBalance: _editing && !_balanceTouched ? null : sen,
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
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final wallet = widget.initial;
    final bigStyle = textTheme.headlineMedium?.copyWith(fontSize: 30, fontWeight: FontWeight.w700);
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(editing: _editing, iconKey: _iconKey),
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(t.wallet.nameLabel, hint: t.wallet.nameRequiredHint),
              const SizedBox(height: AppSpacing.xs),
              TransactionSlab(
                radius: 4,
                shadow: 2,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: TextField(
                  controller: _nameController,
                  autofocus: !_editing,
                  maxLength: walletNameMaxLength,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: colors.accent,
                  onChanged: (_) => setState(() {}),
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: t.wallet.nameHint,
                    hintStyle: TextStyle(color: colors.textMuted),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, right: AppSpacing.xs),
                child: Text(
                  '${_nameController.text.characters.length}/$walletNameMaxLength · ${t.wallet.nameMaxHint}',
                  textAlign: TextAlign.end,
                  style: transactionLabelStyle(context, color: colors.textMuted).copyWith(fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(t.wallet.iconLabel),
              const SizedBox(height: AppSpacing.xs),
              // Tiga kolom sama lebar (ubin ke-4 dan ke-5 di baris kedua), bukan
              // ubin berlebar tetap yang menyisakan ruang kosong di kanan.
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = AppSpacing.xs;
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
              const SizedBox(height: AppSpacing.md),
              AppSectionLabel(t.wallet.initialBalanceLabel),
              const SizedBox(height: AppSpacing.xs),
              TransactionSlab(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                      decoration: BoxDecoration(color: colors.surfaceLow, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Text('Rp', style: PixelTypography.tabularMono(context, fontSize: 16, color: colors.accent)),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: TextField(
                              controller: _balanceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [RupiahInputFormatter()],
                              cursorColor: colors.accent,
                              style: bigStyle,
                              onChanged: (_) => setState(() => _balanceTouched = true),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                                hintText: '0',
                                hintStyle: bigStyle?.copyWith(color: colors.textMuted.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      t.wallet.initialBalanceHelp,
                      style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final amount in _quickAmounts)
                    AppQuickChip(
                      label: formatRupiahShort(amount),
                      onTap: () => _setBalance((parseRupiahInput(_balanceController.text) ?? 0) + amount),
                    ),
                  AppQuickChip(
                    label: t.record.clearAmountAction,
                    color: colors.tinted(colors.pending, 0.22),
                    onTap: () => _setBalance(0),
                  ),
                ],
              ),
              if (wallet != null) ...[
                const SizedBox(height: AppSpacing.md),
                _CurrentBalanceCard(wallet: wallet),
                const SizedBox(height: AppSpacing.md),
                TransactionSlab(
                  radius: 4,
                  shadow: 2,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.wallet.activeSwitchLabel,
                              style: textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              t.wallet.activeSwitchHelp,
                              style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Switch(
                        value: _isActive,
                        activeThumbColor: colors.onAccent,
                        activeTrackColor: colors.accent,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: _editing ? t.transaction.saveChangesAction : t.wallet.saveAddAction,
                onPressed: _canSave ? _save : null,
              ),
              if (wallet != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppButton(label: t.wallet.deleteAction, color: colors.expense, onPressed: _delete),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  t.wallet.deleteHelp,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: colors.textMuted),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.wallet.privacyNote,
                textAlign: TextAlign.center,
                style: transactionLabelStyle(context, color: colors.textMuted).copyWith(fontWeight: FontWeight.w400),
              ),
            ],
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
    final colors = context.appColors;
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.surfaceHigh, borderRadius: BorderRadius.circular(8)),
            child: const AppIcon(IconKey.chevronLeft, size: 28),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Column(
              children: [
                Text(
                  (editing ? t.wallet.editStepLabel : t.wallet.addStepLabel).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: transactionLabelStyle(context, color: colors.accent),
                ),
                Text(
                  editing ? t.wallet.editTitle : t.wallet.addTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22, height: 1.2),
                ),
              ],
            ),
          ),
        ),
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: colors.surfaceMid, borderRadius: BorderRadius.circular(8)),
          child: AppIcon(walletIconKey(iconKey), size: 28),
        ),
      ],
    );
  }
}

/// Satu ubin pilihan ikon/jenis dompet: ikon di atas, label jenis di bawah.
class _IconChoice extends StatelessWidget {
  const _IconChoice({required this.iconKey, required this.selected, required this.onTap});

  final IconKey iconKey;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? colors.tinted(colors.accent, 0.16) : colors.surfaceLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? colors.accent : Colors.transparent, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(iconKey, size: 36),
            const SizedBox(height: 4),
            Text(
              (walletTypeLabel(iconKey.name) ?? '').toUpperCase(),
              textAlign: TextAlign.center,
              style: transactionLabelStyle(
                context,
                size: 9,
                color: selected ? colors.accent : colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Saldo tercatat saat ini (hanya baca) beserta catatan bahwa mengubah saldo
/// awal menghitungnya ulang -- selisih dengan uang nyata dicatat lewat CATAT.
class _CurrentBalanceCard extends StatelessWidget {
  const _CurrentBalanceCard({required this.wallet});

  final Wallet wallet;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            t.wallet.currentBalanceLabel.toUpperCase(),
            style: transactionLabelStyle(context, color: colors.textMuted),
          ),
          const SizedBox(height: 2),
          FitStart(
            child: Text(
              AppMoneyFormatter.format(wallet.currentBalance),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: wallet.currentBalance < 0 ? colors.expense : colors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            t.wallet.editBalanceNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}
