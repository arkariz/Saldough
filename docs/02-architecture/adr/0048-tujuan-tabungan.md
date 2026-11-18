# Tujuan tabungan: rencana yang membaca saldo dompet tertaut

## 1. Metadata

- **Decision ID:** ADR-048
- **Tanggal:** 2026-11-17
- **Fase roadmap:** Fase 30 (B-96, lihat TASK_LIST)
- **Status:** Accepted (17 Nov 2026); Revisi 1 Accepted 17 Nov 2026 (§8: dompet
  milik tujuan, hanya transfer, hapus menghapus semuanya)
- **Cakupan:** `shared/savings_goal` (baru: entitas, repositori, use case,
  tampilan bersama), `features/savings_goal` (baru: layar), `features/wallet`
  (bagian Tujuan di tab Dompet, lencana dompet tabungan, putus tautan saat
  dompet dihapus), `features/premium` (P11), `features/data_portability`
  (cadangan, ekspor), `core/foundation/entitlement` (batas)
- **Bergantung pada:** ADR-012, ADR-030, ADR-038, ADR-040, ADR-041, ADR-047
- **Rancangan produk:** [WEALTH_ASSETS.md](../../01-product/features/WEALTH_ASSETS.md)
  §4 dan §10; PRD FR-AST-001; [FREEMIUM_PAYWALL.md](../../01-product/features/FREEMIUM_PAYWALL.md)
  P11 dan §10

## 2. Konteks

Pemilik memutuskan (17 Nov 2026) bahwa **tabungan adalah dompet yang
terhubung ke tujuan**: kemajuan dibaca dari saldo dompet itu, tanpa alokasi
virtual dan tanpa "saldo bebas". Satu tujuan boleh banyak dompet, satu dompet
hanya untuk satu tujuan. Menabung memakai transfer yang sudah ada. Gratis
2 tujuan Active, Plus tanpa batas; perkiraan tanggal tercapai dan peringatan
meleset adalah Plus. Dompet tidak punya jenis (T-30.0); peran dompet tabungan
hanya berasal dari tautan ini.

Aturan 5 berlaku penuh: tujuan adalah **rencana**, tidak pernah mengubah saldo
mana pun.

## 3. Keputusan

### 3.1 Entitas

```dart
final class SavingsGoal {
  final String id;
  final String name;            // data pengguna, tidak lewat i18n
  final int targetAmount;       // sen, > 0
  final String iconKey;         // dari categoryIconChoices (pemilih yang sama)
  final DateTime? targetDate;   // hanya penanda (T-6)
  final String? description;
  final SavingsGoalStatus status; // active | completed | archived
  final List<String> walletIds;   // sumber tunggal tautan, urut dipilih
  final DateTime createdAt;
  final DateTime? completedAt;
}
```

- **Tautan disimpan di tujuan**, bukan di `Wallet`. `Wallet` tidak berubah
  bentuk, sehingga tidak ada migrasi dompet dan cadangan dompet tetap.
- Ikon tujuan dipilih dengan pemilih yang sama dengan kategori dan dompet
  (ubin 48dp tanpa label).
- Tidak ada field turunan (terkumpul, persen) yang disimpan.

### 3.2 Hitungan

- `collected = Σ currentBalance` dompet di `walletIds` yang masih ada,
  **termasuk saldo awal** (T-2) dan **dompet nonaktif** (kasus tepi §4.3).
  Id dompet yang sudah tidak ada diabaikan.
- `remaining = max(0, targetAmount − collected)`.
- Persen tampil = `clamp(collected, 0, ∞) × 100 ~/ targetAmount`, hanya saat
  ditampilkan. Saldo negatif tampil 0%.
- Saldo memakai cache `currentBalance` (ADR-012), yang sudah dijaga
  `RecomputeWalletBalances`; penyesuaian saldo (ADR-047) ikut di dalamnya.

### 3.3 Invarian dan use case

Semua aturan ditegakkan di use case `shared/savings_goal`, bukan di widget:

| Use case | Aturan |
|---|---|
| `SaveSavingsGoal` (buat/sunting) | Nama tidak kosong; target > 0; **satu dompet maksimal satu tujuan, apa pun statusnya** (T-3), dicek terhadap semua tujuan lain; dompet yang tidak ada ditolak. Bila target diturunkan sampai ≤ terkumpul, status Active menjadi Completed. |
| `SyncSavingsGoalStatus` | Dipanggil saat `LedgerChanges` atau sesudah simpan: tujuan **Active** dengan terkumpul ≥ target menjadi **Completed** (`completedAt` = sekarang). Mengembalikan daftar yang baru tercapai untuk umpan balik dan analitik. **Completed tidak kembali ke Active otomatis** bila saldo turun (§6.1). |
| `ArchiveSavingsGoal` / `ReactivateSavingsGoal` | Arsip dari Active atau Completed. Mengaktifkan lagi menjadi Active, atau langsung Completed bila sudah tercapai. Tunduk batas (§3.5). |
| `DeleteSavingsGoal` | Menghapus tujuan dan tautannya; saldo tidak tersentuh (T-1). |
| `UnlinkWallet` | Dipanggil `WalletBloc` sebelum dompet dihapus (dompet hanya bisa dihapus bila tanpa transaksi), supaya rujukan cadangan tetap sah. |

Menghubungkan, memutus, mengarsipkan, atau menghapus tujuan tidak pernah
memanggil `RecordTransaction` atau mengubah dompet.

Tujuan yang **diarsipkan tetap memegang dompetnya** (invarian satu dompet satu
tujuan tidak punya pengecualian). Pemilih dompet menampilkan dompet itu sebagai
terhubung ke tujuan yang diarsipkan; untuk memakainya, putus dulu dari tujuan
itu. Untuk Total aset (B-98), hanya tujuan Active dan Completed yang membuat
dompet terhitung sebagai dompet tabungan.

### 3.4 Penyimpanan, cadangan, ekspor

- Kunci `savings_goal_all` (`StorageKey('savings_goal', 'all')`), dokumen
  `{schemaVersion: 1, items}`, `RepositoryGuard`, mengikuti
  `RecurringRuleRepositoryImpl`.
- `BackupRegistry`: `include` `savings_goal_all` (`supportedSchema: 1`), dan
  `BackupReference(from: 'savings_goal_all', fields: ['walletIds'],
  target: 'wallet_all')`. Pemeriksaan rujukan harus mendukung field berisi
  daftar; bila belum, diperluas dengan uji.
- Draf formulir yang tertahan paywall: `savings_goal_draft`, `exclude` dengan
  alasan "draf formulir milik perangkat".
- Ekspor: lembar **Tujuan** (Nama, Target, Terkumpul, Status, Target tanggal,
  Dompet), dihitung saat ekspor.

### 3.5 Batas Gratis dan P11

- `EntitlementLimits.freeSavingsGoals` (bawaan 2, Remote Config
  `free_savings_goals`). Yang dihitung hanya status **Active** (keputusan 4b).
- Pemeriksaan di **saat menyimpan**, bukan saat membuka formulir: pengguna
  Gratis dengan ≥ batas tujuan Active yang menekan Simpan untuk tujuan baru
  (atau Aktifkan lagi) menyimpan isian sebagai draf, lalu membuka paywall
  `PaywallTrigger.savingsGoalLimit` (P11, teks FREEMIUM §9). "Nanti saja"
  menutup paywall; draf dibuka lagi saat Buat tujuan berikutnya, sampai
  disimpan atau dibuang. Tujuan yang sudah ada tidak pernah terhambat.
- Plus berakhir (FREEMIUM §10): tidak ada yang diarsipkan otomatis; semua
  tujuan tetap bisa dilihat, diedit, dan terus mengikuti saldo; membuat atau
  mengaktifkan lagi tertahan selama Active ≥ batas.

### 3.6 Perkiraan tanggal tercapai (Plus)

Dua baris, keduanya berlabel **perkiraan** (keputusan pemilik 17 Nov 2026:
"dari keduanya"):

