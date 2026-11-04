# Rencana Verifikasi — Fase 26 (Catat dari notifikasi v2)

**Dibuat:** 4 November 2026 · **Revisi 0** · **Branch:** `claude/rombak-design-system-theming-5747b4` (sementara; Fase 26 dikerjakan di sini sebelum dipindah ke branch sendiri)
**Rujukan:** [ADR-044](../02-architecture/adr/0044-catat-dari-notifikasi-v2.md),
[NOTIFICATION_CAPTURE_V2.md](../01-product/features/NOTIFICATION_CAPTURE_V2.md) (§4 kartu, §5 duplikat, §10 gerbang, §12 ukuran),
[VERIFICATION_PLAN_FASE_23.md](VERIFICATION_PLAN_FASE_23.md) (pola dan prasyarat uji notifikasi), TASK_LIST Fase 26.
Android saja (Catat dari notifikasi tidak ada di iOS). Jalur rilis: **internal test** Play, tanpa saklar build.

## Cakupan

| Tahap | Tugas | Status verifikasi |
|---|---|---|
| Tahap 0 | T-26.1–T-26.5 (fondasi: tindak lanjut QA Fase 23, penentu bersama, penutup bersama, duplikat dua arah, pola lintas aplikasi) | Bagian A–D di bawah |
| MVP 1a | T-26.6, T-26.7 (Mulai cepat, kartu tiga jenis, satu ketuk, Catat semua, Cek langsung) | Bagian A–G di bawah |
| MVP 1b | T-26.9–T-26.13 (notifikasi bertindak, mesin tanpa layar, jurnal) | Spike T-26.9 dijalankan di satu emulator (bagian H); perangkat dan vendor lain, T-26.10–T-26.13 **belum** |

Bagian 1b tidak boleh dianggap lulus sebelum diuji; rilis internal MVP 1a boleh berjalan tanpa 1b.

## Status pengujian otomatis (sudah dijalankan)

| Pemeriksaan | Hasil (4 Nov 2026) |
|---|---|
| `flutter analyze` (area yang diubah) | Bersih |
| `flutter test` (seluruh proyek) | 2.602 lulus; 2 gagal di `import_boundaries_test` hanya karena galeri debug sementara di working tree (hilang bersama berkas debug) |
| Uji baru Fase 26 | `capture_resolver_test` (urutan, kelas, ambigu, pemutus nama, pola terikat, duplikat, kartu tersimpan), `capture_card_class_test` (kelas dan gerbang), `process_captured_notifications_test` (pos dari rutin, Tautkan, satu ketuk, satu-ke-satu), `notification_capture_pages_test` (Mulai cepat, duplikat, satu ketuk, Catat semua, banner izin, peristiwa analitik), `capture_events_test` |
| Uji layar yang belum ada | Tombol **Tautkan** di layar (alurnya diuji di tingkat use case), Mulai cepat gagal memuat daftar |

## Risiko utama

| # | Risiko | Kenapa penting |
|---|---|---|
| R1 | Satu ketuk mencatat draf yang salah (dompet, jenis, nominal) | Saldo salah tanpa formulir yang ditinjau; aturan 8 pengecualian ketiga |
| R2 | Transaksi ganda: kartu notifikasi dan catatan manual, atau dua kartu serupa | Saldo dan anggaran terhitung dua kali |
| R3 | Kemunculan rutin tertaut ke rutin yang salah, atau pos anggaran salah | Rutin dan anggaran salah; pemutus nama menebak |
| R4 | Mulai cepat tanpa daftar bank: aplikasi tak dikenal tidak terbaca | Fitur tampak menyala tetapi tidak mencatat |
| R5 | Sumber aktif tanpa dompet | Semua tangkapan masuk kotak masuk "dompet tidak dikenali" |
| R6 | Izin dicabut tanpa tanda | Kotak masuk tampak kosong padahal tidak ada yang masuk |
| R7 | Gerbang Plus bocor (Gratis bisa satu ketuk) atau terlalu ketat | Nilai Plus; kepercayaan pengguna Gratis |
| R8 | Tata letak luap di 360dp atau teks 2× | Tombol tidak terjangkau |

## Prasyarat data uji

