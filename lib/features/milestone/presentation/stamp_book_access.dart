import 'package:flutter/foundation.dart';
import 'package:saldough/features/milestone/domain/entities/milestone_ledger.dart';

/// Pintu layar Buku Stempel dan baris Akun ke keadaan stempel (ADR-046). Fitur
/// tidak mengenal koordinator di akar; akar komposisi yang mengimplementasinya.
abstract interface class MilestoneBookAccess {
  /// Catatan terkini.
  ValueListenable<MilestoneLedger> get ledger;

  /// Semua stempel dianggap sudah dilihat (titik "baru" hilang).
  Future<void> markAllSeen();

  /// Sakelar Perayaan stempel (G-8).
  Future<void> setCelebrationEnabled({required bool enabled});
}
