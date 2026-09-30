# Batas antarfitur: akar komposisi, rute bertipe, sinyal buku besar, dan presentasi di shared

## 1. Metadata

- **Decision ID:** ADR-030
- **Tanggal:** 2026-09-30
- **Fase roadmap:** Fase 12 (rapikan batas arsitektur), T-12.1 s.d. T-12.6
- **Status:** Accepted
- **Cakupan:** Global — `lib/app/` (baru), `lib/core/`, `lib/shared/`, seluruh
  `lib/features/*/presentation/`
- **Mengubah:** ADR-0009 §3 (`shared/<module>/presentation/` diizinkan,
  akar komposisi keluar dari `core/`)
- **Menegakkan ulang:** ADR-0004 (kunci rute per fitur), ditambah lembar
  modal sebagai rute dan helper push bertipe
- **Bergantung pada:** ADR-0003, ADR-0004, ADR-0005, ADR-0009, ADR-012

## 2. Konteks

Review arsitektur 30 Sep 2026 (sesudah T-11.15) memeriksa graf impor 285
berkas `lib/` (33.726 baris tanpa `.g.dart`). Lapisan **di dalam** tiap modul
sehat: `domain/` tidak mengimpor Flutter, paket infrastruktur, `data/`, atau
`presentation/`; `presentation/` tidak mengimpor `data/`; paket Firebase,
suara, dan penyimpanan hanya dipakai di `data/`, `di/`, atau `core/`; semua
repository memakai `RepositoryGuard`; uang tetap `int`; fitur mengimpor
`shared/` hanya lewat barrel.

Batas **antar** modul tidak mengikuti dokumen:

| # | Temuan | Bukti |
|---|---|---|
| A1 | Navigasi bertipe ADR-0004 tidak dipakai sejak pivot 2.0: nol `RouteNode`/`RouteKey`, nol `*_route_keys.dart`. Layar dibuka lewat `Navigator.push(MaterialPageRoute)` di 9 tempat, sehingga ada 40 impor langsung antarfitur ke page, bloc, dan widget — sebagian melingkar (budget ↔ transaction, record → freelance → record). | `RootModule._featureModules` kosong |
| A2 | Data antarfitur disinkronkan manual: sesudah CATAT, `AppShellPage` memuat ulang 4 bloc; halaman rincian meminjam bloc fitur lain lewat `BlocProvider.value`, yang hanya berfungsi karena shell menyarangkan 5 scope. | `app_shell_page.dart:109-119`, `openWalletDetail`, `openBudgetDetail`, `openTransactionDetail` |
| A3 | `core/` bergantung pada semua fitur: `root_module.dart` mengimpor adapter `data/` fitur, `app_shell_page.dart` mengimpor page/bloc/scope enam fitur. | ADR-0009 §3: `core/` tanpa makna bisnis |
| A4 | Port baca `BudgetItemCatalog` milik `record` dipakai juga oleh `transaction` (scope, bloc, state, rincian). | `features/record/domain/budget_item_catalog.dart` |
| A5 | Widget yang dipakai beberapa fitur tinggal di satu fitur: bidang formulir `budget_form_fields.dart` (5 berkas freelance), `wallet_select_field` (freelance), `account_avatar` dan `transaction_date_group_card` (home, budget, wallet). | graf impor |
| A6 | Penyaring, pencarian, pengelompokan per tanggal, dan jumlah bersih transaksi ditulis sebagai metode privat `TransactionBloc` (439 baris), tidak teruji sebagai fungsi murni. | `transaction_bloc.dart:325-439` |
| A7 | `shared/category/presentation/` melanggar "`shared` tanpa `presentation/`" tanpa pengecualian tercatat. | ADR-0009 §3 |
| A8 | Parser ucapan (kosakata uang dan tanggal) di `core/utils/formatters/`, padahal hanya dipakai `record`. | `spoken_amount_parser.dart`, `spoken_date_parser.dart`, `number_lexicon.dart` |
| A9 | Berkas presentasi besar: `home_cards.dart` 913 baris, `freelance_project_page.dart` 788, `transaction_detail_page.dart` 770, `wallet_detail_page.dart` 597. | |
| A10 | Pelanggaran kecil: `Icons.` di `app.dart`, warna harfiah di `spotlight_overlay.dart`, fake tulis tangan di 10 berkas uji (ADR-0010). | |
| A11 | ARCHITECTURE_OVERVIEW basi: menyebut `core/storage/`, `app_injectable.dart`, `*_route_keys.dart` yang tidak ada; tidak menyebut `shared/category`, `record/data/capture`, `core/language`. | |

