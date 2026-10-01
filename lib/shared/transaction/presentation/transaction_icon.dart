import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:saldough/core/presentation/widgets/widgets.dart';
import 'package:saldough/core/theme/theme.dart';
import 'package:saldough/shared/category/category.dart';
import 'package:saldough/shared/category/category_presentation.dart';
import 'package:saldough/shared/transaction/source_icons.dart';
import 'package:saldough/shared/transaction/transaction.dart';

/// Ikon transaksi (ADR-032 §3.10): kotak berwarna jenis -- satu-satunya
/// penanda warna per baris (ADR-020 §3.3) -- berisi ikon kategori bila ada
/// (ikon jenis untuk transfer dan transaksi tanpa kategori), plus lencana
/// ikon notifikasi asal di sudut kanan bawah bila transaksinya dari
/// notifikasi.
///
/// Lencana keluar sedikit dari kotak ([badgeOverhang]) tanpa menambah lebar
/// tata letak, dan dibingkai cincin [ringColor] (warna latar di bawahnya)
/// supaya logo berwarna apa pun tetap terpisah dari kotak.
class TransactionIcon extends StatelessWidget {
  /// Membuat [TransactionIcon] dari bagian-bagiannya; dipakai juga untuk
  /// draf yang belum jadi transaksi (kotak masuk).
  const TransactionIcon({
    required this.kind,
    this.categoryId,
    this.sourceIconId,
    this.size = 44,
    this.ringColor,
    super.key,
  });

  /// [TransactionIcon] untuk [transaction].
  TransactionIcon.of(Transaction transaction, {double size = 44, Color? ringColor, Key? key})
    : this(
        kind: switch (transaction) {
          IncomeTransaction() => TransactionKind.income,
          ExpenseTransaction() => TransactionKind.expense,
          TransferTransaction() => TransactionKind.transfer,
        },
        categoryId: transaction.categoryId,
        sourceIconId: transaction.sourceIconId,
        size: size,
        ringColor: ringColor,
        key: key,
      );

  /// Jenis transaksi: warna kotak dan ikon cadangan.
  final TransactionKind kind;

  /// Kategori (ikon utama), atau `null`.
  final String? categoryId;

  /// Ikon notifikasi asal (lencana), atau `null`.
  final String? sourceIconId;

  /// Sisi kotak utama.
  final double size;

  /// Warna cincin lencana: warna permukaan tempat ikon ini berada. Bawaan
  /// latar kartu.
  final Color? ringColor;

  /// Seberapa jauh lencana keluar dari tepi kotak.
  static const badgeOverhang = 4.0;

  @override
  Widget build(BuildContext context) {
    final tile = _Tile(kind: kind, categoryId: categoryId, size: size);
    final id = sourceIconId;
    if (id == null) return tile;
    return ValueListenableBuilder<Map<String, Uint8List>>(
      valueListenable: SourceIcons.notifier,
      builder: (context, _, _) {
        final png = SourceIcons.of(id);
        if (png == null) return tile;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            tile,
            Positioned(
              right: -badgeOverhang,
              bottom: -badgeOverhang,
              child: _SourceBadge(png: png, size: size / 2, ringColor: ringColor ?? context.appColors.cardBackground),
            ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.kind, required this.categoryId, required this.size});

  final TransactionKind kind;
  final String? categoryId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tint = colors.kindFill(kind);
    final ink = colors.kindInk(kind);
    final category = kind == TransactionKind.transfer ? null : ActiveCategories.byId(categoryId);
    final icon =
        category.let(categoryIcon) ??
        switch (kind) {
          TransactionKind.income => IconKey.income,
          TransactionKind.expense => IconKey.expense,
          TransactionKind.transfer => IconKey.transfer,
        };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.iconTile(tint),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [BoxShadow(color: Color.lerp(ink, colors.edge, 0.4)!, offset: const Offset(0, 2))],
      ),
      child: AppIcon(icon, size: size * 0.68),
    );
  }
}

/// Logo notifikasi asal: sudut membulat, cincin warna latar 2 px, garis tepi
/// tipis. Diabaikan pembaca layar -- judul dan dompet baris sudah
/// menjelaskan transaksinya.
class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.png, required this.size, required this.ringColor});

  final Uint8List png;
  final double size;
  final Color ringColor;

  static const _ring = 2.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ExcludeSemantics(
      child: Container(
        width: size + _ring * 2,
        height: size + _ring * 2,
        padding: const EdgeInsets.all(_ring),
        decoration: BoxDecoration(color: ringColor, borderRadius: BorderRadius.circular(size * 0.3 + _ring)),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.3),
            border: Border.all(color: colors.edge.withValues(alpha: 0.18)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.3),
            child: ColoredBox(
              color: colors.cardBackground,
              child: Image.memory(png, fit: BoxFit.cover, gaplessPlayback: true),
            ),
          ),
        ),
      ),
    );
  }
}

extension on Category? {
  T? let<T>(T Function(Category) f) {
    final self = this;
    return self == null ? null : f(self);
  }
}
