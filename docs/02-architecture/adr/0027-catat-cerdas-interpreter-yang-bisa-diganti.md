# Catat Cerdas: bukti teks, interpreter yang bisa diganti, draf CATAT

## 1. Metadata

- **Decision ID:** ADR-027
- **Tanggal:** 2026-09-30
- **Fase roadmap:** Fase 11 (Catat Cerdas), T-11.2 dst.
- **Status:** Accepted
- **Cakupan:** `features/record` (domain/data/presentation `capture/`),
  `lib/core/utils/formatters/spoken_amount_parser.dart`
- **Bergantung pada:** ADR-026 (kategori), ADR-025 (mata uang), ADR-023
  (fitur online), aturan 1 dan 8 CLAUDE.md

## 2. Konteks

Pemilik ingin mencatat transaksi dari **suara** lebih dulu, lalu dari
**notifikasi** (bank/e-wallet) dan **foto** (struk). Riset lengkap ada di
`docs/04-planning/VOICE_INPUT_RESEARCH.md`. Temuan yang mengikat desain:

- Model bahasa (lokal maupun cloud) bisa mengarang nominal, dompet, dan
  kategori; skor keyakinan model tidak terkalibrasi.
- Pilihan penyedia belum final: Gemma lokal lebih dulu (Opsi A, mulai dari
  model termurah), Firebase AI sebagai jalur pivot.
- CATAT adalah satu-satunya jalur pembuatan transaksi manual (aturan 8).
- Ketiga sumber pada akhirnya menghasilkan **teks**: transkrip suara, teks
  notifikasi, teks OCR struk.

## 3. Keputusan

### 3.1 Bukti teks yang tidak terikat sumber

Masukan pipeline adalah `CaptureEvidence`:

| Field | Tipe | Catatan |
|---|---|---|
| `source` | `CaptureSource { voice, notification, photo }` | |
| `text` | `String` | Transkrip / teks notifikasi / teks OCR |
| `capturedAt` | `DateTime` | Waktu tangkap; untuk notifikasi = waktu notifikasi |
| `origin` | `String?` | Mis. nama paket aplikasi pengirim notifikasi; tidak dikirim ke model |

Menambah sumber baru = menambah nilai enum dan satu penangkap (STT, pendengar
notifikasi, OCR); interpreter, resolver, dan UI tidak berubah.

### 3.2 Interpreter mengekstrak potongan teks, bukan nilai final

```dart
abstract interface class TransactionInterpreter {
  Future<Either<Failure, InterpretedTransaction>> interpret(
    CaptureEvidence evidence,
    InterpretationContext context,
  );
}
```

`InterpretedTransaction` berisi `kind?` dan **kutipan** dari `evidence.text`:
`amountText`, `walletText`, `toWalletText`, `categoryName`, `note`,
`dateText`. Tidak ada nominal numerik, mata uang, atau skor keyakinan dari
model. Implementasi: aturan (Dart), LLM lokal, Firebase AI, dan kaskade.

### 3.3 Satu resolver deterministik untuk semua penyedia

`CaptureDraftResolver` (domain) mengubah hasil interpreter menjadi `RecordDraft`
+ daftar `DraftIssue`:
- nominal: `SpokenAmountParser` → `int` sen (ADR-025 §3.1: seperseratus satuan
  utama), hanya bila `amountText` benar-benar ada di `evidence.text`;
- dompet: dicocokkan ke dompet aktif; tidak pernah membuat dompet;
- kategori: dicocokkan ke kategori aktif (nama + alias bawaan); tidak pernah
  membuat kategori;
- tanggal: hari ini/kemarin dari teks, selain itu `capturedAt` (diganti
  ADR-029 §3.2: tanggal ditafsirkan paket bahasa, resolver hanya memvalidasi);
- transfer ("top up X"): tujuan = X, sumber hanya bila disebut; tanpa sumber
  → issue dan pengguna wajib memilih.

### 3.4 Keluaran = formulir CATAT terisi

`RecordDraft` membuka `openRecordSheet(draft: …)`. Pengguna meninjau, mengubah,
lalu menekan Catat. Tidak ada layar pratinjau atau jalur simpan lain; hasil
interpreter tidak pernah menyentuh repository.

### 3.5 Penyedia model: Firebase AI Logic dulu (revisi 30 Sep 2026)

Keputusan pemilik 30 Sep 2026 menggantikan arah "Gemma lokal dulu" di riset:

1. **Penyedia pertama: Firebase AI Logic** (`firebase_ai`,
   `FirebaseAI.googleAI()`, Gemini Developer API) dengan `responseSchema`
   yang sama dengan kontrak §3.2, lewat `FirebaseAiTransactionInterpreter`.
