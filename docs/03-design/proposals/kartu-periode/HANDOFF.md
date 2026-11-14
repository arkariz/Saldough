# Serah terima desain: Buku Periode dan Kartu Periode (D1–D8)

**Untuk:** `flutter-engineer`. **Dari:** `ui-ux-designer`. **Status:** usulan rupa, belum disetujui pemilik. Perilaku dan aturan ada di `docs/01-product/features/BUKU_PERIODE.md` (BP-1–BP-21); bila dokumen ini berbeda dari dokumen itu, dokumen fitur yang benar. Konteks tugas: antrean B-95, urutan T-n.1–T-n.9 di dokumen serah terima product owner.

## 0. Baca dulu

| Berkas | Isi |
|---|---|
| `pratinjau-kartu.html` | D1+D2 versi tenang (acuan perilaku dan susunan data) |
| `pratinjau-kartu-gamifikasi.html` | D1+D2 versi permainan (acuan gerak) |
| `buku-periode-d3-d8.html` | D3–D8, alur tersambung |

Buka ketiganya di browser dan pakai panel kontrolnya; angka, urutan, dan gerak yang tertulis di bawah diukur dari berkas itu. Nilai px adalah dp logis pada lebar 360. Token memakai nama `context.ds` (`docs/03-design/design-system-v2/`), bukan `context.appColors`.

## 1. Keputusan yang masih terbuka dan memengaruhi kode

Jangan membangun di atas poin ini sebelum product owner menjawab.

| # | Pertanyaan | Dampak |
|---|---|---|
| 1 | **Versi mana yang dipakai: tenang atau permainan?** Versi permainan melonggarkan BP-13 (satu perayaan per pembukaan) dan GAMIFICATION. | Seluruh bagian 5 (gerak) dan widget tambahan bagian 3 |
| 2 | Teks penjelas D2 di dokumen ("Nominal tidak pernah ikut") bertentangan dengan BP-16 (nominal boleh ikut atas pilihan). Rupa memakai "Nominal mati secara bawaan dan hanya ikut kalau kamu menyalakannya". | Teks `book.share.*` |
| 3 | Rasio gambar kartu: rupa memakai **4:5**. Kalau story jadi sasaran, 9:16 mengubah susunan fakta. | Perender gambar (bagian 4.1) |
| 4 | KT-BP5: Rak Buku sebagai segmen ketiga Riwayat. | D7 dan arsitektur informasi |
| 5 | Stempel dicap pengguna lewat satu ketukan (seremoni) atau diraih otomatis seperti aturan B-94? | Logika stempel (bagian 4.4) |
| 6 | Kilap (polos, hijau, pelangi, emas) dan rak stempel: bagian resmi buku atau hanya efek layar bagikan? | Model kartu dan penyimpanan |
| 7 | Aset pose Tanuki baru (D8) atau cukup gerak di atas aset clay yang ada? | Aset |
| 8 | Angka contoh D6 (rata-rata Makan Rp1.280.000, Transport Rp650.000, anggaran Makan Rp1.800.000) karangan desainer; abaikan, ambil dari data uji emas. | Uji |

## 2. Peta layar ke fitur

| ID | Layar | Rute (usulan, akar komposisi) | Tugas | Gerbang |
|---|---|---|---|---|
| D1 | Gambar kartu | bukan layar; dirender ke gambar | T-n.7a | Semua pengguna |
| D2 | Pratinjau kartu | rute alur dari D3 atau D5 | T-n.7a | Semua pengguna |
| D3 | Kartu Beranda akhir periode | slot di Beranda | T-n.5, n.7a | Isi kartu beda Gratis/Plus |
| D4 | Ritual Tutup buku | rute alur dari D3 | T-n.5 | Plus |
| D5 | Sampul buku | rute dari D4 atau D7 | T-n.6 | Plus (dibuka sekali); terkunci bila belum dibuka dan Gratis |
| D6 | Halaman rapor | rute dari D5 | T-n.6 | sama dengan D5 |
| D7 | Rak Buku | segmen ketiga Riwayat | T-n.7 | tampil semua; isi menurut BP-10 |
| D8 | Pose Tanuki | bukan layar; aset dan aturan | T-n.6, n.7a | – |

Batas arsitektur (ADR-030) tetap: fitur tidak mengimpor isi fitur lain; penyedia halaman terdaftar di `lib/app/`. Rute baru memakai kunci rute (`<fitur>_route_keys.dart`).

