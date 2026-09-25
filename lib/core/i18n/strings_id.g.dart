///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'strings.g.dart';

// Path: <root>
typedef TranslationsId = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  _meta = meta ?? TranslationMetadata(
		    locale: AppLocale.id,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		_meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <id>.
	final TranslationMetadata<AppLocale, Translations> _meta;
	@override TranslationMetadata<AppLocale, Translations> get $meta => _meta;

	/// Access flat map
	dynamic operator[](String key) => _meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$id app = Translations$app$id.internal(_root);
	late final Translations$common$id common = Translations$common$id.internal(_root);
	late final Translations$appShell$id appShell = Translations$appShell$id.internal(_root);
	late final Translations$record$id record = Translations$record$id.internal(_root);
	late final Translations$transaction$id transaction = Translations$transaction$id.internal(_root);
	late final Translations$wallet$id wallet = Translations$wallet$id.internal(_root);
	late final Translations$budget$id budget = Translations$budget$id.internal(_root);
	late final Translations$freelance$id freelance = Translations$freelance$id.internal(_root);
}

// Path: app
class Translations$app$id {
	Translations$app$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Saldough'
	String get title => 'Saldough';
}

// Path: common
class Translations$common$id {
	Translations$common$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Simpan'
	String get save => 'Simpan';

	/// id: 'Batal'
	String get cancel => 'Batal';

	/// id: 'Hapus'
	String get delete => 'Hapus';

	/// id: 'Sunting'
	String get edit => 'Sunting';

	/// id: 'Tambah'
	String get add => 'Tambah';

	/// id: 'Coba lagi'
	String get retry => 'Coba lagi';

	/// id: 'Memuat...'
	String get loading => 'Memuat...';

	/// id: 'Ada yang salah. Coba lagi.'
	String get genericErrorMessage => 'Ada yang salah. Coba lagi.';

	/// id: 'Hapus?'
	String get confirmDeleteTitle => 'Hapus?';
}

// Path: appShell
class Translations$appShell$id {
	Translations$appShell$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Beranda'
	String get homeTabLabel => 'Beranda';

	/// id: 'Anggaran'
	String get budgetTabLabel => 'Anggaran';

	/// id: 'Catat'
	String get recordAction => 'Catat';

	/// id: 'Transaksi'
	String get transactionsTabLabel => 'Transaksi';

	/// id: 'Dompet'
	String get walletsTabLabel => 'Dompet';

	/// id: 'Segera hadir.'
	String get comingSoonMessage => 'Segera hadir.';
}

// Path: record
class Translations$record$id {
	Translations$record$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Catat Transaksi'
	String get sheetTitle => 'Catat Transaksi';

	/// id: 'Catat Pemasukan'
	String get incomeAction => 'Catat Pemasukan';

	/// id: 'Catat Pengeluaran'
	String get expenseAction => 'Catat Pengeluaran';

	/// id: 'Catat Transfer'
	String get transferAction => 'Catat Transfer';

	/// id: 'Masuk ke Dompet'
	String get toWalletFieldLabel => 'Masuk ke Dompet';

	/// id: 'Dari Dompet'
	String get fromWalletFieldLabel => 'Dari Dompet';

	/// id: 'Ke Dompet'
	String get destinationWalletFieldLabel => 'Ke Dompet';

	/// id: 'Tanggal'
	String get dateFieldLabel => 'Tanggal';

	/// id: 'Kategori (opsional)'
	String get categoryFieldHint => 'Kategori (opsional)';

	/// id: 'Tulis catatan singkat'
	String get noteFieldHint => 'Tulis catatan singkat';

	/// id: 'Belum ada dompet. Buat dompet dulu di tab Dompet.'
	String get noWalletsMessage => 'Belum ada dompet. Buat dompet dulu di tab Dompet.';

	/// id: 'Dompet asal dan tujuan tidak boleh sama.'
	String get sameWalletWarning => 'Dompet asal dan tujuan tidak boleh sama.';

	/// id: 'Pemasukan tercatat.'
	String get incomeSavedMessage => 'Pemasukan tercatat.';

	/// id: 'Pengeluaran tercatat.'
	String get expenseSavedMessage => 'Pengeluaran tercatat.';

	/// id: 'Transfer tercatat.'
	String get transferSavedMessage => 'Transfer tercatat.';

	/// id: 'Saldough hanya mencatat riwayat manual. Aplikasi ini tidak pernah memindahkan uang secara otomatis.'
	String get disclaimerMessage => 'Saldough hanya mencatat riwayat manual. Aplikasi ini tidak pernah memindahkan uang secara otomatis.';

	/// id: 'Catat uang yang masuk ke salah satu dompet.'
	String get incomeSubtitle => 'Catat uang yang masuk ke salah satu dompet.';

	/// id: 'Catat uang yang keluar dari salah satu dompet.'
	String get expenseSubtitle => 'Catat uang yang keluar dari salah satu dompet.';

	/// id: 'Catat perpindahan uang antar dompet milikmu sendiri.'
	String get transferSubtitle => 'Catat perpindahan uang antar dompet milikmu sendiri.';

	/// id: 'Menambah saldo dompet'
	String get incomeEffectLabel => 'Menambah saldo dompet';

	/// id: 'Mengurangi saldo dompet'
	String get expenseEffectLabel => 'Mengurangi saldo dompet';

	/// id: 'Total saldo tidak berubah'
	String get transferEffectLabel => 'Total saldo tidak berubah';

	/// id: 'Belum dipilih'
	String get walletNotSelectedPrompt => 'Belum dipilih';

	/// id: 'Menyimpan...'
	String get savingMessage => 'Menyimpan...';

	/// id: 'Gaji'
	String get categorySuggestionSalary => 'Gaji';

	/// id: 'Bonus'
	String get categorySuggestionBonus => 'Bonus';

	/// id: 'Penjualan'
	String get categorySuggestionSales => 'Penjualan';

	/// id: 'Hadiah'
	String get categorySuggestionGift => 'Hadiah';

	/// id: 'Makan'
	String get categorySuggestionFood => 'Makan';

	/// id: 'Belanja'
	String get categorySuggestionShopping => 'Belanja';

	/// id: 'Transport'
	String get categorySuggestionTransport => 'Transport';

	/// id: 'Tagihan'
	String get categorySuggestionBills => 'Tagihan';

	/// id: 'Pilih jenis peristiwa finansial yang ingin dicatat.'
	String get sheetSubtitle => 'Pilih jenis peristiwa finansial yang ingin dicatat.';

	/// id: 'Info Pencatatan'
	String get noticeTitle => 'Info Pencatatan';

	/// id: 'Contoh:'
	String get examplesLabel => 'Contoh:';

	/// id: 'Uang Masuk'
	String get incomeBadge => 'Uang Masuk';

	/// id: 'Uang Keluar'
	String get expenseBadge => 'Uang Keluar';

	/// id: 'Mutasi Internal'
	String get transferBadge => 'Mutasi Internal';

	/// id: 'Pilih Pemasukan'
	String get pickIncomeAction => 'Pilih Pemasukan';

	/// id: 'Pilih Pengeluaran'
	String get pickExpenseAction => 'Pilih Pengeluaran';

	/// id: 'Pilih Transfer'
	String get pickTransferAction => 'Pilih Transfer';

	/// id: 'Tarik Tunai'
	String get transferExampleCash => 'Tarik Tunai';

	/// id: 'Top-up e-Wallet'
	String get transferExampleTopUp => 'Top-up e-Wallet';

	/// id: 'Pindah Rekening'
	String get transferExampleMove => 'Pindah Rekening';

	/// id: 'Langkah 2 // Transaksi'
	String get stepLabel => 'Langkah 2 // Transaksi';

	/// id: 'Sunting // Transaksi'
	String get editStepLabel => 'Sunting // Transaksi';

	/// id: 'Aturan Kas: Saldo Terpotong'
	String get expenseRuleTitle => 'Aturan Kas: Saldo Terpotong';

	/// id: 'Pengeluaran langsung memotong saldo dompet yang kamu pilih di bawah ini.'
	String get expenseRuleBody => 'Pengeluaran langsung memotong saldo dompet yang kamu pilih di bawah ini.';

	/// id: 'Penting'
	String get transferNoticeTitle => 'Penting';

	/// id: 'Ini catatan perpindahan uang manual yang sudah kamu lakukan di dunia nyata. Bukan transfer bank otomatis.'
	String get transferNoticeBody => 'Ini catatan perpindahan uang manual yang sudah kamu lakukan di dunia nyata. Bukan transfer bank otomatis.';

	/// id: 'Nominal Masuk'
	String get amountLabelIncome => 'Nominal Masuk';

	/// id: 'Nominal Pengeluaran'
	String get amountLabelExpense => 'Nominal Pengeluaran';

	/// id: 'Nominal Transfer'
	String get amountLabelTransfer => 'Nominal Transfer';

	/// id: 'Bersihkan'
	String get clearAmountAction => 'Bersihkan';

	/// id: 'Kategori'
	String get categorySectionLabel => 'Kategori';

	/// id: 'Opsional'
	String get optionalHint => 'Opsional';

	/// id: 'Lainnya'
	String get categoryOtherLabel => 'Lainnya';

	/// id: 'Ketik kategori sendiri'
	String get categoryCustomHint => 'Ketik kategori sendiri';

	/// id: 'Hiburan'
	String get categorySuggestionEntertainment => 'Hiburan';

	/// id: 'Investasi'
	String get categorySuggestionInvestment => 'Investasi';

	/// id: 'Dompet Sumber Dana'
	String get expenseWalletSectionLabel => 'Dompet Sumber Dana';

	/// id: 'Keterangan / Catatan'
	String get noteSectionLabel => 'Keterangan / Catatan';

	/// id: 'Saldo berkurang'
	String get balanceDecreasesCaption => 'Saldo berkurang';

	/// id: 'Saldo bertambah'
	String get balanceIncreasesCaption => 'Saldo bertambah';

	/// id: 'Saldo $wallet akan bertambah $amount saat dicatat.'
	String incomeSummary({required Object wallet, required Object amount}) => 'Saldo ${wallet} akan bertambah ${amount} saat dicatat.';

	/// id: 'Saldo $wallet akan berkurang $amount saat dicatat.'
	String expenseSummary({required Object wallet, required Object amount}) => 'Saldo ${wallet} akan berkurang ${amount} saat dicatat.';

	/// id: 'Ringkasan Catatan Mutasi'
	String get transferSummaryTitle => 'Ringkasan Catatan Mutasi';

	/// id: 'Dompet $wallet berkurang $amount'
	String transferSummaryFrom({required Object wallet, required Object amount}) => 'Dompet ${wallet} berkurang ${amount}';

	/// id: 'Dompet $wallet bertambah $amount'
	String transferSummaryTo({required Object wallet, required Object amount}) => 'Dompet ${wallet} bertambah ${amount}';

	/// id: '*Catatan internal Saldough. Tidak mendebit atau mengirim uang di rekening bank sungguhan.'
	String get footnote => '*Catatan internal Saldough. Tidak mendebit atau mengirim uang di rekening bank sungguhan.';

	/// id: 'Saldo'
	String get balanceLabel => 'Saldo';

	/// id: 'Pilih kategori'
	String get categoryPlaceholder => 'Pilih kategori';

	/// id: 'Tanpa kategori'
	String get categoryNoneLabel => 'Tanpa kategori';

	/// id: 'Tahap 1 // Pilih Jenis'
	String get choiceStepLabel => 'Tahap 1 // Pilih Jenis';

	/// id: 'Luar'
	String get flowOutside => 'Luar';

	/// id: 'Dompet'
	String get flowWallet => 'Dompet';

	/// id: 'Dompet asal'
	String get flowSourceWallet => 'Dompet asal';

	/// id: 'Dompet tujuan'
	String get flowTargetWallet => 'Dompet tujuan';

	/// id: 'Pos anggaran'
	String get budgetItemLabel => 'Pos anggaran';

