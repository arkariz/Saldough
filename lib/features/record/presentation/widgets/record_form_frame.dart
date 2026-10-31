import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/utils/formatters/money_expression.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_controller.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_host.dart';
import 'package:saldough/features/record/presentation/widgets/record_save_button.dart';

/// Kerangka lembar Catat (prototipe `Catat.dc.html`, ADR-034): bar atas
/// (tutup, judul di tengah, mikrofon), pengalih jenis, isi formulir yang
/// bisa digulir, lalu di bawah papan angka dan tombol simpan yang menyebut
/// jenisnya.
///
/// [amountController] menyalakan [AppKeypad] di bawah, lengkap dengan kolom
/// operator kalkulator (T-8.18); papan angka disembunyikan selama keyboard
/// sistem terbuka (mis. mengetik catatan).
/// Tombol simpan nonaktif selama [onSubmit] `null` (nominal atau dompet
/// belum terisi).
class RecordFormFrame extends StatelessWidget {
  /// Membuat [RecordFormFrame].
  const RecordFormFrame({
    required this.kind,
    required this.title,
    required this.isEditing,
    required this.onBack,
    required this.submitLabel,
    required this.onSubmit,
    required this.children,
    this.kindSwitcher,
    this.amountController,
    this.onAmountChanged,
    super.key,
  });

  /// Jenis transaksi.
  final TransactionKind kind;

  /// Judul bar atas ("Catat", atau judul sunting).
  final String title;

  /// `true` saat menyunting: tanpa mikrofon.
  final bool isEditing;

  /// Dipanggil saat tombol tutup diketuk.
  final VoidCallback onBack;

  /// Teks tombol simpan, menyebut jenisnya.
  final String submitLabel;

  /// Dipanggil saat tombol simpan ditekan; `null` menonaktifkannya.
  final VoidCallback? onSubmit;

  /// Pengalih jenis CATAT di bawah bar atas (opsional).
  final Widget? kindSwitcher;

  /// Pengendali nominal yang diisi lewat papan angka.
  final RecordAmountController? amountController;

  /// Dipanggil sesudah papan angka mengubah nominal.
  final VoidCallback? onAmountChanged;

  /// Isi formulir, dari atas ke bawah.
  final List<Widget> children;

  void _onKey(String key) {
    if (amountController!.applyKey(key)) onAmountChanged?.call();
  }

  void _onClear() {
    amountController!.clear();
    onAmountChanged?.call();
  }

  /// Susunan papan angka: 3 kolom angka dan kolom operator kalkulator
  /// (T-8.18), dengan `000` (atau pemisah desimal) dan hapus di baris bawah.
  static List<List<DsKeypadKey>> get _keypadRows {
    final decimal = ActiveCurrency.value.fractionDigits > 0;
    final operators = moneyOperatorSymbols.keys.toList();
    DsKeypadKey op(int i) => DsKeypadKey(
      value: operators[i],
      label: moneyOperatorSymbols[operators[i]],
      muted: true,
      semanticLabel: switch (operators[i]) {
        moneyKeyAdd => t.common.keypadAdd,
        moneyKeySubtract => t.common.keypadSubtract,
        moneyKeyMultiply => t.common.keypadMultiply,
        _ => t.common.keypadDivide,
      },
    );
    return [
      [const DsKeypadKey(value: '1'), const DsKeypadKey(value: '2'), const DsKeypadKey(value: '3'), op(0)],
      [const DsKeypadKey(value: '4'), const DsKeypadKey(value: '5'), const DsKeypadKey(value: '6'), op(1)],
      [const DsKeypadKey(value: '7'), const DsKeypadKey(value: '8'), const DsKeypadKey(value: '9'), op(2)],
      [
        if (decimal)
          DsKeypadKey(value: moneyKeyDecimal, label: MoneySeparators.decimal, muted: true)
        else
          const DsKeypadKey(value: '000', muted: true),
        const DsKeypadKey(value: '0'),
        DsKeypadKey(
          value: moneyKeyBackspace,
          icon: Icons.backspace_outlined,
          semanticLabel: t.common.keypadBackspace,
          muted: true,
        ),
        op(3),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = context.ds.colors;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(title: title, isEditing: isEditing, onBack: onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(DsSpacing.md, DsSpacing.xs, DsSpacing.md, DsSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?kindSwitcher,
                    for (final (i, child) in children.indexed) ...[
                      if (i > 0 || kindSwitcher != null) const SizedBox(height: 8),
                      child,
                    ],
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: c.surfaceCard,
                border: Border(top: BorderSide(color: c.outlineSubtle)),
                boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 16, offset: Offset(0, -4))],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(DsSpacing.md, DsSpacing.xs, DsSpacing.md, DsSpacing.sm),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (amountController != null && !keyboardOpen) ...[
                        DsKeypad(
                          rows: _keypadRows,
                          onKey: _onKey,
                          onClear: _onClear,
                          clearValue: moneyKeyBackspace,
                        ),
                        const SizedBox(height: DsSpacing.xs),
                      ],
                      RecordSaveButton(key: const ValueKey('record-submit'), label: submitLabel, onPressed: onSubmit),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.isEditing, required this.onBack});

  final String title;
  final bool isEditing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final onVoice = isEditing ? null : RecordVoiceAction.maybeOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(DsSpacing.xs, DsSpacing.xs, DsSpacing.xs, 0),
      child: Row(
        children: [
          DsIconButton(icon: Icons.close, label: t.common.close, onPressed: onBack),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: context.ds.typography.headlineSm,
              ),
            ),
          ),
          if (onVoice != null)
            DsIconButton(
              key: const ValueKey('record-voice'),
              icon: Icons.mic_none,
              label: t.record.voice.micLabel,
              onPressed: onVoice,
            )
          else
            const SizedBox(width: DsSpacing.minTapTarget),
        ],
      ),
    );
  }
}

/// Keterangan satu kalimat di Jadikan Rutin / ubah rutin: menyimpan jadwal
/// tidak mengubah saldo, karena tidak ada transaksi baru yang dicatat.
class RecordNoBalanceChange extends StatelessWidget {
  /// Membuat [RecordNoBalanceChange].
  const RecordNoBalanceChange({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      t.record.repeat.noBalanceChange,
      textAlign: TextAlign.center,
      style: context.ds.typography.bodyMd.copyWith(color: context.ds.colors.textSecondary),
    );
  }
}
