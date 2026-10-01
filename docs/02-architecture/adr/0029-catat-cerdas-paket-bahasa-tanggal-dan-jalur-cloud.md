# Catat Cerdas per bahasa: paket bahasa, tanggal pasti, jalur langsung ke cloud

## 1. Metadata

- **Decision ID:** ADR-029
- **Tanggal:** 2026-09-30
- **Fase roadmap:** Fase 11 (Catat Cerdas), T-11.11 s.d. T-11.13
- **Status:** Accepted
- **Cakupan:** `features/record` (`domain/capture/`, `data/capture/`,
  `presentation/capture/`), `lib/core/utils/formatters/`
  (`spoken_amount_parser.dart`, `number_lexicon.dart`,
  `spoken_date_parser.dart`), `lib/core/currency/app_currency.dart`
- **Mengubah:** ADR-027 §3.2 (kontrak interpreter: tanggal), §3.3 (resolver
  tanpa kosakata bahasa), §3.5 butir 3 (kaskade)
- **Bergantung pada:** ADR-025 (mata uang), ADR-027, ADR-028 (bahasa
  aplikasi = bahasa ucapan)

## 2. Konteks

Tinjauan pemilik 30 Sep 2026 atas cara `RecordDraft` diisi dari suara
menemukan tiga masalah:

1. **Kosakata Indonesia tertanam di kode.** Kata jenis transaksi, preposisi
   dompet, kata pengisi, "kemarin", dan bilangan kata ada sebagai konstanta
   di `RuleBasedTransactionInterpreter`, `CaptureDraftResolver`, dan
   `SpokenAmountParser`. Menambah bahasa berarti menyunting ketiganya.
   Bahasa Inggris (bahasa aplikasi kedua, ADR-028) selama ini ditafsirkan
   dengan aturan Indonesia.
2. **Tanggal pasti tidak dikenali.** "beli kopi 5000 tanggal 27 september"
   jatuh ke hari ini, dan "27" malah dianggap calon nominal kedua.
3. **Bahasa tanpa aturan tidak punya jalan.** Kaskade ADR-027 §3.5 selalu
   memakai aturan lebih dulu; bahasa yang aturannya tidak ada harus langsung
   ke Firebase AI.

Temuan tambahan dari contoh yang sama: "5000" tanpa "ribu"/"Rp" ditolak
sebagai `amountWithoutUnit`. Pemilik (30 Sep 2026): untuk IDR, angka polos
seperti 1000, 2000, 9000 langsung masuk formulir sebagai nominal sah.

## 3. Keputusan

### 3.1 Paket bahasa

Satu `CaptureLanguage` per bahasa (`domain/capture/language/`) memuat
seluruh kosakata yang sebelumnya tertanam:

| Bagian | Isi |
|---|---|
| `numbers` (`NumberLexicon`, core) | Bilangan kata, skala, akhiran digit ("35rb", "25k"), slang, kata "koma"/"point", pemisah ribuan |
| `dates` (`DateLexicon`, core) | Kata relatif (hari ini, kemarin, …), "N hari lalu", nama bulan, penanda tanggal ("tanggal", "tgl", "on the"), akhiran urutan ("27th"), urutan tanggal angka (H/B atau B/H) |
| Kata jenis | Transfer, pemasukan kuat, pemasukan lemah, tanda pengeluaran |
| Preposisi dompet | Asal, tujuan, dan "pakai/via" |
| `cashWords` | Sinonim dompet tunai, dipakai resolver saat mencocokkan dompet |
| `fillerWords` | Kata yang dibuang dari catatan |

Registri `CaptureLanguages` memetakan kode bahasa aplikasi ke paketnya. Isi
awal: **`id` dan `en`**. Paket `en` sengaja dibuat sekarang: satu
implementasi belum membuktikan abstraksinya bisa ditambah.

`RuleBasedTransactionInterpreter` menerima satu paket dan tidak lagi punya
kata sendiri. `SpokenAmountParser` dan `SpokenDateParser` generik;
algoritmanya membaca peran kata dari leksikon. Menambah bahasa = menulis satu
paket dan mendaftarkannya, tanpa menyentuh parser, interpreter, atau
resolver.