	/// id: 'Tanpa anggaran'
	String get budgetItemNone => 'Tanpa anggaran';

	/// id: 'Opsional. Hanya pos anggaran aktif yang cocok dengan dompet di atas yang ditawarkan.'
	String get budgetItemHelp => 'Opsional. Hanya pos anggaran aktif yang cocok dengan dompet di atas yang ditawarkan.';

	/// id: 'Honor freelance?'
	String get freelanceCalloutTitle => 'Honor freelance?';

	/// id: 'Kerja selesai belum tentu uangnya sudah masuk. Catat jam kerja dan pembayarannya di Freelance.'
	String get freelanceCalloutBody => 'Kerja selesai belum tentu uangnya sudah masuk. Catat jam kerja dan pembayarannya di Freelance.';
}

// Path: transaction
class Translations$transaction$id {
	Translations$transaction$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Transaksi'
	String get pageTitle => 'Transaksi';

	/// id: 'Cari catatan / kategori...'
	String get searchHint => 'Cari catatan / kategori...';

	/// id: 'Status log bulan ini'
	String get monthStatusLabel => 'Status log bulan ini';

	/// id: '$count log aktif'
	String logCountBadge({required Object count}) => '${count} log aktif';

	/// id: 'Arus Bersih (Netto)'
	String get netFlowLabel => 'Arus Bersih (Netto)';

	/// id: 'Semua $count'
	String allFilterLabel({required Object count}) => 'Semua ${count}';

	/// id: 'Masuk $count'
	String incomeFilterLabel({required Object count}) => 'Masuk ${count}';

	/// id: 'Keluar $count'
	String expenseFilterLabel({required Object count}) => 'Keluar ${count}';

	/// id: 'Mutasi $count'
	String transferFilterLabel({required Object count}) => 'Mutasi ${count}';

	/// id: 'Semua Dompet'
	String get walletFilterAllLabel => 'Semua Dompet';

	/// id: 'Dompet'
	String get walletFilterLabel => 'Dompet';

	/// id: 'Semua Kategori'
	String get categoryFilterAllLabel => 'Semua Kategori';

	/// id: 'Kategori'
	String get categoryFilterLabel => 'Kategori';

	/// id: 'Hari Ini'
	String get todayLabel => 'Hari Ini';

	/// id: 'Kemarin'
	String get yesterdayLabel => 'Kemarin';

	/// id: '+MASUK'
	String get incomeBadge => '+MASUK';

	/// id: '-KELUAR'
	String get expenseBadge => '-KELUAR';

	/// id: '# MUTASI'
	String get transferBadge => '# MUTASI';

	/// id: 'Tanpa judul'
	String get untitledTransaction => 'Tanpa judul';

	/// id: 'Inventaris Kosong'
	String get emptyMonthBadge => 'Inventaris Kosong';

	/// id: 'Belum ada transaksi'
	String get emptyMonthTitle => 'Belum ada transaksi';

	/// id: 'Catat pemasukan, pengeluaran, atau transfer untuk mulai melihat riwayat buku kas harianmu.'
	String get emptyMonthSubtitle => 'Catat pemasukan, pengeluaran, atau transfer untuk mulai melihat riwayat buku kas harianmu.';

	/// id: 'Catat Transaksi Sekarang'
	String get emptyMonthCta => 'Catat Transaksi Sekarang';

	/// id: 'Panduan Catatan Kas'
	String get emptyGuideTitle => 'Panduan Catatan Kas';

	/// id: 'Pemasukan'
	String get emptyGuideIncomeTitle => 'Pemasukan';

	/// id: 'Menambah saldo dompet pilihan secara riil dan tercatat di kas.'
	String get emptyGuideIncomeDescription => 'Menambah saldo dompet pilihan secara riil dan tercatat di kas.';

	/// id: 'Pengeluaran'
	String get emptyGuideExpenseTitle => 'Pengeluaran';

	/// id: 'Memotong saldo dompet dan menghitung kuota batas anggaran bulanan.'
	String get emptyGuideExpenseDescription => 'Memotong saldo dompet dan menghitung kuota batas anggaran bulanan.';

	/// id: 'Transfer Antar Dompet'
	String get emptyGuideTransferTitle => 'Transfer Antar Dompet';

	/// id: 'Memindahkan catatan saldo antar dompet tanpa mengubah total kekayaan.'
	String get emptyGuideTransferDescription => 'Memindahkan catatan saldo antar dompet tanpa mengubah total kekayaan.';

	/// id: 'Semua transaksi dicatat manual • Privasi 100% aman di perangkatmu'
	String get trustFooterMessage => 'Semua transaksi dicatat manual • Privasi 100% aman di perangkatmu';

	/// id: 'Tidak ada transaksi yang cocok dengan filter'
	String get emptyFilterTitle => 'Tidak ada transaksi yang cocok dengan filter';

	/// id: 'Coba ganti atau hapus filter yang sedang aktif.'
	String get emptyFilterSubtitle => 'Coba ganti atau hapus filter yang sedang aktif.';

	/// id: 'Hapus filter'
	String get clearFiltersButton => 'Hapus filter';

	/// id: 'Transaksi gagal dimuat'
	String get loadErrorTitle => 'Transaksi gagal dimuat';

	/// id: 'Periksa lagi lalu coba muat ulang.'
	String get loadErrorSubtitle => 'Periksa lagi lalu coba muat ulang.';

	/// id: 'Kembali'
	String get detailBackLabel => 'Kembali';

	/// id: 'Pemasukan tercatat'
	String get detailIncomeTitle => 'Pemasukan tercatat';

	/// id: 'Pengeluaran tercatat'
	String get detailExpenseTitle => 'Pengeluaran tercatat';

	/// id: 'Transfer tercatat'
	String get detailTransferTitle => 'Transfer tercatat';

	/// id: 'Jenis Entri'
	String get detailTypeLabel => 'Jenis Entri';

	/// id: 'Pemasukan'
	String get detailIncomeType => 'Pemasukan';

	/// id: 'Pengeluaran'
	String get detailExpenseType => 'Pengeluaran';

	/// id: 'Transfer antar dompet'
	String get detailTransferType => 'Transfer antar dompet';

	/// id: 'Kategori'
	String get detailCategoryLabel => 'Kategori';

	/// id: 'Dompet Tujuan'
	String get detailIncomeWalletLabel => 'Dompet Tujuan';

	/// id: 'Dompet Sumber'
	String get detailExpenseWalletLabel => 'Dompet Sumber';

	/// id: 'Saldo saat ini'
	String get detailCurrentBalance => 'Saldo saat ini';

	/// id: 'Catatan Manual'
	String get detailNoteLabel => 'Catatan Manual';

	/// id: 'Dari'
	String get detailFromLabel => 'Dari';

	/// id: 'Ke'
	String get detailToLabel => 'Ke';

	/// id: 'Jumlah'
	String get detailAmountLabel => 'Jumlah';

	/// id: 'Catatan ini adalah rekaman manual di Saldough. Saldo dompet dihitung dari data yang kamu masukkan, tanpa terhubung ke rekening bank.'
	String get detailManualNote => 'Catatan ini adalah rekaman manual di Saldough. Saldo dompet dihitung dari data yang kamu masukkan, tanpa terhubung ke rekening bank.';

	/// id: 'Ubah Catatan Ini'
	String get editAction => 'Ubah Catatan Ini';

	/// id: 'Hapus Catatan dari Riwayat'
	String get deleteAction => 'Hapus Catatan dari Riwayat';

	/// id: 'Ubah Catatan'
	String get editSheetTitle => 'Ubah Catatan';

	/// id: 'Simpan Perubahan'
	String get saveChangesAction => 'Simpan Perubahan';

	/// id: 'Hapus catatan ini?'
	String get deleteConfirmTitle => 'Hapus catatan ini?';

	/// id: 'Catatan dihapus dari riwayat, dan saldo dompet dihitung ulang tanpa catatan ini.'
	String get deleteConfirmMessage => 'Catatan dihapus dari riwayat, dan saldo dompet dihitung ulang tanpa catatan ini.';

	/// id: 'Perubahan tersimpan.'
	String get updatedMessage => 'Perubahan tersimpan.';

	/// id: 'Catatan dihapus.'
	String get deletedMessage => 'Catatan dihapus.';

	/// id: 'Anggaran'
	String get budgetLabel => 'Anggaran';

	/// id: 'Lihat anggaran'
	String get openBudgetAction => 'Lihat anggaran';

	/// id: 'Pemasukan ini dicatat dari pembayaran freelance. Untuk mengubahnya, batalkan penerimaannya di Freelance.'
	String get detailFreelanceNote => 'Pemasukan ini dicatat dari pembayaran freelance. Untuk mengubahnya, batalkan penerimaannya di Freelance.';
}

// Path: wallet
class Translations$wallet$id {
	Translations$wallet$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Dompet Saya'
	String get heading => 'Dompet Saya';

	/// id: 'Posisi saldo kas saat ini'
	String get subtitle => 'Posisi saldo kas saat ini';

	/// id: '$count kantong aktif'
	String activeBadge({required Object count}) => '${count} kantong aktif';

	/// id: 'Total saldo semua dompet'
	String get totalLabel => 'Total saldo semua dompet';

	/// id: 'Catatan Manual'
	String get manualNoteTitle => 'Catatan Manual';

	/// id: 'Saldo dihitung dari catatan yang kamu buat sendiri, bukan sinkronisasi otomatis dari bank.'
	String get manualNoteBody => 'Saldo dihitung dari catatan yang kamu buat sendiri, bukan sinkronisasi otomatis dari bank.';

	/// id: 'Daftar Dompet'
	String get listHeading => 'Daftar Dompet';

	/// id: 'Saldo Aktif'
	String get balanceLabel => 'Saldo Aktif';

	/// id: 'Tambah Dompet Baru'
	String get addAction => 'Tambah Dompet Baru';

	/// id: 'Dompet Nonaktif'
	String get inactiveHeading => 'Dompet Nonaktif';

	/// id: 'Nonaktif'
	String get inactiveBadge => 'Nonaktif';

	/// id: 'Bank / Rekening'
	String get typeBank => 'Bank / Rekening';

	/// id: 'Uang Tunai'
	String get typeCash => 'Uang Tunai';

	/// id: 'Dompet Digital'
	String get typeEwallet => 'Dompet Digital';

	/// id: 'Tabungan'
	String get typeSavings => 'Tabungan';

	/// id: 'Kartu'
	String get typeCard => 'Kartu';

	/// id: 'Belum ada dompet'
	String get emptyBadge => 'Belum ada dompet';

	/// id: 'Belum ada dompet tercatat'
	String get emptyTitle => 'Belum ada dompet tercatat';

	/// id: 'Tambahkan dompet pertama untuk mulai mencatat posisi uangmu. Bisa berupa rekening bank, e-wallet, atau uang tunai di saku.'
	String get emptyBody => 'Tambahkan dompet pertama untuk mulai mencatat posisi uangmu. Bisa berupa rekening bank, e-wallet, atau uang tunai di saku.';

	/// id: 'Dompet gagal dimuat'
	String get loadErrorTitle => 'Dompet gagal dimuat';

	/// id: 'Data dompet tidak terbaca. Coba lagi.'
	String get loadErrorSubtitle => 'Data dompet tidak terbaca. Coba lagi.';

	/// id: 'Tambah Dompet Baru'
	String get addTitle => 'Tambah Dompet Baru';

	/// id: 'Ubah Dompet'
	String get editTitle => 'Ubah Dompet';

	/// id: 'Dompet // Baru'
	String get addStepLabel => 'Dompet // Baru';

	/// id: 'Dompet // Ubah'
	String get editStepLabel => 'Dompet // Ubah';

	/// id: 'Nama Dompet'
	String get nameLabel => 'Nama Dompet';

	/// id: 'Contoh: Tabungan Mandiri, OVO, Brankas Tunai'
	String get nameHint => 'Contoh: Tabungan Mandiri, OVO, Brankas Tunai';

