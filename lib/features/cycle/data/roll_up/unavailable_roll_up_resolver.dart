import 'package:saldough/features/cycle/domain/entities/roll_up_resolution.dart';
import 'package:saldough/features/cycle/domain/entities/roll_up_source.dart';
import 'package:saldough/features/cycle/domain/repositories/roll_up_resolver.dart';

/// Placeholder [RollUpResolver] selama Fase 4 (rencana belanja dan kartu
/// kredit) belum dibangun — lihat ROADMAP.md Fase 2: "Baris roll-up sudah
/// dikenali jenisnya di fase ini, tetapi sumbernya baru ada di Fase 4.
/// Sampai itu, baris roll-up ditampilkan bernilai nol dengan penanda bahwa
/// sumbernya belum tersedia."
///
/// Ganti registrasi DI-nya dengan resolver sungguhan begitu Fase 4 selesai
/// — tidak ada kode lain yang perlu berubah, `CycleRepositoryImpl` hanya
/// bergantung pada antarmuka [RollUpResolver].
final class UnavailableRollUpResolver implements RollUpResolver {
  /// Membuat [UnavailableRollUpResolver].
  const UnavailableRollUpResolver();

  @override
  Future<RollUpResolution> resolve(RollUpSource source) async => const .unavailable();
}