Pemisah ribuan mengikuti bahasa (ADR-028 §7): "35.000" pasti ribuan dalam
`id` tetapi ragu dalam `en`, "5,000" sebaliknya.

### 3.2 Tanggal pasti, ditafsirkan paket bahasa

`InterpretedTransaction` mendapat field `date` di samping kutipan
`dateText`. Interpreter aturan mengisinya lewat `SpokenDateParser` dengan
`DateLexicon` bahasanya; penyedia cloud (T-11.7) mengisinya dari keluaran
model. Resolver **tidak lagi mengenal kata tanggal apa pun** dan hanya
memeriksa:

- `dateText` benar-benar ada di teks bukti (pagar karangan, sama seperti
  nominal);
- `date` tidak sesudah hari tangkap dan tidak sebelum tahun 2000 (batas
  pemilih tanggal CATAT).

- bila bahasa bukti punya paket dan `SpokenDateParser` mengenali
  kutipannya, tafsiran paket sama dengan `date` (verifikasi M3, H2, 30 Sep
  2026: "kemarin" tidak boleh menjadi 1 Sep). Kutipan yang tidak dikenali
  paket tetap dipercaya ke model. Resolver tetap tanpa kata tanggal: kata
  datang dari `DateLexicon` paket.

Gagal salah satu → `DraftIssue.dateUnclear` dan tanggal bawaan. Tanpa
`dateText`, `date` diabaikan.

Pagar nominal juga diperketat di verifikasi M3 (H1): kutipan nominal selain
harus substring teks bukti, nilainya harus sama dengan frasa bilangan utuh
(`SpokenAmountParser.findAll`) yang ditumpanginya, sehingga kutipan yang
memotong angka ("350" dari "350 ribu", "5 juta" dari "1,5 juta") menjadi
`amountMissing`.

Pola yang dikenali:

| Pola | `id` | `en` |
|---|---|---|
| Relatif | hari ini, kemarin, kemarin lusa, "N hari (yang) lalu" | today, yesterday, (the) day before yesterday, "N days ago" |
| Hari + bulan (+ tahun) | "(tanggal) 27 september (2026)", "27 sept" | "September 27(th)(, 2026)", "(the) 27th (of) September" |
| Hari saja | "tanggal 27", "tgl 5" (penanda wajib) | "on the 27th", "the 5th" (penanda + akhiran urutan wajib) |
| Angka | 27/9, 27-9-2026 (H/B/T) | 9/27, 9/27/2026 (B/H/T) |

Tanpa tahun (keputusan pemilik): **tanggal terdekat yang sudah lewat**.
Diucapkan 30 Sep 2026: "27 september" → 27 Sep 2026, "5 oktober" → 5 Okt
2025, "tanggal 31" → 31 Agu 2026. Tahun disebut tetapi tanggalnya di masa
depan atau tidak ada (31 Feb) → `dateUnclear`.

Tanggal mengambil jam dari waktu tangkap, sama seperti "kemarin" sebelumnya.
Rentang teks tanggal dikeluarkan dari pencarian nominal, dompet, kategori,
dan catatan, jadi "27" tidak pernah menjadi nominal.

### 3.3 Angka polos per mata uang

`AppCurrency.plainAmountMinUnits` adalah batas bawah (satuan utama) agar
angka tanpa satuan diterima sebagai nominal. **IDR = 100**. Contoh:

- "parkir 2000" → Rp2.000
- "beli 2 kopi 5000" → Rp5.000 ("2" di bawah batas, jadi jumlah barang)
- "parkir 5" → tetap `amountWithoutUnit`

Mata uang lain `null`: angka polos tetap disorot, karena "coffee 5" lebih
sering berarti jumlah barang. Nominal bersatuan selalu menang atas angka
polos; dua angka polos di atas batas → `amountMultiple`.

### 3.4 Penyusun draf: aturan, cloud, atau keduanya

`CaptureDraftComposer` (domain) menggantikan `CascadingTransactionInterpreter`
di ADR-027 §3.5 butir 3. Kaskade butuh penilaian yakin/tidak
(`RecordDraft.isConfident`), dan penilaian itu hanya ada sesudah resolver,
jadi urutannya diatur di atas interpreter, bukan di dalamnya.