Akibatnya, menambah fitur berarti menyunting shell (sarang scope dan
pemuatan ulang), `RootModule`, dan mengimpor page fitur lain; keterikatan
tumbuh setiap fitur bertambah. Pemilik memutuskan 30 Sep 2026: **A1 memakai
kunci rute** (ADR-0004 ditegakkan, bukan direvisi), dan **A7 diizinkan**.

## 3. Keputusan

### 3.1 Akar komposisi pindah ke `lib/app/`

`RootModule`, `di.dart`, `SaldoughApp`, dan `AppShellPage` pindah ke
`lib/app/`. Hanya `lib/app/` (dan `main.dart`) yang boleh melihat semua fitur.
**`core/` tidak mengimpor `shared/` maupun `features/`.** Infrastruktur rute
tanpa impor fitur (`AppRouteRegistry`, `RouteNodeGoRouterExt`, penangan efek
navigasi) tetap di `core/foundation/navigation/`; daftar `FeatureRouteModule`
disusun di `lib/app/`.

### 3.2 `shared/<module>/presentation/` diizinkan

Berisi widget dan helper tampilan untuk **entitas modul itu** yang dipakai ≥2
fitur (mis. nama kategori, baris transaksi, pemilih dompet, avatar akun),
diekspor lewat barrel kedua `<module>_presentation.dart`, bukan barrel
utama, supaya `domain/` yang mengimpor barrel utama tidak ikut menarik
Flutter. Tetap **tanpa** bloc, page, scope, dan rute — itu milik fitur. Widget tanpa entitas (bidang formulir, kartu) tetap di
`core/presentation/widgets/`.

### 3.3 Navigasi antarfitur lewat kunci rute (ADR-0004 ditegakkan)

1. Setiap **layar penuh** didaftarkan sebagai `RouteNode` di
   `features/<fitur>/presentation/navigation/<fitur>_route_module.dart`,
   kuncinya di `<fitur>_route_keys.dart` (`RouteKey<TInput>` + `RouteInput`).
   Fitur lain hanya boleh mengimpor berkas kunci. `Navigator.push` dengan
   `MaterialPageRoute` untuk layar fitur tidak dipakai lagi, termasuk di dalam
   satu fitur, supaya aturannya satu dan bisa dicek mesin.
2. Pembangun `RouteNode` memasang dependensinya sendiri: `ScopeProvider.of(context)`
   (kontainer akar) → `ScopeWidget` fiturnya → `BlocProvider.value` →
   `EffectListener`, dibungkus `PixelTheme`. **Tidak ada lagi bloc yang
   dipinjam dari rute pemanggil**; tiap rute punya instans blocnya sendiri,
   dan §3.4 yang menjaga semuanya segar.
3. Membuka rute:
   - dari logika bloc: `NavigatePushEffect(keyId: XRouteKeys.y.id, input: …)`
     (ADR-0004 §7);
   - dari ketukan widget tanpa logika: helper bertipe
     `context.pushRoute(XRouteKeys.y, input)` di `core/foundation/navigation/`,
     yang memaksa pasangan kunci–input cocok saat kompilasi dan
     mengembalikan `Future` hasil rute.
4. **Lembar modal yang dibuka lintas fitur juga rute.** Di Saldough,
   `RouteTransition.slideFromBottom` dirender `RouteNodeGoRouterExt` sebagai
   `ModalBottomSheetRoute` (layar penuh, sudut atas `AppRadius.sm`, sama
   dengan `showFullScreenSheet`), jadi CATAT dan sunting transaksi tetap
   tampil sebagai lembar. Lembar formulir yang hanya dibuka di dalam satu
   fitur tetap `showFullScreenSheet`.
5. Kunci berformat `<fitur>.<layar>`. Input membawa id atau entitas yang
   sudah dimuat; tautan dalam belum dibutuhkan, jadi `defaultInput` hanya
   didaftarkan untuk rute tanpa argumen.

### 3.4 Sinkronisasi antarfitur: sinyal buku besar

1. `LedgerChanges` (`shared/transaction/domain/`, Dart murni): `Stream<void>
   changes` dan `notifyChanged()`. Satu instans di akar, dijembatani ke scope
   yang membutuhkannya.
