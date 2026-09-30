# Rencana Verifikasi Mendalam — Fase 11 (Catat Cerdas)

**Dibuat:** 30 September 2026 · **Branch:** `claude/kategori-dan-suara`
**Rujukan:** [ADR-026](../02-architecture/adr/0026-sistem-kategori.md),
[ADR-027](../02-architecture/adr/0027-catat-cerdas-interpreter-yang-bisa-diganti.md),
[VOICE_INPUT_RESEARCH.md](VOICE_INPUT_RESEARCH.md), TASK_LIST Fase 11.

Verifikasi dilakukan **per milestone**, bukan per task dan bukan di akhir:
per task terlalu mahal dan temuannya sering berubah lagi, di akhir diffnya
terlalu besar dan kesalahan fondasi terlambat ketahuan. Uji otomatis dan
`flutter analyze` tetap menjadi pagar di setiap task.

Setiap milestone ditinjau **hanya terhadap rentang commit-nya** supaya hasil
tidak tercampur pekerjaan yang belum selesai.

---

## Cara memakai dokumen ini

1. Checkout commit akhir milestone (kolom "Rentang commit").
2. Jalankan pemeriksaan otomatis (bagian "Perintah").
3. Tinjau kode dengan fokus di "Risiko utama" dan "Daftar periksa kode".
4. Lakukan "Daftar periksa perangkat".
5. Catat hasil di bagian "Hasil" milestone itu: lulus / temuan (dengan
   berkas:baris) / keputusan. Temuan yang dikerjakan belakangan masuk
   Antrean TASK_LIST sebagai `B-n`.

Perintah umum (semua milestone):

```bash
flutter analyze
```

```bash
flutter test
```

```bash
git diff --stat <commit-awal>^..<commit-akhir>
```

Ingat: tooling Flutter menulis ulang `minSdk = 23` di
`android/app/build.gradle.kts` saat build — kembalikan sebelum commit.

---

## Milestone 1 — Fondasi: kategori, parser, resolver, draf (T-11.1 s.d. T-11.4)

**Kapan:** sekarang, sebelum pekerjaan T-11.6 dan seterusnya, dan **wajib**
sebelum build apa pun diunggah ke closed testing (migrasi menyentuh data
pengguna dan tidak bisa dibatalkan di perangkat mereka).

**Rentang commit:** `12fca06` .. `57772e8`
(dokumen riset, ADR-026/027, `c6a0d3b` kategori, `8ed8893` parser/resolver,
`57772e8` draf CATAT).

### Risiko utama

| # | Risiko | Kenapa penting |
|---|---|---|
| R1 | Migrasi `categoryKey` → `categoryId` salah atau kehilangan data | Data closed testing; tidak bisa dibatalkan |
| R2 | Migrasi tidak idempoten / terhenti di tengah menghasilkan kategori ganda atau id yatim | Pembukaan berikutnya mengulang migrasi |
| R3 | Transaksi skema 1 disunting sebelum migrasi kehilangan label | `keepingLegacyCategoryOf` hanya di `saveTransaction` |
| R4 | `ActiveCategories` basi (nama/arsip tidak ikut berubah di layar) | Cache statis, pola ADR-025 |
| R5 | Parser nominal menghasilkan angka salah tanpa issue | Uang; aturan 1 CLAUDE.md |
| R6 | Resolver menerima nominal/dompet/kategori karangan | Inti ADR-027 |
| R7 | Draf tersimpan tanpa pengguna menekan Catat, atau jalur simpan baru di luar CATAT | Aturan 8 |

### Daftar periksa kode

**Kategori (`lib/shared/category/`, `transaction_model.dart`,
`transaction_repository_impl.dart`, `main.dart`)**
- [ ] `MigrateLegacyCategories`: urutan tulis = kategori → dokumen bulan →
      penanda. Tidak ada jalur yang menulis penanda sebelum transaksi.
- [ ] Id `legacy.<jenis>.<label>` deterministik dan stabil terhadap
      beda huruf/spasi; label berbeda jenis tidak bertabrakan.
