import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/features/record/presentation/bloc/record_bloc.dart';
import 'package:saldough/features/record/presentation/widgets/record_amount_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_category_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_choice.dart';
import 'package:saldough/features/record/presentation/widgets/record_date_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_draft_card.dart';
import 'package:saldough/features/record/presentation/widgets/record_form_frame.dart';
import 'package:saldough/features/record/presentation/widgets/record_note_field.dart';
import 'package:saldough/features/record/presentation/widgets/record_repeat_field.dart';
import 'package:saldough/shared/capture/capture.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/recurring/recurring.dart';
import 'package:saldough/shared/transaction/transaction.dart';
import 'package:saldough/shared/wallet/wallet.dart';
import 'package:saldough/shared/wallet/wallet_presentation.dart';

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
    this.draft,
    this.initialWalletId,
    this.frequentCategoryIds = const [],
    this.onCreateCategory,
    this.kindSwitcher,
    this.initialRepeat,
    this.repeatLocked = false,
    this.scheduleOnly = false,
    this.occurrence,
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

  /// Ulangi awal (chip pembuka atau Jadikan Rutin, T-15.3); `null` = tidak
  /// diulang. Diabaikan saat menyunting.
  final RecurringPattern? initialRepeat;

  /// Jadikan Rutin: Ulangi wajib nyala.
  final bool repeatLocked;

  /// Ubah rutin: tombol selalu "Simpan Jadwal", karena tidak ada transaksi
  /// yang dicatat.
  final bool scheduleOnly;

  /// Kemunculan rutin yang dicatat ("Ubah dulu", T-15.6): menampilkan
  /// pemberitahuan E5/E11 dan menyembunyikan Ulangi.
  final RecordOccurrence? occurrence;

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
  final Future<Category?> Function(String name, String? iconKey)? onCreateCategory;

  /// Draf Catat Cerdas (ADR-027 §3.4): mengisi formulir seperti [prefill]
  /// (mode CATAT, transaksi baru) dan menampilkan teks yang tertangkap serta
  /// hal yang perlu diperiksa. Diabaikan kalau [initial] atau [prefill]
  /// terisi.
  final RecordDraft? draft;

  @override
  State<IncomeFormSheet> createState() => _IncomeFormSheetState();
}

class _IncomeFormSheetState extends State<IncomeFormSheet> {
  final _amountController = TextEditingController();
  String? _categoryId;
  final _noteController = TextEditingController();
  String? _walletId;
  DateTime _date = DateTime.now();
  late RecurringPattern? _repeat = widget.initial == null ? widget.initialRepeat : null;

  @override
  void initState() {
    super.initState();
    final tx = widget.initial ?? widget.prefill;
    final draft = widget.draft;
    if (tx == null && draft != null) {
      final amount = draft.amountSen;
      if (amount != null && amount > 0 && isMoneyInputExact(amount)) _amountController.text = formatMoneyInput(amount);
      // Dompet yang disebut tapi tidak dikenal: biarkan kosong supaya dipilih.
      _walletId = draft.walletId ?? (draft.issues.contains(DraftIssue.walletUnknown) ? null : widget.initialWalletId);
      _categoryId = draft.categoryId;
      _noteController.text = draft.note;
      if (draft.date != null) _date = draft.date!;
      return;
    }
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


  void _submit() {
    final amount = _amountSen;
    final walletId = _walletId;
    if (amount == null || walletId == null) return;
    Navigator.of(context).pop(
      IncomeRecorded(
        walletId: walletId,
        amount: amount,
        date: _date,
        repeat: _repeat,
        note: _noteController.text.trim(),
        categoryId: _categoryId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.initial != null;
    final amount = _amountSen;
    return RecordFormFrame(
      kindSwitcher: editing ? null : widget.kindSwitcher,
      kind: TransactionKind.income,
      title: editing ? t.transaction.editSheetTitle : t.appShell.recordAction,
      isEditing: editing,
      onBack: () => Navigator.of(context).pop(),
      amountController: _amountController,
      onAmountChanged: () => setState(() {}),
      submitLabel: editing
          ? t.transaction.saveChangesAction
          : repeatSubmitLabel(
              repeat: _repeat,
              date: _date,
              scheduleOnly: widget.scheduleOnly,
              plain: t.record.incomeAction,
            ),
      onSubmit: _canSubmit ? _submit : null,
      children: [
        if (!editing && widget.prefill == null && widget.draft != null) RecordDraftCard(draft: widget.draft!),
        // Di atas nominal: keputusan "honor freelance atau pemasukan biasa"
        // diambil sebelum mengisi apa pun.
        if (!editing)
          const SpotlightTarget(
            spotlightKey: SpotlightKey.recordFreelance,
            child: _FreelanceCallout(),
          ),
        SpotlightTarget(
          spotlightKey: SpotlightKey.recordAmount,
          child: RecordAmountField(controller: _amountController, kind: TransactionKind.income),
        ),
        RecordCategoryField(
          value: _categoryId,
          onChanged: (id) => setState(() => _categoryId = id),
          categoryKind: CategoryKind.income,
          frequentIds: widget.frequentCategoryIds,
          onCreate: widget.onCreateCategory,
          title: _noteController.text,
        ),
        AppListCard(
          dividerIndent: AppListCard.iconIndent,
          children: [
            SpotlightTarget(
              spotlightKey: SpotlightKey.recordWallet,
              child: WalletSelectField(
                label: t.record.toWalletFieldLabel,
                wallets: widget.wallets,
                selectedId: _walletId,
                onSelected: (id) => setState(() => _walletId = id),
                previewAmountSen: widget.repeatLocked ? null : amount,
              ),
            ),
            RecordDateField(
              date: _date,
              kind: TransactionKind.income,
              allowFuture: _repeat != null,
              onChanged: (date) => setState(() => _date = date),
            ),
            RecordNoteField(
              controller: _noteController,
              kind: TransactionKind.income,
              onChanged: (_) => setState(() {}),
            ),
            if (!editing && widget.occurrence == null)
              SpotlightTarget(
                spotlightKey: SpotlightKey.recordRepeat,
                child: RecordRepeatField(
                  value: _repeat,
                  date: _date,
                  kind: TransactionKind.income,
                  locked: widget.repeatLocked,
                  onChanged: (repeat) => setState(() {
                    _repeat = repeat;
                    if (repeat == null) _date = dateWithoutRepeat(_date);
                  }),
                ),
              ),
          ],
        ),
        if (widget.occurrence case final occurrence?)
          RecordOccurrenceNotice(occurrence: occurrence, amount: _amountSen, date: _date),
        if (widget.repeatLocked) const RecordNoBalanceChange(),
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
        child: AppCard(
          color: colors.surface2,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.space2 + AppSpacing.space1,
            vertical: AppSpacing.space2,
          ),
          child: Row(
            children: [
              const AppIconTile(IconKey.worklog, size: 32),
              const SizedBox(width: AppSpacing.space2),
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
                          color: colors.ink2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              AppIcon(IconKey.chevronRight, color: colors.warning),
            ],
          ),
        ),
      ),
    );
  }
}