## 3. Komponen

### 3.1 Yang sudah ada di `core/design_system` dan dipakai apa adanya

| Dipakai di | Widget |
|---|---|
| top bar sub-layar | `DsTopBar` (tombol ikon 44) |
| tombol | `DsButton` (`primary`, `secondary`, `ghost`; di bar bawah tinggi 48) |
| kartu | `DsCard` |
| baris daftar (D3 arus, D4 baris) | `DsListCard`, `DsLedgerRow` |
| meter anggaran D6 hlm 4 | `DsSegmentMeter` (varian `budget`, 10 segmen) |
| badge | `DsBadge` |
| navigasi bawah | `DsNavBar` |
| banner pembaruan D3 | `DsInlineBanner` |
| hitung naik D6 hlm 1 | `DsCountUp` (1,1 dtk, easeOutCubic) |
| denyut, gerak diam | `DsPulse`, `DsIdleMotion` |
| konfeti/perayaan | `DsCelebration`, `DsJiggle` |
| ikon clay | `ClayIcons.forIcon`, aset `assets/icons_clay/` |

### 3.2 Widget baru (nama usulan; tulis di `core/design_system/components/` hanya bila dipakai lebih dari satu fitur, selain itu di fitur)

| Widget | Dipakai di | Isi |
|---|---|---|
| `DsPeriodCard` | D1, D2, D3 (mini) | Gambar kartu 4:5. Lihat 4.1 |
| `DsFoilOverlay` | D1/D2 versi permainan | Lapisan kilap (`color-dodge`), 4 tingkat |
| `DsStampSeal` | D1, D5, D2 | Segel bulat: koin clay + teks melingkar |
| `DsStickerChip` | D2 | Chip pil dengan keadaan: mati, menyala, terkunci |
| `DsMoodMeter` | D2 (permainan) | `DsSegmentMeter` yang hanya naik, dengan label kata |
| `DsMascotBubble` | D2, D4, D6 | Tanuki + balon ketik per huruf |
| `DsBookCover` | D5, D7, D3 (mini) | Sampul buku (gradasi hijau, bingkai emas, kilap menyapu) |
| `DsPageDots` | D6 | Titik halaman, titik aktif memanjang 20 |
| `DsStepBar` | D4 | Tiga batang langkah |
| `DsConfettiBurst` | semua | `CustomPainter`: daun, koin, bintang |

Semua widget menerima teks yang sudah jadi, tidak mengandung string antarmuka.

## 4. Spek per layar

### 4.1 D1 Gambar kartu (`DsPeriodCard`)

- **Ukuran:** rasio 4:5. Di layar 252×315; ekspor 1080×1350 (skala ×4,286). Semua ukuran di bawah dalam dp pada lebar 252.
- **Latar:** gradasi 150° `#2D6A40` → `heroSurface` (45%) → `#123320`; bingkai 1 `heroBorder`; sudut 22; padding 16 (14 bila padat). Cahaya hijau `heroGlow` 22% buram 32 di pojok kanan atas.
- **Isi, atas ke bawah:**
  1. Baris kepala: logo daun bulat 20 (`primaryFixed`) + kata "tanukonomy" Space Mono 11; Tanuki clay 46 di kanan.
  2. Judul periode: 22/26, w800, `onHero`. Subjudul 12/16 `onHeroMuted` ("Periodeku, dicatat Tanuki."), disembunyikan pada mode padat.
  3. Fakta (menempel ke bawah): kisi 2 kolom jarak 6, ubin radius 12 hitam 28% bingkai putih 16%; label Space Mono 9 kapital `onHeroMuted`, nilai 13/18 w700 tabular. Jumlah ganjil: ubin terakhir selebar penuh.
  4. Kotak nominal (hanya bila ada yang dinyalakan): satu kotak, baris per nominal, label kiri nilai kanan.
  5. Kaki: garis atas putih 14%; "Mencatat, bukan melakukan" kiri, "Google Play" kanan, 10/12.