	/// id: 'Wajib'
	String get nameRequiredHint => 'Wajib';

	/// id: 'Maks. 24 karakter'
	String get nameMaxHint => 'Maks. 24 karakter';

	/// id: 'Pilih Ikon'
	String get iconLabel => 'Pilih Ikon';

	/// id: 'Saldo Awal Saat Ini'
	String get initialBalanceLabel => 'Saldo Awal Saat Ini';

	/// id: 'Saldo awal adalah uang yang ada saat ini, sebelum pencatatan transaksi dimulai. Ia pernyataan keadaan, bukan setoran, jadi tidak muncul di riwayat.'
	String get initialBalanceHelp => 'Saldo awal adalah uang yang ada saat ini, sebelum pencatatan transaksi dimulai. Ia pernyataan keadaan, bukan setoran, jadi tidak muncul di riwayat.';

	/// id: 'Saldo Tercatat Saat Ini'
	String get currentBalanceLabel => 'Saldo Tercatat Saat Ini';

	/// id: 'Mengubah saldo awal menghitung ulang saldo tercatat. Untuk selisih dengan uang nyata, catat pemasukan atau pengeluaran lewat CATAT.'
	String get editBalanceNote => 'Mengubah saldo awal menghitung ulang saldo tercatat. Untuk selisih dengan uang nyata, catat pemasukan atau pengeluaran lewat CATAT.';

	/// id: 'Dompet aktif'
	String get activeSwitchLabel => 'Dompet aktif';

	/// id: 'Dompet nonaktif tidak muncul di pemilih dompet. Transaksinya tetap tersimpan dan dihitung.'
	String get activeSwitchHelp => 'Dompet nonaktif tidak muncul di pemilih dompet. Transaksinya tetap tersimpan dan dihitung.';

	/// id: 'Simpan Dompet'
	String get saveAddAction => 'Simpan Dompet';

	/// id: 'Hapus Dompet'
	String get deleteAction => 'Hapus Dompet';

	/// id: 'Hanya bisa dihapus kalau belum punya transaksi sama sekali. Kalau sudah, nonaktifkan saja.'
	String get deleteHelp => 'Hanya bisa dihapus kalau belum punya transaksi sama sekali. Kalau sudah, nonaktifkan saja.';

	/// id: 'Hapus dompet?'
	String get deleteConfirmTitle => 'Hapus dompet?';

	/// id: 'Dompet $name akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.'
	String deleteConfirmMessage({required Object name}) => 'Dompet ${name} akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.';

	/// id: 'Dompet tersimpan.'
	String get savedMessage => 'Dompet tersimpan.';

	/// id: 'Dompet diperbarui.'
	String get updatedMessage => 'Dompet diperbarui.';

	/// id: 'Dompet dihapus.'
	String get deletedMessage => 'Dompet dihapus.';

	/// id: 'Dompet ini sudah punya transaksi, jadi tidak bisa dihapus. Nonaktifkan saja.'
	String get deleteBlockedMessage => 'Dompet ini sudah punya transaksi, jadi tidak bisa dihapus. Nonaktifkan saja.';

	/// id: 'Data tersimpan lokal dan privat di perangkatmu.'
	String get privacyNote => 'Data tersimpan lokal dan privat di perangkatmu.';

	/// id: 'Kembali'
	String get detailBackLabel => 'Kembali';

	/// id: 'Sunting'
	String get detailEditAction => 'Sunting';

	/// id: 'Transaksi Bulan Ini'
	String get detailRecentHeading => 'Transaksi Bulan Ini';

	/// id: 'Pemasukan'
	String get detailIncomeLabel => 'Pemasukan';

	/// id: 'Pengeluaran'
	String get detailExpenseLabel => 'Pengeluaran';

	/// id: 'Belum ada transaksi'
	String get detailRecentEmptyTitle => 'Belum ada transaksi';

	/// id: 'Belum ada transaksi bulan ini untuk dompet ini.'
	String get detailRecentEmpty => 'Belum ada transaksi bulan ini untuk dompet ini.';

	/// id: 'Lihat Semua Transaksi'
	String get detailViewAllAction => 'Lihat Semua Transaksi';

	/// id: 'Catat Transaksi Dompet Ini'
	String get detailRecordAction => 'Catat Transaksi Dompet Ini';

	/// id: 'Transfer masuk'
	String get detailTransferInLabel => 'Transfer masuk';

	/// id: 'Transfer keluar'
	String get detailTransferOutLabel => 'Transfer keluar';

	/// id: 'Perubahan saldo'
	String get detailBalanceChangeLabel => 'Perubahan saldo';
}

// Path: budget
class Translations$budget$id {
	Translations$budget$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Anggaran Saya'
	String get heading => 'Anggaran Saya';

	/// id: '$count aktif'
	String activeBadge({required Object count}) => '${count} aktif';

	/// id: 'Total rencana anggaran aktif'
	String get summaryTitle => 'Total rencana anggaran aktif';

	/// id: '$percent% terpakai'
	String summaryPercent({required Object percent}) => '${percent}% terpakai';

	/// id: 'Rencana'
	String get plannedLabel => 'Rencana';

	/// id: 'Terpakai'
	String get spentLabel => 'Terpakai';

	/// id: 'Sisa'
	String get remainingLabel => 'Sisa';

	/// id: 'Terpakai ($percent%)'
	String spentPercentLabel({required Object percent}) => 'Terpakai (${percent}%)';

	/// id: 'Anggaran adalah rencana belanja, bukan pemotongan saldo dompet. Saldo baru berkurang saat pengeluaran atau transfer dicatat.'
	String get summaryNote => 'Anggaran adalah rencana belanja, bukan pemotongan saldo dompet. Saldo baru berkurang saat pengeluaran atau transfer dicatat.';

	/// id: 'Semua'
	String get filterAll => 'Semua';

	/// id: 'Aktif'
	String get filterActive => 'Aktif';

	/// id: 'Selesai'
	String get filterFinished => 'Selesai';

	/// id: 'Nonaktif'
	String get filterArchived => 'Nonaktif';

	/// id: 'Dompet'
	String get filterWalletLabel => 'Dompet';

	/// id: 'Semua dompet'
	String get filterWalletAll => 'Semua dompet';

	/// id: 'Buat Anggaran Baru'
	String get addAction => 'Buat Anggaran Baru';

	/// id: 'Mingguan'
	String get periodWeekly => 'Mingguan';

	/// id: 'Bulanan'
	String get periodMonthly => 'Bulanan';

	/// id: 'Belum terpakai'
	String get itemStatusPlanned => 'Belum terpakai';

	/// id: 'Terpakai sebagian'
	String get itemStatusPartiallySpent => 'Terpakai sebagian';

	/// id: 'Selesai'
	String get itemStatusCompleted => 'Selesai';

	/// id: 'Lewat anggaran'
	String get itemStatusOverspent => 'Lewat anggaran';

	/// id: '$count pos'
	String itemCount({required Object count}) => '${count} pos';

	/// id: 'Slot rencana kosong'
	String get emptyBadge => 'Slot rencana kosong';

	/// id: 'Belum ada anggaran'
	String get emptyTitle => 'Belum ada anggaran';

	/// id: 'Rencanakan batas belanja mingguan atau bulanan untuk satu dompet. Membuat anggaran tidak mengurangi saldo dompet.'
	String get emptyBody => 'Rencanakan batas belanja mingguan atau bulanan untuk satu dompet. Membuat anggaran tidak mengurangi saldo dompet.';

	/// id: 'Tidak ada anggaran yang cocok'
	String get emptyFilteredTitle => 'Tidak ada anggaran yang cocok';

	/// id: 'Tidak ada anggaran dengan status dan dompet yang dipilih.'
	String get emptyFilteredBody => 'Tidak ada anggaran dengan status dan dompet yang dipilih.';

	/// id: 'Tampilkan semua anggaran'
	String get resetFilterAction => 'Tampilkan semua anggaran';

	/// id: 'Buat dompet dulu'
	String get noWalletTitle => 'Buat dompet dulu';

	/// id: 'Setiap anggaran terikat ke satu dompet. Tambahkan dompet di tab Dompet, lalu kembali ke sini.'
	String get noWalletBody => 'Setiap anggaran terikat ke satu dompet. Tambahkan dompet di tab Dompet, lalu kembali ke sini.';

	/// id: 'Anggaran gagal dimuat'
	String get loadErrorTitle => 'Anggaran gagal dimuat';

	/// id: 'Data anggaran tidak bisa dibaca. Coba lagi.'
	String get loadErrorSubtitle => 'Data anggaran tidak bisa dibaca. Coba lagi.';

	/// id: 'Anggaran tersimpan.'
	String get savedMessage => 'Anggaran tersimpan.';

	/// id: 'Perubahan anggaran tersimpan.'
	String get updatedMessage => 'Perubahan anggaran tersimpan.';

	/// id: 'Anggaran dihapus.'
	String get deletedMessage => 'Anggaran dihapus.';

	/// id: 'Anggaran diarsipkan.'
	String get archivedMessage => 'Anggaran diarsipkan.';

	/// id: 'Anggaran diaktifkan kembali.'
	String get unarchivedMessage => 'Anggaran diaktifkan kembali.';

	/// id: 'Anggaran baru'
	String get addStepLabel => 'Anggaran baru';

	/// id: 'Sunting anggaran'
	String get editStepLabel => 'Sunting anggaran';

	/// id: 'Buat Anggaran'
	String get addTitle => 'Buat Anggaran';

	/// id: 'Ubah Anggaran'
	String get editTitle => 'Ubah Anggaran';

	/// id: 'Aturan Anggaran'
	String get ruleTitle => 'Aturan Anggaran';

	/// id: 'Rencana ini tidak memotong saldo dompetmu. Saldo hanya berkurang saat kamu mencatat transaksi.'
	String get ruleBody => 'Rencana ini tidak memotong saldo dompetmu. Saldo hanya berkurang saat kamu mencatat transaksi.';

	/// id: 'Nama anggaran'
	String get nameLabel => 'Nama anggaran';

	/// id: 'Contoh: Kebutuhan Rumah Tangga'
	String get nameHint => 'Contoh: Kebutuhan Rumah Tangga';

	/// id: 'Wajib'
	String get requiredHint => 'Wajib';

	/// id: 'Dompet terkait'
	String get walletLabel => 'Dompet terkait';

	/// id: 'Hanya pengeluaran dan transfer keluar dari dompet ini yang terhitung ke anggaran.'
	String get walletHelp => 'Hanya pengeluaran dan transfer keluar dari dompet ini yang terhitung ke anggaran.';

	/// id: 'Saldo: $amount'
	String walletBalance({required Object amount}) => 'Saldo: ${amount}';

	/// id: 'Periode'
	String get periodLabel => 'Periode';

	/// id: 'Mulai'
	String get startDateLabel => 'Mulai';

	/// id: '$start – $end'
	String periodRange({required Object start, required Object end}) => '${start} – ${end}';

	/// id: 'Pos anggaran'
	String get itemsLabel => 'Pos anggaran';

	/// id: 'Rincian rencana belanja atau rencana transfer. Total rencana anggaran adalah jumlah seluruh pos.'
	String get itemsHelp => 'Rincian rencana belanja atau rencana transfer. Total rencana anggaran adalah jumlah seluruh pos.';

	/// id: 'Tambah Pos'
	String get addItemAction => 'Tambah Pos';

	/// id: 'Simpan Anggaran'
	String get saveAddAction => 'Simpan Anggaran';

	/// id: 'Arsipkan Anggaran'
	String get archiveAction => 'Arsipkan Anggaran';

	/// id: 'Aktifkan Kembali'
	String get unarchiveAction => 'Aktifkan Kembali';

	/// id: 'Anggaran nonaktif disembunyikan dari daftar aktif. Transaksi yang tertaut tetap tercatat.'
	String get archiveHelp => 'Anggaran nonaktif disembunyikan dari daftar aktif. Transaksi yang tertaut tetap tercatat.';

