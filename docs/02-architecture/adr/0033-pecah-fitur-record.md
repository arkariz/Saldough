# Pecah fitur `record`: mesin tafsir di `shared/capture`, suara dan notifikasi jadi fitur sendiri

## 1. Metadata

- **Decision ID:** ADR-033
- **Tanggal:** 2026-10-01
- **Fase roadmap:** Fase 13 (pecah fitur `record`), T-13.1 s.d. T-13.6
- **Status:** Accepted (pemilik meminta audit dan pengerjaannya 1 Okt 2026)
- **Cakupan:** `lib/features/record/`, modul baru `lib/shared/capture/`,
  fitur baru `lib/features/voice_capture/` dan
  `lib/features/notification_capture/`, `lib/app/` (pemasangan),
  pemakai kunci rute (`account`, shell)
- **Bergantung pada:** ADR-0009 (zona `shared/`), ADR-027/029 (mesin tafsir
  Catat Cerdas), ADR-030 (kunci rute, batas impor), ADR-032 (catat dari
  notifikasi)
- **Mengubah:** cakupan folder di ADR-027 §3, ADR-029, dan ADR-032 §1;
  kunci `record.voice`, `record.notificationSettings`, dan
  `record.captureInbox` di ADR-030 §3.3

## 2. Konteks

Audit 1 Okt 2026: `features/record` berisi 77 berkas, 11.249 baris, kira-kira
sepertiga `lib/`. Isinya empat tanggung jawab:

| Bagian | Baris | Isi |
|---|---|---|
| CATAT | 2.749 | formulir, `RecordBloc`, `record_defaults`, sunting transaksi |
| Mesin tafsir | 2.364 | bukti, interpreter aturan/Gemini, resolver, penyusun draf, paket bahasa, parser angka/tanggal |
| Suara | 1.037 | transkriptor, `VoiceCaptureBloc`, lembar suara, pilih bahasa ucapan |
| Notifikasi | 4.769 | domain, data, 4 halaman, 2 bloc, host shell, DI (+698 baris Kotlin) |

Peta impor menunjukkan ketiga bagian di luar CATAT **sudah terpisah secara
alami**:

- notifikasi → mesin tafsir: 26 impor; notifikasi → CATAT: 0 (CATAT dibuka
  lewat `RecordRouteKeys.sheet` + `RecordDraft`);
- CATAT → mesin tafsir: hanya `RecordDraft` dan `DraftKind`;
- suara → CATAT: `openRecordSheet` dan `RecordBloc`.

Yang menyatukan mereka hanya folder. Akibatnya:

1. **R1** `RecordBloc` menyimpan `voiceCaptureFactory` dan
   `speechLanguagePrompt` hanya supaya alur suara bisa mengambilnya: bloc
   formulir jadi tempat titip dependensi fitur lain.
2. **R2** Kode notifikasi tersebar: `notification_rule_interpreter.dart` di
   `data/capture/`, gateway/store di `data/capture/notification/`, domain 15
   berkas datar yang mencampur entitas, port, kebijakan, dan use case.
3. **R3** `process_captured_notifications.dart` berisi dua use case; susunan
   "pola pengguna + pola bawaan aktif" dan "dompet aktif" ditulis dua kali.
4. Uji batas impor (ADR-030 §3.8) hanya menjaga batas **antarfitur**. Selama
   tiga bagian ini satu fitur, notifikasi bebas mengimpor isi CATAT dan
   sebaliknya; batasnya tidak dijaga mesin.

## 3. Keputusan

### 3.1 Mesin tafsir ke `shared/capture/`

Dipakai tiga fitur (CATAT lewat `RecordDraft`, suara, notifikasi), jadi
memenuhi syarat `shared/` ADR-0009:

```
lib/shared/capture/
├── capture.dart          # barrel
├── domain/               # capture_evidence, interpreted_transaction, record_draft,
│                         # transaction_interpreter, capture_draft_resolver,
│                         # capture_draft_composer, number_lexicon, spoken_*_parser,
│                         # language/ (paket bahasa, termasuk leksikon notifikasi)
└── data/                 # rule_based_transaction_interpreter,
                          # firebase_ai_transaction_interpreter
```

