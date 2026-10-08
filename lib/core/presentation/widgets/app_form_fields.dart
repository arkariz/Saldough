import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/app_button.dart';
import 'package:saldough/core/presentation/widgets/app_icon.dart';
import 'package:saldough/core/presentation/widgets/pixel_corner_border.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';

// Bidang formulir bersama lembar Anggaran dan Freelance (ADR-030 §3.5);
// semula `budget_form_fields.dart` di fitur `budget`.

/// Bingkai kolom isian design system (komponen TextField): `surface`, tinggi
/// minimal `size-field` (52), garis `lineStrong` 1px, berganti `brand` 2px
/// saat fokus, sudut piksel kecil.
class AppFieldBox extends StatefulWidget {
  /// Membuat [AppFieldBox] di sekitar [child] (biasanya `TextField` tanpa
  /// bingkai).
  const AppFieldBox({required this.child, super.key});

  /// Isi kolom.
  final Widget child;

  @override
  State<AppFieldBox> createState() => _AppFieldBoxState();
}

class _AppFieldBoxState extends State<AppFieldBox> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        constraints: const BoxConstraints(minHeight: AppSize.field),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space3),
        alignment: Alignment.centerLeft,
        decoration: ShapeDecoration(
          color: colors.surface,
          shape: PixelCornerBorder.small(
            side: BorderSide(color: _focused ? colors.brand : colors.lineStrong, width: _focused ? 2 : 1),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

/// Kolom teks polos — nama anggaran dan nama pos.
class AppFormTextField extends StatelessWidget {
  /// Membuat [AppFormTextField].
  const AppFormTextField({
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
    return AppFieldBox(
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: colors.brand,
        onChanged: onChanged,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: false,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: hint,
          hintStyle: TextStyle(color: colors.ink3),
        ),
      ),
    );
  }
}

/// Kolom nominal mata uang aktif (berpemisah ribuan, ADR-025). Nilai dibaca pemanggil
/// lewat [senOf] — satuan sen, sesuai aturan uang proyek.
class AppFormMoneyField extends StatelessWidget {
  /// Membuat [AppFormMoneyField].
  const AppFormMoneyField({required this.controller, required this.onChanged, this.large = false, super.key});

  /// Pengendali teks.
  final TextEditingController controller;

  /// Dipanggil tiap teks berubah.
  final ValueChanged<String> onChanged;

  /// Huruf besar untuk nominal utama.
  final bool large;

  /// Nominal dalam sen dari isi [controller], atau `null` kalau kosong/nol.
  static int? senOf(TextEditingController controller) => parseMoneyInput(controller.text);

  /// Teks awal untuk [sen]: kosong kalau nol atau tidak bisa ditulis utuh
  /// di kolom (lihat `isMoneyInputExact`).
  static String initialText(int? sen) => sen == null || sen <= 0 || !isMoneyInputExact(sen) ? '' : formatMoneyInput(sen);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final style = large ? context.numberStyles.amountLg : context.numberStyles.amount;
    return AppFieldBox(
      child: Row(
        children: [
          Text(ActiveCurrency.value.symbol, style: context.numberStyles.amountSm.copyWith(color: colors.ink2)),
          const SizedBox(width: AppSpacing.space2),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: moneyKeyboardType,
              inputFormatters: [MoneyInputFormatter()],
              cursorColor: colors.brand,
              style: style,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                filled: false,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
                hintText: '0',
                hintStyle: style.copyWith(color: colors.ink3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Kolom bilangan bulat positif (jumlah barang).
class AppFormQuantityField extends StatelessWidget {
  /// Membuat [AppFormQuantityField].
  const AppFormQuantityField({required this.controller, required this.onChanged, super.key});

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
    return AppFieldBox(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
        cursorColor: colors.brand,
        style: context.numberStyles.amount,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: false,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.space1),
          hintText: '1',
          hintStyle: TextStyle(color: colors.ink3),
        ),
      ),
    );
  }
}

/// Bar atas sheet formulir (design system Sheet): tombol tutup di kiri,
/// judul `title` di tengah.
class AppFormHeader extends StatelessWidget {
  /// Membuat [AppFormHeader].
  const AppFormHeader({required this.title, super.key});

  /// Judul.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppIconButton(icon: IconKey.close, label: t.common.close, onPressed: () => Navigator.of(context).pop()),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        const SizedBox(width: AppSize.touch),
      ],
    );
  }
}
