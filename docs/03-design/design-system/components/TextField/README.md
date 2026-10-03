# TextField

Kolom isian berlabel untuk teks dan angka di form, plus varian pencarian.

**Anatomi:** label `label` di atas → kolom 52px (`line-strong` 1px, fokus `brand` 2px) → bantuan `body-sm` di bawah.

**Aturan**
- Label selalu tampil di atas kolom; placeholder hanya contoh ("Contoh: Tabungan Mandiri"), bukan pengganti label.
- "Wajib" tidak ditulis; kolom opsional diberi "(opsional)" di labelnya.
- Galat: garis `danger` 2px, ikon `error`, kalimat cara memperbaikinya. Tampilkan saat kolom ditinggalkan atau saat menyimpan, bukan saat mengetik.
- Nominal di form memakai Keypad atau kolom angka dengan pemisah ribuan otomatis.
- Pencarian: pil `surface-2` tinggi 48px dengan ikon `search`.

**Disediakan pemakai:** label, nilai, placeholder, bantuan, pesan galat, jenis keyboard.
