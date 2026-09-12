# Siklus bulanan: template, rollover, dan baris roll-up

## 1. Metadata

- **Decision ID:** ADR-008
- **Tanggal:** 2026-09-09
- **Fase roadmap:** Fase 2
- **Status:** Accepted
- **Cakupan:** Fitur: siklus bulanan, belanja, kartu kredit

## 2. Konteks

Keputusan ini menjawab nyeri utama pemilik secara langsung. Tiga dari sembilan
baris nyeri di
[analisis proses manual](../../00-foundation/MANUAL_PROCESS_ANALYSIS.md)
berasal dari satu akar yang sama: angka dihitung di satu tempat lalu diketik
ulang di tempat lain, dan struktur bulan disalin lalu disunting tangan.

Tiga angka disalin manual setiap bulan. Total belanja dari spreadsheet
`bulanan`, dan total tagihan dari dua spreadsheet kartu kredit. Ketiganya masuk
ke bagian anggaran sebagai satu baris.

Struktur bulan juga disalin manual. Bukti kegagalannya terekam di data: tiga
blok bulan berturut-turut sama-sama berlabel `Kos agustus - september`, karena
label lama tidak ikut diperbarui saat blok disalin.

Ada pula perbedaan perilaku antar baris anggaran yang tidak pernah dinyatakan
eksplisit di spreadsheet, tetapi jelas terlihat dari datanya. Sebagian baris
muncul hampir tiap bulan, seperti `Kos`, `listrik`, `Wifi`, dan `Laundry`.
Sebagian lain hanya muncul sekali, seperti `Kulkas`, `kasur`, dan
`Pelunasan pelatihan ABA`. Kedua jenis ini harus diperlakukan berbeda saat bulan
baru dibuat.

## 3. Keputusan

Saldough memperkenalkan dua konsep pada baris anggaran, dan satu mekanisme
pembuatan bulan baru.

**Baris punya jenis.** Sebuah `BudgetLine` bernilai `manual` atau `rollUp`.
Baris `manual` nominalnya diketik pemilik. Baris `rollUp` nominalnya dihitung
dari sumber yang ditunjuk `rollUpSource`, dan **tidak bisa disunting langsung**.
Tiga sumber yang berlaku: rencana belanja, dan dua kartu kredit.

**Baris punya sifat keberulangan.** Setiap baris pemasukan dan anggaran punya
penanda `isTemplate`. Baris bertanda tetap ikut terbawa saat bulan baru dibuat;
baris insidental tidak.

**Rollover membuat bulan baru dari template**, dengan empat aturan:

1. Salin hanya baris bertanda `isTemplate` true.
2. Untuk baris `rollUp`, salin strukturnya tetapi jangan salin nominalnya.
   Hitung ulang dari sumbernya di bulan yang baru.
3. Tandai setiap baris hasil salinan sebagai perlu ditinjau.
4. Salin persentase alokasi investasi bawaan.

Aturan ketiga adalah inti keputusan ini. Baris hasil rollover tidak dianggap
benar sampai pemilik mengonfirmasinya. Jumlah baris yang belum ditinjau
ditampilkan di ringkasan siklus, sehingga bulan tidak bisa dianggap selesai
selama masih ada yang menggantung.

Nilai roll-up dihitung saat dibaca, bukan disimpan ganda. Saat rencana belanja
atau transaksi kartu berubah, baris anggaran yang bergantung padanya ikut
berubah tanpa langkah tambahan.

## 4. Opsi yang dipertimbangkan

- **Opsi A — Menyalin bulan sebelumnya apa adanya, seperti spreadsheet**
- **Opsi B — Template terpisah dengan penanda tetap, roll-up dihitung saat
  dibaca (Dipilih)**
- **Opsi C — Baris berulang otomatis penuh tanpa peninjauan**

## 5. Analisis konsekuensi

### Opsi A — Menyalin bulan sebelumnya apa adanya

Paling mudah dipahami karena persis seperti yang dilakukan pemilik sekarang, dan
tidak butuh konsep baru.

Tetapi opsi ini memindahkan masalahnya, bukan menyelesaikannya. Baris insidental
bulan lalu ikut terbawa dan harus dihapus manual, dan label lama tetap bisa
lolos tanpa ditinjau. Nyeri yang paling nyata justru tidak tersentuh.

### Opsi B — Template terpisah dengan penanda tetap, roll-up dihitung saat dibaca (Dipilih)

Menyelesaikan ketiga akar masalah sekaligus. Baris insidental tidak ikut
terbawa, angka roll-up tidak pernah perlu diketik ulang, dan penanda perlu
ditinjau memaksa setiap baris tetap diperiksa sebelum bulan dianggap selesai.