- **Mode padat** bila `jumlah fakta + jumlah nominal ≥ 6`: padding 16→16, judul 21/26, subjudul hilang, ubin padding 6×9, nilai 13, Tanuki 48.
- **Segel stempel:** 84, miring −12°, kanan atas di bawah baris kepala (offset kanan 10, atas 86), hanya tampil bila stempel diraih.
- **Rim emas** (Plus): bingkai luar 3 `#FDE68A` + cahaya 22.
- **Kosong:** bila tidak ada fakta, teks tengah "Nyalakan satu fakta untuk mengisi kartu."
- **Keadaan yang diuji:** 1–6 fakta; dengan dan tanpa nominal; selisih negatif (tanda minus U+2212, tanpa warna peringatan); stempel ada/tidak; peralihan (judul "25 Sep – 31 Okt", label "Periode peralihan · 37 hari"); kategori buatan pengguna ditampilkan "kategori buatanmu".
- **Kendala struktural (BP-16):** model kartu hanya berisi `jumlahCatatan`, `rutin(tercatat, dilewati)`, `stempel`, `kategoriBawaanTerbesar(persen)`, dan tiga nominal opsional. Tidak ada field untuk nama dompet, saldo, pedagang, nominal per transaksi, atau catatan. Uji pada gambar dan teks bagikan.
- **Teks bagikan** memuat tautan toko dengan `utm_source=period_card` (BP-18); di gambar hanya "Google Play".
- **Perender:** `RepaintBoundary` + `toImage(pixelRatio: 1080/252)`, di perangkat, tanpa jaringan (BP-17). Tanpa kilap dan tanpa gerak pada gambar ekspor (kilap hanya di pratinjau). Latar luar transparan; kartu sudah opak.
- **Semantik:** gambar kartu `Semantics(label: ringkasan fakta yang tampil)`; ubin di dalamnya `excludeSemantics`.

### 4.2 D2 Pratinjau kartu

- **Kerangka:** `DsTopBar` "Bagikan kartu periode" (versi permainan: "Kartu periode" + lencana kilap di kanan). Badan bisa digulir, bar bawah tetap.
- **Badan (jarak 14–16, margin 20):**
  1. Versi permainan: adegan (gradasi `scene`), Tanuki 84 + balon; versi tenang: tidak ada.
  2. Kartu (4.1) di tengah dalam panggung perspektif.
  3. Kalimat penjelas 13/18 `textSecondary`.
  4. Daftar sakelar (versi tenang) atau baki stiker (versi permainan): Jumlah catatan, Rutin beres, Stempel periode (hanya tenang), Kategori terbesar; kelompok "Nominal": Pemasukan, Pengeluaran, Selisih.
  5. Banner info bila ada nominal yang dinyalakan: "Nominal yang kamu nyalakan terlihat oleh siapa pun yang menerima gambar." Ikon `info`.
  6. Banner catatan bila nominal disembunyikan di aplikasi: sakelar nominal nonaktif, teks "Nominal disembunyikan di aplikasi, jadi tidak bisa ikut di kartu."
  7. Ajakan Plus (Gratis saja): satu baris, sampul buku 40×52 diburamkan (blur 5 + garis acak, angka tidak terbaca), "Cerita lengkapnya ada di buku periode. Buka dengan Plus." Tanpa hitung mundur. Pengguna Plus tidak melihatnya.
- **Bar bawah:** tombol "Bagikan kartu" 48. Nonaktif bila tidak ada fakta dinyalakan, dengan teks 12 di bawahnya "Nyalakan minimal satu fakta untuk membagikan."
- **Bawaan:** jumlah catatan, rutin beres, stempel menyala; kategori terbesar dan tiga nominal **mati**. Sakelar baris: tinggi min 52, switch 44×26 (isi `actionPrimary` bila menyala).
- **Perilaku:** kartu berubah seketika saat sakelar digeser (tenang) atau dengan animasi tampar (permainan, 4.4). Nominal disembunyikan → sakelar nominal dimatikan paksa dan nonaktif.
- **Hasil bagikan:** `Share.shareXFiles` (lembar sistem). Tidak ada unggahan.

### 4.3 D3 Kartu Beranda

