# LedgerRow

Baris transaksi di dalam `ds-listcard`. Padding 12, jarak 12.

- Icon tile `md`: ikon clay kategori, atau nada `income`.
- Baris 1: judul 13 w600 di kiri, nominal Space Mono 12 rata kanan.
- Baris 2: keterangan 12 `text-muted` ("Tempat · waktu", KT-DS2) dan tag kategori di kanan.
- Pengeluaran `text-primary`; pemasukan `income` termasuk judul; transfer `text-secondary`.

Nominal tidak pernah terpotong. Format tanda dan mata uang lewat `AppMoneyText`/`AppMoneyFormatter` di aplikasi, bukan teks tetap.

**Flutter:** `DsLedgerRow`, `DsListCard`.