- [ ] Label transfer dibuang, `note` tidak disentuh (keputusan pemilik).
- [ ] `TransactionModel.toJson` tidak lagi menulis `categoryKey` kecuali
      label lama yang belum dimigrasi; `schemaVersion` 2.
- [ ] `TransferTransaction` tidak pernah punya kategori di seluruh jalur
      (CATAT, sunting, catat lagi, migrasi).
- [ ] Kegagalan migrasi di `main.dart` tidak menghalangi aplikasi terbuka dan
      dicoba lagi pembukaan berikutnya.
- [ ] `CategoryRepositoryImpl.saveCategories` menimpa di tempat; urutan
      pengguna tidak berubah saat mengganti nama/mengarsipkan.
- [ ] `CreateCategory`: nama kembar sejenis dipakai ulang, terarsip
      dipulihkan; id tidak bertabrakan.
- [ ] Semua pemakai lama `categoryKey` sudah pindah (`grep -rn categoryKey lib`
      hanya boleh tersisa di model/migrasi).
- [ ] Penyaring, pencarian, dan judul Transaksi memakai nama dari id;
      kategori terarsip tetap tampil di transaksi lama.
- [ ] `RecordBloc.createCategory` (metode publik, bukan event) — terima atau
      catat sebagai utang desain.

**Parser & resolver (`spoken_amount_parser.dart`,
`domain/capture/`, `data/capture/rule_based_transaction_interpreter.dart`)**
- [ ] Tidak ada `double` di jalur nominal; sen = satuan × 100 (ADR-025 §3.1).
- [ ] Kasus tepi: "setengah", "seribu lima ratus", "1.5jt", "Rp35.000,00",
      "0,5 juta", angka sangat besar (overflow `int`?), "5m", tahun/jam
      ("jam 12", "tahun 2026") tidak jadi nominal bersatuan.
- [ ] Mata uang non-IDR: kata mata uang aplikasi sendiri tidak dianggap asing.
- [ ] Resolver: kutipan nominal wajib substring teks bukti; dompet/kategori
      hanya dari daftar aktif; kategori arsip tidak dipilih.
- [ ] `matchWallet` tidak menebak saat ada dua kandidat.
- [ ] Interpreter aturan: kata kunci jenis (transfer/pemasukan) tidak salah
      tangkap kalimat pengeluaran umum (mis. "masuk angin", "dapat diskon").

**Draf CATAT (`open_record_sheet.dart`, tiga `*_form_sheet.dart`,
`record_draft_card.dart`)**
- [ ] Draf hanya mengisi formulir; simpan tetap lewat tombol Catat.
- [ ] Dompet tidak dikenal dan transfer tanpa asal tidak diisi dompet bawaan.
- [ ] Draf diabaikan saat mode sunting / catat lagi.
- [ ] Nominal draf yang tidak `isMoneyInputExact` tidak diisi diam-diam salah.

### Daftar periksa perangkat

- [ ] **Migrasi data sungguhan:** pasang build `main` (sebelum Fase 11),
      buat dompet + transaksi berlabel (termasuk ejaan beda, label cocok alias
      bawaan, transfer berlabel), lalu pasang build milestone ini **di atasnya**
      tanpa hapus data. Periksa: kategori terbentuk, transaksi berkategori
      benar, label transfer hilang, saldo tidak berubah.
- [ ] Buka ulang aplikasi → migrasi tidak berjalan lagi, tidak ada kategori
      ganda.
- [ ] Layar Kategori: tambah, ganti nama, arsip, pulihkan; perubahan tampak
      di Riwayat dan rincian transaksi tanpa restart.
- [ ] CATAT: "Tambah kategori" dari formulir langsung terpilih.
- [ ] Bahasa en/id: nama kategori bawaan mengikuti bahasa saat pertama dibuat
      (sengaja tidak ikut berganti sesudahnya — ADR-026 §3.1).
- [ ] Lebar 360dp dan teks 2x: pemilih kategori, layar Kategori, kartu draf.

### Kriteria lulus

Tidak ada temuan R1–R3, R5–R7. Temuan R4 atau kosmetik boleh masuk antrean.

### Hasil

