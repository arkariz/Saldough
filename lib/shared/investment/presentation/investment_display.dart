import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:saldough/core/design_system/design_system.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/widgets/clay_icons.dart';
import 'package:saldough/core/utils/formatters/money_formatter.dart';
import 'package:saldough/core/utils/formatters/money_input.dart';
import 'package:saldough/shared/investment/domain/instrument.dart';
import 'package:saldough/shared/investment/domain/instrument_position.dart';
import 'package:saldough/shared/investment/domain/instrument_summary.dart';
import 'package:saldough/shared/investment/domain/investment_usecases.dart';

/// Ikon jenis instrumen (rupa B-97 §0).
IconData instrumentTypeIcon(InstrumentType type) => switch (type) {
  InstrumentType.stock => Symbols.candlestick_chart_rounded,
  InstrumentType.mutualFund => Symbols.pie_chart_rounded,
  InstrumentType.bond => Symbols.receipt_long_rounded,
  InstrumentType.gold => Symbols.toll_rounded,
  InstrumentType.other => Symbols.category_rounded,
};

/// Ilustrasi clay jenis instrumen (rupa B-97, poles 18 Nov 2026).
String instrumentClayAsset(InstrumentType type) => switch (type) {
  InstrumentType.stock => ClayIcons.stock,
  InstrumentType.mutualFund => ClayIcons.fund,
  InstrumentType.bond => ClayIcons.bond,
  InstrumentType.gold => ClayIcons.gold,
  InstrumentType.other => ClayIcons.chart,
};

/// Ubin ikon clay jenis instrumen.
Widget instrumentTile(InstrumentType type, {DsIconTileSize size = DsIconTileSize.md}) =>
    DsIconTile.asset(asset: instrumentClayAsset(type), size: size);

/// Nama jenis instrumen.
String instrumentTypeLabel(InstrumentType type) => switch (type) {
  InstrumentType.stock => t.assets.invest.type.stock,
  InstrumentType.mutualFund => t.assets.invest.type.mutualFund,
  InstrumentType.bond => t.assets.invest.type.bond,
  InstrumentType.gold => t.assets.invest.type.gold,
  InstrumentType.other => t.assets.invest.type.other,
};

/// Keterangan satuan per jenis untuk formulir.
String instrumentTypeHelp(InstrumentType type) => switch (type) {
  InstrumentType.stock => t.assets.invest.typeHelp.stock,
  InstrumentType.mutualFund => t.assets.invest.typeHelp.mutualFund,
  InstrumentType.bond => t.assets.invest.typeHelp.bond,
  InstrumentType.gold => t.assets.invest.typeHelp.gold,
  InstrumentType.other => t.assets.invest.typeHelp.other,
};

/// Akhiran satuan jumlah ("lot", "unit", "gram"); obligasi tidak punya
/// (jumlahnya uang).
String quantityUnit(InstrumentType type) => switch (type) {
  InstrumentType.stock => t.assets.invest.unit.lot,
  InstrumentType.gold => t.assets.invest.unit.gram,
  InstrumentType.mutualFund || InstrumentType.other || InstrumentType.bond => t.assets.invest.unit.unit,
};

/// Batas angka desimal saat mengisi jumlah: saham 2 (0,01 lot = 1 lembar),
/// lainnya 4 (ADR-049 §3.2). Obligasi 0 (uang).
int quantityDecimals(InstrumentType type) => switch (type) {
  InstrumentType.stock => 2,
  InstrumentType.bond => 0,
  InstrumentType.mutualFund || InstrumentType.gold || InstrumentType.other => 4,
};

/// Bilangan berskala [value] (÷ [scale]) dengan pemisah locale, tanpa nol
/// buntut: 123456 → "12,3456"; 50000 → "5".
String formatScaled(int value, {int scale = quantityScale}) {
  final negative = value < 0;
  final abs = value.abs();
  final whole = MoneySeparators.groupThousands(abs ~/ scale);
  final digits = scale.toString().length - 1;
  var fraction = (abs % scale).toString().padLeft(digits, '0');
  fraction = fraction.replaceFirst(RegExp(r'0+$'), '');
  return '${negative ? '−' : ''}$whole${fraction.isEmpty ? '' : '${MoneySeparators.decimal}$fraction'}';
}

