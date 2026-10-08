import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
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
    // Hanya saldo awal yang bisa ditulis utuh di kolom yang diisi; yang lain
    // dibiarkan kosong dan tidak akan dikirim kecuali disentuh.
    if (wallet.initialBalance >= 0 && isMoneyInputExact(wallet.initialBalance)) {
      _balanceController.text = wallet.initialBalance == 0 ? '' : formatMoneyInput(wallet.initialBalance);
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
          padding: const EdgeInsets.fromLTRB(AppSpacing.space4, AppSpacing.space4, AppSpacing.space4, AppSpacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(editing: _editing, iconKey: _iconKey),
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.wallet.nameLabel, hint: t.wallet.nameRequiredHint),
              const SizedBox(height: AppSpacing.space1),
              TransactionSlab(
                radius: 4,
                shadow: 2,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
                child: TextField(
                  controller: _nameController,
                  autofocus: !_editing,
                  maxLength: walletNameMaxLength,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: colors.brand,
                  onChanged: (_) => setState(() {}),
                  buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: t.wallet.nameHint,
                    hintStyle: TextStyle(color: colors.ink2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, right: AppSpacing.space1),
                child: Text(
                  '${_nameController.text.characters.length}/$walletNameMaxLength · ${t.wallet.nameMaxHint}',
                  textAlign: TextAlign.end,
                  style: transactionLabelStyle(context, color: colors.ink2).copyWith(fontWeight: FontWeight.w400),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.wallet.iconLabel),
              const SizedBox(height: AppSpacing.space1),
              // Tiga kolom sama lebar (ubin ke-4 dan ke-5 di baris kedua), bukan
              // ubin berlebar tetap yang menyisakan ruang kosong di kanan.
              LayoutBuilder(
                builder: (context, constraints) {
                  const gap = AppSpacing.space1;
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
              const SizedBox(height: AppSpacing.space4),
              AppSectionLabel(t.wallet.initialBalanceLabel),
              const SizedBox(height: AppSpacing.space1),
              TransactionSlab(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2, vertical: AppSpacing.space1),
                      decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Text(ActiveCurrency.value.symbol, style: context.numberStyles.amount.copyWith(color: colors.brand)),
                          const SizedBox(width: AppSpacing.space2),
                          Expanded(
                            child: TextField(
                              controller: _balanceController,
                              keyboardType: moneyKeyboardType,
                              inputFormatters: [MoneyInputFormatter()],
                              cursorColor: colors.brand,
                              style: bigStyle,
                              onChanged: (_) => setState(() => _balanceTouched = true),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
                                hintText: '0',
                                hintStyle: bigStyle?.copyWith(color: colors.ink2.withValues(alpha: 0.5)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      t.wallet.initialBalanceHelp,
                      style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.space1),
              Wrap(
                spacing: AppSpacing.space1,
                runSpacing: AppSpacing.space1,
                children: [
                  for (final amount in ActiveCurrency.value.quickAmounts(QuickAmountMultipliers.walletBalance))
                    AppQuickChip(
                      label: formatQuickAmount(amount),
                      onTap: () => _setBalance((parseMoneyInput(_balanceController.text) ?? 0) + amount),
                    ),
                  AppQuickChip(
                    label: t.record.clearAmountAction,
                    color: colors.tinted(colors.warning, 0.22),
                    onTap: () => _setBalance(0),
                  ),
                ],
              ),
              if (wallet != null) ...[
                const SizedBox(height: AppSpacing.space4),
                _CurrentBalanceCard(wallet: wallet),
                const SizedBox(height: AppSpacing.space4),
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
                              style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Switch(
                        value: _isActive,
                        activeThumbColor: colors.onBrand,
                        activeTrackColor: colors.brand,
                        onChanged: (value) => setState(() => _isActive = value),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.space6),
              AppButton(
                label: _editing ? t.transaction.saveChangesAction : t.wallet.saveAddAction,
                onPressed: _canSave ? _save : null,
              ),
              if (wallet != null) ...[
                const SizedBox(height: AppSpacing.space6),
                AppButton.danger(label: t.wallet.deleteAction, onPressed: _delete),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  t.wallet.deleteHelp,
                  textAlign: TextAlign.center,
                  style: textTheme.bodySmall?.copyWith(color: colors.ink2),
                ),
              ],
              const SizedBox(height: AppSpacing.space2),
              Text(
                t.wallet.privacyNote,
                textAlign: TextAlign.center,
                style: transactionLabelStyle(context, color: colors.ink2).copyWith(fontWeight: FontWeight.w400),
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
            decoration: BoxDecoration(color: colors.surface3, borderRadius: BorderRadius.circular(8)),
            child: const AppIcon(IconKey.chevronLeft, size: 28),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space2),
            child: Column(
              children: [
                Text(
                  (editing ? t.wallet.editStepLabel : t.wallet.addStepLabel).toUpperCase(),
                  textAlign: TextAlign.center,
                  style: transactionLabelStyle(context, color: colors.brand),
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
          decoration: BoxDecoration(color: colors.surface2, borderRadius: BorderRadius.circular(8)),
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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space1, vertical: AppSpacing.space2),
        decoration: BoxDecoration(
          color: selected ? colors.tinted(colors.brand, 0.16) : colors.surface2,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? colors.brand : Colors.transparent, width: 2),
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
                color: selected ? colors.brand : colors.ink2,
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
            style: transactionLabelStyle(context, color: colors.ink2),
          ),
          const SizedBox(height: 2),
          FitStart(
            child: Text(
              AppMoneyFormatter.format(wallet.currentBalance),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.ink,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.space1),
          Text(
            t.wallet.editBalanceNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.ink2),
          ),
        ],
      ),
    );
  }
}