**Tanggal:** 30 Sep 2026 · **Perangkat:** Samsung Galaxy M15 5G (SM-M156B),
Android 16, bahasa perangkat Inggris · **Build:** debug dari worktree
`57772e8` (M1) dan `a1bcc5d` (sebelum Fase 11).

**Status: TIDAK LULUS** — temuan F1 (R1), F2 dan F3 (R5) harus diperbaiki
sebelum build apa pun diunggah ke closed testing.

**Otomatis:** `flutter analyze` bersih; 691 uji lulus. Probe tambahan
(`probe_test` di luar repo, 30 kasus) gagal di 12 kasus → F2–F5.

**Uji migrasi di HP (data lama sungguhan):** build `a1bcc5d` dipasang,
dibuat 1 dompet (BCA, saldo awal Rp5.000.000) dan 17 transaksi lewat UI lama
(15 pengeluaran, 2 pemasukan; 10 berlabel, 7 tanpa label), lalu build M1
dipasang **di atasnya** tanpa hapus data. Isi Hive diperiksa sebelum/sesudah.

| Label lama | Hasil migrasi | Catatan |
|---|---|---|
| Makan, Kopi, KOPI, Food | `builtin.food` "Food & Drinks" | **4 label pengguna melebur jadi satu** (F1) |
| air | `builtin.bills` "Bills" | salah makna bila "air mineral" (F1/F5) |
| Data | `builtin.internet` "Phone & Internet" | alias `data` (F1/F5) |
| Gaji | `builtin.salary` "Salary" | judul transaksi berubah bahasa (perangkat en) |
| Proyek | `builtin.freelance` "Freelance" | alias |
| Arisan, arisan | `legacy.expense.arisan` "Arisan" | ✅ ejaan beda digabung benar |
| (tanpa label) ×7 | tanpa kategori | ✅ |

Lulus: 17 transaksi utuh, saldo BCA tetap Rp10.655.000, `schemaVersion` 2,
`categoryKey` hilang seluruhnya, penanda migrasi tertulis; buka ulang tidak
menulis apa pun (ukuran berkas Hive identik) dan tidak ada kategori ganda;
layar Kategori (ganti nama "Bills"→"Tagihan", arsip "Food & Drinks") langsung
tampak di Riwayat tanpa restart; kategori terarsip tetap jadi judul transaksi
lama dan tidak ditawarkan di CATAT; kategori sering dipakai tampil di atas;
"Add category" dari CATAT langsung terpilih.

**Tidak diuji di perangkat (alasan):** teks 2x dan lebar 360dp, serta
penanaman nama kategori dalam bahasa Indonesia — butuh mengubah setelan
sistem HP pemilik; draf CATAT (T-11.4) — belum ada jalur UI di M1, tercakup
uji widget; label pada transfer lama — UI lama tidak bisa membuatnya,
tercakup uji unit.

#### Temuan