- **Slot:** di bawah kartu saldo hero, di atas Arus. **Satu kartu pada satu waktu.** Prioritas: banner pembaruan ▸ lembar Apa yang baru ▸ banner kotak masuk ▸ kartu ini. Bila pembaruan tampil, kartu tidak dirender.
- **Kartu** (radius 20, padding 14, grid 76 | isi, jarak 12):
  - Kiri: Gratis → kartu mini 68×86 dengan kilap menyapu (`DsPeriodCard` skala kecil); Plus → buku mini 70×92 (`DsBookCover`) berayun ±3° 3,4 dtk.
  - Kanan: eyebrow Space Mono kapital `actionPrimary` ("Kartu periode" / "Buku periode"), judul 14/20 w700, keterangan 12/16 `textMuted`.
  - Baris tombol rata kanan: "Nanti" (ghost kecil) dan tombol utama kecil ("Bagikan" Gratis, "Tutup buku" Plus).
- **Teks:** Gratis "Kartu periode 25 Okt – 24 Nov siap dibagikan" / "Pilih fakta yang mau kamu tampilkan."; Plus "Buku 25 Okt – 24 Nov siap ditutup" / "Tiga langkah, semuanya boleh dilewati."
- **Masuk:** geser naik 24 + skala .96 → 1, opasitas, 600ms `easeOutBack`. **Nanti:** geser kanan 60 + mengecil + menutup tinggi 350ms; ingat "ditutup untuk periode ini". Buku tetap menunggu di Rak (BP-9).
- **Kondisi tampil:** hanya periode yang sudah berakhir dengan ≥3 transaksi (BP-3, BP-20).
- **Tidak boleh** tampil di Catat, lembar lain, onboarding, atau tur (BP-13).

### 4.4 Gerak versi permainan (bila disetujui)

Semua dihormati lewat `DsMotion.reduced(context)`: bila benar, animasi berulang berhenti, partikel tidak digambar, perayaan tidak dipasang, nilai langsung ke akhir.

| Gerak | Spek | Pemicu |
|---|---|---|
| Tanuki napas | geser −5 + skala Y 1,03, 3,2 dtk, berulang | selalu |
| Tanuki girang (`cheer`) | 900ms: tekan (skala 1,12/.86) → lompat −24 dan miring ±8° → mendarat 1,08/.92 | stiker menempel, stempel, langkah selesai |
| Tanuki melambai / berpikir | miring ±10° / −12°, 0,9–1,2 dtk | berbagi, balik kartu / lepas stiker |
| Balon ketik | 14–16ms per huruf; hormati reduced (langsung penuh); `Semantics(liveRegion: true)` | setiap tindakan |
| Kartu miring | ±11° Y, ±9° X mengikuti jari, kembali 250ms; mati bila reduced atau kartu terbalik | geser di panggung |
| Kilap | `color-dodge`, gradasi 6 titik bergeser dengan posisi jari; opasitas = tingkat/3 × .75 | tingkat 0–3 |
| Tingkat kilap | `min(3, ⌊stiker/2⌋ + stempel + rimEmas)`; nama "Kilap polos/hijau/pelangi/emas" | – |
| Stiker menempel | 500ms, skala 2,4 → 0,9 → 1, putar −10° → 2° → 0 | stiker dinyalakan |
| Stempel dicap | 600ms: skala 3,2 → .88 → 1,06 → 1, putar −40° → −12°; lalu getar layar 420ms (±5) dan konfeti 44 | tombol Cap stempel |
| Balik kartu | rotasi Y 180° 700ms `easeOutBack` | ketuk kartu |
| Meluncur | 1,1 dtk naik −300, mengecil .7, kembali | Bagikan |
| Konfeti | 12–44 partikel (daun hijau, koin emas, bintang kuning), kecepatan 2–7, gravitasi .16, umur 70–110 bingkai | tindakan di atas |
| Meter semangat | hanya naik: `3 + stiker + (stempel ? 3 : 0)`, maks 10; label Santai/Siap/Semangat/Girang/Meluap | – |

Satu `Ticker` per komponen; berhenti saat rute tidak tampil (`TickerMode`). Animasi berulang hanya skala, keburaman, geser. Uji kinerja di perangkat kelas bawah sebelum merilis kilap dan konfeti.

### 4.5 D4 Ritual Tutup buku

