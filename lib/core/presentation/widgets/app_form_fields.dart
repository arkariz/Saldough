import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';

// Bidang formulir bersama lembar Anggaran dan Freelance (ADR-030 §3.5);
// semula `budget_form_fields.dart` di fitur `budget`.

/// Bingkai kolom isian v2: `surfaceCard`, tinggi minimal 52, garis `outline`
/// 1px (cukup kontras untuk isian), berganti `actionPrimary` 2px saat fokus,
/// sudut membulat.
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
    final c = context.ds.colors;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (focused) => setState(() => _focused = focused),
      child: AnimatedContainer(
        duration: DsMotion.reduced(context) ? Duration.zero : DsMotion.standard,
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: c.surfaceCard,
          borderRadius: DsRadius.mdAll,
          border: Border.all(color: _focused ? c.actionPrimary : c.outline, width: _focused ? 2 : 1),
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
    final ds = context.ds;
    return AppFieldBox(
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        maxLength: maxLength,
        textCapitalization: TextCapitalization.sentences,
        cursorColor: ds.colors.actionPrimary,
        style: ds.typography.bodyMd.copyWith(color: ds.colors.textPrimary),
        onChanged: onChanged,
        buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: false,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          hintText: hint,
          hintStyle: ds.typography.bodyMd.copyWith(color: ds.colors.textMuted),
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
  static String initialText(int? sen) =>
      sen == null || sen <= 0 || !isMoneyInputExact(sen) ? '' : formatMoneyInput(sen);

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final style = (large ? ds.typography.amount.copyWith(fontSize: 24, height: 32 / 24) : ds.typography.amount)
        .copyWith(
          color: c.textPrimary,
        );
    return AppFieldBox(
      child: Row(
        children: [
          Text(ActiveCurrency.value.symbol, style: ds.typography.amountSm.copyWith(color: c.textSecondary)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: moneyKeyboardType,
              inputFormatters: [MoneyInputFormatter()],
              cursorColor: c.actionPrimary,
              style: style,
              onChanged: onChanged,
              decoration: InputDecoration(
                border: InputBorder.none,
                filled: false,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                hintText: '0',
                hintStyle: style.copyWith(color: c.textMuted),
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
    final ds = context.ds;
    return AppFieldBox(
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
        cursorColor: ds.colors.actionPrimary,
        style: ds.typography.amount.copyWith(color: ds.colors.textPrimary),
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          filled: false,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          hintText: '1',
          hintStyle: ds.typography.amount.copyWith(color: ds.colors.textMuted),
        ),
      ),
    );
  }
}

/// Bar atas sheet formulir: tombol tutup di kiri, judul di tengah.
class AppFormHeader extends StatelessWidget {
  /// Membuat [AppFormHeader].
  const AppFormHeader({required this.title, super.key});

  /// Judul.
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DsIconButton(icon: Icons.close, label: t.common.close, onPressed: () => Navigator.of(context).pop()),
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: context.ds.typography.headlineMd.copyWith(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 44),
      ],
    );
  }
}
