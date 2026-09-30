# Sistem kategori: daftar bawaan yang bisa diubah

## 1. Metadata

- **Decision ID:** ADR-026
- **Tanggal:** 2026-09-30
- **Fase roadmap:** Fase 11 (Catat Cerdas), T-11.1; prasyarat ADR-027
- **Status:** Accepted
- **Cakupan:** `lib/shared/category/` (baru), `lib/shared/transaction/`,
  `features/record` (pemilih kategori CATAT), `features/transaction`
  (judul, rincian, penyaring), `features/account` (layar Kategori)
- **Mengganti:** konvensi "kategori = teks bebas" di `PROJECT_GLOSSARY.md`
  dan `DOMAIN_MODEL.md` bagian Transaksi (`categoryKey`).

## 2. Konteks

Sampai ADR ini, `Transaction.categoryKey` adalah label teks bebas. Formulir
CATAT menawarkan saran (lima label riwayat terbanyak + beberapa saran i18n)
dan item "Lainnya" untuk mengetik sendiri. Akibatnya:

- "Makan", "makan", dan "Makan siang" menjadi tiga kelompok berbeda di
  penyaring Transaksi.
- Pencatatan cerdas (suara, notifikasi, foto — ADR-027) tidak bisa
  memvalidasi keluaran model: kategori karangan model tidak dapat dibedakan
  dari label sah karena himpunannya terbuka.
- `DOMAIN_MODEL.md` masih mencatat "Daftar kategori transaksi" sebagai hal
  yang belum diisi pemilik.

Keputusan pemilik (30 September 2026):

1. Kategori berupa **daftar bawaan yang bisa diubah** pengguna (tambah, ganti
   nama, arsipkan).
2. **Datar** (tanpa induk/sub) dan **dipisah per jenis**: pengeluaran dan
   pemasukan. **Transfer tidak berkategori.**
3. Label lama **dimigrasi** menjadi kategori; label pada transaksi transfer
   **dibuang**.
4. Kata kunci (alias) hanya untuk kategori bawaan, didefinisikan di kode, tanpa
   UI penyunting alias.
5. Set bawaan disetujui (lihat §3.2).

## 3. Keputusan

### 3.1 Entitas

`Category` (`lib/shared/category/domain/category.dart`):

| Field | Tipe | Catatan |
|---|---|---|
| `id` | `String` | Bawaan: `builtin.<key>`; hasil migrasi: `legacy.<kind>.<label kecil>`; buatan pengguna: id waktu mikrodetik seperti entitas lain |
| `kind` | `CategoryKind { expense, income }` | |
| `name` | `String` | Selalu terisi. Nama bawaan ditulis dari i18n **saat dibuat**, lalu menjadi data milik pengguna (sama seperti nama dompet) — mengganti bahasa aplikasi tidak mengganti nama kategori |
| `builtInKey` | `String?` | Kunci kategori bawaan; menautkan alias dan ikon bawaan. `null` untuk buatan pengguna |
| `iconKey` | `String?` | Nama `IconKey`; `null` = ditebak dari nama (`categoryIconFor`) |
| `isArchived` | `bool` | Diarsipkan, tidak dihapus: transaksi lama tetap menunjuknya |
| `sortOrder` | `int` | Urutan di pemilih |

### 3.2 Set bawaan

Pengeluaran: Makan & Minum, Belanja Harian, Transportasi, Tagihan, Pulsa &
Internet, Kesehatan, Hiburan, Belanja, Pendidikan, Keluarga, Donasi, Lainnya.
Pemasukan: Gaji, Freelance, Bonus, Hadiah, Lainnya.

Definisinya (kunci, jenis, ikon, alias id/en) ada di
`lib/shared/category/domain/built_in_categories.dart`. Alias dipakai pencocokan
deterministik (ADR-027) dan migrasi (§3.4), tidak disimpan.

### 3.3 Transaksi

`IncomeTransaction` dan `ExpenseTransaction` memakai `categoryId: String?`.
`TransferTransaction` tidak punya kategori. `categoryKey` dihapus dari domain.
Dokumen JSON transaksi naik ke `schemaVersion` 2 dengan kunci `categoryId`;
pembaca tetap menerima `categoryKey` lama hanya untuk migrasi.

### 3.4 Penyimpanan dan migrasi

Seluruh kategori satu dokumen `category/all` (pola dompet, ADR-012 — jumlahnya
puluhan). Migrasi sekali jalan `MigrateLegacyCategories`, dipanggil `main.dart`
sebelum layar pertama, dengan penanda `category/_migration`:

1. Muat kategori tersimpan; tambahkan kategori bawaan yang belum ada.
2. Kumpulkan label unik per jenis dari seluruh transaksi pemasukan/pengeluaran.
3. Label yang sama (tanpa beda huruf besar/spasi) dengan nama atau alias
   kategori bawaan jenis itu → id bawaan; selainnya → kategori `legacy.*` baru.
   Id deterministik membuat migrasi aman diulang bila terhenti di tengah.