	/// id: 'Hapus Anggaran'
	String get deleteAction => 'Hapus Anggaran';

	/// id: 'Hapus anggaran?'
	String get deleteConfirmTitle => 'Hapus anggaran?';

	/// id: 'Anggaran "$name" beserta posnya akan dihapus. Transaksi yang tertaut tetap tercatat dan saldo dompet tidak berubah.'
	String deleteConfirmMessage({required Object name}) => 'Anggaran "${name}" beserta posnya akan dihapus. Transaksi yang tertaut tetap tercatat dan saldo dompet tidak berubah.';

	/// id: 'Tambah Pos'
	String get itemAddTitle => 'Tambah Pos';

	/// id: 'Ubah Pos'
	String get itemEditTitle => 'Ubah Pos';

	/// id: 'Nama pos'
	String get itemNameLabel => 'Nama pos';

	/// id: 'Contoh: Beras'
	String get itemNameHint => 'Contoh: Beras';

	/// id: 'Nominal'
	String get itemModeAmount => 'Nominal';

	/// id: 'Jumlah × harga'
	String get itemModeItemized => 'Jumlah × harga';

	/// id: 'Nominal rencana'
	String get itemAmountLabel => 'Nominal rencana';

	/// id: 'Jumlah'
	String get itemQuantityLabel => 'Jumlah';

	/// id: 'Harga satuan'
	String get itemUnitPriceLabel => 'Harga satuan';

	/// id: 'Total pos'
	String get itemTotalLabel => 'Total pos';

	/// id: '$quantity × $price'
	String itemItemizedDetail({required Object quantity, required Object price}) => '${quantity} × ${price}';

	/// id: 'Simpan Pos'
	String get itemSaveAction => 'Simpan Pos';

	/// id: 'Hapus Pos'
	String get itemDeleteAction => 'Hapus Pos';

	/// id: 'Daftar Anggaran'
	String get detailBackLabel => 'Daftar Anggaran';

	/// id: 'Sunting anggaran'
	String get detailEditAction => 'Sunting anggaran';

	/// id: 'Catat Pengeluaran'
	String get detailRecordExpenseAction => 'Catat Pengeluaran';

	/// id: 'Catat Transfer'
	String get detailRecordTransferAction => 'Catat Transfer';

	/// id: 'Pos Anggaran'
	String get detailItemsHeading => 'Pos Anggaran';

	/// id: 'Anggaran ini belum punya pos. Tambahkan pos lewat Sunting supaya pengeluaran bisa ditautkan.'
	String get detailNoItems => 'Anggaran ini belum punya pos. Tambahkan pos lewat Sunting supaya pengeluaran bisa ditautkan.';

	/// id: 'Transaksi Tertaut'
	String get detailLinkedHeading => 'Transaksi Tertaut';

	/// id: 'Belum ada transaksi yang tertaut ke anggaran ini.'
	String get detailLinkedEmpty => 'Belum ada transaksi yang tertaut ke anggaran ini.';

	/// id: 'Cara kerja pos anggaran'
	String get detailHowTitle => 'Cara kerja pos anggaran';

	/// id: 'Catat lewat tombol di tiap pos. Pos pengeluaran menghitung pengeluaran dari $wallet; pos transfer menghitung transfer dari $wallet ke dompet tujuannya. Anggaran sendiri tidak pernah memotong saldo.'
	String detailHowBody({required Object wallet}) => 'Catat lewat tombol di tiap pos. Pos pengeluaran menghitung pengeluaran dari ${wallet}; pos transfer menghitung transfer dari ${wallet} ke dompet tujuannya. Anggaran sendiri tidak pernah memotong saldo.';

	/// id: 'Dompet tidak ditemukan'
	String get unknownWallet => 'Dompet tidak ditemukan';

	/// id: 'Total rencana anggaran'
	String get totalPlannedLabel => 'Total rencana anggaran';

	/// id: 'Tambahkan minimal satu pos. Transaksi dicatat ke pos, jadi anggaran tanpa pos tidak bisa melacak pengeluaran.'
	String get itemsRequiredHint => 'Tambahkan minimal satu pos. Transaksi dicatat ke pos, jadi anggaran tanpa pos tidak bisa melacak pengeluaran.';

	/// id: 'Saldo $wallet tetap'
	String walletUnchangedNote({required Object wallet}) => 'Saldo ${wallet} tetap';

	/// id: 'Jenis pos'
	String get itemKindLabel => 'Jenis pos';

	/// id: 'Pengeluaran'
	String get itemKindExpense => 'Pengeluaran';

	/// id: 'Transfer'
	String get itemKindTransfer => 'Transfer';

	/// id: 'Jenis tidak bisa diganti karena pos ini sudah punya transaksi tertaut.'
	String get itemKindLockedHint => 'Jenis tidak bisa diganti karena pos ini sudah punya transaksi tertaut.';

	/// id: 'Dompet tujuan'
	String get itemTargetWalletLabel => 'Dompet tujuan';

	/// id: 'Hanya transfer dari dompet anggaran ke dompet ini yang terhitung ke pos.'
	String get itemTargetWalletHelp => 'Hanya transfer dari dompet anggaran ke dompet ini yang terhitung ke pos.';

	/// id: 'Butuh dompet aktif lain sebagai tujuan transfer.'
	String get itemNoTargetWallet => 'Butuh dompet aktif lain sebagai tujuan transfer.';

	/// id: 'Ke $wallet'
	String itemTransferTo({required Object wallet}) => 'Ke ${wallet}';

	/// id: 'Pos transfer "$name" menuju dompet anggaran itu sendiri. Ganti dompet tujuan posnya atau dompet anggarannya.'
	String itemTargetConflict({required Object name}) => 'Pos transfer "${name}" menuju dompet anggaran itu sendiri. Ganti dompet tujuan posnya atau dompet anggarannya.';
}

// Path: freelance
class Translations$freelance$id {
	Translations$freelance$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Freelance'
	String get title => 'Freelance';

	/// id: 'Worklog ($count)'
	String worklogTab({required Object count}) => 'Worklog (${count})';

	/// id: 'Pembayaran ($count)'
	String paymentsTab({required Object count}) => 'Pembayaran (${count})';

	/// id: 'Data freelance gagal dimuat'
	String get loadErrorTitle => 'Data freelance gagal dimuat';

	/// id: 'Aturan kas freelance'
	String get ruleTitle => 'Aturan kas freelance';

	/// id: 'Jam kerja yang selesai tidak menambah saldo dompet. Uang baru masuk ke dompet saat pembayarannya dicatat diterima.'
	String get ruleBody => 'Jam kerja yang selesai tidak menambah saldo dompet. Uang baru masuk ke dompet saat pembayarannya dicatat diterima.';

	/// id: 'Ringkasan upah & jam'
	String get summaryTitle => 'Ringkasan upah & jam';

	/// id: 'Waktu kerja'
	String get totalHoursLabel => 'Waktu kerja';

	/// id: '$hours jam'
	String hoursValue({required Object hours}) => '${hours} jam';

	/// id: 'jam'
	String get hourShort => 'jam';

	/// id: '$count proyek'
	String projectCount({required Object count}) => '${count} proyek';

	/// id: 'Total diperoleh'
	String get earnedLabel => 'Total diperoleh';

	/// id: 'Jam × tarif, sebelum potongan'
	String get earnedCaption => 'Jam × tarif, sebelum potongan';

	/// id: 'Sudah diterima'
	String get paidLabel => 'Sudah diterima';

	/// id: 'Pembayarannya sudah dicatat'
	String get paidCaption => 'Pembayarannya sudah dicatat';

	/// id: 'Belum diterima'
	String get unpaidLabel => 'Belum diterima';

	/// id: 'Belum ditagih atau tertunda'
	String get unpaidCaption => 'Belum ditagih atau tertunda';

	/// id: '$percent% sudah diterima'
	String paidRatio({required Object percent}) => '${percent}% sudah diterima';

	/// id: 'Proyek'
	String get projectsLabel => 'Proyek';

	/// id: 'Belum ada proyek. Tambahkan klien atau proyek beserta tarif per jamnya dulu.'
	String get projectsEmpty => 'Belum ada proyek. Tambahkan klien atau proyek beserta tarif per jamnya dulu.';

	/// id: '+ Proyek'
	String get projectAddAction => '+ Proyek';

	/// id: 'Proyek freelance'
	String get projectStepLabel => 'Proyek freelance';

	/// id: 'Tambah Proyek'
	String get projectAddTitle => 'Tambah Proyek';

	/// id: 'Ubah Proyek'
	String get projectEditTitle => 'Ubah Proyek';

	/// id: 'Nama klien atau proyek'
	String get projectNameLabel => 'Nama klien atau proyek';

	/// id: 'Contoh: Studio Koding'
	String get projectNameHint => 'Contoh: Studio Koding';

	/// id: 'Wajib'
	String get requiredHint => 'Wajib';

	/// id: 'Tarif per jam'
	String get hourlyRateLabel => 'Tarif per jam';

	/// id: 'Tarif bawaan untuk entri baru. Mengubahnya tidak mengubah entri yang sudah dicatat.'
	String get hourlyRateHelp => 'Tarif bawaan untuk entri baru. Mengubahnya tidak mengubah entri yang sudah dicatat.';

	/// id: 'Potongan'
	String get deductionsLabel => 'Potongan';

	/// id: 'Dipotong dari gaji kotor setiap pembayaran, misalnya pajak. Mengubahnya tidak mengubah pembayaran yang sudah dibuat.'
	String get deductionsHelp => 'Dipotong dari gaji kotor setiap pembayaran, misalnya pajak. Mengubahnya tidak mengubah pembayaran yang sudah dibuat.';

	/// id: 'Tambah potongan'
	String get deductionAddAction => 'Tambah potongan';

	/// id: 'Potongan'
	String get deductionTitle => 'Potongan';

	/// id: 'Nama potongan'
	String get deductionLabelLabel => 'Nama potongan';

	/// id: 'Contoh: Pajak'
	String get deductionLabelHint => 'Contoh: Pajak';

	/// id: 'Persen'
	String get deductionKindPercentage => 'Persen';

	/// id: 'Nominal tetap'
	String get deductionKindFixed => 'Nominal tetap';

	/// id: 'Persen dari gaji kotor'
	String get deductionPercentLabel => 'Persen dari gaji kotor';

	/// id: 'Paling banyak satu angka di belakang koma, misalnya 2,5.'
	String get deductionPercentHelp => 'Paling banyak satu angka di belakang koma, misalnya 2,5.';

	/// id: 'Nominal per pembayaran'
	String get deductionAmountLabel => 'Nominal per pembayaran';

	/// id: 'Simpan potongan'
	String get deductionSaveAction => 'Simpan potongan';

	/// id: 'Hapus potongan'
	String get deductionRemoveAction => 'Hapus potongan';

	/// id: 'Simpan proyek'
	String get projectSaveAction => 'Simpan proyek';

	/// id: 'Hapus proyek'
	String get projectDeleteAction => 'Hapus proyek';

	/// id: 'Proyek yang sudah punya entri worklog tidak bisa dihapus.'
	String get projectDeleteLockedHint => 'Proyek yang sudah punya entri worklog tidak bisa dihapus.';

	/// id: 'Hapus proyek?'
	String get projectDeleteConfirmTitle => 'Hapus proyek?';

	/// id: 'Proyek "$name" akan dihapus.'
	String projectDeleteConfirmMessage({required Object name}) => 'Proyek "${name}" akan dihapus.';

	/// id: 'Proyek ini sudah punya entri worklog, jadi tidak bisa dihapus.'
	String get projectDeleteRefused => 'Proyek ini sudah punya entri worklog, jadi tidak bisa dihapus.';

	/// id: 'Proyek tersimpan.'
	String get projectSavedMessage => 'Proyek tersimpan.';

	/// id: 'Perubahan proyek tersimpan.'
	String get projectUpdatedMessage => 'Perubahan proyek tersimpan.';

