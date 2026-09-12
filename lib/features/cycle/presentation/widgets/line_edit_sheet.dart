import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/cycle/domain/repositories/card_catalog.dart';
import 'package:saldough/shared/income/income.dart';

/// Hasil [LineEditSheet].
class LineEditResult {
  /// Membuat [LineEditResult].
  const LineEditResult({
    required this.label,
    required this.amount,
    this.sourceId,
    this.rollUpSource,
  });

  /// Nama baris.
  final String label;

  /// Nominal dalam sen. Diabaikan kalau [rollUpSource] diisi.
  final int amount;

  /// Rujukan ke `IncomeSource` yang dipilih, atau `null` kalau tidak ditaut
  /// (T-3.4/FR-INC-002). Selalu `null` untuk baris anggaran.
  final String? sourceId;

  /// Sumber roll-up yang dipilih (Rencana Belanja/kartu kredit), atau `null`
  /// untuk baris manual biasa. Selalu `null` untuk baris pemasukan.
  final RollUpSource? rollUpSource;
}

/// Pilihan sumber nominal baris anggaran — lihat [LineEditSheet.isBudgetLine].
enum _BudgetSourceChoice { manual, grocery, card }

/// Bottom sheet tambah/sunting satu baris pemasukan atau anggaran.
///
/// Nominal diketik pemilik dalam rupiah bulat (tanpa sen) lewat keyboard
/// numerik, lalu dikonversi × 100 — pengguna tidak pernah mengetik satuan
/// sen secara langsung.
class LineEditSheet extends StatefulWidget {
  /// Membuat [LineEditSheet].
  const LineEditSheet({
    required this.title,
    required this.cycleId,
    this.initialLabel,
    this.initialAmount,
    this.sources = const [],
    this.initialSourceId,
    this.isIncomeLine = false,
    this.isBudgetLine = false,
    this.cards = const [],
    this.usedRollUpSources = const [],
    this.onIncomeSourceAdded,
    super.key,
  });

  /// Judul sheet, misalnya "Tambah baris pemasukan".
  final String title;

  /// Siklus yang sedang disunting — jadi `planId` kalau baris anggaran baru
  /// ditautkan ke Rencana Belanja (tautan 1:1 `GroceryPlan`↔`MonthlyCycle`,
  /// laporan pemilik). Tidak relevan untuk baris pemasukan, tapi tetap wajib
  /// diisi supaya pemanggil tidak lupa -- `cycle_page.dart` selalu punya
  /// `state.cycle.id` di tangan untuk kedua jenis baris.
  final String cycleId;

  /// Nama awal, kalau menyunting baris yang sudah ada.
  final String? initialLabel;

  /// Nominal awal dalam sen, kalau menyunting baris yang sudah ada.
  final int? initialAmount;

  /// Sumber pemasukan yang bisa ditautkan. Kosong untuk baris anggaran —
  /// pemilihan sumber hanya tampil kalau daftar ini tidak kosong.
  final List<IncomeSource> sources;

  /// Sumber yang sudah ditaut, kalau menyunting baris yang sudah ada.
  final String? initialSourceId;

  /// True untuk baris pemasukan, false untuk baris anggaran. Menentukan
  /// apakah hint+tombol "tambah sumber pemasukan" ditampilkan saat
  /// [sources] kosong (T-3.4 — sebelumnya kosong tanpa penjelasan kalau
  /// belum ada `IncomeSource` terdaftar, laporan pemilik).
  final bool isIncomeLine;

  /// True untuk baris anggaran BARU — menentukan apakah pemilihan sumber
  /// nominal (Manual/Rencana Belanja/Kartu Kredit) ditampilkan (laporan
  /// pemilik: sebelumnya tidak ada cara menautkan baris anggaran ke Rencana
  /// Belanja/kartu dari UI, hanya lewat seed). Baris anggaran yang sudah
  /// ada (sunting) selalu baris `manual` — baris `rollUp` tidak bisa dibuka
  /// lewat sheet ini sama sekali (ADR-0008, digerbang di `cycle_page.dart`).
  final bool isBudgetLine;