Tanpa `presentation/`. Pemakai mengimpor barrel `capture.dart` (aturan
barrel ADR-030 §3.8).

### 3.2 Fitur `voice_capture`

```
lib/features/voice_capture/
├── domain/speech_transcriber.dart
├── data/system_speech_transcriber.dart
├── presentation/  bloc/, voice_capture_sheet, speech_language_sheet,
│                  open_voice_capture, navigation/ (kunci + modul rute)
└── di/voice_capture_scope.dart
```

- Kunci `VoiceCaptureRouteKeys.capture` (`voiceCapture.capture`) menggantikan
  `record.voice`. Rutenya alur transparan yang memasang
  `VoiceCaptureScope` sendiri, lalu membuka CATAT lewat
  `RecordRouteKeys.sheet` dengan draf.
- `RecordBloc` tidak lagi punya `voiceCaptureFactory` maupun
  `speechLanguagePrompt` (R1).

### 3.3 Fitur `notification_capture`

```
lib/features/notification_capture/
├── domain/
│   ├── entities/   captured_notification, notification_source, settings,
│   │               pattern, capture_inbox_entry
│   ├── services/   notification_text, notification_template, auto_record_policy,
│   │               built_in_notification_patterns, notification_draft_composer,
│   │               transaction_from_draft, capture_inbox_changes
│   ├── ports/      notification_capture_gateway, notification_capture_store
│   └── usecases/   process_captured_notifications, capture_inbox_actions
├── data/           method_channel_notification_capture_gateway,
│                   notification_capture_store_impl, notification_rule_interpreter
├── presentation/   bloc/, pages/, widgets/, host/, navigation/
└── di/             notification_capture_module, notification_capture_scope
```

- Kunci `NotificationCaptureRouteKeys.settings` dan `.inbox`
  (`notificationCapture.settings`, `notificationCapture.inbox`) menggantikan
  `record.notificationSettings` dan `record.captureInbox`.
- CATAT dibuka lewat `RecordRouteKeys.sheet` + `RecordSheetInput(draft:)`;
  pencatatan otomatis lewat `RecordTransaction` (`shared/transaction`).
- `NotificationCaptureModule` tetap terdaftar di kontainer akar (pengecualian
  yang disengaja): pemrosesan dipicu shell dan siklus hidup aplikasi, bukan
  satu layar. Host dan banner shell diimpor `lib/app/`, yang memang akar
  komposisi.

### 3.4 `features/record` tinggal CATAT

`domain/record_defaults.dart`, bloc, formulir, sunting transaksi, kunci dan
modul rute (`sheet`, `edit`). `RecordSheetInput.draft` bertipe
`RecordDraft` dari `shared/capture`.

### 3.5 Urutan pengerjaan

Perbaikan penangkap notifikasi (revisi ADR-032, T-13.1) dikerjakan lebih
dulu karena menyangkut data pengguna. Pemindahan berkas (T-13.2–13.4)
mekanis: hanya jalur impor dan nama kunci rute yang berubah; satu uji lama
yang gagal adalah tanda perilaku ikut berubah. Pelepasan R1 dan perapian R2/R3
menyusul sesudah berkas berada di tempatnya.

## 4. Akibat

- Uji batas impor otomatis menjaga ketiga fitur hanya bicara lewat kunci rute
  dan `shared/`.
- `features/record` turun dari 11,2 rb ke ±2,9 rb baris.
- Kunci rute lama berubah nama; tidak ada tautan dalam (*deep link*) atau data
  tersimpan yang memakai nama kunci, jadi tanpa migrasi.
- Nama kunci penyimpanan (`settings/notification_capture`, `capture/*`)
  **tidak berubah**.

## 5. Alternatif yang ditolak

- **Hanya merapikan subfolder di dalam `record`.** Batasnya tetap tidak
  dijaga mesin, dan `RecordBloc` tetap jadi tempat titip.
- **Mesin tafsir sebagai fitur sendiri.** Fitur hanya boleh dibuka lewat kunci
  rute; mesin tafsir adalah pustaka domain tanpa layar, tempatnya `shared/`.
