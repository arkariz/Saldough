# Perbaikan hasil review UX — daftar kerja dan progres

Dokumen ini adalah daftar kerja untuk menindaklanjuti review produk/UX yang
dijalankan skill [`ux-review`](../../.claude/skills/ux-review/SKILL.md) pada
**11 September 2026**, terhadap commit `8891451` (sama dengan `main` saat
review dijalankan).

Review itu sendiri tidak mengubah kode — dokumen inilah jembatan dari temuan
ke pekerjaan. Setiap item ditulis supaya bisa dikerjakan oleh agent lain tanpa
menjalankan ulang review: sudah memuat berkas dan barisnya, apa yang salah,
akibatnya ke pemilik, langkah perbaikan konkret, kunci i18n yang perlu
ditambah, tes yang perlu ditulis, dan cara memverifikasinya.

## Cara memakai dokumen ini

Aturan pencentangan sama ketat dengan [TASK_LIST.md](TASK_LIST.md): kotak
hanya dicentang kalau perbaikannya **selesai dan terverifikasi**. Pekerjaan
setengah jalan dibiarkan kosong dengan catatan satu baris apa yang kurang.

| Penanda | Arti |
|---|---|
| `- [ ]` | Belum dikerjakan |
| `- [x]` | Selesai dan terverifikasi |
| 🔴 | Blocker — menghalangi pemilik menyelesaikan tugas intinya |
| 🟠 | Friksi — bisa diselesaikan tapi berputar-putar atau butuh tebakan |
| 🟡 | Polish — kosmetik/konsistensi, tidak menghalangi siapa pun |
| ⛔ | Terkunci — butuh keputusan pemilik dulu. **Saat ini tidak ada item terkunci**: kedua keputusan sudah dijawab (lihat bagian di bawah) |

Identitas item: `UX-<nomor>`. Kolom "Kat." merujuk kategori checklist
`ux-review` (`references/checklist.md`), supaya temuan bisa dilacak balik ke
asalnya.

## Aturan yang berlaku untuk SEMUA item

Dibaca sebelum menyentuh kode apa pun. Ini bukan anjuran — semuanya aturan
mengikat yang sudah ada di proyek, dan paling sering dilanggar saat perbaikan
UI dikerjakan cepat-cepat.

1. **Warna selalu lewat `context.appColors`** atau `colorScheme`, jarak/sudut/
   elevasi selalu lewat `AppSpacing`/`AppRadius`/`AppElevation`. Tidak pernah
   harfiah. (`.claude/AGENT_CONTEXT.md` bagian "Tampilan".)
2. **Teks antarmuka selalu lewat slang.** Tidak pernah string harfiah di
   widget, dan tidak pernah nilai mentah (id siklus, tanggal) dipakai sebagai
   pesan utuh. Setiap kunci baru ditambahkan ke **`assets/i18n/id.i18n.json`
   DAN `assets/i18n/en.i18n.json`** — paritas saat ini 160/160 kunci, jangan
   dirusak — lalu regenerasi dengan `dart run build_runner build`.
3. **Uang bertipe `int` satuan sen.** Ditampilkan lewat `AppMoneyText`/
   `AppMoneyFormatter`, tidak pernah diformat ulang di widget.
4. **Mock pakai `mocktail`** (`class MockX extends Mock implements X {}`) dan
   bloc pakai `bloc_test` (ADR-0010). Jangan membuat fake tulis tangan.
5. **`Either` dari fpdart tidak punya `==` berbasis nilai.** Jangan menulis
   `expect(result, right(...))` — ia akan gagal walau nilainya sama. Bongkar
   dengan `switch`/`case Left()`/`case Right(value: final x)` lalu `fail(...)`
   di cabang yang salah.
6. **Jangan menyunting nominal baris roll-up secara langsung** (ADR-0008).
   Beberapa item di bawah menyentuh tampilan baris roll-up — tampilannya saja,
   bukan aturan bekunya.
7. **Setiap perubahan kode ditutup dengan** `flutter analyze` (harus 0 issue)
   dan `flutter test` (baseline 124 lulus — jangan turun).

⚠ **Proyek ini belum punya satu pun widget test** — seluruh 28 berkas tes yang
ada menguji bloc, use case, repository, dan formatter. Sebagian besar item di
bawah bersifat widget. Untuk item yang logikanya bisa didorong ke bloc/state,
**tes bloc tetap wajib**. Untuk yang murni tata letak/copy, boleh tanpa tes
otomatis, tapi sebutkan di catatan pengerjaan bahwa verifikasinya manual.

## Ringkasan progres

Terakhir diperbarui: 11 September 2026 — pemilik menjawab kedua keputusan;
UX-30 selesai dan langkah dokumentasi UX-22 selesai.

