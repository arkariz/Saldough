import 'dart:convert';

/// Dokumen penyimpanan contoh untuk uji cadangan (ADR-040), dalam bentuk
/// string tersimpan seperti yang ditulis repositori.
Map<String, String> sampleDocs({
  String wallet = 'BCA',
  List<String> months = const ['2026-10'],
  int amount = 100,
}) {
  String enc(Object o) => jsonEncode(o);
  return {
    'wallet_all': enc({
      'schemaVersion': 1,
      'items': [
        {'id': 'w1', 'name': wallet, 'iconKey': 'walletBank', 'initialBalance': 1000, 'currentBalance': 900},
        {'id': 'w2', 'name': 'Tunai', 'iconKey': 'walletCash', 'initialBalance': 50, 'currentBalance': 50},
      ],
    }),
    'category_all': enc({
      'schemaVersion': 1,
      'items': [
        {'id': 'c1', 'name': 'Makan'},
      ],
    }),
    'settings_currency': enc({'schemaVersion': 1, 'code': 'IDR'}),
    'transaction__index': enc({'months': months}),
    for (final m in months)
      'transaction_$m': enc({
        'schemaVersion': 2,
        'items': [
          {
            'id': 't-$m',
            'type': 'expense',
            'date': '$m-03T00:00:00.000',
            'amount': amount,
            'walletId': 'w1',
            'categoryId': 'c1',
            'sourceIconId': 'ic1',
          },
        ],
      }),
    'source_icon_ic1': enc({'png': 'AAAA'}),
  };
}