/// Jumlah dengan satuan: "12 lot", "1.523,4567 unit", obligasi "Rp5.000.000"
/// (ikut Sembunyikan nominal karena uang).
String formatQuantity(InstrumentType type, int quantity) => type.usesNominal
    ? AppMoneyFormatter.format(quantity)
    : '${formatScaled(quantity)} ${quantityUnit(type)}';

/// Banyak lembar dari jumlah lot berskala (saham saja).
String formatShares(int quantity) => formatScaled(quantity * sharesPerLot);

/// Harga per satuan harga: "Rp9.875 per lembar", obligasi "100,5% dari
/// nominal" (ADR-049 §3.4).
String formatUnitPrice(InstrumentType type, int unitPrice) {
  final p = t.assets.invest.price;
  return switch (type) {
    InstrumentType.stock => '${AppMoneyFormatter.format(unitPrice)} ${p.perShare}',
    InstrumentType.gold => '${AppMoneyFormatter.format(unitPrice)} ${p.perGram}',
    InstrumentType.mutualFund || InstrumentType.other => '${AppMoneyFormatter.format(unitPrice)} ${p.perUnit}',
    InstrumentType.bond => '${formatScaled(unitPrice)}${p.bondPercent}',
  };
}

/// Persen [part] terhadap [whole] satu desimal, bertanda: "+6,8%". `null`
/// bila [whole] 0.
String? formatSignedPercent(int part, int whole) {
  if (whole == 0) return null;
  final tenths = mulDivRound(part.abs(), 1000, whole.abs());
  final sign = part > 0 ? '+' : (part < 0 ? '−' : '');
  return '$sign${formatScaled(tenths, scale: 10)}%';
}

/// Nominal bertanda: "+Rp750.000", "−Rp120.000".
String formatSignedMoney(int sen) =>
    sen > 0 ? '+${AppMoneyFormatter.format(sen)}' : (sen < 0 ? '−${AppMoneyFormatter.format(-sen)}' : AppMoneyFormatter.format(0));

/// Pil untung/rugi (rupa B-97 §0): hijau untung, merah rugi, dengan tanda dan
/// ikon tren. Tidak tampil bila [amount] 0.
class InvestmentGainPill extends StatelessWidget {
  /// Membuat [InvestmentGainPill]. [base] = penyebut persen (nilai
  /// perolehan); `null` = tanpa persen.
  const InvestmentGainPill({required this.amount, this.base, super.key});

  /// Untung (positif) atau rugi (negatif), sen.
  final int amount;

  /// Penyebut persen.
  final int? base;

  @override
  Widget build(BuildContext context) {
    if (amount == 0) return const SizedBox.shrink();
    final percent = base == null ? null : formatSignedPercent(amount, base!);
    return DsPill(
      label: percent == null ? formatSignedMoney(amount) : '${formatSignedMoney(amount)} · $percent',
      tone: amount > 0 ? DsPillTone.positive : DsPillTone.danger,
      icon: amount > 0 ? Symbols.trending_up_rounded : Symbols.trending_down_rounded,
    );
  }
}

/// Penanda kesegaran nilai (rupa B-97 §0): teks redup bila < 30 hari, pil
/// kuning bila kedaluwarsa, pil netral bila belum pernah diperbarui.
class InvestmentFreshness extends StatelessWidget {
  /// Membuat [InvestmentFreshness].
  const InvestmentFreshness({required this.summary, required this.today, this.sheetFetchedAt, super.key});

  /// Ringkasan instrumen.
  final InstrumentSummary summary;

  /// Hari ini.
  final DateTime today;

  /// Kapan harga terakhir diambil dari Google Sheet (ADR-051 §3.4), untuk
  /// "Dari Google Sheet · 19.25".
  final DateTime? sheetFetchedAt;