| Batch | Isi | Item | Selesai | Catatan |
|---|---|---:|---:|---|
| 1 | Keamanan aksi destruktif | 1 | 0 | Prioritas #1 — tidak butuh keputusan pemilik |
| 2 | Jalan buntu dan validasi form | 5 | 0 | Prioritas #3 |
| 3 | Navigasi dan IA | 5 | 0 | |
| 4 | Cakupan state dan copy | 10 | 0 | |
| 5 | Token dan warna semantik | 9 | 1 | UX-30 selesai; UX-22 (prioritas #2) sudah dibuka — ADR-nya sudah ditulis, sisanya kode |
| 6 | Sentuh dan aksesibilitas | 5 | 0 | |
| 7 | Aturan domain (baris roll-up) | 2 | 0 | |
| **Total** | | **37** | **1** | |

Di luar daftar ini ada **3 dugaan bug** (bukan temuan UX) di bagian terakhir —
diverifikasi dan ditindak lewat skill `code-review`, bukan di sini.

## Urutan kerja yang disarankan

Bukan urutan nomor. Alasannya: yang pertama paling murah dan paling besar
akibatnya. Kedua keputusan pemilik sudah dijawab, jadi tidak ada lagi yang
menunggu.

1. **UX-01** (konfirmasi hapus) — berdiri sendiri, infrastrukturnya sudah ada.
2. **UX-22** (varian `…OnLight` di kode) — ADR-nya sudah ditulis, jadi ini
   tinggal menuangkan tabel ADR ke `AppColorsExtension` dan memakainya di titik
   pemakaian. Mengerjakannya juga membuka UX-26.
3. **UX-02 … UX-06** (jalan buntu + validasi) — satu pola dipakai ulang, jadi
   lebih murah dikerjakan sekaligus daripada terpisah.
4. **UX-25, UX-27, UX-28, UX-29** (ikon kunci, peran huruf, tumpukan cadangan,
   token garis tepi) — kecil dan tidak berisiko, bagus dikerjakan sambil
   menunggu keputusan UX-22.
5. Sisanya bebas, mengikuti prioritas pemilik.

## Keputusan pemilik — SUDAH DIJAWAB (11 September 2026)

Dua item semula terkunci karena menyentuh
[ADR-0006](../02-architecture/adr/0006-design-token-semantic-color-mapping.md),
yang statusnya sudah disetujui pemilik. **Keduanya sudah dijawab**, dan
jawabannya sudah dituliskan ke ADR-0006 bagian "8b. Catatan revisi" — jadi
ADR-nya kini yang jadi acuan, bukan dokumen ini. Tidak ada lagi item yang
terkunci.

| Keputusan | Jawaban pemilik | Dituliskan di | Sisa pekerjaan |
|---|---|---|---|
| 1 — palet mode terang | **Opsi A**: tambah varian `…OnLight`, hex isian tetap | ADR-0006 §8b + tabel varian | Kode: UX-22, lalu UX-26 |
| 2 — bayangan mode gelap | **ADR-0006 yang berlaku** | ADR-0006 §8b, `AGENT_CONTEXT.md` diselaraskan | Tidak ada — UX-30 selesai |

### ✅ Keputusan 1 — palet mode terang (jawaban: opsi A)

Pengukuran kontras WCAG di UX-22 menunjukkan enam slot semantik gagal ambang
keterbacaan **khusus di mode terang** (mode gelap sehat seluruhnya). Ini
memicu kriteria peninjauan ulang yang ADR-0006 §8 tuliskan sendiri.

Pemilik memilih **opsi A**. Tiga pilihan yang diajukan, untuk rekaman:

| Pilihan | Yang dilakukan | Akibat |
|---|---|---|
| **A ← DIPILIH** | Tambah varian `…OnLight` untuk dipakai saat warna jadi teks/ikon di atas kartu terang; hex isian tetap apa adanya | Karakter pop-art utuh (isian tetap cerah), keterbacaan beres. Tabel ADR-0006 bertambah 6 baris |
| **B** | Ganti hex terang yang ada jadi versi lebih gelap | Lebih sederhana, tapi isian chip/badge jadi lebih kalem — mengubah rasa yang pemilik pilih |
| **C** | Terima apa adanya | Ikon "perlu ditinjau" praktis tak terlihat dan angka Sisa negatif sulit dibaca di mode terang, permanen |

Hex final berikut sudah dihitung, diverifikasi lolos ≥4.5:1 terhadap kartu
putih **dan** dasar krem `#F2E9D8` dengan hue yang sama seperti slot aslinya,
dan **sudah resmi tercatat di tabel ADR-0006** — ambil dari sana saat
mengerjakan UX-22, bukan dari dokumen ini:

| Slot | Hex terang sekarang | Rasio (kartu/dasar) | Kandidat `…OnLight` | Rasio (kartu/dasar) |
|---|---|---:|---|---:|
| `income` | `#1E9E46` | 3.48 / 2.89 | `#15702F` | 6.19 / 5.14 |
| `expense` | `#E13553` | 4.34 / 3.60 | `#B01C3A` | 6.83 / 5.67 |
| `overBudget` | `#F07B12` | 2.78 / 2.31 | `#A84F05` | 5.55 / 4.60 |
| `investment` | `#D99B00` | 2.43 / 2.02 | `#7A5400` | 6.78 / 5.63 |
| `rollUp` | `#2D6FE0` | 4.71 / 3.90 | `#2159BE` | 6.49 / 5.38 |
| `needsReview` | `#FFD400` | 1.43 / 1.19 | `#756000` | 6.12 / 5.08 |

Mode gelap **tidak perlu varian apa pun** — rasio terendahnya 5.39.

### ✅ Keputusan 2 — bayangan kartu di mode gelap (jawaban: ADR-0006 berlaku)

Dua aturan proyek saling bertabrakan:

- `.claude/AGENT_CONTEXT.md:98` — "Di mode gelap, kartu memakai batas rambut,
  bukan bayangan."
- ADR-0006 §Batasan — "bayangan keras offset adalah motif, bukan opsional —
  jangan diam-diam diganti bayangan Material standar di mode terang maupun
  gelap."

Kode mengikuti ADR (`app_card.dart:44`), jadi di mode gelap setiap kartu punya
bayangan keras 4px berwarna `edge` — yang di mode gelap bernilai krem
`#F2E9D8`. Hasilnya halo krem tegas di sekeliling setiap panel di atas dasar
hitam, dan itu memang yang diinginkan.

**Pemilik menetapkan ADR-0006 yang berlaku.** `AGENT_CONTEXT.md` sudah
diselaraskan, ADR-0006 §8b mencatat keputusannya, dan tidak ada perubahan kode
maupun nilai token. Lihat UX-30 — selesai.

---

# Batch 1 — Keamanan aksi destruktif

## - [ ] UX-01 🔴 Konfirmasi untuk setiap aksi hapus

| | |
|---|---|
| **Kat.** | A (IA & navigasi) |
| **Prioritas** | #1 — kerjakan pertama |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** Delapan titik panggilan hapus (tujuh jenis objek) menjalankan
penghapusan langsung saat ikon ditekan. Hanya hapus siklus yang punya dialog
konfirmasi.

| Objek | Berkas:baris (pada `8891451`) | Event |
|---|---|---|
| Pos tujuan | `lib/features/investment/presentation/pages/investment_page.dart:141` | `GoalDeleted` |
| Kartu kredit | `lib/features/card/presentation/pages/card_page.dart:138` | `CreditCardDeleted` |
| Sumber pemasukan | `lib/features/income/presentation/pages/income_source_list_page.dart:93` | `IncomeSourceDeleted` |
| Pinjaman antar pos | `lib/features/investment/presentation/pages/investment_page.dart:365` | `GoalLoanDeleted` |
| Langganan berulang | `lib/features/card/presentation/pages/card_page.dart:388` | `RecurringSubscriptionDeleted` |
| Bahan belanja | `lib/features/grocery/presentation/pages/grocery_page.dart:146` | `GroceryItemRemoved` |
| Baris pemasukan | `lib/features/cycle/presentation/pages/cycle_page.dart:257` | `IncomeLineRemoved` |
| Baris anggaran | `lib/features/cycle/presentation/pages/cycle_page.dart:339` | `BudgetLineRemoved` |
| ✅ Siklus (sudah ada) | `lib/features/cycle/presentation/pages/cycle_page.dart:411-427` | `CycleDeleteRequested` |

**Konsekuensi.** Satu ketukan salah pada ikon 24px — yang duduk di dalam baris
yang juga bisa diketuk, karena `InkWell` induknya membuka sheet sunting —
menghapus permanen. Tidak ada undo: `actionLabel` snackbar **sengaja** belum
disambungkan ke bloc, dan alasannya terdokumentasi di
`lib/core/foundation/effect_handler/src/snackbar_effect_handler.dart:45-50`.
Yang paling berat: hapus pos tujuan membuang saldo pos beserta seluruh riwayat
alokasinya, dan hapus kartu membuang seluruh siklus tagihan kartu itu sekaligus
membuat baris anggaran roll-up yang menautnya jadi kehilangan sumber.

**Langkah perbaikan.**

1. Buat helper bersama di
   `lib/core/presentation/widgets/confirm_delete_dialog.dart` — jangan ulangi
   `showDialog` delapan kali. Alasannya sama dengan kenapa `AppCard` dibuat
   sejak fase fondasi (lihat catatan di `app_card.dart:7-10`).
   ```dart
   /// Menanyakan konfirmasi sebelum aksi yang tidak bisa dibatalkan.
   /// Mengembalikan true hanya kalau pemilik menekan tombol hapus.
   Future<bool> showConfirmDelete(
     BuildContext context, {
     required String message,
     String? title,
     String? confirmLabel,
   }) async { … }
   ```
   Isinya mengikuti pola yang sudah terbukti di `cycle_page.dart:411-427`:
   `AlertDialog` dengan dua `TextButton` (`t.common.cancel` dan label hapus),
   tombol hapus diberi `foregroundColor` destruktif — pakai slot yang sama
   dengan `dialog_effect_handler.dart:28` supaya konsisten. Ekspor lewat
   `lib/core/presentation/widgets/widgets.dart`.
2. Pasang di kedelapan titik di atas. Pola pemanggilan:
   ```dart
   onPressed: () async {
     final confirmed = await showConfirmDelete(
       context,
       title: t.investment.confirmDeleteGoalTitle(name: goal.name),
       message: t.investment.confirmDeleteGoalMessage,
     );
     if (confirmed) bloc.add(GoalDeleted(goal.id));
   },
   ```
   Hati-hati: `bloc` diambil sebelum `await` (sudah jadi kebiasaan di berkas
   ini), dan jangan memakai `context` setelah `await` untuk hal lain selain
   yang memang aman.
3. Ubah `cycle_page.dart:411-427` supaya ikut memakai helper baru, sehingga
   tidak ada dua implementasi dialog yang berbeda.
4. Tulis pesan yang menyebut **konsekuensi konkret**, mengikuti mutu
   `deleteCycleConfirmMessage` yang sudah ada ("Seluruh baris pemasukan dan
   anggaran bulan ini akan terhapus…") — bukan "Yakin?".

**Kunci i18n baru** (tambahkan ke `id.i18n.json` dan `en.i18n.json`):

```jsonc
// investment
"confirmDeleteGoalTitle": "Hapus pos $name?",
"confirmDeleteGoalMessage": "Saldo pos dan seluruh riwayat alokasinya akan terhapus. Tindakan ini tidak bisa dibatalkan.",
"confirmDeleteLoanTitle": "Hapus pinjaman ini?",
"confirmDeleteLoanMessage": "Catatan pokok dan pengembaliannya akan terhapus, dan saldo kedua pos ikut berubah.",
// card
"confirmDeleteCardTitle": "Hapus kartu $name?",
"confirmDeleteCardMessage": "Seluruh siklus tagihan dan transaksi kartu ini akan terhapus. Baris anggaran yang menaut kartu ini akan kehilangan sumbernya.",
"confirmDeleteSubscriptionTitle": "Hapus langganan $name?",
"confirmDeleteSubscriptionMessage": "Langganan ini tidak lagi disiapkan otomatis tiap siklus tagihan. Transaksi yang sudah tercatat tidak terpengaruh.",
// income
"confirmDeleteSourceTitle": "Hapus sumber $name?",
"confirmDeleteSourceMessage": "Baris pemasukan di siklus mana pun yang menaut sumber ini tidak lagi ikut berubah saat sumbernya disunting. Nominal yang sudah tercatat tidak terhapus.",
// grocery
"confirmDeleteItemTitle": "Hapus $name?",
"confirmDeleteItemMessage": "Total bulanan rencana belanja akan berubah, dan baris anggaran yang menautnya ikut menyesuaikan.",
// cycle
"confirmDeleteIncomeLineTitle": "Hapus baris $name?",
"confirmDeleteBudgetLineTitle": "Hapus baris $name?",
"confirmDeleteLineMessage": "Baris ini akan terhapus dari siklus bulan ini. Tindakan ini tidak bisa dibatalkan."
```

Catatan: `common.confirmDeleteMessage` ("Tindakan ini tidak bisa dibatalkan.")
saat ini **ada tapi tidak terpakai sama sekali** — boleh dipakai sebagai
sufiks bersama, atau dihapus kalau setiap pesan sudah menuliskannya sendiri.
Jangan ditinggalkan menggantung.

**Tes.** Tidak ada logika bloc yang berubah, jadi tes bloc yang ada harus tetap
lulus tanpa disentuh. Kalau memilih menulis widget test pertama proyek ini,
yang paling bernilai: "menekan ikon hapus lalu Batal TIDAK memancarkan event
hapus". Tempatkan di `test/features/<fitur>/presentation/pages/`.

**Verifikasi.**
- `flutter analyze` 0 issue, `flutter test` tetap ≥124 lulus.
- Periksa manual kedelapan titik: Batal benar-benar membatalkan, dan pesannya
  menyebut objek yang benar (nama pos/kartu/bahan ikut terisi).
- `grep -rn "Deleted(\|Removed(" lib --include='*.dart' | grep -v bloc` —
  setiap hasil harus berada di dalam cabang `if (confirmed)`.

---

# Batch 2 — Jalan buntu dan validasi form

## - [ ] UX-02 🔴 Pilihan "Kartu Kredit" jadi jalan buntu kalau belum ada kartu

| | |
|---|---|
| **Kat.** | B (alur & penyelesaian tugas) |
| **Berkas** | `lib/features/cycle/presentation/widgets/line_edit_sheet.dart:322-338`, `:240` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** Dua cacat bertumpuk di sheet tambah baris anggaran:

1. Chip "Kartu Kredit" (`:322-326`) adalah `AppChip` biasa — **tidak pernah
   dinonaktifkan**, berbeda dari chip "Rencana Belanja" (`:316-321`) yang lewat
   `_budgetSourceChip`.
2. Gerbangnya `widget.cards.every((card) => _isCardUsed(card.id))` (`:331`) —
   dan `[].every(...)` bernilai **`true` untuk daftar kosong**. Jadi saat belum
   ada kartu terdaftar, pemilik melihat `selectCardHint` ("Pilih kartu") tanpa
   satu pun chip untuk dipilih.

Lalu `_submit()` di `:240` `return` tanpa suara karena `rollUpSource == null`.

**Konsekuensi.** Pemilik baru yang belum mendaftarkan kartu masuk jalan buntu
total: diminta "Pilih kartu", tidak ada yang bisa dipilih, Simpan bungkam,
tanpa penjelasan dan tanpa arah keluar.

**Langkah perbaikan.**

1. Bedakan tiga keadaan, jangan satukan jadi satu `every`:
   ```dart
   bool get _hasNoCards => widget.cards.isEmpty;
   bool get _allCardsUsed =>
       widget.cards.isNotEmpty && widget.cards.every((c) => _isCardUsed(c.id));
   ```
2. Lewatkan chip "Kartu Kredit" ke `_budgetSourceChip` dengan
   `disabled: _hasNoCards || _allCardsUsed` — sejajar dengan chip Rencana
   Belanja. (Bergantung pada **UX-33**, yang membuat chip nonaktif menyebut
   alasannya; kerjakan berurutan supaya chip tidak sekadar jadi redup dan bisu.)
3. Ganti copy sesuai keadaan, bukan satu `selectCardHint` untuk semuanya:
   belum ada kartu → arahkan ke Belanja › Kartu Kredit; semua terpakai →
   sebutkan itu; ada yang bisa dipilih → baru "Pilih kartu".
4. Sekalian: `_submit()` tidak boleh lagi `return` diam-diam — itu **UX-03**,
   kerjakan bersamaan karena menyentuh fungsi yang sama.

**Kunci i18n baru** (`cycle`):
```jsonc
"noCardsHint": "Belum ada kartu terdaftar. Tambah dulu di Belanja › Kartu Kredit.",
"allCardsUsedHint": "Semua kartu sudah ditautkan ke baris anggaran lain."
```
`selectCardHint` yang ada tetap dipakai, tapi hanya untuk keadaan ketiga.

**Tes.** Logikanya ada di widget, jadi widget test yang paling langsung. Kalau
tidak menulis widget test, minimal pastikan manual: buka sheet tambah baris
anggaran di perangkat yang **belum** punya kartu, pastikan chipnya redup dan
pesannya mengarahkan.

**Verifikasi.** `flutter analyze` bersih; uji tiga keadaan (0 kartu, semua
kartu terpakai, ada kartu bebas) dan pastikan ketiganya memberi pesan berbeda
yang benar.

## - [ ] UX-03 🔴 Simpan gagal tanpa satu pun pesan

| | |
|---|---|
| **Kat.** | B, C, D |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** Setiap form melakukan `return` diam-diam saat input tidak valid:

| Berkas:baris | Kondisi yang diabaikan |
|---|---|
| `line_edit_sheet.dart:234` | label kosong (jalur roll-up) |
| `line_edit_sheet.dart:240` | sumber roll-up belum dipilih |
| `line_edit_sheet.dart:248` | label atau nominal kosong |
| `line_edit_sheet.dart:250` | nominal bukan angka |
| `worklog_page.dart:99` | jam kosong atau ≤ 0 |
| `grocery_page.dart` `_GroceryItemEditSheet._submit` | nama/harga kosong |
| `income_source_edit_sheet.dart:70` | nama kosong |

Di `assets/i18n/id.i18n.json` **tidak ada satu pun kunci validasi** — jadi ini
bukan copy yang kurang pas, melainkan belum ada sama sekali.

**Konsekuensi.** Pemilik menekan Simpan, sheet tidak tertutup, tidak ada pesan,
tidak ada field yang ditandai. Tidak ada cara tahu field mana yang salah.
Digabung dengan tidak adanya umpan balik ketukan (**UX-32**), ini tidak bisa
dibedakan dari aplikasi yang menggantung.

**Langkah perbaikan.** Pola acuannya sudah ada di repo ini dan sudah benar —
`investment_page.dart:262, 317, 321`: Simpan dinonaktifkan
(`onPressed: isValidTotal ? _submit : null`) dan angka yang salah berubah warna.
Salin pola itu, jangan bikin pola baru.

1. Di setiap `State` form, tambahkan getter `bool get _canSubmit` yang
   mengevaluasi syaratnya, dan panggil `setState` dari `onChanged` setiap field
   yang ikut menentukannya.
2. `AppButton(label: t.common.save, onPressed: _canSubmit ? _submit : null)` —
   `AppButton` sudah punya tampilan nonaktif (`app_button.dart:38`), jadi tidak
   perlu widget baru.
3. Tambahkan `errorText` pada `InputDecoration` field yang salah, supaya
   alasannya terlihat di tempat masalahnya, bukan cuma tombol yang mati.
4. Setelah semua jalur dijaga, `_submit()` tidak perlu lagi `return` bisu —
   tapi biarkan penjaganya sebagai pertahanan lapis kedua (jangan dihapus).

**Kunci i18n baru** (`common`):
```jsonc
"validationRequired": "Wajib diisi.",
"validationInvalidNumber": "Masukkan angka yang benar.",
"validationMustBePositive": "Harus lebih dari 0."
```

**Tes.** Kalau validasinya didorong ke bloc (tidak wajib, tapi lebih mudah
diuji), tulis tes bloc seperti biasa. Untuk validasi di widget, widget test.

**Verifikasi.** Untuk ketujuh jalur di tabel: buka form, biarkan kosong,
pastikan Simpan **terlihat nonaktif** (bukan aktif tapi bisu), lalu isi dan
pastikan jadi aktif.

## - [ ] UX-04 🟠 Pengali minggu hanya tersimpan kalau pemilik menekan "enter"

| | |
|---|---|
| **Kat.** | B |
| **Berkas** | `lib/features/grocery/presentation/pages/grocery_page.dart:79-90` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** `_WeeksPerMonthField` hanya punya `onSubmitted`. Tidak ada tombol
simpan dan tidak ada `onChanged`. Mengetik "5" lalu menutup keyboard atau
scroll: field tetap menampilkan 5, tapi yang tersimpan masih 4.

**Konsekuensi.** Total bulanan belanja — dan karena itu baris anggaran roll-up
yang menautnya di siklus — tetap memakai pengali lama, sementara layar
menunjukkan angka berbeda. Layar berbohong tentang isi penyimpanan, dan itu
menabrak nilai utama proyek: angka harus sama persis dengan spreadsheet.

**Langkah perbaikan.** Pilih salah satu, jangan dua-duanya:
- **(disarankan)** Commit lewat `onChanged` dengan debounce (`AppDurations`
  sudah ada sebagai sumber nilai durasi — jangan tulis angka harfiah), sambil
  tetap mempertahankan `onSubmitted`.
- Atau tambahkan tombol simpan eksplisit di sebelah field.

Jangan memakai `onEditingComplete` saja — ia tidak terpanggil saat pemilik
scroll menjauh, yang justru kasus gagalnya.

**Tes.** `grocery_bloc_test.dart` sudah ada; tambahkan kasus bahwa
`WeeksPerMonthChanged` menghasilkan `rollUpAmount` baru. Perilaku pengikatan
field-nya sendiri perlu widget test atau verifikasi manual.

**Verifikasi.** Ubah pengali, **jangan** tekan enter, scroll ke bawah lalu ke
atas lagi: nilai di field dan total bulanan harus sepakat. Lalu cek baris
anggaran roll-up di tab Siklus ikut berubah.

## - [ ] UX-05 🟠 Input tak valid berubah jadi Rp 0 secara diam-diam

| | |
|---|---|
| **Kat.** | B |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** Pola `(int.tryParse(...) ?? 0) * 100` dipakai di jalur simpan:

| Berkas:baris | Field |
|---|---|
| `income_source_edit_sheet.dart:75` | nominal tetap |
| `income_source_edit_sheet.dart:76` | tarif per jam |
| `income_source_edit_sheet.dart:~170` | nilai aturan potongan (tiap keystroke) |
| `goal_edit_sheet.dart:49` | saldo awal pos |
| `investment_page.dart:247` | tambahan dana (return deposit) |

**Konsekuensi.** Salah ketik tidak memblokir penyimpanan, tapi menulis **Rp 0**.
Tarif per jam jadi 0 berarti seluruh gaji bersih freelance jadi 0, dan tidak
ada yang memberi tahu. Untuk proyek yang menempatkan ketepatan angka di atas
kecepatan, memaksa input tak valid menjadi nol adalah perilaku paling buruk
yang mungkin dipilih.

**Langkah perbaikan.** Tolak simpan alih-alih memaksa jadi 0 — ini efek
samping wajar dari **UX-03**, jadi kerjakan setelahnya. Khusus dua hal
tambahan:

1. Bedakan "kosong" dari "nol yang disengaja". Saldo awal pos dan tambahan dana
   **boleh** 0 secara sah; nama dan tarif per jam tidak boleh kosong. Jangan
   menolak 0 yang valid.
2. Tambahkan `inputFormatters: [FilteringTextInputFormatter.digitsOnly]` pada
   field angka yang belum punya — `worklog_page.dart:135-139` (jam) dan field
   nilai potongan di `income_source_edit_sheet.dart`. Field lain sudah punya,
   jadi ini sekadar menutup celah yang tidak konsisten.

**Tes.** Tambahkan kasus di `income_source_bloc_test.dart` dan
`investment_bloc_test.dart` bahwa input tak valid **tidak** menghasilkan state
tersimpan bernilai 0.

**Verifikasi.** Isi tarif per jam dengan teks kosong lalu Simpan — harus
tertolak, bukan tersimpan sebagai Rp 0. Lalu cek gaji bersih di buku jam tidak
berubah jadi 0.

## - [ ] UX-06 🟠 Menandai baris "tetap" bisa gagal tanpa pemilik tahu

| | |
|---|---|
| **Kat.** | B |
| **Berkas** | `lib/features/cycle/presentation/bloc/cycle_bloc.dart:259-281` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** `_syncIncomeTemplate` dan `_syncBudgetTemplate` memakai
`getOrElse((_) => .empty())` untuk membaca template (`:261`, `:273`), lalu
**membuang hasil `saveTemplate()`** tanpa diperiksa (`:266`, `:278`).

**Konsekuensi.** Pin di baris berubah jadi terisi — UI-nya optimistis — tapi
kalau penulisan template gagal, baris itu tidak ikut terbawa saat rollover
bulan depan, dan pemilik baru tahu sebulan kemudian. Checklist kategori B
menandai `getOrElse` di jalur aksi utama sebagai temuan, dan menandai baris
sebagai tetap **adalah** aksi utama: ADR-0008 menyebutnya tindakan sadar yang
mendaftarkan baris ke template.

⚠ Cacat kedua di baris yang sama lebih berat dan **bukan** bagian item ini:
kalau pembacaan template gagal, kode membangun template baru dari basis kosong
lalu menulisnya kembali — menyapu seluruh baris tetap yang lain. Itu dugaan bug,
lihat **BUG-3** di bagian terakhir dokumen ini.

**Langkah perbaikan.**

1. Bongkar hasil `saveTemplate()` dengan `switch` dan pancarkan
   `_effectError(failure)` di cabang `Left` — pola `_effectError` sudah ada di
   `cycle_effect.dart:4-7`.
2. Batalkan perubahan pin di state kalau penulisannya gagal, supaya UI tidak
   menunjukkan keadaan yang tidak tersimpan. Kalau itu terlalu berbelit,
   minimal pesannya harus jelas bahwa penandaan gagal.
3. Jangan sentuh `getOrElse` di `:261`/`:273` di item ini — itu BUG-3.

**Tes.** `cycle_bloc_test.dart` sudah memakai `mocktail` + `bloc_test` dan
sudah punya `MockCycleTemplateRepository`. Tambahkan: "IncomeLineTemplateToggled
memancarkan efek galat saat saveTemplate gagal". Ingat aturan `Either` di
bagian atas dokumen — bongkar dengan `switch`, jangan `expect(result, left(...))`.

**Verifikasi.** `flutter test` dengan tes baru lulus; `flutter analyze` bersih.

---

# Batch 3 — Navigasi dan information architecture

## - [ ] UX-07 🟠 Balik ke tab Siklus selalu melompat ke bulan berjalan

| | |
|---|---|
| **Kat.** | A |
| **Berkas** | `lib/core/presentation/shell/main_shell_page.dart:92-96` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** `_CycleTab.build()` memanggil `_currentCycleId()` lalu
`..add(CycleOpened(cycleId))`. `IndexedStack` memang mempertahankan state
anaknya, tapi `setState` di `onDestinationSelected` membangun ulang
`MainShellPage`, jadi `build()` ini jalan lagi **setiap kali pindah tab**.

**Konsekuensi.** Pemilik sedang memeriksa anggaran Agustus lewat chevron,
pindah ke tab Belanja untuk mengecek roll-up, balik ke Siklus — sudah di
September lagi, tanpa pemberitahuan. Posisi navigasi hilang setiap kali.

**Langkah perbaikan.**

1. Jangan lagi memancarkan `CycleOpened` dari `build()`. Pilihan paling kecil
   risikonya: pancarkan hanya kalau belum ada siklus termuat, mis. dengan
   memeriksa `bloc.state.cycle.id.isEmpty` sebelum `add`. Alternatif yang lebih
   bersih: pindahkan ke `StatefulWidget.initState` milik `_CycleTab`.
2. ⚠ **Jangan** menghapus jalur penyegaran yang dipakai **Fix #8** — sumber
   pemasukan baru harus tetap terdeteksi tanpa pindah tab. Itu sudah ditangani
   `CycleIncomeSourcesRefreshRequested` (`cycle_page.dart:243, 275`), bukan oleh
   rebuild ini, jadi keduanya tidak bergantung satu sama lain. Verifikasi ulang
   Fix #8 setelah perubahan ini (lihat checklist kategori H).
3. Periksa tiga tab lain (`_IncomeTab`, `_GroceryTab`, `_InvestmentTab`) — pola
   `..add(XxxLoaded())` yang sama ada di ketiganya. Di sana akibatnya jauh lebih
   ringan (tidak ada "posisi" yang hilang, hanya muat ulang), tapi kalau
   diperbaiki sekalian, **pastikan** data tetap segar setelah kembali dari
   layar yang didorong `context.push` — itu justru masalah yang Fix #8 perbaiki.

**Tes.** Tambahkan di `cycle_bloc_test.dart`: `CycleOpened` untuk id yang sama
tidak perlu memuat ulang (atau, kalau solusinya di widget, cukup verifikasi
manual). Tes Fix #8 yang ada harus tetap lulus tanpa disentuh.

**Verifikasi.** Buka Siklus → geser ke bulan sebelumnya → pindah ke tab
Belanja → balik ke Siklus: harus **tetap** di bulan sebelumnya. Lalu ulangi
skenario Fix #8: tambah sumber pemasukan dari sheet baris pemasukan, balik,
sumber baru harus langsung muncul.

## - [ ] UX-08 🟠 Satu-satunya jalan ke layar Kartu Kredit terkubur di dasar tab Belanja

| | |
|---|---|
| **Kat.** | A |
| **Berkas** | `lib/features/grocery/presentation/pages/grocery_page.dart:45-49` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** Tombol "Kartu Kredit" adalah item **terakhir** `ListView` — di
bawah daftar mingguan DAN daftar bulanan. Dengan daftar belanja sungguhan
(puluhan bahan) tombol ini butuh scroll panjang, padahal ini satu-satunya pintu
ke seluruh fitur kartu di aplikasi.

Bandingkan `income_source_list_page.dart:31-35`: entry point "Catat Jam Kerja"
diletakkan paling **atas**, mendorong konten utama (daftar sumber) ke bawah.
Dua pintu sejenis, dua posisi berlawanan, dua-duanya salah arah.

**Konsekuensi.** Fitur kartu praktis tersembunyi; dan di layar Pemasukan,
konten utama terdorong oleh tombol navigasi.

**Langkah perbaikan.** Pindahkan **keduanya** ke `AppBar.actions` layar
induknya, supaya tidak ikut ter-scroll dan tidak mendorong konten utama:

- `grocery_page.dart:21` → tambahkan `actions:` dengan `IconButton`
  (`Icons.credit_card`, `tooltip: t.grocery.cardEntryPointLabel`) yang
  memancarkan `CardEntryPointTapped`.
- `income_source_list_page.dart:20` → hal yang sama dengan
  `Icons.access_time` dan `WorklogEntryPointTapped`.

⚠ Ini **bukan** pembatalan Fix #2. Fix #2 menghapus icon button Income/Worklog
dari app bar **layar Siklus**, karena di sana keduanya redundan dengan bottom
nav. Di sini app bar-nya milik layar Belanja dan Pemasukan sendiri, dan
tujuannya bukan tab — jadi tidak ada redundansi. Catat pembedaan ini di
catatan pengerjaan supaya tidak dibaca sebagai regresi Fix #2.

⚠ Ikon sendirian tidak punya label terlihat. Pastikan `tooltip` terisi, dan
pertimbangkan tetap menyisakan tombol berlabel di body untuk kartu — karena
tooltip di Android hanya muncul saat tekan-lama.

**Tes.** `grocery_bloc_test.dart` dan `income_source_bloc_test.dart` sudah
menguji event entry point-nya; tidak ada logika baru. Verifikasi manual.

**Verifikasi.** Dengan daftar belanja panjang, pintu ke Kartu Kredit harus
terjangkau tanpa scroll.

## - [ ] UX-09 🟠 Pemilik harus mengetik `YYYY-MM` dengan tangan di dua tempat

| | |
|---|---|
| **Kat.** | B |
| **Berkas** | `lib/features/worklog/presentation/pages/worklog_page.dart:241-244`, `lib/features/investment/presentation/pages/investment_page.dart:266-270` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** Dua layar meminta pemilik mengetik kode bulan sebagai teks bebas:
"Siklus tujuan (YYYY-MM)" untuk menyuntikkan gaji bersih, dan "Siklus
(YYYY-MM)" sebagai pintu masuk **seluruh** alur alokasi investasi bulanan.

**Konsekuensi.** Mengetik kode bulan adalah pekerjaan tangan yang justru jadi
alasan aplikasi ini dibuat. Salah ketik di layar investasi hanya dibalas
`cycleNotFound` ("Siklus ini belum ada.") tanpa menyebut siklus apa saja yang
**ada**. Ini juga bertolak belakang dengan premis Fix #1, yang sengaja
menyembunyikan `YYYY-MM` dari mata pemilik di app bar.

**Langkah perbaikan.** Ganti `TextField` dengan pemilih dari daftar siklus yang
benar-benar ada. Datanya sudah tersedia di sisi `cycle`
(`CycleRepository.listCycleIds`, `cycle_repository.dart:15`) — yang belum ada
adalah jalan membacanya dari dua fitur ini tanpa melanggar ADR-0009.

Pola yang harus diikuti sudah mapan di repo ini: kedua fitur **sudah** punya
port sendiri ke `cycle`, diimplementasikan di `features/cycle/data/adapters/`
dan dikawat di `RootModule`. Jadi tambahkan method ke port yang sudah ada,
jangan bikin port baru:

1. `lib/features/worklog/domain/repositories/cycle_income_writer.dart` →
   tambah `Future<Either<Failure, List<String>>> listCycleIds();`
   **Hapus `// ignore_for_file: one_member_abstracts` di berkas itu** — setelah
   ada method kedua, ignore itu tidak lagi berlaku dan akan jadi ignore mati.
2. `lib/features/investment/domain/repositories/cycle_investment_gateway.dart` →
   tambah method yang sama.
3. Implementasikan di `lib/features/cycle/data/adapters/cycle_income_writer_impl.dart`
   dan `cycle_investment_gateway_impl.dart` dengan mendelegasikan ke
   `CycleRepository.listCycleIds()`.
4. Muat daftarnya ke `WorklogState` dan `InvestmentState`, lalu ganti field jadi
   `AppChip` (atau `DropdownButton`) berlabel hasil
   `CycleMonthFormatter.format(id)` — jangan tampilkan `YYYY-MM` mentah.
5. Untuk investasi, default ke siklus terbaru yang belum ditutup kalau ada;
   `cycleNotFound` jadi nyaris tak terjangkau setelah ini, tapi biarkan sebagai
   pertahanan lapis kedua.

**Tes.** Wajib, karena ini menyentuh port lintas fitur:
- `test/features/cycle/data/adapters/cycle_income_writer_impl_test.dart` dan
  `cycle_investment_gateway_impl_test.dart` sudah ada — tambahkan kasus
  `listCycleIds` meneruskan hasil dan meneruskan `Failure`.
- `worklog_bloc_test.dart` dan `investment_bloc_test.dart` — state memuat daftar
  siklus saat dibuka.
- Ingat aturan `Either`: bongkar dengan `switch`, jangan `expect(result, right(...))`.

**Verifikasi.** `flutter test` lulus; di kedua layar, siklus dipilih dari daftar
dan labelnya berupa nama bulan ("Agustus 2026"), bukan `2026-08`.

## - [ ] UX-10 🟡 Bagian di bawah daftar kartu tidak menyebut kartu mana

| | |
|---|---|
| **Kat.** | A |
| **Berkas** | `lib/features/card/presentation/pages/card_page.dart:52-84` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** "Siklus tagihan berjalan", form transaksi, langganan, dan riwayat
semuanya milik `state.selectedCard`, tapi tidak ada satu pun judul yang
menyebut nama kartunya. Satu-satunya penanda adalah ikon centang 18px di kartu
terpilih jauh di atas (`:112`).

**Konsekuensi.** Dengan dua kartu (sesuai data pemilik) ini ambigu setelah
scroll: pemilik bisa mencatat transaksi ke kartu yang salah.

**Langkah perbaikan.** Sisipkan nama kartu ke judul bagian, mis. "Siklus
tagihan berjalan — BRI Touch". Butuh kunci i18n berparameter, bukan
penggabungan string di widget (aturan slang).

**Kunci i18n baru** (`card`) — menggantikan pemakaian telanjang kunci yang ada:
```jsonc
"openStatementTitleFor": "Siklus tagihan berjalan — $cardName",
"subscriptionsTitleFor": "Langganan berulang — $cardName",
"historyTitleFor": "Riwayat siklus tagihan — $cardName"
```
Kunci lama (`openStatementTitle`, `subscriptionsTitle`, `historyTitle`) tetap
dipakai kalau hanya ada satu kartu terdaftar — atau dihapus kalau diputuskan
selalu memakai varian bernama. Jangan tinggalkan kunci menggantung.

**Verifikasi.** Dengan dua kartu, setiap judul bagian menyebut kartu yang aktif,
dan ikut berubah saat kartu lain dipilih.

## - [ ] UX-11 🟡 `LineEditSheet` tidak punya tombol Batal

| | |
|---|---|
| **Kat.** | A |
| **Berkas** | `lib/features/cycle/presentation/widgets/line_edit_sheet.dart:373`, `:360` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** Sheet hanya menampilkan Simpan, padahal `t.common.cancel` sudah ada
dan dipakai di dialog. Dengan `autofocus: true` (`:360`) keyboard langsung
terbuka, jadi satu-satunya jalan keluar adalah menarik sheet ke bawah atau
mengetuk scrim di atas keyboard.

**Langkah perbaikan.** Tambahkan Batal di sebelah Simpan dalam satu `Row`
(gunakan `AppSpacing.sm` sebagai jarak). ⚠ Perhatikan **UX-35**: sheet ini
belum bisa di-scroll, jadi menambah baris tombol memperburuk risiko terdorongnya
Simpan keluar layar. Kerjakan **setelah** atau **bersama** UX-35.

Periksa juga sheet lain supaya konsisten: `income_source_edit_sheet.dart`,
`_GroceryItemEditSheet`, `goal_edit_sheet.dart`, `goal_loan_edit_sheet.dart`,
`credit_card_edit_sheet.dart`, `recurring_subscription_edit_sheet.dart`.
Keputusannya harus sama di semuanya — pilih satu dan terapkan menyeluruh.

**Verifikasi.** Batal menutup sheet tanpa menyimpan apa pun di seluruh sheet.

---

# Batch 4 — Cakupan state dan copy

## - [ ] UX-12 🟠 `rollUpSourceUnavailable` tidak memberi tahu apa yang harus dilakukan

| | |
|---|---|
| **Kat.** | C |
| **Berkas** | `lib/features/cycle/presentation/widgets/cycle_line_tile.dart:86-90` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** Menampilkan `t.cycle.rollUpSourceUnavailable` ("Sumber belum
tersedia") sebagai `bodySmall` polos — warna `textMuted`, tanpa ikon. Pemilik
melihat baris bernominal Rp 0 dengan keterangan samar, tanpa tahu bahwa yang
perlu dilakukan adalah mendaftarkan kartunya dulu.

**Konsekuensi.** Baris anggaran menunjukkan Rp 0 yang terlihat seperti data
hilang, padahal sebabnya bisa ditindaklanjuti.

**Langkah perbaikan.**

1. Bedakan sumbernya. `BudgetLine.rollUpSource` sudah membedakan grocery dari
   kartu, jadi pesannya bisa spesifik — teruskan informasi itu ke
   `CycleLineTile` (tambah parameter, jangan baca entity domain dari widget
   kalau pola di berkas ini memang meneruskan nilai primitif).
2. Tulis copy yang menyebut sebab **dan** solusi. Acuan mutu ada di fitur
   sebelah: `investment.cycleClosedMessage` = "Siklus ini sudah ditutup. Buka
   kembali untuk menyunting alokasi." Tiru strukturnya.

**Kunci i18n baru** (`cycle`):
```jsonc
"rollUpSourceUnavailableCard": "Kartu sumbernya belum terdaftar. Tambah dulu di Belanja › Kartu Kredit.",
"rollUpSourceUnavailableGrocery": "Rencana belanja masih kosong. Isi dulu di tab Belanja."
```
`rollUpSourceUnavailable` yang ada boleh tetap jadi cadangan, atau dihapus
kalau kedua cabang sudah tertutup.

**Verifikasi.** Buat baris anggaran roll-up ke kartu, lalu hapus kartunya
(sekarang lewat konfirmasi UX-01): barisnya harus menjelaskan apa yang hilang
dan ke mana harus pergi.

## - [ ] UX-13 🟠 Badge "Perlu ditinjau" tidak pernah menjelaskan maknanya

| | |
|---|---|
| **Kat.** | C |
| **Berkas** | `lib/features/cycle/presentation/widgets/cycle_line_tile.dart:98`, `lib/features/cycle/presentation/pages/cycle_page.dart:151` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** Badge hanya berbunyi "Perlu ditinjau" dan banner "Ada $count baris
perlu ditinjau." Makna sebenarnya menurut ADR-0008 — baris ini hasil salinan
rollover, nominalnya warisan bulan lalu dan belum dikonfirmasi untuk bulan ini —
tidak tersampaikan sama sekali.

**Konsekuensi.** Pemilik yang tidak membaca ADR tidak punya cara menyimpulkan
bahwa yang diminta adalah **memeriksa nominalnya**, bukan sekadar menekan
"Sudah benar". Akibatnya baris warisan bisa dikonfirmasi tanpa diperiksa — dan
angka bulan ini salah, yang langsung melawan nilai inti proyek.

**Langkah perbaikan.** Tambahkan satu baris penjelas di `_UnreviewedBanner`
(`cycle_page.dart:135-157`), bukan di setiap badge (supaya tidak berulang-ulang
di tiap baris).

**Kunci i18n baru** (`cycle`):
```jsonc
"unreviewedBannerHint": "Nominalnya masih ikut bulan lalu — periksa sebelum ditandai benar."
```

**Verifikasi.** Jalankan rollover, lihat banner di siklus baru: harus
menjelaskan apa yang diminta, bukan cuma jumlahnya.

## - [ ] UX-14 🟠 Snackbar sukses rollover isinya `id` siklus mentah

| | |
|---|---|
| **Kat.** | D |
| **Berkas** | `lib/features/cycle/presentation/bloc/cycle_effect.dart:9-12` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** `_effectCycleCreated(cycleId)` mengembalikan
`ShowSnackBarEffect(message: cycleId)`. Setelah menekan "Buat bulan berikutnya",
pemilik melihat snackbar hijau yang isinya hanya **`2026-10`** — bukan kalimat,
dan tanpa kunci slang sama sekali.

**Konsekuensi.** Melanggar aturan `.claude/AGENT_CONTEXT.md:96` ("Teks
antarmuka selalu lewat slang. Tidak pernah harfiah"), sekaligus memunculkan
kembali format `YYYY-MM` yang Fix #1 sengaja sembunyikan dari pemilik.

**Langkah perbaikan.**
```dart
UiEffect _effectCycleCreated(String cycleId) => ShowSnackBarEffect(
  message: t.cycle.cycleCreatedMessage(
    month: CycleMonthFormatter.format(cycleId),
  ),
  severity: .success,
);
```
Tambahkan impor `CycleMonthFormatter` di `cycle_bloc.dart` (berkas effect ini
adalah `part of` bloc-nya).

**Kunci i18n baru** (`cycle`):
```jsonc
"cycleCreatedMessage": "Siklus $month sudah dibuat."
```

**Tes.** `cycle_bloc_test.dart` sudah menguji rollover. Tambahkan/perbarui
penegasan bahwa pesan efeknya bukan id mentah.

**Verifikasi.** Rollover memunculkan "Siklus Oktober 2026 sudah dibuat."

## - [ ] UX-15 🟠 "Per mil" vs glosarium "persentase" vs enum `.percentage`

| | |
|---|---|
| **Kat.** | D, G |
| **Butuh keputusan pemilik** | Sebagian — penggantian nama enum |

**Masalah.** Tiga sumber tidak sejalan di jalur hitung gaji bersih:

| Sumber | Menyebut |
|---|---|
| `assets/i18n/id.i18n.json:69` (`deductionKindPermille`) | "Per mil" |
| `lib/shared/income/domain/calculate_net_pay.dart:23` | `grossPay * rule.value ~/ 1000` → per mil |
| `docs/00-foundation/PROJECT_GLOSSARY.md:47` | "persentase atau nominal tetap" |
| `DeductionKind.percentage` (`lib/shared/income/domain/deduction_kind.dart`) | persentase |

Kode dan label UI sudah **benar** (per mil); glosarium dan nama enum yang salah.

**Konsekuensi.** Pemilik yang membaca glosarium akan memasukkan angka dengan
asumsi persen, lalu potongannya 10× lebih kecil dari yang dimaksud — di field
yang menentukan gaji bersih. Ini temuan copy yang berujung pada angka salah.

**Langkah perbaikan.**

1. **Tanpa perlu keputusan:** perbaiki `PROJECT_GLOSSARY.md:47` menjadi "per mil
   atau nominal tetap", dan periksa `DOMAIN_MODEL.md` apakah menyebut hal yang
   sama — kalau ya, perbaiki juga.
2. **Butuh persetujuan pemilik** (perubahan kode lintas berkas): ganti nama
   `DeductionKind.percentage` → `.permille`. Menyentuh `deduction_kind.dart`,
   `deduction_rule.dart`, `deduction_rule_model.dart` (hati-hati: nilai
   serialisasi tersimpan — **jangan** mengubah string yang sudah ada di
   penyimpanan tanpa migrasi), `calculate_net_pay.dart`,
   `income_source_edit_sheet.dart`, dan tes terkait.
   ⚠ Periksa `deduction_rule_model.dart` dulu: kalau nama enum ikut tersimpan ke
   Hive, penggantian nama akan merusak data seed yang sudah diimpor di Fase 6.
   Kalau begitu, cukup kerjakan langkah 1 dan catat alasan enum dibiarkan.

**Tes.** `test/shared/income/domain/calculate_net_pay_test.dart` sudah ada dan
sudah menguji per mil — pastikan tetap lulus. Kalau enum diganti nama, tes
`worklog_repository_impl_test.dart` dan seed Fase 6 perlu dicek ulang.

**Verifikasi.** Jalankan ulang rekonsiliasi seed Fase 6 (lihat catatan T-6.8 di
TASK_LIST.md) — nol selisih rupiah harus tetap nol.

## - [ ] UX-16 🟡 Gagal memuat terlihat seperti siklus kosong

| | |
|---|---|
| **Kat.** | B, C |
| **Berkas** | `lib/features/cycle/presentation/pages/cycle_page.dart:29`, `lib/features/cycle/presentation/bloc/cycle_bloc.dart` cabang `Left` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** `t.common.retry` ("Coba lagi") ada di i18n tapi **tidak dipakai di
mana pun**. Saat `getCycle` gagal, bloc hanya memunculkan snackbar lalu
`isLoading: false`; `cycle_page.dart:29` lolos dari gerbang spinner dan merender
halaman dengan "Belum ada baris pemasukan." / "Belum ada baris anggaran."

**Konsekuensi.** Snackbar hilang setelah beberapa detik, lalu pemilik menatap
layar yang menyatakan datanya kosong. Di aplikasi keuangan, kegagalan baca yang
tampil sebagai "tidak ada data" adalah pesan yang menakutkan dan salah.

**Langkah perbaikan.**

1. Tambahkan penanda galat ke `CycleState` (mis. `String? loadErrorMessage`,
   atau `bool hasLoadError`) — ini data state, jadi masuk `props`, **berbeda**
   dari `effect` yang sengaja dikecualikan dari `props` (ADR-0003).
2. Render state galat tersendiri di `cycle_page.dart` dengan tombol "Coba lagi"
   yang memancarkan `CycleOpened(state.cycle.id)`. Copy-nya sudah ada.
3. Bersihkan penanda itu saat pemuatan berikutnya berhasil.
4. Lakukan hal yang sama di layar lain yang punya pola `isLoading && isEmpty`
   kalau sekalian dikerjakan — tapi cycle yang paling penting.

⚠ Ada dugaan bug di jalur yang sama (`BUG-1`: layar galat Flutter kalau
pemuatan **pertama** gagal, karena `cycle.id` masih kosong). Memperbaiki UX-16
dengan benar kemungkinan besar ikut menutup BUG-1 — tapi tetap verifikasi BUG-1
secara terpisah lewat `code-review`, jangan diasumsikan beres.

**Tes.** `cycle_bloc_test.dart`: "CycleOpened yang gagal menghasilkan state
bertanda galat, bukan state siklus kosong".

**Verifikasi.** Paksa kegagalan baca (mis. lewat mock di tes, atau sementara di
repository) dan pastikan layar menampilkan galat + tombol, bukan daftar kosong.

## - [ ] UX-17 🟡 Penanganan state memuat tidak konsisten, dan token shimmer mati

| | |
|---|---|
| **Kat.** | C, E |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** Tiga hal terkait:

1. `cycle_page.dart:29` mensyaratkan `state.cycle.id.isEmpty`, jadi pindah bulan
   lewat chevron **tidak menampilkan indikator apa pun** — ketuk, lalu layar
   diam sampai data datang.
2. `grocery_page.dart:25` sebaliknya: `if (state.isLoading)` tanpa penjaga, jadi
   setiap muat ulang mengganti seluruh halaman dengan spinner dan membuang
   posisi scroll.
3. `shimmerBase`/`shimmerHighlight` di `app_colors_extension.dart:69-73` punya
   **0 pemakaian** — skeleton yang ADR-0006 siapkan slotnya tidak pernah dibuat.

**Konsekuensi.** Satu pola per layar, tidak ada yang bisa diandalkan pemilik;
dan dua slot token yang dijanjikan ADR-0006 tidak pernah sampai ke layar.

**Langkah perbaikan.**

1. Samakan aturannya: pemuatan **pertama** (belum ada data) → skeleton/spinner
   penuh; pemuatan **ulang** (sudah ada data) → indikator halus yang tidak
   membuang konten, mis. `RefreshProgressIndicator` kecil di app bar, bukan
   mengganti seluruh body.
2. Buat `AppSkeleton` di `lib/core/presentation/widgets/` yang memakai
   `shimmerBase`/`shimmerHighlight` dan `AppDurations` untuk animasinya, lalu
   pakai untuk pemuatan pertama. Ini sekaligus menutup temuan slot mati.
3. Kalau skeleton dinilai terlalu besar cakupannya untuk sekarang, minimal
   selesaikan poin 1 dan catat bahwa kedua slot shimmer masih menganggur —
   jangan centang item ini sebagian.

**Verifikasi.** Pindah bulan memberi umpan balik; muat ulang Belanja tidak
membuang posisi scroll.

## - [ ] UX-18 🟡 State kosong menyebut tujuan tanpa menyediakan jalannya

| | |
|---|---|
| **Kat.** | C |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** `worklog.noFreelanceSource` menyebut "Tambah dulu di layar Sumber
Pemasukan" tanpa tombol ke sana (`worklog_page.dart:25-27`);
`cycle.emptyIncome`/`emptyBudget` hanya "Belum ada baris …" tanpa mengarahkan
aksi (`cycle_page.dart:225`, `:310`).

**Langkah perbaikan.** Untuk tiap state kosong, sediakan aksi di tempatnya —
pola acuannya sudah ada dan sudah benar: hint + `AppButton` di
`line_edit_sheet.dart:284-300` (hasil Fix #3). Tiru itu.

Untuk `cycle.emptyIncome`/`emptyBudget`, tombol "Tambah baris…" sudah ada tepat
di bawah daftar, jadi cukup sesuaikan copy supaya mengarah ke tombol itu alih-alih
sekadar menyatakan kekosongan.

**Kunci i18n** — sesuaikan nilai yang ada (bukan kunci baru):
```jsonc
"emptyIncome": "Belum ada baris pemasukan. Tambahkan yang pertama di bawah.",
"emptyBudget": "Belum ada baris anggaran. Tambahkan yang pertama di bawah."
```
Untuk worklog, tambahkan tombol yang memancarkan navigasi ke Sumber Pemasukan.

**Verifikasi.** Di setiap state kosong ada satu aksi jelas yang bisa diketuk.

## - [ ] UX-19 🟡 Satu konsep, dua ejaan

| | |
|---|---|
| **Kat.** | D |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.**

| Konsep | Di satu tempat | Di tempat lain | Glosarium |
|---|---|---|---|
| Rencana belanja | `cycle.budgetSourceGrocery` = "Rencana **B**elanja" | `grocery.pageTitle` = "Rencana **b**elanja" | "Rencana belanja" |
| Kartu kredit | `cycle.budgetSourceCard` = "Kartu **K**redit" | `card.pageTitle` = "Kartu **k**redit" | "Kartu" / "Kartu kredit" |

Terlihat langsung ke pemilik: baris anggaran yang dibuat lewat chip itu diberi
nama "Rencana Belanja" (`line_edit_sheet.dart:195`), sementara layar tujuannya
berjudul "Rencana belanja".

**Langkah perbaikan.** Samakan ke bentuk glosarium (huruf kapital hanya di awal
kalimat) di `id.i18n.json` **dan** `en.i18n.json`. Periksa sekalian seluruh
nilai i18n untuk drift serupa.

⚠ Nama baris anggaran yang **sudah tersimpan** dari seed/pemakaian tidak ikut
berubah — label tersimpan di entity, bukan dibaca dari i18n saat render. Jangan
menulis migrasi untuk ini; cukup catat bahwa baris lama mempertahankan namanya.
(Lihat juga **UX-37**: pemilik semestinya bisa menamai sendiri.)

**Verifikasi.** `grep -n "Rencana Belanja\|Kartu Kredit" assets/i18n/*.json`
tidak menyisakan bentuk title-case.

## - [ ] UX-20 🟡 `kindAdHoc` tidak memakai istilah glosarium

| | |
|---|---|
| **Kat.** | D |
| **Berkas** | `assets/i18n/id.i18n.json:64`, `docs/00-foundation/PROJECT_GLOSSARY.md:40` |
| **Butuh keputusan pemilik** | Ringan — pilih mana yang menang |

**Masalah.** UI menulis "Sekali jalan"; glosarium menetapkan "Pemasukan lain"
untuk `IncomeSourceKind.adHoc`.

**Langkah perbaikan.** Pilih satu dan selaraskan dua-duanya. "Sekali jalan"
sebetulnya lebih deskriptif untuk dipakai sebagai label chip pendek; kalau itu
yang dipilih, **perbarui glosariumnya**, jangan biarkan dua istilah hidup
bersama. Glosarium sendiri mewajibkan istilah ditambahkan di sana dulu sebelum
dipakai (`PROJECT_GLOSSARY.md:5`).

**Verifikasi.** Hanya satu istilah muncul di kode dan dokumen.

## - [ ] UX-21 🟡 Tanggal mentah dan judul konfirmasi generik

| | |
|---|---|
| **Kat.** | D |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.**
- `worklog_page.dart:130` menyusun tanggal dengan tangan →
  `'${_date.year}-${_date.month…}-${_date.day…}'` = "2026-09-11". Melanggar
  aturan slang, dan tidak konsisten dengan bulan di app bar siklus yang sudah
  diformat lokal sejak Fix #1.
- `cycle_page.dart:414` memakai `common.confirmDeleteTitle` = "Hapus?" —
  pesan di bawahnya sudah bagus dan menyebut konsekuensi, tapi judulnya tidak
  menyebut siklus apa.

**Langkah perbaikan.**
1. Buat `CycleDayFormatter` (atau tambahkan method ke `CycleMonthFormatter`) di
   `lib/core/utils/formatters/`, mengikuti pola yang sudah ada di
   `cycle_month_formatter.dart` — termasuk alasan kenapa nama bulan ditulis
   tangan dan bukan lewat `DateFormat` (`flutter_localizations` tidak dimuat;
   lihat komentar `:52-56` di berkas itu). Pakai daftar bulan yang sama,
   jangan menduplikasinya.
2. Tes formatter baru di `test/core/utils/formatters/` — `cycle_month_formatter_test.dart`
   sudah jadi contoh bentuknya.
3. Judul konfirmasi hapus siklus ikut diperbaiki saat mengerjakan **UX-01**
   (kunci `confirmDeleteCycleTitle` dengan parameter `$month`).

**Verifikasi.** Tanggal di form catat jam tampil sebagai "11 September 2026"
(atau bentuk lokal yang dipilih), bukan `2026-09-11`.

---

# Batch 5 — Token dan warna semantik

## - [ ] UX-22 🔴 Mode terang gagal ambang kontras di hampir seluruh palet semantik

| | |
|---|---|
| **Kat.** | E |
| **Prioritas** | #2 |
| **Butuh keputusan pemilik** | Tidak lagi — **opsi A sudah dipilih**, dan langkah 1 (ADR-0006) sudah dikerjakan. Sisanya kode. |

**Masalah.** Rasio kontras WCAG dihitung dari tabel hex ADR-0006 (ambang 4.5:1
teks normal, 3:1 teks besar ≥18.66px bold):

| Pemakaian nyata | Berkas:baris | Terang | Gelap |
|---|---|---:|---:|
| Ikon 🚩 `needsReview` di atas kartu putih | `cycle_page.dart:149` | **1.43** ❌ | 13.34 ✅ |
| Sisa negatif (`overBudget`, `headlineSmall`) | `app_money_text.dart:39` + `cycle_page.dart:197` | **2.78** ❌ | 8.39 ✅ |
| `AppChip` terpilih: teks krem di atas hijau | `app_chip.dart:48, 57` | **2.89** ❌ | 10.76 ✅ |
| Nominal `income` (`titleMedium`, 16px) | `cycle_line_tile.dart:113` | **3.48** ❌ | 9.62 ✅ |
| `AppButton`: putih di atas hijau | `app_theme.dart:74-75` | **3.48** ❌ | 10.36 ✅ |
| Slot `investment` | (belum dipakai, lihat UX-26) | **2.43** ❌ | 12.02 ✅ |

Mode gelap sehat seluruhnya — rasio terendahnya 5.39, tidak butuh perubahan.

⚠ Ini bukan temuan yang baru muncul. `UI_UX_DESIGN_TASKS.md:227-235` sudah
menandainya sebagai keputusan terbuka untuk ronde implementasi, lalu `:346-348`
menyatakannya "closed" karena penambahan `onNeedsReview`. Penutupan itu **hanya
benar untuk kasus teks di atas isian kuning** (memang aman: 12.93). Kasus warna
sebagai **teks atau ikon di atas kartu terang** tidak pernah diperiksa — dan
justru itulah yang dipakai `_UnreviewedBanner`. Catatan itu perlu dibuka kembali,
dan cakupannya lebih luas dari perkiraan semula: bukan cuma `needsReview` dan
`investment`, tapi juga `income`, `expense`, `overBudget`, dan `rollUp`.

**Konsekuensi.** Dua elemen terpenting di layar utama paling parah: ikon penanda
"perlu ditinjau" praktis tak terlihat, dan angka Sisa saat lewat anggaran gagal
bahkan untuk ambang teks besar. Pemilik tidak bisa memindai apakah bulan ini
aman tanpa membaca pelan-pelan.

**Langkah perbaikan** (opsi A — pemilik sudah memilih).

1. ~~Tulis ulang tabel hex di ADR-0006 dengan enam baris `…OnLight`, plus
   catatan revisi.~~ **SELESAI 11 September 2026** — lihat ADR-0006 bagian
   "Varian `…OnLight`" untuk nilai hex final dan bagian 8b untuk catatan
   revisinya. Ambil hex dari ADR, jangan dari dokumen ini.
2. Tambahkan enam field ke `AppColorsExtension`
   (`lib/core/theme/extensions/app_colors_extension.dart`): `incomeOnLight`,
   `expenseOnLight`, `overBudgetOnLight`, `investmentOnLight`, `rollUpOnLight`,
   `needsReviewOnLight`. **Wajib** diisi di `light` **dan** `dark` (di `dark`,
   isi dengan nilai slot aslinya — mode gelap tidak butuh varian), lalu
   ditambahkan ke `copyWith` dan `lerp`. Melewatkan salah satu dari dua method
   itu akan lolos `analyze` tapi merusak transisi tema — tiap field harus
   muncul 7 kali di berkas itu (parameter konstruktor, deklarasi field, `light`,
   `dark`, parameter `copyWith`, penugasan `copyWith`, `lerp`); hitung dengan
   `grep -c` sebagai pemeriksaan cepat.
3. Ganti pemakaian di titik-titik pada tabel di atas supaya memakai varian
   `…OnLight` saat warna dipakai sebagai **teks/ikon**, dan tetap memakai slot
   asli saat dipakai sebagai **isian** (chip terpilih, latar snackbar, tombol).
   `AppMoneyText` (`app_money_text.dart:36-40`) dan `AppChip._onFill`
   (`app_chip.dart:56-57`) adalah dua titik pusatnya — memperbaiki keduanya
   menutup sebagian besar kasus sekaligus.
4. Jangan membuat varian `…OnDark`. Tidak ada yang membutuhkannya, dan itu
   menggandakan permukaan token tanpa alasan.

**Tes.** Tulis tes token di `test/core/theme/app_colors_extension_test.dart`
(belum ada — ini berkas baru) yang **menghitung rasio kontras** dan menegaskan
setiap varian `…OnLight` ≥4.5:1 terhadap `cardBackground` dan `background`.
Dengan begitu regresi palet ketangkap otomatis, bukan lewat mata. Rumus WCAG
relative luminance cukup belasan baris Dart murni, tidak butuh Flutter.

**Verifikasi.** Tes kontras lulus; periksa mata di mode terang bahwa ikon
"perlu ditinjau" dan angka Sisa negatif terbaca jelas.

## - [ ] UX-23 🟠 Nominal anggaran tampil hijau "pemasukan"

| | |
|---|---|
| **Kat.** | E |
| **Berkas** | `lib/features/cycle/presentation/widgets/cycle_line_tile.dart:113-116`, `lib/features/cycle/presentation/pages/cycle_page.dart:176-190` |
| **Butuh keputusan pemilik** | Tidak (keterbacaannya ikut membaik setelah UX-22, tapi tidak bergantung padanya) |

**Masalah.** Kedua titik memanggil `AppMoneyText` **tanpa** `color`, jadi
pewarnaan otomatis berdasarkan tanda berlaku — dan nominal anggaran selalu
disimpan positif, sehingga dirender dengan `colors.income`.

**Konsekuensi.** Di kartu total, "Pemasukan" dan "Anggaran" tampil dengan warna
**persis sama**; di daftar baris, pengeluaran listrik terlihat sehijau gaji
masuk. Seluruh guna warna semantik — memindai layar tanpa membaca label — hilang.

Ini tepat yang diperingatkan dokumentasi widget itu sendiri
(`app_money_text.dart:11-14`): *"Pakai [color] untuk menimpa … misalnya baris
anggaran yang nominalnya selalu disimpan positif tapi semantiknya pengeluaran."*
Peringatannya ada, pemakainya tidak mengikutinya.

**Langkah perbaikan.**

1. `cycle_line_tile.dart`: tambahkan parameter yang membedakan baris pemasukan
   dari baris anggaran (mis. `bool isExpense`), teruskan dari `_IncomeSection`/
   `_BudgetSection`, lalu kirim `color: colors.expense` (atau
   `expenseOnLight` setelah UX-22) untuk baris anggaran.
2. `_TotalsCard` (`cycle_page.dart:159-207`): beri `color` eksplisit pada total
   Pemasukan (`income`) dan total Anggaran (`expense`).
3. **Biarkan Sisa** memakai pewarnaan otomatis — di sana tandanya memang yang
   bermakna, dan ADR-0006 secara khusus menetapkan sisa negatif memakai
   `overBudget` (bukan `expense`). Jangan sentuh itu.

**Tes.** Murni tampilan; verifikasi manual, atau widget test kalau sekalian
memulai.

**Verifikasi.** Di kartu total, angka Pemasukan dan Anggaran berbeda warna; baris
anggaran tidak lagi hijau.

## - [ ] UX-24 🟠 Slot `expense` dipakai untuk tombol hapus yang netral

| | |
|---|---|
| **Kat.** | E |
| **Berkas** | `cycle_line_tile.dart:130`, `cycle_page.dart:409`, `dialog_effect_handler.dart:28`, `app_theme.dart:37` |
| **Butuh keputusan pemilik** | Ringan — lihat langkah 2 |

**Masalah.** `colors.expense` dipakai untuk ikon hapus di dua tempat dan untuk
tombol destruktif di dialog; selain itu `app_theme.dart:37` memetakan
`ColorScheme.error` ke `colors.expense`.

**Konsekuensi.** Satu warna memikul tiga makna berbeda: pengeluaran, aksi
destruktif, dan galat. Di aplikasi keuangan, merah-pengeluaran itu normal dan
merah-galat itu alarm — menyatukannya membuat keduanya tidak bisa dibedakan.
Checklist kategori E menyebut pemakaian `expense` untuk tombol hapus netral
sebagai antipola secara eksplisit, dan dokumentasi slot `overBudget` menegaskan
semangat yang sama (satu slot, satu makna).

**Langkah perbaikan.**

1. Ikon hapus: pakai `colors.textMuted` untuk keadaan normal — hapus adalah aksi
   netral sampai dikonfirmasi, dan setelah **UX-01** konfirmasinya yang memikul
   beban peringatan, bukan warna ikonnya. Warna destruktif tetap dipakai pada
   tombol konfirmasi **di dalam** dialog.
2. `ColorScheme.error` → butuh slot sendiri. Dua pilihan, tanyakan ke pemilik
   kalau ragu: (a) tambahkan slot `danger` ke `AppColorsExtension` dan ADR-0006,
   terpisah dari `expense`; atau (b) terima bahwa galat dan pengeluaran berbagi
   warna dan catat alasannya di ADR sebagai keputusan sadar. Jangan dibiarkan
   tanpa catatan.

**Verifikasi.** `grep -rn "appColors.expense\|colors.expense" lib` — setiap sisa
hasilnya harus benar-benar tentang uang keluar atau tombol destruktif di dalam
dialog konfirmasi.

## - [ ] UX-25 🟡 `overBudget` dipakai untuk ikon kunci siklus tertutup

| | |
|---|---|
| **Kat.** | E |
| **Berkas** | `lib/features/cycle/presentation/pages/cycle_page.dart:120` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** `_ClosedBanner` memakai `Icon(Icons.lock, color: colors.overBudget)`.
Siklus tertutup bukan kondisi lewat anggaran.

**Langkah perbaikan.** Ganti ke `colors.textMuted` — sekaligus jadi konsisten
dengan ikon kunci di app bar yang sudah memakainya (`cycle_page.dart:93`).
Perbaikan satu kata, tidak ada risiko.

**Verifikasi.** Kedua ikon kunci (banner dan app bar) berwarna sama.

## - [ ] UX-26 🟡 Dua slot semantik praktis mati

| | |
|---|---|
| **Kat.** | E |
| **Butuh keputusan pemilik** | Tidak lagi — tapi **bergantung teknis pada UX-22**: butuh varian `…OnLight` sudah ada di kode |

**Masalah.**

- **`investment` (`#D99B00`): 0 pemakaian.** Seluruh fitur Investasi — total
  portofolio (`investment_page.dart:98`), saldo tiap pos (`:135`) — dirender
  hijau `income` lewat pewarnaan otomatis `AppMoneyText`. Slot yang ADR-0006
  definisikan khusus untuk "pos tujuan dan alokasi dana investasi" tidak pernah
  dipakai.
- **`rollUp` (`#2D6FE0`): 1 pemakaian**, dan itu hanya sebagai latar snackbar
  `info` (`snackbar_effect_handler.dart:21`) — **tidak pernah** pada baris
  anggaran roll-up yang menjadi alasan slot itu ada.

**Konsekuensi.** Tiga fitur tampil dengan warna yang sama (hijau), jadi warna
berhenti membawa informasi. Untuk `rollUp` akibatnya lebih jauh: baris roll-up
jadi tidak bisa dibedakan sama sekali — lihat **UX-36**, yang menyelesaikan
gejalanya.

**Langkah perbaikan.**

1. `investment`: beri `color` eksplisit pada `AppMoneyText` di
   `_TotalPortfolioCard` dan `_GoalTile` — lihat pola yang sama di **UX-23**.
2. `rollUp`: dipakai sebagai penanda baris roll-up; dikerjakan sebagai bagian
   dari **UX-36**, bukan di sini. Item ini hanya mencatat bahwa slotnya ada dan
   menganggur.
3. Keduanya jadi teks di atas kartu terang, jadi pakai `investmentOnLight` dan
   `rollUpOnLight` — bukan slot aslinya (`investment` hanya 2.43:1 apa adanya).
   Karena itu UX-22 harus selesai lebih dulu.

**Verifikasi.** Setiap slot di `AppColorsExtension` punya ≥1 pemakaian yang
sesuai maknanya, atau dihapus dari ADR-0006 kalau diputuskan tidak diperlukan.

## - [ ] UX-27 🟡 Peran huruf ketiga ADR-0006 tidak pernah terpakai

| | |
|---|---|
| **Kat.** | E |
| **Berkas** | `lib/core/theme/app_theme.dart:17` |
| **Butuh keputusan pemilik** | Ringan — di mana Bangers dipakai adalah pilihan rasa |

**Masalah.** `AppTheme.shout()` (Bangers) punya **0 call site**. Badge/label
bergaya stiker komik — salah satu dari tiga peran huruf yang ADR-0006 tetapkan —
tidak pernah sampai ke layar. `AppChip` yang seharusnya jadi pemakainya
(`app_chip.dart:47`) memakai `labelMedium` (Space Grotesk).

**Konsekuensi.** Gaya komik yang pemilik pilih hadir separuh: panel dan
bayangannya ada, "suara"-nya tidak.

**Langkah perbaikan.** Pakai `AppTheme.shout()` di tempat yang ADR-0006 maksud:
label badge pendek. Kandidat paling jelas — badge `needsReviewBadge` di
`cycle_line_tile.dart:97-101`, badge `subscriptionInactiveBadge`, dan
`overriddenBadge` di belanja. **Jangan** dipakai untuk angka atau teks panjang
(ADR-0006 tegas: angka selalu Archivo Black, body selalu Space Grotesk) — Bangers
sulit dibaca dalam kalimat.

⚠ Kerjakan bersama **UX-28**: `shout()` saat ini juga tidak punya tumpukan
cadangan, padahal komentarnya sendiri mewajibkan.

**Verifikasi.** Minimal satu badge memakai Bangers; tidak ada angka atau body
text yang memakainya.

## - [ ] UX-28 🟡 Tumpukan huruf cadangan yang diwajibkan ADR-0006 tidak ada

| | |
|---|---|
| **Kat.** | E |
| **Berkas** | `lib/core/theme/app_theme.dart:17, 66, 94-108` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** ADR-0006 §Risiko menerima pengambilan huruf saat runtime **dengan
syarat**: "setiap gaya teks wajib mendeklarasikan tumpukan huruf cadangan yang
nyata." Seluruh pemanggilan `GoogleFonts.*` tidak mengisi `fontFamilyFallback`,
dan `pubspec.yaml` tidak membundel font apa pun. Komentar di `app_theme.dart:16`
bahkan menuliskan kewajiban itu tepat di atas kode yang tidak melakukannya.

**Konsekuensi.** Peluncuran pertama tanpa koneksi → seluruh identitas komik
jatuh ke Roboto bawaan, tanpa pemberitahuan. Untuk aplikasi yang seluruh
karakternya ada di tipografi, ini kegagalan yang tidak terlihat sampai terjadi.

**Langkah perbaikan.** Pilih satu:
- **(paling murah)** Isi `fontFamilyFallback` di setiap pemanggilan
  `GoogleFonts.*` dengan tumpukan nyata per peran — untuk Archivo Black dan
  Bangers, pilih keluarga tebal/kondensa yang ada di Android dan iOS; untuk
  Space Grotesk, sans-serif sistem. Ini yang ADR minta secara literal.
- **(paling andal)** Bundel ketiga font sebagai aset di `pubspec.yaml` dan
  berhenti memakai `google_fonts` di jalur tema. Menghapus ketergantungan
  jaringan sama sekali, dengan ongkos ukuran APK. Kalau memilih ini, perbarui
  ADR-0006 §Risiko karena risiko yang diterima di sana jadi tidak berlaku lagi.

**Verifikasi.** Jalankan di perangkat/emulator dalam mode pesawat dengan cache
font dibersihkan: tata letaknya harus tetap masuk akal dan tidak jatuh ke huruf
yang jauh berbeda lebarnya.

## - [ ] UX-29 🟡 Lebar garis tepi — motif inti gaya ini — tidak ditokenkan dan sudah melenceng

| | |
|---|---|
| **Kat.** | E |
| **Berkas** | `app_card.dart:43`, `app_button.dart:41`, `app_theme.dart:58, 78` (2.5) vs `app_chip.dart:43` (2) |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** ADR-0006 menyebut "garis tepi tebal (2.5–3px)" sebagai motif wajib,
tapi nilainya ditulis harfiah di empat tempat dan sudah berbeda di satu tempat
(`AppChip` memakai 2). Tidak ada token untuk itu, padahal `AppSpacing`,
`AppRadius`, `AppElevation`, dan `AppDurations` semuanya ada.

**Konsekuensi.** Justru nilai yang paling mendefinisikan gaya ini yang tidak
ikut berubah kalau token direvisi — dan sudah terbukti melenceng.

**Langkah perbaikan.** Buat `lib/core/theme/tokens/app_border.dart` mengikuti
bentuk token lain (`abstract final class` dengan `static const double`), mis.
`AppBorder.thick = 2.5` dan `AppBorder.thin = 2` kalau memang dua tingkat
disengaja. Ekspor dari `lib/core/theme/theme.dart`. Ganti keempat titik. Putuskan
apakah `AppChip` memang sengaja lebih tipis — kalau tidak, samakan ke `thick`.

**Verifikasi.** `grep -rn "width: 2" lib --include='*.dart' | grep -v tokens/` —
tidak menyisakan lebar garis harfiah.

## - [x] UX-30 🟡 Dua aturan proyek bertabrakan soal bayangan kartu di mode gelap

| | |
|---|---|
| **Kat.** | E |
| **Butuh keputusan pemilik** | Sudah dijawab — ADR-0006 yang berlaku |
| **Status** | **Selesai 11 September 2026.** Dokumen saja, tanpa perubahan kode. |

**Masalah.** `.claude/AGENT_CONTEXT.md:98` mewajibkan kartu mode gelap memakai
batas rambut, bukan bayangan; ADR-0006 §Batasan mewajibkan bayangan keras di
**kedua** mode. Kode mengikuti ADR (`app_card.dart:44`).

**Konsekuensi langsung.** Di mode gelap, `AppElevation.hardShadow(colors.edge)`
memakai `edge` yang bernilai krem `#F2E9D8`, jadi setiap kartu punya halo krem
tegas 4px di atas dasar hitam. Itu mungkin memang yang diinginkan — tapi satu
dari dua dokumen mengikat sedang salah, dan agent berikutnya yang membaca
AGENT_CONTEXT akan "memperbaiki" sesuatu yang sengaja.

**Yang dikerjakan.** Pemilik menetapkan ADR-0006 yang berlaku, jadi
`.claude/AGENT_CONTEXT.md` yang diperbaiki: butir "Di mode gelap, kartu memakai
batas rambut, bukan bayangan" diganti menjadi pernyataan bahwa garis tepi tebal
dan bayangan keras offset berlaku di **kedua** mode, dengan tautan ke ADR-0006.
ADR-0006 §8b mencatat keputusannya. `app_card.dart` tidak disentuh — ia sudah
benar sejak awal.

**Verifikasi.** Kedua dokumen kini menyebut hal yang sama, dan kode
(`app_card.dart:44`) mengikutinya tanpa perubahan. `flutter analyze` 0 issue,
`flutter test` 124 lulus — tidak terpengaruh karena tidak ada kode yang diubah.

---

# Batch 6 — Sentuh dan aksesibilitas

## - [ ] UX-31 🟠 `AppChip` jadi kontrol utama tapi area sentuhnya ±28px

| | |
|---|---|
| **Kat.** | F |
| **Berkas** | `lib/core/presentation/widgets/app_chip.dart:38-44` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** Tinggi efektifnya ≈28px: `labelMedium` (12px) + padding vertikal
`AppSpacing.xs` (4px × 2) + garis tepi (2px × 2). Di bawah ambang ±44px yang
jadi acuan skill `mobile-design`.

Dan ini bukan elemen dekoratif — `AppChip` adalah satu-satunya kontrol untuk:
memilih sumber pemasukan (`line_edit_sheet.dart:276`), memilih sumber nominal
anggaran (`:311-326`), memilih kartu (`:346`), memilih sumber worklog
(`worklog_page.dart:67`), dan menukar jenis potongan
(`income_source_edit_sheet.dart:191`).

**Konsekuensi.** Target kecil yang berdempetan (`Wrap` dengan jarak
`AppSpacing.sm` = 8px) mudah salah ketuk, dan salah ketuk di sini berarti
menautkan baris ke sumber yang salah.

**Langkah perbaikan.** Naikkan area sentuh **tanpa** mengubah tampilan visual:
bungkus isi `AppChip` dengan `ConstrainedBox`/`SizedBox` bertinggi minimum, atau
tambahkan padding transparan di luar `Container` yang bergaris tepi. Jangan
sekadar memperbesar padding dalam — itu mengubah bentuk chip dan ikut mengubah
rasa visual yang pemilik setujui.

Sekalian: ganti `GestureDetector` (`:36`) jadi `InkWell`/`InkResponse` supaya
bisa ikut menerima umpan balik tekan dari **UX-32**.

**Verifikasi.** Ukur area ketuk (mis. lewat `debugPaintPointersEnabled` atau
Flutter DevTools) ≥44px tinggi, sementara chip tetap terlihat sama.

## - [ ] UX-32 🟠 Tidak ada umpan balik ketukan di seluruh aplikasi

| | |
|---|---|
| **Kat.** | F |
| **Berkas** | `lib/core/theme/app_theme.dart:48-49` |
| **Butuh keputusan pemilik** | Ringan — bentuk efek tekannya pilihan rasa |

**Masalah.** `splashFactory: NoSplash.splashFactory` dan
`highlightColor: Colors.transparent` mematikan umpan balik Material secara
global, dan `AppChip` memakai `GestureDetector` polos. Tidak ada penggantinya —
tidak ada animasi tekan, tidak ada pergeseran bayangan keras.

**Konsekuensi.** Setiap ketukan bungkam sampai state berubah. Paling terasa pada
baris yang memang tidak merespons (**UX-36**) dan chip nonaktif (**UX-33**):
pemilik tidak bisa membedakan "ketukanku tidak terdaftar" dari "terdaftar tapi
ditolak".

⚠ Mematikan splash itu **sengaja** — ADR-0006 menolak bahasa visual Material
generik. Jangan sekadar menghidupkan kembali `InkSplash`; itu akan membawa balik
tampilan yang pemilik tolak.

**Langkah perbaikan.** Buat efek tekan yang sesuai motif komik: saat ditekan,
bayangan keras ditarik ke 0 dan panel bergeser sejauh offset-nya ke kanan-bawah —
efek "tombol ditekan" klasik komik. Itu memakai `AppElevation.hardShadow` yang
sudah ada, jadi konsisten dengan bahasa visualnya dan tidak memperkenalkan
kosakata baru.

Terapkan di `AppButton`, `AppCard` yang bisa diketuk, dan `AppChip`. Pakai
`AppDurations` untuk durasinya — jangan angka harfiah.

**Verifikasi.** Setiap elemen yang bisa diketuk memberi tanda saat ditekan, dan
tampilannya masih terbaca sebagai gaya komik, bukan Material.

## - [ ] UX-33 🟠 Chip nonaktif hanya diredupkan, dan penjelasannya sudah ditulis tapi tak pernah muncul

| | |
|---|---|
| **Kat.** | F, G |
| **Berkas** | `lib/features/cycle/presentation/widgets/line_edit_sheet.dart:221-228` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** `_budgetSourceChip` memakai `Opacity(0.4)` + `onTap: null`. Satu
sinyal saja (opasitas), tanpa ikon dan tanpa keterangan. Checklist kategori G
meminta tepat ini: chip nonaktif harus menyebut **kenapa**, bukan sekadar pudar
yang mudah disangka "belum dipilih".

Yang membuat ini lebih tajam: copy-nya **sudah ada dan sudah bagus** —
`cycle.rollUpSourceAlreadyUsed` = "Sumber ini sudah ditautkan ke baris anggaran
lain." Tapi satu-satunya yang memunculkannya adalah penjaga di bloc
(`_effectRollUpSourceAlreadyUsed`, `cycle_effect.dart:24-27`), dan penjaga itu
hanya terpicu kalau UI dilewati — yang tidak mungkin terjadi justru karena
chipnya sudah dinonaktifkan. Kalimat penjelas terbaik di fitur ini tidak akan
pernah dibaca pemilik.

**Langkah perbaikan.** Pilih salah satu:
- **(disarankan)** Biarkan chip tetap bisa diketuk, dan saat diketuk tampilkan
  `rollUpSourceAlreadyUsed` — tapi **jangan** memilihnya. Cara paling ringan:
  `_budgetSourceChip` menerima callback `onDisabledTap` yang memancarkan
  snackbar. Pemilik dapat penjelasan tepat saat mencari penjelasan.
- Atau tambahkan keterangan kecil di bawah deretan chip yang menyebut sumber
  mana yang sudah terpakai.

Tambahkan juga sinyal kedua selain opasitas (ikon gembok kecil atau garis coret),
supaya tidak bergantung warna/kontras saja.

⚠ **Jangan hapus penjaga di bloc.** Ia pertahanan lapis kedua untuk Fix #9, dan
tesnya ada di `cycle_bloc_test.dart`.

**Tes.** Tes bloc Fix #9 harus tetap lulus tanpa disentuh.

**Verifikasi.** Buat dua baris anggaran, tautkan yang pertama ke Rencana Belanja,
lalu buka sheet lagi: chip Rencana Belanja redup, dan mengetuknya menjelaskan
alasannya.

## - [ ] UX-34 🟡 Toggle jenis potongan tampil sebagai badge terisi permanen

| | |
|---|---|
| **Kat.** | F |
| **Berkas** | `lib/features/income/presentation/widgets/income_source_edit_sheet.dart:189-195` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** `AppChip` dengan `selected: true` **selalu**, yang saat diketuk
menukar labelnya sendiri antara "Per mil" dan "Tetap (Rp)". Tampilannya identik
dengan badge status statis, tidak ada petunjuk bahwa ia bisa diketuk, dan pilihan
alternatifnya tidak pernah terlihat.

**Langkah perbaikan.** Tampilkan dua chip (Per mil / Tetap) dengan satu terpilih
— pola yang sudah dipakai untuk pemilih jenis sumber pemasukan **di sheet yang
sama** (`:110-120`). Konsistensi internal jadi gratis.

⚠ Baris ini sempit (`Row` dengan field label + chip + field nilai 72px + ikon
hapus). Dua chip mungkin tidak cukup ruang — pertimbangkan memindahkan pemilih
jenis ke baris sendiri di bawah, atau memakai `SegmentedButton` yang lebih padat.
Periksa di lebar 390px.

**Verifikasi.** Jenis potongan terlihat sebagai pilihan, bukan badge, dan kedua
pilihannya terlihat sekaligus.

## - [ ] UX-35 🟡 `LineEditSheet` tidak punya `SingleChildScrollView`

| | |
|---|---|
| **Kat.** | F |
| **Berkas** | `lib/features/cycle/presentation/widgets/line_edit_sheet.dart:265` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** `Column(mainAxisSize: .min)` langsung, tanpa pembungkus scroll.
`isScrollControlled: true` (`:128`) hanya mengizinkan sheet lebih tinggi dari
setengah layar — ia **tidak** membuat isinya bisa di-scroll.

**Konsekuensi potensial.** Dengan beberapa chip sumber yang membungkus ke 2–3
baris, hint, dua field, dan keyboard terbuka di ponsel pendek, tombol Simpan bisa
terdorong keluar tanpa cara menggapainya — sheet jadi tidak bisa diselesaikan.

⚠ **Belum diverifikasi dengan render sungguhan.** Review ini tidak menjalankan
aplikasi; alasannya: build web berangkat dengan penyimpanan kosong, jadi yang
terender adalah sheet tanpa chip sumber sama sekali — justru bukan kondisi padat
yang memicu masalah ini. Perbaikannya satu baris dan tanpa risiko, jadi kerjakan
terlepas dari verifikasi.

**Langkah perbaikan.** Bungkus `Column` dengan `SingleChildScrollView`, persis
seperti sheet tetangganya yang sudah benar: `income_source_edit_sheet.dart:91`.
Periksa sekalian sheet lain yang belum punya.

**Verifikasi.** Dengan 5+ sumber pemasukan terdaftar dan keyboard terbuka di
perangkat pendek, Simpan tetap terjangkau (boleh dengan scroll).

---

# Batch 7 — Aturan domain (baris roll-up)

## - [ ] UX-36 🟠 Baris roll-up tidak bisa dibedakan sebelum diketuk, dan ketukannya diam saja

| | |
|---|---|
| **Kat.** | G |
| **Berkas** | `lib/features/cycle/presentation/widgets/cycle_line_tile.dart:65`, `:127` |
| **Butuh keputusan pemilik** | Tidak |

**Masalah.** `onTap: isEditable ? onTap : null`. Gerbangnya **benar** secara
teknis — ADR-0008 dipatuhi, sheet tidak terbuka — tapi secara pengalaman ini
kasus terburuk: **tidak ada beda tampilan apa pun** antara baris yang bisa
disunting dan yang tidak. Tidak ada ikon kunci, tidak ada warna `rollUp` (slot
itu memang menganggur, lihat **UX-26**), tidak ada peredupan. Satu-satunya
perbedaan adalah ikon tong sampah yang tidak muncul (`:127`) — perbedaan lewat
ketidakhadiran, yang hanya terlihat kalau dibandingkan berdampingan.

**Konsekuensi.** Pemilik mengetuk baris "Rencana Belanja" untuk mengoreksi
nominalnya, tidak terjadi apa-apa, mengetuk lagi, masih tidak terjadi apa-apa.
Tanpa umpan balik ketukan (**UX-32**) ini tidak bisa dibedakan dari aplikasi yang
menggantung. Dan copy penjelasnya pun sudah ada dan tak terpakai:
`cycle.rollUpNotEditable` = "Baris ini dihitung otomatis, tidak bisa disunting
langsung."

Checklist kategori G menyebut ini persis: pembedaan harus terlihat **sebelum**
pemakai mencoba mengetuk, dan kalau tampilannya identik lalu baru ditolak setelah
tap itu friksi nyata meski secara teknis benar. Di sini bahkan tidak ada
penolakan — hanya kebisuan.

**Langkah perbaikan.**

1. Beri baris roll-up penanda visual: ikon kecil (mis. `Icons.link` atau
   `Icons.calculate`) berwarna `colors.rollUp` — ini sekaligus menghidupkan slot
   yang menganggur di **UX-26**. Letakkan sejajar ikon `Icons.repeat` penanda
   baris tetap (`:78-82`).
   ⚠ `rollUp` hanya 4.71:1 di atas kartu putih; sebagai **ikon** itu lolos ambang
   3:1 untuk objek grafis, tapi kalau juga dipakai sebagai teks, tunggu varian
   `…OnLight` dari **UX-22**.
2. Biarkan ketukannya **memunculkan** `rollUpNotEditable` alih-alih diabaikan:
   teruskan callback terpisah (mis. `onTapWhenNotEditable`) dari `cycle_page.dart`
   yang memancarkan efek itu. Jangan memanggil `onTap` yang sama — itu akan
   membuka sheet sunting, yang justru tidak boleh.
3. ⚠ **Jangan** membuat baris roll-up bisa disunting. ADR-0008 dan aturan
   "Yang TIDAK boleh dilakukan" di `AGENT_CONTEXT.md:123` melarangnya. Item ini
   hanya soal tampilan dan umpan balik.

**Tes.** Kalau efeknya dipancarkan lewat bloc, tambahkan kasus di
`cycle_bloc_test.dart`. Penjaga `_effectRollUpNotEditable` yang sudah ada
(`cycle_bloc.dart` jalur `BudgetLineSaved`) tetap dipertahankan.

**Verifikasi.** Baris roll-up terlihat berbeda dari baris manual tanpa perlu
diketuk, dan mengetuknya menjelaskan kenapa tidak bisa disunting.

## - [ ] UX-37 🟡 Baris roll-up tidak bisa diberi nama sendiri oleh pemilik

| | |
|---|---|
| **Kat.** | G |
| **Berkas** | `lib/features/cycle/presentation/widgets/line_edit_sheet.dart:357`, `:195`, `:206` |
| **Butuh keputusan pemilik** | Ringan — apakah nama memang sengaja dikunci |

**Masalah.** Field nama disembunyikan saat sumbernya bukan manual (`:357`), dan
`_selectBudgetSource`/`_selectCard` memaksa labelnya jadi "Rencana Belanja" atau
nama kartu. Tidak ada petunjuk bahwa nama itu terkunci.

Efek samping sejenis: mengetik nama lalu berpindah ke chip Rencana Belanja akan
**menimpa** teks yang sudah diketik, tanpa peringatan (`:195`). Hal yang sama
terjadi saat memilih sumber pemasukan (`:184`).

**Konsekuensi.** Pemilik yang di spreadsheet memakai nama sendiri ("Belanja
bulanan", "BRI") tidak bisa memakainya — padahal seluruh premis proyek ini adalah
meniru struktur dan istilah spreadsheet pemilik, bukan memperkenalkan yang baru.

**Langkah perbaikan.**

1. Tetap tampilkan field nama untuk baris roll-up, dengan nilai awal terisi
   otomatis (nama kartu / "Rencana belanja") tapi **boleh** diubah. Nominalnya
   yang dihitung otomatis, bukan namanya — ADR-0008 tidak pernah mengunci label.
2. Jangan menimpa teks yang sudah diketik pemilik. Isi otomatis hanya kalau field
   masih kosong atau masih berisi nilai otomatis sebelumnya.
3. Terkait **UX-19**: begitu pemilik bisa menamai sendiri, drift title-case di
   i18n berhenti menular ke data.

**Verifikasi.** Buat baris roll-up, ganti namanya, simpan: nama pilihan pemilik
yang tersimpan, dan nominalnya tetap dihitung dari sumbernya.

---

# Di luar cakupan — dugaan bug, tangani lewat `code-review`

Tiga hal ini ditemukan saat membaca kode tapi **bukan** temuan UX: semuanya
terlihat seperti cacat fungsional. Skill `ux-review` tidak memperbaiki bug, dan
tidak menebak-nebak korektnes. Verifikasi dan tindak lanjuti lewat skill
`code-review`, bukan sebagai bagian dari daftar di atas.

## - [ ] BUG-1 Kemungkinan crash saat pemuatan siklus pertama gagal

`CycleState.initial()` mengisi `cycle.id` dengan `''` (`cycle_state.dart:29`).
Kalau `getCycle` pertama mengembalikan `Left`, bloc memancarkan `isLoading: false`
dengan id masih `''`; gerbang spinner di `cycle_page.dart:29` lolos; lalu
`_AppBarSliver` memanggil `_shiftMonth('')` (`:68-69`) yang menjalankan
`int.parse('')` di `:102` → `FormatException`. Hasilnya layar galat Flutter, bukan
pesan kegagalan. Kemungkinan ikut tertutup oleh **UX-16**, tapi jangan
diasumsikan — verifikasi sendiri.

## - [ ] BUG-2 Sen bisa terpotong saat baris dibuka lalu disimpan tanpa diubah

Field diisi `amount ~/ 100` lalu disimpan `* 100` (`line_edit_sheet.dart:155, 252`,
plus pola sama di sembilan berkas lain). `AppMoneyFormatter` membulatkan setengah
ke atas saat menampilkan (`money_formatter.dart:22`). Jadi nominal dengan sen
bukan nol tampil sebagai Rp X, tapi membuka dan menyimpan barisnya menulis
Rp X−1. Jalur yang menghasilkan sen bukan nol memang ada dan wajar:
`calculate_net_pay.dart:23` (`grossPay * rule.value ~/ 1000`). Bersinggungan
langsung dengan NFR-ACC-001 dan nilai "sampai rupiah terakhir".

## - [ ] BUG-3 Kegagalan baca template bisa menghapus seluruh baris template

`cycle_bloc.dart:261, 273` memakai `getOrElse((_) => .empty())`, lalu template
baru dibangun dari basis kosong itu dan ditulis kembali (`:266`, `:278`). Kalau
pembacaan gagal, penulisan berikutnya menyapu semua baris tetap yang lain.
Berbeda dari **UX-06**, yang hanya soal pemilik tidak diberi tahu saat penulisan
gagal.

---

## Catatan pengerjaan

Bagian ini diisi saat item dikerjakan — satu entri per ronde, mengikuti
kebiasaan [TASK_LIST.md](TASK_LIST.md) dan
[UI_UX_DESIGN_TASKS.md](UI_UX_DESIGN_TASKS.md): apa yang dikerjakan, apa yang
diputuskan pemilik, apa yang sengaja ditunda, dan hasil verifikasinya
(`flutter analyze`, `flutter test`, rekonsiliasi seed kalau menyentuh angka).

**11 September 2026 (dokumen dibuat)** — Review `ux-review` dijalankan terhadap
commit `8891451`. 37 temuan dicatat jadi item UX-01…UX-37, plus 3 dugaan bug.
Belum ada yang dikerjakan. Cek regresi Fix #1–#9 dilakukan sebagai bagian review:
kesembilan masih utuh, tidak ada regresi. Dua item menunggu keputusan pemilik
(palet mode terang, dan konflik aturan bayangan mode gelap).

**11 September 2026 (kedua keputusan pemilik dijawab — dokumentasi saja)** —
Pemilik memilih **opsi A** untuk palet mode terang, dan menetapkan **ADR-0006
yang berlaku** untuk aturan bayangan mode gelap. Ronde ini sengaja dibatasi ke
dokumen; tidak ada satu baris kode yang diubah.

- **ADR-0006** ditambahi bagian "Varian `…OnLight`" berisi tabel hex final
  keenam varian beserta rasio kontras terukurnya, aturan pemakaian satu kalimat
  (isian memakai slot asli, teks/ikon memakai varian), dan alasan kenapa tidak
  ada varian `…OnDark`. Bagian "8b. Catatan revisi" baru mencatat kedua
  keputusan, menegaskan bahwa ini koreksi keterbacaan dan bukan perubahan arah
  rasa, serta menandai bahwa tabelnya mendahului kode (preferensi pemilik
  "dokumentasi lebih dulu, kode menyusul"). Kriteria peninjauan ulang di bagian
  8 yang menyebut kegagalan kontras ditandai sudah terpicu dan ditindak,
  supaya tidak dibaca sebagai kriteria yang masih menganggur.
- **`.claude/AGENT_CONTEXT.md`** butir "Di mode gelap, kartu memakai batas
  rambut, bukan bayangan" diganti menjadi pernyataan bahwa garis tepi tebal dan
  bayangan keras offset berlaku di kedua mode, dengan tautan ke ADR-0006. Ini
  menutup **UX-30**, satu-satunya item yang pekerjaannya murni dokumen.
- **UX_REVIEW_FIXES.md** (dokumen ini): kunci ⛔ pada UX-22 dan UX-26 dilepas,
  langkah 1 UX-22 ditandai selesai, UX-30 dicentang, dan bagian keputusan
  ditulis ulang dari "ditunggu" menjadi "sudah dijawab" lengkap dengan tabel
  sisa pekerjaan.
- **UI_UX_DESIGN_TASKS.md** diberi catatan bahwa klaim "catatan kontras sudah
  closed" di entri 11 September sebelumnya hanya benar separuh.

Verifikasi: `flutter analyze` 0 issue dan `flutter test` 124 lulus (sama dengan
baseline — wajar, tidak ada kode yang disentuh). Seluruh tautan relatif di
dokumen yang disunting dicek resolve. **Sisa UX-22 adalah pekerjaan kode** dan
belum dikerjakan, jadi kotaknya tetap kosong.