- Dompet: **BRI**, **BCA**, **Tabungan** (ketiganya aktif); satu skenario dengan hanya satu dompet.
- Rutin uji: **Spotify** Rp54.000 tetap, pengeluaran, dompet BCA, bulanan, kategori Hiburan, tertaut ke pos anggaran Hiburan; **Netflix** Rp65.000 tetap; **Listrik** kira-kira Rp300.000.
- Anggaran bulan ini dengan pos berkunci template untuk Spotify dan Netflix.
- Akun Plus (uji coba atau pengganti paket) dan satu skenario Gratis (`ActivePlan` Gratis lewat pengganti paket debug).
- Notifikasi uji tanpa aplikasi bank asli: `adb shell cmd notification post -S bigtext -t "Judul" Tag "…"` terkirim dari paket `com.android.shell`; daftarkan paket itu lewat "Tambah sumber uji adb" di setelan (build debug). Jangan memakai nama bank dalam teks uji; pakai pola "Pembayaran Rp… ke … berhasil" dan "Dana masuk Rp… dari …".
- Jam perangkat boleh dimajukan lewat `cmd alarm set-time` (`auto_time 0`), lalu dikembalikan.

## Prioritas

**P1 = wajib sebelum rilis internal** (menyangkut uang: R1–R3, R5); **P2 = wajib sebelum rilis publik**; **P3 = bila sempat**.

| Prioritas | Baris |
|---|---|
| P1 | A3, A4, B2–B6, B9, C1–C5, D1–D6 |
| P2 | A1, A2, A5–A8, B1, B7, B8, B10, C6, E1–E4, F1–F5, G1–G4 |
| P3 | Mode gelap dan bahasa Inggris selain G4; kombinasi layar sempit di luar G1 |

## Daftar periksa perangkat

### A. Mulai cepat (T-26.5, T-26.6)

| # | Langkah | Harapan | Hasil |
|---|---|---|---|
| A1 | Beranda › Nyalakan catat dari notifikasi | Semua aplikasi terpasang (kecuali Tanukonomy) urut nama; **tidak ada** yang tercentang; tombol Nyalakan mati dengan "Pilih minimal satu aplikasi." | |
| A2 | Ketik di pencarian, centang satu aplikasi, ubah pencarian | Daftar tersaring; pilihan tidak hilang saat disaring | |
| A3 | Satu dompet aktif: pilih satu aplikasi lalu Nyalakan | Tanpa pertanyaan dompet; di setelan sumber itu berdompet satu-satunya dompet (tidak merah "Dompet belum dipilih") | |
| A4 | Beberapa dompet: pilih dua aplikasi | Tiap aplikasi menampilkan pemilih dompet; Nyalakan mati dengan "Pilih dompet untuk tiap aplikasi" sampai keduanya dipilih; dompet terpilih tersimpan per aplikasi | |
| A5 | Gratis: catatan di atas daftar; pilih dua aplikasi lalu Nyalakan | "Paket Gratis: satu aplikasi."; dua aplikasi membuka paywall tanpa menyimpan | |
| A6 | Plus: dua aplikasi | Tanpa catatan batas; keduanya tersimpan | |
| A7 | Akses notifikasi belum ada: Nyalakan | Dialog pengungkapan memuat "Pilih Tanukonomy lalu nyalakan"; Lanjut membuka daftar akses Android; sesudah memberi izin dan kembali, layar menutup dan fitur menyala | |
| A8 | Pilih aplikasi yang bukan bank (mis. kalkulator) | Bisa dipilih dan disimpan sebagai sumber | |

### B. Kartu dan satu ketuk (T-26.7)

