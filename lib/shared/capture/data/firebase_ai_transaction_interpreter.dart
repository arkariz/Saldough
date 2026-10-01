import 'dart:convert';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:saldough/shared/capture/domain/capture_evidence.dart';
import 'package:saldough/shared/capture/domain/interpreted_transaction.dart';
import 'package:saldough/shared/capture/domain/transaction_interpreter.dart';

/// Pemanggil model: prompt pengguna masuk, teks JSON keluar (atau `null`).
typedef ExtractionModel = Future<String?> Function(String prompt);

/// Interpreter cloud lewat Firebase AI Logic (`firebase_ai`, Gemini Developer
/// API; ADR-027 §3.5, T-11.7). Dipanggil `CaptureDraftComposer` hanya bila
/// draf aturan tidak yakin atau bahasanya tidak punya paket aturan (ADR-029
/// §3.4).
///
/// Keluarannya **kutipan**, sama seperti interpreter aturan: nominal,
/// dompet, dan kategori tetap dihitung dan dicocokkan `CaptureDraftResolver`,
/// jadi karangan model ditolak di sana. Yang dikirim hanya teks bukti, nama
/// dompet dan kategori aktif, tanggal hari ini, dan kode bahasa -- tanpa
/// saldo, riwayat, id, atau `origin` (ADR-027 §3.5 butir 4).
final class FirebaseAiTransactionInterpreter implements TransactionInterpreter {
  /// Membuat [FirebaseAiTransactionInterpreter] dengan [model] (uji); bawaan
  /// memanggil Gemini lewat Firebase.
  FirebaseAiTransactionInterpreter({ExtractionModel? model}) : _model = model ?? _gemini;

  /// Model flash-lite stabil (riset §8, dicek 30 Sep 2026). Ganti di sini
  /// bila model ini dipensiunkan.
  static const modelName = 'gemini-3.5-flash-lite';

  final ExtractionModel _model;

  @override
  Future<Either<Failure, InterpretedTransaction>> interpret(
    CaptureEvidence evidence,
    InterpretationContext context,
  ) async {
    try {
      final raw = await _model(extractionPrompt(evidence, context));
      final parsed = raw == null ? null : parseExtraction(raw, capturedAt: evidence.capturedAt);
      if (parsed == null) return left(const SystemFailure(code: FailureCode.unknown, message: 'cloud: bad JSON'));
      return right(parsed);
    } on Object catch (error) {
      // Termasuk `Error` dari SDK: penyusun draf tidak boleh tertahan.
      return left(SystemFailure(code: FailureCode.unknown, message: 'cloud: $error'));
    }
  }
}

GenerativeModel? _cachedModel;

/// Model dibuat saat pertama dipakai, bukan saat DI: Firebase belum tentu
/// terinisialisasi (perangkat offline sejak dibuka), dan kegagalannya harus
/// menjadi `Left`, bukan galat saat membangun layar.
Future<String?> _gemini(String prompt) async {
  if (Firebase.apps.isEmpty) throw Exception('Firebase belum terinisialisasi');
  final model = _cachedModel ??= FirebaseAI.googleAI().generativeModel(
    model: FirebaseAiTransactionInterpreter.modelName,
    systemInstruction: Content.system(extractionInstruction),
    generationConfig: GenerationConfig(
      temperature: 0,
      maxOutputTokens: 512,
      responseMimeType: 'application/json',
      responseSchema: extractionSchema,
    ),
  );
  final response = await model.generateContent([Content.text(prompt)]);
  return response.text;
}

