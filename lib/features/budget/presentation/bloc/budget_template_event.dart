part of 'budget_template_bloc.dart';

/// Event [BudgetTemplateBloc].
sealed class BudgetTemplateEvent {
  /// Membuat [BudgetTemplateEvent].
  const BudgetTemplateEvent();
}

/// Memuat template dan dompet (atau lewat "Coba lagi").
final class BudgetTemplatesStarted extends BudgetTemplateEvent {
  /// Membuat [BudgetTemplatesStarted].
  const BudgetTemplatesStarted();
}

/// Menambah template baru dari [name] dan [items].
final class BudgetTemplateAdded extends BudgetTemplateEvent {
  /// Membuat [BudgetTemplateAdded].
  const BudgetTemplateAdded({required this.name, required this.items});

  /// Nama template.
  final String name;

  /// Pos bawaan.
  final List<BudgetItem> items;
}

/// Menyimpan [template] yang sudah disunting (nama, pos, status aktif).
final class BudgetTemplateEdited extends BudgetTemplateEvent {
  /// Membuat [BudgetTemplateEdited].
  const BudgetTemplateEdited(this.template);

  /// Template sesudah disunting.
  final BudgetTemplate template;
}

/// Menggandakan [template] jadi template baru bernama "… (salinan)".
final class BudgetTemplateDuplicated extends BudgetTemplateEvent {
  /// Membuat [BudgetTemplateDuplicated].
  const BudgetTemplateDuplicated(this.template);

  /// Template sumber.
  final BudgetTemplate template;
}

/// Menghapus [template]. Anggaran yang pernah dibuat darinya tetap ada.
final class BudgetTemplateDeleted extends BudgetTemplateEvent {
  /// Membuat [BudgetTemplateDeleted].
  const BudgetTemplateDeleted(this.template);

  /// Template yang dihapus.
  final BudgetTemplate template;
}