- **Kerangka:** top bar `close` + "Tutup buku". Badan: `DsStepBar` (3 batang tinggi 6, jarak 6, terisi sampai langkah sekarang), baris Tanuki 64 + balon (versi tenang: tanpa Tanuki, hanya judul), isi langkah, bar bawah dua tombol ("Lewati" ghost, "Lanjut" utama; langkah 3: hanya "Tutup buku").
- **Langkah 1 Tanpa kategori:** judul 20/26 w800.
  - Rapi: baris dengan lingkaran centang 30 (`actionPrimary`, animasi pop) + "12 dari 12 transaksi rapi", judul "Semua transaksi sudah berkategori".
  - Ada yang tertinggal: judul "2 transaksi belum berkategori", daftar ringkas dua transaksi di wadah `toneWarmContainer` (bukan merah), tombol sekunder "Beri kategori" membuka CATAT/penyunting kategori yang ada; sesudah selesai kembali ke langkah dan jadi rapi.
- **Langkah 2 Rutin menunggu:** jumlah dan jalan ke segmen Rutin, atau "Semua rutin sudah selesai"; bila satu dilewati: keterangan "Cicilan dilewati, itu tidak apa-apa."
- **Langkah 3 Kilas balik:** dua ubin (Anggaran, Terpakai) memakai komponen kilas balik yang ada; baris info "Data tetap bisa kamu ubah kapan saja."
- **Penutup:** tombol memicu: konfeti 40, getar layar, lalu pindah ke D5 dan cetak stempel.
- **Perilaku (BP-5, BP-6):** Tutup buku tidak mengunci atau mengubah data. Semua langkah boleh dilewati. Menutup di tengah menyimpan langkah yang selesai. Rapor bisa dibuka tanpa ritual.
- **Keadaan:** semua rapi (dua ketukan); ada yang tertinggal; dilewati; ditutup di tengah.

### 4.6 D5 Sampul buku (`DsBookCover`)

- **Ukuran:** 232×320 di tengah adegan; sudut 6 kiri / 16 kanan; gradasi 145° `#2F6E43` → `#14391F`; bayangan `10 14 24 0 hitam 35%`, punggung (inset kiri) gelap, bingkai emas 1,5 `#FDE68A` 65% berjarak 10.
- **Isi:** eyebrow "Buku periode" (Space Mono 10), nama periode 26/30 w800, label tahun atau "Periode peralihan · n hari" (Space Mono 10 emas), Tanuki 74 di kanan bawah, baris stempel di dasar.
- **Stempel tercetak:** bulat 64, bingkai 2 emas, koin clay + nama 7,5 Space Mono; dicap satu per satu berselang 900ms (mulai 500ms), tiap cap memicu getar dan konfeti 22. Banyak stempel membungkus ke baris kedua; nol stempel menyisakan ruang kosong tanpa tulisan "belum ada".
- **Gerak:** buku melayang miring (rotasi Y −18°→−12°, 4 dtk). "Buka rapor": buku membuka (skala 1,04, putar −6°) lalu D6.
- **Stempel dilipat ke sampul** bila ritual/rapor dibuka pada pembukaan yang sama (BP-13); tidak ada perayaan terpisah.
- **Tombol:** "Buka rapor" utama dengan kilat menyapu.
- **Tidak ada** peringkat, skor, atau perbandingan dengan pengguna lain.

### 4.7 D6 Halaman rapor

- **Kerangka:** top bar (periode), `PageView` 5 halaman bersyarat, `DsPageDots` di bawah. Margin halaman 20.
- **Halaman 1 Arus:** judul "Uang masuk lebih besar dari uang keluar." (hanya bila selisih ≥ 0; selisih negatif memakai kalimat netral "Uang keluar lebih besar dari uang masuk periode ini.", tanpa warna peringatan). Dua ubin Pemasukan/Pengeluaran + kartu selisih 32/38 w800. Angka hitung naik 1,1 dtk saat halaman tampil pertama. Angka **sama persis** dengan Arus Beranda dan Analisis (uji B-3, B-15).
- **Halaman 2 Ke mana uang pergi:** maksimal lima kategori teratas + "Lainnya" + "Tanpa kategori" (bila ada); baris: ikon clay 34, nama + nominal, persen (Space Mono), batang 8 (`actionPrimary`) yang memanjang 900ms `easeOutExpo`. Persen dibulatkan setengah ke atas, jumlah tidak dipaksa 100. Transfer tidak dihitung. Pemasukan freelance tanpa kategori masuk Freelance. Kategori buatan pengguna pada halaman ini boleh bernama aslinya (hanya kartu yang menyamarkan).
- **Halaman 3 Dibanding biasanya:** maksimal tiga sorotan dengan ambang ≥20% dan ≥Rp50.000 terhadap rata-rata tiga periode; ubin netral (`surfaceSunken`), nama kategori, dua nominal, selisih persen dengan tanda + atau − (Space Mono), **tanpa warna peringatan**. Hilang pada periode peralihan.
- **Halaman 4 Rutin dan rencana:** baris stempel (ikon clay 38) untuk rutin tercatat dan dilewati; kartu rencana vs kenyataan dengan `DsSegmentMeter`. "Rutin tak terlewat" diraih bila tidak ada kemunculan Menunggu.
- **Halaman 5 Kata Tanuki:** Tanuki 96 + balon, dua sampai empat kalimat dari templat lokal (BP-8), diketik per huruf saat halaman tampil.
- **Halaman bersyarat:** halaman dengan data kosong dilewati, titik halaman menyesuaikan.
- **Catatan netral** bila ada transaksi tanpa kategori: "2 transaksi belum berkategori, jadi pembagian kategori belum penuh" dengan tautan Beri kategori.
- **Nominal disembunyikan** (`AmountVisibility`): nominal tertutup, persen dan kalimat tetap tampil.
- **Semantik:** titik halaman `Semantics(label: "Halaman n dari 5")`; angka hitung naik membacakan nilai akhir.

