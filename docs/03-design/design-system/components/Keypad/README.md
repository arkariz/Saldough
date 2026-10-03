# Keypad

Papan angka untuk mengisi nominal di Catat, pengganti keyboard sistem.

**Aturan**
- Selalu tampil di sheet Catat; nominal di atasnya bergaya `amount-display` dengan pemisah ribuan otomatis.
- Tombol `000` untuk mempercepat nominal rupiah; hapus satu digit dengan `backspace`, tekan lama untuk mengosongkan.
- Tombol 52px, jarak 8px, latar `surface-2`, angka tabular.
- Getar ringan saat ditekan bila perangkat mendukung.
- Batas nominal mengikuti aplikasi; tolak digit yang melewatinya dengan getar, bukan pesan galat.

**Disediakan pemakai:** nilai saat ini (sen), handler ubah.