| # | Langkah | Harapan | Hasil |
|---|---|---|---|
| B1 | Kirim "Pembayaran Rp25.000 ke KOPI KENANGAN berhasil" (Plus, tingkat otomatis mati) | Kartu di kotak masuk tanpa lencana "Catat otomatis mati"; kategori terbaca; tombol Abaikan, **Ubah dulu**, **Catat** | |
| B2 | Ketuk **Catat** | Transaksi tersimpan **tanpa formulir** bertanggal notifikasi, saldo dompet turun, snackbar "Tercatat Rp25.000 · app" dengan Batalkan; kartu hilang | |
| B3 | Ketuk **Batalkan** pada snackbar | Transaksi hilang, saldo kembali, kartu kembali ke kotak masuk | |
| B4 | **Ubah dulu** pada kartu lain | CATAT terbuka terisi (nominal, dompet, kategori, catatan); Simpan menghapus kartu | |
| B5 | Dua kartu atau lebih yang dikenali: tombol **Catat semua yang cocok (n)** | Hanya yang boleh satu ketuk ikut; yang perlu diisi tetap menunggu; snackbar "n transaksi tercatat" dengan Batalkan yang mengembalikan semuanya | |
| B6 | Kartu tanpa kategori atau dengan nominal tak terbaca | Tanpa Ubah dulu; **Catat** membuka CATAT; nominal tak terbaca ada **Ajari pola** | |
| B7 | Beranda: satu tangkapan menunggu, ketuk **Cek** | Langsung CATAT terisi (bukan kotak masuk); Simpan menghapus tangkapan dari Beranda | |
| B8 | Beranda: dua tangkapan, ketuk **Cek** | Kotak masuk terbuka | |
| B9 | Kirim promosi "Diskon Rp50.000 …" dari sumber yang sama | Tidak menjadi transaksi yang dicatat otomatis (selalu ditinjau, pola bawaan belum terverifikasi) | |
| B10 | Judul slide Beranda | Tanpa yang menunggu: "Catat dari notifikasi" (membuka setelan); ada yang menunggu: "Kotak masuk notifikasi" | |

### C. Rencana: rutin dan pos (T-26.2, T-26.3)

| # | Langkah | Harapan | Hasil |
|---|---|---|---|
| C1 | Kirim notifikasi Rp54.000 dari sumber BCA (cocok rutin Spotify) | Kartu berlencana "Cocok dengan …"; kategori Hiburan dan catatan "Spotify" terisi dari rutin | |
| C2 | Ketuk **Catat** (Plus) pada kartu C1 | Transaksi tertaut ke kemunculan rutin (status rutin menjadi tercatat) **dan** terhitung di pos anggaran Hiburan; Rutin dan Anggaran ikut segar | |
| C3 | Tingkat otomatis menyala (Plus); kirim notifikasi cocok persis | Tercatat otomatis dan tertaut, pos terisi, log tautan otomatis ada | |
| C4 | Dua rutin bernominal sama; teks memuat nama salah satu | Kartu menyarankan rutin bernama itu; **tidak** pernah tertaut otomatis | |
| C5 | Dua rutin bernominal sama; teks tanpa nama | Kartu tanpa saran rutin dan tanpa Ubah dulu; perlu diputuskan di CATAT | |
| C6 | Rutin kira-kira (Listrik, ±10%) | Kartu cocok rencana; satu ketuk hanya Plus; tidak tertaut otomatis | |

### D. Duplikat dua arah (T-26.4)

| # | Langkah | Harapan | Hasil |
|---|---|---|---|
| D1 | Catat manual transaksi yang sama (jenis, dompet, nominal, hari) **sebelum** notifikasi datang | Kartu berlencana "Mungkin sudah tercatat" dan "Sama dengan catatan …"; aksi Sudah, tutup / Tetap catat | |
| D2 | Catat manual **sesudah** kartu muncul, kotak masuk tetap terbuka | Kartu berubah menjadi duplikat tanpa hilang sendiri | |
| D3 | **Sudah, tutup** | Kartu hilang (dengan Urungkan), transaksi manual tidak tersentuh | |
| D4 | **Tetap catat** | CATAT terbuka; menyimpan menghasilkan dua transaksi sah | |
| D5 | Catatan manual belum tertaut dan ada rutin yang cocok: **Tautkan ke {rutin}** | Catatan manual tertaut ke kemunculan dan pos; kartu hilang; saldo tidak berubah | |
| D6 | Dua kartu serupa, satu catatan manual | Hanya kartu tertua yang berlabel duplikat | |

### E. Izin dan setelan

| # | Langkah | Harapan | Hasil |
|---|---|---|---|
| E1 | Cabut akses notifikasi di setelan Android, buka kotak masuk | Banner "Butuh izin membaca notifikasi" dengan Beri izin; bukan sekadar "Tidak ada yang perlu dicek" | |
| E2 | Beri izin lagi, kembali ke aplikasi | Banner hilang tanpa membuka ulang layar | |
| E3 | Matikan fitur di setelan | Tanpa banner izin | |
| E4 | Setelan › aplikasi › Filter dan pola | Pola bawaan berlaku untuk aplikasi mana pun (tidak per paket); bisa dimatikan | |

### F. Gerbang Gratis dan Plus (ADR-044 §3.8)