  /// Seluruh kartu kredit terdaftar, dipakai pemilihan kartu saat
  /// [_BudgetSourceChoice.card] dipilih. Kosong untuk baris pemasukan.
  final List<CardSummary> cards;

  /// Sumber roll-up yang SUDAH ditautkan ke baris anggaran lain di siklus
  /// ini — dipakai menonaktifkan (bukan menyembunyikan) pilihan Rencana
  /// Belanja/kartu yang sudah terpakai, supaya tidak bisa menautkan dua
  /// baris anggaran ke sumber yang sama (laporan pemilik: sebelumnya bisa
  /// berkali-kali). Kartu yang berbeda tetap boleh masing-masing punya
  /// baris sendiri — hanya sumber yang SAMA yang dibatasi.
  final List<RollUpSource> usedRollUpSources;

  /// Dipanggil setelah pemilik balik dari layar "Tambah sumber pemasukan"
  /// (lewat tombol `addIncomeSourceButton` di bawah) — widget pemanggil
  /// memakainya
  /// untuk menyegarkan daftar sumber pemasukan tanpa pemilik harus
  /// berpindah tab dulu (laporan pemilik: sumber baru sebelumnya tidak
  /// terdeteksi sampai pindah-balik tab). `null` kalau tidak relevan
  /// (misalnya untuk baris anggaran).
  final VoidCallback? onIncomeSourceAdded;

  /// Menampilkan [LineEditSheet] sebagai modal bottom sheet, mengembalikan
  /// [LineEditResult] atau `null` kalau dibatalkan.
  static Future<LineEditResult?> show(
    BuildContext context, {
    required String title,
    required String cycleId,
    String? initialLabel,
    int? initialAmount,
    List<IncomeSource> sources = const [],
    String? initialSourceId,
    bool isIncomeLine = false,
    bool isBudgetLine = false,
    List<CardSummary> cards = const [],
    List<RollUpSource> usedRollUpSources = const [],
    VoidCallback? onIncomeSourceAdded,
  }) {
    return showModalBottomSheet<LineEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LineEditSheet(
        title: title,
        cycleId: cycleId,
        initialLabel: initialLabel,
        initialAmount: initialAmount,
        sources: sources,
        initialSourceId: initialSourceId,
        isIncomeLine: isIncomeLine,
        isBudgetLine: isBudgetLine,
        cards: cards,
        usedRollUpSources: usedRollUpSources,
        onIncomeSourceAdded: onIncomeSourceAdded,
      ),
    );
  }

  @override
  State<LineEditSheet> createState() => _LineEditSheetState();
}

class _LineEditSheetState extends State<LineEditSheet> {
  late final _labelController = TextEditingController(
    text: widget.initialLabel ?? '',
  );
  late final _amountController = TextEditingController(
    text: widget.initialAmount == null
        ? ''
        : (widget.initialAmount! ~/ 100).toString(),
  );
  late String? _sourceId = widget.initialSourceId;

  /// Nilai terakhir yang DIISI OTOMATIS ke [_labelController] (bukan yang
  /// diketik pemilik sendiri) -- dipakai [_fillLabel] untuk memutuskan
  /// apakah aman menimpa isi field saat pemilik pindah pilihan sumber
  /// (UX-37): field hanya diisi ulang kalau masih kosong atau masih persis
  /// berisi isian otomatis SEBELUMNYA, tidak pernah menimpa nama yang
  /// sudah diketik tangan.
  String? _autoFilledLabel;

  void _fillLabel(String value) {
    if (_labelController.text.isEmpty || _labelController.text == _autoFilledLabel) {
      _labelController.text = value;
    }
    _autoFilledLabel = value;
  }

  /// Sumber nominal baris anggaran — hanya relevan saat [LineEditSheet.
  /// isBudgetLine] true. Baris anggaran yang sudah ada selalu `manual`
  /// (lihat catatan di [LineEditSheet.isBudgetLine]).
  _BudgetSourceChoice _budgetSource = .manual;
  String? _selectedCardId;