2. Dipancarkan **sekali per unit kerja, sesudah semua dokumennya tertulis** —
   bukan per penulisan repository. Transaksi ditulis lebih dulu dan saldo
   dompet menyusul (ADR-012); memancarkan di antaranya membuat pelanggan
   memuat saldo lama. Titik pancar: `RecordTransaction.call` dan
   `RecordTransaction.delete` (CATAT, sunting/hapus/urungkan, pembayaran
   freelance diterima), dan `WalletBloc` sesudah tambah/sunting/hapus dompet
   berhasil (satu-satunya penulis yang mengorkestrasi unit kerjanya sendiri).
3. Pelanggan: bloc yang menampilkan saldo atau transaksi (`TransactionBloc`,
   `WalletBloc`, `BudgetBloc`, `HomeBloc`, termasuk instans milik rute
   rincian). Berlangganan di konstruktor, batal di `close`, dan memuat ulang
   **tanpa** keadaan memuat (setara `*Refreshed`). Penulis boleh tetap memuat
   ulang dirinya sesudah menulis; muatan ganda murah dan `Bloc` tidak
   memancarkan state yang sama dua kali.
4. Data lain tidak memakai sinyal: kategori sudah lewat `ActiveCategories`;
   anggaran dan freelance disegarkan saat kembali dari rute (`await
   pushRoute(…)` lalu `*Refreshed` bloc fitur sendiri) dan saat tab dipilih
   (shell). Sinyal kedua baru ditambahkan kalau muncul penulis lintas fitur
   untuk data itu.
5. Shell tidak lagi memuat ulang bloc fitur lain sesudah CATAT.

### 3.5 Port dan widget lintas fitur

- Port **baca** yang dipakai ≥2 fitur pindah ke `shared/`:
  `BudgetItemCatalog` + `BudgetItemOption` → `shared/budget_catalog/`;
  implementasinya tetap di `features/budget/data/adapters/`. Port **tulis**
  tetap milik fitur konsumen (ADR-0009).
- Bidang formulir generik `budget_form_fields.dart` → `core/presentation/widgets/`
  dengan nama `AppForm*`. `wallet_select_field` → `shared/wallet/presentation/`,
  `transaction_date_group_card` → `shared/transaction/presentation/`,
  `account_avatar` → `shared/auth/presentation/` (§3.2). Dua yang terakhir
  menunggu tahapnya: kartu grup tanggal bergantung pada pengelompokan yang
  baru menjadi domain di §3.6 (tahap 2), dan avatar membuka layar Akun,
  jadi butuh kunci rute (tahap 4).

### 3.6 Logika query keluar dari bloc

Penyaring, pencarian, pengelompokan per tanggal, dan jumlah bersih transaksi
menjadi fungsi murni di `shared/transaction/domain/` dengan uji unit;
`TransactionBloc` hanya mengorkestrasi.

### 3.7 Letak lain

- `spoken_amount_parser.dart`, `spoken_date_parser.dart`, dan
  `number_lexicon.dart` pindah ke `features/record/domain/capture/`.
  `money_formatter`/`money_input` tetap di `core/`.
- Ketergantungan timbal balik `shared/wallet` ↔ `shared/transaction`
  diterima: keduanya satu konteks buku besar (saldo adalah cache transaksi,
  ADR-012). Impor di antara keduanya tetap lewat barrel.

### 3.8 Aturan dijaga uji

Batas di atas dicek `test/architecture/import_boundaries_test.dart`, yang
membaca impor `lib/`: `core/` tidak mengimpor `shared/`/`features/`; fitur
hanya mengimpor fitur lain lewat `*_route_keys.dart`; `shared/` saling impor
lewat barrel; `domain/` tanpa Flutter dan tanpa `data/`/`presentation/`;
`presentation/` tanpa `data/`; tidak ada `MaterialPageRoute` di `features/`.

## 4. Opsi yang dipertimbangkan

**Navigasi (A1)**

- **Opsi A — revisi ADR-0004, navigasi imperatif sah.** Paling murah, tetapi
  impor page antarfitur tetap tanpa batas.
- **Opsi B — satu berkas *entry* per fitur** (`openWalletDetail(...)`).
  Batasnya sama dengan biaya lebih kecil, tetapi tetap menarik pohon widget
  fitur lain dan tidak memakai registri yang sudah ada.
- **Opsi C — kunci rute ADR-0004 (Dipilih pemilik).** Argumen bertipe,
  menu pengembang terisi, fitur tidak saling menarik widget.

**Sinkronisasi (A2)**

- **Opsi A — fan-out di shell (status quo).** Setiap penulis dan fitur baru
  harus ingat menyunting shell.
- **Opsi B — aliran perubahan per repository.** Memancar di antara penulisan
  transaksi dan saldo, jadi pelanggan melihat saldo lama.