| # | Langkah | Harapan | Hasil |
|---|---|---|---|
| F1 | Gratis: kartu dikenali | Tidak ada Ubah dulu; **Catat** membuka CATAT (2 ketuk) | |
| F2 | Gratis: kartu cocok rutin tetap yang persis | Sama: Catat membuka CATAT (satu ketuk kartu seluruhnya Plus) | |
| F3 | Gratis: **Catat semua** | Tidak tampil | |
| F4 | Gratis: anti-duplikat, pos dari rutin, Cek langsung ke CATAT | Tetap bekerja | |
| F5 | Satu ketuk di segmen Rutin (Gratis) | Tidak berubah | |

### G. Regresi dan tampilan

| # | Langkah | Harapan | Hasil |
|---|---|---|---|
| G1 | Layar 360dp dan teks 2× untuk Mulai cepat dan kotak masuk | Tanpa overflow; tombol terjangkau (kartu tiga tombol membungkus) | |
| G2 | Sumber, pola, rutin, dan kotak masuk dari build sebelumnya (`adb install -r`) | Terbaca tanpa migrasi; id pola bawaan baru (`builtin.any.*`) | |
| G3 | Cadangkan dan pulihkan | Tidak terpengaruh | |
| G4 | Mode gelap dan bahasa Inggris untuk semua teks baru | Teks `en` lengkap, kontras cukup | |

### H. Spike mesin tanpa layar (T-26.9, hasil 4 Nov 2026)

Bukan daftar periksa; hasil percobaan di **satu** perangkat: emulator Google `sdk_gphone64_arm64`, Android 17 (API 37). Kode spike: `CaptureWorker.kt`, `CaptureActionable.kt`, `CaptureActionReceiver.kt`, `lib/app/capture_worker/capture_worker_main.dart` (hanya jalan di build yang bisa di-debug dan berkas `files/capture_worker_spike` ada).

| # | Yang dicoba | Hasil |
|---|---|---|
| H1 | Notifikasi dari sumber terdaftar masuk saat aplikasi tertutup; layanan pendengar menyalakan `FlutterEngine` dengan entrypoint Dart | **Berhasil.** Mesin dibuat di proses layanan yang sama; Dart hidup, membaca Hive (1 dompet, 17 kategori), menjalankan `CaptureResolver` yang sama dengan aplikasi (kelas `recognized`, nominal dan dompet benar), menutup Hive, memasang notifikasi, lalu mesin dimatikan |
| H2 | Notifikasi punya tombol **Catat** dan **Abaikan**; ketuk **Catat** dari bayangan notifikasi | **Berhasil.** `BroadcastReceiver` menulis keputusan ke jurnal native tanpa membuka aplikasi (tidak ada Activity yang muncul); notifikasi diganti hasilnya |
| H3 | Waktu dari notifikasi masuk sampai notifikasi bertombol, build **profil (AOT)** | Dingin ±0,6 dtk (mesin 377 ms, Dart hidup +214 ms, baca dan selesaikan ±25 ms) |
| H4 | Sama, build debug (JIT) | Dingin 1,0–1,4 dtk; hangat (proses yang sama) 0,4–0,5 dtk (mesin 24 ms) |
| H5 | Memori (PSS proses layanan) | AOT: 71 MB diam → 140 MB saat mesin hidup (+69 MB) → 113 MB sesudah dimatikan (+42 MB tertahan). Debug: 68 → 386 → 123 MB. Perlu diukur ulang di perangkat nyata |
| H6 | UI dibuka ±1 dtk sementara mesin tanpa layar menahan Hive terbuka (9 dtk) | UI memuat data normal dalam ±3 dtk; **tanpa galat kunci atau Hive**, di proses yang sama. Mesin tanpa layar hanya membaca, jadi tak ada tulisan bertabrakan; pemadatan Hive dari dua isolate tidak diuji |
| H7 | Dua notifikasi berselang 1,2 dtk, mesin masih berjalan | Yang kedua dicatat "menunggu di antrean" tetapi **tidak pernah diproses** (mesin hanya mengambil satu pekerjaan). Implementasi akhir harus menguras antrean sampai kosong |
| H8 | Mesin dinyalakan dari proses yang baru dimulai oleh layanan (tanpa Activity) | Berhasil; `FlutterEngine(context)` memuat pustaka dan mendaftarkan semua plugin (termasuk Firebase) tanpa galat yang terlihat |

