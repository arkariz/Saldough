# HeroCard

Kartu terakota untuk satu angka utama layar, dengan kepala tanuki mengintip dari tepi bawah.

**Dipakai untuk:** total saldo di Beranda. Paling banyak satu per layar; layar lain memakai angka utama di atas `bg` tanpa kartu.

**Anatomi:** label `body-sm` → angka `amount-hero` dengan "Rp" diperkecil → tautan ke rinciannya ("Di 4 dompet") → kepala tanuki 96px di kanan bawah, menempel ke tepi bawah kartu.

**Aturan**
- Latar `brand`, semua teks dan ikon `on-brand`. Jangan menaruh badge atau tombol berwarna lain di dalamnya.
- Saat nominal disembunyikan (tombol mata), angka diganti titik; tanuki tetap.
- Huruf tetap Plus Jakarta Sans.

**Disediakan pemakai:** label, nilai dalam sen, teks tautan dan handler-nya.
