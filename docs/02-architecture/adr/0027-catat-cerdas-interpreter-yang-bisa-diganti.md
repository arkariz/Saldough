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
- tanggal: hari ini/kemarin dari teks, selain itu `capturedAt`;
- transfer ("top up X"): tujuan = X, sumber hanya bila disebut; tanpa sumber
  → issue dan pengguna wajib memilih.

### 3.4 Keluaran = formulir CATAT terisi

`RecordDraft` membuka `openRecordSheet(draft: …)`. Pengguna meninjau, mengubah,
lalu menekan Catat. Tidak ada layar pratinjau atau jalur simpan lain; hasil
interpreter tidak pernah menyentuh repository.

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
**Status implementasi:** belum dimulai
