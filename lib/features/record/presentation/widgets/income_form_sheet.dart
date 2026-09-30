import 'package:flutter/material.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_category_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_date_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_frame.dart';
import 'package:saldough/features/record/presentation/widgets/record_note_field.dart';
import 'package:saldough/features/record/presentation/widgets/wallet_select_field.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';

/// Formulir catat pemasukan (FR-TXN-001) — satu layar, tanpa berpindah
/// halaman (NFR-UX-001). Mengembalikan [IncomeRecorded] lewat
/// `Navigator.pop` saat disimpan; tombol kembali menutup CATAT;
/// `AppShellPage` yang menafsirkan hasilnya, mengikuti pola
/// `IncomeSourceEditSheet` yang sudah ada. Tata letaknya mengikuti rujukan
/// visual `pixel_kas_catat_pemasukan`.
class IncomeFormSheet extends StatefulWidget {
  /// Membuat [IncomeFormSheet] dengan [wallets] sebagai pilihan tujuan.
  const IncomeFormSheet({
    required this.wallets,
    this.initial,
    this.prefill,
    this.initialWalletId,
    this.frequentCategoryIds = const [],
    this.onCreateCategory,
    this.kindSwitcher,
    super.key,
  });

  /// Dompet aktif yang bisa dipilih sebagai tujuan.
  final List<Wallet> wallets;

  /// Transaksi yang disunting. `null` = mode CATAT (transaksi baru). Kalau
  /// terisi, formulir terisi awal, tombol berjudul "Simpan Perubahan", dan
  /// tombol kembali hanya menutup lembar (tidak ada lembar pilihan CATAT
  /// untuk kembali). Hasil yang dikembalikan sama seperti mode CATAT.
  final IncomeTransaction? initial;

  /// Transaksi sumber untuk "Catat lagi" (UX-4) -- BEDA dari [initial]:
  /// formulir terisi awal (nominal, kategori, catatan, dompet) tapi TETAP
  /// mode CATAT (tombol "Catat Pemasukan", bukan "Simpan Perubahan"; hasil
  /// yang disimpan transaksi BARU, bukan menimpa yang lama) dan tanggalnya
  /// tetap hari ini, bukan tanggal transaksi sumber. Diabaikan kalau
  /// [initial] terisi.
  final IncomeTransaction? prefill;

  /// Pengalih jenis CATAT (Keluar/Masuk/Transfer, UX-1) di bawah kop —
  /// dipasang `RecordFormHost`; tidak tampil saat menyunting.
  final Widget? kindSwitcher;

  /// Dompet tujuan pra-terpilih (FR-REC-002, pintasan dari layar rincian
  /// dompet, atau dompet bawaan CATAT, UX-2). Diabaikan kalau [initial]
  /// atau [prefill] terisi -- keduanya selalu memakai dompet transaksi itu
  /// sendiri.
  final String? initialWalletId;

  /// Id kategori yang paling sering dipakai untuk jenis ini, dari riwayat —
  /// ditawarkan paling atas (UX-3).
  final List<String> frequentCategoryIds;

  /// Membuat kategori baru dari "Tambah kategori" (ADR-026 §3.6); `null`
  /// berarti pilihan itu tidak ditawarkan.
  final Future<Category?> Function(String name)? onCreateCategory;

