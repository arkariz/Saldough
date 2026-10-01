# Riset & Rencana Implementasi — Catat lewat Suara

> **Revisi keputusan 30 Sep 2026:** penyedia model pertama diganti ke
> **Firebase AI Logic tier gratis** (hanya untuk pengembangan dan closed
> testing; pindah berbayar sebelum rilis publik), dengan parser aturan tetap
> lebih dulu dan cloud hanya bila ragu. Gemma lokal ditunda (antrean B-15).
> Bagian §5–§6 dan Fase 3 di bawah tetap disimpan sebagai rujukan untuk B-15.
> Keputusan mengikat ada di ADR-027 §3.5.

**Tanggal riset:** 30 September 2026 · **Status:** diimplementasi di Fase 11 (progres di TASK_LIST); semula
keputusan pemilik 30 Sep 2026: STT server boleh, Opsi A (Gemma lokal, mulai
dari model termurah), sistem kategori dibangun sekalian (set bawaan disetujui,
label transfer lama dibuang), top-up = transfer ·
**Keputusan terkait:** ADR-023 (fitur online), ADR-024, ADR-025 (satu mata uang),
aturan 1 (uang `int` sen) dan aturan 8 (CATAT satu-satunya jalur pembuatan).

Label bukti dipakai di seluruh dokumen:
- **[V]** fakta terverifikasi dari sumber resmi saat riset (tautan disertakan).
- **[U]** belum terverifikasi / hanya sumber sekunder / dari ingatan.
- **[E]** estimasi penulis, bukan hasil ukur.


> **Catatan path (1 Okt 2026):** path berkas di rencana ini ditulis sebelum
> implementasi dan Fase 12. Lokasi sebenarnya: kode suara di
> `lib/features/record/{domain,data,presentation}/capture/` (parser ucapan
> juga di `domain/capture/`, bukan `core/utils/formatters/`), kategori di
> `lib/shared/category/` dan layar kelolanya di `lib/features/account/`,
> registrasi DI di `lib/app/di/root_module.dart`, `RecordDraft` di
> `domain/capture/record_draft.dart`, `BudgetItemCatalog` di
> `lib/shared/budget_catalog/`. Gemma lokal ditunda (B-15), jadi
> `local_llm_transaction_interpreter.dart` belum ada.

---

## 1. Ringkasan eksekutif

1. **Tidak ada STT on-device berbahasa Indonesia yang terjamin offline di kedua
   platform** lewat API sistem. Android bisa offline bila paket id-ID terpasang
   (dicek saat runtime); iOS tidak mempublikasikan daftar locale on-device, dan
   `SpeechTranscriber` iOS 26 dilaporkan tidak memuat id_ID [U]. Satu-satunya
   yang pasti offline di dua platform adalah Whisper (whisper.cpp), dengan
   biaya ukuran 75–466 MB dan latensi yang belum terukur di ponsel.
2. **STT:** pengenal suara sistem lewat paket `speech_to_text`
   (7.5.0, publisher terverifikasi) dengan `localeId: id_ID`, *prefer on-device*
   bila tersedia, jatuh ke mode server bila tidak (disetujui pemilik).
   Ukuran tambahan ≈ 0.
3. **Model Gemma yang realistis** (dicoba berurutan dari yang termurah, keputusan
   pemilik): Gemma 3 1B int4 (529 MB [V]) adalah model
   terkecil yang masuk akal **tanpa fine-tuning**; Gemma 3 270M / FunctionGemma
   (≈288 MB [V]) lebih kecil dan cepat, tetapi Google sendiri menyatakan butuh
   fine-tuning (58% → 85% di tugas acuannya [V]). Gemma 4 E2B lebih pintar dan
   berlisensi Apache 2.0, tetapi 2,58 GB [V] — terlalu berat untuk aplikasi
   pencatat.
4. **Runtime:** LiteRT-LM (penerus MediaPipe LLM Inference yang kini
   maintenance-only [V]). Tidak ada plugin Flutter resmi; `flutter_gemma`
   (komunitas, aktif) adalah jalur paling matang. Dekode terbatas skema JSON
   ada di C++ LiteRT-LM [V] tetapi **tidak terdokumentasi di flutter_gemma** [V].
5. **Gemini Nano (Android) dan Apple Foundation Models tidak mendukung bahasa
   Indonesia** [V] — tidak dipakai.
6. **Keputusan desain terpenting:** model (lokal maupun cloud) **hanya mengekstrak
   potongan teks** (jenis, frasa nominal, sebutan dompet, kategori, catatan).
   Konversi nominal ke `int` sen, pencocokan dompet, dan validasi dikerjakan
   **kode Dart deterministik yang sama** untuk semua penyedia. Nominal yang tidak
   muncul di transkrip ditolak → halusinasi angka tidak bisa lolos.
7. **Pratinjau = formulir CATAT yang sudah terisi.** Suara tidak pernah menyimpan
   sendiri; ia membuka CATAT dengan draf. Ini sekaligus memenuhi aturan 8 dan
   "AI tidak boleh mengubah state keuangan".
8. **Hibrida ringan:** parser aturan (Dart) selalu jalan dulu (milidetik);
   Gemma dipanggil hanya bila parser tidak yakin — terutama untuk kategori dan
   catatan. Setelah **sistem kategori** dibangun, kategori menjadi himpunan
   tertutup sehingga kategori halusinasi bisa ditolak.
9. **Biaya Opsi A ≈ Rp 0:** Hugging Face tidak menagih bandwidth unduhan dan
   penyimpanan repo publik gratis (best-effort) [V]. Catatan: repo Gemma 3 1B
   resmi di `litert-community` *gated* [V] → perlu salinan publik milik pemilik
   yang memenuhi syarat redistribusi Gemma Terms §3.1 [V], atau pakai Gemma 4
   E2B yang tidak gated & Apache 2.0 [V] (tetapi 2,6 GB).
10. **Rekomendasi akhir (Opsi A):** sistem kategori → STT sistem + parser aturan
    + form CATAT terisi draf → Gemma lokal, mulai dari model termurah 270M → 1B → Gemma 4 E2B
    (unduhan opt-in dari HF,
    perangkat ≥ 6 GB RAM) → adaptor Firebase AI disiapkan di balik antarmuka
    yang sama sebagai jalur pivot. Perangkat di bawah syarat tetap dapat parser.
    Biaya cloud bila dipivot: ~US$4/bulan per 15.000 panggilan
    `gemini-3.5-flash-lite` [E dari harga V], wajib tier berbayar + App Check
    (wajib mulai 2 Nov 2026 [V]).

---

## 2. Analisis kode saat ini

### Current Architecture
- Flutter 3.47.2, struktur 3 zona `core/` · `shared/` · `features/` (ADR-0009).
- State: `Bloc<E,S>` dari `package:state_management`, state `UiState<S>` dengan
  field `effect` (ADR-0003).
- Galat: `Either<Failure,T>` lewat mixin `RepositoryGuard`
  (`lib/core/foundation/repository_guard.dart`, ADR-0005).
- DI: `package:di` (pembungkus get_it). Root di `lib/core/di/src/root_module.dart`,
  scope fitur `IsolatedScope` di `lib/features/*/di/*_scope.dart`.
- Navigasi: GoRouter lewat `AppRouteRegistry` (hanya `/home`, `/onboarding`);
  sebagian besar layar dibuka sebagai sheet dari shell.
- Penyimpanan: Hive (`hive_storage`, dokumen JSON, ADR-0002/0012).
- i18n: slang, `assets/i18n/id.i18n.json` (dasar) + `en`.

### Relevant Existing Components
| Komponen | Lokasi | Catatan untuk fitur suara |
|---|---|---|
| `Transaction` (sealed: `IncomeTransaction`, `ExpenseTransaction`, `TransferTransaction`) | `lib/shared/transaction/domain/transaction.dart` | `amount` `int` sen > 0, `date`, `note`, `categoryKey?`; expense/transfer punya `budgetItemId?`; transfer `fromWalletId`≠`toWalletId`. Tidak ada enum jenis — jenis = subkelas. |
| `Wallet` | `lib/shared/wallet/domain/wallet.dart` | `id`, `name`, `iconKey`, `isActive`. Tidak ada alias. |
| Kategori | — | **Bukan entitas.** `categoryKey` = label teks bebas; saran dari `RecordDefaults.incomeCategories/expenseCategories` (`lib/features/record/domain/record_defaults.dart`), diurutkan dari transaksi terbaru. `DOMAIN_MODEL.md` baris ~468: "Daftar kategori transaksi" belum diisi pemilik. |
| Pos anggaran | `BudgetItemCatalog.listOptions()` (`lib/features/record/domain/budget_item_catalog.dart`) | Tautan opsional; di luar MVP suara. |
| CATAT | `openRecordSheet(...)` di `lib/features/record/presentation/open_record_sheet.dart` → `RecordFormHost` → `Income/Expense/TransferFormSheet` | Prefill sebagian: `initialWalletId`, `initialChoice`, `initialAmountSen`, `initialToWalletId`, `prefillFrom: Transaction`. **Belum bisa** menerima catatan, kategori, atau tanggal (prefill memaksa tanggal = hari ini, `expense_form_sheet.dart:126`). |
| `RecordBloc` | `lib/features/record/presentation/bloc/record_*.dart` | Event `IncomeRecorded/ExpenseRecorded/TransferRecorded`; simpan lewat use case `lib/shared/transaction/domain/usecases/record_transaction.dart`. |
| Uang | `lib/core/utils/formatters/money_formatter.dart` (`AppMoneyFormatter`), `money_input.dart` (`parseMoneyInput`) | `parseMoneyInput` mengurai **input ketikan** berpemisah locale → `int?` sen. Tidak mengenal "ribu/juta/k/rb". |
| Mata uang | `ActiveCurrency.notifier` (`lib/core/currency/active_currency.dart`), `AppCurrency` enum dengan `fractionDigits` | Satu mata uang per aplikasi (ADR-025). |
| Firebase | `app_bootstrap_firebase.dart`, `lib/shared/auth/` | `firebase_core/auth/analytics/crashlytics` ada; **tidak ada** `firebase_ai`, `firebase_app_check`. Init dibungkus try/catch — aplikasi tetap jalan tanpa Firebase. |
| Analytics | `lib/core/foundation/analytics/` | Bisa dipakai untuk event hasil suara (tanpa isi transkrip). |