  bool get _isNewBudgetLine =>
      widget.isBudgetLine && widget.initialLabel == null;

  bool get _isGroceryUsed =>
      widget.usedRollUpSources.contains(RollUpSource.grocery(widget.cycleId));

  bool _isCardUsed(String cardId) =>
      widget.usedRollUpSources.contains(RollUpSource.card(cardId));

  /// True kalau belum ada kartu terdaftar sama sekali — beda dari
  /// [_allCardsUsed] (ada kartu, tapi semuanya sudah ditautkan). Dipisah
  /// karena `[].every(...)` bernilai `true` untuk daftar kosong: sebelum
  /// perbaikan ini, kedua keadaan tercampur jadi satu gerbang yang sama dan
  /// pemilik yang belum punya kartu melihat "Pilih kartu" tanpa satu pun
  /// chip untuk dipilih (laporan pemilik, UX-02).
  bool get _hasNoCards => widget.cards.isEmpty;

  /// True kalau ada kartu terdaftar tapi semuanya sudah dipakai baris
  /// anggaran roll-up lain.
  bool get _allCardsUsed =>
      widget.cards.isNotEmpty && widget.cards.every((c) => _isCardUsed(c.id));

  /// Gerbang tombol Simpan — dinonaktifkan (bukan diam-diam menolak submit)
  /// saat input belum lengkap, mengikuti pola `_AllocationPlanForm` di
  /// `investment_page.dart` (UX-03).
  bool get _canSubmit {
    if (_isNewBudgetLine && _budgetSource != .manual) {
      if (_labelController.text.trim().isEmpty) return false;
      return _budgetSource == .grocery
          ? !_isGroceryUsed
          : _selectedCardId != null && !_isCardUsed(_selectedCardId!);
    }
    final label = _labelController.text.trim();
    final amountText = _amountController.text.trim();
    if (label.isEmpty || amountText.isEmpty) return false;
    return int.tryParse(amountText) != null;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _selectSource(IncomeSource source) {
    setState(() {
      _sourceId = source.id;
      _fillLabel(source.name);
      if (source.kind == .fixedSalary && source.fixedAmount != null) {
        _amountController.text = (source.fixedAmount! ~/ 100).toString();
      }
    });
  }

  void _selectBudgetSource(_BudgetSourceChoice choice) {
    setState(() {
      _budgetSource = choice;
      if (choice == .grocery) {
        _fillLabel(t.cycle.budgetSourceGrocery);
      } else if (choice == .manual) {
        _selectedCardId = null;
      }
    });
  }

  void _selectCard(CardSummary card) {
    setState(() {
      _selectedCardId = card.id;
      _fillLabel(card.name);
    });
  }

  /// Chip pilihan sumber anggaran yang bisa dinonaktifkan — dipakai untuk
  /// Rencana Belanja/kartu yang sudah ditautkan ke baris lain (lihat
  /// [LineEditSheet.usedRollUpSources]): tetap TAMPIL (bukan disembunyikan,
  /// supaya pemilik tahu kenapa tidak bisa dipilih lagi) tapi diredupkan dan
  /// tidak merespons ketukan.
  Widget _budgetSourceChip({
    required String label,
    required bool selected,
    required bool disabled,
    required VoidCallback onTap,
    String? disabledMessage,
  }) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppChip(
            label: label,
            selected: selected && !disabled,
            // UX-33: chip nonaktif TETAP bisa diketuk -- ketukannya
            // menjelaskan alasannya (disabledMessage), bukan diam saja.
            // Sebelumnya onTap dinolkan total, jadi copy penjelas yang
            // sudah ditulis (mis. rollUpSourceAlreadyUsed) tidak pernah
            // terbaca pemilik.
            onTap: disabled
                ? (disabledMessage == null ? null : () => _showDisabledExplanation(disabledMessage))
                : onTap,
          ),
          if (disabled)
            Positioned(
              right: -3,
              top: -3,
              child: Icon(Icons.lock, size: 13, color: context.appColors.textMuted),
            ),
        ],
      ),
    );
  }

  void _showDisabledExplanation(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _submit() {
    if (_isNewBudgetLine && _budgetSource != .manual) {
      final label = _labelController.text.trim();
      if (label.isEmpty) return;
      final rollUpSource = _budgetSource == .grocery
          ? RollUpSource.grocery(widget.cycleId)
          : _selectedCardId == null
          ? null
          : RollUpSource.card(_selectedCardId!);
      if (rollUpSource == null) return;
      Navigator.of(context).pop(
        LineEditResult(label: label, amount: 0, rollUpSource: rollUpSource),
      );
      return;
    }
    final label = _labelController.text.trim();
    final amountText = _amountController.text.trim();
    if (label.isEmpty || amountText.isEmpty) return;
    final rupiah = int.tryParse(amountText);
    if (rupiah == null) return;
    Navigator.of(context).pop(
      LineEditResult(label: label, amount: rupiah * 100, sourceId: _sourceId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        bottom: AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .stretch,
        children: [
          Text(widget.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.md),
          if (widget.sources.isNotEmpty) ...[
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                for (final source in widget.sources)
                  AppChip(
                    label: source.name,
                    selected: source.id == _sourceId,
                    onTap: () => _selectSource(source),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ] else if (widget.isIncomeLine) ...[
            Text(
              t.cycle.noIncomeSourcesHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            AppButton(
              label: t.cycle.addIncomeSourceButton,
              icon: Icons.arrow_forward,
              onPressed: () async {
                final onIncomeSourceAdded = widget.onIncomeSourceAdded;
                Navigator.of(context).pop();
                await context.push('/income/list');
                onIncomeSourceAdded?.call();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (_isNewBudgetLine) ...[
            Text(
              t.cycle.budgetSourceFieldLabel,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                AppChip(
                  label: t.cycle.budgetSourceManual,
                  selected: _budgetSource == .manual,
                  onTap: () => _selectBudgetSource(.manual),
                ),
                _budgetSourceChip(
                  label: t.cycle.budgetSourceGrocery,
                  selected: _budgetSource == .grocery,
                  disabled: _isGroceryUsed,
                  disabledMessage: _isGroceryUsed ? t.cycle.rollUpSourceAlreadyUsed : null,
                  onTap: () => _selectBudgetSource(.grocery),
                ),
                _budgetSourceChip(
                  label: t.cycle.budgetSourceCard,
                  selected: _budgetSource == .card,
                  disabled: _hasNoCards || _allCardsUsed,
                  disabledMessage: _hasNoCards
                      ? t.cycle.noCardsHint
                      : _allCardsUsed
                      ? t.cycle.allCardsUsedHint
                      : null,
                  onTap: () => _selectBudgetSource(.card),
                ),
              ],
            ),
            if (_hasNoCards)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  t.cycle.noCardsHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            else if (_allCardsUsed)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  t.cycle.allCardsUsedHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            // Chip "Kartu Kredit" dinonaktifkan lewat _hasNoCards/
            // _allCardsUsed di atas, jadi baris ini hanya bisa tercapai saat
            // memang ada kartu yang masih bisa dipilih -- selectCardHint
            // ("Pilih kartu") berlaku tanpa syarat di sini.
            if (_budgetSource == .card) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  t.cycle.selectCardHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    for (final card in widget.cards)
                      _budgetSourceChip(
                        label: card.name,
                        selected: card.id == _selectedCardId,
                        disabled: _isCardUsed(card.id),
                        disabledMessage: _isCardUsed(card.id) ? t.cycle.rollUpSourceAlreadyUsed : null,
                        onTap: () => _selectCard(card),
                      ),
                  ],
                ),
              ),
            ],
          ],
          if (!_isNewBudgetLine || _budgetSource == .manual) ...[
            TextField(
              controller: _labelController,
              autofocus: true,
              decoration: InputDecoration(labelText: t.cycle.labelFieldHint),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _amountController,
              keyboardType: .number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: t.cycle.amountFieldHint),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _submit(),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(t.common.cancel),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(label: t.common.save, onPressed: _canSubmit ? _submit : null),
              ),
            ],
          ),
        ],
      )),
    );
  }
}
