import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/rupiah_input.dart';

/// Kolom teks polos di dalam slab — nama anggaran dan nama pos.
class BudgetTextField extends StatelessWidget {
  /// Membuat [BudgetTextField].
  const BudgetTextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.autofocus = false,
    this.maxLength = 40,
    super.key,
  });

  /// Pengendali teks.
  final TextEditingController controller;

  /// Teks petunjuk.
  final String hint;

  /// Dipanggil tiap teks berubah.
  final ValueChanged<String> onChanged;

  /// Fokus otomatis saat dibuka.
  final bool autofocus;

  /// Panjang maksimum.
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      radius: 4,
      shadow: 2,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: colors.accent,
        onChanged: onChanged,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: colors.textMuted),
        ),
      ),
    );
  }
}

/// Kolom nominal rupiah utuh (berpemisah ribuan). Nilai dibaca pemanggil
/// lewat [senOf] — satuan sen, sesuai aturan uang proyek.
class BudgetMoneyField extends StatelessWidget {
  /// Membuat [BudgetMoneyField].
  const BudgetMoneyField({required this.controller, required this.onChanged, this.large = false, super.key});

  /// Pengendali teks.
  final TextEditingController controller;

  /// Dipanggil tiap teks berubah.
  final ValueChanged<String> onChanged;

  /// Huruf besar untuk nominal utama.
  final bool large;

  /// Nominal dalam sen dari isi [controller], atau `null` kalau kosong/nol.
  static int? senOf(TextEditingController controller) {
    final rupiah = parseRupiahInput(controller.text);
    return rupiah == null ? null : rupiah * 100;
  }

  /// Teks awal untuk [sen]: kosong kalau nol atau bukan rupiah utuh.
  static String initialText(int? sen) => sen == null || sen <= 0 || sen % 100 != 0 ? '' : formatRupiahInput(sen ~/ 100);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    final style = large
        ? textTheme.headlineMedium?.copyWith(fontSize: 26, fontWeight: FontWeight.w700)
        : textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700);
    return TransactionSlab(
      radius: 4,
      shadow: 2,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: Row(
        children: [
          Text('Rp', style: PixelTypography.tabularMono(context, fontSize: 16, color: colors.accent)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [RupiahInputFormatter()],
              cursorColor: colors.accent,
              style: style,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                hintText: '0',
                hintStyle: style?.copyWith(color: colors.textMuted.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kolom bilangan bulat positif (jumlah barang).
class BudgetQuantityField extends StatelessWidget {
  /// Membuat [BudgetQuantityField].
  const BudgetQuantityField({required this.controller, required this.onChanged, super.key});

  /// Pengendali teks.
  final TextEditingController controller;

  /// Dipanggil tiap teks berubah.
  final ValueChanged<String> onChanged;

  /// Jumlah dari isi [controller], atau `null` kalau kosong/nol.
  static int? valueOf(TextEditingController controller) {
    final value = int.tryParse(controller.text);
    return value == null || value <= 0 ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      radius: 4,
      shadow: 2,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
        cursorColor: colors.accent,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          hintText: '1',
          hintStyle: TextStyle(color: colors.textMuted.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}

/// Dua (atau lebih) pilihan bergaya tab — periode dan mode nominal pos.
class BudgetSegmented<T> extends StatelessWidget {
  /// Membuat [BudgetSegmented].
  const BudgetSegmented({required this.options, required this.selected, required this.onChanged, super.key});

  /// Pilihan beserta labelnya, sesuai urutan.
  final List<(T, String)> options;

  /// Pilihan aktif.
  final T selected;

  /// Dipanggil dengan pilihan baru.
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      color: colors.surfaceMid,
      padding: const EdgeInsets.all(AppSpacing.xs),
      shadow: 2,
      child: Row(
        children: [
          for (final (value, label) in options) ...[
            if (value != options.first.$1) const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Semantics(
                button: true,
                selected: value == selected,
                child: GestureDetector(
                  onTap: () => onChanged(value),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: value == selected ? colors.accent : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label.toUpperCase(),
                      textAlign: TextAlign.center,
                      style: transactionLabelStyle(
                        context,
                        size: 12,
                        color: value == selected ? colors.onAccent : colors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bilah atas formulir: tombol kembali, judul bertingkat dua.
class BudgetFormHeader extends StatelessWidget {
  /// Membuat [BudgetFormHeader].
  const BudgetFormHeader({required this.stepLabel, required this.title, super.key});

  /// Label kecil di atas judul.
  final String stepLabel;

  /// Judul.
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Semantics(
          button: true,
          label: t.common.cancel,
          child: GestureDetector(
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
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Column(
              children: [
                Text(
                  stepLabel.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: transactionLabelStyle(context, color: colors.accent),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 22, height: 1.2),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}