	/// id: 'Proyek dihapus.'
	String get projectDeletedMessage => 'Proyek dihapus.';

	/// id: 'Proyek'
	String get projectLabel => 'Proyek';

	/// id: 'Pilih proyek'
	String get projectPick => 'Pilih proyek';

	/// id: 'Daftar entri jam kerja'
	String get entriesLabel => 'Daftar entri jam kerja';

	/// id: 'Belum ada entri worklog.'
	String get entriesEmpty => 'Belum ada entri worklog.';

	/// id: 'Tambah Worklog'
	String get entryAddAction => 'Tambah Worklog';

	/// id: 'Log pekerjaan'
	String get entryStepLabel => 'Log pekerjaan';

	/// id: 'Tambah Worklog'
	String get entryAddTitle => 'Tambah Worklog';

	/// id: 'Ubah Worklog'
	String get entryEditTitle => 'Ubah Worklog';

	/// id: 'Mencatat jam kerja tidak menambah saldo dompet mana pun. Uangnya baru tercatat saat pembayarannya diterima.'
	String get entryRuleBody => 'Mencatat jam kerja tidak menambah saldo dompet mana pun. Uangnya baru tercatat saat pembayarannya diterima.';

	/// id: 'Tanggal kerja'
	String get workDateLabel => 'Tanggal kerja';

	/// id: 'Durasi pengerjaan'
	String get hoursLabel => 'Durasi pengerjaan';

	/// id: 'Terisi dari tarif proyek. Ubah kalau tarif entri ini berbeda.'
	String get entryRateHelp => 'Terisi dari tarif proyek. Ubah kalau tarif entri ini berbeda.';

	/// id: 'Catatan'
	String get noteLabel => 'Catatan';

	/// id: 'Apa yang dikerjakan (opsional)'
	String get noteHint => 'Apa yang dikerjakan (opsional)';

	/// id: 'Simpan Worklog'
	String get entrySaveAction => 'Simpan Worklog';

	/// id: 'Nominal ini tercatat sebagai diperoleh, belum diterima.'
	String get entrySaveHint => 'Nominal ini tercatat sebagai diperoleh, belum diterima.';

	/// id: 'Hapus entri'
	String get entryDeleteAction => 'Hapus entri';

	/// id: 'Hapus entri worklog?'
	String get entryDeleteConfirmTitle => 'Hapus entri worklog?';

	/// id: 'Entri ini akan dihapus. Saldo dompet tidak berubah.'
	String get entryDeleteConfirmMessage => 'Entri ini akan dihapus. Saldo dompet tidak berubah.';

	/// id: 'Entri yang sudah masuk pembayaran tidak bisa diubah atau dihapus.'
	String get entryLockedMessage => 'Entri yang sudah masuk pembayaran tidak bisa diubah atau dihapus.';

	/// id: 'Worklog tersimpan.'
	String get entrySavedMessage => 'Worklog tersimpan.';

	/// id: 'Perubahan worklog tersimpan.'
	String get entryUpdatedMessage => 'Perubahan worklog tersimpan.';

	/// id: 'Worklog dihapus.'
	String get entryDeletedMessage => 'Worklog dihapus.';

	/// id: '$hours jam × $rate'
	String hoursTimesRate({required Object hours, required Object rate}) => '${hours} jam × ${rate}';

	/// id: 'Belum ditagih'
	String get statusUnbilled => 'Belum ditagih';

	/// id: 'Tertunda'
	String get statusPending => 'Tertunda';

	/// id: 'Diterima'
	String get statusPaid => 'Diterima';

	/// id: 'Perkiraan diterima $date'
	String expectedOn({required Object date}) => 'Perkiraan diterima ${date}';

	/// id: 'Diterima $date di $wallet'
	String receivedOn({required Object date, required Object wallet}) => 'Diterima ${date} di ${wallet}';

	/// id: 'Proyek terhapus'
	String get unknownProject => 'Proyek terhapus';

	/// id: 'dompet terhapus'
	String get unknownWallet => 'dompet terhapus';

	/// id: 'Tekan Catat Diterima hanya saat uangnya benar-benar sudah masuk ke rekeningmu. Aksi ini membuat satu catatan pemasukan dan menambah saldo dompet pilihan.'
	String get paymentsRuleBody => 'Tekan Catat Diterima hanya saat uangnya benar-benar sudah masuk ke rekeningmu. Aksi ini membuat satu catatan pemasukan dan menambah saldo dompet pilihan.';

	/// id: 'Tertunda (bersih)'
	String get pendingTotalLabel => 'Tertunda (bersih)';

	/// id: 'Diterima (bersih)'
	String get paidTotalLabel => 'Diterima (bersih)';

	/// id: '$count pembayaran'
	String paymentCount({required Object count}) => '${count} pembayaran';

	/// id: 'Buat Pembayaran'
	String get paymentAddAction => 'Buat Pembayaran';

	/// id: 'Semua entri worklog sudah masuk pembayaran.'
	String get paymentAddDisabledHint => 'Semua entri worklog sudah masuk pembayaran.';

	/// id: 'Menunggu pembayaran'
	String get pendingSectionLabel => 'Menunggu pembayaran';

	/// id: 'Tidak ada pembayaran tertunda.'
	String get pendingEmpty => 'Tidak ada pembayaran tertunda.';

	/// id: 'Riwayat pembayaran diterima'
	String get paidSectionLabel => 'Riwayat pembayaran diterima';

	/// id: 'Belum ada pembayaran yang diterima.'
	String get paidEmpty => 'Belum ada pembayaran yang diterima.';

	/// id: 'Pembayaran freelance'
	String get paymentStepLabel => 'Pembayaran freelance';

	/// id: 'Buat Pembayaran'
	String get paymentAddTitle => 'Buat Pembayaran';

	/// id: 'Membuat pembayaran hanya mengelompokkan jam kerja jadi satu tagihan. Saldo dompet belum berubah sampai pembayaran dicatat diterima.'
	String get paymentCreateRuleBody => 'Membuat pembayaran hanya mengelompokkan jam kerja jadi satu tagihan. Saldo dompet belum berubah sampai pembayaran dicatat diterima.';

	/// id: 'Entri ditagih: $count ($hours jam)'
	String paymentEntriesLabel({required Object count, required Object hours}) => 'Entri ditagih: ${count} (${hours} jam)';

	/// id: '$count entri · $hours jam'
	String paymentEntriesSummary({required Object count, required Object hours}) => '${count} entri · ${hours} jam';

	/// id: 'Perkiraan tanggal diterima'
	String get expectedDateLabel => 'Perkiraan tanggal diterima';

	/// id: 'Gaji kotor'
	String get grossPayLabel => 'Gaji kotor';

	/// id: 'Gaji bersih'
	String get netPayLabel => 'Gaji bersih';

	/// id: 'Potongan tidak boleh sama dengan atau melebihi gaji kotor.'
	String get netPayNotPositive => 'Potongan tidak boleh sama dengan atau melebihi gaji kotor.';

	/// id: 'Buat Pembayaran'
	String get paymentCreateAction => 'Buat Pembayaran';

	/// id: 'Ubah tanggal'
	String get paymentChangeDateAction => 'Ubah tanggal';

	/// id: 'Hapus'
	String get paymentDeleteAction => 'Hapus';

	/// id: 'Hapus pembayaran?'
	String get paymentDeleteConfirmTitle => 'Hapus pembayaran?';

	/// id: 'Pembayaran tertunda ini dihapus dan entrinya kembali belum ditagih. Saldo dompet tidak berubah.'
	String get paymentDeleteConfirmMessage => 'Pembayaran tertunda ini dihapus dan entrinya kembali belum ditagih. Saldo dompet tidak berubah.';

	/// id: 'Entri yang dipilih sudah ditagih atau bukan milik proyek ini.'
	String get paymentEntriesInvalid => 'Entri yang dipilih sudah ditagih atau bukan milik proyek ini.';

	/// id: 'Pembayaran yang sudah diterima tidak bisa dihapus. Batalkan penerimaannya dulu.'
	String get paymentPaidLocked => 'Pembayaran yang sudah diterima tidak bisa dihapus. Batalkan penerimaannya dulu.';

	/// id: 'Pembayaran ini sudah dicatat diterima.'
	String get paymentAlreadyPaid => 'Pembayaran ini sudah dicatat diterima.';

	/// id: 'Pembayaran dibuat.'
	String get paymentCreatedMessage => 'Pembayaran dibuat.';

	/// id: 'Tanggal pembayaran diperbarui.'
	String get paymentUpdatedMessage => 'Tanggal pembayaran diperbarui.';

	/// id: 'Pembayaran dihapus.'
	String get paymentDeletedMessage => 'Pembayaran dihapus.';

	/// id: 'Catat Pembayaran Diterima'
	String get receiveTitle => 'Catat Pembayaran Diterima';

	/// id: 'Pencatatan, bukan pembayaran'
	String get receiveRuleTitle => 'Pencatatan, bukan pembayaran';

	/// id: 'Saldough tidak menerima atau memindahkan uang. Catat hanya uang yang sudah benar-benar masuk ke rekeningmu; saldo dompet pilihan akan bertambah sebesar gaji bersih.'
	String get receiveRuleBody => 'Saldough tidak menerima atau memindahkan uang. Catat hanya uang yang sudah benar-benar masuk ke rekeningmu; saldo dompet pilihan akan bertambah sebesar gaji bersih.';

	/// id: 'Nominal diterima'
	String get receiveAmountLabel => 'Nominal diterima';

	/// id: 'Dompet penerima'
	String get receiveWalletLabel => 'Dompet penerima';

	/// id: 'Tanggal diterima'
	String get receiveDateLabel => 'Tanggal diterima';

	/// id: 'Pembayaran freelance $project'
	String receiveNoteDefault({required Object project}) => 'Pembayaran freelance ${project}';

	/// id: 'Catat Diterima'
	String get receiveAction => 'Catat Diterima';

	/// id: 'Pembayaran dicatat diterima. Saldo dompet bertambah.'
	String get paymentReceivedMessage => 'Pembayaran dicatat diterima. Saldo dompet bertambah.';

	/// id: 'Batalkan penerimaan'
	String get receiptCancelAction => 'Batalkan penerimaan';

	/// id: 'Batalkan penerimaan?'
	String get receiptCancelConfirmTitle => 'Batalkan penerimaan?';

	/// id: 'Catatan pemasukannya dihapus dan saldo dompet berkurang kembali. Pembayaran kembali tertunda.'
	String get receiptCancelConfirmMessage => 'Catatan pemasukannya dihapus dan saldo dompet berkurang kembali. Pembayaran kembali tertunda.';

	/// id: 'Penerimaan dibatalkan. Pembayaran kembali tertunda.'
	String get receiptCancelledMessage => 'Penerimaan dibatalkan. Pembayaran kembali tertunda.';

	/// id: 'Ubah'
	String get changeAction => 'Ubah';

	/// id: 'Hapus pemasukan'
	String get receiptCancelConfirmAction => 'Hapus pemasukan';
}

