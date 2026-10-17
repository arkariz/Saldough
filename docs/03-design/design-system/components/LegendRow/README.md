# LegendRow

Baris legenda DonutChart di dalam kartu yang sama: penanda warna, nama kategori, persen, dan nominal dalam satu baris. Mengetuknya memilih kategori di donat (keputusan pemilik 12 Okt 2026, menggantikan ShareRow).

**Anatomi**
- `tk-swatch` 10px warna irisannya → nama (`body` 500, boleh membungkus) → persen (`label` `ink-2`, kolom 44px rata kanan) → nominal (`amount-sm`, rata kanan, minimal 92px). Tinggi minimal 48px. Pemisah `line` mulai sejajar nama.
- Urutan sama dengan irisan: kategori terbesar dulu (lima teratas), lalu "Lainnya (n kategori)" dengan ikon `expand_more`/`expand_less` 20px di belakang namanya, lalu Tanpa kategori (penanda `line-strong`).
- Baris anak Lainnya (`tk-legrow--child`): menjorok sejajar nama, tanpa penanda, nama `body-sm` `ink-2`.
- Nominal penuh tanpa tanda; pengeluaran `ink`, pemasukan `positive`. Nominal tersembunyi: `Rp•••••`, persen tetap.

**Interaksi**
- Ketuk baris atau irisan: kategori itu terpilih. Baris mendapat latar `surface-2` dan nama tebal, irisan lain meredup, tengah donat menampilkan kategorinya (lihat DonutChart). Ketuk lagi: kembali ke total.
- Ketuk Lainnya: memilih Lainnya dan membuka anak-anaknya. Ketuk anak: memilih anak itu (irisan Lainnya tetap yang menyala).
- Pindah ke rincian kategori lewat tautan "Lihat rincian {kategori}" di bawah donat, bukan dari baris. Satu ketukan selalu memilih, tidak pernah langsung berpindah layar.
- Tanpa kategori terpilih: di bawah donat muncul tombol `secondary` kecil "Beri kategori".
- Aksesibilitas: `button` dengan `aria-pressed`; label "Makan, 11%, Rp1.245.000".

**Disediakan pemakai:** warna, nama, persen, nominal, terpilih atau tidak, handler pilih.
