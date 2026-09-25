import 'package:dependencies/dependencies.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';

/// Satu klien atau proyek freelance beserta tarif dan potongan bawaannya.
/// Lihat DOMAIN_MODEL.md bagian "Proyek".
///
/// [hourlyRate] dan [deductionRules] adalah nilai BAWAAN: disalin ke entri
/// worklog dan pembayaran saat keduanya dibuat, sehingga mengubahnya tidak
/// mengubah kerja atau pembayaran yang sudah tercatat (ADR-019).
final class FreelanceProject extends Equatable {
  /// Membuat [FreelanceProject].
  const FreelanceProject({
    required this.id,
    required this.name,
    required this.hourlyRate,
    this.deductionRules = const [],
  });

  /// Identitas proyek.
  final String id;

  /// Nama klien atau proyek. Data pengguna, bukan teks antarmuka.
  final String name;

  /// Tarif per jam bawaan, dalam sen.
  final int hourlyRate;

  /// Potongan bawaan untuk pembayaran proyek ini.
  final List<DeductionRule> deductionRules;

  /// Salinan [FreelanceProject] dengan field yang disebutkan diganti.
  FreelanceProject copyWith({String? name, int? hourlyRate, List<DeductionRule>? deductionRules}) {
    return FreelanceProject(
      id: id,
      name: name ?? this.name,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      deductionRules: deductionRules ?? this.deductionRules,
    );
  }

  @override
  List<Object?> get props => [id, name, hourlyRate, deductionRules];
}
