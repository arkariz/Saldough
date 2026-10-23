# Monetisasi: hak Plus, uji coba terbalik, dan gerbang fitur

## 1. Metadata

- **Decision ID:** ADR-041
- **Tanggal:** 2026-10-23
- **Fase roadmap:** Plus tahap B (B-41, "Fondasi Plus")
- **Status:** Proposed (menunggu pemilik; keputusan yang diminta di §3.10)
- **Cakupan:** Modul baru `core/foundation/entitlement/`, fitur baru
  `features/premium/` (+ adaptor RevenueCat), glue akar komposisi
  (`lib/app/premium/`, `lib/app/di/root_module.dart`), gerbang di fitur yang
  sudah ada (`notification_capture`, `recurring`, `analysis`, `budget`,
  `freelance`, `plan`, `shared/capture`), tiga kunci penyimpanan baru yang
  didaftarkan ke `BackupRegistry` (ADR-040)

## 2. Konteks

[FREEMIUM_PAYWALL.md](../../01-product/features/FREEMIUM_PAYWALL.md) (§8, §9,
§10, §12, §15, §16) dan laporan bisnis pemilik
[Tanukonomy Plus: Rencana Bisnis dan Spesifikasi Kerja Paywall](https://claude.ai/artifact/SKsV87e4f7hX8h58Qvv7G5)
menetapkan *apa* yang gratis dan *apa* yang Plus, harga, panjang uji coba, dan
aturan keras (pencatatan manual tidak pernah digerbang; turun ke Gratis tidak
mengunci data; Plus yang luring tetap Plus). KT-P1–P18 sudah diputuskan pemilik
(18 dan 23 Okt 2026). Dokumen itu menyerahkan lima hal teknis ke ADR ini:
struktur kode, penyimpanan dan keadaan hak, perhitungan tanggal berakhir uji
coba, gerbang R3, dan pengelolaan offering/ID pengguna RevenueCat (KT-P6).

Keadaan kode yang relevan (diperiksa 23 Okt 2026 di `origin/main`, setelah
Fase 22):

- **Belum ada billing, hak, atau kuota apa pun.** `pubspec.yaml` tidak memuat
  `purchases_flutter`. Satu-satunya "gerbang" yang ada ialah status fitur
  `FeatureStatuses` (`core/discovery/`), yang menjawab *apakah izin sistem ada*,
  bukan *apakah pengguna berhak*.
- **Remote Config sudah dipakai**, tetapi hanya oleh `features/app_update`
  (`FirebaseRemoteConfigGateway`: nilai bawaan kosong, interval ambil 30 menit,
  hanya kunci berawalan `whats_new_`). `core` tidak boleh mengimpor fitur
  (ADR-030), jadi gateway itu tidak bisa dipakai ulang oleh port hak di `core`.
- **Progres onboarding hanya boolean.** `TutorialProgress.onboardingDone`
  tidak mencatat *kapan* onboarding selesai; uji coba (§8.1) butuh tanggal itu.
  Jalur pulihkan-saat-onboarding (T-22.5) juga menandai onboarding selesai
  (`markOnboardingDoneIfRestoring`), tanpa melewati langkah onboarding biasa.
- **Periode keuangan sudah berriwayat** (ADR-038): `financialPeriodOf(date,
  schedule)` satu-satunya cara menghitung periode; `FinancialMonthSchedule`
  disimpan sebagai riwayat berlaku-sejak.
- **Akun opsional** (ADR-023/024): `shared/auth` menyediakan identitas Firebase
  bila pengguna masuk; tanpa masuk, tidak ada ID pengguna.
- **Cadangan manual memuat seluruh kunci kecuali yang didaftarkan `exclude`**
  (ADR-040 §3.3); uji kelengkapan registri gagal bila ada kunci baru yang
  terlewat. Setiap kunci baru di ADR ini harus diputuskan masuk atau tidak.
- **Peristiwa Analytics** sudah memakai `restore_completed`
  (`DataPortabilityEvents`, Fase 22, dengan parameter `surface`), sedangkan
  laporan bisnis (bagian Untuk Engineer) memakai nama yang sama untuk
  *pemulihan pembelian*; daftar di FREEMIUM_PAYWALL §12.5 belum memuatnya. Dua arti pada satu nama akan merusak funnel.

## 3. Keputusan

Saldough menyimpan **satu keadaan paket** (`PlanState`) yang dihitung dari tiga
sumber: uji coba lokal, hak dari RevenueCat (pembelian Play atau hadiah), dan
tenggang luring. Fitur bertanya ke **satu port** (`Entitlements`) dan
**tidak pernah** ke RevenueCat langsung. Gerbang berada di presentasi atau
use case otomasi, **tidak pernah** di `RecordTransaction`.

### 3.1 Struktur kode (ADR-030)

```
lib/core/foundation/entitlement/
  entitlements.dart            port Entitlements (current, changes, can, tryUse)
  plan_state.dart              PlanState (sealed), PlanSource, TrialWindow
  plus_feature.dart            enum PlusFeature + titik gerbang
  entitlement_limits.dart      EntitlementLimits (nilai bawaan lokal)
  entitlement_config.dart      port EntitlementConfig (batas dari Remote Config)
  trial_rules.dart             trialEndsOn(start, schedule) murni
  entitlement_resolver.dart    resolvePlan(cache, trial, now, grace) murni
lib/features/premium/
  data/    revenuecat_entitlements.dart, firebase_entitlement_config.dart,
           entitlement_cache_store.dart, trial_store.dart, quota_store.dart
  domain/  paywall_trigger.dart (P1..P10), offering_policy.dart
  presentation/ paywall, layar hadiah, rekap nilai, layar turun, bloc
  navigation/premium_route_keys.dart, premium_route_module.dart
lib/app/premium/
  premium_wiring.dart          menyusun adaptor, menyuntikkan ID pengguna
```

- **`core/foundation/entitlement/` tidak mengimpor SDK maupun fitur.** Port
  `Entitlements` dan `EntitlementConfig` hidup di `core`; adaptor
  (`purchases_flutter`, `firebase_remote_config`) hidup di `features/premium/data/`
  dan didaftarkan akar komposisi. Fitur lain memakai `PremiumRouteKeys.paywall`
  dan `Entitlements` (impor dari `core`, bukan dari `features/premium`).
- `features/premium` **tidak** mengimpor fitur lain; fitur lain tidak
  mengimpornya selain lewat `premium_route_keys.dart` (aturan ADR-030 §3.3).
- `test/architecture/import_boundaries_test.dart` diperluas: (a)
  `core/foundation/entitlement/` tidak mengimpor `package:purchases_flutter`,
  `firebase_*`, atau `features/`; (b) tidak ada berkas di luar `lib/app/` dan
  `features/premium/data/` yang mengimpor `purchases_flutter`; (c)
  `lib/features/record/` dan `shared/transaction/` tidak mengimpor
  `entitlement/` (menjaga aturan "CATAT tidak punya cabang hak").

### 3.2 Keadaan paket: `PlanState`

```dart
sealed class PlanState {
  // Gratis: tidak ada hak aktif.
  Free();
  // Uji coba terbalik lokal; berlaku sampai [endsOn] (hari terakhir, inklusif).
  Trial({required DateTime endsOn});
  // Plus dari RevenueCat. [until] = akhir periode berbayar; [source] =
  // purchase | promotional. [inGrace] = Play melaporkan masa tenggang
  // pembayaran: tetap Plus.
  Plus({required DateTime until, required PlanSource source, bool inGrace});
  // Langganan ditahan (billing gagal, lewat masa tenggang Play): perilaku
  // Gratis, dengan ajakan memperbaiki pembayaran.
  OnHold({required DateTime since});
}
```

- `isPlus` = `Trial` | `Plus` (termasuk tenggang). `Free` dan `OnHold` tidak.
- **Prioritas** bila beberapa sumber ada: `Plus` mengalahkan `Trial`. Trial yang
  habis tidak dihitung ulang bila pengguna memasang ulang sesudah membeli.
- **Mulai berlangganan saat masih uji coba** langsung menjadi `Plus`; sisa
  uji coba tidak diperpanjang atau dikembalikan (harga perkenalan §3.5
  mengompensasinya).
- Masa tenggang dan "ditahan" **mengikuti status Play yang dilaporkan
  RevenueCat** (`CustomerInfo`/`EntitlementInfo.billingIssueDetectedAt`,
  `periodType`, `isActive`); aplikasi tidak menghitung sendiri. Bila langganan
  yang ditahan kemudian dibayar, RevenueCat melaporkan aktif lagi dan keadaan
  kembali `Plus` lewat jalan yang sama dengan pembelian baru; tidak ada cabang
  khusus.
- `PlanState` adalah nilai (`Equatable`), `changes` adalah `Stream<PlanState>`
  broadcast yang hanya memancar bila nilainya berubah.

### 3.3 Hak, cache, dan luring

- `Entitlements.current` mengembalikan hasil `resolvePlan(...)` (fungsi murni,
  mudah diuji) dari **tiga masukan**: `TrialRecord?` (§3.4), `CachedPlus?`
  (hak RevenueCat terakhir yang diketahui), dan `now`.
- **Cache hak** (`entitlement_cache`): `{schemaVersion, until, source, lastVerifiedAt}`
  ditulis setiap kali RevenueCat berhasil dibaca. **Tenggang luring 3 hari**
  dihitung dari `max(until, lastVerifiedAt)`: selama `now ≤ until` hak tetap
  berlaku **tanpa koneksi**; sesudah `until` tanpa bisa diverifikasi, hak
  tetap berlaku sampai `until + 3 hari`, lalu jatuh ke `Free`. Pengguna Plus
  yang luring tetap Plus (NFR-REL-001).
- **Gagal membaca hak tidak pernah menghalangi apa pun yang gratis.** Tidak
  ada kondisi galat yang membuat `current` melempar: bila adaptor gagal
  diinisialisasi, `current` dihitung dari cache dan uji coba.
- Penyegaran hak: saat aplikasi dibuka, saat kembali dari latar, dan sesudah
  pembelian. Tidak ada polling terus-menerus.
- Nilai uji `now` diinjeksi (`Clock`), seperti di `RestoreEngine`.

### 3.4 Uji coba terbalik (KT-P2)

`trial_rules.dart` (murni, tanpa Flutter):

```
trialEndsOn(DateTime start, FinancialMonthSchedule schedule, {int minDays = 14}):
  p     = financialPeriodOf(start, schedule)
  sisa  = hari dari start sampai p.end, keduanya dihitung (inklusif)
  return sisa >= minDays ? p.endDay : financialPeriodOf(p.end + 1 hari, schedule).endDay
```

- `start` = **tanggal onboarding selesai** (hari kalender setempat), bukan tanggal
  pasang. Onboarding wajib menjawab awal periode lebih dulu (Fase 21), sehingga
  `schedule` sudah menjadi pilihan pengguna saat uji coba dimulai.
- **Dihitung sekali dan disimpan** di `entitlement_trial`:
  `{schemaVersion, startedOn, endsOn}`. Perubahan `FinancialMonthSchedule`
  sesudahnya (termasuk periode peralihan 13–46 hari) **tidak** menghitung ulang.
- Plus berlaku sampai **rapor periode itu dibuka, paling lama `endsOn + 1 hari`**
  (hari tenggang untuk rapor). Sampai B-49 (rapor) ada, batas praktisnya
  `endsOn + 1 hari`; sebelum itu `Trial.endsOn` sama dengan `endsOn`.
- **Jalur pulihkan-saat-onboarding (T-22.5):** onboarding ditandai selesai oleh
  jurnal pemulihan, bukan oleh langkah penutup. Uji coba dimulai **di sana juga**
  (`markOnboardingDoneIfRestoring` memanggil `StartTrial`), memakai jadwal
  periode dari cadangan yang baru diterapkan. Pengguna yang hanya mengganti
  ponsel tidak kehilangan uji coba, tetapi juga tidak mendapat dua uji coba
  (lihat §3.9, soal pasang ulang).
- **Pemasangan ulang membuat uji coba baru.** Tanpa server sendiri, aplikasi tidak
  bisa mengenali pemasangan ulang. Risikonya diterima (§3.10, P-4): Plus tidak
  menyimpan data yang tidak ada di perangkat, jadi menyalahgunakan uji coba hanya
  membuka fitur berbiaya (Gemini) selama paling lama satu periode. Diukur lewat
  `trial_started` per ID anonim RevenueCat.

### 3.5 RevenueCat, Play, dan ID pengguna (KT-P6)

| Objek | Nilai |
|---|---|
| Entitlement | `plus` (satu-satunya hak) |
| Langganan Play | `plus` dengan base plan `monthly`, `yearly`, `yearly-founder` |
| Harga Pendiri | `yearly-founder` dinonaktifkan untuk pembelian baru sesudah 90 hari sejak rilis publik (pelanggan lama tetap diperpanjang) |
| Offer | `intro-first-year` pada `yearly` (KT-P12: harga perkenalan tahun pertama Rp129.000, lalu Rp179.000) |
| Offering | `default`, `founder`, `post_trial` |

- **Memilih offering** ada di `OfferingPolicy` (domain `premium`, murni):
  `founder` bila `now ≤ founder_until`, `post_trial` dalam 48 jam sesudah uji
  coba berakhir (`post_trial_offer_hours`), selain itu `default`. Harga
  ditampilkan **dari string harga toko** (`StoreProduct.priceString`), tidak ada
  harga di kode atau Remote Config.
- **ID pengguna:** anonim RevenueCat sejak pertama dibuka. Bila pengguna masuk
  akun (ADR-024), `Purchases.logIn(firebaseUid)`; keluar akun memanggil
  `Purchases.logOut()`. ID yang sama dipakai untuk hak promosi (hadiah penguji)
  dan pemulihan lintas perangkat. **Pemakaian tanpa akun tetap penuh**: Plus
  yang dibeli tanpa akun terikat ke akun Google Play lewat pemulihan pembelian
  (`restorePurchases`), bukan ke akun Tanukonomy.
- **Kunci SDK RevenueCat** (public SDK key Android) disuntikkan lewat
  `--dart-define=REVENUECAT_ANDROID_KEY=...` di CI dan build lokal. Kunci ini
  memang dirancang publik, tetapi tidak di-commit supaya mudah diganti per
  lingkungan; tanpa kunci, `Entitlements` jatuh ke uji coba lokal dan cache
  (tidak ada pembelian, tombol beli tidak tampil).
- **Hak promosi (hadiah penguji, KT-P5):** Plus 12 bulan lewat entitlement
  promosi RevenueCat diberikan ke ID pengguna; penguji yang **tidak masuk akun**
  tidak punya ID stabil. Jalurnya §3.10 P-1.

### 3.6 Batas dan jatah dari Remote Config

Port `EntitlementConfig` (di `core`) memberi `EntitlementLimits` bertipe;
adaptornya (`features/premium/data/FirebaseEntitlementConfig`) memakai
**instance Remote Config yang sama** dengan `app_update` tetapi **gateway
sendiri** (kunci berbeda, `getAll` difilter per awalan). Nilai bawaan hidup di
`EntitlementLimits.defaults` (kode), sehingga **tanpa koneksi atau Remote Config
gagal, nilai bawaan dipakai** (tidak pernah nol atau tak terbatas).

| Kunci | Bawaan | Arti |
|---|---|---|
| `free_notification_sources` | 1 | Aplikasi sumber notifikasi di Gratis |
| `free_smart_interpretations` | 30 | Tafsir Gemini per periode di Gratis, termasuk foto struk (KT-P14) |
| `taste_ask` / `taste_guardian` | 3 / 1 | Jatah cicip per periode |
| `free_analysis_periods` | 6 | Periode Analisis di Gratis |
| `free_budget_templates` / `free_active_projects` | 1 / 2 | Batas template dan proyek aktif |
| `plus_fair_use_interpretations` / `_photo` / `_ask` | 1000 / 150 / 300 | Batas wajar bulanan Plus, tidak ditampilkan |
| `paywall_max_per_day` / `paywall_max_per_period` | 1 / 3 | Batas frekuensi paywall kontekstual |
| `trial_min_days` | 14 | Sisa hari minimum periode berjalan |
| `founder_until` | tanggal | Akhir jendela Harga Pendiri |
| `post_trial_offer_hours` | 48 | Lama penawaran sesudah uji coba |

- Nilai tidak sah (negatif, bukan angka) diabaikan dan dipakai bawaannya.
- Perubahan Remote Config berlaku saat aplikasi berikutnya dibuka atau lewat
  `onConfigUpdated`; **tidak** memengaruhi uji coba yang sudah berjalan.
- Kunci ini adalah parameter biasa, **terpisah** dari `whats_new_*` yang
  disinkronkan `scripts/release_notes.js`. Skrip itu hanya menyentuh awalan
  `whats_new_`, sehingga kedua pemakai tidak saling menghapus.

### 3.7 Jatah cicip dan kuota (penyimpanan per periode)

- `Entitlements.tryUse(PlusFeature, {Clock})` mengembalikan `QuotaResult`
  (`allowed`, `remaining`, `exhausted`) dan **mencatat pemakaian** bila `allowed`.
- Pemakaian disimpan di `entitlement_quota`: `{schemaVersion, periodStart,
  used: {feature: n}}`. Dihitung per **periode keuangan** (`financialPeriodOf`);
  bergantinya periode mereset otomatis. Dengan riwayat jadwal (ADR-038),
  periode lampau tidak dihitung ulang.
- Pengguna **Plus/Trial** tidak dihitung jatah cicip, tetapi tetap dicek **batas
  wajar** (`plus_fair_use_*`) yang tidak ditampilkan kecuali tersentuh.
- **Kuota tafsir Gemini** (`free_smart_interpretations`) digerbang di port
  `shared/capture`, bukan di UI: sesudah habis, hanya parser aturan yang
  berjalan dan **tidak ada yang gagal** (Gratis tetap bisa mencatat).
- Pemakaian yang gagal (jaringan, galat) **tidak** menghabiskan jatah:
  `tryUse` dipanggil sesudah hasil berhasil, atau dikembalikan lewat
  `refund(feature)`.

### 3.8 Titik gerbang yang sudah ada

Satu pola: UI/use case otomasi memanggil `Entitlements`; bila `!can`, tampil
`PaywallTrigger` (tidak pernah mengubah data).

| Titik | Modul | Perilaku di Gratis | Trigger |
|---|---|---|---|
| Aplikasi sumber notifikasi ke-2 dst. | `notification_capture` | Paywall; aplikasi pertama tetap | P2 |
| Tingkat otomatis, pola baru | `notification_capture` | Kembali ke "tinjau semua"; pola lama tetap dipakai | P3 |
| Kuota tafsir Gemini | `shared/capture` (port) | Sesudah habis, parser aturan saja | P4 |
| Otomasi rutin R3 (Catat otomatis, belum terlihat, kenaikan harga dari notifikasi, menganggur, saran) | `recurring`, `notification_capture` | Rutin yang `autoRecord` kembali menunggu konfirmasi satu ketuk; label R3 tidak tampil; satu deteksi boleh jadi Contoh Penjaga | P1 |
| Analisis > 6 periode, tren 12 bulan | `analysis` | Tampilan buram + kartu; Riwayat tetap penuh | P6 |
| Template ke-2, proyek aktif ke-3 | `budget`, `freelance` | Yang ada tetap dipakai; membuat baru terhalang (proyek boleh jadi arsip) | P7 |
| Perkiraan lewat +2 bulan, Bagaimana kalau | `plan` | Kartu | P5 |

- **Gerbang R3 (ADR-037):** `RecurringRule.autoRecord` **tidak dihapus** saat
  turun ke Gratis; setelan disimpan untuk bila berlangganan lagi. Yang berubah
  adalah *penjalan otomasi*: `AutoRecordHost` (`features/recurring/presentation/host/`,
  ADR-037 §3.2) memeriksa `can(PlusFeature.recurringAutomation)` sebelum
  mencatat; bila tidak, kemunculan dibiarkan berstatus menunggu seolah
  `autoRecord == false` (kartu Menunggu, konfirmasi satu ketuk). Sakelar
  Catat otomatis di "Atur lebih lanjut" tetap tampil dengan label Plus dan
  membuka paywall P1; nilainya tidak ditulis ulang.
  Transaksi yang sudah tercatat otomatis tetap ada (data tidak dikunci).
- **Pengecualian aturan 8 tetap berlaku:** kemunculan rutin bernominal tetap
  yang dikonfirmasi pengguna satu ketuk memakai `RecordTransaction` di Gratis
  maupun Plus; tidak ada cabang hak di sana.
- Pemeriksaan hak **tidak boleh** dilakukan di `RecordTransaction`,
  `TransactionRepository`, atau layar CATAT. Uji arsitektur §3.1(c) menjaganya.

### 3.9 Turun ke Gratis, `restore`, dan data

- **Turun tidak menghapus atau mengunci data** (FREEMIUM_PAYWALL §10). Semua
  gerbang di §3.8 hanya mengubah *pekerjaan baru*; tidak ada penulisan yang
  dilakukan saat turun.
- **Pemulihan data (ADR-040) tidak menyalin hak.** Tiga kunci baru
  **ditandai `exclude`** di `BackupRegistry` dengan alasan:
  - `entitlement_trial` — tanggal uji coba milik pemasangan dan akun Play, bukan
    data pengguna; menyalinnya ke ponsel lain akan memperpanjang atau
    memulai ulang uji coba secara tidak sah.
  - `entitlement_cache` — hak tercantum pada akun Play/RevenueCat, bukan
    berkas; menyalin cache bisa memberi Plus ke ponsel yang tidak berhak.
  - `entitlement_quota` — jatah per periode milik perangkat; memulihkan tidak
    boleh mereset jatah.
- **Pulihkan pembelian** (`Purchases.restorePurchases`) adalah tindakan terpisah
  di layar Akun/paywall untuk memulihkan hak di ponsel baru; ia **tidak**
  terkait pemulihan data.

### 3.10 Keputusan yang diminta dari pemilik

| # | Hal | Rekomendasi |
|---|---|---|
| P-1 | Hadiah penguji (KT-P5, Plus 12 bulan) bagi yang **tidak masuk akun**: entitlement promosi RevenueCat butuh ID pengguna stabil | Dua jalur: yang masuk akun diberi entitlement promosi di dasbor RevenueCat; yang tidak masuk akun diberi **kode promo Play** (satu kode per penguji). Pemilik menyiapkan keduanya. |
| P-2 | Nama peristiwa pemulihan pembelian | Pakai `purchase_restored`; nama `restore_completed` sudah dipakai Fase 22 untuk pemulihan data. §12.5 FREEMIUM_PAYWALL menambahkan peristiwa ini; laporan bisnis pemilik perlu disesuaikan. |
| P-3 | Uji coba bagi yang menyelesaikan onboarding lewat pemulihan data | Mulai di pemulihan (§3.4), memakai jadwal periode dari cadangan. |
| P-4 | Pemasangan ulang membuat uji coba baru (tanpa server) | Terima risikonya, ukur lewat `trial_started`; kendalikan hanya bila terbukti merugikan. |
| P-5 | `plus_fair_use_*` memakai angka dokumen | Pakai bawaan dokumen; ukur biaya nyata sejak Plus dijual. |
| P-6 | Kunci SDK RevenueCat lewat `--dart-define` | Setuju; pemilik memberi kunci ke CI. |
| P-7 | Akun RevenueCat, langganan dan base plan di Play Console, offering | Pekerjaan pemilik; ADR ini hanya memberi nama objek (§3.5). |

### 3.11 Peristiwa Analytics (ADR-023: tanpa nominal, nama, atau isi)

`trial_started{days}`, `trial_moment{pillar}`, `trial_value_recap_shown`,
`trial_ended{outcome}`, `paywall_viewed{trigger}`, `paywall_dismissed{trigger}`,
`purchase_started{plan}`, `purchase_completed{plan}`, `purchase_failed{reason}`,
`purchase_restored`, `plus_feature_used{feature}`,
`taste_quota_exhausted{feature}`.

- `plan` ∈ `monthly | yearly | yearly_founder | yearly_intro`; `reason` ∈
  `cancelled | network | billing | other`; `trigger` ∈ `P1..P10`;
  `outcome` ∈ `purchased | lapsed`.
- Dikelompokkan di `PremiumEvents` (seperti `DataPortabilityEvents`) dengan uji
  parameter. `PLAY_DATA_SAFETY.md` diperbarui: **riwayat pembelian** dan ID
  pengguna dibaca/disimpan RevenueCat (penyedia pihak ketiga); kategori jawaban
  formulir (pembelian, ID perangkat atau lainnya) diperiksa terhadap formulir
  Play saat B-41 dikerjakan, bukan ditebak di sini. Kebijakan privasi situs
  (B-20) memuat RevenueCat.

## 4. Opsi yang dipertimbangkan

| Opsi | Ringkas |
|---|---|
| **A. `purchases_flutter` (RevenueCat) + port `Entitlements` (Dipilih)** | Verifikasi kuitansi di server RevenueCat tanpa backend sendiri; ID anonim cocok dengan akun opsional; siap iOS; hak promosi |
| B. `in_app_purchase` + Cloud Functions | Tanpa pihak ketiga, tetapi butuh Firebase Blaze (T-11.8), verifikasi kuitansi sendiri, dan tidak punya hak promosi |
| C. Hak sepenuhnya lokal (tanpa verifikasi server) | Paling sederhana; mudah dibobol dan tidak punya pemulihan lintas perangkat |
| D. Gerbang di `RecordTransaction` | Satu titik, tetapi melanggar aturan 8 dan bisa menghalangi pencatatan |
| **E. Gerbang di presentasi dan use case otomasi (Dipilih)** | Pencatatan manual bebas cabang hak |

## 5. Konsekuensi

### Opsi A — RevenueCat + port (Dipilih)

- (+) Verifikasi kuitansi dan status tenggang/tahan dilakukan RevenueCat; hak
  promosi untuk penguji; mudah ditukar adaptornya karena fitur hanya melihat
  `Entitlements`.
- (−) Ketergantungan pada pihak ketiga dan biaya (sumber berbeda: US$2.500 MTR
  lalu 1%, atau US$10.000; cek halaman harga resmi sebelum rilis berbayar).
- (−) Satu SDK baru (`purchases_flutter`) dan pembaruan Keamanan Data.

### Opsi B

- (+) Tanpa pihak ketiga. (−) Backend dan Blaze untuk satu fitur; tidak ada
  hak promosi.

### Opsi C

- (−) Tidak cocok untuk produk berbayar; ditolak.

### Opsi D

- (−) Melanggar aturan 8 dan NFR-REL-001; ditolak.

### Opsi E — Presentasi dan use case otomasi (Dipilih)

- (+) CATAT dan kemunculan rutin satu ketuk tidak pernah terhalang.
- (−) Setiap titik gerbang perlu uji widget sendiri; risiko ada titik yang
  terlewat ditutup daftar §3.8 dan uji per titik.

### Risiko

| Risiko | Mitigasi |
|---|---|
| Cache hak basi memberi Plus terlalu lama | Tenggang 3 hari dari `max(until, lastVerifiedAt)`; selewat itu `Free` |
| Hak gagal dibaca saat dibuka | `current` dihitung dari cache dan uji coba; tidak melempar |
| Salah menghitung `trialEndsOn` di periode peralihan | Fungsi murni diuji dengan jadwal berriwayat dan peralihan 13–46 hari |
| Uji coba disalahgunakan lewat pasang ulang | Diterima (P-4), diukur |
| Biaya Gemini melebihi pendapatan pemakai berat | Batas wajar; biaya nyata diukur |
| Titik gerbang terlewat | Daftar §3.8 + uji per titik + uji arsitektur |

## 6. Rencana verifikasi

- **Uji murni:** `trialEndsOn` (batas 13/14 hari, periode mulai tanggal 25,
  peralihan, akhir bulan); `resolvePlan` (uji coba, Plus, tenggang, ditahan,
  tenggang luring 3 hari persis, `until` dan `lastVerifiedAt`); `OfferingPolicy`
  (founder, post_trial 48 jam, default); `QuotaStore` (ganti periode, refund).
- **Uji adaptor:** `RevenueCatEntitlements` dengan SDK palsu (pembelian, tenggang,
  ditahan, pulihkan); `FirebaseEntitlementConfig` dengan nilai tidak sah dan
  Remote Config gagal.
- **Uji gerbang per titik** (§3.8): Gratis dan Plus; R3 mengembalikan ke
  konfirmasi satu ketuk **tanpa mengubah `autoRecord`**; CATAT tidak punya
  cabang hak.
- **Uji arsitektur:** §3.1(a)–(c); uji kelengkapan registri (tiga kunci
  `exclude` beserta alasannya).
- **Uji bolak-balik:** pulihkan data **tidak** mengubah `entitlement_*`.
- **Perangkat (QA/pemilik, jalur uji Play):** pembelian bulanan dan tahunan,
  uji coba berakhir, penawaran 48 jam, tenggang dan ditahan (angka perpanjangan
  dipercepat di Play), mode pesawat, pulihkan pembelian di ponsel kedua.

## 7. Tidak dikerjakan di ADR ini

- Fitur Plus baru (Penjaga B-44, Catat dari foto B-45, Bagaimana kalau B-46):
  ADR sendiri bila ada keputusan teknis baru.
- iOS (StoreKit lewat RevenueCat): struktur siap, belum diverifikasi.
- Plus Keluarga dan Dompet Bersama (B-60), cadangan otomatis (B-51), kosmetik
  (B-56).
- Eksperimen harga di Play; harga tetap hipotesis yang disetel lewat Remote
  Config dan Play.

## 8. Rujukan

- [FREEMIUM_PAYWALL.md](../../01-product/features/FREEMIUM_PAYWALL.md) §8–§12,
  §15–§16
- [Tanukonomy Plus: Rencana Bisnis dan Spesifikasi Kerja Paywall](https://claude.ai/artifact/SKsV87e4f7hX8h58Qvv7G5)
- [ADR-023](0023-identitas-opsional-firebase-auth-analitik-crashlytics.md),
  [ADR-024](0024-kepemilikan-data-lokal-dan-akun.md),
  [ADR-030](0030-batas-antarfitur-rute-bertipe-dan-sinyal-buku-besar.md),
  [ADR-037](0037-otomasi-rutin-r3.md),
  [ADR-038](0038-periode-keuangan-berriwayat-dan-peralihan.md),
  [ADR-039](0039-pengumuman-pembaruan-play-shorebird-dan-catatan.md),
  [ADR-040](0040-ekspor-cadangan-dan-pemulihan-manual.md)
