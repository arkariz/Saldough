import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';

/// Ikon jenis transaksi untuk [kind] -- dipakai kotak jenis di kop layar dan
/// kartu pilihan CATAT.
IconKey recordKindIcon(TransactionKind kind) => switch (kind) {
  TransactionKind.income => IconKey.income,
  TransactionKind.expense => IconKey.expense,
  TransactionKind.transfer => IconKey.transfer,
};

/// Kerangka layar formulir CATAT (rujukan visual `pixel_kas_catat_pemasukan`,
/// `..._pengeluaran`, `..._transfer_antar_dompet`): kop (tombol kembali,
/// "Langkah 2 // Transaksi" + judul, kotak jenis), [notice] opsional, isi
/// formulir berjarak seragam, tombol simpan berwarna jenis, dan catatan kaki
/// bahwa aplikasi hanya mencatat.
///
/// Mengisi tinggi penuh lembar (`SizedBox.expand`) supaya lembar terasa
/// sebagai satu layar; isinya bisa digulir dan naik mengikuti papan ketik.
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
    this.notice,
    super.key,
  });

  /// Jenis transaksi; menentukan warna tombol simpan dan kotak jenis.
  final TransactionKind kind;

  /// Judul layar, mis. "Catat Pengeluaran".
  final String title;

  /// `true` saat menyunting: label langkah berganti jadi "Sunting".
  final bool isEditing;

  /// Dipanggil saat tombol kembali diketuk.
  final VoidCallback onBack;

  /// Teks tombol simpan.
  final String submitLabel;

  /// Dipanggil saat tombol simpan ditekan; `null` menonaktifkannya.
  final VoidCallback? onSubmit;

  /// Kartu bantuan tepat di bawah kop (opsional).
  final Widget? notice;

  /// Bagian-bagian formulir, dari atas ke bawah.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox.expand(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(kind: kind, title: title, isEditing: isEditing, onBack: onBack),
              if (notice != null) ...[const SizedBox(height: AppSpacing.md), notice!],
              for (final child in children) ...[const SizedBox(height: AppSpacing.md), child],
              const SizedBox(height: AppSpacing.lg),
              AppButton(label: submitLabel, color: colors.kindInk(kind), onPressed: onSubmit),
              const SizedBox(height: AppSpacing.sm),
              Text(
                t.record.footnote,
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
  const _Header({required this.kind, required this.title, required this.isEditing, required this.onBack});

  final TransactionKind kind;
  final String title;
  final bool isEditing;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        GestureDetector(
          onTap: onBack,
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
                  (isEditing ? t.record.editStepLabel : t.record.stepLabel).toUpperCase(),
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
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.tinted(colors.kindFill(kind), 0.22),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Color.lerp(colors.kindInk(kind), colors.textPrimary, 0.4)!, offset: const Offset(0, 2)),
            ],
          ),
          child: AppIcon(recordKindIcon(kind), size: 28),
        ),
      ],
    );
  }
}

/// Kartu bantuan berlatar hangat: kotak ikon, judul tebal, dan isi.
///
/// Dipakai pemilih jenis CATAT ("Info Pencatatan"), formulir pengeluaran
/// ("Aturan Kas") dan transfer ("Penting").
class RecordNotice extends StatelessWidget {
  /// Membuat [RecordNotice].
  const RecordNotice({required this.title, required this.body, this.flat = false, super.key});

  /// Judul tebal.
  final String title;

  /// Isi penjelasan.
  final String body;

  /// Pita datar tanpa bayangan bawah -- untuk layar yang kartu-kartu di
  /// dekatnya sudah berbayangan, supaya kartu info tidak terbaca sebagai
  /// salah satunya.
  final bool flat;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TransactionSlab(
      color: colors.tinted(colors.pending, 0.14),
      padding: const EdgeInsets.all(AppSpacing.sm),
      shadow: flat ? 0 : 3,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.tinted(colors.pending, 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const AppIcon(IconKey.overBudget, size: 20),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700)),
                Text(body, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Judul bagian formulir: huruf besar Space Mono di kiri, [hint] kecil di
/// kanan. `Wrap` supaya [hint] turun baris, bukan meluap, pada teks besar.
class RecordSectionLabel extends StatelessWidget {
  /// Membuat [RecordSectionLabel].
  const RecordSectionLabel(this.label, {this.hint, super.key});

  /// Judul bagian.
  final String label;

  /// Keterangan kecil di ujung kanan.
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: 2,
          children: [
            Text(label.toUpperCase(), style: transactionLabelStyle(context, size: 12, color: colors.textPrimary)),
            if (hint != null)
              Text(
                hint!,
                style: transactionLabelStyle(context, color: colors.textMuted).copyWith(fontWeight: FontWeight.w400),
              ),
          ],
        ),
      ),
    );
  }
}

/// Ringkasan konsekuensi catatan (mis. "Saldo BCA akan bertambah ..."):
/// kartu bernuansa jenis dengan tanda centang. Isinya [children] (biasanya
/// satu atau dua `Text`).
class RecordSummaryCard extends StatelessWidget {
  /// Membuat [RecordSummaryCard].
  const RecordSummaryCard({required this.kind, required this.children, this.title, super.key});

  /// Jenis transaksi; menentukan nuansa warna.
  final TransactionKind kind;

  /// Judul kecil huruf besar di atas isi (opsional).
  final String? title;

  /// Isi ringkasan.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.tinted(colors.kindFill(kind), 0.16),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(IconKey.check, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title!.toUpperCase(), style: transactionLabelStyle(context, color: colors.kindInk(kind))),
                ...children,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