### 4.8 D7 Rak Buku

- **Letak:** segmen ketiga kontrol segmen Riwayat (Daftar | Analisis | Buku) **bila KT-BP5 disetujui**. Kontrol segmen 3 segmen, tinggi 40.
- **Isi:** kisi 2 kolom jarak 22 baris / 14 kolom; tiap sel `DsBookCover` kecil (tinggi 128) + nama periode 13/18 w700 + status 11/14 `textMuted`. Garis rak 6 di bawah tiap baris.
- **Urutan:** terbaru di atas.
- **Keadaan sel:**
  - Belum dibuka: pita "Baru" emas di pojok, berayun ±3°.
  - Sudah dibuka: sampul sedikit lebih pudar, tanpa pita.
  - Terkunci (hanya Gratis, untuk buku yang belum pernah dibuka): ikon `lock` 28 di tengah, sampul `saturate(.4) brightness(.8)`, koin diburamkan; ketuk memunculkan toast "Buku ini dibuka dengan Plus. Kartu periodenya tetap bisa kamu bagikan."
  - Peralihan: baris status berawalan "Periode peralihan · n hari".
  - Kosong: Tanuki 110 + "Belum ada buku" + "Buku pertama siap saat periodemu berakhir." Tanpa tombol.
- **Tidak ada** hitungan "n buku menunggu" atau penanda belum-dibuka di tab (BP-9).
- **Gerbang (BP-10):** sesudah Plus berakhir, buku yang pernah dibuka tetap bisa dibuka; yang belum terkunci. Periksa di rute, bukan hanya di UI.

### 4.9 D8 Pose Tanuki

- **Empat pose:** biasa, senang, menulis, tenang. Tidak ada pose sedih atau kecewa. Wadah pose 110×110 di kartu 2 kolom.
- **Implementasi sekarang:** gerak di atas aset clay (`tanuki_mascot`, `tanuki_sleeping`, `note_pencil`). Pose senang: lompat berulang 1,8 dtk + dua kilau. Menulis: miring ±5° + pensil 42 menggores. Tenang: gambar tidur + "z" melayang.
- **Aset baru:** tidak ada yang digambar. Bila diputuskan, ganti per berkas tanpa mengubah kode (nama berkas tetap).
- **Satu set pose** dipakai di kartu bagikan dan di buku.

## 5. Token yang dipakai

Semua dari `design-system-v2/tokens.json`; tidak ada nilai heksadesimal baru kecuali yang di bawah (turunan warna hero, tetap sama di terang dan gelap).

| Peran | Token |
|---|---|
| kanvas, kartu, cekung | `surfaceCanvas`, `surfaceCard`, `surfaceSunken` |
| teks | `textPrimary`, `textSecondary`, `textMuted`, `textTertiary` |
| garis | `outlineSubtle`, `outlineStrong`, `outlineFocus` |
| tindakan | `actionPrimary`, `actionPrimaryPressed`, `onActionPrimary` |
| hero/sampul/kartu | `heroSurface`, `heroBorder`, `heroGlow`, `onHero`, `onHeroMuted`, `heroAccent`, `heroAccentWarm` |
| info, hangat | `infoContainer`/`onInfoContainer`, `toneWarmContainer`/`onToneWarmContainer` |
| bayangan | `ds.elevation.card`, `ds.elevation.overlay` |

