# Rencana dan hasil verifikasi: Fase 28 (Mesin tonggak + Buku Stempel)

**Diuji:** 14–15 Nov 2026, build debug dari branch `claude/buku-periode-fase-27`
(`1.1.0+24`), emulator Android 17 `Medium_Phone_2` (arm64). Satu emulator, bukan
perangkat nyata, dan **bukan perangkat kelas bawah**.
**Rujukan:** [GAMIFICATION.md](../01-product/features/GAMIFICATION.md) §4 (S1–S8),
[ADR-046](../02-architecture/adr/0046-mesin-tonggak-dan-buku-stempel.md), T-28.8.
**Cara:** `adb` (input dan `uiautomator` untuk membaca layar), tangkapan layar
dikirim ke pemilik, isi catatan stempel dibaca dari berkas Hive debug. Data uji:
instal baru dan pemulihan `demo_id.tkbak` (cadangan 9 Nov, sebelum fitur ada:
34 transaksi, 4 dompet, sejak 1 Okt).

## Status pengujian otomatis

| Pemeriksaan | Hasil |
|---|---|
| `flutter analyze` (lib, folder yang disentuh) | Bersih; satu info lama `directives_ordering` di `core/presentation/widgets/widgets.dart`, bukan dari fase ini |
| Uji milestone, `test/app`, i18n, analitik, arsitektur, design system, Akun, Beranda | Lulus pada eksekusi masing-masing (tidak dijalankan sebagai satu `flutter test` penuh) |
| Fakta stempel (15 kasus), mesin, kebijakan perayaan, koordinator, penyimpanan, saklar jarak jauh, peristiwa | Lulus |
| Uji widget Buku Stempel, Akun, segel, snackbar, lembar, gerak penuh | Lulus |

## Hasil per skenario

| # | Skenario | Hasil | Catatan |
|---|---|---|---|
| S1 | Mulai: dompet pertama lalu catatan pertama | **Tidak sesuai tulisan skenario** | Pada instal baru, dompet dan catatan pertama terjadi saat tur Beranda tampil, jadi **tidak ada perayaan** (G-4: perayaan terhalang tidak menunggu). Hanya titik di Akun. Skenario menulis snackbar dan "menunggu lalu tampil sekali di Beranda". Lihat F28-1 |
| S2 | Periode rapi | **Lulus** | Pemulihan data Oktober (berkategori) menghasilkan Periode rapi; fakta dihitung dari data nyata |
| S3 | Rutin tak terlewat | Tidak teruji di perangkat | Data uji punya rutin yang masih menunggu, jadi stempel memang tidak diraih (benar). Kasus lulus/dilewati/dijeda hanya di uji otomatis |
| S4 | Dua stempel sekaligus | Tidak teruji di perangkat | Hanya uji otomatis (`planCelebration`: satu snackbar digabung) |
| S5 | Terlambat tapi tetap dihargai | Tidak teruji di perangkat | Hanya uji otomatis; stempel dihitung ulang dari data tiap evaluasi |
| S6 | Absen | **Lulus (bagian yang bisa diuji)** | Setelah aplikasi dihentikan paksa dan dibuka lagi, isi Buku Stempel dan titik tidak berubah; stempel tidak pernah dicabut (uji G-1) |
| S7 | Pengguna lama | **Lulus** | Pulihkan cadangan tanpa catatan stempel: lima stempel (Dompet, Catatan, Periode rapi, Cadangan, Anggaran) dan Pembayaran pertama diterima masuk **diam-diam** (`quiet`, `seeded`, `introShown:false`), tanpa snackbar atau lembar. Satu banner "Buku Stempel baru. Yang sudah kamu capai sudah ada di sini." di papan status Beranda; ketuk membuka Buku Stempel dan banner hilang |
| S8 | Dimatikan | **Lulus** | Sakelar mati: baris Buku Stempel menutup, keterangan sakelar berganti; menyalakan lagi: baris kembali dan stempel utuh |

## Pemeriksaan tambahan

| Pemeriksaan | Hasil |
|---|---|
| Lembar pengenalan (stempel pertama sepanjang masa) | Lulus: tampil di Beranda dengan segel, judul, teks, Oke dan Atur di Akun; Oke menutup |
| Cadangan memicu evaluasi | Lulus (perbaikan `BackupRecordedGateway`): Cadangan pertama diraih setelah cadangan tersimpan |
| Layar Buku Stempel (Kaya) | Terbuka dengan adegan Tanuki, balon, kelompok, tanggal; lembar detail terbuka; tanpa galat Flutter di logcat |
| Pemulihan menggantikan catatan stempel tanpa menggabung (G-10) | Lulus: tanggal diraih menjadi 15 Nov, bukan 14 Nov |
| Snackbar "Stempel baru" | **Belum pernah terlihat di perangkat** (lihat F28-3) |
| Titik di ikon Akun (Beranda) | Tidak terbaca lewat `uiautomator`; tangkapan layar dikirim ke pemilik untuk dinilai mata |
| Kinerja kilap, daun, dan konfeti | **Belum terukur**: `dumpsys gfxinfo` tidak mencatat bingkai Flutter (0 bingkai) dan tidak ada perangkat kelas bawah. Perlu uji di ponsel Android kelas bawah |

## Temuan

| # | Sev. | Temuan | Rekomendasi |
|---|---|---|---|
| F28-1 | S2 (keputusan) | Pengguna baru nyaris tidak pernah melihat perayaan stempel pertama: dompet dan catatan pertama jatuh saat onboarding atau tur masih tampil, dan perayaan terhalang **tidak menunggu** (G-4, rupa §4.4). Skenario S1 di GAMIFICATION menulis hal berbeda (menunggu lalu tampil sekali) | Pilih: (a) terima, ubah S1 jadi "titik di Akun"; atau (b) izinkan **satu** perayaan tertunda yang tampil begitu Beranda aktif dan bebas halangan |
| F28-2 | S3 (belum pasti) | Sesudah pemulihan (boot ulang dalam proses), banner pengguna lama belum terlihat di papan status; baru terlihat setelah aplikasi dibuka ulang | Selidiki apakah koordinator di container baru memuat catatan tepat waktu; ulangi di perangkat nyata |
| F28-3 | S3 | Perayaan hanya bisa tampil bila stempel diraih saat Beranda aktif. Stempel dari tab lain, Akun, atau evaluasi saat aplikasi dibuka tidak pernah dirayakan (hanya titik). Praktis snackbar hanya muncul sesudah Catat (kembali ke Beranda) | Tambahkan ke keputusan F28-1; atau terima |
| F28-4 | S3 | Tonggak tersembunyi (Kotak masuk bersih, Pembayaran pertama diterima) tampil hanya bila diraih (belum ada pelacak "fitur dipakai", KT-G3) | Tinjau bila KT-G3 dianggap kurang |

## Yang belum diverifikasi

Perangkat nyata dari vendor berbeda, perangkat kelas bawah (kinerja kilap dan
konfeti, Gerak dikurangi pada pengaturan sistem), tema gelap dan preset warna
Pink pada segel, lebar 360dp dan teks 200%, bahasa en, snackbar dan titik Akun
secara visual, dan cadangan lalu pulihkan di perangkat lain.