1. **Dengan laju sekarang** (utama), dari laju tabungan nyata dompet tertaut:
   `rata-rata = (Σ netto dompet tertaut pada 3 periode keuangan lengkap
   terakhir) ÷ 3`, dengan netto = pemasukan + transfer masuk − pengeluaran −
   transfer keluar pada dompet itu. Transfer antardompet tertaut dalam tujuan
   yang sama saling menghapus. Penyesuaian saldo **tidak** dihitung, karena
   koreksi bukan laju menabung. Periode memakai `financialPeriodOf`.
2. **Bila uang nganggur ikut ditabung** (skenario), dari rata-rata sisa uang
   nganggur (`MonthPlan.remaining`) 3 periode lengkap terakhir, **ditambahkan**
   ke laju di butir 1. Ini pengandaian per tujuan ("bila seluruh uang nganggur
   masuk ke tujuan ini"), bukan pembagian: dengan beberapa tujuan, angkanya
   tidak dijumlahkan dan teksnya menyebut pengandaian itu. Uang nganggur
   dihitung `features/plan`; tujuan membacanya lewat port
   `IdleMoneyAverage` yang dipasang akar komposisi (ADR-030), bukan impor
   antarfitur.

Aturan bersama: rata-rata ≤ 0 atau riwayat kurang dari satu periode lengkap
menampilkan "Belum bisa diperkirakan" (baris 1) atau menyembunyikan baris 2
(uang nganggur ≤ 0). Riwayat dihitung sejak tujuan dibuat: periode lengkap
yang berakhir sebelum `createdAt` tidak ikut, dan pembaginya jumlah periode
yang sudah dijalani (1–3), supaya tujuan baru tidak dibagi periode kosong
(diperjelas saat T-30.7, 18 Nov 2026). Uang nganggur memakai aturan yang sama
sejak catatan pertama. Tanggal = awal periode berjalan + `ceil(sisa ÷ laju)`
periode. Tanpa janji pasti.

Alasan laju dompet tertaut menjadi baris utama: uang nganggur adalah sisa
seluruh rencana bulan, bukan uang yang benar-benar masuk ke dompet tabungan;
sebagai satu-satunya dasar, angka yang sama akan terhitung untuk setiap tujuan.

### 3.7 Peringatan meleset (Plus)

Penjaga belum ada (hanya nama cadangan `PlusFeature.guardian`, B-44). Di fase
ini, rincian tujuan Plus menampilkan satu baris **"Perkiraan melewati target
tanggal"** bila perkiraan > `targetDate`. Peringatan aktif lewat Penjaga
(notifikasi) dikerjakan bersama B-44, bukan di sini.

### 3.8 Letak dan batas fitur (ADR-030)

- `shared/savings_goal/`: entitas, repositori, use case, dan
  `savings_goal_presentation.dart` (kartu tujuan, lencana "Tujuan: …" di kartu
  dompet). Dibaca tab Dompet, nanti Beranda dan Buku Periode.
- `features/savings_goal/`: daftar/rincian/formulir, `SavingsGoalRouteKeys`
  (`list`, `detail`, `form`), scope sendiri.
- Tab Dompet (`features/wallet`) menampilkan bagian **Tujuan** memakai widget
  `shared` dan membuka layar lewat kunci rute; tidak mengimpor isi
  `features/savings_goal`.
- "Buat dompet baru" dari pemilih dompet memakai kunci rute baru
  `WalletRouteKeys.create`, yang mengembalikan id dompet yang dibuat.

### 3.9 Riwayat tujuan dan umpan balik

- Rincian tujuan menampilkan transaksi yang menyentuh dompet tertaut
  (`walletIdsOf`), terbaru dulu, termasuk penyesuaian saldo dengan rupanya
  sendiri.
- Tujuan yang baru Completed memberi umpan balik singkat satu kali (snackbar
  satu slot, tanpa streak). Tonggak Buku Stempel ditunda sampai Fase 28 di
  `main`.

### 3.10 Analitik

`goal_created` (`collected`: `initial`/`empty`; sejak Revisi 1 menggantikan `linked_wallets`), `goal_completed`,
`paywall_shown` dengan pemicu P11 dan `goal_estimate` (T-30.7). Tanpa nama tujuan atau nominal (ADR-023).

## 4. Opsi yang dipertimbangkan

- **Opsi A — Alokasi virtual** (dokumen sumber). Ditolak pemilik (keputusan 2).
- **Opsi B — Field `goalId` di `Wallet`.** Menyederhanakan invarian satu dompet
  satu tujuan, tetapi mengubah bentuk dompet (migrasi, skema cadangan dompet,
  setiap penyimpan dompet ikut tahu tujuan). Ditolak.
- **Opsi C — `walletIds` di `SavingsGoal`, invarian di use case (Dipilih).**
  Dompet tidak berubah; satu dokumen baru; invarian diuji di satu tempat.
- **Opsi D — Perkiraan hanya dari uang nganggur.** Hitung ganda antartujuan;
  dipakai sebagai baris skenario kedua saja (§3.6).

## 5. Konsekuensi

- **Positif:** tidak ada sentuhan ke saldo, transaksi, atau bentuk dompet;
  kemajuan selalu sama dengan uang yang ada; fondasi untuk Total aset (B-98).
- **Negatif:** invarian satu dompet satu tujuan hanya dijaga use case (bukan
  bentuk data), sehingga cadangan hasil sunting tangan bisa melanggarnya;
  pemulihan memeriksa ulang dan menolak bila ada dompet ganda.
- **Dokumen yang ikut:** DOMAIN_MODEL (entitas baru), PROJECT_GLOSSARY,
  `writing.md`, EXPORT_BACKUP, FREEMIUM_PAYWALL (P11 terhubung), WEALTH_ASSETS
  T-6 (sesuai §3.6 bila disetujui), PLAY_DATA_SAFETY (data lokal baru).

## 6. Keputusan pemilik atas pertanyaan terbuka (17 Nov 2026)

1. **Completed menetap** walau saldo turun lagi di bawah target; kemajuan
   tetap mengikuti saldo; pengguna bisa mengaktifkan lagi (tunduk batas).
2. **Perkiraan dari keduanya**: laju dompet tertaut sebagai baris utama, uang
   nganggur sebagai baris skenario (§3.6).
3. **Rupa dikerjakan agen** seperti B-99 (spek di `docs/03-design/proposals/`).

## 7. Revisi

- 2026-11-17: dibuat (Proposed), lalu disetujui pemilik (Accepted) dengan jawaban §6.
- 2026-11-17: Revisi 1 (Proposed), keputusan pemilik "hanya otomatis", lihat §8.

## 8. Revisi 1: dompet milik tujuan (Accepted, 17 Nov 2026)

Pemilik memutuskan (17 Nov 2026) bahwa **setiap tujuan selalu punya tepat satu
dompet sendiri yang dibuat otomatis**, dan pengguna tidak lagi menautkan
dompet yang sudah ada. Bagian ini menggantikan §3.1–§3.4 dan §3.8 bila
bertentangan. Kode Fase 30 yang belum dirilis diubah langsung, tanpa migrasi.

### 8.1 Entitas

- `SavingsGoal.walletIds` diganti **`walletId`** (satu dompet milik tujuan,
  wajib). Tidak ada perubahan pada `Wallet`: "milik tujuan" dibaca dari
  tujuan yang menyimpan `walletId`-nya.
- Dompet milik tujuan bernama dan berikon sama dengan tujuannya; mengubah nama
  atau ikon tujuan ikut mengubah dompetnya.
- `collected` = `currentBalance` dompet itu. Aturan 5 tetap: tujuan tidak
  pernah membuat transaksi.

### 8.2 Use case

| Use case | Aturan |
|---|---|
| `CreateSavingsGoal` | Membuat dompet (nama dan ikon tujuan, **saldo awal = "Sudah terkumpul"**, opsional, bawaan 0; saldo awal bukan transaksi), lalu tujuannya. Bila tujuan gagal disimpan, dompet yang baru dibuat dihapus lagi. Batas Active Gratis diperiksa sebelum apa pun ditulis. |
| `UpdateSavingsGoal` | Nama, ikon, target, target tanggal, keterangan; nama/ikon disalin ke dompet. Target turun sampai tercapai → Completed. |
| `DeleteSavingsGoal` | **Menghapus semuanya** (keputusan pemilik): semua transaksi yang menyentuh dompet tujuan (transfer masuk/keluar dan penyesuaian saldo), lalu dompetnya, lalu tujuannya; dompet lain yang tersentuh transfer dihitung ulang, jadi saldonya di catatan kembali seperti sebelum uang dipindah. Konfirmasi menyebut akibat ini. Urutan: transaksi dulu (lewat `RecordTransaction.delete` per transaksi supaya hitung ulang dan `LedgerChanges` berlaku), lalu dompet, lalu tujuan. |
| Arsip, aktifkan lagi, sinkron status | Seperti §3.3. Mengarsipkan tidak mengubah dompet. |

`UnlinkWalletFromGoals` dihapus. Sebagai gantinya, **dompet milik tujuan tidak
bisa dihapus dari Dompet**: `WalletBloc` menolak dengan pesan "Dompet ini milik
tujuan <nama>. Hapus tujuannya untuk menghapus dompet ini."

### 8.2a Dompet tujuan hanya untuk transfer

Keputusan pemilik (17 Nov 2026): dompet milik tujuan **hanya menerima dan
mengirim transfer** dari/ke dompet lain. **Pemasukan dan pengeluaran ke dompet
tujuan ditolak**:

- `RecordTransaction` (satu-satunya jalur penyimpanan) menolak
  `IncomeTransaction`/`ExpenseTransaction` ber-`walletId` dompet tujuan dengan
  `ValidationFailure` (`goalWalletTransferOnly`). Karena semua jalur (CATAT,
  catat notifikasi, rutin, freelance) memakai use case ini, aturan berlaku di
  semua jalur. Untuk itu `RecordTransaction` membaca `SavingsGoalRepository`.
- Pemilih dompet pemasukan/pengeluaran di CATAT, aturan dompet catat
  notifikasi, rutin pemasukan/pengeluaran, dan pembayaran freelance tidak
  menawarkan dompet tujuan; pemilih transfer (asal dan tujuan) menawarkannya.
- Penyesuaian saldo (ADR-047) tetap boleh: ia koreksi catatan, bukan
  pemasukan atau pengeluaran.

### 8.3 Tempat tampil

- Dompet milik tujuan **tidak tampil** di grid dompet tab Dompet maupun di
  daftar dompet nonaktif; ia tampil sebagai tujuan di bagian Tujuan.
- Ia **tetap tampil di pemilih dompet CATAT** (transfer masuk ke tujuan dan
  mengambil dari tujuan) dan di Riwayat, karena ia dompet sungguhan.
- Rincian tujuan punya tindakan **Lihat dompet** (rincian dompet yang sudah
  ada) untuk Ubah saldo dan riwayat lengkap.
- Hitungan Total aset dan lapisannya ada di ADR-050.

### 8.4 Formulir

Kolom pemilih dompet dihapus. Tujuan baru punya kolom **Sudah terkumpul**
(opsional). Teks bantu menjelaskan bahwa tujuan punya dompet sendiri; uang
dimasukkan lewat CATAT › Transfer ke tujuan, dan cocok bila uangnya memang
dipisah (kantong rekening, deposito, amplop). Bila uangnya tetap di rekening
yang sama, catatan rekening itu akan lebih kecil dari saldo bank.

### 8.5 Cadangan

`BackupReference(from: 'savings_goal_all', fields: ['walletId'], target:
'wallet_all', unique: true)`; dokumen tetap skema 1 karena belum pernah
dirilis.
- 2026-11-17: Revisi 1 disetujui pemilik, ditambah §8.2a (hanya transfer) dan hapus menghapus semuanya.