### Belum ada sama sekali
Izin `RECORD_AUDIO` (manifest hanya `INTERNET`), `NSMicrophoneUsageDescription`
/ `NSSpeechRecognitionUsageDescription`, `permission_handler`, paket audio/STT/ML,
`MethodChannel`, isolate/`compute`, klien HTTP, `ios/Podfile` (target iOS 15.0
di pbxproj).

### Reusable Components
- `RepositoryGuard` + `Either` untuk semua adaptor (STT, interpreter, unduh model).
- `openRecordSheet` + form CATAT sebagai layar pratinjau/edit (diperluas dengan draf).
- `RecordDefaults` sebagai sumber daftar kategori ringkas untuk konteks model.
- `WalletRepository` (daftar dompet aktif) untuk konteks dan pencocokan.
- `ActiveCurrency` + `AppCurrency.fractionDigits` untuk konversi ke sen.
- `AppMoneyFormatter` untuk tampilan pratinjau.
- `AppBootstrap` (Firebase) untuk adaptor cloud; analytics untuk metrik.
- Pola `IsolatedScope` untuk mendaftarkan implementasi interpreter.

### Potential Conflicts
1. **Aturan 8 (CATAT satu-satunya jalur).** Layar "Preview → Save" terpisah akan
   melanggarnya. Solusi: pratinjau = form CATAT terisi draf.
2. **`prefillFrom` butuh `Transaction` utuh** (id, amount > 0) dan mereset
   tanggal. Perlu tipe draf baru (`RecordDraft`) yang semua field-nya opsional.
3. **Kategori bukan entitas** (label teks bebas, dipakai di 13 berkas: domain
   `transaction.dart`, `transaction_model.dart`, `record_defaults.dart`, bloc &
   form CATAT termasuk transfer, `transaction_bloc/event`, `transaction_display`,
   `transaction_detail_page`, `open_edit_transaction_sheet`). Pemilik memutuskan
   **membangun sistem kategori** (§3A) sebagai prasyarat, sehingga kategori
   menjadi himpunan tertutup yang bisa divalidasi.
4. **Invarian lokal-first.** STT server dan Firebase AI adalah panggilan jaringan
   yang membawa data keuangan (ucapan). PRD §8 (revisi 28 Sep) mengizinkan
   fitur online asalkan pencatatan inti tetap offline — suara harus jadi
   *tambahan*, bukan jalur wajib. Formulir Keamanan Data Play perlu diperbarui
   (`PLAY_DATA_SAFETY.md`) bila audio/teks dikirim ke layanan pihak ketiga.
5. **Gaya lisensi Gemma 3** mewajibkan NOTICE & penerusan batasan penggunaan bila
   model didistribusikan [V]; Gemma 4 Apache 2.0.
6. **`minSdk 23`**: API STT on-device Android butuh 31+/33+; perlu degradasi.

### Architecture Constraints
- Domain tidak boleh mengimpor paket STT/LLM/Firebase.
- Uang tetap `int` sen; model tidak boleh menghasilkan `double` kanonik.
- Tidak ada Riverpod/GetX; tidak ada lintas-impor antar fitur → seluruh fitur
  suara tinggal **di dalam `features/record/`** (ia mode input CATAT).
- Teks UI lewat i18n; kosakata "mencatat, bukan melakukan".

---

## 3. Arsitektur yang direkomendasikan

> **Tambahan pemilik 30 Sep 2026:** input dari **notifikasi** dan **foto**
> menyusul. Karena itu interpreter menerima `CaptureEvidence { source: voice |
> notification | photo, text, capturedAt, origin? }` — bukan transkrip suara
> saja — dan kode tinggal di `features/record/{domain,data,presentation}/capture/`.
> Notifikasi dan foto hanya menambah penangkap (pendengar notifikasi, OCR);
> interpreter, resolver, dan form CATAT sama. Lihat ADR-027.

```text
 [Tombol mic di pemilih CATAT]
            │
            ▼
 VoiceCaptureSheet (presentation) ── VoiceEntryBloc
            │
            ▼
 SpeechTranscriber  (domain interface)
   └─ SystemSpeechTranscriber (data, paket speech_to_text)      → String transkrip
            │
            ▼
 TransactionInterpreter (domain interface)                      → InterpretedTransaction
   ├─ RuleBasedTransactionInterpreter   (data, Dart murni)         (potongan teks, tanpa angka final)
   ├─ LocalLlmTransactionInterpreter    (data, flutter_gemma)
   ├─ FirebaseAiTransactionInterpreter  (data, firebase_ai)
   └─ CascadingTransactionInterpreter   (rule → llm bila tidak yakin)
            │
            ▼
 CaptureDraftResolver (domain, deterministik, SATU untuk semua penyedia)
   - SpokenAmountParser  → int sen (atau issue); juga "Rp35.000,00" notifikasi
   - WalletMatcher       → walletId (atau issue)
   - CategoryMatcher     → categoryId (nama + alias bawaan; himpunan tertutup)
   - RelativeDateResolver (hari ini / kemarin)
   - validasi domain     → List<DraftIssue>
            │
            ▼
 RecordDraft + issues  ──►  openRecordSheet(draft: …)  (form CATAT terisi,
                                                        field bermasalah disorot)
            │  pengguna menekan Simpan
            ▼
 RecordBloc → record_transaction use case → TransactionRepository (tidak berubah)
```

Prinsip:
- **Interpreter = pengekstrak potongan (span extractor), bukan pembuat transaksi.**
  Outputnya teks yang dikutip dari transkrip; semua konversi angka dan pencocokan
  ID dilakukan resolver. Mengganti Gemma ↔ Firebase hanya mengganti satu kelas
  di DI; validasi tidak berubah.
- Tidak ada jalur dari interpreter ke repository.

---

## 3A. Sistem kategori (prasyarat, keputusan pemilik 30 Sep 2026)

Keputusan: daftar **bawaan + bisa diubah**, **datar**, **dipisah per jenis**,
label lama **dimigrasi**, **alias bawaan saja**. Ini perubahan model domain →
ADR-0026 dan pembaruan `DOMAIN_MODEL.md` (bagian Transaksi baris ~122 dan
"Daftar kategori transaksi" baris ~468) serta glosarium.

**Entitas** `Category` di `lib/shared/category/domain/category.dart` (zona
`shared` karena dipakai CATAT, Transaksi, dan kelak laporan):
| Field | Tipe | Catatan |
|---|---|---|
| `id` | `String` | stabil; bawaan memakai id tetap (`builtin.food`, …) agar alias & i18n bisa menempel |
| `kind` | `CategoryKind { expense, income }` | transfer tidak berkategori |
| `name` | `String?` | null = pakai nama i18n bawaan; terisi bila pengguna mengganti nama atau kategori buatan sendiri |
| `builtInKey` | `String?` | kunci kategori bawaan (untuk nama i18n & alias); null untuk buatan pengguna |
| `iconKey` | `String?` | opsional, ikut sistem ikon ADR-013/015 |
| `isArchived` | `bool` | diarsipkan, bukan dihapus (transaksi lama tetap menunjuk) |
| `sortOrder` | `int` | urutan di pemilih |

**Alias bawaan** (tidak disimpan, didefinisikan di kode
`lib/shared/category/domain/built_in_categories.dart`): tiap kategori bawaan
membawa daftar kata kunci id/en, mis. Makan & Minum ← makan, makan siang,
sarapan, ngopi, kopi, geprek, lunch, coffee; Transportasi ← bensin, ojek,
parkir, tol, grab, gojek; Tagihan ← listrik, air, PLN, internet, pulsa. Alias
dipakai `CategoryMatcher` (deterministik) dan dikirim ringkas ke model.