  @override
  Widget build(BuildContext context) {
    final s = t.assets.invest;
    final age = summary.ageInDays(today);
    if (age == null) return DsPill(label: s.neverUpdated);
    final valuation = summary.valuation!;
    final fetched = sheetFetchedAt;
    if (age <= 0 && fetched != null && valuation.source != ValuationSource.manual) {
      final time = formatClock(fetched);
      final ds = context.ds;
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DsIconTile.asset(asset: ClayIcons.priceRefresh, size: DsIconTileSize.xs),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              valuation.source == ValuationSource.sheetEstimate
                  ? s.sheet.estimate(time: time)
                  : s.sheet.fromSheet(time: time),
              style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted),
            ),
          ),
        ],
      );
    }
    final label = age <= 0 ? s.updatedToday : s.staleValue(n: age);
    if (summary.isStale(today)) {
      return DsPill(label: label, tone: DsPillTone.warning, icon: Symbols.schedule_rounded);
    }
    final ds = context.ds;
    return Text(label, style: ds.typography.bodySm.copyWith(color: ds.colors.textMuted));
  }
}

/// Mengurai isian desimal locale ("12,5") menjadi bilangan berskala
/// [scale]; `null` bila kosong, tidak sah, atau 0.
int? parseScaled(String text, {int scale = quantityScale}) {
  final cleaned = text.trim().replaceAll(RegExp('[.,]'), '.');
  if (cleaned.isEmpty) return null;
  final match = RegExp(r'^(\d*)(?:\.(\d*))?$').firstMatch(cleaned);
  if (match == null) return null;
  final digits = scale.toString().length - 1;
  final whole = int.tryParse(match.group(1)!.isEmpty ? '0' : match.group(1)!) ?? 0;
  var fraction = match.group(2) ?? '';
  if (fraction.length > digits) fraction = fraction.substring(0, digits);
  final value = whole * scale + int.parse(fraction.padRight(digits, '0'));
  return value <= 0 ? null : value;
}

/// Teks isian untuk bilangan berskala [value] (tanpa pemisah ribuan):
/// 125000 → "12,5".
String scaledInputText(int value, {int scale = quantityScale}) {
  final digits = scale.toString().length - 1;
  final fraction = (value % scale).toString().padLeft(digits, '0').replaceFirst(RegExp(r'0+$'), '');
  return '${value ~/ scale}${fraction.isEmpty ? '' : '${MoneySeparators.decimal}$fraction'}';
}

/// Jumlah dari isian formulir sesuai jenis: obligasi = uang (sen), lainnya
/// berskala (ADR-049 §3.2).
int? parseQuantityInput(InstrumentType type, String text) =>
    type.usesNominal ? parseMoneyInput(text) : parseScaled(text);

/// Isian formulir dari jumlah tersimpan.
String quantityInputText(InstrumentType type, int quantity) =>
    type.usesNominal ? formatMoneyInput(quantity) : scaledInputText(quantity);

/// Harga per satuan harga dari isian: obligasi persen ("100,5" → 1005000),
/// lainnya uang.
int? parseUnitPriceInput(InstrumentType type, String text) =>
    type.usesNominal ? parseScaled(text) : parseMoneyInput(text);

/// Lima pilihan jenis instrumen berupa ubin clay (rupa B-97 §3 butir 2),
/// dipakai formulir dan CATAT › Instrumen baru. Yang terpilih membesar
/// pelan dan berbingkai warna utama.
class InstrumentTypeChips extends StatelessWidget {
  /// Membuat [InstrumentTypeChips].
  const InstrumentTypeChips({required this.selected, required this.onSelected, this.enabled = true, super.key});

  /// Jenis terpilih.
  final InstrumentType? selected;

  /// Dipanggil saat jenis dipilih.
  final ValueChanged<InstrumentType> onSelected;

