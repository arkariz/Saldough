import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/features/cycle/domain/entities/cycle_template.dart';

/// Kontrak akses data [CycleTemplate] — dokumen tunggal, bukan per bulan.
abstract interface class CycleTemplateRepository {
  /// Membaca template. `Right` selalu terisi — [CycleTemplate.empty] kalau
  /// belum pernah disunting.
  Future<Either<Failure, CycleTemplate>> getTemplate();

  /// Menyimpan [template] apa adanya.
  Future<Either<Failure, Unit>> saveTemplate(CycleTemplate template);
}
