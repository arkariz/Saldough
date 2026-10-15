# DonutChart

Porsi tiap kategori dari total pengeluaran atau pemasukan satu periode, dengan total di tengah dan legenda LegendRow di kartu yang sama. Bisa diketuk untuk melihat satu kategori. Dipakai di Riwayat › Analisis (keputusan pemilik 12 Okt 2026).

**Bentuk**
- Lingkar 216px, tebal 24px, di tengah kartu. Irisan mulai jam 12 dan berputar searah jarum jam, urut sama dengan daftar di bawahnya: kategori terbesar dulu, lalu Lainnya, lalu Tanpa kategori.
- Celah 2px warna `surface` antaririsan, supaya irisan bersebelahan tetap terbedakan walau warnanya mirip. Ujung irisan rata.
- Warna irisan: token kategori `cat-*` (warna ikon, bukan `-bg`), tetap per kategori di semua periode, misalnya Makan `cat-orange`, Belanja `cat-green`. Lainnya `cat-slate`, Tanpa kategori `line-strong`. Warna tidak membawa makna status.
- Tengah: jenis (`body-sm` `ink-2`) dan total (`amount-lg`, pemasukan `positive`). Ini angka utama layar; tidak ada `amount-hero` lain di Analisis.
- Pembanding (`tk-cmp`) di bawah donat, rata tengah.

**Interaksi**
- Tanpa pilihan: tengah = jenis dan total; pembanding total di bawahnya.
- Kategori terpilih (ketuk irisan atau LegendRow): irisan lain meredup ke 25% (150ms; kurangi gerakan: langsung), tengah = nama kategori, nominal, dan "11% dari pengeluaran"; di bawah donat pembanding kategori itu ("↑ Rp295.000 dibanding rata-rata 3 bulan", atau Badge "baru bulan ini"), lalu tautan "Lihat rincian Makan". Tanpa kategori terpilih: tombol "Beri kategori" sebagai ganti tautan.
- Ketuk kategori yang sama lagi: kembali ke total. Pilihan tidak disimpan; pindah periode atau jenis mengosongkannya.
- Irisan kecil sulit diketuk; LegendRow adalah jalan utama dan jalan untuk pembaca layar. Tengah donat `aria-live="polite"`.
- Transfer tidak pernah menjadi irisan.

**Aturan**
- Donat tidak berdiri sendiri: legendanya LegendRow di kartu yang sama, dengan penanda warna dan persen tertulis. Porsi terbaca tanpa warna. Urutan dalam kartu: donat, pembanding, tautan, sorotan (0–3 baris), legenda, lalu kaki kartu transfer.
- Transfer di periode itu tampil di kaki kartu (`tk-card__foot`, latar `surface-2`): tile transfer, judul "Dipindahkan antardompet" dengan nominal `ink-2` tanpa tanda di kanan, dan di bawahnya "Tidak mengurangi total uangmu". Satu dompet: dua baris, "Transfer masuk" dan "Transfer keluar". Tanpa transfer: kaki kartu tidak ada. Tanpa penanda warna, persen, atau irisan, supaya jelas bukan bagian porsi.
- Irisan yang sangat kecil (di bawah 1%) tetap digambar minimal 1,5px panjang busur supaya terlihat ada.
- Nominal tersembunyi: total di tengah menjadi `Rp•••••`, irisan tetap tampil.
- Aksesibilitas: SVG `role="img"` dengan label ringkas "Pengeluaran September: Belanja 27%, Cicilan 26%, …".
- Tanpa animasi berputar; boleh pudar masuk 250ms (kurangi gerakan: langsung tampil).

**Disediakan pemakai:** jenis, total, daftar irisan (nilai, warna, nama, persen).