`CaptureEvidence` membawa `languageCode` (bahasa aplikasi = bahasa ucapan,
ADR-028). Alurnya:

1. **Ada paket bahasa:** aturan dulu. Draf yakin → selesai.
2. **Tidak yakin, atau tidak ada paket:** cloud, bila terpasang, dengan batas
   waktu ±5 dtk. Jawaban sah → draf cloud.
3. **Cloud tidak ada, galat, atau lewat batas waktu:** draf aturan apa
   adanya. Tanpa paket bahasa, hasilnya draf kosong: formulir terbuka dengan
   transkrip terlihat dan nominal disorot. Tidak ada pesan galat (ADR-027
   §3.5 butir 7).

Sampai T-11.7 slot cloud kosong (`null`). T-11.7 cukup mendaftarkan
`FirebaseAiTransactionInterpreter` di slot itu.

Resolver memakai `NumberLexicon` dan `cashWords` dari paket bahasa. Untuk
bahasa tanpa paket, resolver memakai `NumberLexicon.neutral`: hanya digit,
dan simbol serta kode mata uang. Pengenal ucapan umumnya menulis nominal
sebagai digit, jadi kutipan cloud tetap bisa dihitung Dart.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Tambah `if (bahasa == 'en')` di interpreter yang ada**
- **Opsi B — Satu interpreter aturan per bahasa, masing-masing lengkap**
- **Opsi C — Paket bahasa (data) + parser generik + penyusun draf (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A
Paling cepat, tetapi setiap bahasa baru menambah cabang di tiga berkas, dan
resolver tetap tahu kata Indonesia.

### Opsi B
Bahasa terisolasi, tetapi logika pemilihan nominal, dompet, dan catatan
tergandakan per bahasa dan pasti menyimpang.

### Opsi C (Dipilih)
Logika ditulis sekali; bahasa hanya data. Kelemahan: tata bahasa bilangan
dan tanggal harus muat dalam peran yang disediakan leksikon. Bahasa yang
tidak muat (mis. bilangan Jepang) tetap bisa lewat jalur cloud.

## 6. Konsekuensi

### Yang menjadi lebih mudah
- Menambah bahasa aplikasi tidak memblokir Catat Cerdas: tanpa paket, suara
  langsung ke cloud.
- Keluaran tanggal cloud divalidasi dengan pagar yang sama dengan nominal.

### Yang menjadi lebih sulit
- Uji benchmark perlu dijalankan per paket bahasa.

### Risiko yang diterima
- Batas angka polos IDR 100 bisa salah membaca "beli 100 lembar" sebagai
  Rp100 bila tidak ada nominal bersatuan lain. Pengguna tetap meninjau di
  formulir.

## 7. Catatan implementasi

- Jangan menaruh kata bahasa apa pun di resolver, parser, atau interpreter.
  Tempatnya di paket bahasa.
- Kutipan tanggal tetap wajib ada di teks bukti. Jangan menerima `date` dari
  model tanpa `dateText`.
- Rentang tanggal harus dikeluarkan dari pencarian nominal **sebelum**
  memilih nominal.

## 8. Kriteria peninjauan ulang

- Bahasa ketiga tidak muat dalam peran `NumberLexicon`/`DateLexicon`.
- Benchmark T-11.9 menunjukkan batas angka polos IDR terlalu rendah atau
  terlalu tinggi.

## 9. Artefak terkait

### Dokumentasi
- ADR-025, ADR-027, ADR-028; TASK_LIST T-11.11 s.d. T-11.13

### Rujukan kode
- `lib/shared/capture/domain/language/` (dipindah dari `features/record`,
  ADR-033)
- `lib/shared/capture/domain/capture_draft_composer.dart`
- `lib/core/utils/formatters/number_lexicon.dart`,
  `spoken_amount_parser.dart`, `spoken_date_parser.dart`

---

**Penulis keputusan:** Claude (agen), atas keputusan pemilik
**Ditinjau oleh:** pemilik
**Tanggal disetujui:** 2026-09-30
**Status implementasi:** selesai 30 Sep 2026 (T-11.11 s.d. T-11.13); slot cloud diisi di T-11.7