| # | Tingkat | Risiko | Temuan | Bukti |
|---|---|---|---|---|
| F1 | **Blokir** | R1 | Migrasi mencocokkan label lama ke kategori bawaan lewat **alias**, sehingga label berbeda milik pengguna melebur permanen dan judul transaksi lama berubah (termasuk bahasanya). Tidak bisa dibatalkan setelah build terpasang. | Tabel di atas; `migrate_legacy_categories.dart:68` → `category_matcher.dart:18` |
| F2 | **Blokir** | R5 | Nominal salah tanpa issue: "satu setengah juta" → 500.000; "dua setengah juta" → 500.000; "satu koma lima juta" → 5.000.000; "kopi 25 ribu 2 gelas" → 25.002; "tiga puluh ribu dua bungkus" → 30.002; "Rp 99.999.999.999.999.999" meluap jadi negatif. | probe P1–P3b, P4b; `spoken_amount_parser.dart` (`setengah`, digit sesudah skala, tanpa batas) |
| F3 | **Blokir** | R5 | Deret digit ≥ 20 (nomor referensi di notifikasi/struk) melempar `FormatException` dari `int.parse`; lewat interpreter aturan ini membuat `VoiceCaptureBloc` tertahan di tahap "memahami". | probe P4 |
| F4 | Tinggi | R6 | Kata kunci jenis terlalu longgar: "bayar masuk tol", "dapat diskon beli baju", "beli pulsa bonus kuota" → **pemasukan**, tanpa issue, jadi draf tampak yakin dan tidak dikirim ke cloud (ADR-027 §3.5). | probe I1–I3; `rule_based_transaction_interpreter.dart` `_incomeWords` |
| F5 | Sedang | R6 | Alias bawaan terlalu lebar untuk pencocokan kalimat: "beli air mineral" → Tagihan; juga `data`, `anak`, `les`, `kos`, `fee`, `project`. | probe I4; `built_in_categories.dart` |
| F6 | Sedang | R1 | Bila membaca label lama gagal, kategori bawaan tidak pernah disimpan (pemilih CATAT kosong); kegagalan migrasi hanya `developer.log`, tidak dilaporkan ke Crashlytics. | `migrate_legacy_categories.dart:58-83`, `main.dart:59` |
| F7 | Rendah | R3 | Menyunting transaksi skema 1 yang **pindah bulan** sebelum migrasi berhasil membuang labelnya (`keepingLegacyCategoryOf` hanya melihat dokumen bulan tujuan). | `transaction_repository_impl.dart:117-122` |
| F8 | Rendah | R4 | `ActiveCategories` memberi tahu di setiap baca (daftar baru selalu dianggap berubah) → seluruh aplikasi dibangun ulang tiap `listCategories`. | `category_repository_impl.dart` `_publish` |
| F9 | Rendah | — | Ganti nama boleh menghasilkan dua kategori sejenis bernama sama; "Catat lagi" bisa mencatat ke kategori terarsip. | `category_manager_bloc.dart`, form `prefill` |
| F10 | Catatan | — | `RecordBloc.createCategory` metode publik (bukan event) — perlu diterima pemilik atau dicatat sebagai utang desain. | `record_bloc.dart` |

**Tindak lanjut (30 Sep 2026, T-11.10):** F1 diterima pemilik (belum ada
pengguna dengan data lama; ADR-026 §3.4). F2–F6 diperbaiki dengan kasus probe
sebagai uji regresi (724 uji lulus). F7–F10 ke antrean B-16. Dengan F1
diterima dan F2–F6 tertutup, **M1 dianggap lulus** untuk build closed testing
berikutnya; uji migrasi di HP tidak diulang karena perubahan F6 hanya urutan
tulis dan tercakup uji unit.


---

## Milestone 2 — Suara sampai formulir (T-11.5, T-11.6)

**Kapan:** setelah T-11.6 selesai, tepat sebelum build closed testing yang
memuat fitur suara diunggah.

**Rentang commit:** `2d17c2c` .. (commit akhir T-11.6)

### Risiko utama

| # | Risiko |
|---|---|
| S1 | ANR/jank saat membuka CATAT atau lembar rekam (sekali terlihat di emulator build debug, belum terbukti penyebabnya) |
| S2 | Sesi STT bocor: pengenal tetap mendengar setelah lembar ditutup |
| S3 | Pesan galat salah (izin ditolak / layanan tidak ada / jaringan / tidak ada ucapan) |
| S4 | Loop `openRecordSheet` → rekam → `openRecordSheet` membuka lembar ganda atau kehilangan pintasan (dompet/pos anggaran) |
| S5 | Privasi: audio/teks keluar perangkat tanpa diungkapkan; formulir Keamanan Data dan kebijakan privasi tidak cocok |
| S6 | Izin: `RECORD_AUDIO`, `<queries>`, dua kunci Info.plist; tidak ada izin berlebih (Bluetooth sengaja tidak ditambahkan) |

### Daftar periksa kode

- [ ] `SystemSpeechTranscriber`: stream selalu ditutup tepat sekali (hasil
      akhir, galat, status done, cancel); tidak ada `add` setelah `close`.
- [ ] Jeda `_errorGrace` tidak menelan hasil akhir yang datang terlambat.
- [ ] `VoiceCaptureBloc.close` membatalkan sesi; `showVoiceCaptureSheet`
      selalu menutup bloc (termasuk saat lembar ditutup dengan geser).