Menghitung roll-up saat dibaca juga menghilangkan kemungkinan angka basi. Tidak
ada nilai tersimpan yang bisa menyimpang dari sumbernya.

Kelemahannya, pemilik harus menandai baris mana yang tetap dan mana yang
insidental. Ini beban baru yang tidak ada di spreadsheet. Beban itu diringankan
dengan menjadikan baris baru bersifat insidental secara bawaan, sehingga
menandai tetap adalah tindakan sadar yang dilakukan sekali per baris.

Kelemahan kedua, menghitung saat dibaca berarti membuka satu bulan juga memuat
rencana belanja dan siklus kartu yang terkait. Dengan volume data yang ada, ini
tidak terasa.

### Opsi C — Baris berulang otomatis penuh tanpa peninjauan

Paling sedikit interaksi. Bulan baru langsung terisi lengkap.

Tetapi justru inilah kegagalan yang sudah terjadi di spreadsheet. Nominal
listrik dan kos berubah antar bulan, dan tanpa dorongan untuk meninjau, nilai
lama akan diterima diam-diam. Kecepatan di sini menghasilkan angka yang salah.

## 6. Konsekuensi

### Yang menjadi lebih mudah

- Membuat bulan baru menjadi satu tindakan.
- Angka belanja dan tagihan kartu tidak pernah perlu diketik ulang.
- Baris yang belum diperiksa terlihat jelas, sehingga tidak ada yang lolos.

### Yang menjadi lebih sulit

- Pemilik harus menandai baris tetap sekali per baris.
- Baris roll-up tidak bisa disunting langsung, yang bisa terasa membatasi saat
  pemilik ingin menimpa angkanya cepat-cepat.
- Membuka satu bulan memuat lebih banyak dokumen daripada sekadar dokumen
  siklusnya.

### Risiko yang diterima

- Penanda perlu ditinjau bisa diabaikan pemilik kalau terlalu sering muncul.
  Ditangani dengan hanya menandai baris hasil rollover, bukan setiap perubahan.
- Larangan menyunting baris roll-up bisa menghalangi kasus sah, misalnya
  tagihan kartu yang sudah dibayar sebagian. Ditangani dengan menyediakan
  penyesuaian di sumbernya, bukan di baris anggarannya.

## 7. Catatan implementasi

### Batasan yang harus dijaga

- Baris ber-`kind` `rollUp` wajib punya `rollUpSource`. Ini invarian di
  [DOMAIN_MODEL.md](../DOMAIN_MODEL.md).
- Nominal baris roll-up dihitung, tidak pernah disimpan di dokumen siklus.
- Baris baru bawaannya `isTemplate` false.
- Rollover tidak pernah menyalin baris ber-`isTemplate` false.
- Siklus yang sudah ditutup tidak bisa disunting tanpa dibuka kembali secara
  sadar.

### Perilaku yang diharapkan

- Menyunting rencana belanja langsung mengubah baris `Bulanan` di SATU siklus
  yang ditautkan ke rencana itu (`GroceryPlan.id` == `MonthlyCycle.id`, satu
  dokumen per bulan — lihat "Catatan revisi" di bagian 8b), bukan lagi seluruh
  siklus terbuka.
- Menambah transaksi kartu langsung mengubah baris kartu di siklus yang
  bersangkutan.
- Menutup siklus membekukan nilai roll-up, sehingga riwayat tidak berubah kalau
  daftar belanja disunting kemudian.

Perilaku terakhir penting dan mudah terlewat. Tanpa pembekuan saat penutupan,
menyunting daftar belanja hari ini akan mengubah anggaran bulan-bulan
sebelumnya, dan riwayat pemilik menjadi tidak dapat dipercaya.

### Antipola yang harus dihindari

- Menyimpan nominal roll-up di dokumen siklus yang masih terbuka.
- Menyalin nominal roll-up saat rollover.
- Menandai seluruh baris hasil rollover sudah ditinjau secara otomatis.
- Mengizinkan penyuntingan langsung nominal baris roll-up.

## 8. Kriteria peninjauan ulang

- Pemilik mulai mengabaikan penanda perlu ditinjau secara konsisten.
- Muncul sumber roll-up keempat, sehingga `RollUpSource` perlu dibuat lebih
  umum.
- Membuka satu bulan mulai terasa lambat karena dokumen yang dimuat bertambah.

## 8b. Catatan revisi