/// The flat map containing all translations for locale <id>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Saldough',
			'common.save' => 'Simpan',
			'common.cancel' => 'Batal',
			'common.delete' => 'Hapus',
			'common.edit' => 'Sunting',
			'common.add' => 'Tambah',
			'common.retry' => 'Coba lagi',
			'common.loading' => 'Memuat...',
			'common.genericErrorMessage' => 'Ada yang salah. Coba lagi.',
			'common.confirmDeleteTitle' => 'Hapus?',
			'appShell.homeTabLabel' => 'Beranda',
			'appShell.budgetTabLabel' => 'Anggaran',
			'appShell.recordAction' => 'Catat',
			'appShell.transactionsTabLabel' => 'Transaksi',
			'appShell.walletsTabLabel' => 'Dompet',
			'appShell.comingSoonMessage' => 'Segera hadir.',
			'record.sheetTitle' => 'Catat Transaksi',
			'record.incomeAction' => 'Catat Pemasukan',
			'record.expenseAction' => 'Catat Pengeluaran',
			'record.transferAction' => 'Catat Transfer',
			'record.toWalletFieldLabel' => 'Masuk ke Dompet',
			'record.fromWalletFieldLabel' => 'Dari Dompet',
			'record.destinationWalletFieldLabel' => 'Ke Dompet',
			'record.dateFieldLabel' => 'Tanggal',
			'record.categoryFieldHint' => 'Kategori (opsional)',
			'record.noteFieldHint' => 'Tulis catatan singkat',
			'record.noWalletsMessage' => 'Belum ada dompet. Buat dompet dulu di tab Dompet.',
			'record.sameWalletWarning' => 'Dompet asal dan tujuan tidak boleh sama.',
			'record.incomeSavedMessage' => 'Pemasukan tercatat.',
			'record.expenseSavedMessage' => 'Pengeluaran tercatat.',
			'record.transferSavedMessage' => 'Transfer tercatat.',
			'record.disclaimerMessage' => 'Saldough hanya mencatat riwayat manual. Aplikasi ini tidak pernah memindahkan uang secara otomatis.',
			'record.incomeSubtitle' => 'Catat uang yang masuk ke salah satu dompet.',
			'record.expenseSubtitle' => 'Catat uang yang keluar dari salah satu dompet.',
			'record.transferSubtitle' => 'Catat perpindahan uang antar dompet milikmu sendiri.',
			'record.incomeEffectLabel' => 'Menambah saldo dompet',
			'record.expenseEffectLabel' => 'Mengurangi saldo dompet',
			'record.transferEffectLabel' => 'Total saldo tidak berubah',
			'record.walletNotSelectedPrompt' => 'Belum dipilih',
			'record.savingMessage' => 'Menyimpan...',
			'record.categorySuggestionSalary' => 'Gaji',
			'record.categorySuggestionBonus' => 'Bonus',
			'record.categorySuggestionSales' => 'Penjualan',
			'record.categorySuggestionGift' => 'Hadiah',
			'record.categorySuggestionFood' => 'Makan',
			'record.categorySuggestionShopping' => 'Belanja',
			'record.categorySuggestionTransport' => 'Transport',
			'record.categorySuggestionBills' => 'Tagihan',
			'record.sheetSubtitle' => 'Pilih jenis peristiwa finansial yang ingin dicatat.',
			'record.noticeTitle' => 'Info Pencatatan',
			'record.examplesLabel' => 'Contoh:',
			'record.incomeBadge' => 'Uang Masuk',
			'record.expenseBadge' => 'Uang Keluar',
			'record.transferBadge' => 'Mutasi Internal',
			'record.pickIncomeAction' => 'Pilih Pemasukan',
			'record.pickExpenseAction' => 'Pilih Pengeluaran',
			'record.pickTransferAction' => 'Pilih Transfer',
			'record.transferExampleCash' => 'Tarik Tunai',
			'record.transferExampleTopUp' => 'Top-up e-Wallet',
			'record.transferExampleMove' => 'Pindah Rekening',
			'record.stepLabel' => 'Langkah 2 // Transaksi',
			'record.editStepLabel' => 'Sunting // Transaksi',
			'record.expenseRuleTitle' => 'Aturan Kas: Saldo Terpotong',
			'record.expenseRuleBody' => 'Pengeluaran langsung memotong saldo dompet yang kamu pilih di bawah ini.',
			'record.transferNoticeTitle' => 'Penting',
			'record.transferNoticeBody' => 'Ini catatan perpindahan uang manual yang sudah kamu lakukan di dunia nyata. Bukan transfer bank otomatis.',
			'record.amountLabelIncome' => 'Nominal Masuk',
			'record.amountLabelExpense' => 'Nominal Pengeluaran',
			'record.amountLabelTransfer' => 'Nominal Transfer',
			'record.clearAmountAction' => 'Bersihkan',
			'record.categorySectionLabel' => 'Kategori',
			'record.optionalHint' => 'Opsional',
			'record.categoryOtherLabel' => 'Lainnya',
			'record.categoryCustomHint' => 'Ketik kategori sendiri',
			'record.categorySuggestionEntertainment' => 'Hiburan',
			'record.categorySuggestionInvestment' => 'Investasi',
			'record.expenseWalletSectionLabel' => 'Dompet Sumber Dana',
			'record.noteSectionLabel' => 'Keterangan / Catatan',
			'record.balanceDecreasesCaption' => 'Saldo berkurang',
			'record.balanceIncreasesCaption' => 'Saldo bertambah',
			'record.incomeSummary' => ({required Object wallet, required Object amount}) => 'Saldo ${wallet} akan bertambah ${amount} saat dicatat.',
			'record.expenseSummary' => ({required Object wallet, required Object amount}) => 'Saldo ${wallet} akan berkurang ${amount} saat dicatat.',
			'record.transferSummaryTitle' => 'Ringkasan Catatan Mutasi',
			'record.transferSummaryFrom' => ({required Object wallet, required Object amount}) => 'Dompet ${wallet} berkurang ${amount}',
			'record.transferSummaryTo' => ({required Object wallet, required Object amount}) => 'Dompet ${wallet} bertambah ${amount}',
			'record.footnote' => '*Catatan internal Saldough. Tidak mendebit atau mengirim uang di rekening bank sungguhan.',
			'record.balanceLabel' => 'Saldo',
			'record.categoryPlaceholder' => 'Pilih kategori',
			'record.categoryNoneLabel' => 'Tanpa kategori',
			'record.choiceStepLabel' => 'Tahap 1 // Pilih Jenis',
			'record.flowOutside' => 'Luar',
			'record.flowWallet' => 'Dompet',
			'record.flowSourceWallet' => 'Dompet asal',
			'record.flowTargetWallet' => 'Dompet tujuan',
			'record.budgetItemLabel' => 'Pos anggaran',
			'record.budgetItemNone' => 'Tanpa anggaran',
			'record.budgetItemHelp' => 'Opsional. Hanya pos anggaran aktif yang cocok dengan dompet di atas yang ditawarkan.',
			'record.freelanceCalloutTitle' => 'Honor freelance?',
			'record.freelanceCalloutBody' => 'Kerja selesai belum tentu uangnya sudah masuk. Catat jam kerja dan pembayarannya di Freelance.',
			'transaction.pageTitle' => 'Transaksi',
			'transaction.searchHint' => 'Cari catatan / kategori...',
			'transaction.monthStatusLabel' => 'Status log bulan ini',
			'transaction.logCountBadge' => ({required Object count}) => '${count} log aktif',
			'transaction.netFlowLabel' => 'Arus Bersih (Netto)',
			'transaction.allFilterLabel' => ({required Object count}) => 'Semua ${count}',
			'transaction.incomeFilterLabel' => ({required Object count}) => 'Masuk ${count}',
			'transaction.expenseFilterLabel' => ({required Object count}) => 'Keluar ${count}',
			'transaction.transferFilterLabel' => ({required Object count}) => 'Mutasi ${count}',
			'transaction.walletFilterAllLabel' => 'Semua Dompet',
			'transaction.walletFilterLabel' => 'Dompet',
			'transaction.categoryFilterAllLabel' => 'Semua Kategori',
			'transaction.categoryFilterLabel' => 'Kategori',
			'transaction.todayLabel' => 'Hari Ini',
			'transaction.yesterdayLabel' => 'Kemarin',
			'transaction.incomeBadge' => '+MASUK',
			'transaction.expenseBadge' => '-KELUAR',
			'transaction.transferBadge' => '# MUTASI',
			'transaction.untitledTransaction' => 'Tanpa judul',
			'transaction.emptyMonthBadge' => 'Inventaris Kosong',
			'transaction.emptyMonthTitle' => 'Belum ada transaksi',
			'transaction.emptyMonthSubtitle' => 'Catat pemasukan, pengeluaran, atau transfer untuk mulai melihat riwayat buku kas harianmu.',
			'transaction.emptyMonthCta' => 'Catat Transaksi Sekarang',
			'transaction.emptyGuideTitle' => 'Panduan Catatan Kas',
			'transaction.emptyGuideIncomeTitle' => 'Pemasukan',
			'transaction.emptyGuideIncomeDescription' => 'Menambah saldo dompet pilihan secara riil dan tercatat di kas.',
			'transaction.emptyGuideExpenseTitle' => 'Pengeluaran',
			'transaction.emptyGuideExpenseDescription' => 'Memotong saldo dompet dan menghitung kuota batas anggaran bulanan.',
			'transaction.emptyGuideTransferTitle' => 'Transfer Antar Dompet',
			'transaction.emptyGuideTransferDescription' => 'Memindahkan catatan saldo antar dompet tanpa mengubah total kekayaan.',
			'transaction.trustFooterMessage' => 'Semua transaksi dicatat manual • Privasi 100% aman di perangkatmu',
			'transaction.emptyFilterTitle' => 'Tidak ada transaksi yang cocok dengan filter',
			'transaction.emptyFilterSubtitle' => 'Coba ganti atau hapus filter yang sedang aktif.',
			'transaction.clearFiltersButton' => 'Hapus filter',
			'transaction.loadErrorTitle' => 'Transaksi gagal dimuat',
			'transaction.loadErrorSubtitle' => 'Periksa lagi lalu coba muat ulang.',
			'transaction.detailBackLabel' => 'Kembali',
			'transaction.detailIncomeTitle' => 'Pemasukan tercatat',
			'transaction.detailExpenseTitle' => 'Pengeluaran tercatat',
			'transaction.detailTransferTitle' => 'Transfer tercatat',
			'transaction.detailTypeLabel' => 'Jenis Entri',
			'transaction.detailIncomeType' => 'Pemasukan',
			'transaction.detailExpenseType' => 'Pengeluaran',
			'transaction.detailTransferType' => 'Transfer antar dompet',
			'transaction.detailCategoryLabel' => 'Kategori',
			'transaction.detailIncomeWalletLabel' => 'Dompet Tujuan',
			'transaction.detailExpenseWalletLabel' => 'Dompet Sumber',
			'transaction.detailCurrentBalance' => 'Saldo saat ini',
			'transaction.detailNoteLabel' => 'Catatan Manual',
			'transaction.detailFromLabel' => 'Dari',
			'transaction.detailToLabel' => 'Ke',
			'transaction.detailAmountLabel' => 'Jumlah',
			'transaction.detailManualNote' => 'Catatan ini adalah rekaman manual di Saldough. Saldo dompet dihitung dari data yang kamu masukkan, tanpa terhubung ke rekening bank.',
			'transaction.editAction' => 'Ubah Catatan Ini',
			'transaction.deleteAction' => 'Hapus Catatan dari Riwayat',
			'transaction.editSheetTitle' => 'Ubah Catatan',
			'transaction.saveChangesAction' => 'Simpan Perubahan',
			'transaction.deleteConfirmTitle' => 'Hapus catatan ini?',
			'transaction.deleteConfirmMessage' => 'Catatan dihapus dari riwayat, dan saldo dompet dihitung ulang tanpa catatan ini.',
			'transaction.updatedMessage' => 'Perubahan tersimpan.',
			'transaction.deletedMessage' => 'Catatan dihapus.',
			'transaction.budgetLabel' => 'Anggaran',
			'transaction.openBudgetAction' => 'Lihat anggaran',
			'transaction.detailFreelanceNote' => 'Pemasukan ini dicatat dari pembayaran freelance. Untuk mengubahnya, batalkan penerimaannya di Freelance.',
			'wallet.heading' => 'Dompet Saya',
			'wallet.subtitle' => 'Posisi saldo kas saat ini',
			'wallet.activeBadge' => ({required Object count}) => '${count} kantong aktif',
			'wallet.totalLabel' => 'Total saldo semua dompet',
			'wallet.manualNoteTitle' => 'Catatan Manual',
			'wallet.manualNoteBody' => 'Saldo dihitung dari catatan yang kamu buat sendiri, bukan sinkronisasi otomatis dari bank.',
			'wallet.listHeading' => 'Daftar Dompet',
			'wallet.balanceLabel' => 'Saldo Aktif',
			'wallet.addAction' => 'Tambah Dompet Baru',
			'wallet.inactiveHeading' => 'Dompet Nonaktif',
			'wallet.inactiveBadge' => 'Nonaktif',
			'wallet.typeBank' => 'Bank / Rekening',
			'wallet.typeCash' => 'Uang Tunai',
			'wallet.typeEwallet' => 'Dompet Digital',
			'wallet.typeSavings' => 'Tabungan',
			'wallet.typeCard' => 'Kartu',
			'wallet.emptyBadge' => 'Belum ada dompet',
			'wallet.emptyTitle' => 'Belum ada dompet tercatat',
			'wallet.emptyBody' => 'Tambahkan dompet pertama untuk mulai mencatat posisi uangmu. Bisa berupa rekening bank, e-wallet, atau uang tunai di saku.',
			'wallet.loadErrorTitle' => 'Dompet gagal dimuat',
			'wallet.loadErrorSubtitle' => 'Data dompet tidak terbaca. Coba lagi.',
			'wallet.addTitle' => 'Tambah Dompet Baru',
			'wallet.editTitle' => 'Ubah Dompet',
			'wallet.addStepLabel' => 'Dompet // Baru',
			'wallet.editStepLabel' => 'Dompet // Ubah',
			'wallet.nameLabel' => 'Nama Dompet',
			'wallet.nameHint' => 'Contoh: Tabungan Mandiri, OVO, Brankas Tunai',
			'wallet.nameRequiredHint' => 'Wajib',
			'wallet.nameMaxHint' => 'Maks. 24 karakter',
			'wallet.iconLabel' => 'Pilih Ikon',
			'wallet.initialBalanceLabel' => 'Saldo Awal Saat Ini',
			'wallet.initialBalanceHelp' => 'Saldo awal adalah uang yang ada saat ini, sebelum pencatatan transaksi dimulai. Ia pernyataan keadaan, bukan setoran, jadi tidak muncul di riwayat.',
			'wallet.currentBalanceLabel' => 'Saldo Tercatat Saat Ini',
			'wallet.editBalanceNote' => 'Mengubah saldo awal menghitung ulang saldo tercatat. Untuk selisih dengan uang nyata, catat pemasukan atau pengeluaran lewat CATAT.',
			'wallet.activeSwitchLabel' => 'Dompet aktif',
			'wallet.activeSwitchHelp' => 'Dompet nonaktif tidak muncul di pemilih dompet. Transaksinya tetap tersimpan dan dihitung.',
			'wallet.saveAddAction' => 'Simpan Dompet',
			'wallet.deleteAction' => 'Hapus Dompet',
			'wallet.deleteHelp' => 'Hanya bisa dihapus kalau belum punya transaksi sama sekali. Kalau sudah, nonaktifkan saja.',
			'wallet.deleteConfirmTitle' => 'Hapus dompet?',
			'wallet.deleteConfirmMessage' => ({required Object name}) => 'Dompet ${name} akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.',
			'wallet.savedMessage' => 'Dompet tersimpan.',
			'wallet.updatedMessage' => 'Dompet diperbarui.',
			'wallet.deletedMessage' => 'Dompet dihapus.',
			'wallet.deleteBlockedMessage' => 'Dompet ini sudah punya transaksi, jadi tidak bisa dihapus. Nonaktifkan saja.',
			'wallet.privacyNote' => 'Data tersimpan lokal dan privat di perangkatmu.',
			'wallet.detailBackLabel' => 'Kembali',
			'wallet.detailEditAction' => 'Sunting',
			'wallet.detailRecentHeading' => 'Transaksi Bulan Ini',
			'wallet.detailIncomeLabel' => 'Pemasukan',
			'wallet.detailExpenseLabel' => 'Pengeluaran',
			'wallet.detailRecentEmptyTitle' => 'Belum ada transaksi',
			'wallet.detailRecentEmpty' => 'Belum ada transaksi bulan ini untuk dompet ini.',
			'wallet.detailViewAllAction' => 'Lihat Semua Transaksi',
			'wallet.detailRecordAction' => 'Catat Transaksi Dompet Ini',
			'wallet.detailTransferInLabel' => 'Transfer masuk',
			'wallet.detailTransferOutLabel' => 'Transfer keluar',
			'wallet.detailBalanceChangeLabel' => 'Perubahan saldo',
			'budget.heading' => 'Anggaran Saya',
			'budget.activeBadge' => ({required Object count}) => '${count} aktif',
			'budget.summaryTitle' => 'Total rencana anggaran aktif',
			'budget.summaryPercent' => ({required Object percent}) => '${percent}% terpakai',
			'budget.plannedLabel' => 'Rencana',
			'budget.spentLabel' => 'Terpakai',
			'budget.remainingLabel' => 'Sisa',
			'budget.spentPercentLabel' => ({required Object percent}) => 'Terpakai (${percent}%)',
			'budget.summaryNote' => 'Anggaran adalah rencana belanja, bukan pemotongan saldo dompet. Saldo baru berkurang saat pengeluaran atau transfer dicatat.',
			'budget.filterAll' => 'Semua',
			'budget.filterActive' => 'Aktif',
			'budget.filterFinished' => 'Selesai',
			'budget.filterArchived' => 'Nonaktif',
			'budget.filterWalletLabel' => 'Dompet',
			'budget.filterWalletAll' => 'Semua dompet',
			'budget.addAction' => 'Buat Anggaran Baru',
			'budget.periodWeekly' => 'Mingguan',
			'budget.periodMonthly' => 'Bulanan',
			'budget.itemStatusPlanned' => 'Belum terpakai',
			'budget.itemStatusPartiallySpent' => 'Terpakai sebagian',
			'budget.itemStatusCompleted' => 'Selesai',
			'budget.itemStatusOverspent' => 'Lewat anggaran',
			'budget.itemCount' => ({required Object count}) => '${count} pos',
			'budget.emptyBadge' => 'Slot rencana kosong',
			'budget.emptyTitle' => 'Belum ada anggaran',
			'budget.emptyBody' => 'Rencanakan batas belanja mingguan atau bulanan untuk satu dompet. Membuat anggaran tidak mengurangi saldo dompet.',
			'budget.emptyFilteredTitle' => 'Tidak ada anggaran yang cocok',
			'budget.emptyFilteredBody' => 'Tidak ada anggaran dengan status dan dompet yang dipilih.',
			'budget.resetFilterAction' => 'Tampilkan semua anggaran',
			'budget.noWalletTitle' => 'Buat dompet dulu',
			'budget.noWalletBody' => 'Setiap anggaran terikat ke satu dompet. Tambahkan dompet di tab Dompet, lalu kembali ke sini.',
			'budget.loadErrorTitle' => 'Anggaran gagal dimuat',
			'budget.loadErrorSubtitle' => 'Data anggaran tidak bisa dibaca. Coba lagi.',
			'budget.savedMessage' => 'Anggaran tersimpan.',
			'budget.updatedMessage' => 'Perubahan anggaran tersimpan.',
			'budget.deletedMessage' => 'Anggaran dihapus.',
			'budget.archivedMessage' => 'Anggaran diarsipkan.',
			'budget.unarchivedMessage' => 'Anggaran diaktifkan kembali.',
			'budget.addStepLabel' => 'Anggaran baru',
			'budget.editStepLabel' => 'Sunting anggaran',
			'budget.addTitle' => 'Buat Anggaran',
			'budget.editTitle' => 'Ubah Anggaran',
			'budget.ruleTitle' => 'Aturan Anggaran',
			'budget.ruleBody' => 'Rencana ini tidak memotong saldo dompetmu. Saldo hanya berkurang saat kamu mencatat transaksi.',
			'budget.nameLabel' => 'Nama anggaran',
			'budget.nameHint' => 'Contoh: Kebutuhan Rumah Tangga',
			'budget.requiredHint' => 'Wajib',
			'budget.walletLabel' => 'Dompet terkait',
			'budget.walletHelp' => 'Hanya pengeluaran dan transfer keluar dari dompet ini yang terhitung ke anggaran.',
			'budget.walletBalance' => ({required Object amount}) => 'Saldo: ${amount}',
			'budget.periodLabel' => 'Periode',
			'budget.startDateLabel' => 'Mulai',
			'budget.periodRange' => ({required Object start, required Object end}) => '${start} – ${end}',
			'budget.itemsLabel' => 'Pos anggaran',
			'budget.itemsHelp' => 'Rincian rencana belanja atau rencana transfer. Total rencana anggaran adalah jumlah seluruh pos.',
			'budget.addItemAction' => 'Tambah Pos',
			'budget.saveAddAction' => 'Simpan Anggaran',
			'budget.archiveAction' => 'Arsipkan Anggaran',
			'budget.unarchiveAction' => 'Aktifkan Kembali',
			'budget.archiveHelp' => 'Anggaran nonaktif disembunyikan dari daftar aktif. Transaksi yang tertaut tetap tercatat.',
			'budget.deleteAction' => 'Hapus Anggaran',
			'budget.deleteConfirmTitle' => 'Hapus anggaran?',
			'budget.deleteConfirmMessage' => ({required Object name}) => 'Anggaran "${name}" beserta posnya akan dihapus. Transaksi yang tertaut tetap tercatat dan saldo dompet tidak berubah.',
			'budget.itemAddTitle' => 'Tambah Pos',
			'budget.itemEditTitle' => 'Ubah Pos',
			'budget.itemNameLabel' => 'Nama pos',
			'budget.itemNameHint' => 'Contoh: Beras',
			'budget.itemModeAmount' => 'Nominal',
			'budget.itemModeItemized' => 'Jumlah × harga',
			'budget.itemAmountLabel' => 'Nominal rencana',
			'budget.itemQuantityLabel' => 'Jumlah',
			'budget.itemUnitPriceLabel' => 'Harga satuan',
			'budget.itemTotalLabel' => 'Total pos',
			'budget.itemItemizedDetail' => ({required Object quantity, required Object price}) => '${quantity} × ${price}',
			'budget.itemSaveAction' => 'Simpan Pos',
			'budget.itemDeleteAction' => 'Hapus Pos',
			'budget.detailBackLabel' => 'Daftar Anggaran',
			'budget.detailEditAction' => 'Sunting anggaran',
			'budget.detailRecordExpenseAction' => 'Catat Pengeluaran',
			'budget.detailRecordTransferAction' => 'Catat Transfer',
			'budget.detailItemsHeading' => 'Pos Anggaran',
			'budget.detailNoItems' => 'Anggaran ini belum punya pos. Tambahkan pos lewat Sunting supaya pengeluaran bisa ditautkan.',
			'budget.detailLinkedHeading' => 'Transaksi Tertaut',
			'budget.detailLinkedEmpty' => 'Belum ada transaksi yang tertaut ke anggaran ini.',
			'budget.detailHowTitle' => 'Cara kerja pos anggaran',
			'budget.detailHowBody' => ({required Object wallet}) => 'Catat lewat tombol di tiap pos. Pos pengeluaran menghitung pengeluaran dari ${wallet}; pos transfer menghitung transfer dari ${wallet} ke dompet tujuannya. Anggaran sendiri tidak pernah memotong saldo.',
			'budget.unknownWallet' => 'Dompet tidak ditemukan',
			'budget.totalPlannedLabel' => 'Total rencana anggaran',
			'budget.itemsRequiredHint' => 'Tambahkan minimal satu pos. Transaksi dicatat ke pos, jadi anggaran tanpa pos tidak bisa melacak pengeluaran.',
			'budget.walletUnchangedNote' => ({required Object wallet}) => 'Saldo ${wallet} tetap',
			'budget.itemKindLabel' => 'Jenis pos',
			'budget.itemKindExpense' => 'Pengeluaran',
			'budget.itemKindTransfer' => 'Transfer',
			'budget.itemKindLockedHint' => 'Jenis tidak bisa diganti karena pos ini sudah punya transaksi tertaut.',
			'budget.itemTargetWalletLabel' => 'Dompet tujuan',
			'budget.itemTargetWalletHelp' => 'Hanya transfer dari dompet anggaran ke dompet ini yang terhitung ke pos.',
			'budget.itemNoTargetWallet' => 'Butuh dompet aktif lain sebagai tujuan transfer.',
			'budget.itemTransferTo' => ({required Object wallet}) => 'Ke ${wallet}',
			'budget.itemTargetConflict' => ({required Object name}) => 'Pos transfer "${name}" menuju dompet anggaran itu sendiri. Ganti dompet tujuan posnya atau dompet anggarannya.',
			'freelance.title' => 'Freelance',
			'freelance.worklogTab' => ({required Object count}) => 'Worklog (${count})',
			'freelance.paymentsTab' => ({required Object count}) => 'Pembayaran (${count})',
			'freelance.loadErrorTitle' => 'Data freelance gagal dimuat',
			'freelance.ruleTitle' => 'Aturan kas freelance',
			'freelance.ruleBody' => 'Jam kerja yang selesai tidak menambah saldo dompet. Uang baru masuk ke dompet saat pembayarannya dicatat diterima.',
			'freelance.summaryTitle' => 'Ringkasan upah & jam',
			'freelance.totalHoursLabel' => 'Waktu kerja',
			'freelance.hoursValue' => ({required Object hours}) => '${hours} jam',
			'freelance.hourShort' => 'jam',
			'freelance.projectCount' => ({required Object count}) => '${count} proyek',
			'freelance.earnedLabel' => 'Total diperoleh',
			'freelance.earnedCaption' => 'Jam × tarif, sebelum potongan',
			'freelance.paidLabel' => 'Sudah diterima',
			'freelance.paidCaption' => 'Pembayarannya sudah dicatat',
			'freelance.unpaidLabel' => 'Belum diterima',
			'freelance.unpaidCaption' => 'Belum ditagih atau tertunda',
			'freelance.paidRatio' => ({required Object percent}) => '${percent}% sudah diterima',
			'freelance.projectsLabel' => 'Proyek',
			'freelance.projectsEmpty' => 'Belum ada proyek. Tambahkan klien atau proyek beserta tarif per jamnya dulu.',
			'freelance.projectAddAction' => '+ Proyek',
			'freelance.projectStepLabel' => 'Proyek freelance',
			'freelance.projectAddTitle' => 'Tambah Proyek',
			'freelance.projectEditTitle' => 'Ubah Proyek',
			'freelance.projectNameLabel' => 'Nama klien atau proyek',
			'freelance.projectNameHint' => 'Contoh: Studio Koding',
			'freelance.requiredHint' => 'Wajib',
			'freelance.hourlyRateLabel' => 'Tarif per jam',
			'freelance.hourlyRateHelp' => 'Tarif bawaan untuk entri baru. Mengubahnya tidak mengubah entri yang sudah dicatat.',
			'freelance.deductionsLabel' => 'Potongan',
			'freelance.deductionsHelp' => 'Dipotong dari gaji kotor setiap pembayaran, misalnya pajak. Mengubahnya tidak mengubah pembayaran yang sudah dibuat.',
			'freelance.deductionAddAction' => 'Tambah potongan',
			'freelance.deductionTitle' => 'Potongan',
			'freelance.deductionLabelLabel' => 'Nama potongan',
			'freelance.deductionLabelHint' => 'Contoh: Pajak',
			'freelance.deductionKindPercentage' => 'Persen',
			'freelance.deductionKindFixed' => 'Nominal tetap',
			'freelance.deductionPercentLabel' => 'Persen dari gaji kotor',
			'freelance.deductionPercentHelp' => 'Paling banyak satu angka di belakang koma, misalnya 2,5.',
			'freelance.deductionAmountLabel' => 'Nominal per pembayaran',
			'freelance.deductionSaveAction' => 'Simpan potongan',
			'freelance.deductionRemoveAction' => 'Hapus potongan',
			'freelance.projectSaveAction' => 'Simpan proyek',
			'freelance.projectDeleteAction' => 'Hapus proyek',
			'freelance.projectDeleteLockedHint' => 'Proyek yang sudah punya entri worklog tidak bisa dihapus.',
			'freelance.projectDeleteConfirmTitle' => 'Hapus proyek?',
			'freelance.projectDeleteConfirmMessage' => ({required Object name}) => 'Proyek "${name}" akan dihapus.',
			'freelance.projectDeleteRefused' => 'Proyek ini sudah punya entri worklog, jadi tidak bisa dihapus.',
			'freelance.projectSavedMessage' => 'Proyek tersimpan.',
			'freelance.projectUpdatedMessage' => 'Perubahan proyek tersimpan.',
			'freelance.projectDeletedMessage' => 'Proyek dihapus.',
			'freelance.projectLabel' => 'Proyek',
			'freelance.projectPick' => 'Pilih proyek',
			'freelance.entriesLabel' => 'Daftar entri jam kerja',
			'freelance.entriesEmpty' => 'Belum ada entri worklog.',
			'freelance.entryAddAction' => 'Tambah Worklog',
			'freelance.entryStepLabel' => 'Log pekerjaan',
			'freelance.entryAddTitle' => 'Tambah Worklog',
			'freelance.entryEditTitle' => 'Ubah Worklog',
			'freelance.entryRuleBody' => 'Mencatat jam kerja tidak menambah saldo dompet mana pun. Uangnya baru tercatat saat pembayarannya diterima.',
			'freelance.workDateLabel' => 'Tanggal kerja',
			'freelance.hoursLabel' => 'Durasi pengerjaan',
			'freelance.entryRateHelp' => 'Terisi dari tarif proyek. Ubah kalau tarif entri ini berbeda.',
			'freelance.noteLabel' => 'Catatan',
			'freelance.noteHint' => 'Apa yang dikerjakan (opsional)',
			'freelance.entrySaveAction' => 'Simpan Worklog',
			'freelance.entrySaveHint' => 'Nominal ini tercatat sebagai diperoleh, belum diterima.',
			'freelance.entryDeleteAction' => 'Hapus entri',
			'freelance.entryDeleteConfirmTitle' => 'Hapus entri worklog?',
			'freelance.entryDeleteConfirmMessage' => 'Entri ini akan dihapus. Saldo dompet tidak berubah.',
			'freelance.entryLockedMessage' => 'Entri yang sudah masuk pembayaran tidak bisa diubah atau dihapus.',
			'freelance.entrySavedMessage' => 'Worklog tersimpan.',
			'freelance.entryUpdatedMessage' => 'Perubahan worklog tersimpan.',
			'freelance.entryDeletedMessage' => 'Worklog dihapus.',
			'freelance.hoursTimesRate' => ({required Object hours, required Object rate}) => '${hours} jam × ${rate}',
			'freelance.statusUnbilled' => 'Belum ditagih',
			'freelance.statusPending' => 'Tertunda',
			'freelance.statusPaid' => 'Diterima',
			'freelance.expectedOn' => ({required Object date}) => 'Perkiraan diterima ${date}',
			'freelance.receivedOn' => ({required Object date, required Object wallet}) => 'Diterima ${date} di ${wallet}',
			'freelance.unknownProject' => 'Proyek terhapus',
			'freelance.unknownWallet' => 'dompet terhapus',
			'freelance.paymentsRuleBody' => 'Tekan Catat Diterima hanya saat uangnya benar-benar sudah masuk ke rekeningmu. Aksi ini membuat satu catatan pemasukan dan menambah saldo dompet pilihan.',
			'freelance.pendingTotalLabel' => 'Tertunda (bersih)',
			'freelance.paidTotalLabel' => 'Diterima (bersih)',
			'freelance.paymentCount' => ({required Object count}) => '${count} pembayaran',
			'freelance.paymentAddAction' => 'Buat Pembayaran',
			'freelance.paymentAddDisabledHint' => 'Semua entri worklog sudah masuk pembayaran.',
			'freelance.pendingSectionLabel' => 'Menunggu pembayaran',
			'freelance.pendingEmpty' => 'Tidak ada pembayaran tertunda.',
			'freelance.paidSectionLabel' => 'Riwayat pembayaran diterima',
			'freelance.paidEmpty' => 'Belum ada pembayaran yang diterima.',
			'freelance.paymentStepLabel' => 'Pembayaran freelance',
			'freelance.paymentAddTitle' => 'Buat Pembayaran',
			'freelance.paymentCreateRuleBody' => 'Membuat pembayaran hanya mengelompokkan jam kerja jadi satu tagihan. Saldo dompet belum berubah sampai pembayaran dicatat diterima.',
			'freelance.paymentEntriesLabel' => ({required Object count, required Object hours}) => 'Entri ditagih: ${count} (${hours} jam)',
			'freelance.paymentEntriesSummary' => ({required Object count, required Object hours}) => '${count} entri · ${hours} jam',
			'freelance.expectedDateLabel' => 'Perkiraan tanggal diterima',
			'freelance.grossPayLabel' => 'Gaji kotor',
			'freelance.netPayLabel' => 'Gaji bersih',
			'freelance.netPayNotPositive' => 'Potongan tidak boleh sama dengan atau melebihi gaji kotor.',
			'freelance.paymentCreateAction' => 'Buat Pembayaran',
			'freelance.paymentChangeDateAction' => 'Ubah tanggal',
			'freelance.paymentDeleteAction' => 'Hapus',
			'freelance.paymentDeleteConfirmTitle' => 'Hapus pembayaran?',
			'freelance.paymentDeleteConfirmMessage' => 'Pembayaran tertunda ini dihapus dan entrinya kembali belum ditagih. Saldo dompet tidak berubah.',
			'freelance.paymentEntriesInvalid' => 'Entri yang dipilih sudah ditagih atau bukan milik proyek ini.',
			'freelance.paymentPaidLocked' => 'Pembayaran yang sudah diterima tidak bisa dihapus. Batalkan penerimaannya dulu.',
			'freelance.paymentAlreadyPaid' => 'Pembayaran ini sudah dicatat diterima.',
			'freelance.paymentCreatedMessage' => 'Pembayaran dibuat.',
			'freelance.paymentUpdatedMessage' => 'Tanggal pembayaran diperbarui.',
			'freelance.paymentDeletedMessage' => 'Pembayaran dihapus.',
			'freelance.receiveTitle' => 'Catat Pembayaran Diterima',
			'freelance.receiveRuleTitle' => 'Pencatatan, bukan pembayaran',
			'freelance.receiveRuleBody' => 'Saldough tidak menerima atau memindahkan uang. Catat hanya uang yang sudah benar-benar masuk ke rekeningmu; saldo dompet pilihan akan bertambah sebesar gaji bersih.',
			'freelance.receiveAmountLabel' => 'Nominal diterima',
			'freelance.receiveWalletLabel' => 'Dompet penerima',
			'freelance.receiveDateLabel' => 'Tanggal diterima',
			'freelance.receiveNoteDefault' => ({required Object project}) => 'Pembayaran freelance ${project}',
			'freelance.receiveAction' => 'Catat Diterima',
			'freelance.paymentReceivedMessage' => 'Pembayaran dicatat diterima. Saldo dompet bertambah.',
			'freelance.receiptCancelAction' => 'Batalkan penerimaan',
			'freelance.receiptCancelConfirmTitle' => 'Batalkan penerimaan?',
			'freelance.receiptCancelConfirmMessage' => 'Catatan pemasukannya dihapus dan saldo dompet berkurang kembali. Pembayaran kembali tertunda.',
			'freelance.receiptCancelledMessage' => 'Penerimaan dibatalkan. Pembayaran kembali tertunda.',
			'freelance.changeAction' => 'Ubah',
			'freelance.receiptCancelConfirmAction' => 'Hapus pemasukan',
			_ => null,
		};
	}
}
