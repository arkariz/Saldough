import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/budget/domain/entities/budget_item.dart';

/// Definisi anggaran yang bisa dipakai ulang — nama beserta pos bawaannya —
/// bukan anggaran aktif. Lihat DOMAIN_MODEL.md bagian "Template anggaran".
///
/// ⚠ Template tidak terikat dompet maupun periode; keduanya dipilih saat
/// anggaran dibuat darinya. Anggaran yang lahir dari template berdiri
/// sendiri: menyunting salah satunya tidak pernah mengubah yang lain, dan
/// membuat atau menyunting template tidak pernah mengubah saldo dompet mana
/// pun (aturan 5 CLAUDE.md).
final class BudgetTemplate extends Equatable {
  /// Membuat [BudgetTemplate].
  const BudgetTemplate({
    required this.id,
    required this.name,
    this.items = const [],
    this.isEnabled = true,
  });

  /// Identitas template.
  final String id;

  /// Nama template, misalnya `Belanja bulanan`. Data pengguna.
  final String name;

  /// Pos bawaan beserta nominal rencananya.
  final List<BudgetItem> items;

  /// Template nonaktif tidak ditawarkan saat membuat anggaran.
  final bool isEnabled;

  /// Nominal rencana dalam sen: `Σ item.plannedAmount`. Turunan, tidak
  /// pernah disimpan — sama dengan `Budget.plannedAmount` (ADR-017).
  int get plannedAmount => items.fold(0, (sum, item) => sum + item.plannedAmount);

  /// Salinan [BudgetTemplate] dengan field yang disebutkan diganti.
  BudgetTemplate copyWith({
    String? name,
    List<BudgetItem>? items,
    bool? isEnabled,
  }) {
    return BudgetTemplate(
      id: id,
      name: name ?? this.name,
      items: items ?? this.items,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  List<Object?> get props => [id, name, items, isEnabled];
}