- [ ] `openRecordSheet` rekursif: pintasan (`initialWalletId`, pos anggaran,
      nominal) — mana yang sengaja dibawa, mana yang hilang.
- [ ] Locale ucapan mengikuti bahasa aplikasi (`id_ID`/`en_US`) — cukup?
- [ ] Teks transkrip tidak dikirim ke Analytics/Crashlytics dan tidak
      disimpan.

### Daftar periksa perangkat (HP sungguhan; emulator hanya untuk alur)

- [ ] Izin pertama kali: izinkan → rekam → formulir terisi.
- [ ] Izin ditolak → pesan izin; ditolak permanen → arahan ke pengaturan
      (saat ini belum ada — putuskan).
- [ ] Mode pesawat → pesan jaringan (atau berhasil kalau paket id offline ada).
- [ ] 10 kalimat dari dataset §10 diucapkan: catat transkrip vs draf.
- [ ] Lingkungan bising (kafe/jalan): 5 kalimat.
- [ ] Buka–tutup lembar rekam 10× cepat: tidak ada ANR, mikrofon mati.
- [ ] iOS: izin dua dialog (mikrofon + pengenalan ucapan), alur sama.
- [ ] Build **release** (bukan debug) di Android menengah: waktu buka CATAT.

### Kriteria lulus

Tidak ada S1, S2, S5. Pesan S3 benar untuk empat kasus. Formulir Keamanan
Data diperbarui sebelum unggah.

### Hasil

_(diisi saat verifikasi)_

---

## Milestone 3 — Firebase AI dan kaskade (T-11.7 s.d. T-11.9)

**Kapan:** setelah benchmark T-11.9 punya angka, dan sekali lagi (ringkas)
tepat sebelum pindah ke tier berbayar dan rilis publik.

**Rentang commit:** (commit awal T-11.7) .. (commit akhir T-11.9)

### Risiko utama

| # | Risiko |
|---|---|
| C1 | Keluaran model lolos pagar resolver (kutipan palsu yang kebetulan substring) |
| C2 | Data berlebih dikirim ke cloud (saldo, riwayat, id, `origin`) |
| C3 | Tier gratis terbawa ke rilis publik (data keuangan dipakai pelatihan) |
| C4 | Offline / kuota habis / galat jaringan membuat lembar rekam buntu, bukan jatuh ke draf aturan |
| C5 | App Check belum aktif menjelang 2 Nov 2026 |
| C6 | Abstraksi tidak benar-benar bisa diganti (mengganti penyedia butuh ubah domain/UI) |
| C7 | Angka benchmark tidak jujur (hanya teks, bukan transkrip nyata) |

### Daftar periksa

- [ ] Kaskade: aturan dulu; cloud hanya saat `isConfident` salah. Ukur laju
      panggilan cloud pada dataset §10.
- [ ] Payload: periksa isi permintaan (log debug) — hanya teks + nama dompet +
      nama kategori + tanggal.
- [ ] `responseSchema` sama dengan kontrak ADR-027 §3.2; JSON rusak → draf
      aturan.
- [ ] Mode pesawat, kuota habis (simulasi 429), Firebase gagal init → draf
      aturan, tanpa pesan galat yang membingungkan.
- [ ] App Check aktif dan enforcement diuji di proyek uji.
- [ ] Penguji closed testing sudah diberi tahu soal tier gratis; Keamanan
      Data dan kebijakan privasi (repo web) sudah menyebut Gemini.
- [ ] Sebelum rilis publik: proyek sudah Blaze, batas anggaran terpasang.
- [ ] Uji "pivot": ganti registrasi DI ke interpreter palsu tanpa mengubah
      berkas domain/presentasi.
- [ ] Laporan benchmark: amount/type/wallet/category accuracy, JSON validity,
      p50/p95 latensi, laju fallback, di minimal 1 Android menengah + 1 iPhone.

### Kriteria lulus

Tidak ada C1–C4. C3 wajib nol sebelum rilis publik. Hasil benchmark tercatat
di TASK_LIST T-11.9.

### Hasil

_(diisi saat verifikasi)_
