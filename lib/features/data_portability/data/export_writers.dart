import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:saldough/features/data_portability/domain/export_data.dart';
import 'package:saldough/features/data_portability/domain/export_labels.dart';
import 'package:saldough/features/data_portability/domain/export_rows.dart';

/// Penulis berkas ekspor (ADR-040 §3.6). Murni dan tanpa `double`: nominal
/// ditulis dari sen lewat [formatSen].
abstract final class ExportWriters {
  static String _kindText(ExportKind kind, ExportLabels labels) => switch (kind) {
    ExportKind.income => labels.income,
    ExportKind.expense => labels.expense,
    ExportKind.transfer => labels.transfer,
  };

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ---------------------------------------------------------------- CSV

  /// CSV transaksi: UTF-8 dengan BOM, koma, kutip RFC 4180, titik desimal,
  /// akhir baris CRLF (E-3).
  ///
  /// Kolom teks yang diawali `=`, `+`, `-`, `@`, tab, atau CR diberi awalan `'`
  /// supaya Excel tidak menjalankannya sebagai rumus (injeksi CSV); kolom
  /// angka tidak disentuh.
  static Uint8List csv(ExportData data, List<ExportRow> rows, ExportLabels labels) {
    final digits = data.currency.fractionDigits;
    final out = StringBuffer()..write(_csvLine(labels.transactionColumns));
    for (final r in rows) {
      out.write(
        _csvLine([
          _day(r.date),
          _day(r.periodStart),
          _kindText(r.kind, labels),
          formatSen(r.amount, fractionDigits: digits),
          formatSen(r.flow, fractionDigits: digits),
          r.currencyCode,
          _safe(r.wallet),
          _safe(r.toWallet),
          _safe(r.category),
          _safe(r.note),
          _safe(r.budget),
          _safe(r.rule),
          _safe(r.project),
          _safe(r.id),
        ]),
      );
    }
    return Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(out.toString())]);
  }

  static String _safe(String text) => text.isNotEmpty && '=+-@\t\r'.contains(text[0]) ? "'$text" : text;

  static String _csvLine(List<String> fields) => '${fields.map(_csvField).join(',')}\r\n';

  static String _csvField(String value) {
    if (!value.contains(RegExp('[",\r\n]'))) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  // --------------------------------------------------------------- XLSX

  /// xlsx dua lembar (Transaksi dan Dompet). Tanggal berupa sel tanggal
  /// berformat `yyyy-mm-dd` supaya penyaring dan pivot bekerja; nominal berupa
  /// angka; teks berupa `inlineStr` (tidak pernah dibaca sebagai rumus).
  static Uint8List xlsx(ExportData data, List<ExportRow> rows, ExportLabels labels) {
    final digits = data.currency.fractionDigits;
    final transactions = <List<_Cell>>[
      [for (final h in labels.transactionColumns) _Cell.header(h)],
      for (final r in rows)
        [
          _Cell.date(r.date),
          _Cell.date(r.periodStart),
          _Cell.text(_kindText(r.kind, labels)),
          _Cell.number(formatSen(r.amount, fractionDigits: digits)),
          _Cell.number(formatSen(r.flow, fractionDigits: digits)),
          _Cell.text(r.currencyCode),
          _Cell.text(r.wallet),
          _Cell.text(r.toWallet),
          _Cell.text(r.category),
          _Cell.text(r.note),
          _Cell.text(r.budget),
          _Cell.text(r.rule),
          _Cell.text(r.project),
          _Cell.text(r.id),
        ],
    ];
    final wallets = <List<_Cell>>[
      [for (final h in labels.walletColumns) _Cell.header(h)],
      for (final w in data.wallets)
        [
          _Cell.text(w.name),
          _Cell.number(formatSen(w.initialBalance, fractionDigits: digits)),
          _Cell.number(formatSen(w.currentBalance, fractionDigits: digits)),
        ],
    ];
    return _package([
      _Sheet(labels.transactionsSheet, transactions, const [12, 12, 13, 15, 15, 9, 18, 18, 18, 32, 24, 18, 20, 28]),
      _Sheet(labels.walletsSheet, wallets, const [24, 16, 16]),
    ]);
  }

  static Uint8List _package(List<_Sheet> sheets) {
    final archive = Archive()
      ..addFile(ArchiveFile.string('[Content_Types].xml', _contentTypes(sheets.length)))
      ..addFile(ArchiveFile.string('_rels/.rels', _rootRels))
      ..addFile(ArchiveFile.string('xl/workbook.xml', _workbook(sheets)))
      ..addFile(ArchiveFile.string('xl/_rels/workbook.xml.rels', _workbookRels(sheets.length)))
      ..addFile(ArchiveFile.string('xl/styles.xml', _styles));
    for (final (i, sheet) in sheets.indexed) {
      archive.addFile(ArchiveFile.string('xl/worksheets/sheet${i + 1}.xml', sheet.toXml()));
    }
    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  static const _xmlHeader = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>\n';
  static const _ns = 'http://schemas.openxmlformats.org';
  static const _rel = '$_ns/officeDocument/2006/relationships';
  static const _ct = 'application/vnd.openxmlformats-officedocument.spreadsheetml';

  static String _contentTypes(int sheetCount) => [
    _xmlHeader,
    '<Types xmlns="$_ns/package/2006/content-types">',
    '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>',
    '<Default Extension="xml" ContentType="application/xml"/>',
    '<Override PartName="/xl/workbook.xml" ContentType="$_ct.sheet.main+xml"/>',
    '<Override PartName="/xl/styles.xml" ContentType="$_ct.styles+xml"/>',
    for (var i = 1; i <= sheetCount; i++)
      '<Override PartName="/xl/worksheets/sheet$i.xml" ContentType="$_ct.worksheet+xml"/>',
    '</Types>',
  ].join();

  static final String _rootRels = [
    _xmlHeader,
    '<Relationships xmlns="$_ns/package/2006/relationships">',
    '<Relationship Id="rId1" Type="$_rel/officeDocument" Target="xl/workbook.xml"/>',
    '</Relationships>',
  ].join();

  static String _workbook(List<_Sheet> sheets) => [
    _xmlHeader,
    '<workbook xmlns="$_ns/spreadsheetml/2006/main" xmlns:r="$_rel"><sheets>',
    for (final (i, s) in sheets.indexed) '<sheet name="${_escape(s.safeName)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>',
    '</sheets></workbook>',
  ].join();

  static String _workbookRels(int sheetCount) => [
    _xmlHeader,
    '<Relationships xmlns="$_ns/package/2006/relationships">',
    for (var i = 1; i <= sheetCount; i++)
      '<Relationship Id="rId$i" Type="$_rel/worksheet" Target="worksheets/sheet$i.xml"/>',
    '<Relationship Id="rId${sheetCount + 1}" Type="$_rel/styles" Target="styles.xml"/>',
    '</Relationships>',
  ].join();

  // Gaya: 0 biasa, 1 judul tebal, 2 tanggal `yyyy-mm-dd`.
  static final String _styles = [
    _xmlHeader,
    '<styleSheet xmlns="$_ns/spreadsheetml/2006/main">',
    r'<numFmts count="1"><numFmt numFmtId="164" formatCode="yyyy\-mm\-dd"/></numFmts>',
    '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>',
    '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>',
    '<fills count="2"><fill><patternFill patternType="none"/></fill>',
    '<fill><patternFill patternType="gray125"/></fill></fills>',
    '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>',
    '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>',
    '<cellXfs count="3">',
    '<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>',
    '<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>',
    '<xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/>',
    '</cellXfs>',
    '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>',
    '</styleSheet>',
  ].join();

  /// Meloloskan teks ke XML 1.0: karakter kontrol yang dilarang dibuang.
  static String _escape(String value) {
    final buffer = StringBuffer();
    for (final rune in value.runes) {
      final allowed =
          rune == 0x9 ||
          rune == 0xA ||
          rune == 0xD ||
          (rune >= 0x20 && rune <= 0xD7FF) ||
          (rune >= 0xE000 && rune <= 0xFFFD) ||
          (rune >= 0x10000 && rune <= 0x10FFFF);
      if (!allowed) continue;
      switch (rune) {
        case 0x26:
          buffer.write('&amp;');
        case 0x3C:
          buffer.write('&lt;');
        case 0x3E:
          buffer.write('&gt;');
        case 0x22:
          buffer.write('&quot;');
        default:
          buffer.writeCharCode(rune);
      }
    }
    return buffer.toString();
  }

  /// Nomor seri tanggal Excel (hari sejak 1899-12-30), dari tanggal kalender.
  static int _serial(DateTime d) => DateTime.utc(d.year, d.month, d.day).difference(DateTime.utc(1899, 12, 30)).inDays;

  static String _column(int index) {
    var n = index;
    var out = '';
    do {
      out = String.fromCharCode(65 + n % 26) + out;
      n = n ~/ 26 - 1;
    } while (n >= 0);
    return out;
  }
}

enum _CellKind { header, text, number, date }

final class _Cell {
  const _Cell(this.kind, this.value);
  const _Cell.header(String text) : this(_CellKind.header, text);
  const _Cell.text(String text) : this(_CellKind.text, text);
  const _Cell.number(String decimal) : this(_CellKind.number, decimal);
  _Cell.date(DateTime day) : this(_CellKind.date, '${ExportWriters._serial(day)}');

  final _CellKind kind;
  final String value;

  String toXml(String ref) {
    switch (kind) {
      case _CellKind.number:
        return '<c r="$ref"><v>$value</v></c>';
      case _CellKind.date:
        return '<c r="$ref" s="2"><v>$value</v></c>';
      case _CellKind.header:
        return '<c r="$ref" s="1" t="inlineStr"><is><t>${ExportWriters._escape(value)}</t></is></c>';
      case _CellKind.text:
        if (value.isEmpty) return '';
        final text = value.length > 32767 ? value.substring(0, 32767) : value;
        return '<c r="$ref" t="inlineStr"><is><t xml:space="preserve">${ExportWriters._escape(text)}</t></is></c>';
    }
  }
}

final class _Sheet {
  const _Sheet(this.name, this.rows, this.widths);

  final String name;
  final List<List<_Cell>> rows;
  final List<int> widths;

  /// Nama lembar Excel: paling panjang 31 karakter, tanpa `[]:*?/\`.
  String get safeName {
    final cleaned = name.replaceAll(RegExp(r'[\[\]:*?/\\]'), ' ').trim();
    final result = cleaned.isEmpty ? 'Sheet' : cleaned;
    return result.length > 31 ? result.substring(0, 31) : result;
  }

  String toXml() {
    final out = StringBuffer(ExportWriters._xmlHeader)
      ..write('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">')
      ..write('<sheetViews><sheetView workbookViewId="0">')
      ..write('<pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews>')
      ..write('<cols>');
    for (final (i, w) in widths.indexed) {
      out.write('<col min="${i + 1}" max="${i + 1}" width="$w" customWidth="1"/>');
    }
    out.write('</cols><sheetData>');
    for (final (r, row) in rows.indexed) {
      out.write('<row r="${r + 1}">');
      for (final (c, cell) in row.indexed) {
        out.write(cell.toXml('${ExportWriters._column(c)}${r + 1}'));
      }
      out.write('</row>');
    }
    out.write('</sheetData></worksheet>');
    return out.toString();
  }
}