**Set bawaan** (disetujui pemilik 30 Sep 2026):
Pengeluaran — Makan & Minum, Belanja Harian, Transportasi, Tagihan, Pulsa &
Internet, Kesehatan, Hiburan, Belanja, Pendidikan, Keluarga, Donasi, Lainnya.
Pemasukan — Gaji, Freelance, Bonus, Hadiah, Lainnya.

**Transaksi:** `categoryKey: String?` diganti `categoryId: String?` pada
`IncomeTransaction` dan `ExpenseTransaction`; `TransferTransaction` tidak
memilikinya lagi.

**Penyimpanan:** satu dokumen Hive `categories` mengikuti tata letak ADR-0012;
`CategoryRepository` (`listCategories(kind)`, `save`, `archive`) dengan
`RepositoryGuard`; didaftarkan di `root_module.dart` sebagai lazy singleton.

**Migrasi sekali jalan** (penanda versi di `KeyValueStorage`; cek dulu apakah
ADR-0012 sudah punya pola migrasi):
1. Buat kategori bawaan bila belum ada.
2. Kumpulkan label unik per jenis dari seluruh transaksi.
3. Label yang cocok (nama/alias, tanpa beda huruf besar/spasi) ke kategori
   bawaan → pakai id bawaan; selainnya → kategori buatan pengguna baru.
4. Tulis `categoryId`, hapus `categoryKey`. Label pemasukan/pengeluaran tidak
   ada yang hilang.
5. Label pada transaksi **transfer**: **dibuang** (keputusan pemilik 30 Sep
   2026); `note` tidak diubah.

**UI:**
- Pemilih kategori di form CATAT (menggantikan `record_category_field.dart`
  teks bebas): chip kategori per jenis, urut terbaru dipakai
  (menggantikan peran `RecordDefaults.*Categories`), aksi "Tambah kategori"
  inline. Membuat kategori bukan membuat transaksi → tidak melanggar aturan 8.
- Layar "Kategori" (dari Akun): daftar per jenis, tambah, ganti nama, ikon,
  arsipkan, urutkan.
- Tampilan transaksi (`transaction_display.dart`, detail, filter di
  `transaction_bloc`) membaca nama lewat id; kategori terarsip tetap tampil.
- Pembayaran freelance diterima: kategori otomatis "Freelance" (bawaan) —
  usulan, bukan keharusan.

---

## 4. Riset STT on-device

### Perbandingan

| Kriteria | Pengenal sistem via `speech_to_text` | Whisper (whisper.cpp via `whisper_ggml`) | iOS 26 SpeechTranscriber | sherpa-onnx | Vosk / Moonshine / ML Kit GenAI Speech |
|---|---|---|---|---|---|
| Android | Ya (layanan Google) [V] | 21+ [V] | — | Ya [V] | Tidak ada id-ID [V] |
| iOS | Ya (SFSpeechRecognizer) [V] | 15.6+ [V] | iOS 26+ | Ya [V] | — |
| Integrasi Flutter | Matang, 7.5.0, csdcorp.com terverifikasi [V] | Baik, 2.6.0, MIT [V] | Tidak ada plugin | Paket resmi, uploader tak terverifikasi [V] | — |
| Offline | Sebagian: Android bila paket id-ID terpasang; iOS tidak diketahui [U] | Penuh [V] | Ya | Penuh | — |
| Bahasa Indonesia | Ya (mode server) [V]; offline tidak terjamin | WER FLEURS: tiny 51,7 · base 33,1 · small 16,3 · medium 10,2 [U, sekunder] | id_ID dilaporkan tidak ada [U] | Hanya lewat model Whisper | Tidak |
| Akurasi | Tidak ada data resmi id-ID [V absen] | Lihat WER; ucapan campur 27–41% WER (small) [U] | — | = Whisper | — |
| Latensi | Streaming, hasil parsial langsung [V] | Tidak ada benchmark ponsel kredibel [V absen]; small kemungkinan beberapa detik [E] | — | — | — |
| RAM | Rendah (proses sistem) | ~273 MB (tiny) – ~852 MB (small) [V] | Rendah | Mirip Whisper | — |
| Ukuran model | 0 (sistem) | 75 MB tiny · 142 MB base · 466 MB small [V] | 0 | Mirip Whisper | — |
| Baterai | Tidak diketahui; beban di layanan sistem | Tidak diketahui; lebih berat (inferensi penuh) [E] | — | — | — |
| Akselerasi HW | Diatur OS | Metal / CPU NEON [U] | Neural Engine [U] | CPU | — |
| Pemeliharaan | Aktif (rilis ±2 minggu lalu) [V] | Aktif (±2 bulan lalu) [V] | Apple | Sangat aktif | — |
| Kompleksitas dependensi | Rendah | Sedang (native lib, unduh model) | Tinggi (channel sendiri) | Sedang | — |
| Privasi | Mode server: audio ke Google/Apple | Penuh di perangkat | Di perangkat | Di perangkat | — |
| Kesiapan produksi | Tinggi | Sedang (ukuran, latensi) | Tidak untuk id-ID | Sedang | Tidak |

### Bukti & catatan
- Android: `RecognizerIntent.EXTRA_PREFER_OFFLINE` hanya petunjuk [V, AOSP];
  `createOnDeviceSpeechRecognizer()` API 31+ [U] melempar
  `UnsupportedOperationException` bila tidak tersedia [V];
  `checkRecognitionSupport`/`triggerModelDownload` API 33+ untuk memeriksa &
  mengunduh paket bahasa [V]. `EXTRA_BIASING_STRINGS` untuk bias frasa [V].
  Perangkat tanpa layanan Google (mis. Huawei) bisa tidak punya pengenal sama sekali.
- iOS: `supportsOnDeviceRecognition`/`requiresOnDeviceRecognition` sejak iOS 13
  [V]; Apple tidak mempublikasikan daftar locale on-device → cek saat runtime.
- `speech_to_text`: `SpeechListenOptions.onDevice`, `autoPunctuation`, `pauseFor`,
  `contextualPhrases` [V]; 7.6.0-beta menambah pengecekan dukungan offline [V].
  Dibuat untuk frasa pendek; Android berhenti ±5 detik hening [V] — cocok untuk
  satu transaksi per ucapan.
- **Format angka:** tidak ada bukti resmi apakah id-ID mengeluarkan "35.000",
  "35 ribu", atau "tiga puluh lima ribu" [V absen]. Anekdot: Google cenderung
  angka [U]. **Konsekuensi:** parser harus menerima semua bentuk.
- Campur kode (id+en, "top up GoPay"): satu studi melaporkan CER ±92% vs 4% untuk
  Indonesia murni [U, sekunder] — titik lemah; mitigasi: `contextualPhrases`
  berisi nama dompet pengguna + tahap review wajib.
- Nama dompet/kategori & kebisingan: tidak ada data resmi → masuk benchmark (§10).

**Rekomendasi STT:** pengenal sistem via `speech_to_text`, *prefer on-device*,
fallback server dengan izin eksplisit pengguna (lihat §14). Whisper sebagai
opsi unduhan belakangan untuk mode "offline ketat" setelah diukur.

---

## 5. Riset Gemma / LLM lokal

### Runtime
| Item | Status |
|---|---|
| MediaPipe LLM Inference | Maintenance-only; Google mengarahkan ke LiteRT-LM [V] |
| LiteRT-LM | C++/Python/Kotlin **Stable**, Swift **Early Preview**, Flutter **Community** [V]. Android CPU/GPU/NPU, iOS CPU/GPU [V]. Dekode terbatas (LLGuidance: JSON Schema/Regex/Lark) di C++ [V]; bug terbuka #3721 (EOS bisa muncul di dalam string JSON) [V] |
| `flutter_gemma` | 1.11.3, sashadenisov.dev (terverifikasi), MIT. Android/iOS/desktop/web. Engine LiteRT-LM (FFI), MediaPipe, ONNX. Unduh model dengan progres/retry, foreground service Android. iOS ≥15; LiteRT-LM Android butuh arm64. Function calling ada; **JSON schema/grammar tidak terdokumentasi** [V] |
| `llamadart` | 0.9.0, MIT, GGUF via llama.cpp + `.litertlm`; **JSON Schema → GBNF** (output terkekang) [V]; iOS ≥16.4 |

### Model
| Model | Ukuran file | Memori puncak | Kecepatan terpublikasi | Lisensi | Kesesuaian |
|---|---|---|---|---|---|
| Gemma 3 270M | ~0,3 GB [V] | – | GPU "WIP" [V] | Gemma Terms | Dirancang untuk fine-tuning ekstraksi [V]; tanpa FT tidak layak [E] |
| FunctionGemma 270M | 288 MB [V] | 551 MB [V] | S25 Ultra CPU: 1.718 prefill / 126 decode tok/s [V] | Gemma Terms | 58% tanpa FT, 85% dengan FT (tugas Mobile Actions) [V] |
| **Gemma 3 1B int4** | **529 MB** [V] | CPU ~1,0–1,2 GB [V] | S24 Ultra CPU 379/55, GPU 2.531/49 tok/s [V] | Gemma Terms | **Terkecil yang masuk akal tanpa FT** [E] |
| Gemma 3n E2B | – | – | S24 Ultra CPU 110/16 tok/s [V] | Gemma Terms | Lebih lambat dari 1B untuk tugas ini |
| Gemma 4 E2B | 2.583 MB [V] | 676 MB (GPU) – 1.733 MB (CPU) [V] | S26 Ultra GPU 3.808/52; iPhone 17 Pro GPU 2.878/56 tok/s [V] | **Apache 2.0** | Kualitas tertinggi yang realistis; unduhan terlalu besar untuk MVP |
| Gemma 4 E4B | 3,65 GB [V] | – | 1.293/22 tok/s [V] | Apache 2.0 | Berlebihan |

