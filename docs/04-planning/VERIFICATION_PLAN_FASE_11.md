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

_(diisi saat verifikasi)_

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

## Milestone 3 — Model lokal dan keputusan pivot (T-11.7 s.d. T-11.9)

**Kapan:** setelah benchmark T-11.9 punya angka, sebelum model diaktifkan
untuk pengguna.

**Rentang commit:** (commit awal T-11.7) .. (commit akhir T-11.9)

### Risiko utama

| # | Risiko |
|---|---|
| M1 | Keluaran model lolos pagar resolver (kutipan palsu yang kebetulan substring) |
| M2 | Memori/ANR/kill OS saat memuat model di perangkat menengah |
| M3 | Unduhan: checksum, lanjut-setelah-putus, ruang penyimpanan, versi lama tidak terhapus |
| M4 | Lisensi Gemma: NOTICE, teks Terms, batasan penggunaan di syarat & ketentuan (repo web) |
| M5 | Abstraksi tidak benar-benar bisa diganti: mengganti ke Firebase AI butuh ubah domain/UI |
| M6 | Angka benchmark tidak jujur (hanya teks, bukan transkrip nyata; hanya flagship) |

### Daftar periksa

- [ ] Kaskade: aturan dulu, model hanya saat tidak yakin; ukur laju panggilan
      model.
- [ ] Gating perangkat: di bawah syarat, fitur tetap jalan dengan aturan.
- [ ] Model dilepas saat idle; satu inferensi pada satu waktu.
- [ ] Uji "pivot": ganti registrasi DI ke adaptor lain (atau palsu) tanpa
      mengubah berkas domain/presentasi.
- [ ] Laporan benchmark: amount/type/wallet/category accuracy, JSON validity,
      p50/p95 latensi, RAM puncak, ukuran model, di minimal 1 Android
      menengah + 1 flagship + 1 iPhone.
- [ ] Tangga model (270M → 1B → Gemma 4 E2B) dicatat beserta alasan naik.

### Kriteria lulus

Tidak ada M1, M2, M4. Keputusan pivot (tetap lokal / tambah Firebase AI)
tercatat di ADR-027 atau ADR baru dengan angka benchmark.

### Hasil

_(diisi saat verifikasi)_
