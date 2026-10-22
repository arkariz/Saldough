import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saldough/core/currency/currency.dart';
import 'package:saldough/features/data_portability/data/export_writers.dart';
import 'package:saldough/features/data_portability/domain/export_labels.dart';
import 'package:saldough/features/data_portability/domain/export_rows.dart';
import 'package:saldough/shared/transaction/transaction.dart';

import '../../helpers/export_fixtures.dart';

/// Penulis CSV dan xlsx (E-3, ADR-040 §3.6).
void main() {
  String csvText(List<int> bytes) => utf8.decode(bytes.sublist(3));

  group('CSV', () {
    test('UTF-8 dengan BOM, CRLF, judul kolom, dan baris sesuai §5.2', () {
      final data = sampleExportData();
      final bytes = ExportWriters.csv(data, buildExportRows(data), idLabels);
      expect(bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
      final lines = csvText(bytes).split('\r\n');
      expect(lines.last, '', reason: 'berakhir dengan CRLF');
      expect(lines.first, idLabels.transactionColumns.join(','));
      expect(
        lines[1],
        '2026-09-23,2026-09-25,Pemasukan,8500000,8500000,IDR,BCA,,Gaji,Gaji Sep,,Gaji bulanan,,t3',
      );
      expect(lines[2], '2026-09-26,2026-09-25,Transfer,1000000,0,IDR,BCA,GoPay,,Isi GoPay,,,,t1');
      expect(
        lines[3],
        '2026-09-26,2026-09-25,Pengeluaran,45000,-45000,IDR,GoPay,,Makan,Nasi padang,Bulanan › Makan,,,t2',
      );
    });

    test('koma, kutip ganda, dan baris baru di catatan: dikutip RFC 4180, tetap satu sel', () {
      final data = sampleExportData(noteOfSalary: 'Gaji, "bonus"\nbulan ini');
      final text = csvText(ExportWriters.csv(data, buildExportRows(data), idLabels));
      expect(text, contains('"Gaji, ""bonus""\nbulan ini"'));
    });

    test('catatan yang diawali karakter rumus diberi awalan petik; kolom angka tidak disentuh', () {
      for (final note in ['=HYPERLINK("http://x")', '+1', '-1', '@SUM(A1)']) {
        final data = sampleExportData(noteOfSalary: note);
        final line = csvText(ExportWriters.csv(data, buildExportRows(data), idLabels)).split('\r\n')[1];
        final prefixed = "'$note";
        final field = prefixed.contains(RegExp('[",]')) ? '"${prefixed.replaceAll('"', '""')}"' : prefixed;
        expect(line, contains(',$field,'), reason: 'catatan "$note" harus dilumpuhkan');
      }
      final data = sampleExportData();
      final expenseLine = csvText(ExportWriters.csv(data, buildExportRows(data), idLabels)).split('\r\n')[3];
      expect(expenseLine, contains(',-45000,'), reason: 'Arus negatif tetap angka, bukan teks berawalan petik');
    });

    test('mata uang berdesimal memakai titik desimal', () {
      final data = sampleExportData(currency: AppCurrency.usd);
      final line = csvText(ExportWriters.csv(data, buildExportRows(data), idLabels)).split('\r\n')[1];
      expect(line, contains(',8500000.00,8500000.00,USD,'));
    });

    test('tanpa transaksi: hanya baris judul', () {
      final data = sampleExportData(transactions: const []);
      final lines = csvText(ExportWriters.csv(data, const [], idLabels)).split('\r\n');
      expect(lines.length, 2);
    });
  });

  group('xlsx', () {
    Archive unzip(List<int> bytes) => ZipDecoder().decodeBytes(bytes);
    String part(Archive a, String name) => utf8.decode(a.findFile(name)!.content as List<int>);

    test('berkas ZIP berisi semua bagian OOXML dan dua lembar bernama', () {
      final data = sampleExportData();
      final a = unzip(ExportWriters.xlsx(data, buildExportRows(data), idLabels));
      expect(a.files.map((f) => f.name).toSet(), {
        '[Content_Types].xml',
        '_rels/.rels',
        'xl/workbook.xml',
        'xl/_rels/workbook.xml.rels',
        'xl/styles.xml',
        'xl/worksheets/sheet1.xml',
        'xl/worksheets/sheet2.xml',
      });
      expect(part(a, 'xl/workbook.xml'), allOf(contains('name="Transaksi"'), contains('name="Dompet"')));
    });

    test('tanggal berupa nomor seri Excel berformat tanggal; nominal berupa angka, bukan teks', () {
      final data = sampleExportData();
      final sheet = part(unzip(ExportWriters.xlsx(data, buildExportRows(data), idLabels)), 'xl/worksheets/sheet1.xml');
      // 23 Sep 2026 = 46288 (Excel: 1 Jan 2026 = 46023).
      expect(sheet, contains('<c r="A2" s="2"><v>46288</v></c>'));
      expect(sheet, contains('<c r="B2" s="2"><v>46290</v></c>'));
      expect(sheet, contains('<c r="D2"><v>8500000</v></c>'));
      expect(sheet, contains('<c r="E4"><v>-45000</v></c>'));
      expect(sheet, contains('<c r="E3"><v>0</v></c>'));
    });

    test('teks berupa inlineStr dengan karakter XML diloloskan, dan tidak pernah rumus', () {
      final data = sampleExportData(noteOfSalary: '=SUM(A1) & <b>"x"</b>');
      final sheet = part(unzip(ExportWriters.xlsx(data, buildExportRows(data), idLabels)), 'xl/worksheets/sheet1.xml');
      expect(sheet, contains('t="inlineStr"'));
      expect(sheet, contains('=SUM(A1) &amp; &lt;b&gt;&quot;x&quot;&lt;/b&gt;'));
      expect(sheet, isNot(contains('<f>')), reason: 'tanpa elemen rumus');
    });

    test('karakter kontrol XML terlarang dibuang dan sel kosong tidak ditulis', () {
      final data = sampleExportData(noteOfSalary: 'a\u0000b\u0008c\u000Bd e');
      final sheet = part(unzip(ExportWriters.xlsx(data, buildExportRows(data), idLabels)), 'xl/worksheets/sheet1.xml');
      expect(sheet, contains('abcd e'));
      expect(sheet, isNot(contains('<c r="H2"')), reason: 'dompet tujuan kosong untuk pemasukan');
    });

    test('lembar Dompet: nama, saldo awal, saldo sekarang sebagai angka; nonaktif ikut', () {
      final data = sampleExportData();
      final sheet = part(unzip(ExportWriters.xlsx(data, buildExportRows(data), idLabels)), 'xl/worksheets/sheet2.xml');
      expect(sheet, contains('>BCA<'));
      expect(sheet, contains('>GoPay<'));
      expect(sheet, contains('<c r="B2"><v>1000000</v></c>'));
      expect(sheet, contains('<c r="C2"><v>8400000</v></c>'));
    });

    test('nama lembar dibersihkan dari karakter terlarang dan dipotong 31 karakter', () {
      const labels = ExportLabels(
        fileStem: 'x',
        transactionsSheet: 'Tran/saksi: [semua] yang sangat panjang sekali namanya',
        walletsSheet: '   ',
        transactionColumns: ['a'],
        walletColumns: ['b'],
        income: '',
        expense: '',
        transfer: '',
      );
      final data = sampleExportData(transactions: const []);
      final workbook = part(unzip(ExportWriters.xlsx(data, const [], labels)), 'xl/workbook.xml');
      final names = RegExp('name="([^"]*)"').allMatches(workbook).map((m) => m.group(1)!).toList();
      expect(names.first.length, lessThanOrEqualTo(31));
      expect(names.first, isNot(matches(RegExp(r'[\[\]:*?/\\]'))));
      expect(names.last, 'Sheet');
    });

    test('ekspor 20.000 transaksi selesai dalam waktu wajar dan menghasilkan lembar utuh', () {
      final txs = <Transaction>[
        for (var i = 0; i < 20000; i++)
          ExpenseTransaction(
            id: 'e$i',
            date: DateTime(2020).add(Duration(days: i % 2000)),
            amount: 1000 + i,
            note: 'catatan $i',
            walletId: 'bca',
          ),
      ];
      final data = sampleExportData(transactions: txs);
      final stopwatch = Stopwatch()..start();
      final bytes = ExportWriters.xlsx(data, buildExportRows(data), idLabels);
      stopwatch.stop();
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 20)));
      expect(RegExp('<row ').allMatches(part(unzip(bytes), 'xl/worksheets/sheet1.xml')).length, 20001);
    });

    // Sampel untuk diperiksa pembaca pihak ketiga (openpyxl) bila diminta.
    test('menulis sampel ke EXPORT_SAMPLE_DIR bila di-set', () {
      final dir = Platform.environment['EXPORT_SAMPLE_DIR'];
      if (dir == null) return;
      final data = sampleExportData(noteOfSalary: 'Gaji, "bonus" =1+1 & <tag>\nbaris kedua 🍛');
      final rows = buildExportRows(data);
      File('$dir/sample.xlsx').writeAsBytesSync(ExportWriters.xlsx(data, rows, idLabels));
      File('$dir/sample.csv').writeAsBytesSync(ExportWriters.csv(data, rows, idLabels));
    });
  });
}