**12 September 2026 — `GroceryPlan` jadi satu dokumen per bulan, bukan lagi
dokumen tunggal dibaca bersama.** Sejak Fase 4, `GroceryPlan` adalah satu
dokumen singleton (`grocery:plan`) dibaca LIVE oleh setiap `BudgetLine`
ber-`rollUpSource` `grocery` di SELURUH siklus yang masih terbuka —
`GroceryRollUpSource` tidak membawa identitas apa pun, jadi tidak ada cara
membedakan "rencana belanja bulan ini" dari "rencana belanja bulan lalu".
Pemilik melaporkan ini sebagai keterbatasan: daftar belanja memang berubah
tiap bulan (harga naik, item baru), dan satu dokumen bersama berarti
menyunting bulan ini ikut menggeser angka bulan lain yang masih terbuka,
padahal belum tentu keduanya dimaksudkan sama.

Keputusan: `GroceryPlan` diberi `id` (format `YYYY-MM`, sama seperti
`MonthlyCycle.id`), dan `GroceryRollUpSource` diberi field `planId` — satu
baris anggaran roll-up `grocery` sekarang menunjuk SATU rencana belanja
tertentu, dengan konvensi **1:1**: baris yang dibuat dari siklus `2026-08`
menunjuk `GroceryPlan` ber-`id` `2026-08`. Ini pola yang sama seperti
`CardRollUpSource.cardId` sejak awal (kartu selalu punya identitas) — bukan
konsep baru, hanya menyamakan `grocery` dengan `card`.

**Bulan baru tidak mulai kosong.** `GroceryPlanRepositoryImpl.getPlan`
menyalin daftar item dari bulan SEBELUMNYA kalau bulan yang diminta belum
pernah disunting (permintaan eksplisit pemilik — lihat `AskUserQuestion`:
opsi "disalin dari bulan sebelumnya" dipilih atas "kosong, diisi manual tiap
bulan"). Salinan ini tidak otomatis tertulis ke penyimpanan — sama seperti
`MonthlyCycle` yang "ada" secara malas sampai baris pertamanya disimpan
(`CycleBloc._loadCycle`), rencana belanja bulan baru hanya benar-benar
tersimpan sendiri saat pemilik pertama kali menyimpan perubahan padanya.

Konsekuensi pada rollover (`RollOverCycle`): kalau baris template punya
`GroceryRollUpSource`, `planId`-nya BUKAN disalin apa adanya (itu akan
mewariskan `planId` siklus asal, bukan siklus baru) — ditaut ulang ke `id`
siklus baru. Ini satu-satunya pengecualian pada aturan 2 di bagian 3
("salin strukturnya, bukan nominalnya") yang perlu field tambahan selain
nominal untuk tetap benar; `CardRollUpSource.cardId` tidak terpengaruh
karena kartu bukan entitas per-bulan.

**Dampak pada kalimat "Perilaku yang diharapkan" di bagian 7**: baris
"menyunting rencana belanja langsung mengubah baris `Bulanan` di seluruh
siklus yang belum ditutup" sudah TIDAK BENAR lagi sejak revisi ini — sekarang
hanya mengubah SATU siklus yang `id`-nya sama dengan rencana yang disunting.
Kalimat itu sudah diperbarui langsung di bagian 7, bukan hanya dicatat di
sini — beda dari revisi UX-22 ADR-0006 (koreksi keterbacaan tanpa mengubah
isi keputusan), ini mengubah perilaku yang didokumentasikan, jadi bagian
utamanya yang harus benar, catatan ini menjelaskan alasannya.

Penanda "kunci" (closed) siklus TETAP berfungsi seperti sebelumnya
(`CycleRepositoryImpl._resolveRollUps` berhenti menghitung ulang begitu
`isClosed`) — tautan 1:1 tidak mengubah aturan pembekuan saat penutupan,
hanya mengubah SIAPA yang dihitung ulang saat siklus masih terbuka (satu
bulan, bukan semua).

## 9. Artefak terkait

### Dokumentasi

- [MANUAL_PROCESS_ANALYSIS.md](../../00-foundation/MANUAL_PROCESS_ANALYSIS.md)
  untuk bukti nyeri yang mendasarinya.
- [DOMAIN_MODEL.md](../DOMAIN_MODEL.md) untuk entitas dan invariannya.
- PRD FR-TPL-001 sampai FR-TPL-004, FR-GROC-003, dan FR-CARD-005.
- [ADR-0002](0002-local-first-hive-document-storage.md) untuk bentuk dokumennya.

---

**Penulis keputusan:** Tim Saldough
**Ditinjau oleh:** Pemilik proyek
**Tanggal disetujui:** 2026-09-09
**Status implementasi:** Disetujui, belum diimplementasikan
