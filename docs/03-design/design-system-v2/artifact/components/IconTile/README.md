# IconTile

Kotak ikon di kiri baris, kartu, dan banner. Dua keluarga ikon (KT-DS5, KT-DS6):

- **Ikon benda** (kategori, dompet, jenis transaksi, maskot) memakai ilustrasi **clay** SVG berwarna penuh di tile datar `ds-tile--clay`. Ikonnya tetap; tile mengikuti tema.
- **Ikon tindakan** (tambah, cari, kembali) memakai Material Symbols Outlined; tidak dibungkus clay.

**Ukuran:** `lg` 48 (maskot), `md` 40 (aksi cepat, baris transaksi), `sm` 36 (banner), `xs` 24 bulat (kotak statistik hero). Sudut 12px, bingkai 1px.
**Nada:** `neutral` (surface-sunken), `income`, `info`, `warning`, `solid` (hijau), dan warna kategori `orange/blue/purple/rose/teal/amber` (token `cat-*`). Hanya tombol Catat di navigasi yang bertimbul.

**Flutter:** `DsIconTile`; pemetaan ikon benda di `ClayIcons.forIcon`.