Bahasa Indonesia: Gemma 3 dilatih 140+ bahasa; Gemma 4 mengklaim 35+ bahasa
"out of the box"; **tidak ada kartu model yang menyebut Indonesia eksplisit** [U].
Semua angka kecepatan dari ponsel flagship — perangkat menengah belum diukur.

### Model OS (ditolak)
- Gemini Nano / ML Kit Prompt API: beta, hanya perangkat tertentu, bahasa yang
  divalidasi Inggris & Korea [V].
- Apple Foundation Models: daftar bahasa Apple Intelligence (14 Sep 2026)
  **tidak memuat Indonesia** [V].

### Kesimpulan: tangga model, mulai dari yang paling murah (keputusan pemilik 30 Sep 2026)
Hosting dan inferensi semua kandidat sama-sama Rp 0, jadi "murah" di sini
berarti unduhan, RAM, latensi, dan baterai terkecil. Model dicoba berurutan
dan naik satu anak tangga hanya bila gagal ambang benchmark (§10):

1. **Gemma 3 270M IT** (~0,3 GB, `flutter_gemma` .litertlm) tanpa fine-tuning.
   Google menyatakan model ini dirancang untuk di-fine-tune [V], jadi
   kemungkinan besar gagal — tetapi mengujinya murah dan memberi angka dasar.
2. **Gemma 3 1B int4** (529 MB) — terkecil yang masuk akal tanpa fine-tuning [E].
3. **Gemma 4 E2B** (2,6 GB, Apache 2.0) — hanya bila 1B gagal.

Cabang samping: bila dataset (§10) sudah ratusan–ribuan contoh, fine-tune
270M / FunctionGemma bisa kembali ke anak tangga 1 dengan akurasi lebih baik —
bukan MVP. Keduanya berlisensi Gemma Terms; repo 1B resmi gated [V], repo 270M
kemungkinan juga [U] → siapkan mirror HF publik milik pemilik (§6).

---

## 6. Optimasi sumber daya

**Ukuran APK/unduhan**
- Model **tidak dibundel**. Unduh saat pertama kali pengguna mengaktifkan
  "Pemahaman suara di perangkat" (opt-in), lewat Wi-Fi disarankan, dengan
  progres & bisa dibatalkan (fitur unduh `flutter_gemma` [V]).
