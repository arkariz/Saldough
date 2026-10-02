# Brief konten onboarding — Tanukonomy

**Dibuat:** 27 September 2026 · **Diperbarui:** 27 September 2026 (prompt
Gemini dihapus, diganti spesifikasi konten)
**Status:** Siap dipakai sebagai acuan membuat ilustrasi
**Berkaitan:** [ONBOARDING_PLAN.md](ONBOARDING_PLAN.md) bagian 3,
[ASO_NAME_RESEARCH.md](../../03-release/ASO_NAME_RESEARCH.md),
[ADR-015](../../02-architecture/adr/0015-adopsi-bahasa-visual-pixel-kas.md),
[ADR-016](../../02-architecture/adr/0016-revisi-palet-satu-peran-satu-warna.md)

Dokumen ini menjelaskan **apa yang harus disampaikan** tiap layar
onboarding — pesan, informasi, teks, dan isi visual — supaya ilustrasi bisa
dibuat dengan alat atau prompt apa pun. Dokumen ini sengaja tidak memuat
prompt.

## 1. Gambaran alur

Empat layar geser + satu layar akhir. Setiap layar: satu ilustrasi di atas,
judul, satu–dua kalimat isi, indikator halaman, **Lewati** di kanan atas,
**Lanjut** di bawah. Onboarding tampil sekali setelah instalasi baru (KO-1)
dan bisa dilewati kapan saja.

Onboarding **menjual manfaat, lalu memperkenalkan konsep** yang
mewujudkannya. Kalimatnya positif — apa yang pengguna dapat — bukan daftar
hal yang tidak dilakukan aplikasi. Sifat "mencatat" cukup tersampaikan lewat
kosakata (buku kas, catat, tercatat) dan maskot pencatat.

| # | Judul | Manfaat (value) | Konsep yang diperkenalkan |
|---|---|---|---|
| OB-1 | Semua uangmu, satu buku | Gambaran utuh keuangan pribadi | Buku kas dengan tiga pertanyaan: di mana, apa yang terjadi, ke mana direncanakan |
| OB-2 | Tahu di mana uangmu | Posisi uang selalu jelas | Dompet, saldo awal, saldo tercatat, total saldo |
| OB-3 | Catat dalam hitungan detik | Mencatat cepat dan ringan | CATAT; pemasukan, pengeluaran, transfer |
| OB-4 | Rencanakan, lalu pantau | Tahu masih di jalur atau tidak | Anggaran, periode, pos, terpakai, template |
| Akhir | Mulai dari dompet pertamamu | Langkah pertama yang jelas | Dompet pertama; tur singkat di tiap layar |

Freelance (penghasilan yang dikerjakan vs yang diterima) diperkenalkan di
tur Freelance saat layar itu pertama dibuka, bukan di onboarding (KO-2).

## 2. Maskot: tanuki juru catat

Dipakai di setiap ilustrasi, dengan tampilan yang sama di semua layar.

- **Siapa:** tanuki (anjing rakun Jepang) kecil dan gemuk yang bertugas
  mencatat. Terinspirasi patung tanuki Shigaraki penyambut tamu, yang
  membawa buku catatan utang-piutang (通い帳) sebagai lambang kepercayaan.
- **Ciri tetap:** bulu coklat keabuan hangat, topeng mata gelap khas
  tanuki, moncong dan perut krem, ekor tebal bergaris, **topi jerami**
  kecil, **syal terracotta**, membawa **buku kas coklat** dan **pensil
  kuning**.
- **Kepribadian:** tenang, ramah, teliti, bisa dipercaya. Bukan jahil,
  bukan serakah.
- **Tidak pernah:** memegang uang, koin, kartu, botol sake, atau daun; tidak
  ada daun di kepalanya (daun = lambang tanuki menipu dengan "uang daun").
- **Nama (usulan):** Nuki *(rekomendasi)*, Tanu, atau Kayo.

## 3. Konten per layar

Istilah mengikuti [glosarium](../../00-foundation/PROJECT_GLOSSARY.md)
(NFR-UX-002). Teks adalah draf `id`; terjemahan `en` ditulis di T-9.1.

### OB-1 — Semua uangmu, satu buku

- **Judul:** Semua uangmu, satu buku
- **Isi:** *Lihat di mana uangmu berada, apa saja yang terjadi padanya, dan
  ke mana kamu merencanakannya — semuanya di buku kas pribadimu.*
- **Manfaat:** gambaran utuh dan rasa kendali atas uang sendiri.
- **Konsep:** Tanukonomy adalah **buku kas pribadi** yang menjawab tiga
  pertanyaan. Ketiganya menjadi tiga layar berikutnya:
  **di mana** (Dompet), **apa yang terjadi** (Transaksi lewat CATAT),
  **ke mana direncanakan** (Anggaran).
- **Ilustrasi:** tanuki membuka buku kas besar dengan bangga; di halamannya
  tampak tiga gambar kecil tanpa tulisan — dompet, lembar catatan, dan
  kalender rencana — sebagai pratinjau tiga layar berikutnya.
- **Kesan:** hangat, teratur, "ini bukuku".

### OB-2 — Tahu di mana uangmu