  @override
  State<IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends State<IncomeFormSheet> {
  final _amountController = TextEditingController();
  String? _categoryId;
  final _noteController = TextEditingController();
  String? _walletId;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    final tx = widget.initial ?? widget.prefill;
    if (tx == null) {
      _walletId = widget.initialWalletId;
      return;
    }
    _amountController.text = formatMoneyInput(tx.amount);
    // Tanggal HANYA diambil dari `initial` (mode sunting) -- "Catat lagi"
    // (`prefill`) tetap mencatat hari ini, bukan tanggal transaksi sumber.
    if (widget.initial != null) _date = tx.date;
    _noteController.text = tx.note;
    _walletId = tx.walletId;
    _categoryId = tx.categoryId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  int? get _amountSen => parseMoneyInput(_amountController.text);

  bool get _canSubmit => _amountSen != null && _walletId != null;

  Wallet? get _wallet {
    for (final wallet in widget.wallets) {
      if (wallet.id == _walletId) return wallet;
    }
    return null;
  }

  void _submit() {
    final amount = _amountSen;
    final walletId = _walletId;
    if (amount == null || walletId == null) return;
    Navigator.of(context).pop(
      IncomeRecorded(
        walletId: walletId,
        amount: amount,
        date: _date,
        note: _noteController.text.trim(),
        categoryId: _categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    final wallet = _wallet;
    final amount = _amountSen;
    return RecordFormFrame(
      kindSwitcher: editing ? null : widget.kindSwitcher,
      kind: TransactionKind.income,
      title: editing ? t.transaction.editSheetTitle : t.record.incomeAction,
      isEditing: editing,
      onBack: () => Navigator.of(context).pop(),
      submitLabel: editing
          ? t.transaction.saveChangesAction
          : t.record.incomeAction,
      onSubmit: _canSubmit ? _submit : null,
      children: [
        // Di atas nominal: keputusan "honor freelance atau pemasukan biasa"
        // diambil sebelum mengisi apa pun (dulu di dasar formulir, mudah
        // terlewat).
        if (!editing)
          const SpotlightTarget(
            spotlightKey: SpotlightKey.recordFreelance,
            child: _FreelanceCallout(),
          ),
        SpotlightTarget(
          spotlightKey: SpotlightKey.recordAmount,
          child: RecordAmountField(
            controller: _amountController,
            label: t.record.amountLabelIncome,
            kind: TransactionKind.income,
            quickAmounts: ActiveCurrency.value.quickAmounts(QuickAmountMultipliers.incomeOrTransfer),
            autofocus: true,
            onChanged: () => setState(() {}),
          ),
        ),
        RecordCategoryField(
          value: _categoryId,
          onChanged: (id) => setState(() => _categoryId = id),
          categoryKind: CategoryKind.income,
          frequentIds: widget.frequentCategoryIds,
          onCreate: widget.onCreateCategory,
        ),
        SpotlightTarget(
          spotlightKey: SpotlightKey.recordWallet,
          child: WalletSelectField(
            label: t.record.toWalletFieldLabel,
            wallets: widget.wallets,
            selectedId: _walletId,
            onSelected: (id) => setState(() => _walletId = id),
            previewAmountSen: amount,
          ),
        ),
        RecordDateField(
          date: _date,
          kind: TransactionKind.income,
          onChanged: (date) => setState(() => _date = date),
        ),
        RecordNoteField(
          controller: _noteController,
          kind: TransactionKind.income,
        ),
        if (_canSubmit && wallet != null && amount != null)
          RecordSummaryCard(
            kind: TransactionKind.income,
            children: [
              Text(
                t.record.incomeSummary(
                  wallet: wallet.name,
                  amount: AppMoneyFormatter.format(amount),
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
      ],
    );
  }
}

/// Kartu jalan ke Ikhtisar Freelance (FR-FRL-005, rujukan
/// `pixel_kas_catat_pemasukan` "PATH B"): honor freelance yang sudah
/// dikerjakan belum tentu sudah diterima, jadi dicatat lewat worklog dan
/// pembayaran, bukan sebagai pemasukan biasa. Mengembalikan [OpenFreelance].
class _FreelanceCallout extends StatelessWidget {
  const _FreelanceCallout();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final textTheme = Theme.of(context).textTheme;
    // Ringkas, satu baris: penjelasannya ada di langkah tur `recordFreelance`.
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(const OpenFreelance()),
        behavior: HitTestBehavior.opaque,
        child: TransactionSlab(
          color: colors.tinted(colors.pending, 0.1),
          shadowColor: colors.pending,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              const AppIcon(IconKey.worklog),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${t.record.freelanceCalloutTitle} ',
                        style: textTheme.titleSmall,
                      ),
                      TextSpan(
                        text: t.record.freelanceCalloutAction,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppIcon(IconKey.chevronRight, color: colors.pending),
            ],
          ),
        ),
      ),
    );
  }
}