Temuan yang mengubah rancangan:
1. **Perpustakaan titik masuk harus terjangkau dari `main.dart`** (impor yang tidak dipakai), kalau tidak "library not found" dan mesin gagal. `@pragma('vm:entry-point')` saja tidak cukup.
2. **Watchdog harus per-jalan dan dibatalkan saat selesai**: versi pertama spike membiarkan watchdog lama mematikan mesin berikutnya di tengah jalan.
3. **Konfigurasi native ditulis ulang dari setelan Dart tiap aplikasi dibuka** (`syncNotificationCapture`); itu benar untuk produksi, tetapi menyalakan fitur lewat berkas konfigurasi hanya bertahan sampai aplikasi dibuka.
4. **Antrean harus dikuras** (H7). Dart mengambil tangkapan lewat `pending()` yang sudah ada, bukan satu pekerjaan per mesin.
5. Mulai dingin ±0,6 dtk dan +69 MB sementara cukup untuk perangkat ini; pada perangkat dengan memori kecil atau vendor yang agresif mematikan proses angkanya bisa buruk (belum diukur).

Hasil tambahan T-26.10 (4 Nov 2026, emulator yang sama, build debug):

| # | Yang dicoba | Hasil |
|---|---|---|
| H9 | Ketuk **Catat** pada notifikasi bertombol, lalu buka aplikasi | **Berhasil.** Jurnal memuat keputusan dan draf (Rp31.000, BRI, Makan & Minum, "WARUNG ABC"); saat aplikasi dibuka, transaksi `cap_<id>` tersimpan di Hive, saldo dompet turun tepat Rp31.000, jurnal kosong, antrean native di-ack, notifikasi bertindak hilang |
| H10 | Entri jurnal yang sama masuk lagi (meniru proses mati sebelum ack) lalu buka aplikasi | **Aman.** Tetap satu transaksi, saldo tidak berubah, jurnal dikosongkan |
| H11 | Status Plus | Mesin tanpa layar membaca salinan native: Plus → tombol Catat; tanpa salinan = Gratis (tanpa tombol) |
| H12 | Notifikasi bertindak saat izin POST_NOTIFICATIONS belum diberikan | Tidak ada notifikasi dan **tidak ada entri jurnal** (jurnal baru ditulis bila notifikasi benar-benar dipasang); tangkapan tetap diproses biasa saat aplikasi dibuka |

Hasil tambahan T-26.11 (4 Nov 2026, emulator yang sama, build debug, tanpa berkas penanda):

| # | Yang dicoba | Hasil |
|---|---|---|
| H13 | Plus, sumber terpilih, `autoNotify` tanpa penanda | **Berhasil.** Mesin tanpa layar menyala sendiri, notifikasi bertombol Catat/Abaikan, teks mengikuti bahasa perangkat |
| H14 | Dua tangkapan berselang detik | Keduanya diproses (putaran kedua menguras antrean); notifikasi terpisah |
| H15 | Dua tangkapan lengkap sekaligus | Notifikasi mandiri "2 transaksi menunggu dicek" dengan tombol **Catat semua**; sebagai **ringkasan grup tombolnya tidak tampil** (Android 17), karena itu dibuat mandiri |
| H16 | Ketuk **Catat semua**, lalu **Batalkan** | Dua keputusan masuk jurnal, hasil "2 transaksi tercatat"; Batalkan menghapus keduanya dari jurnal ("Dibatalkan") |
| H17 | Gratis + `autoNotify` | Mesin tidak menyala, tidak ada notifikasi |
| H18 | Gratis + pengingat dinyalakan sendiri | Mesin menyala (`plus=false`), notifikasi informasi tanpa tombol |

| H19 | Catat pada notifikasi bertombol yang cocok dengan rutin (entri jurnal bermuatan `match`) | Receiver menyalakan mesin tanpa layar; Dart membaca keputusan dan `match`, lalu menjalankan penyesuaian pengingat (log "pengingat rutin disesuaikan"). Efek pada jadwal sungguhan belum terlihat (tanpa rutin dan pengingat mati di data uji) |

Belum diuji di perangkat: pengingat generik saat mesin tanpa layar gagal; **pengingat rutin sungguhan batal setelah Catat lewat tombol** (perlu rutin dengan pengingat menyala dan notifikasi yang cocok dengannya; periksa juga bahwa `cancel` plugin berfungsi dari mesin tanpa layar).