/// Instruksi sistem. Berbahasa Inggris karena ucapan bisa dalam bahasa apa
/// pun; isi catatan tetap mengikuti bahasa ucapan.
@visibleForTesting
const extractionInstruction = '''
You extract ONE personal-finance transaction from a short user utterance. The app only records transactions; it never moves money.
Copy text from the utterance; never invent values.
- kind: "expense", "income", or "transfer" (moving money between the user's own wallets).
- amount_text: the exact substring of the utterance that states the money amount, character for character (e.g. "35 ribu", "Rp35.000", "twenty dollars"). null if none.
- wallet_text: the wallet paid from or received into (for a transfer: the source). Use the exact name from WALLETS when it matches, otherwise copy the words from the utterance. null if not mentioned.
- to_wallet_text: transfer destination, same rules. null unless kind is "transfer".
- category: exactly one name from the category list for that kind, or null. Always null for a transfer.
- note: a short description of what it was for, in the utterance's language, without the amount, wallet, or date. Empty string if nothing is left.
- date_text: the exact substring saying when it happened (e.g. "kemarin", "27 september"), or null.
- date: date_text resolved against TODAY as YYYY-MM-DD, never after TODAY. null if date_text is null.''';

/// Skema keluaran = kontrak `InterpretedTransaction` (ADR-027 §3.2,
/// ADR-029 §3.2).
@visibleForTesting
final extractionSchema = Schema.object(
  properties: {
    'kind': Schema.enumString(enumValues: ['expense', 'income', 'transfer']),
    'amount_text': Schema.string(nullable: true),
    'wallet_text': Schema.string(nullable: true),
    'to_wallet_text': Schema.string(nullable: true),
    'category': Schema.string(nullable: true),
    'note': Schema.string(),
    'date_text': Schema.string(nullable: true),
    'date': Schema.string(nullable: true, description: 'YYYY-MM-DD'),
  },
  propertyOrdering: ['kind', 'amount_text', 'wallet_text', 'to_wallet_text', 'category', 'note', 'date_text', 'date'],
);

/// Prompt pengguna untuk [evidence]: hanya nama, tanpa saldo, riwayat, atau
/// id (ADR-027 §3.5 butir 4).
@visibleForTesting
String extractionPrompt(CaptureEvidence evidence, InterpretationContext context) {
  String list(List<String> names) => names.isEmpty ? '(none)' : names.join(', ');
  final today = context.today;
  final date =
      '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-'
      '${today.day.toString().padLeft(2, '0')}';
  return 'TODAY: $date\n'
      'LANGUAGE: ${evidence.languageCode}\n'
      'WALLETS: ${list(context.walletNames)}\n'
      'EXPENSE CATEGORIES: ${list(context.expenseCategoryNames)}\n'
      'INCOME CATEGORIES: ${list(context.incomeCategoryNames)}\n'
      'UTTERANCE: ${jsonEncode(evidence.text)}';
}

/// Membaca JSON keluaran model, atau `null` bila rusak. Tanggal mengambil jam
/// dari [capturedAt], sama seperti interpreter aturan.
@visibleForTesting
InterpretedTransaction? parseExtraction(String raw, {required DateTime capturedAt}) {
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return null;
  }
  if (decoded is! Map<String, dynamic>) return null;
  final map = decoded;
  String? text(String key) {
    final value = map[key];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  final kind = switch (text('kind')) {
    'expense' => DraftKind.expense,
    'income' => DraftKind.income,
    'transfer' => DraftKind.transfer,
    _ => null,
  };
  DateTime? date;
  if (RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(text('date') ?? '') case final m?) {
    final (year, month, day) = (int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    final value = DateTime(year, month, day, capturedAt.hour, capturedAt.minute, capturedAt.second);
    // `DateTime` menormalkan 31 Feb menjadi 3 Mar -- tanggal yang tidak ada
    // dibuang, bukan digeser.
    if (value.year == year && value.month == month && value.day == day) date = value;
  }
  return InterpretedTransaction(
    kind: kind,
    amountText: text('amount_text'),
    walletText: text('wallet_text'),
    toWalletText: kind == DraftKind.transfer ? text('to_wallet_text') : null,
    categoryName: kind == DraftKind.transfer ? null : text('category'),
    note: text('note') ?? '',
    dateText: text('date_text'),
    date: date,
  );
}
