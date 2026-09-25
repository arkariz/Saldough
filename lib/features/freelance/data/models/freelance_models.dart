import 'package:saldough/features/freelance/domain/entities/deduction_kind.dart';
import 'package:saldough/features/freelance/domain/entities/deduction_rule.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_payment.dart';
import 'package:saldough/features/freelance/domain/entities/freelance_project.dart';
import 'package:saldough/features/freelance/domain/entities/payment_status.dart';
import 'package:saldough/features/freelance/domain/entities/worklog_entry.dart';

/// Versi skema ketiga dokumen freelance. Naikkan kalau bentuk field berubah.
const freelanceSchemaVersion = 1;

/// Serialisasi [DeductionRule], disimpan di dalam proyek dan pembayaran.
abstract final class DeductionRuleJson {
  DeductionRuleJson._();

  /// Menulis [rule] ke JSON.
  static Map<String, dynamic> toJson(DeductionRule rule) => {
    'id': rule.id,
    'label': rule.label,
    'kind': rule.kind.name,
    'value': rule.value,
  };

  /// Membaca [DeductionRule] dari JSON.
  static DeductionRule fromJson(Map<String, dynamic> json) => DeductionRule(
    id: json['id'] as String,
    label: json['label'] as String,
    kind: DeductionKind.values.byName(json['kind'] as String),
    value: json['value'] as int,
  );

  /// Membaca daftar potongan; kunci yang tidak ada dibaca sebagai kosong.
  static List<DeductionRule> listFromJson(Object? json) =>
      ((json as List<dynamic>?) ?? const []).map((e) => fromJson(e as Map<String, dynamic>)).toList();
}

/// Serialisasi [FreelanceProject] (tanpa `freezed`, mengikuti konvensi
/// monorepo).
abstract final class FreelanceProjectJson {
  FreelanceProjectJson._();

  /// Menulis [project] ke JSON.
  static Map<String, dynamic> toJson(FreelanceProject project) => {
    'id': project.id,
    'name': project.name,
    'hourlyRate': project.hourlyRate,
    'deductionRules': project.deductionRules.map(DeductionRuleJson.toJson).toList(),
  };

  /// Membaca [FreelanceProject] dari JSON.
  static FreelanceProject fromJson(Map<String, dynamic> json) => FreelanceProject(
    id: json['id'] as String,
    name: json['name'] as String,
    hourlyRate: json['hourlyRate'] as int,
    deductionRules: DeductionRuleJson.listFromJson(json['deductionRules']),
  );
}

/// Serialisasi [WorklogEntry]. Nominal yang diperoleh tidak disimpan —
/// turunan dari jam × tarif.
abstract final class WorklogEntryJson {
  WorklogEntryJson._();

  /// Menulis [entry] ke JSON.
  static Map<String, dynamic> toJson(WorklogEntry entry) => {
    'id': entry.id,
    'projectId': entry.projectId,
    'date': entry.date.toIso8601String(),
    'hours': entry.hours,
    'hourlyRate': entry.hourlyRate,
    'note': entry.note,
    'paymentId': entry.paymentId,
  };

  /// Membaca [WorklogEntry] dari JSON.
  static WorklogEntry fromJson(Map<String, dynamic> json) => WorklogEntry(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    date: DateTime.parse(json['date'] as String),
    hours: json['hours'] as int,
    hourlyRate: json['hourlyRate'] as int,
    note: json['note'] as String?,
    paymentId: json['paymentId'] as String?,
  );
}

/// Serialisasi [FreelancePayment]. Gaji kotor, potongan, dan gaji bersih
/// tidak disimpan — turunan dari entri dan potongannya.
abstract final class FreelancePaymentJson {
  FreelancePaymentJson._();

  /// Menulis [payment] ke JSON.
  static Map<String, dynamic> toJson(FreelancePayment payment) => {
    'id': payment.id,
    'projectId': payment.projectId,
    'entryIds': payment.entryIds,
    'expectedDate': payment.expectedDate.toIso8601String(),
    'deductionRules': payment.deductionRules.map(DeductionRuleJson.toJson).toList(),
    'status': payment.status.name,
    'walletId': payment.walletId,
    'incomeTransactionId': payment.incomeTransactionId,
    'receivedDate': payment.receivedDate?.toIso8601String(),
  };

  /// Membaca [FreelancePayment] dari JSON.
  static FreelancePayment fromJson(Map<String, dynamic> json) => FreelancePayment(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    entryIds: (json['entryIds'] as List<dynamic>).cast<String>(),
    expectedDate: DateTime.parse(json['expectedDate'] as String),
    deductionRules: DeductionRuleJson.listFromJson(json['deductionRules']),
    status: PaymentStatus.values.byName(json['status'] as String),
    walletId: json['walletId'] as String?,
    incomeTransactionId: json['incomeTransactionId'] as String?,
    receivedDate: switch (json['receivedDate']) {
      final String date => DateTime.parse(date),
      _ => null,
    },
  );
}
