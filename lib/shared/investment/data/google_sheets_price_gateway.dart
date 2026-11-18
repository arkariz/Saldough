import 'dart:convert';
import 'dart:io';

import 'package:dependencies/dependencies.dart';
import 'package:failures/failures.dart';
import 'package:saldough/shared/investment/domain/price_sheet.dart';

/// Satu permintaan HTTP ke Google: kode status dan isi jawaban.
typedef SheetsTransport = Future<(int, String)> Function(String method, Uri uri, {required String token, String? body});

/// Token akses `drive.file` pengguna, atau `null` bila belum diizinkan.
typedef SheetsAccessToken = Future<String?> Function();

/// [PriceSheetGateway] di atas Sheets API v4, langsung dari perangkat dengan
/// token pengguna (ADR-051 §3.2). Tanpa server dan tanpa kunci API.
final class GoogleSheetsPriceGateway implements PriceSheetGateway {
  /// Membuat [GoogleSheetsPriceGateway]; [transport] diganti di uji.
  GoogleSheetsPriceGateway({required this.accessToken, SheetsTransport? transport})
    : _transport = transport ?? _httpTransport;

  /// Penyedia token.
  final SheetsAccessToken accessToken;
  final SheetsTransport _transport;

  static const _base = 'https://sheets.googleapis.com/v4/spreadsheets';

  /// Judul kolom baris pertama (ADR-051 §3.3).
  static const header = ['id', 'Nama', 'Kode', 'Harga'];

  @override
  Future<Either<Failure, String>> create(String title) async {
    final created = await _send('POST', Uri.parse(_base), {
      // en_US: pemisah argumen rumus koma, desimal titik.
      'properties': {'title': title, 'locale': 'en_US'},
    });
    return switch (created) {
      Left(value: final f) => left(f),
      Right(value: final json) => await _writeHeader(json['spreadsheetId'] as String),
    };
  }

  Future<Either<Failure, String>> _writeHeader(String id) async {
    final written = await _send('PUT', _values(id, 'A1:D1', {'valueInputOption': 'RAW'}), {
      'values': [header],
    });
    return written.map((_) => id);
  }

  @override
  Future<Either<Failure, Unit>> syncRows(String sheetId, List<PriceSheetRow> rows) async {
    final ids = await _send('GET', _values(sheetId, 'A2:A'));
    if (ids case Left(value: final f)) return left(f);
    final existing = <String, int>{};
    final column = ids.getOrElse((_) => const {})['values'] as List<dynamic>? ?? const [];
    for (final (i, row) in column.indexed) {
      final cells = row as List<dynamic>;
      if (cells.isNotEmpty && cells.first is String) existing[cells.first as String] = i + 2;
    }
    var next = column.length + 2;
    final data = <Map<String, Object?>>[];
    for (final row in rows) {
      final line = existing[row.instrumentId] ?? next++;
      // Kolom Harga hanya ditulis bila berumus; isian pengguna tidak ditimpa.
      data.add({
        'range': row.formula == null ? 'A$line:C$line' : 'A$line:D$line',
        'values': [
          [row.instrumentId, row.name, row.code, ?row.formula],
        ],
      });
    }
    if (data.isEmpty) return right(unit);
    final updated = await _send('POST', Uri.parse('$_base/$sheetId/values:batchUpdate'), {
      'valueInputOption': 'USER_ENTERED',
      'data': data,
    });
    return updated.map((_) => unit);
  }

  @override
  Future<Either<Failure, Map<String, Object?>>> readPrices(String sheetId) async {
    final read = await _send('GET', _values(sheetId, 'A2:D', {'valueRenderOption': 'UNFORMATTED_VALUE'}));
    return read.map((json) {
      final rows = json['values'] as List<dynamic>? ?? const [];
      return {
        for (final row in rows.cast<List<dynamic>>())
          if (row.isNotEmpty && row.first is String) row.first as String: row.length > 3 ? row[3] : null,
      };
    });
  }

  Uri _values(String id, String range, [Map<String, String>? query]) =>
      Uri.parse('$_base/$id/values/$range').replace(queryParameters: query);

  Future<Either<Failure, Map<String, dynamic>>> _send(String method, Uri uri, [Object? body]) async {
    final token = await accessToken();
    if (token == null) return left(_failure(PriceSheetFailures.notAuthorized, 'Izin Google Sheet belum diberikan.'));
    try {
      final (status, text) = await _transport(method, uri, token: token, body: body == null ? null : jsonEncode(body));
      if (status == 401 || status == 403) {
        return left(_failure(PriceSheetFailures.notAuthorized, 'Izin Google Sheet ditolak ($status).'));
      }
      if (status == 404) return left(_failure(PriceSheetFailures.notFound, 'Google Sheet tidak ditemukan.'));
      if (status >= 300) return left(_failure(PriceSheetFailures.unreachable, 'Sheets API $status.'));
      return right(text.isEmpty ? const {} : jsonDecode(text) as Map<String, dynamic>);
    } on SocketException catch (e) {
      return left(_failure(PriceSheetFailures.unreachable, 'Tanpa jaringan: ${e.message}'));
    } on HttpException catch (e) {
      return left(_failure(PriceSheetFailures.unreachable, e.message));
    }
  }

  static Failure _failure(FailureCode code, String message) => code == PriceSheetFailures.unreachable
      ? NetworkFailure(code: code, message: message)
      : AuthorizationFailure(code: code, message: message);

  static Future<(int, String)> _httpTransport(String method, Uri uri, {required String token, String? body}) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final request = await client.openUrl(method, uri);
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
      if (body != null) {
        request.headers.contentType = ContentType.json;
        request.write(body);
      }
      final response = await request.close().timeout(const Duration(seconds: 20));
      return (response.statusCode, await response.transform(utf8.decoder).join());
    } finally {
      client.close();
    }
  }
}