- **Hosting di Hugging Face — Rp 0** (dicek ulang atas pertanyaan pemilik):
  - Penyimpanan repo **publik** gratis untuk akun Free ("best-effort", diminta
    dipakai secara bertanggung jawab) [V, https://huggingface.co/docs/hub/storage-limits].
    Satu model ±0,5 GB jauh di bawah skala yang dipersoalkan.
  - Dokumentasi Hub **tidak mencantumkan biaya bandwidth/unduhan**; berkas
    dilayani lewat CloudFront [V, sama]. Yang ada hanya batas laju: unduhan
    ("resolvers") anonim 3.000 permintaan / 5 menit **per alamat IP** [V,
    https://huggingface.co/docs/hub/rate-limits] — per perangkat, tidak relevan
    untuk satu unduhan per pengguna. Angka anonim "dapat berubah".
  - **Hambatan nyata:** `litert-community/Gemma3-1B-IT` *gated* — harus login
    dan menyetujui lisensi [V]; token HF tidak boleh ditanam di aplikasi. Jalan
    keluar: unggah salinan `.litertlm` ke repo publik milik pemilik, memenuhi
    Gemma Terms §3.1 [V]: sertakan batasan penggunaan §3.2 di syarat &
    ketentuan aplikasi (repo `tanukonomy-web`), berikan salinan Gemma Terms,
    tandai berkas yang dimodifikasi, dan sertakan berkas NOTICE ("Gemma is
    provided under and subject to the Gemma Terms of Use found at
    ai.google.dev/gemma/terms").
  - Alternatif tanpa urusan lisensi: `litert-community/gemma-4-E2B-it-litert-lm`
    **tidak gated, Apache 2.0** [V], tetapi 2.583 MB.
  - Risiko kecil: kebijakan "best-effort" bisa berubah → URL model disimpan di
    konfigurasi (bukan dikodekan keras) agar bisa dipindah ke host lain.
- Simpan `modelId + versi + sha256` di konfigurasi; verifikasi checksum; hapus
  versi lama setelah versi baru siap.
- Privasi: perangkat menghubungi `huggingface.co` saat mengunduh (IP terlihat);
  sebut di kebijakan privasi.

**RAM**
- Muat model *lazy* saat sheet suara dibuka pertama kali (sambil pengguna bicara
  = "warm-up" gratis); lepaskan saat sheet ditutup atau setelah 60 dtk idle [E].
- Konteks maksimal ±512 token, output maksimal ±96 token [E]; satu sesi, satu
  inferensi pada satu waktu (antrian ditolak, bukan ditumpuk).
- Inferensi native berjalan di luar thread UI (FFI/native) — tidak perlu isolate
  Dart tambahan kecuali benchmark menunjukkan jank [U].

**Latensi** [E dari angka V]
- Parser aturan: < 10 ms.
- Gemma 3 1B CPU flagship: prompt ±400 token / 379 tok/s ≈ 1,1 s + 60 token /
  55 tok/s ≈ 1,1 s → ≈ 2,2 s + waktu muat (belum diketahui). Perangkat menengah
  bisa 2–4× lebih lambat [E].
- Firebase flash-lite: round-trip jaringan, belum diukur.

**CPU/GPU/NPU**
- Android: GPU (OpenCL) bila tersedia, fallback CPU; NPU hanya pada SoC tertentu
  — jangan jadi syarat MVP. iOS: GPU (Metal); tidak ada NPU di LiteRT-LM [V].
- Pilih backend lewat opsi `flutter_gemma`, dengan fallback CPU bila init GPU gagal.

**Baterai**
- Angka pasti **tidak diketahui**. Satu-satunya data resmi: Gemma 3 270M INT4
  memakai 0,75% baterai untuk 25 percakapan di Pixel 9 Pro [V]. Untuk satu
  transaksi (±3 dtk STT + ±2 dtk inferensi) dampaknya diperkirakan kecil [E].
- Metodologi ukur: Android `dumpsys batterystats` / Perfetto power rails
  (Pixel), iOS Xcode Instruments Energy Log; 50 transaksi berturut-turut, layar
  menyala, bandingkan dengan baseline 50× form ketik.

**Siklus hidup model**
`tidak ada → mengunduh → terpasang(v) → dimuat → siap → dilepas`; dicatat di
`KeyValueStorage`. Gagal unduh/muat → fitur tetap jalan dengan parser aturan
(dan cloud bila diizinkan).

**Segmentasi perangkat (MVP, sederhana)**
Syarat LLM lokal: Android arm64 + API 26+ + RAM total ≥ 6 GB; iOS 16+ dengan
RAM ≥ 6 GB (iPhone 13 Pro/14 ke atas) [E]. Deteksi: arsitektur & versi OS pasti
bisa; RAM total di Android lewat `ActivityManager.MemoryInfo.totalMem`, di iOS
`ProcessInfo.physicalMemory` — ketersediaan di `device_info_plus` **belum
diverifikasi** [U], bisa lewat channel kecil. Selain itu jangan mengklasifikasi;
perangkat di bawah syarat → parser aturan (+ cloud bila diaktifkan).

---

## 7. Desain ekstraksi transaksi

### Input
Transkrip final (teks), bukan audio. Hasil parsial STT hanya untuk tampilan.

### Kontrak output interpreter (`InterpretedTransaction`)
Semua field opsional, semuanya **teks yang dikutip dari transkrip** kecuali `kind`:

```json
{
  "kind": "expense | income | transfer | null",
  "amount_text": "35 ribu",
  "wallet_text": "BCA",
  "to_wallet_text": null,
  "category": "Makan",
  "note": "makan siang",
  "date_text": "tadi"
}
```

Tidak ada `amount` numerik, tidak ada `confidence`, tidak ada `currency` dari
model. Mata uang selalu `ActiveCurrency` (ADR-025).

### Strategi prompt (LLM lokal & cloud)
- Instruksi sistem pendek, bahasa Indonesia, tugas tunggal "ekstrak field",
  larangan menambah informasi; `amount_text` wajib substring persis transkrip.
- 4–6 contoh few-shot (pengeluaran, pemasukan, transfer, tanpa dompet, ambigu).
- Temperatur 0 (atau top-k 1), output maksimal ±96 token, tanpa penalaran.
- Lokal: tanpa dukungan skema di `flutter_gemma` → minta JSON saja, parse,
  validasi, **satu** retry bila JSON rusak, lalu gagal ke parser aturan.
  Alternatif bila perlu skema keras: `llamadart` + GBNF (dievaluasi di Fase 3).
- Cloud: `responseMimeType: application/json` + `responseSchema` [V].

### Konteks ringkas
Dikirim: daftar nama dompet aktif (maks ±10, tanpa saldo), daftar kategori
aktif untuk jenis terkait (nama saja, maks ±20; model memilih **nama dari
daftar** atau null), tanggal hari ini. **Tidak dikirim:** saldo,
riwayat transaksi, ID internal, catatan lama. Pencocokan ke ID dilakukan
resolver, bukan model.

Deterministik (bukan LLM): nominal, mata uang, pencocokan dompet (nama +
normalisasi huruf kecil/spasi + jarak edit kecil), tanggal relatif
(hari ini/tadi/barusan/kemarin), batas nilai.

### Nominal aman (`SpokenAmountParser`, Dart murni)
Keluaran: `int` sen, dihitung dengan aritmetika bilangan bulat dari token.
| Masukan | Aturan | IDR (0 desimal) |
|---|---|---|
| `5k`, `5rb`, `5 ribu` | ×1.000 | 5.000 (satuan utama; sen = satuan × 100, ADR-025 §3.1) |
| `5 juta`, `5jt` | ×1.000.000 | 5.000.000 |
| `1,5 juta` | koma = desimal (locale id) → 1 + 5/10 juta, dihitung sebagai `15 × 100.000` | 1.500.000 |
| `1.500.000` | titik = pemisah ribuan | 1.500.000 |
| `5.000` | pemisah ribuan | 5.000 |
| `5,000` | **ambigu** di id (desimal) vs en (ribuan) → issue `ambiguousAmount` | – |
| `dua puluh lima ribu` | parser bilangan kata Indonesia (satu…sembilan, belas, puluh, ratus, ribu, juta, miliar; se-: seribu, sejuta, seratus) | 25.000 |
| `satu juta lima ratus ribu` | idem | 1.500.000 |
| `goceng`, `gocap`, `ceban` | kamus slang opsional (Fase 7, hanya bila muncul di benchmark) | – |

Kasus ambigu, **tidak boleh ditebak**:
- `beli dua kopi lima puluh ribu` → dua angka; ambil frasa bersatuan uang
  ("lima puluh ribu") sebagai nominal, "dua" dianggap kuantitas; bila ada >1
  frasa bersatuan (`kopi 25 ribu roti 15 ribu`) → issue `multipleAmounts`,
  nominal dikosongkan. Tidak ada penjumlahan otomatis.
- Angka tanpa satuan (`parkir 5`) → issue `amountWithoutUnit`, nominal dikosongkan.
- Mata uang lain disebut ("10 dolar") saat aplikasi IDR → issue `unsupportedCurrency`.

### Validasi (resolver, sama untuk semua penyedia)
| Kondisi | Tindakan |
|---|---|
| JSON rusak / field tak dikenal | buang; retry 1× (LLM) lalu parser aturan |
| `amount_text` bukan substring transkrip | abaikan (halusinasi), issue `amountMissing` |
| nominal hilang / ≤ 0 / tak terurai | field kosong + issue |
| nominal > batas wajar (mis. 10 miliar satuan) | issue `amountSuspicious` (tetap ditampilkan) |
| dompet tak cocok dengan dompet aktif | kosong + issue `unknownWallet` (tanpa buat dompet) |
| dompet tak disebut | kosong → form memakai dompet bawaan CATAT |
| transfer tanpa dua dompet berbeda | issue `transferIncomplete` |
| "top up <dompet>" | selalu **transfer**, `<dompet>` = tujuan; sumber hanya diisi bila disebut eksplisit ("dari BCA"). Tanpa sumber → issue `transferSourceMissing`, dan form **tidak** mengisi dompet bawaan untuk sumber — pengguna wajib memilih (keputusan pemilik) |
| jenis ambigu ("transfer uang", "bayar tagihan" tanpa nominal) | `kind` null → form menanyakan jenis |
| kategori | `CategoryMatcher`: nama/alias → id kategori aktif jenis yang sama. Nama dari model yang tidak ada di daftar (halusinasi) → dibuang, kategori kosong + issue `categoryUnknown`; tidak pernah membuat kategori baru otomatis |
| kategori pada transfer | dibuang (transfer tidak berkategori) |
| tanggal di masa depan | issue, pakai hari ini |

**Skor keyakinan dari model tidak dipakai.** Riset menunjukkan confidence yang
dinyatakan LLM cenderung overconfident (Xiong et al., ICLR 2024 [V]; Tian et al.
2023 [V]). "Yakin" didefinisikan deterministik: nominal terurai tunggal + jenis
terdeteksi + tidak ada issue blokir.

---

## 8. Lokal vs cloud di balik abstraksi yang sama

```dart
// lib/features/record/domain/capture/transaction_interpreter.dart (ilustrasi)
abstract interface class TransactionInterpreter {
  Future<Either<Failure, InterpretedTransaction>> interpret(
    CaptureEvidence evidence,      // sumber (suara/notifikasi/foto) + teks + waktu
    InterpretationContext context, // nama dompet, kategori, tanggal hari ini
  );
}
```

```text
TransactionInterpreter
  ├── RuleBasedTransactionInterpreter      (selalu ada, offline, gratis)
  ├── LocalLlmTransactionInterpreter       (flutter_gemma; nama tidak mengikat ke Gemma)
  ├── FirebaseAiTransactionInterpreter     (firebase_ai, googleAI()/vertexAI())
  └── CascadingTransactionInterpreter(primary, fallback, isConfident)
```

- Mengembalikan `Either` agar selaras ADR-0005, bukan melempar.
- Domain hanya mengenal `TransactionInterpreter`, `InterpretedTransaction`,
  `InterpretationContext`, `CaptureDraftResolver`, `RecordDraft`, `DraftIssue`.
- Pilihan implementasi di `RecordScope` berdasarkan setelan pengguna + kapabilitas
  perangkat; mengganti penyedia = satu baris registrasi DI.
- Firebase: paket `firebase_ai` 4.0.0 (pengganti `firebase_vertexai`) [V];
  `FirebaseAI.googleAI()` (Gemini Developer API) atau `.vertexAI()` (butuh
  billing) [V]; model `gemini-3.5-flash-lite` stabil, pensiun ≥ 21 Jul 2027 [V];
  **App Check wajib mulai 2 Nov 2026** [V] → tambahkan `firebase_app_check`.
  Hybrid on-device Firebase **tidak tersedia untuk Flutter** dan bahasa
  Indonesia tidak didukung Nano [V/U].
- Offline: adaptor cloud mengembalikan `Left(NetworkFailure)` → cascade ke
  parser aturan; UI tidak pernah buntu.
- Privasi cloud: yang terkirim hanya transkrip + nama dompet + daftar kategori
  (tanpa saldo). Wajib tier berbayar (tier gratis dipakai untuk pelatihan dan
  bisa dibaca peninjau manusia [V]).

---

## 9. Analisis biaya (skala awal)

Asumsi [E]: 100 pengguna aktif × 5 transaksi suara/hari × 30 hari = 15.000
panggilan/bulan; ±400 token input + ±60 token output per panggilan.

| Pos | A: STT + Gemma lokal | B: STT + Firebase AI | C: STT + lokal + cloud fallback |
|---|---|---|---|
| Inferensi | US$0 | 15.000 × (400×0,30 + 60×2,50)/1M ≈ **US$4/bln** [E, harga `gemini-3.5-flash-lite` V: $0,30 in / $2,50 out per 1M] | ≈ US$0–4, tergantung laju fallback |
| STT sistem | US$0 (ditanggung OS) [V] | US$0 | US$0 |
| Unduh model | **US$0** lewat repo publik Hugging Face (tanpa biaya bandwidth tercantum, storage publik gratis best-effort) [V]; 100 × 529 MB ≈ 53 GB bandwidth pengguna (kuota data mereka) | 0 | idem A |
| Infrastruktur | 0 | Blaze plan (bayar pakai) + App Check | keduanya |
| Kompleksitas dev | Tinggi (native runtime, unduh, device gating, lisensi) | Rendah–sedang | Tertinggi |
| Pemeliharaan | Versi model, runtime komunitas | Pensiun model, harga berubah | Keduanya |

Harga lain [V]: `gemini-3.1-flash-lite` $0,25/$1,50; `gemini-2.5-flash-lite`
$0,10/$0,40 (tidak ada di daftar model Firebase saat ini [U]). Batas laju tier
gratis hanya terlihat di AI Studio [V] — tidak diketahui.

**Pilihan: Opsi A** (keputusan pemilik; biaya operasional ≈ US$0). Parser aturan
tetap ada sebagai lapis pertama dan sebagai jalur perangkat yang tidak lolos
syarat model — biayanya nol dan resolver memang membutuhkannya. Opsi B/C
tetap mungkin lewat adaptor Fase 8 tanpa mengubah domain.

---

## 10. Strategi benchmark

### Dataset awal (teks; kolom harapan: kind, amount (satuan), wallet, category?, issue?)
Dompet uji: BCA, Cash/Tunai, GoPay. Mata uang IDR.

| # | Ucapan | Harapan |
|---|---|---|
| S1 | makan 25 ribu | expense 25.000 |
| S2 | parkir 5 ribu | expense 5.000 |
| S3 | gaji 10 juta | income 10.000.000 |
| N1 | tadi siang makan ayam geprek dua puluh lima ribu | expense 25.000, note "makan ayam geprek" |
| N2 | barusan beli kopi sebelum meeting | expense, nominal kosong + issue |
| N3 | makan siang tiga puluh lima ribu | expense 35.000 |
| N4 | tadi beli kopi dua puluh lima ribu | expense 25.000 |
| N5 | bayar listrik dua ratus lima puluh ribu | expense 250.000 |
| N6 | gaji masuk dua belas juta | income 12.000.000 |
| N7 | isi bensin seratus ribu | expense 100.000 |
| N8 | beli shampoo dan sabun total tujuh puluh dua ribu | expense 72.000 |
| W1 | makan 30 ribu pakai BCA | expense 30.000, BCA |
| W2 | ojek 15 ribu bayarnya cash | expense 15.000, Cash |
| W3 | gaji 12 juta masuk ke GoPay | income 12.000.000, GoPay |
| W4 | transfer lima ratus ribu dari BCA | transfer 500.000, dari BCA, tujuan kosong + issue |
| W5 | transfer 200 ribu dari BCA ke GoPay | transfer 200.000, BCA→GoPay |
| W6 | top up GoPay 100k | transfer 100.000 ke GoPay, sumber kosong + issue `transferSourceMissing` |
| W7 | top up GoPay 100 ribu dari BCA | transfer 100.000, BCA→GoPay |
| C1 | ngopi 25 ribu | expense 25.000, kategori Makan & Minum (lewat alias) |
| C2 | bayar PLN dua ratus ribu | expense 200.000, kategori Tagihan |
| A1 | tadi belanja | kind expense?, nominal kosong + issue |
| A2 | bayar tagihan | nominal kosong + issue |
| A3 | transfer uang | transfer, nominal & dompet kosong |
| A4 | beli dua kopi lima puluh ribu | expense 50.000 (bukan 100.000) |
| A5 | kopi 25 ribu roti 15 ribu | issue multipleAmounts |
| A6 | parkir 5 | issue amountWithoutUnit |
| M1..M7 | kopi 5k · kopi 25 ribu · 1 juta · 1,5 juta · 1.500.000 · dua puluh lima ribu · satu juta lima ratus ribu | 5.000 · 25.000 · 1.000.000 · 1.500.000 · 1.500.000 · 25.000 · 1.500.000 |
| M8 | kopi 5,000 | issue ambiguousAmount |
| X1 | coffee 25 ribu pakai BCA | expense 25.000, BCA |
| X2 | tadi ngopi 25k | expense 25.000 |
| X3 | dapat 10 dolar | issue unsupportedCurrency |
| D1 | kemarin makan 40 ribu | expense 40.000, tanggal kemarin |

Target ≥ 150 ucapan sebelum memutuskan LLM (dikembangkan dari pola di atas +
variasi slang pemilik dari `MANUAL_PROCESS_ANALYSIS.md`).

### Dua lapis pengujian
1. **Teks → draf** (unit test Dart, deterministik): mengukur parser & resolver,
   dan interpreter LLM dengan transkrip tetap. Jalan di CI untuk parser.
2. **Suara → transkrip** (manual, perangkat nyata): 30 ucapan direkam pemilik di
   ruang tenang + 10 di jalan/kafe; bandingkan transkrip pengenal sistem
   (online vs on-device) dan Whisper small bila dievaluasi.

### Metrik
Amount accuracy (tepat sen), transaction type accuracy, wallet accuracy,
category accuracy (cocok saran atau diterima pemilik), JSON validity (LLM),
**overall transaction accuracy** (semua field wajib benar tanpa edit),
issue precision (issue muncul bila memang ambigu), latensi p50/p95
(tekan-berhenti → form terbuka), RAM puncak (Android Studio Profiler / Xcode
Instruments), ukuran model, laju fallback.

Perangkat uji minimum: 1 Android menengah RAM 4–6 GB, 1 Android flagship,
1 iPhone lama yang didukung.

Ambang keputusan [E, usulan]: bila parser aturan ≥ 90% amount & type accuracy dan
LLM menaikkan overall accuracy < 10 poin, **tunda LLM**.

---

## 11. Cakupan MVP

**IN**
- Sistem kategori (§3A) — prasyarat.
- Tombol mikrofon di pemilih CATAT (satu titik masuk).
- STT sistem id-ID (`speech_to_text`), prefer on-device, fallback server, izin
  mikrofon/ucapan.
- `SpokenAmountParser`, `WalletMatcher`, `CategoryMatcher`, tanggal relatif
  hari ini/kemarin.
- `RuleBasedTransactionInterpreter` + `LocalLlmTransactionInterpreter`
  (model termurah yang lolos benchmark, unduhan opt-in dari HF, perangkat
  ≥ 6 GB RAM; syarat RAM bisa diturunkan bila 270M lolos) dalam
  `CascadingTransactionInterpreter`, di balik `TransactionInterpreter`.
- `CaptureDraftResolver` + `DraftIssue`.
- `RecordDraft` → form CATAT terisi; field bermasalah disorot; Simpan/Edit/Batal
  = perilaku form CATAT yang ada.
- Event analytics tanpa isi transkrip (berhasil/diubah/dibatalkan, jenis issue).
- Dataset benchmark teks + unit test.

**OUT (MVP)**
Asisten percakapan, klarifikasi multi-giliran, multi-transaksi per ucapan,
tautan pos anggaran otomatis, fine-tuning, RAG/vektor DB, backend orkestrasi,
Whisper, simpan audio, penyimpanan transkrip, kamus slang lengkap, UI edit
alias kategori, kategori bertingkat, kategori transfer.

**Sesudah MVP:** adaptor Firebase AI (Fase 8) bila benchmark menunjukkan Gemma
lokal tidak cukup; Gemma 4 E2B sebagai pilihan model lebih besar; fine-tune
270M bila dataset sudah besar.

---

## 12. Rencana implementasi

Semua path baru berada di `lib/features/record/` (fitur suara = mode input CATAT)
dan uji di `test/features/record/` mengikuti ADR-0010.

### Fase 0 — Riset / keputusan
- **Tujuan:** pemilik menjawab sisa §14; tulis ADR-0026 "Sistem kategori" dan
  ADR-0027 "Catat lewat suara: STT sistem + interpreter yang bisa diganti".
- **Berkas:** `docs/02-architecture/adr/0026-*.md`, `0027-*.md`, `DOMAIN_MODEL.md`,
  `PROJECT_GLOSSARY.md`, `TASK_LIST.md` (fase baru, mis. Fase 11, karena Fase 10
  dicadangkan untuk sinkronisasi B-7), `ROADMAP.md`, PRD (FR baru),
  `PLAY_DATA_SAFETY.md` (STT server = audio diproses Google/Apple).
- **Penerimaan:** kedua ADR Accepted, tugas tercatat, set kategori bawaan disetujui.

### Fase 1A — Sistem kategori
- **Tujuan:** entitas `Category`, repository, migrasi, pemilih di CATAT, layar
  kelola (§3A).
- **Berkas:** baru `lib/shared/category/{domain,data}/…`,
  `lib/features/category/` (layar kelola, bloc, scope) atau di bawah
  `features/account/` bila hanya dibuka dari Akun; ubah
  `lib/shared/transaction/domain/transaction.dart`, `transaction_model.dart`,
  `record_defaults.dart`, `record_category_field.dart`, form
  income/expense/transfer, `record_bloc/event`, `transaction_bloc/event`,
  `transaction_display.dart`, `transaction_detail_page.dart`,
  `open_edit_transaction_sheet.dart`, `root_module.dart`, i18n.
- **Langkah:** entitas + repo → migrasi dengan penanda versi → CATAT memakai
  pemilih → tampilan & filter memakai id → layar kelola.
- **Risiko:** migrasi data pengguna closed testing; label yang mirip tapi beda
  ejaan menjadi kategori ganda (bisa digabung pengguna lewat ganti nama/arsip —
  fitur gabung di luar cakupan).
- **Uji:** unit migrasi (label cocok bawaan, label unik, transfer berlabel,
  idempoten bila dijalankan dua kali); bloc_test pemilih; widget test layar kelola.
- **Penerimaan:** data closed testing termigrasi tanpa kehilangan; tidak ada
  referensi `categoryKey` tersisa; `flutter analyze` bersih; seluruh uji lulus.

### Fase 1 — Abstraksi domain
- **Tujuan:** tipe domain murni + resolver.
- **Berkas:** `lib/features/record/domain/capture/`
  (`transaction_interpreter.dart`, `interpreted_transaction.dart`,
  `interpretation_context.dart`, `voice_draft_resolver.dart`, `draft_issue.dart`),
  `lib/features/record/domain/record_draft.dart`,
  `lib/core/utils/formatters/spoken_amount_parser.dart` (bersebelahan dengan
  `money_input.dart`, bergantung `AppCurrency`).
- **Langkah:** definisikan tipe; implement parser nominal dengan aritmetika
  `int`; resolver memakai daftar `Wallet` dan `CategoryRepository` + alias
  bawaan.
- **Risiko:** parser bilangan kata Indonesia punya banyak kasus tepi.
- **Uji:** tabel §10 sebagai uji terparameter; properti: tidak ada `double`.
- **Penerimaan:** semua baris M1–M8, A4–A6 lulus; `flutter analyze` bersih.

### Fase 2 — STT
- **Tujuan:** transkrip id-ID dari mikrofon.
- **Berkas:** `pubspec.yaml` (`speech_to_text`; `permission_handler` hanya bila
  izin bawaan paket tidak cukup), `android/app/src/main/AndroidManifest.xml`
  (`RECORD_AUDIO`, `<queries>` untuk `RecognitionService`),
  `ios/Runner/Info.plist` (`NSMicrophoneUsageDescription`,
  `NSSpeechRecognitionUsageDescription`), `ios/Podfile` bila dibutuhkan,
  `lib/features/record/domain/capture/speech_transcriber.dart`,
  `lib/features/record/data/capture/system_speech_transcriber.dart`.
- **Langkah:** interface `SpeechTranscriber` (stream parsial + hasil final,
  `Either`); `contextualPhrases` = nama dompet + "ribu/juta/rb/k"; deteksi
  on-device, simpan pilihan "izinkan pengenalan online".
- **Dependensi:** STT server sudah disetujui pemilik. **Risiko:** perangkat tanpa layanan Google;
  batas hening Android; bunyi beep. Ingat memori: flutter tooling menulis ulang
  `minSdk = 23` — kembalikan sebelum commit.
- **Uji:** fake transcriber di unit test; uji manual 30 ucapan di perangkat.
- **Penerimaan:** transkrip muncul < 1 dtk setelah berhenti bicara [E target] di
  2 perangkat Android + 1 iPhone; izin ditolak → pesan i18n, tidak crash.

### Fase 3 — Integrasi model lokal
- **Tujuan:** `LocalLlmTransactionInterpreter` dengan model termurah yang lolos
  ambang (tangga §5: 270M → 1B → Gemma 4 E2B).
- **Berkas:** `pubspec.yaml` (`flutter_gemma`),
  `lib/features/record/data/capture/local_llm_transaction_interpreter.dart`,
  `.../model_download_repository.dart`, `lib/core/config/` (URL + sha256 model),
  layar setelan unduhan di Akun, layar Lisensi (NOTICE Gemma).
- **Langkah:** pemilik mengunggah salinan `.litertlm` + NOTICE + Gemma Terms ke
  repo HF publik miliknya (§6); unduh opt-in + checksum; muat lazy; lepaskan
  saat idle; gating perangkat (§6); fallback CPU. Spike awal 1–2 hari: jalankan
  dataset §10 (teks) lewat `flutter_gemma` di satu Android menengah, mulai dari
  Gemma 3 270M; naik ke 1B, lalu Gemma 4 E2B, hanya bila model sebelumnya gagal
  ambang (usulan: kategori & jenis ≥ 85% benar pada kasus yang tidak dapat
  diselesaikan parser, JSON valid ≥ 98%). Karena interpreter tidak bergantung
  pada model tertentu, mengganti model hanya mengganti URL + prompt di konfigurasi.
- **Risiko:** kepatuhan Gemma Terms saat mirror, memori iOS (entitlement virtual
  addressing untuk model besar [V]), runtime komunitas, bug #3721, kebijakan
  "best-effort" HF.
- **Uji:** integrasi di perangkat; unit test dengan fake runtime.
- **Penerimaan:** p95 < 4 dtk di perangkat menengah target [E], RAM puncak dicatat,
  aplikasi tidak di-kill OS.

### Fase 4 — Ekstraksi terstruktur
- **Tujuan:** prompt + parsing JSON + cascade.
- **Berkas:** `.../data/capture/prompt/transaction_extraction_prompt.dart`,
  `.../data/capture/cascading_transaction_interpreter.dart`.
- **Langkah:** prompt §7, temperatur 0, maks 96 token, 1 retry, verifikasi
  substring; cascade rule → LLM hanya bila tidak yakin.
- **Uji:** dataset §10 dengan transkrip tetap; JSON validity.
- **Penerimaan:** JSON validity ≥ 98% [E]; tidak ada nominal yang tidak ada di
  transkrip.

### Fase 5 — Validasi
- **Tujuan:** semua aturan §7 di `CaptureDraftResolver`.
- **Uji:** satu uji per baris tabel validasi; uji "provider-agnostik" (output
  interpreter palsu yang berhalusinasi dompet/nominal → ditolak).
- **Penerimaan:** tidak ada jalur dari interpreter ke repository (dicek review +
  uji bahwa resolver hanya mengembalikan draf).

### Fase 6 — UI
- **Tujuan:** sheet rekam + form CATAT terisi draf.
- **Berkas:** `lib/features/record/presentation/capture/voice_capture_sheet.dart`,
  `.../capture/bloc/voice_entry_{bloc,event,state,effect}.dart`,
  `open_record_sheet.dart` (parameter `RecordDraft? draft`),
  `expense_form_sheet.dart`/`income_form_sheet.dart`/`transfer_form_sheet.dart`
  (terima draf: catatan, kategori, tanggal; sorot issue),
  pemilih CATAT (tombol mic), `record_scope.dart` (registrasi),
  `assets/i18n/id.i18n.json` + `en.i18n.json`, `tourSteps` bila perlu sorotan tur
  (ADR-021).
- **Alur:** ketuk mic → "Mendengarkan…" (teks parsial tampil) → berhenti →
  "Memahami…" → form CATAT terisi → Simpan/ubah/Batal. Tidak ada layar pratinjau
  terpisah.
- **Risiko:** melanggar aturan 8 bila pratinjau dibuat sendiri — dihindari.
- **Uji:** bloc_test untuk `VoiceEntryBloc`; widget test form dengan draf.
- **Penerimaan:** dari berhenti bicara ke form terisi < 1 dtk (jalur aturan) [E];
  semua teks lewat i18n; bisa dipakai di 360dp.

### Fase 7 — Benchmark
- **Tujuan:** angka nyata untuk memutuskan Fase 3/8.
- **Berkas:** `test/features/record/capture/benchmark/voice_benchmark_cases.dart`
  (dataset), skrip/uji laporan akurasi; dokumen hasil di bagian baru dokumen ini.
- **Penerimaan:** laporan metrik §10 untuk parser aturan (wajib) dan LLM/cloud
  (bila dievaluasi), dengan rekomendasi lanjut/tunda.

### Fase 8 — Adaptor pivot cloud
- **Tujuan:** `FirebaseAiTransactionInterpreter`.
- **Berkas:** `pubspec.yaml` (`firebase_ai`, `firebase_app_check`),
  `lib/features/record/data/capture/firebase_ai_transaction_interpreter.dart`,
  `app_bootstrap_firebase.dart` (aktivasi App Check), setelan persetujuan di Akun,
  `PLAY_DATA_SAFETY.md`, kebijakan privasi di repo `tanukonomy-web`.
- **Langkah:** `responseSchema` sama dengan kontrak §7; timeout ±5 dtk; offline →
  `Left` → cascade; Blaze plan.
- **Uji:** fake `GenerativeModel`; uji manual jaringan mati.
- **Penerimaan:** mengganti registrasi DI dari lokal ke cloud tanpa mengubah
  berkas domain/presentasi.

Urutan kerja yang disarankan: **0 → 1A (kategori) → 1 → 2 → 5 → 6 (rilis
internal dengan parser saja) → 3 + 4 (Gemma lokal) → 7 (benchmark lengkap) →
8 hanya bila benchmark menunjukkan Gemma lokal tidak cukup.** Rilis bertahap
ini memberi nilai lebih awal tanpa menunggu model.

---

## 13. Risiko & mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| id-ID tidak tersedia offline di perangkat | Fitur butuh internet | Mode server dengan persetujuan; jalur ketik tetap utama |
| Transkrip angka tak konsisten (digit vs kata) | Nominal salah | Parser menerima semua bentuk; nominal selalu terlihat & bisa diedit |
| Campur kode id/en buruk | Dompet/kategori salah | `contextualPhrases` nama dompet; review wajib |
| LLM berhalusinasi nominal/dompet | Data salah | Kontrak span + verifikasi substring + pencocokan dompet tertutup |
| Model 529 MB+ membuat pengguna enggan | Adopsi rendah | Opt-in, parser tetap jalan tanpa model |
| Runtime komunitas (`flutter_gemma`) berhenti dirawat | Utang teknis | Terbungkus di satu adaptor; `llamadart` sebagai cadangan |
| Lisensi Gemma 3 (NOTICE, batasan) | Kepatuhan | Layar Lisensi; atau Gemma 4 (Apache 2.0) |
| Data keuangan ke cloud | Privasi, Data Safety | Tier berbayar, konteks minimal, persetujuan, formulir diperbarui |
| App Check wajib 2 Nov 2026 | Cloud gagal | Pasang App Check di Fase 8 |
| Melanggar aturan 8 | Arsitektur | Pratinjau = form CATAT |
| Kebijakan storage/bandwidth HF berubah | Unduhan gagal/berbayar | URL model di konfigurasi; bisa pindah host tanpa rilis ulang logika |
| Migrasi kategori merusak data closed testing | Kehilangan label | Migrasi idempoten, diuji, tidak menghapus apa pun sebelum `categoryId` tertulis |
| Kategori ganda hasil migrasi (ejaan berbeda) | Daftar berantakan | Pengguna mengarsipkan/ganti nama; fitur gabung menyusul bila perlu |

---

## 14. Pertanyaan terbuka (yang memblokir)

Sudah dijawab pemilik 30 Sep 2026: STT server **boleh**; **Opsi A**; **sistem
kategori** bawaan + bisa diubah, datar, per jenis, migrasi label, alias bawaan;
top-up = **transfer** dengan sumber wajib jelas.

Dijawab pemilik 30 Sep 2026 (putaran kedua): set kategori bawaan §3A
**disetujui**; label kategori pada transfer lama **dibuang**; model lokal
**mulai dari yang paling murah** (tangga §5: Gemma 3 270M → 1B → Gemma 4 E2B).

Tidak ada lagi pertanyaan yang memblokir. Keputusan berikutnya (model final)
ditentukan data spike Fase 3, bukan tebakan.

---

## 15. Rekomendasi teknis akhir

Yang dibangun pertama: **sistem kategori** (prasyarat), lalu **STT sistem
(`speech_to_text`, id-ID, prefer on-device, fallback server) + parser aturan
Dart + form CATAT terisi draf**, lalu **Gemma lokal via `flutter_gemma`**,
mulai dari model termurah yang lolos benchmark (270M → 1B → Gemma 4 E2B), sebagai
interpreter lokal (Opsi A), semuanya di balik `TransactionInterpreter`
dan `CaptureDraftResolver`. Alasannya:

- Kategori tertutup adalah syarat agar keluaran model bisa divalidasi; tanpa itu
  "kategori halusinasi" tidak bisa dibedakan dari label sah.
- Parser aturan menangani pola "aktivitas + nominal + (dompet)" dalam milidetik
  dan menjamin uang `int` sen; Gemma hanya dipanggil untuk sisanya, sehingga
  latensi & baterai rata-rata tetap rendah.
- Opsi A berbiaya operasional ≈ 0: STT ditanggung OS, model diunduh gratis dari
  repo publik Hugging Face, inferensi di perangkat.
- Abstraksi span-extractor membuat Firebase AI bisa dicolokkan kemudian tanpa
  mengubah domain, validasi, atau UI.

Jalur pivot: **`firebase_ai` + `gemini-3.5-flash-lite` + `responseSchema` +
App Check** pada tier berbayar.

### Matriks keputusan

| Keputusan | Opsi | Rekomendasi | Bukti | Risiko |
|---|---|---|---|---|
| STT | Sistem (`speech_to_text`), Whisper, SpeechTranscriber iOS 26, sherpa-onnx | Sistem, prefer on-device | 0 MB, matang, id-ID online [V]; Whisper 75–466 MB, latensi tak terukur [V] | Offline id-ID tidak terjamin [U] |
| Kategori | Teks bebas, daftar tetap, bawaan + bisa diubah | Bawaan + bisa diubah, datar, per jenis (pemilik) | Validasi keluaran model butuh himpunan tertutup | Migrasi data lama |
| LLM lokal | 270M/FunctionGemma, Gemma 3 1B, 3n E2B, Gemma 4 E2B | Tangga termurah: Gemma 3 270M → 1B int4 → Gemma 4 E2B (pemilik) | 270M butuh FT (58%→85%) [V]; 1B 529 MB [V]; E2B 2,58 GB [V] | Indonesia tidak terdokumentasi [U] |
| Hosting model | Bundel, Firebase Storage, Hugging Face publik | HF repo publik milik pemilik | Storage publik gratis, tanpa biaya bandwidth tercantum [V]; repo resmi gated [V] | Kebijakan best-effort; kepatuhan Gemma Terms |
| Runtime | LiteRT-LM via `flutter_gemma`, llama.cpp via `llamadart`, MediaPipe | `flutter_gemma` (.litertlm) | MediaPipe maintenance-only [V]; LiteRT-LM Flutter = komunitas [V] | Tanpa skema terkekang di Flutter [V] |
| Kuantisasi | int4, int8, campuran | int4 (1B), dynamic_int8 (270M) | Ukuran kartu model [V] | Kualitas int4 untuk id belum diukur |
| Pemuatan model | Bundel, unduh saat instal, unduh opt-in | Unduh opt-in + lazy load + unload idle | Ukuran ≥ 529 MB [V] | Hosting gated, egress [U] |
| Format output | JSON nilai final, JSON span, function calling | JSON span + resolver Dart | Mencegah nominal halusinasi; confidence LLM tak terkalibrasi [V] | Prompt harus disiplin |
| Cloud fallback | Tidak ada, Firebase AI (googleAI/vertexAI), backend sendiri | `firebase_ai`, tier berbayar, App Check | Harga & API [V]; App Check wajib 2 Nov 2026 [V] | Privasi, ketergantungan jaringan |

### Sumber utama
- speech_to_text: https://pub.dev/packages/speech_to_text ·
  SpeechListenOptions: https://pub.dev/documentation/speech_to_text/latest/speech_to_text/SpeechListenOptions-class.html
- Android RecognizerIntent/SpeechRecognizer (AOSP):
  https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/speech/
- Apple SFSpeechRecognizer: https://developer.apple.com/documentation/Speech/SFSpeechRecognizer/supportsOnDeviceRecognition ·
  SpeechTranscriber: https://developer.apple.com/documentation/speech/speechtranscriber
- whisper.cpp: https://github.com/ggml-org/whisper.cpp · whisper_ggml: https://pub.dev/packages/whisper_ggml
- sherpa-onnx: https://pub.dev/packages/sherpa_onnx · Vosk: https://alphacephei.com/vosk/models ·
  ML Kit GenAI Speech: https://developers.google.com/ml-kit/genai/speech-recognition/android
- LiteRT-LM: https://developers.google.com/edge/litert-lm/overview · https://github.com/google-ai-edge/LiteRT-LM ·
  constrained decoding: https://github.com/google-ai-edge/LiteRT-LM/blob/main/docs/api/cpp/constrained-decoding.md ·
  issue #3721: https://github.com/google-ai-edge/LiteRT-LM/issues/3721
- MediaPipe LLM Inference: https://ai.google.dev/edge/mediapipe/solutions/genai/llm_inference
- Gemma 3 270M: https://developers.googleblog.com/en/introducing-gemma-3-270m/ ·
  FunctionGemma: https://ai.google.dev/gemma/docs/functiongemma/model_card ·
  Gemma 3 1B: https://huggingface.co/litert-community/Gemma3-1B-IT ·
  Gemma 3n: https://huggingface.co/google/gemma-3n-E2B-it-litert-lm ·
  Gemma 4: https://developers.google.com/edge/litert-lm/models/gemma-4 · https://ai.google.dev/gemma/docs/core/model_card_4 ·
  Gemma Terms: https://ai.google.dev/gemma/terms
- flutter_gemma: https://pub.dev/packages/flutter_gemma · llamadart: https://pub.dev/packages/llamadart
- ML Kit Prompt API: https://developers.google.com/ml-kit/genai/prompt/android/get-started ·
  Apple Intelligence bahasa: https://support.apple.com/en-us/121115
- Firebase AI Logic structured output: https://firebase.google.com/docs/ai-logic/generate-structured-output?platform=flutter ·
  models: https://firebase.google.com/docs/ai-logic/models · firebase_ai: https://pub.dev/packages/firebase_ai ·
  hybrid Android: https://firebase.google.com/docs/ai-logic/hybrid/android/get-started
- Gemini pricing: https://ai.google.dev/gemini-api/docs/pricing · terms: https://ai.google.dev/gemini-api/terms ·
  rate limits: https://ai.google.dev/gemini-api/docs/rate-limits
- Hugging Face storage: https://huggingface.co/docs/hub/storage-limits ·
  rate limits: https://huggingface.co/docs/hub/rate-limits ·
  Gemma 3 1B (gated): https://huggingface.co/litert-community/Gemma3-1B-IT ·
  Gemma 4 E2B (tidak gated): https://huggingface.co/litert-community/gemma-4-E2B-it-litert-lm
- Kalibrasi: Tian et al. 2023 arXiv:2305.14975 · Xiong et al. ICLR 2024 arXiv:2306.13063
