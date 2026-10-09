import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_host.dart';

/// Kerangka lembar Catat (prototipe `Catat.dc.html`, ADR-034): bar atas
/// (tutup, judul di tengah, mikrofon), pengalih jenis, isi formulir yang
/// bisa digulir, lalu di bawah papan angka dan tombol simpan yang menyebut
/// jenisnya.
///
/// [amountController] menyalakan [AppKeypad] di bawah; papan angka
/// disembunyikan selama keyboard sistem terbuka (mis. mengetik catatan).
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
  final TextEditingController? amountController;

  /// Dipanggil sesudah papan angka mengubah nominal.
  final VoidCallback? onAmountChanged;

  /// Isi formulir, dari atas ke bawah.
  final List<Widget> children;

  void _onKey(String key) {
    final controller = amountController!;
    final next = applyMoneyKey(controller.text, key);
    if (next == controller.text) return;
    controller.text = next;
    onAmountChanged?.call();
  }

  void _onClear() {
    amountController!.clear();
    onAmountChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(title: title, isEditing: isEditing, onBack: onBack),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.space4,
                  AppSpacing.space1,
                  AppSpacing.space4,
                  AppSpacing.space4,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ?kindSwitcher,
                    for (final (i, child) in children.indexed) ...[
                      if (i > 0 || kindSwitcher != null) const SizedBox(height: AppSpacing.space2),
                      child,
                    ],
                  ],
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.line)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  // Papan angka membawa jarak 4px di atas dan bawahnya (area
                  // sentuh), jadi bingkai ini lebih tipis dari prototipe
                  // (QA PR #43 F1: isian form terlihat tanpa menggulir).
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space4,
                    AppSpacing.space1,
                    AppSpacing.space4,
                    AppSpacing.space2,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (amountController != null && !keyboardOpen) ...[
                        AppKeypad(onKey: _onKey, onClear: _onClear),
                        const SizedBox(height: AppSpacing.space1),
                      ],
                      AppButton(
                        key: const ValueKey('record-submit'),
                        label: submitLabel,
                        expand: true,
                        onPressed: onSubmit,
                      ),
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
  const _Header({
    required this.title,
    required this.isEditing,
    required this.onBack,
  });

  final String title;
  final bool isEditing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final onVoice = isEditing ? null : RecordVoiceAction.maybeOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space1,
        AppSpacing.space1,
        AppSpacing.space1,
        0,
      ),
      child: Row(
        children: [
          AppIconButton(
            icon: IconKey.close,
            label: t.common.close,
            onPressed: onBack,
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          if (onVoice != null)
            AppIconButton(
              key: const ValueKey('record-voice'),
              icon: IconKey.microphone,
              label: t.record.voice.micLabel,
              tonal: true,
              onPressed: onVoice,
            )
          else
            const SizedBox(width: AppSize.touch),
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
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: context.appColors.ink2),
    );
  }
}