  /// `false` = terkunci (terpilih tetap terlihat).
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final reduced = DsMotion.reduced(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Lima ubin satu baris bila muat; di layar sempit tiga per baris.
        final perRow = constraints.maxWidth >= 330 ? 5 : 3;
        final width = (constraints.maxWidth - 8 * (perRow - 1)) / perRow;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final type in InstrumentType.values)
              Semantics(
                button: true,
                selected: type == selected,
                enabled: enabled,
                label: instrumentTypeLabel(type),
                excludeSemantics: true,
                child: GestureDetector(
                  key: ValueKey('instrument-type-${type.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: enabled ? () => onSelected(type) : null,
                  child: AnimatedOpacity(
                    duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
                    opacity: enabled || type == selected ? 1 : 0.45,
                    child: AnimatedContainer(
                      duration: reduced ? Duration.zero : const Duration(milliseconds: 200),
                      curve: Curves.easeOutBack,
                      width: width,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: type == selected ? c.actionPrimary.withValues(alpha: 0.10) : c.surfaceCard,
                        borderRadius: DsRadius.lgAll,
                        border: Border.all(
                          color: type == selected ? c.actionPrimary : c.outlineSubtle,
                          width: type == selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            duration: reduced ? Duration.zero : const Duration(milliseconds: 220),
                            curve: Curves.easeOutBack,
                            scale: type == selected ? 1.12 : 1,
                            child: instrumentTile(type, size: DsIconTileSize.sm),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            instrumentTypeLabel(type),
                            // "Reksa dana" boleh dua baris di ubin sempit.
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: ds.typography.labelMd.copyWith(
                              color: type == selected ? c.actionPrimary : c.textSecondary,
                              fontWeight: type == selected ? FontWeight.w700 : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Satu baris ringkasan label–nilai yang tahan nominal dan tanggal panjang
/// (poles B-97): label di kiri (boleh membungkus), keterangan kecil di
/// bawahnya, nilai rata kanan yang tidak pernah terpotong; bila ruang
/// sempit, nilai turun ke baris sendiri.
class InvestmentInfoRow extends StatelessWidget {
  /// Membuat [InvestmentInfoRow].
  const InvestmentInfoRow({
    required this.label,
    required this.value,
    this.caption,
    this.icon,
    this.valueColor,
    this.trailing,
    super.key,
  });

  /// Label.
  final String label;

  /// Nilai (nominal, jumlah, atau harga).
  final String value;

  /// Keterangan kecil di bawah label, mis. tanggal.
  final String? caption;

  /// Ikon kecil di depan label.
  final IconData? icon;

  /// Warna nilai.
  final Color? valueColor;

  /// Tindakan kecil di bawah nilai, mis. "Pakai".
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final c = ds.colors;
    final labelColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ds.typography.bodySm.copyWith(color: c.textSecondary)),
        if (caption case final text?)
          Text(text, style: ds.typography.labelMd.copyWith(color: c.textMuted)),
      ],
    );
    final valueText = Text(
      value,
      textAlign: TextAlign.end,
      style: ds.typography.bodyMd.copyWith(
        fontWeight: FontWeight.w700,
        color: valueColor ?? c.textPrimary,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon case final i?) ...[
            Padding(padding: const EdgeInsets.only(top: 1), child: Icon(i, size: 18, color: c.textMuted)),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Sempit: nilai di bawah label supaya tidak ada yang terpotong.
                final stacked = constraints.maxWidth < 220;
                final right = Column(
                  crossAxisAlignment: stacked ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [valueText, ?trailing],
                );
                if (stacked) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [labelColumn, const SizedBox(height: 2), right],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label mengisi sisa ruang; nilai selebar isinya (paling
                    // banyak sisa ruang) dan selalu rata kanan.
                    Expanded(child: labelColumn),
                    const SizedBox(width: 12),
                    ConstrainedBox(constraints: BoxConstraints(maxWidth: constraints.maxWidth * 0.6), child: right),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Pesan untuk galat investasi yang dikenal (ADR-049 §3.6), atau `null`.
String? investmentFailureMessage(Failure failure) => switch (failure.code) {
  InvestmentFailures.insufficientQuantity => t.assets.invest.editNegative,
  InvestmentFailures.hasRecords => t.assets.invest.deleteBlockedTitle,
  InvestmentFailures.typeLocked => t.assets.invest.typeLocked,
  InvestmentFailures.limitReached => t.premium.paywall.messages.instrument.title,
  _ => null,
};

/// Jam dan menit sesuai bahasa: "19.25" (id) atau "19:25" (en).
String formatClock(DateTime time) {
  final separator = LocaleSettings.currentLocale == AppLocale.en ? ':' : '.';
  return '${time.hour.toString().padLeft(2, '0')}$separator${time.minute.toString().padLeft(2, '0')}';
}
