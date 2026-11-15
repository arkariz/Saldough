# Draf catatan rilis: Buku Stempel (Fase 28)

**Status:** draf agen, **belum disetujui pemilik** dan **belum boleh masuk
`release_notes/`** (catatan yang belum disetujui tidak boleh ada di `main`;
lihat [RELEASE_NOTES.md](RELEASE_NOTES.md)). Salin menjadi
`release_notes/<build>-0.json` setelah nomor build ditetapkan dan pemilik
menyetujui lewat tinjauan PR. Verifikasi perangkat T-28.8 harus lulus lebih dulu.

Isi disusun dari [GAMIFICATION.md](../01-product/features/GAMIFICATION.md) dan
T-28.4–T-28.6. Hanya perubahan yang terasa pengguna; tanpa tanda seru; nama menu
sesuai `assets/i18n`.

```json
{
  "version": "<versi di pubspec.yaml>",
  "groups": [
    {
      "category": "new",
      "notes": [
        {
          "id": "Buku Stempel: stempel kecil untuk hal yang berhasil kamu lakukan, dari dompet pertama sampai cadangan pertama. Tidak ada yang hilang.",
          "en": "Stamp Book: small stamps for things you got done, from your first wallet to your first backup. Nothing ever goes away."
        },
        {
          "id": "Perayaan stempel bisa dimatikan kapan saja di Akun › Aplikasi.",
          "en": "You can turn stamp celebrations off anytime in Account › App."
        }
      ]
    }
  ]
}
```

## Catatan untuk email rilis penguji (skill `release-email`)

- Pengguna lama mendapat stempel yang sudah memenuhi syarat secara diam-diam,
  dengan satu banner pengenalan di Beranda.
- Yang perlu diuji penguji: stempel muncul tepat sekali, tidak ada perayaan saat
  tur atau Catat, sakelar mati menyembunyikan Buku Stempel, dan stempel ikut
  cadangan lalu pulihkan.
- Dua kunci Remote Config (`stamps_enabled`, `stamps_disabled_ids`) harus sudah
  dibuat di konsol Firebase sebelum rilis, agar saklar jarak jauh bisa dipakai.
