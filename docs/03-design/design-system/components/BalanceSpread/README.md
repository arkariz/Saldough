# BalanceSpread

Sebaran saldo per dompet di layar Dompet: satu kartu yang ringkas secara bawaan dan bisa dibuka menjadi donat. Rujukan pemilik: `docs/03-design/proposals/wallet.html` (22 Okt 2026).

**Bentuk**
- Kartu (`tk-card tk-spread`) tanpa padding, tepat di bawah kartu Total saldo. Kepala adalah tombol penuh lebar: IconTile `brandsoft` dengan `donut_small`, judul "Sebaran saldo", subjudul "Ketuk untuk melihat diagram" / "Ketuk untuk menutup diagram", chevron `expand_more` yang berputar 180° saat terbuka.
- **Ringkas** (bawaan): bar proporsi 12px (celah 2px, tiap ruas minimal 3px supaya dompet kecil tetap terlihat), lalu kunci warna satu baris yang boleh membungkus: penanda 8px, nama, persen (`label`, `ink-2`).
- **Terbuka**: garis `line` di atas, DonutChart 216px dengan tengah "Total saldo", nominal, "4 dompet aktif"; lalu legenda dua kolom (`tk-legchip`, tinggi minimal 48px, penanda, nama, persen); lalu kaki: "Lihat total" (kiri, hanya bila ada pilihan) dan "Sembunyikan" (kanan), keduanya Button teks kecil.
- Warna per dompet memakai token `cat-*` dan sama di bar, donat, legenda, dan penanda di subjudul baris dompet. Warna tidak membawa makna status.

**Interaksi**
- Ketuk kepala: buka atau tutup. Menutup mengosongkan pilihan. Pudar masuk 200ms (kurangi gerakan: langsung).
- Ketuk irisan atau legenda: dompet itu terpilih. Irisan lain meredup ke 25%, legenda terpilih memakai garis `brand` dan latar `brand-soft`, tengah donat menjadi nama dompet, saldonya, dan "54% dari total saldo". Baris dompet yang sama di daftar ditandai (`tk-row.is-linked`: latar `surface-2` dan garis `brand` 4px di kiri).
- Ketuk dompet yang sama lagi atau "Lihat total": kembali ke total.
- Pilihan dan keadaan terbuka tidak disimpan; meninggalkan layar mengembalikannya ke ringkas.
- Irisan kecil digambar minimal 6px panjang busur; legenda tetap jalan utama dan jalan untuk pembaca layar.

**Aturan**
- Hanya tampil bila ada dua dompet aktif atau lebih. Satu dompet: kartu tidak ada dan baris dompet tidak menulis persen.
- Persen dibulatkan ke bilangan bulat, di bawah 0,5% ditulis "<1%" (sama dengan Analisis).
- Hanya saldo positif yang menjadi irisan; perlakuan dompet bersaldo nol atau negatif masih pertanyaan (B-66).
- Kata "dialokasikan", "teralokasi", atau "siap dipakai" tidak dipakai: saldo dompet bukan alokasi anggaran (aturan 5).
- Nominal tersembunyi: nominal di tengah donat menjadi `Rp•••••`; persen tetap tampil.
- Aksesibilitas: kepala `aria-expanded`; bar dan SVG `role="img"` dengan label "Sebaran saldo: BCA 54%, Tabungan 44%, …"; legenda `aria-pressed`; tengah donat `aria-live="polite"`.

**Disediakan pemakai:** daftar dompet aktif (nama, saldo, warna), total, keadaan terbuka, dompet terpilih.