Nilai tambahan (belum token; tambahkan ke preset bila disetujui): ujung gradasi kartu/sampul `#2D6A40` dan `#123320`/`#14391F`, emas segel `#FDE68A`/`#F59E0B`, adegan `scene-a`/`scene-b` (`#E3EFE5`/`#F4F8F4` terang, `#16241A`/`#0F1210` gelap). Preset Pink: gradasi kartu memakai `heroSurface` preset itu; periksa kontras `onHero` di atasnya.

Tipografi: Plus Jakarta Sans; Space Mono Bold hanya label kapital, badge, nominal baris, nama stempel (terkecil 11, KT-DS3; di kartu padat dan stempel boleh 9–10 karena bagian gambar, bukan teks UI, dengan catatan pengecualian dicatat).

## 6. Data dan model

| Kebutuhan | Sumber |
|---|---|
| angka periode | model baca Analisis/Arus Beranda; `financialPeriodOf`, `periodDateOf`; uang `int` sen |
| kategori | kategori bawaan atau buatan; kartu menyamarkan buatan menjadi "kategori buatanmu" |
| stempel | mesin tonggak B-94; "periode tertutup" fakta bersama |
| yang disimpan | buku dibuka, langkah ritual, kartu ditutup per periode, sakelar; **daftarkan di `BackupRegistry`**; tidak ada snapshot angka |
| gerbang | `PlusFeature` baru; pola `PlusLocked`; masa tenggang ADR-041 |
| uji Plus | `PLAN_OVERRIDE=plus` |

## 7. Aksesibilitas dan keadaan

- Target sentuh ≥44; chip stiker tinggi min 40 dengan area sentuh 44.
- Kontras teks pada kartu hijau: `onHero` di atas gradasi ≥ 7:1; `onHeroMuted` ≥ 4,5:1 (periksa sebelum merilis; label Space Mono 9 hanya pelengkap).
- Warna tidak jadi satu-satunya pembawa arti: stiker menyala memakai ikon centang, terkunci memakai ikon gembok, sorotan memakai tanda +/−.
- Gerak dikurangi: lihat 4.4; kartu tidak miring, kilap statis, konfeti tidak ada, balon langsung penuh.
- Teks 200%: kartu dan sampul adalah gambar berukuran tetap (tidak ikut skala teks); semua teks UI di sekitarnya ikut dan menggulir.
- Pembaca layar: balon Tanuki `liveRegion`; gambar kartu berlabel ringkasan; sakelar dan chip membacakan keadaan.
- 360dp, id dan en (en lebih panjang: periksa baris kategori dan ubin), terang dan gelap, preset warna.
- Setiap layar punya keadaan memuat, kosong, dan galat (belum digambar; ikuti `DsSkeleton`/`AppEmptyState`/`AppErrorState` yang ada).

## 8. Analitik (tanpa nominal)

`period_card_opened`, `period_card_shared` (`facts`: jumlah, `with_category`: bool, `with_amounts`: bool), `book_ritual_started`, `book_ritual_step` (indeks), `book_ritual_closed`, `book_opened`, `book_page_viewed` (indeks), `book_shelf_opened`. Nilai nominal tidak pernah dicatat.

## 9. Teks (kunci `book.*`)

Teks yang tertulis di rupa adalah usulan; sumber akhir BUKU_PERIODE §13. Istilah terlarang (kas, log, mutasi, netto, inventaris, kantong, entri, piutang, tangkapan, Anda), tanda seru, dan kata yang menilai belanja ditolak `translations_test.dart`. Nominal lewat `AppMoneyFormatter`/`AppMoneyText`.

## 10. Selesai kalau (bagian rupa)

- Setiap layar D1–D8 cocok dengan prototipe pada 360dp terang, gelap, dan satu preset lain, termasuk keadaan di bagian 4.
- Gambar kartu terbukti hanya memuat fakta yang dipilih (uji struktur) dan nominal bawaan mati serta mengikuti sembunyikan nominal.
- Gerak dikurangi diuji; kilap dan konfeti diukur di perangkat Android kelas bawah.
- Selisih dari prototipe dicatat di entri tugas TASK_LIST, bukan diubah diam-diam.
