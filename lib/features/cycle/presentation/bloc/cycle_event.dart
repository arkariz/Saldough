part of 'cycle_bloc.dart';

/// Event [CycleBloc].
sealed class CycleEvent {
  /// Membuat [CycleEvent].
  const CycleEvent();
}

/// Membuka siklus ber-`id` [cycleId]. Kalau belum pernah dibuat, tampil
/// kosong (belum disimpan sampai baris pertama ditambah).
final class CycleOpened extends CycleEvent {
  /// Membuat [CycleOpened].
  const CycleOpened(this.cycleId);

  /// Identitas siklus, format `YYYY-MM`.
  final String cycleId;
}

/// Menambah (kalau [id] `null`) atau menyunting baris pemasukan.
final class IncomeLineSaved extends CycleEvent {
  /// Membuat [IncomeLineSaved].
  const IncomeLineSaved({required this.label, required this.amount, this.id, this.sourceId});

  /// `null` berarti baris baru.
  final String? id;

  /// Nama yang tampil.
  final String label;

  /// Nominal dalam sen.
  final int amount;

  /// Rujukan ke `IncomeSource`, kalau ada.
  final String? sourceId;
}

/// Menghapus baris pemasukan ber-`id` [id].
final class IncomeLineRemoved extends CycleEvent {
  /// Membuat [IncomeLineRemoved].
  const IncomeLineRemoved(this.id);

  /// Identitas baris.
  final String id;
}

/// Menambah (kalau [id] `null`) atau menyunting baris anggaran manual.
///
/// ⚠ Hanya untuk baris [BudgetLineKind.manual] — baris `rollUp` tidak bisa
/// disunting lewat event ini (ADR-0008).
final class BudgetLineSaved extends CycleEvent {
  /// Membuat [BudgetLineSaved].
  const BudgetLineSaved({required this.label, required this.amount, this.id});

  /// `null` berarti baris baru.
  final String? id;

  /// Nama yang tampil.
  final String label;

  /// Nominal dalam sen.
  final int amount;
}

/// Menghapus baris anggaran ber-`id` [id].
final class BudgetLineRemoved extends CycleEvent {
  /// Membuat [BudgetLineRemoved].
  const BudgetLineRemoved(this.id);

  /// Identitas baris.
  final String id;
}

/// Menandai baris pemasukan ber-`id` [lineId] sebagai tetap atau insidental.
///
/// Baris tetap otomatis terdaftar ke `CycleTemplate` (dan dilepas saat
/// ditandai kembali jadi insidental) — lihat catatan di `CycleTemplate`.
final class IncomeLineTemplateToggled extends CycleEvent {
  /// Membuat [IncomeLineTemplateToggled].
  const IncomeLineTemplateToggled(this.lineId);

  /// Identitas baris.
  final String lineId;
}

/// Menandai baris anggaran ber-`id` [lineId] sebagai tetap atau insidental.
final class BudgetLineTemplateToggled extends CycleEvent {
  /// Membuat [BudgetLineTemplateToggled].
  const BudgetLineTemplateToggled(this.lineId);

  /// Identitas baris.
  final String lineId;
}

/// Mengonfirmasi baris pemasukan ber-`id` [lineId] — menghapus penanda
/// perlu ditinjau (FR-TPL-002).
final class IncomeLineReviewed extends CycleEvent {
  /// Membuat [IncomeLineReviewed].
  const IncomeLineReviewed(this.lineId);

  /// Identitas baris.
  final String lineId;
}

/// Mengonfirmasi baris anggaran ber-`id` [lineId].
final class BudgetLineReviewed extends CycleEvent {
  /// Membuat [BudgetLineReviewed].
  const BudgetLineReviewed(this.lineId);

  /// Identitas baris.
  final String lineId;
}

/// Membuat siklus bulan berikutnya dari template, lalu berpindah ke sana.
final class CycleRollOverRequested extends CycleEvent {
  /// Membuat [CycleRollOverRequested].
  const CycleRollOverRequested();
}

/// Menutup siklus yang sedang dibuka.
final class CycleClosed extends CycleEvent {
  /// Membuat [CycleClosed].
  const CycleClosed();
}

/// Membuka kembali siklus yang sudah ditutup, secara sadar (ADR-0008).
final class CycleReopened extends CycleEvent {
  /// Membuat [CycleReopened].
  const CycleReopened();
}