- **Opsi C — sinyal per unit kerja (Dipilih).**

**Presentasi di shared (A7)**

- **Opsi A — pindahkan ke `core/` atau ke satu fitur.** `core/` tidak boleh
  mengenal entitas; menaruhnya di satu fitur mengulang A5.
- **Opsi B — izinkan untuk tampilan entitas modul (Dipilih pemilik).**

## 5. Analisis konsekuensi

Opsi C navigasi paling mahal: 9 titik `Navigator.push`, 40 impor antarfitur,
dan uji widget yang memasang page dengan `BlocProvider.value` harus diubah.
Biaya itu turun banyak kalau sinyal buku besar (§3.4) sudah ada, karena
halaman rincian tidak lagi butuh bloc fitur lain. Karena itu urutannya
sinkronisasi lebih dulu, navigasi sesudahnya.

Tiap rute memiliki instans blocnya sendiri, jadi data yang sama bisa dimuat
dua kali (tab dan rincian). Muatan itu dokumen per bulan dari Hive, murah
dibanding keterikatan yang dihapus.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Menambah fitur: satu modul rute, satu baris di daftar modul, tanpa
  menyunting shell.
- Layar bisa dibuka dari mana saja (tab, rincian, menu pengembang) karena
  tidak bergantung pada bloc yang disediakan pemanggil.
- Batas bisa dicek mesin lewat uji impor.

### Yang menjadi lebih sulit

- Satu lapisan (kunci + modul rute) untuk setiap layar.
- Bloc pelanggan harus mengelola langganan (`close`).

### Risiko yang diterima

- `keyId` di efek navigasi tetap `String` (ADR-0004 §6); ditangani dengan
  selalu memakai `XRouteKeys.y.id` dan helper `pushRoute` untuk ketukan.
- Penulis baru buku besar yang tidak lewat `RecordTransaction` wajib memanggil
  `notifyChanged()`; lupa berarti layar lain basi sampai tab dipilih ulang.

## 7. Catatan implementasi

Urutan dan satu commit per tahap (T-12.1 s.d. T-12.6 di TASK_LIST):

1. Tahap 0 — dokumen ini dan tugasnya.
2. Tahap 1 — pindah berkas tanpa ubah perilaku (§3.1, §3.5, §3.7, A10 kecil).
3. Tahap 2 — logika query transaksi jadi fungsi murni (§3.6).
4. Tahap 3 — `LedgerChanges` (§3.4).
5. Tahap 4 — kunci dan modul rute (§3.3), sekaligus memecah halaman besar
   yang tersentuh (A9).
6. Tahap 5 — fake tulis tangan → `mocktail` (A10), uji batas impor (§3.8),
   sapuan dokumen (A11).

### Batasan yang harus dijaga

- Ambil `ScopeProvider.of(context)` **sebelum** `ScopeWidget` disisipkan
  (ADR-0004 §7).
- Pancarkan `notifyChanged()` hanya sesudah unit kerja `Right`.
- Stub repository di uji bloc harus mencerminkan penulisan terakhir
  (AGENT_CONTEXT, jebakan 3); sinyal membuat pemuatan ulang lebih sering.

### Antipola yang harus dihindari

- Meneruskan bloc antarrute lewat `BlocProvider.value`.
- Memanggil `*Refreshed` bloc fitur lain dari shell atau page.
- Memancarkan sinyal dari repository.

## 8. Kriteria peninjauan ulang

- Tautan dalam dari luar aplikasi dibutuhkan (semua rute butuh
  `defaultInput` atau id di jalur).
- Anggaran atau freelance mendapat penulis lintas fitur (butuh sinyal kedua).
- Pemuatan ulang karena sinyal terasa lambat pada riwayat panjang (B-11).

## 9. Artefak terkait

### Dokumentasi

- [ADR-0004](0004-typed-route-registry-navigation.md),
  [ADR-0009](0009-core-shared-features-zone-layout.md),
  [ADR-012](0012-tata-letak-penyimpanan-buku-besar.md)
- [ARCHITECTURE_OVERVIEW.md](../ARCHITECTURE_OVERVIEW.md) (disapu di tahap 5)
- [TASK_LIST.md](../../04-planning/TASK_LIST.md) Fase 12

### Rujukan kode

- `lib/core/foundation/navigation/`
- `lib/shared/transaction/domain/usecases/record_transaction.dart`

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek (keputusan A1 dan A7, 30 Sep 2026)
**Tanggal disetujui:** 2026-09-30
**Status implementasi:** Direncanakan — Fase 12