2. **Tier gratis (Spark) hanya untuk pengembangan dan closed testing.** Syarat
   Gemini API: pada layanan tanpa bayar, prompt dan jawaban dipakai Google
   untuk meningkatkan produk dan dapat dibaca peninjau manusia, dan Google
   meminta tidak mengirim informasi pribadi ke sana. Karena itu penguji closed
   testing diberi tahu, dan **sebelum rilis publik proyek pindah ke tier
   berbayar** (Blaze) — tanpa perubahan kode. Syarat usia 18+ layanan ini
   dicatat untuk rating konten Play.
3. **Aturan dulu, cloud bila ragu.** (Diganti ADR-029 §3.4:
   `CaptureDraftComposer`, dan bahasa tanpa paket aturan langsung ke cloud.)
   `CascadingTransactionInterpreter`
   memakai `RuleBasedTransactionInterpreter` lebih dulu; Firebase AI hanya
   dipanggil bila draf aturan tidak yakin (`RecordDraft.isConfident` salah).
   Offline, galat, atau kuota habis → draf aturan dipakai apa adanya.
4. **Data yang dikirim:** hanya teks bukti + nama dompet aktif + nama
   kategori aktif + tanggal. Tanpa saldo, riwayat, id, atau `origin`.
5. **App Check** dipasang sebelum 2 Nov 2026 (wajib untuk AI Logic).
6. **Gemma lokal ditunda** (antrean B-15); antarmuka `TransactionInterpreter`
   tetap membuatnya bisa ditambahkan kemudian.
7. **Koneksi (keputusan pemilik 30 Sep 2026):** tidak ada pengecekan
   koneksi di muka (`connectivity_plus` dan sejenisnya tidak dipakai) —
   status jaringan tidak menjamin internet jalan, dan pengenal ucapan bisa
   bekerja offline bila paket bahasanya terpasang. Setiap layanan dicoba,
   lalu kegagalan nyatanya ditangani:
   - STT gagal karena jaringan (`SpeechFailure.network`) → pesan "butuh
     internet", tombol bulat tetap "Rekam ulang", dan "Ketik saja" naik jadi
     tombol utama (sama untuk `unavailable`).
   - Firebase AI: batas waktu ±5 dtk; offline, galat, atau lewat batas waktu
     → draf aturan dibuka di CATAT dengan field bermasalah disorot, tanpa
     pesan galat dan tanpa antrean kirim ulang (transkrip tidak disimpan).
   - Tidak ada indikator offline di seluruh aplikasi: pencatatan inti penuh
     tanpa internet (NFR-REL-001), jadi banner offline memberi kesan salah.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Model mengeluarkan JSON nilai final, langsung disimpan**
- **Opsi B — Model mengeluarkan nilai final, divalidasi, pratinjau sendiri**
- **Opsi C — Kutipan teks + resolver deterministik + form CATAT (Dipilih)**

## 5. Analisis konsekuensi

### Opsi A
Tercepat, tetapi melanggar aturan 8 dan membiarkan halusinasi masuk ke data.

### Opsi B
Validasi mungkin, tetapi nominal numerik karangan model sulit dideteksi, dan
layar pratinjau terpisah menggandakan formulir CATAT.

### Opsi C (Dipilih)
Nominal selalu dihitung Dart dari teks yang benar-benar ada; penyedia model
bisa diganti tanpa menyentuh domain/UI; ketiga sumber memakai jalur yang sama.
Kelemahan: prompt harus disiplin mengutip, dan parser nominal Indonesia perlu
dirawat.

## 6. Konsekuensi

### Yang menjadi lebih mudah
- Pivot Gemma ↔ Firebase AI = ganti satu registrasi DI.
- Notifikasi dan foto hanya butuh penangkap baru.

### Yang menjadi lebih sulit
- `openRecordSheet` dan tiga formulir harus menerima draf parsial.

### Risiko yang diterima
- STT memakai server Google/Apple bila paket bahasa offline tidak ada
  (disetujui pemilik).

## 7. Catatan implementasi

- Jangan pernah menaruh `double` di jalur nominal.
- Jangan mengirim saldo, riwayat, atau id internal ke model.
- Jangan menyimpan audio, foto, atau teks bukti setelah draf dibuat.

## 8. Kriteria peninjauan ulang

- Benchmark menunjukkan kutipan teks terlalu membatasi (mis. foto struk
  multimodal tanpa OCR).
- Kebutuhan multi-transaksi per bukti (satu struk berisi banyak pos).

## 9. Artefak terkait

### Dokumentasi
- `docs/04-planning/VOICE_INPUT_RESEARCH.md`
- ADR-026

### Rujukan kode
- `lib/features/record/domain/capture/`
- `lib/core/utils/formatters/spoken_amount_parser.dart`

---

**Penulis keputusan:** Claude (agen), atas keputusan pemilik
**Ditinjau oleh:** pemilik
**Tanggal disetujui:** 2026-09-30
**Status implementasi:** berjalan (T-11.2 s.d. T-11.5 selesai; penyedia Firebase AI T-11.7). Diubah sebagian oleh ADR-029.