- **Judul:** Tahu di mana uangmu
- **Isi:** *Rekening bank, e-wallet, dan uang tunai jadi dompet. Saldo tiap
  dompet dan totalnya selalu terlihat.*
- **Manfaat:** posisi uang saat ini jelas dalam sekali lihat.
- **Konsep:**
  - **Dompet** — tempat uang berada: bank, e-wallet, tunai, tabungan.
  - **Saldo awal** diisi saat dompet dibuat.
  - **Saldo tercatat** = saldo awal + seluruh transaksi dompet itu.
  - **Total saldo** di Beranda = jumlah saldo tercatat dompet aktif.
- **Ilustrasi:** tanuki di depan deretan wadah uang yang berbeda (gedung
  bank kecil, ponsel e-wallet, amplop tunai), masing-masing dengan papan
  nama kosong; satu papan lebih besar di atasnya melambangkan total.
- **Kesan:** rapi, semua pada tempatnya.

### OB-3 — Catat dalam hitungan detik

- **Judul:** Catat dalam hitungan detik
- **Isi:** *Uang masuk, keluar, atau pindah dompet — ketuk CATAT. Dompet
  yang biasa kamu pakai dan kategori favoritmu sudah menunggu.*
- **Manfaat:** mencatat terasa ringan, jadi kebiasaan harian bertahan.
- **Konsep:**
  - **CATAT** — satu tombol di tengah navigasi bawah untuk semua
    transaksi.
  - **Pemasukan** menambah saldo dompet, **pengeluaran** mengurangi.
  - **Transfer** memindahkan saldo antar dompetmu; totalmu tetap.
  - Dompet dan kategori terisi dari kebiasaanmu (UX-2, UX-3).
- **Ilustrasi:** tanuki menekan satu tombol besar terracotta berikon
  pensil; dari tombol itu keluar tiga arah: **hijau** masuk ke dompet,
  **merah** keluar dari dompet, **biru** berputar di antara dua dompet.
- **Kesan:** cepat, sederhana, satu tempat untuk semuanya.

### OB-4 — Rencanakan, lalu pantau

- **Judul:** Rencanakan, lalu pantau
- **Isi:** *Susun anggaran per minggu atau bulan dengan pos-pos
  belanjamu. Saldo tetap utuh, dan kamu melihat berapa yang sudah terpakai
  dari rencana.*
- **Manfaat:** tahu kapan masih di jalur dan kapan perlu menahan diri.
- **Konsep:**
  - **Anggaran** — rencana untuk satu **periode** dan satu dompet.
  - **Pos anggaran** — baris rencana, misalnya belanja mingguan atau
    listrik.
  - **Terpakai** naik dari transaksi yang ditautkan ke pos dalam
    periodenya; **sisa** = rencana − terpakai.
  - **Template** untuk susunan yang berulang.
- **Ilustrasi:** tanuki menunjuk papan rencana berisi daftar centang dan
  bilah progres bersegmen yang terisi sebagian; di sampingnya dompet
  tertutup rapi.
- **Kesan:** tenang, berpikir ke depan.

### Layar akhir — Mulai dari dompet pertamamu

- **Judul:** Mulai dari dompet pertamamu
- **Isi:** *Tambahkan satu dompet, lalu catat transaksi pertamamu. Di tiap
  layar, tanuki akan menunjukkan jalannya.*
- **Tombol utama:** Buat Dompet Pertama · **Tautan:** Nanti saja
- **Manfaat:** langkah pertama yang jelas dan kecil.
- **Konsep:** dompet pertama membuka semua fitur lain; **tur singkat**
  menyambut di setiap layar saat pertama dibuka.
- **Ilustrasi:** tanuki melambai di samping peti kayu terbuka yang masih
  kosong, siap diisi — selaras dengan ilustrasi keadaan kosong di aplikasi.
- **Kesan:** menyambut, siap mulai.

## 4. Aturan visual untuk semua ilustrasi

| Aturan | Rincian |
|---|---|
| Gaya | Pixel art 16-bit, garis luar gelap `#1E1B19`, bayangan datar — selaras ikon aplikasi (ADR-015) |
| Tanpa teks | Tidak ada huruf atau angka di gambar; semua teks ditulis aplikasi (bisa diterjemahkan) |
| Warna makna | Hijau `#16A34A` = uang masuk, merah `#DC2626` = uang keluar, biru `#2563EB` = transfer — **hanya** dipakai untuk makna itu (ADR-016); aksi = terracotta `#C2410C` |
| Latar | Transparan (atau polos yang mudah dihapus), supaya cocok di mode terang dan gelap |
| Rasio | Adegan 4:3; maskot tunggal 1:1 |
| Konsistensi | Maskot, topi jerami, syal, dan ukuran piksel sama di semua layar |

## 5. Serah terima ke aplikasi

- File PNG: `onboarding_1.png` … `onboarding_5.png`, opsional
  `mascot_idle.png`.
- Periksa sebelum mengirim: tidak ada teks di gambar; maskot tidak memegang
  uang, koin, kartu, botol, atau daun; hijau/merah/biru hanya di OB-3;
  tampilan maskot sama antarlayar.
- Dipasang di T-9.3 (skala *nearest neighbor*, tanpa penghalusan).
