import 'package:saldough/features/worklog/data/models/work_log_entry_model.dart';
import 'package:saldough/features/worklog/domain/entities/billing_book.dart';

/// Model serialisasi [BillingBook].
final class BillingBookModel {
  /// Membuat [BillingBookModel].
  const BillingBookModel({
    required this.id,
    required this.sourceId,
    required this.startDate,
    required this.entries,
    this.endDate,
    this.netPayAmount,
    this.injectedCycleId,
    this.injectedIncomeLineId,
  });

  /// Membaca [BillingBookModel] dari JSON.
  factory BillingBookModel.fromJson(Map<String, dynamic> json) => BillingBookModel(
        id: json['id'] as String,
        sourceId: json['sourceId'] as String,
        startDate: DateTime.parse(json['startDate'] as String),
        endDate: json['endDate'] == null ? null : DateTime.parse(json['endDate'] as String),
        entries: (json['entries'] as List<dynamic>)
            .map((e) => WorkLogEntryModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        netPayAmount: json['netPayAmount'] as int?,
        injectedCycleId: json['injectedCycleId'] as String?,
        injectedIncomeLineId: json['injectedIncomeLineId'] as String?,
      );

  /// Membuat model dari entitas domain.
  factory BillingBookModel.fromEntity(BillingBook book) => BillingBookModel(
        id: book.id,
        sourceId: book.sourceId,
        startDate: book.startDate,
        endDate: book.endDate,
        entries: book.entries.map(WorkLogEntryModel.fromEntity).toList(),
        netPayAmount: book.netPayAmount,
        injectedCycleId: book.injectedCycleId,
        injectedIncomeLineId: book.injectedIncomeLineId,
      );

  /// Versi skema dokumen ini. Naikkan kalau bentuk field berubah.
  static const schemaVersion = 1;

  /// Identitas buku.
  final String id;

  /// Rujukan ke `IncomeSource`.
  final String sourceId;

  /// Tanggal entri pertama.
  final DateTime startDate;

  /// Tanggal entri terakhir. Null selama buku masih terbuka.
  final DateTime? endDate;

  /// Entri dalam periode ini.
  final List<WorkLogEntryModel> entries;

  /// Gaji bersih hasil `CalculateNetPay` saat buku ditutup.
  final int? netPayAmount;

  /// Siklus tujuan penyuntikan.
  final String? injectedCycleId;

  /// Baris pemasukan tujuan.
  final String? injectedIncomeLineId;

  /// Menulis [BillingBookModel] ke JSON.
  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceId': sourceId,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate?.toIso8601String(),
        'entries': entries.map((e) => e.toJson()).toList(),
        'netPayAmount': netPayAmount,
        'injectedCycleId': injectedCycleId,
        'injectedIncomeLineId': injectedIncomeLineId,
      };

  /// Mengubah model jadi entitas domain.
  BillingBook toEntity() => BillingBook(
        id: id,
        sourceId: sourceId,
        startDate: startDate,
        endDate: endDate,
        entries: entries.map((e) => e.toEntity()).toList(),
        netPayAmount: netPayAmount,
        injectedCycleId: injectedCycleId,
        injectedIncomeLineId: injectedIncomeLineId,
      );
}