4. Tulis dokumen kategori **lebih dulu**, lalu tulis ulang tiap dokumen bulan
   (`categoryKey` → `categoryId`; transfer: label dibuang), lalu penanda.

Gagal migrasi tidak menghalangi aplikasi terbuka (NFR-REL-001); dicoba lagi
pada pembukaan berikutnya. Kategori bawaan disimpan sebelum label lama dibaca,
dan kegagalan dilaporkan ke Crashlytics sebagai non-fatal (verifikasi M1, F6).

**Penggabungan lewat alias diterima (KT-3, 30 Sep 2026).** Verifikasi M1 di
perangkat menunjukkan label berbeda milik pengguna ("Makan", "Kopi", "Food")
melebur ke satu kategori bawaan lewat alias, dan judul transaksi lama berubah
ke nama kategori bawaan. Pemilik memutuskan membiarkannya karena belum ada
pengguna dengan data lama. Tinjau ulang kalau keadaan itu berubah sebelum
rilis.

### 3.5 Tampilan

Nama kategori dibaca lewat `ActiveCategories` (`ValueNotifier` statis, diisi
`main.dart`, diperbarui setiap kali kategori disimpan) — pola yang sama dengan
`ActiveCurrency` (ADR-025 §3.5), karena judul transaksi dipakai di banyak layar
tanpa bloc bersama. Kategori terarsip tetap tampil namanya di transaksi lama,
tetapi tidak ditawarkan di pemilih.

### 3.6 UI

- CATAT: pemilih dropdown dari kategori aktif jenis itu (terbanyak dipakai di
  atas), "Tanpa kategori", dan "Tambah kategori" yang membuat kategori baru di
  tempat. Membuat kategori bukan membuat transaksi — aturan 8 tetap utuh.
- Layar **Kategori** dari layar Akun: daftar per jenis, tambah, ganti nama,
  arsipkan/pulihkan.
- Penyaring Transaksi memakai id kategori.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Tetap teks bebas + normalisasi**
- **Opsi B — Daftar tetap dari aplikasi**
- **Opsi C — Bawaan + bisa diubah, datar, per jenis (Dipilih)**
- **Opsi D — Dua tingkat (induk/sub)**

## 5. Analisis konsekuensi

### Opsi A — Tetap teks bebas
Tanpa migrasi, tetapi ejaan ganda tetap terjadi dan keluaran model tidak bisa
divalidasi.

### Opsi B — Daftar tetap
Paling sederhana untuk validasi, tetapi pengguna yang mencatat "Kucing" atau
"Arisan" kehilangan kategorinya.

### Opsi C — Bawaan + bisa diubah (Dipilih)
Himpunan tertutup yang tetap fleksibel. Kelemahan: butuh migrasi dan layar
kelola; label lama berejaan beda menjadi kategori ganda yang harus dirapikan
pengguna (fitur gabung belum ada).

### Opsi D — Dua tingkat
Laporan lebih kaya, tetapi UI dan pencocokan menjadi jauh lebih rumit untuk
manfaat yang belum diminta.

## 6. Konsekuensi

### Yang menjadi lebih mudah
- Penyaring dan ringkasan per kategori konsisten.
- Keluaran pencatatan cerdas bisa ditolak bila kategorinya tidak ada.

### Yang menjadi lebih sulit
- Transaksi menyimpan id, jadi tampilan butuh pencarian nama.
- Menambah kategori dari formulir butuh jalur tulis baru di CATAT.

### Risiko yang diterima
- Kategori ganda hasil migrasi label berejaan berbeda.
- Label transfer lama hilang (keputusan pemilik).

## 7. Catatan implementasi

- Jangan menulis nama kategori ke transaksi; simpan id.
- Kategori tidak pernah dihapus permanen selama ada transaksi — cukup arsip.
- Jangan membuat kategori otomatis dari keluaran model (ADR-027).

## 8. Kriteria peninjauan ulang

- Pengguna meminta sub-kategori atau anggaran per kategori.
- Sinkronisasi (B-7) membutuhkan id kategori global.

## 9. Artefak terkait

### Dokumentasi
- `docs/04-planning/VOICE_INPUT_RESEARCH.md` §3A
- `docs/02-architecture/DOMAIN_MODEL.md` bagian Transaksi dan Kategori

### Rujukan kode
- `lib/shared/category/`
- `lib/shared/transaction/domain/transaction.dart`

---

**Penulis keputusan:** Claude (agen), atas keputusan pemilik
**Ditinjau oleh:** pemilik
**Tanggal disetujui:** 2026-09-30
**Status implementasi:** selesai 30 Sep 2026 (T-11.1)