Belum dicoba (wajib sebelum ADR-044 Accepted): sedikitnya dua perangkat nyata dari vendor lain (satu yang agresif mematikan layanan di latar), Android versi lebih rendah, layar kunci dengan kunci sungguhan (`setAuthenticationRequired`), proses dimatikan sungguhan di tengah penerapan jurnal (hanya diuji lewat entri ulang), mode hemat daya, dan build rilis dengan R8.

## Ukuran keberhasilan

Dihitung dari peristiwa analitik jalur internal (hanya jenis aksi, kelas kartu, dan jumlah; tanpa nominal, nama atau paket aplikasi, dan isi notifikasi; ADR-023) dan dari daftar periksa di atas. Peristiwa baru: `capture_inbox_opened`, `capture_card_action`, `capture_record_saved` (`CaptureEvents`).

| Ukuran | Definisi | Sumber | Usulan target | Status ambang |
|---|---|---|---|---|
| Ketuk per transaksi dari kartu | Bobot per aksi: `one_tap` dan `confirm_all` = 1; `edit_first` dan `record` = 2 (Catat/Ubah dulu lalu Simpan di CATAT). Median atas aksi yang mencatat; `dismiss` dan `close_duplicate` tidak dihitung | `capture_card_action` | Median ≤1 pada kartu dikenali (Plus); 2 pada Gratis | Disepakati |
| Kartu yang diubah dulu | `edit_first` ÷ (`one_tap` + `confirm_all` + `edit_first`) pada kelas `planned` dan `recognized`, pengguna Plus. **Proksi**: mengukur seberapa sering pengguna tidak langsung percaya, bukan jumlah isian yang berubah | `capture_card_action` | <20% | **Belum diputuskan (KT-N2 ditunda)** |
| Perubahan isian sungguhan | Berapa dari kartu `edit_first` yang diubah jenis, dompet, nominal, atau kategorinya di CATAT | Manual: daftar periksa B4 dan tinjauan penguji | Dicatat, tanpa ambang | Belum otomatis (CATAT hanya mengembalikan "disimpan", bukan selisihnya) |
| Sebaran kelas kartu | Porsi kartu `planned`, `recognized`, `needs_input` per pembukaan kotak masuk | `capture_inbox_opened` | `needs_input` <50% pada penguji berpola | Usulan |
| Duplikat lolos | Transaksi ganda yang tidak tertangkap kartu | Manual D1–D6 dan laporan penguji; `close_duplicate` dan `link_existing` = duplikat tertangkap | **0** | Disepakati |
| Izin lolos | Pengguna yang menyelesaikan Mulai cepat sampai akses diberikan | `quick_start_completed` ÷ `notification_row_tapped(action: quick_start)` | >60% | Usulan |
| Pagar nominal besar untuk otomatis | Nominal melebihi kebiasaan (usulan >10× median bentuk) masuk kotak masuk | — (E3) | — | **Belum diputuskan (KT-N2 ditunda)** |

## Keterbatasan yang diketahui (bukan temuan)

- Tombol Tautkan belum punya uji layar; alurnya diuji di use case.
- Jendela pencocokan rutin tetap ±3 hari (±7 hari untuk pola terikat); pembayaran lebih awal dari itu tidak otomatis cocok.
- Ingatan pedagang (kategori dari konfirmasi sebelumnya) belum ada implementasinya (E1/B-85); port `MerchantMemory` sudah terpasang.
- Pos anggaran hanya mengikuti rutin; pengeluaran bebas tanpa rutin tidak diisi (E2/B-86).
- Mesin tanpa layar, jurnal, dan notifikasi bertindak (1b) belum ada, jadi mencatat tanpa membuka aplikasi belum bisa diuji.
- Pengungkapan privasi, kebijakan privasi situs, dan formulir Keamanan Data belum diperbarui untuk Fase 26 (T-26.13); wajib sebelum rilis publik. Peristiwa `capture_*` perlu masuk baris Analytics di `PLAY_DATA_SAFETY.md` (sudah ditambahkan, tinggal diformalkan saat rilis).

## Cara melaporkan

Seperti [VERIFICATION_PLAN_FASE_23.md](VERIFICATION_PLAN_FASE_23.md): nomor langkah, build/commit, langkah reproduksi, hasil nyata vs harapan, tangkapan layar, dan keparahan (S1 uang atau saldo salah, duplikat, atau crash; S2 alur utama terganggu; S3 kosmetik atau teks). Teks notifikasi asli **wajib disamarkan** (nominal, nomor rekening, nama).

## Hasil

*Belum diuji di perangkat.*
