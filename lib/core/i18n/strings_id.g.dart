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
	late final Translations$home$id home = Translations$home$id.internal(_root);
	late final Translations$onboarding$id onboarding = Translations$onboarding$id.internal(_root);
	late final Translations$tour$id tour = Translations$tour$id.internal(_root);
	late final Translations$info$id info = Translations$info$id.internal(_root);
	late final Translations$account$id account = Translations$account$id.internal(_root);
	late final Translations$currency$id currency = Translations$currency$id.internal(_root);
	late final Translations$category$id category = Translations$category$id.internal(_root);
	late final Translations$language$id language = Translations$language$id.internal(_root);
	late final Translations$notificationCapture$id notificationCapture = Translations$notificationCapture$id.internal(_root);
	late final Translations$recurring$id recurring = Translations$recurring$id.internal(_root);
	late final Translations$plan$id plan = Translations$plan$id.internal(_root);
}

// Path: app
class Translations$app$id {
	Translations$app$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Tanukonomy'
	String get title => 'Tanukonomy';
}

// Path: common
class Translations$common$id {
	Translations$common$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: '+${amount}rb'
	String quickAmountThousands({required Object amount}) => '+${amount}rb';

	/// id: '+${amount}jt'
	String quickAmountMillions({required Object amount}) => '+${amount}jt';

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

	/// id: 'Hapus satu digit'
	String get keypadBackspace => 'Hapus satu digit';

	/// id: 'Tambah'
	String get keypadAdd => 'Tambah';

	/// id: 'Kurang'
	String get keypadSubtract => 'Kurang';

	/// id: 'Kali'
	String get keypadMultiply => 'Kali';

	/// id: 'Bagi'
	String get keypadDivide => 'Bagi';

	/// id: 'Tutup'
	String get close => 'Tutup';

	/// id: 'Selesai'
	String get done => 'Selesai';
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

	/// id: 'Tekan lama untuk catat pakai suara'
	String get recordVoiceHint => 'Tekan lama untuk catat pakai suara';

	/// id: 'Riwayat'
	String get transactionsTabLabel => 'Riwayat';

	/// id: 'Dompet'
	String get walletsTabLabel => 'Dompet';

	/// id: 'Rencana'
	String get planTabLabel => 'Rencana';
}

// Path: record
class Translations$record$id {
	Translations$record$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Catat pemasukan'
	String get incomeAction => 'Catat pemasukan';

	/// id: 'Catat pengeluaran'
	String get expenseAction => 'Catat pengeluaran';

	/// id: 'Catat transfer'
	String get transferAction => 'Catat transfer';

	/// id: 'Ke dompet'
	String get toWalletFieldLabel => 'Ke dompet';

	/// id: 'Dari dompet'
	String get fromWalletFieldLabel => 'Dari dompet';

	/// id: 'Ke dompet'
	String get destinationWalletFieldLabel => 'Ke dompet';

	/// id: 'Tanggal'
	String get dateFieldLabel => 'Tanggal';

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

	/// id: 'Belum dipilih'
	String get walletNotSelectedPrompt => 'Belum dipilih';

	/// id: 'Menyimpan...'
	String get savingMessage => 'Menyimpan...';

	/// id: 'Ubah transaksi'
	String get editStepLabel => 'Ubah transaksi';

	/// id: 'Saldo dompet berkurang'
	String get expenseRuleTitle => 'Saldo dompet berkurang';

	/// id: 'Bersihkan'
	String get clearAmountAction => 'Bersihkan';

	/// id: 'Kategori'
	String get categorySectionLabel => 'Kategori';

	/// id: 'Opsional'
	String get optionalHint => 'Opsional';

	/// id: 'Dari dompet'
	String get expenseWalletSectionLabel => 'Dari dompet';

	/// id: 'Catatan'
	String get noteSectionLabel => 'Catatan';

	/// id: 'Saldo'
	String get balanceLabel => 'Saldo';

	/// id: 'Tanpa kategori'
	String get categoryNoneLabel => 'Tanpa kategori';

	/// id: 'Pos anggaran'
	String get budgetItemLabel => 'Pos anggaran';

	/// id: 'Tanpa anggaran'
	String get budgetItemNone => 'Tanpa anggaran';

	/// id: 'Tanggal ini di luar periode anggaran "$name", jadi transaksi ini tidak lagi masuk anggaran itu.'
	String budgetItemOutOfPeriod({required Object name}) => 'Tanggal ini di luar periode anggaran "${name}", jadi transaksi ini tidak lagi masuk anggaran itu.';

	/// id: 'Honor freelance?'
	String get freelanceCalloutTitle => 'Honor freelance?';

	/// id: 'Catat lewat Freelance'
	String get freelanceCalloutAction => 'Catat lewat Freelance';

	/// id: 'Jenis transaksi'
	String get kindSwitcherLabel => 'Jenis transaksi';

	/// id: 'Pengeluaran'
	String get kindExpense => 'Pengeluaran';

	/// id: 'Pemasukan'
	String get kindIncome => 'Pemasukan';

	/// id: 'Transfer'
	String get kindTransfer => 'Transfer';

	/// id: 'Tambah kategori'
	String get categoryAddLabel => 'Tambah kategori';

	/// id: 'Periksa sebelum mencatat'
	String get draftCheckTitle => 'Periksa sebelum mencatat';

	late final Translations$record$draftIssue$id draftIssue = Translations$record$draftIssue$id.internal(_root);
	late final Translations$record$voice$id voice = Translations$record$voice$id.internal(_root);
	late final Translations$record$repeat$id repeat = Translations$record$repeat$id.internal(_root);

	/// id: 'Saldo jadi $amount'
	String balanceAfter({required Object amount}) => 'Saldo jadi ${amount}';

	/// id: 'Semua kategori'
	String get allCategories => 'Semua kategori';

	late final Translations$record$calc$id calc = Translations$record$calc$id.internal(_root);

	/// id: 'Nominal $amount'
	String amountSemantics({required Object amount}) => 'Nominal ${amount}';
}

// Path: transaction
class Translations$transaction$id {
	Translations$transaction$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Riwayat'
	String get pageTitle => 'Riwayat';

	/// id: 'Cari di bulan ini: catatan / kategori...'
	String get searchHint => 'Cari di bulan ini: catatan / kategori...';

	/// id: 'Semua $count'
	String allFilterLabel({required Object count}) => 'Semua ${count}';

	/// id: 'Pemasukan $count'
	String incomeFilterLabel({required Object count}) => 'Pemasukan ${count}';

	/// id: 'Pengeluaran $count'
	String expenseFilterLabel({required Object count}) => 'Pengeluaran ${count}';

	/// id: 'Transfer $count'
	String transferFilterLabel({required Object count}) => 'Transfer ${count}';

	/// id: 'Semua dompet'
	String get walletFilterAllLabel => 'Semua dompet';

	/// id: 'Dompet'
	String get walletFilterLabel => 'Dompet';

	/// id: 'Semua kategori'
	String get categoryFilterAllLabel => 'Semua kategori';

	/// id: 'Kategori'
	String get categoryFilterLabel => 'Kategori';

	/// id: 'Filter'
	String get filterButtonLabel => 'Filter';

	/// id: 'Filter transaksi'
	String get filterSheetTitle => 'Filter transaksi';

	/// id: 'Selesai'
	String get filterSheetDoneAction => 'Selesai';

	/// id: 'Hari ini'
	String get todayLabel => 'Hari ini';

	/// id: 'Kemarin'
	String get yesterdayLabel => 'Kemarin';

	/// id: 'Belum ada transaksi'
	String get emptyMonthTitle => 'Belum ada transaksi';

	/// id: 'Setiap transaksi yang kamu catat muncul di sini, dikelompokkan per hari.'
	String get emptyMonthSubtitle => 'Setiap transaksi yang kamu catat muncul di sini, dikelompokkan per hari.';

	/// id: 'Catat transaksi'
	String get emptyMonthCta => 'Catat transaksi';

	/// id: 'Tiga jenis transaksi'
	String get emptyGuideTitle => 'Tiga jenis transaksi';

	/// id: 'Pemasukan'
	String get emptyGuideIncomeTitle => 'Pemasukan';

	/// id: 'Menambah saldo dompet yang kamu pilih.'
	String get emptyGuideIncomeDescription => 'Menambah saldo dompet yang kamu pilih.';

	/// id: 'Pengeluaran'
	String get emptyGuideExpenseTitle => 'Pengeluaran';

	/// id: 'Mengurangi saldo dompet dan mengisi pos anggaran yang tertaut.'
	String get emptyGuideExpenseDescription => 'Mengurangi saldo dompet dan mengisi pos anggaran yang tertaut.';

	/// id: 'Transfer antardompet'
	String get emptyGuideTransferTitle => 'Transfer antardompet';

	/// id: 'Memindahkan catatan saldo antar dompet tanpa mengubah total kekayaan.'
	String get emptyGuideTransferDescription => 'Memindahkan catatan saldo antar dompet tanpa mengubah total kekayaan.';

	/// id: 'Riwayat lengkapmu, tersimpan aman di perangkatmu'
	String get trustFooterMessage => 'Riwayat lengkapmu, tersimpan aman di perangkatmu';

	/// id: 'Tidak ada transaksi bulan ini yang cocok dengan filter'
	String get emptyFilterTitle => 'Tidak ada transaksi bulan ini yang cocok dengan filter';

	/// id: 'Pencarian dan filter hanya mencakup bulan yang sedang dibuka. Ganti bulan, atau ganti dan hapus filter.'
	String get emptyFilterSubtitle => 'Pencarian dan filter hanya mencakup bulan yang sedang dibuka. Ganti bulan, atau ganti dan hapus filter.';

	/// id: 'Hapus filter'
	String get clearFiltersButton => 'Hapus filter';

	/// id: 'Cari di bulan lain'
	String get crossMonthSearchButton => 'Cari di bulan lain';

	/// id: 'Mencari di bulan sebelumnya...'
	String get crossMonthSearchingLabel => 'Mencari di bulan sebelumnya...';

	/// id: 'Ditemukan di bulan lain'
	String get crossMonthResultsHeader => 'Ditemukan di bulan lain';

	/// id: 'Cari lebih jauh'
	String get crossMonthLoadMoreButton => 'Cari lebih jauh';

	/// id: 'Tidak ditemukan di bulan-bulan sebelumnya.'
	String get crossMonthNoMoreResults => 'Tidak ditemukan di bulan-bulan sebelumnya.';

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

	/// id: 'Jenis transaksi'
	String get detailTypeLabel => 'Jenis transaksi';

	/// id: 'Pemasukan'
	String get detailIncomeType => 'Pemasukan';

	/// id: 'Pengeluaran'
	String get detailExpenseType => 'Pengeluaran';

	/// id: 'Transfer antar dompet'
	String get detailTransferType => 'Transfer antar dompet';

	/// id: 'Kategori'
	String get detailCategoryLabel => 'Kategori';

	/// id: 'Dompet tujuan'
	String get detailIncomeWalletLabel => 'Dompet tujuan';

	/// id: 'Dompet sumber'
	String get detailExpenseWalletLabel => 'Dompet sumber';

	/// id: 'Saldo saat ini'
	String get detailCurrentBalance => 'Saldo saat ini';

	/// id: 'Catatan'
	String get detailNoteLabel => 'Catatan';

	/// id: 'Dari'
	String get detailFromLabel => 'Dari';

	/// id: 'Ke'
	String get detailToLabel => 'Ke';

	/// id: 'Jumlah'
	String get detailAmountLabel => 'Jumlah';

	/// id: 'Tersimpan aman di perangkatmu. Saldo dompet mengikuti setiap catatan, jadi saat kamu menyunting atau menghapusnya, saldonya ikut menyesuaikan.'
	String get detailManualNote => 'Tersimpan aman di perangkatmu. Saldo dompet mengikuti setiap catatan, jadi saat kamu menyunting atau menghapusnya, saldonya ikut menyesuaikan.';

	/// id: 'Ubah'
	String get editAction => 'Ubah';

	/// id: 'Catat lagi'
	String get recordAgainAction => 'Catat lagi';

	/// id: 'Hapus transaksi'
	String get deleteAction => 'Hapus transaksi';

	/// id: 'Ubah transaksi'
	String get editSheetTitle => 'Ubah transaksi';

	/// id: 'Simpan perubahan'
	String get saveChangesAction => 'Simpan perubahan';

	/// id: 'Perubahan tersimpan.'
	String get updatedMessage => 'Perubahan tersimpan.';

	/// id: 'Transaksi dihapus.'
	String get deletedMessage => 'Transaksi dihapus.';

	/// id: 'Urungkan'
	String get undoDeleteAction => 'Urungkan';

	/// id: 'Transaksi dikembalikan.'
	String get restoredMessage => 'Transaksi dikembalikan.';

	/// id: 'Anggaran'
	String get budgetLabel => 'Anggaran';

	/// id: 'Lihat anggaran'
	String get openBudgetAction => 'Lihat anggaran';

	/// id: 'Pemasukan ini dicatat dari pembayaran freelance. Untuk mengubahnya, batalkan penerimaannya di Freelance.'
	String get detailFreelanceNote => 'Pemasukan ini dicatat dari pembayaran freelance. Untuk mengubahnya, batalkan penerimaannya di Freelance.';

	/// id: 'Jadikan rutin'
	String get makeRecurringAction => 'Jadikan rutin';

	/// id: 'Bulan sebelumnya'
	String get previousMonth => 'Bulan sebelumnya';

	/// id: 'Bulan berikutnya'
	String get nextMonth => 'Bulan berikutnya';
}

// Path: wallet
class Translations$wallet$id {
	Translations$wallet$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Total saldo semua dompet aktif'
	String get subtitle => 'Total saldo semua dompet aktif';

	/// id: '$count dompet aktif'
	String activeBadge({required Object count}) => '${count} dompet aktif';

	/// id: 'Dompet aktif'
	String get listHeading => 'Dompet aktif';

	/// id: 'Tambah dompet'
	String get addAction => 'Tambah dompet';

	/// id: 'Dompet nonaktif'
	String get inactiveHeading => 'Dompet nonaktif';

	/// id: 'Nonaktif'
	String get inactiveBadge => 'Nonaktif';

	/// id: 'Bank'
	String get typeBank => 'Bank';

	/// id: 'Uang tunai'
	String get typeCash => 'Uang tunai';

	/// id: 'Dompet digital'
	String get typeEwallet => 'Dompet digital';

	/// id: 'Tabungan'
	String get typeSavings => 'Tabungan';

	/// id: 'Kartu'
	String get typeCard => 'Kartu';

	/// id: 'Belum ada dompet tercatat'
	String get emptyTitle => 'Belum ada dompet tercatat';

	/// id: 'Tambahkan dompet pertama untuk mulai mencatat posisi uangmu. Bisa berupa rekening bank, e-wallet, atau uang tunai di saku.'
	String get emptyBody => 'Tambahkan dompet pertama untuk mulai mencatat posisi uangmu. Bisa berupa rekening bank, e-wallet, atau uang tunai di saku.';

	/// id: 'Dompet gagal dimuat'
	String get loadErrorTitle => 'Dompet gagal dimuat';

	/// id: 'Data dompet tidak terbaca. Coba lagi.'
	String get loadErrorSubtitle => 'Data dompet tidak terbaca. Coba lagi.';

	/// id: 'Tambah dompet'
	String get addTitle => 'Tambah dompet';

	/// id: 'Ubah dompet'
	String get editTitle => 'Ubah dompet';

	/// id: 'Dompet baru'
	String get addStepLabel => 'Dompet baru';

	/// id: 'Ubah dompet'
	String get editStepLabel => 'Ubah dompet';

	/// id: 'Nama dompet'
	String get nameLabel => 'Nama dompet';

	/// id: 'Contoh: Tabungan Mandiri, OVO, Brankas Tunai'
	String get nameHint => 'Contoh: Tabungan Mandiri, OVO, Brankas Tunai';

	/// id: 'Wajib'
	String get nameRequiredHint => 'Wajib';

	/// id: 'Maks. 24 karakter'
	String get nameMaxHint => 'Maks. 24 karakter';

	/// id: 'Pilih ikon'
	String get iconLabel => 'Pilih ikon';

	/// id: 'Saldo awal saat ini'
	String get initialBalanceLabel => 'Saldo awal saat ini';

	/// id: 'Saldo awal adalah uang di dompet ini sekarang, titik mulai pencatatanmu. Setiap transaksi berikutnya dihitung dari sini.'
	String get initialBalanceHelp => 'Saldo awal adalah uang di dompet ini sekarang, titik mulai pencatatanmu. Setiap transaksi berikutnya dihitung dari sini.';

	/// id: 'Saldo tercatat saat ini'
	String get currentBalanceLabel => 'Saldo tercatat saat ini';

	/// id: 'Mengubah saldo awal menghitung ulang saldo tercatat. Untuk selisih dengan uang nyata, catat pemasukan atau pengeluaran lewat Catat.'
	String get editBalanceNote => 'Mengubah saldo awal menghitung ulang saldo tercatat. Untuk selisih dengan uang nyata, catat pemasukan atau pengeluaran lewat Catat.';

	/// id: 'Dompet aktif'
	String get activeSwitchLabel => 'Dompet aktif';

	/// id: 'Dompet nonaktif tidak muncul di pemilih dompet. Transaksinya tetap tersimpan dan dihitung.'
	String get activeSwitchHelp => 'Dompet nonaktif tidak muncul di pemilih dompet. Transaksinya tetap tersimpan dan dihitung.';

	/// id: 'Simpan dompet'
	String get saveAddAction => 'Simpan dompet';

	/// id: 'Hapus dompet'
	String get deleteAction => 'Hapus dompet';

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

	/// id: 'Urutkan dompet'
	String get reorderAction => 'Urutkan dompet';

	/// id: 'Urutkan dompet'
	String get reorderTitle => 'Urutkan dompet';

	/// id: 'Tekan dan seret dompet untuk mengubah urutannya. Urutan ini dipakai di semua daftar dan pemilih dompet.'
	String get reorderHint => 'Tekan dan seret dompet untuk mengubah urutannya. Urutan ini dipakai di semua daftar dan pemilih dompet.';

	/// id: 'Seret untuk memindah $name'
	String reorderHandleLabel({required Object name}) => 'Seret untuk memindah ${name}';

	/// id: 'Simpan urutan'
	String get reorderSaveAction => 'Simpan urutan';

	/// id: 'Urutan dompet tersimpan.'
	String get reorderedMessage => 'Urutan dompet tersimpan.';

	/// id: 'Dompet ini sudah punya transaksi, jadi tidak bisa dihapus. Nonaktifkan saja.'
	String get deleteBlockedMessage => 'Dompet ini sudah punya transaksi, jadi tidak bisa dihapus. Nonaktifkan saja.';

	/// id: 'Data tersimpan lokal dan privat di perangkatmu.'
	String get privacyNote => 'Data tersimpan lokal dan privat di perangkatmu.';

	/// id: 'Kembali'
	String get detailBackLabel => 'Kembali';

	/// id: 'Sunting'
	String get detailEditAction => 'Sunting';

	/// id: 'Transaksi bulan ini'
	String get detailRecentHeading => 'Transaksi bulan ini';

	/// id: 'Pemasukan'
	String get detailIncomeLabel => 'Pemasukan';

	/// id: 'Pengeluaran'
	String get detailExpenseLabel => 'Pengeluaran';

	/// id: 'Belum ada transaksi'
	String get detailRecentEmptyTitle => 'Belum ada transaksi';

	/// id: 'Belum ada transaksi bulan ini untuk dompet ini.'
	String get detailRecentEmpty => 'Belum ada transaksi bulan ini untuk dompet ini.';

	/// id: 'Lihat semua transaksi'
	String get detailViewAllAction => 'Lihat semua transaksi';

	/// id: 'Catat transaksi'
	String get detailRecordAction => 'Catat transaksi';

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

	/// id: '$count aktif'
	String activeBadge({required Object count}) => '${count} aktif';

	/// id: 'Rencana'
	String get plannedLabel => 'Rencana';

	/// id: 'Terpakai'
	String get spentLabel => 'Terpakai';

	/// id: 'Sisa'
	String get remainingLabel => 'Sisa';

	/// id: 'Semua'
	String get filterAll => 'Semua';

	/// id: 'Aktif'
	String get filterActive => 'Aktif';

	/// id: 'Selesai'
	String get filterFinished => 'Selesai';

	/// id: 'Nonaktif'
	String get filterArchived => 'Nonaktif';

	/// id: 'Semua dompet'
	String get filterWalletAll => 'Semua dompet';

	/// id: 'Buat anggaran'
	String get addAction => 'Buat anggaran';

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

	/// id: 'Belum ada anggaran'
	String get emptyTitle => 'Belum ada anggaran';

	/// id: 'Rencanakan batas belanja mingguan atau bulanan untuk satu dompet, lalu pantau berapa yang sudah terpakai.'
	String get emptyBody => 'Rencanakan batas belanja mingguan atau bulanan untuk satu dompet, lalu pantau berapa yang sudah terpakai.';

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

	/// id: 'Buat anggaran'
	String get addTitle => 'Buat anggaran';

	/// id: 'Ubah anggaran'
	String get editTitle => 'Ubah anggaran';

	/// id: 'Aturan anggaran'
	String get ruleTitle => 'Aturan anggaran';

	/// id: 'Rencana ini jadi patokan belanjamu. Saldo dompet bergerak dari transaksi yang kamu catat.'
	String get ruleBody => 'Rencana ini jadi patokan belanjamu. Saldo dompet bergerak dari transaksi yang kamu catat.';

	/// id: 'Nama anggaran'
	String get nameLabel => 'Nama anggaran';

	/// id: 'Contoh: Kebutuhan Rumah Tangga'
	String get nameHint => 'Contoh: Kebutuhan Rumah Tangga';

	/// id: 'Wajib'
	String get requiredHint => 'Wajib';

	/// id: 'Dompet terkait'
	String get walletLabel => 'Dompet terkait';

	/// id: 'Hanya pengeluaran dan transfer keluar dompet ini yang dihitung.'
	String get walletHelp => 'Hanya pengeluaran dan transfer keluar dompet ini yang dihitung.';

	/// id: 'Saldo: $amount'
	String walletBalance({required Object amount}) => 'Saldo: ${amount}';

	/// id: 'Periode'
	String get periodLabel => 'Periode';

	/// id: 'Mulai'
	String get startDateLabel => 'Mulai';

	/// id: '$start – $end'
	String periodRange({required Object start, required Object end}) => '${start} – ${end}';

	/// id: '$start–$end'
	String periodRangeShort({required Object start, required Object end}) => '${start}–${end}';

	/// id: 'Mulai $date · $range'
	String periodStartRow({required Object date, required Object range}) => 'Mulai ${date} · ${range}';

	/// id: 'Pos anggaran'
	String get itemsLabel => 'Pos anggaran';

	/// id: 'Rincian rencana belanja atau rencana transfer. Total rencana anggaran adalah jumlah seluruh pos.'
	String get itemsHelp => 'Rincian rencana belanja atau rencana transfer. Total rencana anggaran adalah jumlah seluruh pos.';

	/// id: 'Tambah pos'
	String get addItemAction => 'Tambah pos';

	/// id: 'Simpan anggaran'
	String get saveAddAction => 'Simpan anggaran';

	/// id: 'Arsipkan anggaran'
	String get archiveAction => 'Arsipkan anggaran';

	/// id: 'Aktifkan kembali'
	String get unarchiveAction => 'Aktifkan kembali';

	/// id: 'Anggaran nonaktif disembunyikan dari daftar aktif. Transaksi yang tertaut tetap tercatat.'
	String get archiveHelp => 'Anggaran nonaktif disembunyikan dari daftar aktif. Transaksi yang tertaut tetap tercatat.';

	/// id: 'Hapus anggaran'
	String get deleteAction => 'Hapus anggaran';

	/// id: 'Hapus anggaran?'
	String get deleteConfirmTitle => 'Hapus anggaran?';

	/// id: 'Anggaran "$name" beserta posnya akan dihapus. Transaksi yang tertaut tetap tercatat dan saldo dompet tidak berubah.'
	String deleteConfirmMessage({required Object name}) => 'Anggaran "${name}" beserta posnya akan dihapus. Transaksi yang tertaut tetap tercatat dan saldo dompet tidak berubah.';

	/// id: 'Tambah pos'
	String get itemAddTitle => 'Tambah pos';

	/// id: 'Ubah pos'
	String get itemEditTitle => 'Ubah pos';

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

	/// id: 'Simpan pos'
	String get itemSaveAction => 'Simpan pos';

	/// id: 'Hapus pos'
	String get itemDeleteAction => 'Hapus pos';

	/// id: 'Daftar anggaran'
	String get detailBackLabel => 'Daftar anggaran';

	/// id: 'Sunting anggaran'
	String get detailEditAction => 'Sunting anggaran';

	/// id: 'Catat pengeluaran'
	String get detailRecordExpenseAction => 'Catat pengeluaran';

	/// id: 'Catat transfer'
	String get detailRecordTransferAction => 'Catat transfer';

	/// id: 'Pos anggaran'
	String get detailItemsHeading => 'Pos anggaran';

	/// id: 'Anggaran ini belum punya pos. Tambahkan pos lewat Sunting supaya pengeluaran bisa ditautkan.'
	String get detailNoItems => 'Anggaran ini belum punya pos. Tambahkan pos lewat Sunting supaya pengeluaran bisa ditautkan.';

	/// id: 'Transaksi tertaut'
	String get detailLinkedHeading => 'Transaksi tertaut';

	/// id: 'Belum ada transaksi yang tertaut ke anggaran ini.'
	String get detailLinkedEmpty => 'Belum ada transaksi yang tertaut ke anggaran ini.';

	/// id: 'Cara kerja pos anggaran'
	String get detailHowTitle => 'Cara kerja pos anggaran';

	/// id: 'Dompet tidak ditemukan'
	String get unknownWallet => 'Dompet tidak ditemukan';

	/// id: 'Total rencana'
	String get totalPlannedLabel => 'Total rencana';

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

	/// id: 'Template anggaran'
	String get templatesAction => 'Template anggaran';

	/// id: 'Template anggaran'
	String get templatesTitle => 'Template anggaran';

	/// id: '$count tersimpan'
	String templatesSavedBadge({required Object count}) => '${count} tersimpan';

	/// id: 'Apa itu template anggaran?'
	String get templatesInfoTitle => 'Apa itu template anggaran?';

	/// id: 'Susunan pos rencana yang bisa dipakai ulang tanpa mengetik dari nol. Setiap pemakaian membuat anggaran baru yang berdiri sendiri.'
	String get templatesInfoBody => 'Susunan pos rencana yang bisa dipakai ulang tanpa mengetik dari nol. Setiap pemakaian membuat anggaran baru yang berdiri sendiri.';

	/// id: '$count pos'
	String templateItemCount({required Object count}) => '${count} pos';

	/// id: 'Daftar pos rencana'
	String get templateItemsLabel => 'Daftar pos rencana';

	/// id: 'Total rencana'
	String get templateTotalLabel => 'Total rencana';

	/// id: 'Gunakan template ini'
	String get templateUseAction => 'Gunakan template ini';

	/// id: 'Ubah'
	String get templateEditAction => 'Ubah';

	/// id: 'Duplikat'
	String get templateDuplicateAction => 'Duplikat';

	/// id: 'Nonaktif'
	String get templateInactiveBadge => 'Nonaktif';

	/// id: 'Buat template'
	String get templateAddAction => 'Buat template';

	/// id: 'Template bisa disunting kapan saja tanpa mengubah anggaran yang sudah dibuat darinya.'
	String get templatesFooter => 'Template bisa disunting kapan saja tanpa mengubah anggaran yang sudah dibuat darinya.';

	/// id: 'Belum ada template'
	String get templatesEmptyBadge => 'Belum ada template';

	/// id: 'Belum ada template'
	String get templatesEmptyTitle => 'Belum ada template';

	/// id: 'Simpan susunan pos yang sering dipakai, misalnya belanja bulanan, supaya anggaran berikutnya tinggal dipakai.'
	String get templatesEmptyBody => 'Simpan susunan pos yang sering dipakai, misalnya belanja bulanan, supaya anggaran berikutnya tinggal dipakai.';

	/// id: 'Buat dompet aktif dulu untuk memakai template.'
	String get templateNeedsWallet => 'Buat dompet aktif dulu untuk memakai template.';

	/// id: 'Template gagal dimuat'
	String get templatesLoadError => 'Template gagal dimuat';

	/// id: 'Buat template'
	String get templateAddTitle => 'Buat template';

	/// id: 'Ubah template'
	String get templateEditTitle => 'Ubah template';

	/// id: 'Template menyimpan susunan pos rencanamu. Dompet dan periodenya dipilih saat template dipakai.'
	String get templateRuleBody => 'Template menyimpan susunan pos rencanamu. Dompet dan periodenya dipilih saat template dipakai.';

	/// id: 'Contoh: Belanja bulanan'
	String get templateNameHint => 'Contoh: Belanja bulanan';

	/// id: 'Tawarkan template ini'
	String get templateEnabledLabel => 'Tawarkan template ini';

	/// id: 'Template nonaktif tetap tersimpan, tapi tidak bisa dipakai membuat anggaran.'
	String get templateEnabledHelp => 'Template nonaktif tetap tersimpan, tapi tidak bisa dipakai membuat anggaran.';

	/// id: 'Simpan template'
	String get templateSaveAction => 'Simpan template';

	/// id: 'Hapus template'
	String get templateDeleteAction => 'Hapus template';

	/// id: 'Hapus template?'
	String get templateDeleteConfirmTitle => 'Hapus template?';

	/// id: 'Template "$name" akan dihapus. Anggaran yang pernah dibuat darinya tidak ikut terhapus.'
	String templateDeleteConfirmMessage({required Object name}) => 'Template "${name}" akan dihapus. Anggaran yang pernah dibuat darinya tidak ikut terhapus.';

	/// id: 'Template tersimpan.'
	String get templateSavedMessage => 'Template tersimpan.';

	/// id: 'Perubahan template tersimpan.'
	String get templateUpdatedMessage => 'Perubahan template tersimpan.';

	/// id: 'Template dihapus.'
	String get templateDeletedMessage => 'Template dihapus.';

	/// id: 'Template digandakan.'
	String get templateDuplicatedMessage => 'Template digandakan.';

	/// id: '$name (salinan)'
	String templateCopyName({required Object name}) => '${name} (salinan)';

	/// id: 'Nama template'
	String get templateNameLabel => 'Nama template';

	/// id: 'Ulangi tiap periode'
	String get repeatLabel => 'Ulangi tiap periode';

	/// id: 'Lahir lagi tiap bulan mulai $date dengan pos yang sama.'
	String repeatHelpMonthly({required Object date}) => 'Lahir lagi tiap bulan mulai ${date} dengan pos yang sama.';

	/// id: 'Lahir lagi tiap minggu mulai $date dengan pos yang sama.'
	String repeatHelpWeekly({required Object date}) => 'Lahir lagi tiap minggu mulai ${date} dengan pos yang sama.';

	/// id: 'Anggaran bulanan bisa diulang bila mulai tanggal 1–28.'
	String get repeatUnavailable => 'Anggaran bulanan bisa diulang bila mulai tanggal 1–28.';

	/// id: 'Periode ini sudah lewat. Perubahannya tidak memengaruhi periode berikutnya.'
	String get repeatPastNote => 'Periode ini sudah lewat. Perubahannya tidak memengaruhi periode berikutnya.';

	/// id: 'Berlaku untuk'
	String get scopeTitle => 'Berlaku untuk';

	/// id: 'Hanya periode ini'
	String get scopeThisPeriod => 'Hanya periode ini';

	/// id: 'Periode ini dan berikutnya'
	String get scopeThisAndNext => 'Periode ini dan berikutnya';

	/// id: 'Rutin'
	String get recurringBadge => 'Rutin';

	/// id: 'Ulangi tiap bulan · $wallet'
	String templateScheduledMonthly({required Object wallet}) => 'Ulangi tiap bulan · ${wallet}';

	/// id: 'Ulangi tiap minggu · $wallet'
	String templateScheduledWeekly({required Object wallet}) => 'Ulangi tiap minggu · ${wallet}';

	/// id: 'Hari ke-$day dari $total'
	String dayOfPeriod({required Object day, required Object total}) => 'Hari ke-${day} dari ${total}';
}

// Path: freelance
class Translations$freelance$id {
	Translations$freelance$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Freelance'
	String get title => 'Freelance';

	/// id: 'Jam kerja ($count)'
	String worklogTab({required Object count}) => 'Jam kerja (${count})';

	/// id: 'Tagihan ($count)'
	String paymentsTab({required Object count}) => 'Tagihan (${count})';

	/// id: 'Data freelance gagal dimuat'
	String get loadErrorTitle => 'Data freelance gagal dimuat';

	/// id: 'Cara Freelance mencatat'
	String get ruleTitle => 'Cara Freelance mencatat';

	/// id: 'Jam kerja terkumpul jadi tagihan, dan saldo dompet bertambah saat tagihannya dicatat diterima.'
	String get ruleBody => 'Jam kerja terkumpul jadi tagihan, dan saldo dompet bertambah saat tagihannya dicatat diterima.';

	/// id: '$hours jam'
	String hoursValue({required Object hours}) => '${hours} jam';

	/// id: 'jam'
	String get hourShort => 'jam';

	/// id: '$count proyek'
	String projectCount({required Object count}) => '${count} proyek';

	/// id: 'Total diperoleh'
	String get earnedLabel => 'Total diperoleh';

	/// id: 'Sudah diterima'
	String get paidLabel => 'Sudah diterima';

	/// id: 'Belum diterima'
	String get unpaidLabel => 'Belum diterima';

	/// id: 'Proyek'
	String get projectsLabel => 'Proyek';

	/// id: 'Belum ada proyek. Tambahkan klien atau proyek beserta tarif per jamnya dulu.'
	String get projectsEmpty => 'Belum ada proyek. Tambahkan klien atau proyek beserta tarif per jamnya dulu.';

	/// id: 'Tambah proyek'
	String get projectAddTitle => 'Tambah proyek';

	/// id: 'Ubah proyek'
	String get projectEditTitle => 'Ubah proyek';

	/// id: 'Nama klien atau proyek'
	String get projectNameLabel => 'Nama klien atau proyek';

	/// id: 'Contoh: Studio Koding'
	String get projectNameHint => 'Contoh: Studio Koding';

	/// id: 'Wajib'
	String get requiredHint => 'Wajib';

	/// id: 'Tarif per jam'
	String get hourlyRateLabel => 'Tarif per jam';

	/// id: 'Tarif bawaan untuk jam kerja baru. Mengubahnya tidak mengubah jam kerja yang sudah dicatat.'
	String get hourlyRateHelp => 'Tarif bawaan untuk jam kerja baru. Mengubahnya tidak mengubah jam kerja yang sudah dicatat.';

	/// id: 'Potongan'
	String get deductionsLabel => 'Potongan';

	/// id: 'Dipotong dari gaji kotor setiap tagihan, misalnya pajak. Mengubahnya tidak mengubah tagihan yang sudah dibuat.'
	String get deductionsHelp => 'Dipotong dari gaji kotor setiap tagihan, misalnya pajak. Mengubahnya tidak mengubah tagihan yang sudah dibuat.';

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

	/// id: 'Nominal per tagihan'
	String get deductionAmountLabel => 'Nominal per tagihan';

	/// id: 'Simpan potongan'
	String get deductionSaveAction => 'Simpan potongan';

	/// id: 'Hapus potongan'
	String get deductionRemoveAction => 'Hapus potongan';

	/// id: 'Simpan proyek'
	String get projectSaveAction => 'Simpan proyek';

	/// id: 'Hapus proyek'
	String get projectDeleteAction => 'Hapus proyek';

	/// id: 'Proyek yang sudah punya jam kerja tidak bisa dihapus.'
	String get projectDeleteLockedHint => 'Proyek yang sudah punya jam kerja tidak bisa dihapus.';

	/// id: 'Hapus proyek?'
	String get projectDeleteConfirmTitle => 'Hapus proyek?';

	/// id: 'Proyek "$name" akan dihapus.'
	String projectDeleteConfirmMessage({required Object name}) => 'Proyek "${name}" akan dihapus.';

	/// id: 'Proyek ini sudah punya jam kerja, jadi tidak bisa dihapus.'
	String get projectDeleteRefused => 'Proyek ini sudah punya jam kerja, jadi tidak bisa dihapus.';

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

	/// id: 'Catat jam kerja'
	String get entryAddTitle => 'Catat jam kerja';

	/// id: 'Ubah jam kerja'
	String get entryEditTitle => 'Ubah jam kerja';

	/// id: 'Jam kerja terkumpul jadi tagihan. Uangnya masuk ke saldo saat tagihannya dicatat diterima.'
	String get entryRuleBody => 'Jam kerja terkumpul jadi tagihan. Uangnya masuk ke saldo saat tagihannya dicatat diterima.';

	/// id: 'Tanggal kerja'
	String get workDateLabel => 'Tanggal kerja';

	/// id: 'Durasi pengerjaan'
	String get hoursLabel => 'Durasi pengerjaan';

	/// id: 'Terisi dari tarif proyek. Ubah kalau tarif kali ini berbeda.'
	String get entryRateHelp => 'Terisi dari tarif proyek. Ubah kalau tarif kali ini berbeda.';

	/// id: 'Catatan'
	String get noteLabel => 'Catatan';

	/// id: 'Apa yang dikerjakan (opsional)'
	String get noteHint => 'Apa yang dikerjakan (opsional)';

	/// id: 'Simpan jam kerja'
	String get entrySaveAction => 'Simpan jam kerja';

	/// id: 'Nominal ini tercatat sebagai diperoleh, belum diterima.'
	String get entrySaveHint => 'Nominal ini tercatat sebagai diperoleh, belum diterima.';

	/// id: 'Hapus jam kerja'
	String get entryDeleteAction => 'Hapus jam kerja';

	/// id: 'Hapus jam kerja ini?'
	String get entryDeleteConfirmTitle => 'Hapus jam kerja ini?';

	/// id: 'Jam kerja ini dihapus. Saldo dompet tidak berubah.'
	String get entryDeleteConfirmMessage => 'Jam kerja ini dihapus. Saldo dompet tidak berubah.';

	/// id: 'Jam kerja yang sudah masuk tagihan tidak bisa diubah atau dihapus.'
	String get entryLockedMessage => 'Jam kerja yang sudah masuk tagihan tidak bisa diubah atau dihapus.';

	/// id: 'Jam kerja tercatat.'
	String get entrySavedMessage => 'Jam kerja tercatat.';

	/// id: 'Perubahan jam kerja tersimpan.'
	String get entryUpdatedMessage => 'Perubahan jam kerja tersimpan.';

	/// id: 'Jam kerja dihapus.'
	String get entryDeletedMessage => 'Jam kerja dihapus.';

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

	/// id: 'Tertunda (bersih)'
	String get pendingTotalLabel => 'Tertunda (bersih)';

	/// id: 'Buat tagihan'
	String get paymentAddTitle => 'Buat tagihan';

	/// id: 'Tagihan mengelompokkan jam kerja yang belum ditagih. Saat dicatat diterima, saldo dompet bertambah.'
	String get paymentCreateRuleBody => 'Tagihan mengelompokkan jam kerja yang belum ditagih. Saat dicatat diterima, saldo dompet bertambah.';

	/// id: 'Ditagih: $count catatan, $hours jam'
	String paymentEntriesLabel({required Object count, required Object hours}) => 'Ditagih: ${count} catatan, ${hours} jam';

	/// id: '$count catatan · $hours jam'
	String paymentEntriesSummary({required Object count, required Object hours}) => '${count} catatan · ${hours} jam';

	/// id: 'Perkiraan tanggal diterima'
	String get expectedDateLabel => 'Perkiraan tanggal diterima';

	/// id: 'Gaji kotor'
	String get grossPayLabel => 'Gaji kotor';

	/// id: 'Gaji bersih'
	String get netPayLabel => 'Gaji bersih';

	/// id: 'Potongan tidak boleh sama dengan atau melebihi gaji kotor.'
	String get netPayNotPositive => 'Potongan tidak boleh sama dengan atau melebihi gaji kotor.';

	/// id: 'Buat tagihan'
	String get paymentCreateAction => 'Buat tagihan';

	/// id: 'Ubah tanggal'
	String get paymentChangeDateAction => 'Ubah tanggal';

	/// id: 'Hapus'
	String get paymentDeleteAction => 'Hapus';

	/// id: 'Hapus tagihan?'
	String get paymentDeleteConfirmTitle => 'Hapus tagihan?';

	/// id: 'Tagihan tertunda ini dihapus dan jam kerjanya kembali belum ditagih. Saldo dompet tidak berubah.'
	String get paymentDeleteConfirmMessage => 'Tagihan tertunda ini dihapus dan jam kerjanya kembali belum ditagih. Saldo dompet tidak berubah.';

	/// id: 'Jam kerja yang dipilih sudah ditagih atau bukan milik proyek ini.'
	String get paymentEntriesInvalid => 'Jam kerja yang dipilih sudah ditagih atau bukan milik proyek ini.';

	/// id: 'Tagihan yang sudah diterima tidak bisa dihapus. Batalkan penerimaannya dulu.'
	String get paymentPaidLocked => 'Tagihan yang sudah diterima tidak bisa dihapus. Batalkan penerimaannya dulu.';

	/// id: 'Tagihan ini sudah dicatat diterima.'
	String get paymentAlreadyPaid => 'Tagihan ini sudah dicatat diterima.';

	/// id: 'Tagihan dibuat.'
	String get paymentCreatedMessage => 'Tagihan dibuat.';

	/// id: 'Tanggal tagihan diperbarui.'
	String get paymentUpdatedMessage => 'Tanggal tagihan diperbarui.';

	/// id: 'Tagihan dihapus.'
	String get paymentDeletedMessage => 'Tagihan dihapus.';

	/// id: 'Catat tagihan diterima'
	String get receiveTitle => 'Catat tagihan diterima';

	/// id: 'Honor sudah masuk'
	String get receiveRuleTitle => 'Honor sudah masuk';

	/// id: 'Catat saat uangnya sudah kamu terima. Saldo dompet pilihan bertambah sebesar gaji bersih, dan tagihan ini tercatat lunas.'
	String get receiveRuleBody => 'Catat saat uangnya sudah kamu terima. Saldo dompet pilihan bertambah sebesar gaji bersih, dan tagihan ini tercatat lunas.';

	/// id: 'Nominal diterima'
	String get receiveAmountLabel => 'Nominal diterima';

	/// id: 'Dompet penerima'
	String get receiveWalletLabel => 'Dompet penerima';

	/// id: 'Tanggal diterima'
	String get receiveDateLabel => 'Tanggal diterima';

	/// id: 'Tagihan freelance $project'
	String receiveNoteDefault({required Object project}) => 'Tagihan freelance ${project}';

	/// id: 'Catat diterima'
	String get receiveAction => 'Catat diterima';

	/// id: 'Tagihan dicatat diterima. Saldo dompet bertambah.'
	String get paymentReceivedMessage => 'Tagihan dicatat diterima. Saldo dompet bertambah.';

	/// id: 'Batalkan penerimaan'
	String get receiptCancelAction => 'Batalkan penerimaan';

	/// id: 'Batalkan penerimaan?'
	String get receiptCancelConfirmTitle => 'Batalkan penerimaan?';

	/// id: 'Pemasukannya dihapus dan saldo dompet berkurang kembali. Tagihan kembali tertunda.'
	String get receiptCancelConfirmMessage => 'Pemasukannya dihapus dan saldo dompet berkurang kembali. Tagihan kembali tertunda.';

	/// id: 'Penerimaan dibatalkan. Tagihan kembali tertunda.'
	String get receiptCancelledMessage => 'Penerimaan dibatalkan. Tagihan kembali tertunda.';

	/// id: 'Ubah'
	String get changeAction => 'Ubah';

	/// id: 'Hapus pemasukan'
	String get receiptCancelConfirmAction => 'Hapus pemasukan';

	/// id: 'Tagih ($count)'
	String billAction({required Object count}) => 'Tagih (${count})';

	/// id: 'Belum ada jam kerja'
	String get entriesEmptyTitle => 'Belum ada jam kerja';

	/// id: 'Jam kerja yang kamu catat jadi dasar tagihan proyek ini.'
	String get entriesEmptyBody => 'Jam kerja yang kamu catat jadi dasar tagihan proyek ini.';

	/// id: 'Tidak ada jam kerja dengan status ini.'
	String get entriesFilteredEmpty => 'Tidak ada jam kerja dengan status ini.';

	/// id: 'Catat jam kerja'
	String get entryAddShortAction => 'Catat jam kerja';

	/// id: 'Semua'
	String get filterAll => 'Semua';

	/// id: 'Tanpa potongan'
	String get noDeductions => 'Tanpa potongan';

	/// id: 'Total $hours jam · $amount'
	String projectTotals({required Object hours, required Object amount}) => 'Total ${hours} jam · ${amount}';

	/// id: 'Belum ada proyek'
	String get projectsEmptyTitle => 'Belum ada proyek';

	/// id: 'Belum ditagih'
	String get unbilledLabel => 'Belum ditagih';

	/// id: 'Belum ada tagihan'
	String get paymentsEmptyTitle => 'Belum ada tagihan';

	/// id: 'Kumpulkan jam kerja yang belum ditagih jadi satu tagihan, lalu catat saat dibayar.'
	String get paymentsEmptyBody => 'Kumpulkan jam kerja yang belum ditagih jadi satu tagihan, lalu catat saat dibayar.';

	/// id: 'Tidak ada tagihan dengan status ini.'
	String get paymentsFilteredEmpty => 'Tidak ada tagihan dengan status ini.';

	/// id: '$count tagihan · terdekat $date'
	String nextExpected({required Object count, required Object date}) => '${count} tagihan · terdekat ${date}';

	/// id: 'Kerja $range'
	String paymentWorkRange({required Object range}) => 'Kerja ${range}';

	/// id: 'Lunas'
	String get paidOffBadge => 'Lunas';
}

// Path: home
class Translations$home$id {
	Translations$home$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Arus $period'
	String flowTitle({required Object period}) => 'Arus ${period}';

	/// id: 'Beranda gagal dimuat'
	String get loadErrorTitle => 'Beranda gagal dimuat';

	/// id: 'Total saldo'
	String get balanceLabel => 'Total saldo';

	/// id: '$count dompet aktif'
	String walletCount({required Object count}) => '${count} dompet aktif';

	/// id: 'Anggaran aktif'
	String get budgetTitle => 'Anggaran aktif';

	/// id: 'Sisa'
	String get budgetRemaining => 'Sisa';

	/// id: 'Lewat rencana'
	String get budgetOver => 'Lewat rencana';

	/// id: 'Lihat anggaran'
	String get budgetAction => 'Lihat anggaran';

	/// id: 'Freelance'
	String get freelanceTitle => 'Freelance';

	/// id: 'Lihat Freelance'
	String get freelanceAction => 'Lihat Freelance';

	/// id: 'Transaksi terbaru'
	String get recentTitle => 'Transaksi terbaru';

	/// id: 'Lihat semua'
	String get seeAll => 'Lihat semua';

	/// id: 'Mulai dari dompetmu'
	String get firstTitle => 'Mulai dari dompetmu';

	/// id: 'Catat di mana uangmu berada sekarang. Setiap transaksi akan memperbarui saldonya.'
	String get firstBody => 'Catat di mana uangmu berada sekarang. Setiap transaksi akan memperbarui saldonya.';

	/// id: 'Tambah dompet pertama'
	String get stepWalletTitle => 'Tambah dompet pertama';

	/// id: 'Rekening bank, dompet digital, atau uang tunai beserta saldonya.'
	String get stepWalletBody => 'Rekening bank, dompet digital, atau uang tunai beserta saldonya.';

	/// id: 'Catat transaksi pertama'
	String get stepRecordTitle => 'Catat transaksi pertama';

	/// id: 'Pengeluaran, pemasukan, atau transfer. Bisa diketik atau diucapkan.'
	String get stepRecordBody => 'Pengeluaran, pemasukan, atau transfer. Bisa diketik atau diucapkan.';

	/// id: 'Buat anggaran'
	String get stepBudgetTitle => 'Buat anggaran';

	/// id: 'Opsional. Rencanakan batas belanja dan lihat sisanya.'
	String get stepBudgetBody => 'Opsional. Rencanakan batas belanja dan lihat sisanya.';

	/// id: 'Selesai'
	String get stepDone => 'Selesai';

	/// id: 'Langkah awal'
	String get stepsTitle => 'Langkah awal';

	/// id: 'Belum ada transaksi'
	String get emptyTitle => 'Belum ada transaksi';

	/// id: 'Mulai dengan mencatat pemasukan, pengeluaran, atau transfer pertamamu.'
	String get emptyBody => 'Mulai dengan mencatat pemasukan, pengeluaran, atau transfer pertamamu.';

	/// id: 'Catat transaksi'
	String get recordAction => 'Catat transaksi';

	/// id: 'Tambah dompet'
	String get createWalletAction => 'Tambah dompet';

	/// id: 'Atau buat anggaran pengeluaran'
	String get budgetLink => 'Atau buat anggaran pengeluaran';

	/// id: '$spent terpakai dari $planned'
	String budgetSpentOf({required Object spent, required Object planned}) => '${spent} terpakai dari ${planned}';

	/// id: 'Di $count dompet'
	String walletLink({required Object count}) => 'Di ${count} dompet';

	/// id: 'Selisih bulan ini'
	String get netLabel => 'Selisih bulan ini';

	/// id: 'Sembunyikan nominal'
	String get hideAmounts => 'Sembunyikan nominal';

	/// id: 'Tampilkan nominal'
	String get showAmounts => 'Tampilkan nominal';

	/// id: 'Aman'
	String get budgetSafe => 'Aman';

	/// id: 'Hampir habis'
	String get budgetNearlyOut => 'Hampir habis';

	/// id: 'Lewat $amount'
	String budgetOverBy({required Object amount}) => 'Lewat ${amount}';

	/// id: 'Belum diterima'
	String get freelanceRowTitle => 'Belum diterima';

	/// id: '$count tagihan, perkiraan $date'
	String freelanceRowSub({required Object count, required Object date}) => '${count} tagihan, perkiraan ${date}';

	/// id: 'Pemasukan'
	String get incomeStat => 'Pemasukan';

	/// id: 'Pengeluaran'
	String get expenseStat => 'Pengeluaran';
}

// Path: onboarding
class Translations$onboarding$id {
	Translations$onboarding$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Lewati'
	String get skipAction => 'Lewati';

	/// id: 'Lanjut'
	String get nextAction => 'Lanjut';

	/// id: 'Tutup'
	String get closeAction => 'Tutup';

	/// id: 'Halaman $current dari $total'
	String pageIndicatorLabel({required Object current, required Object total}) => 'Halaman ${current} dari ${total}';

	/// id: 'Semua uangmu, satu buku'
	String get page1Title => 'Semua uangmu, satu buku';

	/// id: 'Lihat di mana uangmu berada, apa saja yang terjadi padanya, dan ke mana kamu merencanakannya — semuanya di satu buku catatan.'
	String get page1Body => 'Lihat di mana uangmu berada, apa saja yang terjadi padanya, dan ke mana kamu merencanakannya — semuanya di satu buku catatan.';

	/// id: 'Tahu di mana uangmu'
	String get page2Title => 'Tahu di mana uangmu';

	/// id: 'Rekening bank, e-wallet, dan uang tunai jadi dompet. Saldo tiap dompet dan totalnya selalu terlihat.'
	String get page2Body => 'Rekening bank, e-wallet, dan uang tunai jadi dompet. Saldo tiap dompet dan totalnya selalu terlihat.';

	/// id: 'Catat dalam hitungan detik'
	String get page3Title => 'Catat dalam hitungan detik';

	/// id: 'Pemasukan, pengeluaran, atau pindah dompet — ketuk Catat. Dompet yang biasa kamu pakai dan kategori favoritmu sudah menunggu.'
	String get page3Body => 'Pemasukan, pengeluaran, atau pindah dompet — ketuk Catat. Dompet yang biasa kamu pakai dan kategori favoritmu sudah menunggu.';

	/// id: 'Rencanakan, lalu pantau'
	String get page4Title => 'Rencanakan, lalu pantau';

	/// id: 'Susun anggaran per minggu atau bulan dengan pos-pos belanjamu. Saldo tetap utuh, dan kamu melihat berapa yang sudah terpakai dari rencana.'
	String get page4Body => 'Susun anggaran per minggu atau bulan dengan pos-pos belanjamu. Saldo tetap utuh, dan kamu melihat berapa yang sudah terpakai dari rencana.';

	/// id: 'Mulai dari dompet pertamamu'
	String get finalTitle => 'Mulai dari dompet pertamamu';

	/// id: 'Tambahkan satu dompet, lalu catat transaksi pertamamu. Di tiap layar, tanuki akan menunjukkan jalannya.'
	String get finalBody => 'Tambahkan satu dompet, lalu catat transaksi pertamamu. Di tiap layar, tanuki akan menunjukkan jalannya.';

	/// id: 'Tambah dompet'
	String get createWalletAction => 'Tambah dompet';

	/// id: 'Nanti saja'
	String get laterAction => 'Nanti saja';

	/// id: 'Sudah punya akun? Masuk'
	String get signInAction => 'Sudah punya akun? Masuk';

	/// id: 'Kembali'
	String get backAction => 'Kembali';

	/// id: 'Pilih mata uangmu'
	String get currencyTitle => 'Pilih mata uangmu';

	/// id: 'Semua nominal di Tanukonomy memakai mata uang ini. Nanti bisa diganti di layar Akun, tapi angka yang sudah dicatat tidak dikonversi.'
	String get currencyBody => 'Semua nominal di Tanukonomy memakai mata uang ini. Nanti bisa diganti di layar Akun, tapi angka yang sudah dicatat tidak dikonversi.';

	/// id: 'Sesuai wilayah perangkatmu'
	String get currencySuggested => 'Sesuai wilayah perangkatmu';

	/// id: 'Pilih mata uang dulu'
	String get currencyChooseFirst => 'Pilih mata uang dulu';

	/// id: 'Pakai $code'
	String currencyConfirm({required Object code}) => 'Pakai ${code}';

	/// id: 'Pilih bahasa'
	String get languageTitle => 'Pilih bahasa';

	/// id: 'Dipakai untuk tampilan aplikasi dan saat mencatat dengan suara. Bisa diubah lagi di layar Akun.'
	String get languageBody => 'Dipakai untuk tampilan aplikasi dan saat mencatat dengan suara. Bisa diubah lagi di layar Akun.';

	/// id: 'Lanjut'
	String get languageConfirm => 'Lanjut';
}

// Path: tour
class Translations$tour$id {
	Translations$tour$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Lanjut'
	String get nextAction => 'Lanjut';

	/// id: 'Selesai'
	String get doneAction => 'Selesai';

	/// id: 'Lewati tur'
	String get skipAction => 'Lewati tur';

	/// id: '$current/$total'
	String stepCounter({required Object current, required Object total}) => '${current}/${total}';

	/// id: 'Langkah $current dari $total: $title. $body'
	String stepSemantics({required Object current, required Object total, required Object title, required Object body}) => 'Langkah ${current} dari ${total}: ${title}. ${body}';

	/// id: 'Total saldo tercatat'
	String get homeBalanceTitle => 'Total saldo tercatat';

	/// id: 'Jumlah saldo semua dompet aktif — posisi uangmu dalam sekali lihat.'
	String get homeBalanceBody => 'Jumlah saldo semua dompet aktif — posisi uangmu dalam sekali lihat.';

	/// id: 'Satu pintu mencatat'
	String get homeRecordTitle => 'Satu pintu mencatat';

	/// id: 'Semua pemasukan, pengeluaran, dan transfer dicatat dari sini.'
	String get homeRecordBody => 'Semua pemasukan, pengeluaran, dan transfer dicatat dari sini.';

	/// id: 'Arus bulan ini'
	String get homeCashFlowTitle => 'Arus bulan ini';

	/// id: 'Uang yang benar-benar masuk dan keluar bulan ini.'
	String get homeCashFlowBody => 'Uang yang benar-benar masuk dan keluar bulan ini.';

	/// id: 'Sisa anggaran aktif'
	String get homeBudgetTitle => 'Sisa anggaran aktif';

	/// id: 'Sisa rencana dari anggaran yang sedang berjalan. Ketuk untuk rinciannya.'
	String get homeBudgetBody => 'Sisa rencana dari anggaran yang sedang berjalan. Ketuk untuk rinciannya.';

	/// id: 'Ringkasan freelance'
	String get homeFreelanceTitle => 'Ringkasan freelance';

	/// id: 'Penghasilan yang sudah dikerjakan dan yang masih tertunda. Saldo dompet baru bertambah saat tagihan dicatat diterima.'
	String get homeFreelanceBody => 'Penghasilan yang sudah dikerjakan dan yang masih tertunda. Saldo dompet baru bertambah saat tagihan dicatat diterima.';

	/// id: 'Transaksi terbaru'
	String get homeRecentTitle => 'Transaksi terbaru';

	/// id: 'Catatan terakhirmu. Ketuk salah satunya untuk rincian, atau Lihat semua untuk riwayat per bulan.'
	String get homeRecentBody => 'Catatan terakhirmu. Ketuk salah satunya untuk rincian, atau Lihat semua untuk riwayat per bulan.';

	/// id: 'Pilih jenisnya'
	String get recordKindTitle => 'Pilih jenisnya';

	/// id: 'Pengeluaran mengurangi saldo, pemasukan menambah, dan transfer hanya memindahkan antardompet — totalmu tetap.'
	String get recordKindBody => 'Pengeluaran mengurangi saldo, pemasukan menambah, dan transfer hanya memindahkan antardompet — totalmu tetap.';

	/// id: 'Honor freelance lewat jalur sendiri'
	String get recordFreelanceTitle => 'Honor freelance lewat jalur sendiri';

	/// id: 'Honor proyek dicatat sebagai tagihan diterima di Freelance, jadi jam kerja dan tagihannya ikut lunas.'
	String get recordFreelanceBody => 'Honor proyek dicatat sebagai tagihan diterima di Freelance, jadi jam kerja dan tagihannya ikut lunas.';

	/// id: 'Nominal'
	String get recordAmountTitle => 'Nominal';

	/// id: 'Ketik nominalnya dengan papan angka.'
	String get recordAmountBody => 'Ketik nominalnya dengan papan angka.';

	/// id: 'Dompet terisi otomatis'
	String get recordWalletTitle => 'Dompet terisi otomatis';

	/// id: 'Dompet terakhir yang kamu pakai sudah terpilih. Ganti kalau perlu.'
	String get recordWalletBody => 'Dompet terakhir yang kamu pakai sudah terpilih. Ganti kalau perlu.';

	/// id: 'Tautkan ke anggaran'
	String get recordBudgetItemTitle => 'Tautkan ke anggaran';

	/// id: 'Opsional. Pengeluaran yang ditautkan menambah angka terpakai pos itu, selama tanggalnya di dalam periode anggaran.'
	String get recordBudgetItemBody => 'Opsional. Pengeluaran yang ditautkan menambah angka terpakai pos itu, selama tanggalnya di dalam periode anggaran.';

	/// id: 'Total semua dompet'
	String get walletSummaryTitle => 'Total semua dompet';

	/// id: 'Jumlah saldo tercatat dompet aktif.'
	String get walletSummaryBody => 'Jumlah saldo tercatat dompet aktif.';

	/// id: 'Rincian dompet'
	String get walletCardTitle => 'Rincian dompet';

	/// id: 'Ketuk untuk melihat riwayat dompet ini dan mencatat langsung dari sana.'
	String get walletCardBody => 'Ketuk untuk melihat riwayat dompet ini dan mencatat langsung dari sana.';

	/// id: 'Tambah dompet'
	String get walletAddTitle => 'Tambah dompet';

	/// id: 'Rekening, e-wallet, atau tunai. Saldo awalnya bisa diubah kapan saja, dan saldo tercatat ikut menyesuaikan.'
	String get walletAddBody => 'Rekening, e-wallet, atau tunai. Saldo awalnya bisa diubah kapan saja, dan saldo tercatat ikut menyesuaikan.';

	/// id: 'Satu bulan per tampilan'
	String get txnMonthTitle => 'Satu bulan per tampilan';

	/// id: 'Geser bulan untuk melihat riwayat lain. Pemasukan dan pengeluaran di sini hanya untuk bulan yang tampil.'
	String get txnMonthBody => 'Geser bulan untuk melihat riwayat lain. Pemasukan dan pengeluaran di sini hanya untuk bulan yang tampil.';

	/// id: 'Cari dan saring'
	String get txnFilterTitle => 'Cari dan saring';

	/// id: 'Cari catatan atau kategori, lalu saring per dompet dan kategori lewat Filter. Kalau bulan ini kosong, pencarian bisa dilanjutkan ke bulan lain.'
	String get txnFilterBody => 'Cari catatan atau kategori, lalu saring per dompet dan kategori lewat Filter. Kalau bulan ini kosong, pencarian bisa dilanjutkan ke bulan lain.';

	/// id: 'Ubah atau hapus'
	String get txnRowTitle => 'Ubah atau hapus';

	/// id: 'Ketuk transaksi untuk rinciannya; dari sana bisa diubah, dicatat lagi, atau dihapus, dan saldo dihitung ulang.'
	String get txnRowBody => 'Ketuk transaksi untuk rinciannya; dari sana bisa diubah, dicatat lagi, atau dihapus, dan saldo dihitung ulang.';

	/// id: 'Sisa semua anggaran aktif'
	String get budgetSummaryTitle => 'Sisa semua anggaran aktif';

	/// id: 'Rencana dikurangi terpakai — sisa ruang belanjamu di semua anggaran aktif.'
	String get budgetSummaryBody => 'Rencana dikurangi terpakai — sisa ruang belanjamu di semua anggaran aktif.';

	/// id: 'Aktif lebih dulu'
	String get budgetFilterTitle => 'Aktif lebih dulu';

	/// id: 'Daftar menampilkan anggaran aktif. Pilih Selesai atau Nonaktif untuk melihat yang lama.'
	String get budgetFilterBody => 'Daftar menampilkan anggaran aktif. Pilih Selesai atau Nonaktif untuk melihat yang lama.';

	/// id: 'Pakai template'
	String get budgetTemplatesTitle => 'Pakai template';

	/// id: 'Simpan susunan pos yang berulang, lalu buat anggaran baru darinya.'
	String get budgetTemplatesBody => 'Simpan susunan pos yang berulang, lalu buat anggaran baru darinya.';

	/// id: 'Pos anggaran'
	String get budgetDetailItemTitle => 'Pos anggaran';

	/// id: 'Terpakai naik dari transaksi yang ditautkan ke pos ini dalam periode anggaran.'
	String get budgetDetailItemBody => 'Terpakai naik dari transaksi yang ditautkan ke pos ini dalam periode anggaran.';

	/// id: 'Catat dari pos'
	String get budgetDetailRecordTitle => 'Catat dari pos';

	/// id: 'Membuka Catat dengan pos ini sudah terpilih.'
	String get budgetDetailRecordBody => 'Membuka Catat dengan pos ini sudah terpilih.';

	/// id: 'Proyek dan tarif'
	String get freelanceProjectTitle => 'Proyek dan tarif';

	/// id: 'Setiap proyek punya tarif per jam dan potongan. Ketuk proyek untuk mencatat jam kerja dan tagihannya.'
	String get freelanceProjectBody => 'Setiap proyek punya tarif per jam dan potongan. Ketuk proyek untuk mencatat jam kerja dan tagihannya.';

	/// id: 'Jam kerja'
	String get freelanceWorklogTitle => 'Jam kerja';

	/// id: 'Jam kerja adalah penghasilan yang sudah kamu peroleh. Kumpulkan jadi tagihan, lalu catat saat dibayar.'
	String get freelanceWorklogBody => 'Jam kerja adalah penghasilan yang sudah kamu peroleh. Kumpulkan jadi tagihan, lalu catat saat dibayar.';

	/// id: 'Uang benar-benar masuk'
	String get freelanceReceiveTitle => 'Uang benar-benar masuk';

	/// id: 'Catat saat honornya masuk: saldo dompet bertambah dan tagihannya lunas.'
	String get freelanceReceiveBody => 'Catat saat honornya masuk: saldo dompet bertambah dan tagihannya lunas.';

	/// id: 'Catat pakai suara'
	String get homeVoiceTitle => 'Catat pakai suara';

	/// id: 'Tekan lama tombol Catat, ucapkan satu transaksi, lalu periksa formulirnya sebelum dicatat.'
	String get homeVoiceBody => 'Tekan lama tombol Catat, ucapkan satu transaksi, lalu periksa formulirnya sebelum dicatat.';

	/// id: 'Rencana'
	String get planTabsTitle => 'Rencana';

	/// id: 'Bulan ini, anggaran, dan transaksi rutin ada di sini. Ketuk untuk berpindah.'
	String get planTabsBody => 'Bulan ini, anggaran, dan transaksi rutin ada di sini. Ketuk untuk berpindah.';

	/// id: 'Uang nganggur'
	String get planUnplannedTitle => 'Uang nganggur';

	/// id: 'Pemasukan bulan ini dikurangi semua yang sudah terikat.'
	String get planUnplannedBody => 'Pemasukan bulan ini dikurangi semua yang sudah terikat.';

	/// id: 'Saldo dompet ≈'
	String get planForecastTitle => 'Saldo dompet ≈';

	/// id: 'Perkiraan saldo sampai akhir bulan, termasuk titik paling tipisnya.'
	String get planForecastBody => 'Perkiraan saldo sampai akhir bulan, termasuk titik paling tipisnya.';

	/// id: 'Perkiraan saldo'
	String get homeForecastTitle => 'Perkiraan saldo';

	/// id: 'Saldo dompet perkiraan di akhir bulan dan titik paling tipisnya. Ketuk untuk rinciannya di Rencana.'
	String get homeForecastBody => 'Saldo dompet perkiraan di akhir bulan dan titik paling tipisnya. Ketuk untuk rinciannya di Rencana.';

	/// id: 'Menunggu dicatat'
	String get homePendingTitle => 'Menunggu dicatat';

	/// id: 'Tagihan dan pemasukan rutin yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati.'
	String get homePendingBody => 'Tagihan dan pemasukan rutin yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati.';

	/// id: 'Ulangi'
	String get recordRepeatTitle => 'Ulangi';

	/// id: 'Untuk tagihan, gaji, atau langganan. Kemunculan berikutnya akan menunggu kamu catat; tidak pernah dicatat diam-diam.'
	String get recordRepeatBody => 'Untuk tagihan, gaji, atau langganan. Kemunculan berikutnya akan menunggu kamu catat; tidak pernah dicatat diam-diam.';

	/// id: 'Mulai cepat'
	String get recurringStartersTitle => 'Mulai cepat';

	/// id: 'Pilih yang paling sering, mis. gaji atau listrik. Formulirnya terisi, tinggal sesuaikan.'
	String get recurringStartersBody => 'Pilih yang paling sering, mis. gaji atau listrik. Formulirnya terisi, tinggal sesuaikan.';

	/// id: 'Sisa rutin keluar'
	String get recurringSummaryTitle => 'Sisa rutin keluar';

	/// id: 'Tagihan rutin yang belum tercatat bulan ini — uang yang sudah ada tujuannya.'
	String get recurringSummaryBody => 'Tagihan rutin yang belum tercatat bulan ini — uang yang sudah ada tujuannya.';

	/// id: 'Menunggu dicatat'
	String get recurringPendingTitle => 'Menunggu dicatat';

	/// id: 'Kemunculan yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati yang ini.'
	String get recurringPendingBody => 'Kemunculan yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati yang ini.';

	/// id: 'Tambah rutin'
	String get recurringAddTitle => 'Tambah rutin';

	/// id: 'Bisa juga dari Catat lewat Ulangi, atau Jadikan rutin di rincian transaksi.'
	String get recurringAddBody => 'Bisa juga dari Catat lewat Ulangi, atau Jadikan rutin di rincian transaksi.';

	/// id: 'Ulangi tiap periode'
	String get budgetRepeatTitle => 'Ulangi tiap periode';

	/// id: 'Nyalakan supaya anggaran ini lahir lagi tiap bulan dengan pos yang sama. Tidak ada uang yang dipindahkan.'
	String get budgetRepeatBody => 'Nyalakan supaya anggaran ini lahir lagi tiap bulan dengan pos yang sama. Tidak ada uang yang dipindahkan.';

	/// id: 'Bulan depan'
	String get planMonthPickerTitle => 'Bulan depan';

	/// id: 'Lihat perkiraan dua bulan ke depan. Angka di tiap bulan adalah perkiraan akhir bulannya.'
	String get planMonthPickerBody => 'Lihat perkiraan dua bulan ke depan. Angka di tiap bulan adalah perkiraan akhir bulannya.';
}

// Path: info
class Translations$info$id {
	Translations$info$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Info dan tur'
	String get menuTooltip => 'Info dan tur';

	/// id: 'Tur layar ini'
	String get replayTourAction => 'Tur layar ini';

	/// id: 'Pengenalan Tanukonomy'
	String get showIntroAction => 'Pengenalan Tanukonomy';

	/// id: 'Setel ulang semua tutorial'
	String get resetAllAction => 'Setel ulang semua tutorial';

	/// id: 'Setel ulang tutorial?'
	String get resetConfirmTitle => 'Setel ulang tutorial?';

	/// id: 'Pengenalan dan semua tur akan tampil lagi seperti pertama kali. Data keuanganmu tidak tersentuh.'
	String get resetConfirmMessage => 'Pengenalan dan semua tur akan tampil lagi seperti pertama kali. Data keuanganmu tidak tersentuh.';

	/// id: 'Setel ulang'
	String get resetConfirmAction => 'Setel ulang';

	/// id: 'Tutorial disetel ulang.'
	String get resetDoneMessage => 'Tutorial disetel ulang.';
}

// Path: account
class Translations$account$id {
	Translations$account$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Akun'
	String get title => 'Akun';

	/// id: 'Siapkan akunmu'
	String get signedOutTitle => 'Siapkan akunmu';

	/// id: 'Semua pencatatan berjalan penuh tanpa akun. Akun menyiapkan cadangan dan sinkronisasi antarperangkat yang sedang kami bangun.'
	String get signedOutBody => 'Semua pencatatan berjalan penuh tanpa akun. Akun menyiapkan cadangan dan sinkronisasi antarperangkat yang sedang kami bangun.';

	/// id: 'Masuk dengan Google'
	String get googleSignInAction => 'Masuk dengan Google';

	/// id: 'Masuk dengan email'
	String get emailSignInToggle => 'Masuk dengan email';

	/// id: 'Untuk akun yang sudah dibuatkan khusus untukmu.'
	String get emailFormHint => 'Untuk akun yang sudah dibuatkan khusus untukmu.';

	/// id: 'Email'
	String get emailLabel => 'Email';

	/// id: 'Kata sandi'
	String get passwordLabel => 'Kata sandi';

	/// id: 'Masuk'
	String get emailSignInAction => 'Masuk';

	/// id: 'Isi email dan kata sandi dulu.'
	String get emailRequired => 'Isi email dan kata sandi dulu.';

	/// id: 'Kamu sudah masuk.'
	String get signedInMessage => 'Kamu sudah masuk.';

	/// id: 'Kamu sudah keluar.'
	String get signedOutMessage => 'Kamu sudah keluar.';

	/// id: 'Masuk lewat Google'
	String get methodGoogle => 'Masuk lewat Google';

	/// id: 'Masuk lewat email'
	String get methodPassword => 'Masuk lewat email';

	/// id: 'Data kamu'
	String get dataTitle => 'Data kamu';

	/// id: 'Dompet, transaksi, dan anggaran tersimpan di perangkat ini. Keluar atau menghapus akun tidak menyentuhnya.'
	String get dataBody => 'Dompet, transaksi, dan anggaran tersimpan di perangkat ini. Keluar atau menghapus akun tidak menyentuhnya.';

	/// id: 'Keluar'
	String get signOutAction => 'Keluar';

	/// id: 'Zona bahaya'
	String get dangerTitle => 'Zona bahaya';

	/// id: 'Menghapus akun bersifat permanen dan tidak bisa dibatalkan.'
	String get dangerBody => 'Menghapus akun bersifat permanen dan tidak bisa dibatalkan.';

	/// id: 'Hapus akun'
	String get deleteAction => 'Hapus akun';

	/// id: 'Hapus akun?'
	String get deleteConfirmTitle => 'Hapus akun?';

	/// id: 'Akunmu dihapus permanen. Dompet, transaksi, dan anggaran di perangkat ini tetap ada.'
	String get deleteConfirmBody => 'Akunmu dihapus permanen. Dompet, transaksi, dan anggaran di perangkat ini tetap ada.';

	/// id: 'Masukkan kata sandi'
	String get deletePasswordTitle => 'Masukkan kata sandi';

	/// id: 'Demi keamanan, masukkan lagi kata sandimu untuk menghapus akun.'
	String get deletePasswordBody => 'Demi keamanan, masukkan lagi kata sandimu untuk menghapus akun.';

	/// id: 'Akun dihapus.'
	String get deletedMessage => 'Akun dihapus.';

	late final Translations$account$errors$id errors = Translations$account$errors$id.internal(_root);

	/// id: 'Pencatatan'
	String get recordingSection => 'Pencatatan';

	/// id: 'Tampilan'
	String get displaySection => 'Tampilan';

	/// id: 'Ganti angka dengan titik di semua layar, mis. saat membuka aplikasi di depan orang lain.'
	String get hideAmountsBody => 'Ganti angka dengan titik di semua layar, mis. saat membuka aplikasi di depan orang lain.';
}

// Path: currency
class Translations$currency$id {
	Translations$currency$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Pengaturan'
	String get settingsTitle => 'Pengaturan';

	/// id: 'Mata uang'
	String get label => 'Mata uang';

	/// id: 'Pilih mata uang'
	String get pickerTitle => 'Pilih mata uang';

	/// id: 'Ganti ke $code?'
	String changeTitle({required Object code}) => 'Ganti ke ${code}?';

	/// id: 'Angka yang sudah dicatat tidak dikonversi, hanya simbolnya yang berganti. Contoh: $before akan tampil sebagai $after.'
	String changeBody({required Object before, required Object after}) => 'Angka yang sudah dicatat tidak dikonversi, hanya simbolnya yang berganti. Contoh: ${before} akan tampil sebagai ${after}.';

	/// id: 'Ganti'
	String get changeAction => 'Ganti';

	/// id: 'Mata uang diganti ke $code.'
	String changedMessage({required Object code}) => 'Mata uang diganti ke ${code}.';

	late final Translations$currency$names$id names = Translations$currency$names$id.internal(_root);
}

// Path: category
class Translations$category$id {
	Translations$category$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	Map<String, String> get builtIn => {
		'food': 'Makan & Minum',
		'groceries': 'Belanja Harian',
		'transport': 'Transportasi',
		'bills': 'Tagihan',
		'internet': 'Pulsa & Internet',
		'health': 'Kesehatan',
		'entertainment': 'Hiburan',
		'shopping': 'Belanja',
		'education': 'Pendidikan',
		'family': 'Keluarga',
		'donation': 'Donasi',
		'expenseOther': 'Lainnya',
		'salary': 'Gaji',
		'freelance': 'Freelance',
		'bonus': 'Bonus',
		'gift': 'Hadiah',
		'incomeOther': 'Lainnya',
	};

	/// id: 'Kategori'
	String get title => 'Kategori';

	/// id: 'Kategori'
	String get accountEntryTitle => 'Kategori';

	/// id: 'Atur daftar kategori pemasukan dan pengeluaran.'
	String get accountEntryBody => 'Atur daftar kategori pemasukan dan pengeluaran.';

	/// id: 'Pengeluaran'
	String get expenseTab => 'Pengeluaran';

	/// id: 'Pemasukan'
	String get incomeTab => 'Pemasukan';

	/// id: 'Tambah kategori'
	String get addAction => 'Tambah kategori';

	/// id: 'Kategori baru'
	String get addTitle => 'Kategori baru';

	/// id: 'Ubah kategori'
	String get renameTitle => 'Ubah kategori';

	/// id: 'Ikon'
	String get iconLabel => 'Ikon';

	/// id: 'Ikon $n'
	String iconOption({required Object n}) => 'Ikon ${n}';

	/// id: 'Nama kategori'
	String get nameHint => 'Nama kategori';

	/// id: 'Arsipkan'
	String get archiveAction => 'Arsipkan';

	/// id: 'Pulihkan'
	String get restoreAction => 'Pulihkan';

	/// id: 'Terarsip'
	String get archivedSection => 'Terarsip';

	/// id: 'Tidak ditawarkan di Catat, tetapi transaksi lama tetap memakainya.'
	String get archivedHint => 'Tidak ditawarkan di Catat, tetapi transaksi lama tetap memakainya.';

	/// id: 'Belum ada kategori aktif.'
	String get emptyActive => 'Belum ada kategori aktif.';

	/// id: 'Kategori "${name}" diarsipkan.'
	String archivedMessage({required Object name}) => 'Kategori "${name}" diarsipkan.';

	/// id: 'Kategori "${name}" dipulihkan.'
	String restoredMessage({required Object name}) => 'Kategori "${name}" dipulihkan.';
}

// Path: language
class Translations$language$id {
	Translations$language$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Bahasa'
	String get label => 'Bahasa';

	/// id: 'Pilih bahasa'
	String get pickerTitle => 'Pilih bahasa';

	/// id: 'Tampilan aplikasi dan bahasa ucapan'
	String get hint => 'Tampilan aplikasi dan bahasa ucapan';
}

// Path: notificationCapture
class Translations$notificationCapture$id {
	Translations$notificationCapture$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Catat dari notifikasi'
	String get accountEntryTitle => 'Catat dari notifikasi';

	/// id: 'Catat otomatis dari notifikasi bank dan e-wallet.'
	String get accountEntryBody => 'Catat otomatis dari notifikasi bank dan e-wallet.';

	/// id: 'Catat dari notifikasi'
	String get settingsTitle => 'Catat dari notifikasi';

	/// id: 'Aktifkan'
	String get enableLabel => 'Aktifkan';

	/// id: 'Butuh izin membaca notifikasi'
	String get accessMissingTitle => 'Butuh izin membaca notifikasi';

	/// id: 'Tanpa izin ini, Tanukonomy tidak bisa melihat notifikasi bank.'
	String get accessMissingBody => 'Tanpa izin ini, Tanukonomy tidak bisa melihat notifikasi bank.';

	/// id: 'Beri izin'
	String get accessAction => 'Beri izin';

	/// id: 'Izin notifikasi aktif'
	String get accessGranted => 'Izin notifikasi aktif';

	/// id: 'Sebelum memberi izin'
	String get disclosureTitle => 'Sebelum memberi izin';

	/// id: 'Tanukonomy akan bisa membaca notifikasi di HP-mu. • Hanya dari aplikasi yang kamu pilih dan cocok dengan filternya. • Notifikasi OTP tidak pernah disimpan. • Teks yang sulit dibaca bisa dikirim ke Gemini (Google). • Teks notifikasi disimpan di HP paling lama 7 hari.'
	String get disclosureBody => 'Tanukonomy akan bisa membaca notifikasi di HP-mu.\n\n• Hanya dari aplikasi yang kamu pilih dan cocok dengan filternya.\n• Notifikasi OTP tidak pernah disimpan.\n• Teks yang sulit dibaca bisa dikirim ke Gemini (Google).\n• Teks notifikasi disimpan di HP paling lama 7 hari.';

	/// id: 'Lanjut'
	String get disclosureAccept => 'Lanjut';

	/// id: 'Izin notifikasi ditolak. Nyalakan di setelan Android untuk menerima kabar.'
	String get reminderPermissionDenied => 'Izin notifikasi ditolak. Nyalakan di setelan Android untuk menerima kabar.';

	/// id: 'Aplikasi'
	String get sourcesTitle => 'Aplikasi';

	/// id: 'Pilih aplikasi bank atau e-wallet yang notifikasinya mau dicatat.'
	String get sourcesEmpty => 'Pilih aplikasi bank atau e-wallet yang notifikasinya mau dicatat.';

	/// id: 'Tambah aplikasi'
	String get addSource => 'Tambah aplikasi';

	/// id: 'Dompet belum dipilih'
	String get sourceNoWallet => 'Dompet belum dipilih';

	/// id: 'Dijeda'
	String get sourcePaused => 'Dijeda';

	/// id: 'Pilih aplikasi'
	String get pickAppTitle => 'Pilih aplikasi';

	/// id: 'Cari aplikasi'
	String get searchApps => 'Cari aplikasi';

	/// id: 'Pola bawaan'
	String get builtInPatternsBadge => 'Pola bawaan';

	/// id: 'Daftar aplikasi gagal dibaca.'
	String get appsLoadFailed => 'Daftar aplikasi gagal dibaca.';

	/// id: 'Tidak ada aplikasi yang cocok.'
	String get appsEmpty => 'Tidak ada aplikasi yang cocok.';

	/// id: 'Dengarkan aplikasi ini'
	String get sourceEnabled => 'Dengarkan aplikasi ini';

	/// id: 'Dompet'
	String get walletLabel => 'Dompet';

	/// id: 'Filter'
	String get keywordsLabel => 'Filter';

	/// id: 'Hanya notifikasi yang memuat salah satu frasa ini yang dibaca.'
	String get keywordsHint => 'Hanya notifikasi yang memuat salah satu frasa ini yang dibaca.';

	/// id: 'Tambah frasa'
	String get keywordField => 'Tambah frasa';

	/// id: 'Tambah'
	String get addKeyword => 'Tambah';

	/// id: 'Pola'
	String get patternsTitle => 'Pola';

	/// id: 'Ajari Tanukonomy membaca format notifikasi aplikasi ini.'
	String get patternsHint => 'Ajari Tanukonomy membaca format notifikasi aplikasi ini.';

	/// id: 'Belum ada pola. Tanukonomy tetap membaca dengan aturan umum.'
	String get patternsEmpty => 'Belum ada pola. Tanukonomy tetap membaca dengan aturan umum.';

	/// id: 'Bawaan · hasilnya selalu kamu cek'
	String get builtInUnverified => 'Bawaan · hasilnya selalu kamu cek';

	/// id: 'Bawaan'
	String get builtInVerified => 'Bawaan';

	/// id: 'Buat pola dari contoh'
	String get newPattern => 'Buat pola dari contoh';

	/// id: 'Hapus aplikasi ini'
	String get removeSource => 'Hapus aplikasi ini';

	/// id: 'Berhenti membaca notifikasi ${app}?'
	String removeSourceConfirm({required Object app}) => 'Berhenti membaca notifikasi ${app}?';

	/// id: 'Simpan'
	String get save => 'Simpan';

	/// id: 'Buat pola'
	String get patternTitle => 'Buat pola';

	/// id: 'Contoh notifikasi'
	String get patternSampleLabel => 'Contoh notifikasi';

	/// id: 'Tempel teks notifikasi di sini'
	String get patternSampleHint => 'Tempel teks notifikasi di sini';

	/// id: 'Pilih penanda, lalu ketuk katanya. Ketuk lagi untuk menghapus tanda.'
	String get patternInstructions => 'Pilih penanda, lalu ketuk katanya. Ketuk lagi untuk menghapus tanda.';

	/// id: 'Nominal'
	String get roleAmount => 'Nominal';

	/// id: 'Catatan'
	String get roleNote => 'Catatan';

	/// id: 'Abaikan'
	String get roleIgnore => 'Abaikan';

	/// id: 'Jenis'
	String get patternKindLabel => 'Jenis';

	/// id: 'Keluar'
	String get kindExpense => 'Keluar';

	/// id: 'Masuk'
	String get kindIncome => 'Masuk';

	/// id: 'Transfer keluar'
	String get kindTransferOut => 'Transfer keluar';

	/// id: 'Transfer masuk'
	String get kindTransferIn => 'Transfer masuk';

	/// id: 'Kategori'
	String get patternCategory => 'Kategori';

	/// id: 'Tanpa kategori'
	String get patternNoCategory => 'Tanpa kategori';

	/// id: 'Dompet lawan'
	String get patternTransferWallet => 'Dompet lawan';

	/// id: 'Nama pola (opsional)'
	String get patternLabelField => 'Nama pola (opsional)';

	/// id: 'Terbaca: ${amount}'
	String patternPreview({required Object amount}) => 'Terbaca: ${amount}';

	/// id: 'Tandai satu nominal. Kata Catatan harus berurutan.'
	String get patternInvalid => 'Tandai satu nominal. Kata Catatan harus berurutan.';

	/// id: 'Hapus pola'
	String get deletePattern => 'Hapus pola';

	/// id: 'Kotak masuk notifikasi'
	String get inboxTitle => 'Kotak masuk notifikasi';

	/// id: 'Perlu dicek'
	String get inboxPendingTitle => 'Perlu dicek';

	/// id: 'Otomatis'
	String get inboxAutoTitle => 'Otomatis';

	/// id: 'Tidak ada yang perlu dicek.'
	String get inboxEmpty => 'Tidak ada yang perlu dicek.';

	/// id: 'Belum ada yang tercatat otomatis.'
	String get inboxAutoEmpty => 'Belum ada yang tercatat otomatis.';

	/// id: 'Daftar ini disimpan 7 hari.'
	String get inboxRetention => 'Daftar ini disimpan 7 hari.';

	/// id: 'Nominal belum terbaca'
	String get amountUnknown => 'Nominal belum terbaca';

	/// id: 'Mungkin sudah tercatat'
	String get possibleDuplicate => 'Mungkin sudah tercatat';

	late final Translations$notificationCapture$reviewReason$id reviewReason = Translations$notificationCapture$reviewReason$id.internal(_root);

	/// id: 'Catat'
	String get recordAction => 'Catat';

	/// id: 'Abaikan'
	String get dismissAction => 'Abaikan';

	/// id: 'Buat pola dari teks ini'
	String get makePatternAction => 'Buat pola dari teks ini';

	/// id: 'Lihat'
	String get reviewAction => 'Lihat';

	/// id: 'Batalkan'
	String get undoAction => 'Batalkan';

	/// id: 'Batalkan transaksi?'
	String get undoConfirmTitle => 'Batalkan transaksi?';

	/// id: 'Transaksinya dihapus dan saldo dompet kembali seperti sebelumnya.'
	String get undoConfirm => 'Transaksinya dihapus dan saldo dompet kembali seperti sebelumnya.';

	/// id: 'Transaksi otomatis dibatalkan.'
	String get undone => 'Transaksi otomatis dibatalkan.';

	/// id: 'Notifikasi diabaikan.'
	String get dismissed => 'Notifikasi diabaikan.';

	/// id: '(other) {${n} transaksi dari notifikasi menunggu dicek}'
	String banner({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${n} transaksi dari notifikasi menunggu dicek',
	);

	/// id: 'Cek'
	String get bannerAction => 'Cek';

	/// id: 'Tercatat otomatis: ${amount} · ${app}'
	String autoRecordedSnack({required Object amount, required Object app}) => 'Tercatat otomatis: ${amount} · ${app}';

	/// id: '${n} transaksi tercatat otomatis dari notifikasi'
	String autoRecordedSnackMany({required Object n}) => '${n} transaksi tercatat otomatis dari notifikasi';

	/// id: 'Catat dari notifikasi'
	String get reminderChannel => 'Catat dari notifikasi';

	/// id: 'Transaksi dari {app} tertangkap'
	String get reminderCapturedTitle => 'Transaksi dari {app} tertangkap';

	/// id: 'Ketuk untuk melihat.'
	String get reminderCapturedBody => 'Ketuk untuk melihat.';

	/// id: 'Cek ${amount} dari ${app}'
	String reminderReviewTitle({required Object amount, required Object app}) => 'Cek ${amount} dari ${app}';

	/// id: 'Ketuk untuk mencatat.'
	String get reminderReviewBody => 'Ketuk untuk mencatat.';

	/// id: 'Tercatat ${amount} · ${app}'
	String reminderRecordedTitle({required Object amount, required Object app}) => 'Tercatat ${amount} · ${app}';

	/// id: 'Ketuk untuk melihat.'
	String get reminderRecordedBody => 'Ketuk untuk melihat.';

	/// id: 'Contoh teks tertangkap (debug)'
	String get debugSamplesTitle => 'Contoh teks tertangkap (debug)';

	/// id: 'Ketuk untuk menyalin. Samarkan sebelum dibagikan.'
	String get debugSamplesHint => 'Ketuk untuk menyalin. Samarkan sebelum dibagikan.';

	/// id: 'Belum ada notifikasi dari aplikasi terdaftar.'
	String get debugSamplesEmpty => 'Belum ada notifikasi dari aplikasi terdaftar.';

	/// id: 'Tambah sumber uji adb (com.android.shell)'
	String get debugShellSource => 'Tambah sumber uji adb (com.android.shell)';

	/// id: 'Disalin.'
	String get copied => 'Disalin.';

	/// id: 'Tanpa filter, tidak ada notifikasi yang dibaca.'
	String get keywordsEmptyWarning => 'Tanpa filter, tidak ada notifikasi yang dibaca.';

	/// id: 'Pakai filter bawaan'
	String get addDefaultKeywords => 'Pakai filter bawaan';

	/// id: 'Filter kosong — tidak ada yang dibaca'
	String get sourceKeywordsNone => 'Filter kosong — tidak ada yang dibaca';

	/// id: 'Transaksi dari notifikasi bank dan e-wallet yang kamu pilih dicatat untukmu.'
	String get enableHint => 'Transaksi dari notifikasi bank dan e-wallet yang kamu pilih dicatat untukmu.';

	/// id: 'Kotak masuk'
	String get inboxEntryTitle => 'Kotak masuk';

	/// id: 'Cek transaksi dari notifikasi dan batalkan yang tercatat otomatis.'
	String get inboxEntryBody => 'Cek transaksi dari notifikasi dan batalkan yang tercatat otomatis.';

	/// id: 'Saat transaksi tertangkap'
	String get behaviorTitle => 'Saat transaksi tertangkap';

	/// id: 'Catat otomatis'
	String get autoRecordLabel => 'Catat otomatis';

	/// id: 'Semua menunggu kamu cek di kotak masuk.'
	String get autoRecordOffHint => 'Semua menunggu kamu cek di kotak masuk.';

	/// id: 'Yang terbaca jelas langsung tersimpan. Yang ragu tetap menunggu dicek.'
	String get autoRecordOnHint => 'Yang terbaca jelas langsung tersimpan. Yang ragu tetap menunggu dicek.';

	/// id: 'Walau kategori belum terbaca'
	String get autoRecordAnyCategoryLabel => 'Walau kategori belum terbaca';

	/// id: 'Kategori bisa kamu isi belakangan.'
	String get autoRecordAnyCategoryHint => 'Kategori bisa kamu isi belakangan.';

	/// id: 'Kabari lewat notifikasi'
	String get reminderLabel => 'Kabari lewat notifikasi';

	/// id: 'Muncul notifikasi tiap ada transaksi tertangkap.'
	String get reminderHint => 'Muncul notifikasi tiap ada transaksi tertangkap.';

	/// id: 'Dompet ${name}'
	String sourceWallet({required Object name}) => 'Dompet ${name}';

	/// id: 'Transaksi dari aplikasi ini dicatat di dompet ini.'
	String get walletHelp => 'Transaksi dari aplikasi ini dicatat di dompet ini.';

	/// id: 'Filter dan pola'
	String get advancedTitle => 'Filter dan pola';

	/// id: 'Opsional'
	String get advancedHint => 'Opsional';

	/// id: 'Tandai bagiannya'
	String get patternMarkLabel => 'Tandai bagiannya';

	/// id: '"${word}" bukan nominal. Nominal memakai Rp atau titik ribuan.'
	String patternNotAmount({required Object word}) => '"${word}" bukan nominal. Nominal memakai Rp atau titik ribuan.';

	/// id: 'Transfer'
	String get kindTransfer => 'Transfer';

	/// id: 'Arah transfer'
	String get transferDirectionLabel => 'Arah transfer';

	/// id: 'Belum ditentukan'
	String get patternTransferWalletNone => 'Belum ditentukan';

	/// id: 'Sunting templat'
	String get patternTemplateToggle => 'Sunting templat';

	/// id: 'Lainnya'
	String get moreActions => 'Lainnya';
}

// Path: recurring
class Translations$recurring$id {
	Translations$recurring$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$recurring$starters$id starters = Translations$recurring$starters$id.internal(_root);

	/// id: 'Langganan $perMonth/bln · $perYear/thn'
	String subscriptionsLine({required Object perMonth, required Object perYear}) => 'Langganan ${perMonth}/bln · ${perYear}/thn';

	/// id: 'kira-kira $amount'
	String approxSemantics({required Object amount}) => 'kira-kira ${amount}';

	/// id: 'Semua ($n)'
	String filterAll({required Object n}) => 'Semua (${n})';

	/// id: 'Menunggu dicatat'
	String get groupPending => 'Menunggu dicatat';

	/// id: 'Bulan ini'
	String get groupThisMonth => 'Bulan ini';

	/// id: 'Nanti'
	String get groupLater => 'Nanti';

	/// id: 'Dijeda'
	String get groupPaused => 'Dijeda';

	/// id: 'Selesai'
	String get groupEnded => 'Selesai';

	/// id: '$n terlewat'
	String missedMeta({required Object n}) => '${n} terlewat';

	/// id: 'autodebet'
	String get paymentAutoDebit => 'autodebet';

	/// id: 'bayar sendiri'
	String get paymentManual => 'bayar sendiri';

	/// id: '$amount, biasanya $usual'
	String priceUp({required Object amount, required Object usual}) => '${amount}, biasanya ${usual}';

	/// id: 'Belum ada rutin'
	String get emptyTitle => 'Belum ada rutin';

	/// id: 'Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas.'
	String get emptyBody => 'Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas.';

	/// id: 'Belum ada rutin di sini.'
	String get filteredEmpty => 'Belum ada rutin di sini.';

	/// id: 'Tampilkan semua'
	String get showAllAction => 'Tampilkan semua';

	/// id: 'Tambah rutin'
	String get addAction => 'Tambah rutin';

	/// id: 'Rutin gagal dimuat.'
	String get loadError => 'Rutin gagal dimuat.';

	/// id: 'Coba lagi'
	String get retryAction => 'Coba lagi';

	/// id: 'Berikutnya'
	String get nextTitle => 'Berikutnya';

	/// id: 'Tercatat'
	String get recordedTitle => 'Tercatat';

	/// id: 'Lewati'
	String get skipAction => 'Lewati';

	/// id: 'Batal lewati'
	String get unskipAction => 'Batal lewati';

	/// id: 'Ubah'
	String get editAction => 'Ubah';

	/// id: 'Jeda'
	String get pauseAction => 'Jeda';

	/// id: 'Lanjutkan'
	String get resumeAction => 'Lanjutkan';

	/// id: 'Akhiri'
	String get endAction => 'Akhiri';

	/// id: 'Hapus'
	String get deleteAction => 'Hapus';

	/// id: 'Aksi lain'
	String get moreActions => 'Aksi lain';

	/// id: 'Hapus rutin?'
	String get deleteTitle => 'Hapus rutin?';

	/// id: 'Transaksi yang sudah tercatat tidak ikut terhapus.'
	String get deleteBody => 'Transaksi yang sudah tercatat tidak ikut terhapus.';

	/// id: 'Jadwal'
	String get detailSchedule => 'Jadwal';

	/// id: 'Dompet'
	String get detailWallet => 'Dompet';

	/// id: 'Berakhir'
	String get detailEnds => 'Berakhir';

	/// id: 'Cara bayar'
	String get detailPayment => 'Cara bayar';

	/// id: 'Status'
	String get detailStatus => 'Status';

	/// id: 'Pengaturan'
	String get settingsTitle => 'Pengaturan';

	/// id: '$k dari $n tercatat'
	String progressLine({required Object k, required Object n}) => '${k} dari ${n} tercatat';

	/// id: '$n kali'
	String countLine({required Object n}) => '${n} kali';

	/// id: 'Dijeda'
	String get pausedLine => 'Dijeda';

	/// id: '(other) {Bayar sendiri · diingatkan H−$n}'
	String reminderLine({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: 'Bayar sendiri · diingatkan H−${n}',
	);

	/// id: 'Autodebet'
	String get autoDebitLine => 'Autodebet';

	/// id: '$name dijeda.'
	String pausedMessage({required Object name}) => '${name} dijeda.';

	/// id: '$name dilanjutkan.'
	String resumedMessage({required Object name}) => '${name} dilanjutkan.';

	/// id: '$name diakhiri.'
	String endedMessage({required Object name}) => '${name} diakhiri.';

	/// id: '$name dihapus.'
	String deletedMessage({required Object name}) => '${name} dihapus.';

	/// id: '$date dilewati.'
	String skippedMessage({required Object date}) => '${date} dilewati.';

	/// id: 'Perbarui ke $amount'
	String priceUpdateAction({required Object amount}) => 'Perbarui ke ${amount}';

	/// id: 'Rutin ini sudah tidak ada.'
	String get notFound => 'Rutin ini sudah tidak ada.';

	/// id: 'Belum ada yang tercatat.'
	String get noRecorded => 'Belum ada yang tercatat.';

	/// id: '$name tercatat.'
	String recordedMessage({required Object name}) => '${name} tercatat.';

	/// id: '$n rutin tercatat.'
	String recordedAllMessage({required Object n}) => '${n} rutin tercatat.';

	/// id: '$name ditautkan.'
	String linkedMessage({required Object name}) => '${name} ditautkan.';

	/// id: 'Batalkan'
	String get undoAction => 'Batalkan';

	/// id: 'Sudah tercatat?'
	String get similarTitle => 'Sudah tercatat?';

	/// id: 'Mirip $name $amount · $date yang sudah tercatat.'
	String similarBody({required Object name, required Object amount, required Object date}) => 'Mirip ${name} ${amount} · ${date} yang sudah tercatat.';

	/// id: 'Tautkan'
	String get linkAction => 'Tautkan';

	/// id: 'Catat baru'
	String get recordNewAction => 'Catat baru';

	/// id: 'Catat'
	String get recordAction => 'Catat';

	/// id: 'Ubah dulu'
	String get editFirstAction => 'Ubah dulu';

	/// id: 'Catat semua'
	String get recordAllAction => 'Catat semua';

	/// id: 'Lihat semua'
	String get seeAllAction => 'Lihat semua';

	/// id: 'Menunggu dicatat'
	String get pendingCardTitle => 'Menunggu dicatat';

	/// id: 'Biasanya $usual. Periksa lagi nominalnya.'
	String unusualAmountNotice({required Object usual}) => 'Biasanya ${usual}. Periksa lagi nominalnya.';

	/// id: 'Jadwalnya $date. Pastikan tanggalnya benar.'
	String farDateNotice({required Object date}) => 'Jadwalnya ${date}. Pastikan tanggalnya benar.';

	/// id: 'Mencatat $name · $date'
	String occurrenceNotice({required Object name, required Object date}) => 'Mencatat ${name} · ${date}';

	/// id: 'Cocok dengan rutin $name · $date'
	String matchLabel({required Object name, required Object date}) => 'Cocok dengan rutin ${name} · ${date}';

	/// id: 'Tercocok dengan rutin'
	String get linkedTitle => 'Tercocok dengan rutin';

	/// id: 'Lepaskan'
	String get unlinkAction => 'Lepaskan';

	/// id: 'Tautan dilepas. Kemunculannya kembali menunggu.'
	String get unlinkedMessage => 'Tautan dilepas. Kemunculannya kembali menunggu.';

	/// id: 'Pengingat rutin'
	String get reminderChannelName => 'Pengingat rutin';

	/// id: 'Tagihan dan pemasukan rutin yang jatuh tempo.'
	String get reminderChannelDescription => 'Tagihan dan pemasukan rutin yang jatuh tempo.';

	/// id: '(other) {$n hari lagi}'
	String reminderSoonTitle({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n,
		other: '${n} hari lagi',
	);

	/// id: 'Jatuh tempo hari ini'
	String get reminderTodayTitle => 'Jatuh tempo hari ini';

	/// id: '$n rutin jatuh tempo hari ini'
	String reminderTodayManyTitle({required Object n}) => '${n} rutin jatuh tempo hari ini';

	/// id: '$name sudah tercatat.'
	String alreadyRecordedMessage({required Object name}) => '${name} sudah tercatat.';

	/// id: 'Pengingat rutin'
	String get remindersTitle => 'Pengingat rutin';

	/// id: 'Diingatkan sehari sebelum tagihan yang dibayar sendiri, dan pada hari jatuh tempo.'
	String get remindersBody => 'Diingatkan sehari sebelum tagihan yang dibayar sendiri, dan pada hari jatuh tempo.';

	/// id: 'Izin notifikasi belum diberikan. Nyalakan di setelan sistem.'
	String get remindersDenied => 'Izin notifikasi belum diberikan. Nyalakan di setelan sistem.';

	/// id: 'Ingatkan'
	String get ruleRemindersLabel => 'Ingatkan';

	/// id: '$k dari $n'
	String positionMeta({required Object k, required Object n}) => '${k} dari ${n}';

	/// id: 'ke $wallet'
	String toWalletMeta({required Object wallet}) => 'ke ${wallet}';

	/// id: 'Sisa rutin keluar · $month'
	String remainingTitle({required Object month}) => 'Sisa rutin keluar · ${month}';

	/// id: 'Rencana'
	String get plannedLabel => 'Rencana';

	/// id: 'Sudah keluar'
	String get outLabel => 'Sudah keluar';

	/// id: 'Semua'
	String get chipAll => 'Semua';

	/// id: 'Masuk'
	String get chipIncome => 'Masuk';

	/// id: 'Keluar'
	String get chipExpense => 'Keluar';

	/// id: 'Transfer'
	String get chipTransfer => 'Transfer';

	/// id: 'Pos anggaran'
	String get budgetLinkLabel => 'Pos anggaran';

	/// id: 'Belum tertaut. Tautkan supaya tidak terhitung dua kali dengan anggaran.'
	String get budgetLinkNone => 'Belum tertaut. Tautkan supaya tidak terhitung dua kali dengan anggaran.';

	/// id: '$item · $budget'
	String budgetLinkValue({required Object item, required Object budget}) => '${item} · ${budget}';

	/// id: 'Tautkan ke pos anggaran rutin'
	String get budgetLinkPickerTitle => 'Tautkan ke pos anggaran rutin';

	/// id: 'Lepas tautan'
	String get budgetLinkRemove => 'Lepas tautan';

	/// id: 'Belum ada pos anggaran rutin di dompet ini.'
	String get budgetLinkEmpty => 'Belum ada pos anggaran rutin di dompet ini.';

	/// id: '$name tertaut ke pos $item.'
	String budgetLinkedMessage({required Object name, required Object item}) => '${name} tertaut ke pos ${item}.';

	/// id: 'Tautan pos $name dilepas.'
	String budgetUnlinkedMessage({required Object name}) => 'Tautan pos ${name} dilepas.';

	/// id: 'Siapkan dana di $wallet'
	String fundingTitle({required Object wallet}) => 'Siapkan dana di ${wallet}';

	/// id: '$name $amount, $date. Perkiraan kurang ≈$shortfall.'
	String fundingBody({required Object name, required Object amount, required Object date, required Object shortfall}) => '${name} ${amount}, ${date}. Perkiraan kurang ≈${shortfall}.';

	/// id: 'Mulai $month ruang bebas +$amount/bln.'
	String installmentFreeLine({required Object month, required Object amount}) => 'Mulai ${month} ruang bebas +${amount}/bln.';

	/// id: 'Belum terlihat di notifikasi'
	String get unseenLabel => 'Belum terlihat di notifikasi';

	/// id: 'Belum terjadi'
	String get notYetAction => 'Belum terjadi';

	/// id: '$name ditanyakan lagi 2 hari lagi.'
	String snoozedMessage({required Object name}) => '${name} ditanyakan lagi 2 hari lagi.';

	/// id: 'Masih memakai $name?'
	String idleTitle({required Object name}) => 'Masih memakai ${name}?';

	/// id: 'Dua kemunculan terakhir dilewati atau belum terlihat.'
	String get idleBody => 'Dua kemunculan terakhir dilewati atau belum terlihat.';

	/// id: 'Biarkan'
	String get idleKeep => 'Biarkan';

	/// id: '$name dicatat otomatis.'
	String autoRecordedOne({required Object name}) => '${name} dicatat otomatis.';

	/// id: '$n rutin dicatat otomatis.'
	String autoRecordedMany({required Object n}) => '${n} rutin dicatat otomatis.';

	/// id: '$name tercatat $amount, naik dari rutin. Tautkan?'
	String priceUpFound({required Object name, required Object amount}) => '${name} tercatat ${amount}, naik dari rutin. Tautkan?';

	/// id: 'Perbarui rutin'
	String get priceUpUpdate => 'Perbarui rutin';

	/// id: 'Biarkan'
	String get priceUpKeep => 'Biarkan';

	/// id: 'Sepertinya rutin'
	String get suggestTitle => 'Sepertinya rutin';

	/// id: '$name $amount, sekitar tanggal $day tiga bulan terakhir.'
	String suggestLine({required Object name, required Object amount, required Object day}) => '${name} ${amount}, sekitar tanggal ${day} tiga bulan terakhir.';

	/// id: 'Jadikan rutin'
	String get suggestAccept => 'Jadikan rutin';

	/// id: 'Bukan rutin'
	String get suggestDismiss => 'Bukan rutin';

	/// id: 'Tercatat otomatis'
	String get autoRecordedTitle => 'Tercatat otomatis';
}

// Path: plan
class Translations$plan$id {
	Translations$plan$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Rutin'
	String get recurringSegmentLabel => 'Rutin';

	/// id: 'Awal bulan keuangan'
	String get financialMonthTitle => 'Awal bulan keuangan';

	/// id: 'Tanggal $day'
	String financialMonthDay({required Object day}) => 'Tanggal ${day}';

	/// id: 'Hari terakhir bulan'
	String get financialMonthLastDay => 'Hari terakhir bulan';

	/// id: 'Ubah awal bulan keuangan'
	String get financialMonthChange => 'Ubah awal bulan keuangan';

	/// id: 'Biasanya tanggal gajian.'
	String get financialMonthHint => 'Biasanya tanggal gajian.';

	/// id: 'Mulai tanggal $day'
	String financialMonthPreviewTitle({required Object day}) => 'Mulai tanggal ${day}';

	/// id: 'Mulai hari terakhir bulan'
	String get financialMonthPreviewTitleLastDay => 'Mulai hari terakhir bulan';

	/// id: 'Periode ini jadi $range ($days hari), lalu $next.'
	String financialMonthPreviewTransition({required Object range, required Object days, required Object next}) => 'Periode ini jadi ${range} (${days} hari), lalu ${next}.';

	/// id: 'Periode sebelumnya tidak berubah.'
	String get financialMonthPreviewPast => 'Periode sebelumnya tidak berubah.';

	/// id: 'Anggaran rutin'
	String get financialMonthBudgetsTitle => 'Anggaran rutin';

	/// id: 'Yang dicentang ikut mulai $next. Yang tidak, tetap mulai $previous.'
	String financialMonthBudgetsHelp({required Object next, required Object previous}) => 'Yang dicentang ikut mulai ${next}. Yang tidak, tetap mulai ${previous}.';

	/// id: 'tanggal $day'
	String financialMonthOnDay({required Object day}) => 'tanggal ${day}';

	/// id: 'hari terakhir bulan'
	String get financialMonthOnLastDay => 'hari terakhir bulan';

	/// id: 'Berjalan sampai $until, berikutnya mulai $next'
	String financialMonthBudgetMoved({required Object until, required Object next}) => 'Berjalan sampai ${until}, berikutnya mulai ${next}';

	/// id: 'Tetap mulai $start'
	String financialMonthBudgetKept({required Object start}) => 'Tetap mulai ${start}';

	/// id: 'Pilih semua'
	String get financialMonthSelectAll => 'Pilih semua';

	/// id: 'Kosongkan'
	String get financialMonthClearAll => 'Kosongkan';

	/// id: 'Periode peralihan · $days hari'
	String transitionLabel({required Object days}) => 'Periode peralihan · ${days} hari';

	/// id: 'Bulan ini'
	String get thisMonthSegmentLabel => 'Bulan ini';

	/// id: 'Uang nganggur · $month'
	String unplannedTitle({required Object month}) => 'Uang nganggur · ${month}';

	/// id: 'Pemasukan'
	String get incomeRow => 'Pemasukan';

	/// id: 'Tagihan rutin'
	String get billsRow => 'Tagihan rutin';

	/// id: 'Anggaran'
	String get budgetRow => 'Anggaran';

	/// id: 'Di luar rencana'
	String get offPlanRow => 'Di luar rencana';

	/// id: 'Penjelasan'
	String get infoAction => 'Penjelasan';

	/// id: 'Uang nganggur'
	String get infoTitle => 'Uang nganggur';

	/// id: '+ Pemasukan terencana'
	String get infoIncome => '+ Pemasukan terencana';

	/// id: '− Tagihan rutin'
	String get infoBills => '− Tagihan rutin';

	/// id: '− Anggaran'
	String get infoBudget => '− Anggaran';

	/// id: '± Di luar rencana (sudah tercatat)'
	String get infoOffPlan => '± Di luar rencana (sudah tercatat)';

	/// id: '= Uang nganggur'
	String get infoResult => '= Uang nganggur';

	/// id: 'Bukan saldo dompet.'
	String get infoNotBalance => 'Bukan saldo dompet.';

	/// id: 'Saldo dompet ≈'
	String get balanceTitle => 'Saldo dompet ≈';

	/// id: 'Semua'
	String get allWallets => 'Semua';

	/// id: 'Akhir $date'
	String endOf({required Object date}) => 'Akhir ${date}';

	/// id: 'Paling tipis · $date'
	String lowestOn({required Object date}) => 'Paling tipis · ${date}';

	/// id: 'Rincian'
	String get detailsAction => 'Rincian';

	/// id: 'hari ini'
	String get todayLabel => 'hari ini';

	/// id: 'kira-kira $amount'
	String approx({required Object amount}) => 'kira-kira ${amount}';

	/// id: 'Perkiraan saldo'
	String get detailsTitle => 'Perkiraan saldo';

	/// id: 'Saldo sekarang'
	String get detailsNow => 'Saldo sekarang';

	/// id: 'Pemasukan rutin'
	String get detailsIncome => 'Pemasukan rutin';

	/// id: 'Tagihan rutin'
	String get detailsBills => 'Tagihan rutin';

	/// id: 'Sisa anggaran'
	String get detailsBudget => 'Sisa anggaran';

	/// id: 'Di luar rencana · $perDay/hari'
	String detailsUnplanned({required Object perDay}) => 'Di luar rencana · ${perDay}/hari';

	/// id: 'Freelance belum dibayar (belum pasti)'
	String get detailsUncertain => 'Freelance belum dibayar (belum pasti)';

	/// id: 'Transfer rutin'
	String get detailsTransfers => 'Transfer rutin';

	/// id: 'Akhir $date'
	String detailsEnd({required Object date}) => 'Akhir ${date}';

	/// id: 'Hitung jajan harian'
	String get unplannedToggle => 'Hitung jajan harian';

	/// id: 'Butuh riwayat sebulan penuh.'
	String get unplannedUnavailable => 'Butuh riwayat sebulan penuh.';

	/// id: 'Berikutnya'
	String get nextTitle => 'Berikutnya';

	/// id: 'Semua di Rutin'
	String get seeAllRecurring => 'Semua di Rutin';

	/// id: 'Rencanakan bulan ini'
	String get emptyTitle => 'Rencanakan bulan ini';

	/// id: 'Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas.'
	String get emptyBody => 'Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas.';

	/// id: 'Perkiraan saldo, paling tipis $low pada $date, akhir bulan $end'
	String chartSemantics({required Object low, required Object date, required Object end}) => 'Perkiraan saldo, paling tipis ${low} pada ${date}, akhir bulan ${end}';

	/// id: '$date · $amount'
	String chartPoint({required Object date, required Object amount}) => '${date} · ${amount}';

	/// id: 'Perkiraan saldo $date'
	String forecastEndLabel({required Object date}) => 'Perkiraan saldo ${date}';

	/// id: 'Terendah $amount pada $date'
	String forecastLowest({required Object amount, required Object date}) => 'Terendah ${amount} pada ${date}';

	/// id: '≈$amount'
	String approxAmount({required Object amount}) => '≈${amount}';

	/// id: 'Rencana bulan ini gagal dimuat.'
	String get loadError => 'Rencana bulan ini gagal dimuat.';

	/// id: 'Perkiraan'
	String get forecastBadge => 'Perkiraan';

	/// id: 'Awal $date'
	String startOf({required Object date}) => 'Awal ${date}';

	/// id: '$value jt'
	String compactMillion({required Object value}) => '${value} jt';

	/// id: '$value rb'
	String compactThousand({required Object value}) => '${value} rb';

	/// id: 'Siapkan dana'
	String get fundingTitle => 'Siapkan dana';

	/// id: 'Saldo $wallet diperkirakan kurang ≈$shortfall saat $name, $date. Siapkan dana di $wallet sebelum tanggal itu.'
	String fundingBody({required Object wallet, required Object shortfall, required Object name, required Object date}) => 'Saldo ${wallet} diperkirakan kurang ≈${shortfall} saat ${name}, ${date}. Siapkan dana di ${wallet} sebelum tanggal itu.';

	/// id: 'Lihat perkiraan $wallet'
	String fundingAction({required Object wallet}) => 'Lihat perkiraan ${wallet}';

	/// id: '+$n lainnya'
	String fundingMore({required Object n}) => '+${n} lainnya';

	/// id: '$month dimulai'
	String reviewTitle({required Object month}) => '${month} dimulai';

	/// id: '$done/$total'
	String reviewProgress({required Object done, required Object total}) => '${done}/${total}';

	/// id: 'Anggaran rutin bulan ini $amount, lahir sendiri.'
	String reviewBudgets({required Object amount}) => 'Anggaran rutin bulan ini ${amount}, lahir sendiri.';

	/// id: '$name ≈$amount, sesuai?'
	String reviewEstimate({required Object name, required Object amount}) => '${name} ≈${amount}, sesuai?';

	/// id: 'Kilas balik $month'
	String reviewLookback({required Object month}) => 'Kilas balik ${month}';

	/// id: 'Sesuai'
	String get reviewOk => 'Sesuai';

	/// id: 'Ubah'
	String get reviewEdit => 'Ubah';

	/// id: 'Ubah perkiraan'
	String get reviewEditEstimate => 'Ubah perkiraan';

	/// id: 'Lihat'
	String get reviewSee => 'Lihat';

	/// id: 'Selesai meninjau'
	String get reviewDone => 'Selesai meninjau';

	/// id: 'Nanti'
	String get reviewLater => 'Nanti';

	/// id: 'Tinjau rencana $month ($done/$total)'
	String reviewCollapsed({required Object month, required Object done, required Object total}) => 'Tinjau rencana ${month} (${done}/${total})';

	/// id: 'Rencana $month siap.'
	String reviewDoneMessage({required Object month}) => 'Rencana ${month} siap.';

	/// id: 'Pemasukan terjadwal $income, terikat $committed, nganggur $free.'
	String homeReviewBody({required Object income, required Object committed, required Object free}) => 'Pemasukan terjadwal ${income}, terikat ${committed}, nganggur ${free}.';

	/// id: 'Ada rutin bernominal kira-kira yang perlu dicek.'
	String get homeReviewEstimates => 'Ada rutin bernominal kira-kira yang perlu dicek.';

	/// id: 'Tinjau rencana'
	String get homeReviewAction => 'Tinjau rencana';

	/// id: 'Kilas balik $month'
	String lookbackTitle({required Object month}) => 'Kilas balik ${month}';

	/// id: 'Rencana'
	String get lookbackPlanned => 'Rencana';

	/// id: 'Nyata'
	String get lookbackActual => 'Nyata';

	/// id: 'Uang nganggur'
	String get lookbackFree => 'Uang nganggur';

	/// id: 'Selisih terbesar: $line.'
	String lookbackBiggest({required Object line}) => 'Selisih terbesar: ${line}.';

	/// id: 'Perkiraan $month tepat.'
	String accuracyExact({required Object month}) => 'Perkiraan ${month} tepat.';

	/// id: 'Perkiraan $month meleset $amount.'
	String accuracyMissed({required Object month, required Object amount}) => 'Perkiraan ${month} meleset ${amount}.';

	/// id: 'Perkiraan $month meleset $amount, terbesar dari $line.'
	String accuracyMissedBy({required Object month, required Object amount, required Object line}) => 'Perkiraan ${month} meleset ${amount}, terbesar dari ${line}.';

	/// id: '${percent}% pemasukan $month sudah terikat (rutin + anggaran).'
	String committedShare({required Object percent, required Object month}) => '${percent}% pemasukan ${month} sudah terikat (rutin + anggaran).';

	/// id: '${percent}% pemasukan $month sudah terikat (rutin + anggaran); bulan sebelumnya ${previous}%.'
	String committedShareVs({required Object percent, required Object month, required Object previous}) => '${percent}% pemasukan ${month} sudah terikat (rutin + anggaran); bulan sebelumnya ${previous}%.';

	/// id: 'Sesudah $name selesai, mulai $month ruang bebas +$amount/bln.'
	String installmentFree({required Object name, required Object month, required Object amount}) => 'Sesudah ${name} selesai, mulai ${month} ruang bebas +${amount}/bln.';
}

// Path: record.draftIssue
class Translations$record$draftIssue$id {
	Translations$record$draftIssue$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Nominal belum terbaca. Isi sendiri.'
	String get amountMissing => 'Nominal belum terbaca. Isi sendiri.';

	/// id: 'Ada lebih dari satu nominal. Isi yang benar.'
	String get amountMultiple => 'Ada lebih dari satu nominal. Isi yang benar.';

	/// id: 'Angka tanpa satuan (ribu/juta). Pastikan nominalnya.'
	String get amountWithoutUnit => 'Angka tanpa satuan (ribu/juta). Pastikan nominalnya.';

	/// id: 'Nominal bisa dibaca dua cara. Pastikan nominalnya.'
	String get amountAmbiguous => 'Nominal bisa dibaca dua cara. Pastikan nominalnya.';

	/// id: 'Mata uang yang disebut berbeda dari mata uang aplikasi.'
	String get currencyUnsupported => 'Mata uang yang disebut berbeda dari mata uang aplikasi.';

	/// id: 'Dompet yang disebut tidak ada. Pilih dompetnya.'
	String get walletUnknown => 'Dompet yang disebut tidak ada. Pilih dompetnya.';

	/// id: 'Dompet asal belum jelas. Pilih dari dompet mana.'
	String get transferSourceMissing => 'Dompet asal belum jelas. Pilih dari dompet mana.';

	/// id: 'Dompet tujuan belum jelas. Pilih dompet tujuan.'
	String get transferTargetMissing => 'Dompet tujuan belum jelas. Pilih dompet tujuan.';

	/// id: 'Kategori yang disebut tidak ada. Pilih kategorinya.'
	String get categoryUnknown => 'Kategori yang disebut tidak ada. Pilih kategorinya.';

	/// id: 'Tanggal yang disebut tidak bisa dipakai. Pilih tanggalnya.'
	String get dateUnclear => 'Tanggal yang disebut tidak bisa dipakai. Pilih tanggalnya.';

	/// id: 'Arah transaksi tidak tertulis jelas. Pilih Keluar atau Masuk.'
	String get kindUnclear => 'Arah transaksi tidak tertulis jelas. Pilih Keluar atau Masuk.';
}

// Path: record.voice
class Translations$record$voice$id {
	Translations$record$voice$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Catat pakai suara'
	String get title => 'Catat pakai suara';

	/// id: 'Catat pakai suara'
	String get micLabel => 'Catat pakai suara';

	/// id: 'Silakan bicara.'
	String get listening => 'Silakan bicara.';

	/// id: 'Berhenti sendiri saat kamu diam.'
	String get autoStopHint => 'Berhenti sendiri saat kamu diam.';

	/// id: 'Contoh: “makan siang 35 ribu pakai BCA”'
	String get example => 'Contoh: “makan siang 35 ribu pakai BCA”';

	/// id: 'Memahami…'
	String get interpreting => 'Memahami…';

	/// id: 'Ketik saja'
	String get typeInstead => 'Ketik saja';

	late final Translations$record$voice$failure$id failure = Translations$record$voice$failure$id.internal(_root);

	/// id: 'Ketuk mikrofon, lalu ucapkan satu transaksi.'
	String get idleHint => 'Ketuk mikrofon, lalu ucapkan satu transaksi.';

	/// id: 'Rekam'
	String get recordingBadge => 'Rekam';

	/// id: 'Mulai merekam'
	String get startAction => 'Mulai merekam';

	/// id: 'Mendengarkan'
	String get listeningButtonLabel => 'Mendengarkan';

	/// id: 'Rekam ulang'
	String get retryAction => 'Rekam ulang';

	/// id: 'Kamu bicara dalam bahasa apa?'
	String get languageTitle => 'Kamu bicara dalam bahasa apa?';

	/// id: 'Dipakai untuk mengenali ucapan dan untuk tampilan aplikasi. Bisa diubah di Akun.'
	String get languageBody => 'Dipakai untuk mengenali ucapan dan untuk tampilan aplikasi. Bisa diubah di Akun.';

	/// id: 'Lanjut'
	String get languageContinue => 'Lanjut';
}

// Path: record.repeat
class Translations$record$repeat$id {
	Translations$record$repeat$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Ulangi'
	String get label => 'Ulangi';

	/// id: 'Tidak'
	String get off => 'Tidak';

	/// id: 'Tiap minggu'
	String get weekly => 'Tiap minggu';

	/// id: 'Tiap bulan'
	String get monthly => 'Tiap bulan';

	/// id: 'Tiap tahun'
	String get yearly => 'Tiap tahun';

	/// id: 'Tiap $day'
	String everyWeekday({required Object day}) => 'Tiap ${day}';

	/// id: 'Tiap tanggal $day'
	String everyMonthDay({required Object day}) => 'Tiap tanggal ${day}';

	/// id: 'Tiap $date'
	String everyYearDate({required Object date}) => 'Tiap ${date}';

	/// id: 'Tiap $n minggu'
	String everyNWeeks({required Object n}) => 'Tiap ${n} minggu';

	/// id: 'Tiap $n bulan'
	String everyNMonths({required Object n}) => 'Tiap ${n} bulan';

	/// id: 'Tiap $n tahun'
	String everyNYears({required Object n}) => 'Tiap ${n} tahun';

	/// id: 'Atur lebih lanjut'
	String get moreAction => 'Atur lebih lanjut';

	/// id: 'Kurangi'
	String get lessAction => 'Kurangi';

	/// id: 'Tambah'
	String get moreCountAction => 'Tambah';

	/// id: 'Berakhir'
	String get endLabel => 'Berakhir';

	/// id: 'Tidak pernah'
	String get endNever => 'Tidak pernah';

	/// id: 'Setelah N kali'
	String get endAfter => 'Setelah N kali';

	/// id: 'Sampai tanggal'
	String get endOn => 'Sampai tanggal';

	/// id: '$n kali'
	String endsAfterSummary({required Object n}) => '${n} kali';

	/// id: 'sampai $date'
	String endsOnSummary({required Object date}) => 'sampai ${date}';

	/// id: 'Nominal'
	String get amountLabel => 'Nominal';

	/// id: 'Tetap'
	String get amountFixed => 'Tetap';

	/// id: 'Kira-kira'
	String get amountEstimated => 'Kira-kira';

	/// id: 'Cara bayar'
	String get paymentLabel => 'Cara bayar';

	/// id: 'Bayar sendiri'
	String get paymentManual => 'Bayar sendiri';

	/// id: 'Autodebet'
	String get paymentAutoDebit => 'Autodebet';

	/// id: 'Catat dan jadwalkan'
	String get recordAndScheduleAction => 'Catat dan jadwalkan';

	/// id: 'Simpan jadwal'
	String get saveScheduleAction => 'Simpan jadwal';

	/// id: '$name dijadwalkan. Pertama $date.'
	String scheduledMessage({required Object name, required Object date}) => '${name} dijadwalkan. Pertama ${date}.';

	/// id: '$name tercatat dan dijadwalkan.'
	String recordedMessage({required Object name}) => '${name} tercatat dan dijadwalkan.';

	/// id: '$name tercatat. Berikutnya $date.'
	String recordedNextMessage({required Object name, required Object date}) => '${name} tercatat. Berikutnya ${date}.';

	/// id: 'Rutin'
	String get fallbackName => 'Rutin';

	/// id: '$name diperbarui.'
	String updatedMessage({required Object name}) => '${name} diperbarui.';

	/// id: 'Tautkan ke pos $item'
	String linkSuggestionAction({required Object item}) => 'Tautkan ke pos ${item}';

	/// id: 'Catat otomatis'
	String get autoRecordLabel => 'Catat otomatis';

	/// id: 'Dicatat sendiri saat aplikasi dibuka pada tanggalnya; autodebet menunggu sehari. Bisa dibatalkan.'
	String get autoRecordHint => 'Dicatat sendiri saat aplikasi dibuka pada tanggalnya; autodebet menunggu sehari. Bisa dibatalkan.';

	/// id: 'Tidak ada transaksi baru; saldo tidak berubah.'
	String get noBalanceChange => 'Tidak ada transaksi baru; saldo tidak berubah.';
}

// Path: record.calc
class Translations$record$calc$id {
	Translations$record$calc$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Hitungan $expression, nominal $amount'
	String semantics({required Object expression, required Object amount}) => 'Hitungan ${expression}, nominal ${amount}';

	/// id: 'Hasilnya harus lebih dari 0'
	String get notPositive => 'Hasilnya harus lebih dari 0';

	/// id: 'Tidak bisa dibagi 0'
	String get divideByZero => 'Tidak bisa dibagi 0';

	/// id: 'Hasilnya terlalu besar'
	String get tooLarge => 'Hasilnya terlalu besar';
}

// Path: account.errors
class Translations$account$errors$id {
	Translations$account$errors$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Tidak bisa terhubung. Periksa koneksi internetmu, lalu coba lagi.'
	String get network => 'Tidak bisa terhubung. Periksa koneksi internetmu, lalu coba lagi.';

	/// id: 'Email atau kata sandi salah.'
	String get wrongCredentials => 'Email atau kata sandi salah.';

	/// id: 'Terlalu banyak percobaan. Tunggu sebentar, lalu coba lagi.'
	String get tooManyRequests => 'Terlalu banyak percobaan. Tunggu sebentar, lalu coba lagi.';

	/// id: 'Akun ini dinonaktifkan.'
	String get userDisabled => 'Akun ini dinonaktifkan.';

	/// id: 'Gagal masuk. Coba lagi.'
	String get other => 'Gagal masuk. Coba lagi.';
}

// Path: currency.names
class Translations$currency$names$id {
	Translations$currency$names$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Rupiah Indonesia'
	String get idr => 'Rupiah Indonesia';

	/// id: 'Dolar AS'
	String get usd => 'Dolar AS';

	/// id: 'Euro'
	String get eur => 'Euro';

	/// id: 'Pound Inggris'
	String get gbp => 'Pound Inggris';

	/// id: 'Yen Jepang'
	String get jpy => 'Yen Jepang';

	/// id: 'Yuan Tiongkok'
	String get cny => 'Yuan Tiongkok';

	/// id: 'Won Korea Selatan'
	String get krw => 'Won Korea Selatan';

	/// id: 'Rupee India'
	String get inr => 'Rupee India';

	/// id: 'Dolar Singapura'
	String get sgd => 'Dolar Singapura';

	/// id: 'Ringgit Malaysia'
	String get myr => 'Ringgit Malaysia';

	/// id: 'Baht Thailand'
	String get thb => 'Baht Thailand';

	/// id: 'Peso Filipina'
	String get php => 'Peso Filipina';

	/// id: 'Dong Vietnam'
	String get vnd => 'Dong Vietnam';

	/// id: 'Dolar Australia'
	String get aud => 'Dolar Australia';
}

// Path: notificationCapture.reviewReason
class Translations$notificationCapture$reviewReason$id {
	Translations$notificationCapture$reviewReason$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Catat otomatis mati'
	String get autoRecordOff => 'Catat otomatis mati';

	/// id: 'Pola baru, cek dulu'
	String get newPattern => 'Pola baru, cek dulu';

	/// id: 'Nominal belum pasti'
	String get amountUnclear => 'Nominal belum pasti';

	/// id: 'Mata uang lain'
	String get otherCurrency => 'Mata uang lain';

	/// id: 'Jenis belum pasti'
	String get kindUnclear => 'Jenis belum pasti';

	/// id: 'Dompet tidak dikenali'
	String get walletUnknown => 'Dompet tidak dikenali';

	/// id: 'Kategori belum jelas'
	String get categoryUnclear => 'Kategori belum jelas';

	/// id: 'Tanggal belum pasti'
	String get dateUnclear => 'Tanggal belum pasti';
}

// Path: recurring.starters
class Translations$recurring$starters$id {
	Translations$recurring$starters$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Gaji'
	String get salary => 'Gaji';

	/// id: 'Kos/Sewa'
	String get rent => 'Kos/Sewa';

	/// id: 'Listrik'
	String get electricity => 'Listrik';

	/// id: 'Internet'
	String get internet => 'Internet';

	/// id: 'BPJS'
	String get bpjs => 'BPJS';

	/// id: 'Cicilan'
	String get installment => 'Cicilan';

	/// id: 'Paylater'
	String get paylater => 'Paylater';

	/// id: 'Langganan'
	String get subscription => 'Langganan';

	/// id: 'Kirim ke orang tua'
	String get parents => 'Kirim ke orang tua';

	/// id: 'Arisan'
	String get arisan => 'Arisan';

	/// id: 'Tabungan'
	String get savings => 'Tabungan';
}

// Path: record.voice.failure
class Translations$record$voice$failure$id {
	Translations$record$voice$failure$id.internal(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// id: 'Izin mikrofon ditolak. Izinkan di pengaturan perangkat.'
	String get permissionDenied => 'Izin mikrofon ditolak. Izinkan di pengaturan perangkat.';

	/// id: 'Perangkat ini belum punya pengenal ucapan.'
	String get unavailable => 'Perangkat ini belum punya pengenal ucapan.';

	/// id: 'Bahasa ini belum bisa dikenali tanpa internet di HP ini. Sambungkan internet, atau unduh paket bahasanya di setelan pengenalan ucapan perangkat.'
	String get languageOffline => 'Bahasa ini belum bisa dikenali tanpa internet di HP ini. Sambungkan internet, atau unduh paket bahasanya di setelan pengenalan ucapan perangkat.';

	/// id: 'Tidak ada ucapan yang tertangkap. Coba lagi.'
	String get noMatch => 'Tidak ada ucapan yang tertangkap. Coba lagi.';

	/// id: 'Mengenali suara butuh internet di perangkat ini. Sambungkan internet lalu rekam ulang, atau ketik saja.'
	String get network => 'Mengenali suara butuh internet di perangkat ini. Sambungkan internet lalu rekam ulang, atau ketik saja.';

	/// id: 'Ada yang salah. Coba lagi.'
	String get other => 'Ada yang salah. Coba lagi.';
}

/// The flat map containing all translations for locale <id>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'Tanukonomy',
			'common.quickAmountThousands' => ({required Object amount}) => '+${amount}rb',
			'common.quickAmountMillions' => ({required Object amount}) => '+${amount}jt',
			'common.save' => 'Simpan',
			'common.cancel' => 'Batal',
			'common.delete' => 'Hapus',
			'common.edit' => 'Sunting',
			'common.add' => 'Tambah',
			'common.retry' => 'Coba lagi',
			'common.loading' => 'Memuat...',
			'common.genericErrorMessage' => 'Ada yang salah. Coba lagi.',
			'common.confirmDeleteTitle' => 'Hapus?',
			'common.keypadBackspace' => 'Hapus satu digit',
			'common.keypadAdd' => 'Tambah',
			'common.keypadSubtract' => 'Kurang',
			'common.keypadMultiply' => 'Kali',
			'common.keypadDivide' => 'Bagi',
			'common.close' => 'Tutup',
			'common.done' => 'Selesai',
			'appShell.homeTabLabel' => 'Beranda',
			'appShell.budgetTabLabel' => 'Anggaran',
			'appShell.recordAction' => 'Catat',
			'appShell.recordVoiceHint' => 'Tekan lama untuk catat pakai suara',
			'appShell.transactionsTabLabel' => 'Riwayat',
			'appShell.walletsTabLabel' => 'Dompet',
			'appShell.planTabLabel' => 'Rencana',
			'record.incomeAction' => 'Catat pemasukan',
			'record.expenseAction' => 'Catat pengeluaran',
			'record.transferAction' => 'Catat transfer',
			'record.toWalletFieldLabel' => 'Ke dompet',
			'record.fromWalletFieldLabel' => 'Dari dompet',
			'record.destinationWalletFieldLabel' => 'Ke dompet',
			'record.dateFieldLabel' => 'Tanggal',
			'record.noteFieldHint' => 'Tulis catatan singkat',
			'record.noWalletsMessage' => 'Belum ada dompet. Buat dompet dulu di tab Dompet.',
			'record.sameWalletWarning' => 'Dompet asal dan tujuan tidak boleh sama.',
			'record.incomeSavedMessage' => 'Pemasukan tercatat.',
			'record.expenseSavedMessage' => 'Pengeluaran tercatat.',
			'record.transferSavedMessage' => 'Transfer tercatat.',
			'record.walletNotSelectedPrompt' => 'Belum dipilih',
			'record.savingMessage' => 'Menyimpan...',
			'record.editStepLabel' => 'Ubah transaksi',
			'record.expenseRuleTitle' => 'Saldo dompet berkurang',
			'record.clearAmountAction' => 'Bersihkan',
			'record.categorySectionLabel' => 'Kategori',
			'record.optionalHint' => 'Opsional',
			'record.expenseWalletSectionLabel' => 'Dari dompet',
			'record.noteSectionLabel' => 'Catatan',
			'record.balanceLabel' => 'Saldo',
			'record.categoryNoneLabel' => 'Tanpa kategori',
			'record.budgetItemLabel' => 'Pos anggaran',
			'record.budgetItemNone' => 'Tanpa anggaran',
			'record.budgetItemOutOfPeriod' => ({required Object name}) => 'Tanggal ini di luar periode anggaran "${name}", jadi transaksi ini tidak lagi masuk anggaran itu.',
			'record.freelanceCalloutTitle' => 'Honor freelance?',
			'record.freelanceCalloutAction' => 'Catat lewat Freelance',
			'record.kindSwitcherLabel' => 'Jenis transaksi',
			'record.kindExpense' => 'Pengeluaran',
			'record.kindIncome' => 'Pemasukan',
			'record.kindTransfer' => 'Transfer',
			'record.categoryAddLabel' => 'Tambah kategori',
			'record.draftCheckTitle' => 'Periksa sebelum mencatat',
			'record.draftIssue.amountMissing' => 'Nominal belum terbaca. Isi sendiri.',
			'record.draftIssue.amountMultiple' => 'Ada lebih dari satu nominal. Isi yang benar.',
			'record.draftIssue.amountWithoutUnit' => 'Angka tanpa satuan (ribu/juta). Pastikan nominalnya.',
			'record.draftIssue.amountAmbiguous' => 'Nominal bisa dibaca dua cara. Pastikan nominalnya.',
			'record.draftIssue.currencyUnsupported' => 'Mata uang yang disebut berbeda dari mata uang aplikasi.',
			'record.draftIssue.walletUnknown' => 'Dompet yang disebut tidak ada. Pilih dompetnya.',
			'record.draftIssue.transferSourceMissing' => 'Dompet asal belum jelas. Pilih dari dompet mana.',
			'record.draftIssue.transferTargetMissing' => 'Dompet tujuan belum jelas. Pilih dompet tujuan.',
			'record.draftIssue.categoryUnknown' => 'Kategori yang disebut tidak ada. Pilih kategorinya.',
			'record.draftIssue.dateUnclear' => 'Tanggal yang disebut tidak bisa dipakai. Pilih tanggalnya.',
			'record.draftIssue.kindUnclear' => 'Arah transaksi tidak tertulis jelas. Pilih Keluar atau Masuk.',
			'record.voice.title' => 'Catat pakai suara',
			'record.voice.micLabel' => 'Catat pakai suara',
			'record.voice.listening' => 'Silakan bicara.',
			'record.voice.autoStopHint' => 'Berhenti sendiri saat kamu diam.',
			'record.voice.example' => 'Contoh: “makan siang 35 ribu pakai BCA”',
			'record.voice.interpreting' => 'Memahami…',
			'record.voice.typeInstead' => 'Ketik saja',
			'record.voice.failure.permissionDenied' => 'Izin mikrofon ditolak. Izinkan di pengaturan perangkat.',
			'record.voice.failure.unavailable' => 'Perangkat ini belum punya pengenal ucapan.',
			'record.voice.failure.languageOffline' => 'Bahasa ini belum bisa dikenali tanpa internet di HP ini. Sambungkan internet, atau unduh paket bahasanya di setelan pengenalan ucapan perangkat.',
			'record.voice.failure.noMatch' => 'Tidak ada ucapan yang tertangkap. Coba lagi.',
			'record.voice.failure.network' => 'Mengenali suara butuh internet di perangkat ini. Sambungkan internet lalu rekam ulang, atau ketik saja.',
			'record.voice.failure.other' => 'Ada yang salah. Coba lagi.',
			'record.voice.idleHint' => 'Ketuk mikrofon, lalu ucapkan satu transaksi.',
			'record.voice.recordingBadge' => 'Rekam',
			'record.voice.startAction' => 'Mulai merekam',
			'record.voice.listeningButtonLabel' => 'Mendengarkan',
			'record.voice.retryAction' => 'Rekam ulang',
			'record.voice.languageTitle' => 'Kamu bicara dalam bahasa apa?',
			'record.voice.languageBody' => 'Dipakai untuk mengenali ucapan dan untuk tampilan aplikasi. Bisa diubah di Akun.',
			'record.voice.languageContinue' => 'Lanjut',
			'record.repeat.label' => 'Ulangi',
			'record.repeat.off' => 'Tidak',
			'record.repeat.weekly' => 'Tiap minggu',
			'record.repeat.monthly' => 'Tiap bulan',
			'record.repeat.yearly' => 'Tiap tahun',
			'record.repeat.everyWeekday' => ({required Object day}) => 'Tiap ${day}',
			'record.repeat.everyMonthDay' => ({required Object day}) => 'Tiap tanggal ${day}',
			'record.repeat.everyYearDate' => ({required Object date}) => 'Tiap ${date}',
			'record.repeat.everyNWeeks' => ({required Object n}) => 'Tiap ${n} minggu',
			'record.repeat.everyNMonths' => ({required Object n}) => 'Tiap ${n} bulan',
			'record.repeat.everyNYears' => ({required Object n}) => 'Tiap ${n} tahun',
			'record.repeat.moreAction' => 'Atur lebih lanjut',
			'record.repeat.lessAction' => 'Kurangi',
			'record.repeat.moreCountAction' => 'Tambah',
			'record.repeat.endLabel' => 'Berakhir',
			'record.repeat.endNever' => 'Tidak pernah',
			'record.repeat.endAfter' => 'Setelah N kali',
			'record.repeat.endOn' => 'Sampai tanggal',
			'record.repeat.endsAfterSummary' => ({required Object n}) => '${n} kali',
			'record.repeat.endsOnSummary' => ({required Object date}) => 'sampai ${date}',
			'record.repeat.amountLabel' => 'Nominal',
			'record.repeat.amountFixed' => 'Tetap',
			'record.repeat.amountEstimated' => 'Kira-kira',
			'record.repeat.paymentLabel' => 'Cara bayar',
			'record.repeat.paymentManual' => 'Bayar sendiri',
			'record.repeat.paymentAutoDebit' => 'Autodebet',
			'record.repeat.recordAndScheduleAction' => 'Catat dan jadwalkan',
			'record.repeat.saveScheduleAction' => 'Simpan jadwal',
			'record.repeat.scheduledMessage' => ({required Object name, required Object date}) => '${name} dijadwalkan. Pertama ${date}.',
			'record.repeat.recordedMessage' => ({required Object name}) => '${name} tercatat dan dijadwalkan.',
			'record.repeat.recordedNextMessage' => ({required Object name, required Object date}) => '${name} tercatat. Berikutnya ${date}.',
			'record.repeat.fallbackName' => 'Rutin',
			'record.repeat.updatedMessage' => ({required Object name}) => '${name} diperbarui.',
			'record.repeat.linkSuggestionAction' => ({required Object item}) => 'Tautkan ke pos ${item}',
			'record.repeat.autoRecordLabel' => 'Catat otomatis',
			'record.repeat.autoRecordHint' => 'Dicatat sendiri saat aplikasi dibuka pada tanggalnya; autodebet menunggu sehari. Bisa dibatalkan.',
			'record.repeat.noBalanceChange' => 'Tidak ada transaksi baru; saldo tidak berubah.',
			'record.balanceAfter' => ({required Object amount}) => 'Saldo jadi ${amount}',
			'record.allCategories' => 'Semua kategori',
			'record.calc.semantics' => ({required Object expression, required Object amount}) => 'Hitungan ${expression}, nominal ${amount}',
			'record.calc.notPositive' => 'Hasilnya harus lebih dari 0',
			'record.calc.divideByZero' => 'Tidak bisa dibagi 0',
			'record.calc.tooLarge' => 'Hasilnya terlalu besar',
			'record.amountSemantics' => ({required Object amount}) => 'Nominal ${amount}',
			'transaction.pageTitle' => 'Riwayat',
			'transaction.searchHint' => 'Cari di bulan ini: catatan / kategori...',
			'transaction.allFilterLabel' => ({required Object count}) => 'Semua ${count}',
			'transaction.incomeFilterLabel' => ({required Object count}) => 'Pemasukan ${count}',
			'transaction.expenseFilterLabel' => ({required Object count}) => 'Pengeluaran ${count}',
			'transaction.transferFilterLabel' => ({required Object count}) => 'Transfer ${count}',
			'transaction.walletFilterAllLabel' => 'Semua dompet',
			'transaction.walletFilterLabel' => 'Dompet',
			'transaction.categoryFilterAllLabel' => 'Semua kategori',
			'transaction.categoryFilterLabel' => 'Kategori',
			'transaction.filterButtonLabel' => 'Filter',
			'transaction.filterSheetTitle' => 'Filter transaksi',
			'transaction.filterSheetDoneAction' => 'Selesai',
			'transaction.todayLabel' => 'Hari ini',
			'transaction.yesterdayLabel' => 'Kemarin',
			'transaction.emptyMonthTitle' => 'Belum ada transaksi',
			'transaction.emptyMonthSubtitle' => 'Setiap transaksi yang kamu catat muncul di sini, dikelompokkan per hari.',
			'transaction.emptyMonthCta' => 'Catat transaksi',
			'transaction.emptyGuideTitle' => 'Tiga jenis transaksi',
			'transaction.emptyGuideIncomeTitle' => 'Pemasukan',
			'transaction.emptyGuideIncomeDescription' => 'Menambah saldo dompet yang kamu pilih.',
			'transaction.emptyGuideExpenseTitle' => 'Pengeluaran',
			'transaction.emptyGuideExpenseDescription' => 'Mengurangi saldo dompet dan mengisi pos anggaran yang tertaut.',
			'transaction.emptyGuideTransferTitle' => 'Transfer antardompet',
			'transaction.emptyGuideTransferDescription' => 'Memindahkan catatan saldo antar dompet tanpa mengubah total kekayaan.',
			'transaction.trustFooterMessage' => 'Riwayat lengkapmu, tersimpan aman di perangkatmu',
			'transaction.emptyFilterTitle' => 'Tidak ada transaksi bulan ini yang cocok dengan filter',
			'transaction.emptyFilterSubtitle' => 'Pencarian dan filter hanya mencakup bulan yang sedang dibuka. Ganti bulan, atau ganti dan hapus filter.',
			'transaction.clearFiltersButton' => 'Hapus filter',
			'transaction.crossMonthSearchButton' => 'Cari di bulan lain',
			'transaction.crossMonthSearchingLabel' => 'Mencari di bulan sebelumnya...',
			'transaction.crossMonthResultsHeader' => 'Ditemukan di bulan lain',
			'transaction.crossMonthLoadMoreButton' => 'Cari lebih jauh',
			'transaction.crossMonthNoMoreResults' => 'Tidak ditemukan di bulan-bulan sebelumnya.',
			'transaction.loadErrorTitle' => 'Transaksi gagal dimuat',
			'transaction.loadErrorSubtitle' => 'Periksa lagi lalu coba muat ulang.',
			'transaction.detailBackLabel' => 'Kembali',
			'transaction.detailIncomeTitle' => 'Pemasukan tercatat',
			'transaction.detailExpenseTitle' => 'Pengeluaran tercatat',
			'transaction.detailTransferTitle' => 'Transfer tercatat',
			'transaction.detailTypeLabel' => 'Jenis transaksi',
			'transaction.detailIncomeType' => 'Pemasukan',
			'transaction.detailExpenseType' => 'Pengeluaran',
			'transaction.detailTransferType' => 'Transfer antar dompet',
			'transaction.detailCategoryLabel' => 'Kategori',
			'transaction.detailIncomeWalletLabel' => 'Dompet tujuan',
			'transaction.detailExpenseWalletLabel' => 'Dompet sumber',
			'transaction.detailCurrentBalance' => 'Saldo saat ini',
			'transaction.detailNoteLabel' => 'Catatan',
			'transaction.detailFromLabel' => 'Dari',
			'transaction.detailToLabel' => 'Ke',
			'transaction.detailAmountLabel' => 'Jumlah',
			'transaction.detailManualNote' => 'Tersimpan aman di perangkatmu. Saldo dompet mengikuti setiap catatan, jadi saat kamu menyunting atau menghapusnya, saldonya ikut menyesuaikan.',
			'transaction.editAction' => 'Ubah',
			'transaction.recordAgainAction' => 'Catat lagi',
			'transaction.deleteAction' => 'Hapus transaksi',
			'transaction.editSheetTitle' => 'Ubah transaksi',
			'transaction.saveChangesAction' => 'Simpan perubahan',
			'transaction.updatedMessage' => 'Perubahan tersimpan.',
			'transaction.deletedMessage' => 'Transaksi dihapus.',
			'transaction.undoDeleteAction' => 'Urungkan',
			'transaction.restoredMessage' => 'Transaksi dikembalikan.',
			'transaction.budgetLabel' => 'Anggaran',
			'transaction.openBudgetAction' => 'Lihat anggaran',
			'transaction.detailFreelanceNote' => 'Pemasukan ini dicatat dari pembayaran freelance. Untuk mengubahnya, batalkan penerimaannya di Freelance.',
			'transaction.makeRecurringAction' => 'Jadikan rutin',
			'transaction.previousMonth' => 'Bulan sebelumnya',
			'transaction.nextMonth' => 'Bulan berikutnya',
			'wallet.subtitle' => 'Total saldo semua dompet aktif',
			'wallet.activeBadge' => ({required Object count}) => '${count} dompet aktif',
			'wallet.listHeading' => 'Dompet aktif',
			'wallet.addAction' => 'Tambah dompet',
			'wallet.inactiveHeading' => 'Dompet nonaktif',
			'wallet.inactiveBadge' => 'Nonaktif',
			'wallet.typeBank' => 'Bank',
			'wallet.typeCash' => 'Uang tunai',
			'wallet.typeEwallet' => 'Dompet digital',
			'wallet.typeSavings' => 'Tabungan',
			'wallet.typeCard' => 'Kartu',
			'wallet.emptyTitle' => 'Belum ada dompet tercatat',
			'wallet.emptyBody' => 'Tambahkan dompet pertama untuk mulai mencatat posisi uangmu. Bisa berupa rekening bank, e-wallet, atau uang tunai di saku.',
			'wallet.loadErrorTitle' => 'Dompet gagal dimuat',
			'wallet.loadErrorSubtitle' => 'Data dompet tidak terbaca. Coba lagi.',
			'wallet.addTitle' => 'Tambah dompet',
			'wallet.editTitle' => 'Ubah dompet',
			'wallet.addStepLabel' => 'Dompet baru',
			'wallet.editStepLabel' => 'Ubah dompet',
			'wallet.nameLabel' => 'Nama dompet',
			'wallet.nameHint' => 'Contoh: Tabungan Mandiri, OVO, Brankas Tunai',
			'wallet.nameRequiredHint' => 'Wajib',
			'wallet.nameMaxHint' => 'Maks. 24 karakter',
			'wallet.iconLabel' => 'Pilih ikon',
			'wallet.initialBalanceLabel' => 'Saldo awal saat ini',
			'wallet.initialBalanceHelp' => 'Saldo awal adalah uang di dompet ini sekarang, titik mulai pencatatanmu. Setiap transaksi berikutnya dihitung dari sini.',
			'wallet.currentBalanceLabel' => 'Saldo tercatat saat ini',
			'wallet.editBalanceNote' => 'Mengubah saldo awal menghitung ulang saldo tercatat. Untuk selisih dengan uang nyata, catat pemasukan atau pengeluaran lewat Catat.',
			'wallet.activeSwitchLabel' => 'Dompet aktif',
			'wallet.activeSwitchHelp' => 'Dompet nonaktif tidak muncul di pemilih dompet. Transaksinya tetap tersimpan dan dihitung.',
			'wallet.saveAddAction' => 'Simpan dompet',
			'wallet.deleteAction' => 'Hapus dompet',
			'wallet.deleteHelp' => 'Hanya bisa dihapus kalau belum punya transaksi sama sekali. Kalau sudah, nonaktifkan saja.',
			'wallet.deleteConfirmTitle' => 'Hapus dompet?',
			'wallet.deleteConfirmMessage' => ({required Object name}) => 'Dompet ${name} akan dihapus permanen. Tindakan ini tidak bisa dibatalkan.',
			'wallet.savedMessage' => 'Dompet tersimpan.',
			'wallet.updatedMessage' => 'Dompet diperbarui.',
			'wallet.deletedMessage' => 'Dompet dihapus.',
			'wallet.reorderAction' => 'Urutkan dompet',
			'wallet.reorderTitle' => 'Urutkan dompet',
			'wallet.reorderHint' => 'Tekan dan seret dompet untuk mengubah urutannya. Urutan ini dipakai di semua daftar dan pemilih dompet.',
			'wallet.reorderHandleLabel' => ({required Object name}) => 'Seret untuk memindah ${name}',
			'wallet.reorderSaveAction' => 'Simpan urutan',
			'wallet.reorderedMessage' => 'Urutan dompet tersimpan.',
			'wallet.deleteBlockedMessage' => 'Dompet ini sudah punya transaksi, jadi tidak bisa dihapus. Nonaktifkan saja.',
			'wallet.privacyNote' => 'Data tersimpan lokal dan privat di perangkatmu.',
			'wallet.detailBackLabel' => 'Kembali',
			'wallet.detailEditAction' => 'Sunting',
			'wallet.detailRecentHeading' => 'Transaksi bulan ini',
			'wallet.detailIncomeLabel' => 'Pemasukan',
			'wallet.detailExpenseLabel' => 'Pengeluaran',
			'wallet.detailRecentEmptyTitle' => 'Belum ada transaksi',
			'wallet.detailRecentEmpty' => 'Belum ada transaksi bulan ini untuk dompet ini.',
			'wallet.detailViewAllAction' => 'Lihat semua transaksi',
			'wallet.detailRecordAction' => 'Catat transaksi',
			'wallet.detailTransferInLabel' => 'Transfer masuk',
			'wallet.detailTransferOutLabel' => 'Transfer keluar',
			'wallet.detailBalanceChangeLabel' => 'Perubahan saldo',
			'budget.activeBadge' => ({required Object count}) => '${count} aktif',
			'budget.plannedLabel' => 'Rencana',
			'budget.spentLabel' => 'Terpakai',
			'budget.remainingLabel' => 'Sisa',
			'budget.filterAll' => 'Semua',
			'budget.filterActive' => 'Aktif',
			'budget.filterFinished' => 'Selesai',
			'budget.filterArchived' => 'Nonaktif',
			'budget.filterWalletAll' => 'Semua dompet',
			'budget.addAction' => 'Buat anggaran',
			'budget.periodWeekly' => 'Mingguan',
			'budget.periodMonthly' => 'Bulanan',
			'budget.itemStatusPlanned' => 'Belum terpakai',
			'budget.itemStatusPartiallySpent' => 'Terpakai sebagian',
			'budget.itemStatusCompleted' => 'Selesai',
			'budget.itemStatusOverspent' => 'Lewat anggaran',
			'budget.itemCount' => ({required Object count}) => '${count} pos',
			'budget.emptyTitle' => 'Belum ada anggaran',
			'budget.emptyBody' => 'Rencanakan batas belanja mingguan atau bulanan untuk satu dompet, lalu pantau berapa yang sudah terpakai.',
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
			'budget.addTitle' => 'Buat anggaran',
			'budget.editTitle' => 'Ubah anggaran',
			'budget.ruleTitle' => 'Aturan anggaran',
			'budget.ruleBody' => 'Rencana ini jadi patokan belanjamu. Saldo dompet bergerak dari transaksi yang kamu catat.',
			'budget.nameLabel' => 'Nama anggaran',
			'budget.nameHint' => 'Contoh: Kebutuhan Rumah Tangga',
			'budget.requiredHint' => 'Wajib',
			'budget.walletLabel' => 'Dompet terkait',
			'budget.walletHelp' => 'Hanya pengeluaran dan transfer keluar dompet ini yang dihitung.',
			'budget.walletBalance' => ({required Object amount}) => 'Saldo: ${amount}',
			'budget.periodLabel' => 'Periode',
			'budget.startDateLabel' => 'Mulai',
			'budget.periodRange' => ({required Object start, required Object end}) => '${start} – ${end}',
			'budget.periodRangeShort' => ({required Object start, required Object end}) => '${start}–${end}',
			'budget.periodStartRow' => ({required Object date, required Object range}) => 'Mulai ${date} · ${range}',
			'budget.itemsLabel' => 'Pos anggaran',
			'budget.itemsHelp' => 'Rincian rencana belanja atau rencana transfer. Total rencana anggaran adalah jumlah seluruh pos.',
			'budget.addItemAction' => 'Tambah pos',
			'budget.saveAddAction' => 'Simpan anggaran',
			'budget.archiveAction' => 'Arsipkan anggaran',
			'budget.unarchiveAction' => 'Aktifkan kembali',
			'budget.archiveHelp' => 'Anggaran nonaktif disembunyikan dari daftar aktif. Transaksi yang tertaut tetap tercatat.',
			'budget.deleteAction' => 'Hapus anggaran',
			'budget.deleteConfirmTitle' => 'Hapus anggaran?',
			'budget.deleteConfirmMessage' => ({required Object name}) => 'Anggaran "${name}" beserta posnya akan dihapus. Transaksi yang tertaut tetap tercatat dan saldo dompet tidak berubah.',
			'budget.itemAddTitle' => 'Tambah pos',
			'budget.itemEditTitle' => 'Ubah pos',
			'budget.itemNameLabel' => 'Nama pos',
			'budget.itemNameHint' => 'Contoh: Beras',
			'budget.itemModeAmount' => 'Nominal',
			'budget.itemModeItemized' => 'Jumlah × harga',
			'budget.itemAmountLabel' => 'Nominal rencana',
			'budget.itemQuantityLabel' => 'Jumlah',
			'budget.itemUnitPriceLabel' => 'Harga satuan',
			'budget.itemTotalLabel' => 'Total pos',
			'budget.itemItemizedDetail' => ({required Object quantity, required Object price}) => '${quantity} × ${price}',
			'budget.itemSaveAction' => 'Simpan pos',
			'budget.itemDeleteAction' => 'Hapus pos',
			'budget.detailBackLabel' => 'Daftar anggaran',
			'budget.detailEditAction' => 'Sunting anggaran',
			'budget.detailRecordExpenseAction' => 'Catat pengeluaran',
			'budget.detailRecordTransferAction' => 'Catat transfer',
			'budget.detailItemsHeading' => 'Pos anggaran',
			'budget.detailNoItems' => 'Anggaran ini belum punya pos. Tambahkan pos lewat Sunting supaya pengeluaran bisa ditautkan.',
			'budget.detailLinkedHeading' => 'Transaksi tertaut',
			'budget.detailLinkedEmpty' => 'Belum ada transaksi yang tertaut ke anggaran ini.',
			'budget.detailHowTitle' => 'Cara kerja pos anggaran',
			'budget.unknownWallet' => 'Dompet tidak ditemukan',
			'budget.totalPlannedLabel' => 'Total rencana',
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
			'budget.templatesAction' => 'Template anggaran',
			'budget.templatesTitle' => 'Template anggaran',
			'budget.templatesSavedBadge' => ({required Object count}) => '${count} tersimpan',
			'budget.templatesInfoTitle' => 'Apa itu template anggaran?',
			'budget.templatesInfoBody' => 'Susunan pos rencana yang bisa dipakai ulang tanpa mengetik dari nol. Setiap pemakaian membuat anggaran baru yang berdiri sendiri.',
			'budget.templateItemCount' => ({required Object count}) => '${count} pos',
			'budget.templateItemsLabel' => 'Daftar pos rencana',
			'budget.templateTotalLabel' => 'Total rencana',
			'budget.templateUseAction' => 'Gunakan template ini',
			'budget.templateEditAction' => 'Ubah',
			'budget.templateDuplicateAction' => 'Duplikat',
			'budget.templateInactiveBadge' => 'Nonaktif',
			'budget.templateAddAction' => 'Buat template',
			'budget.templatesFooter' => 'Template bisa disunting kapan saja tanpa mengubah anggaran yang sudah dibuat darinya.',
			'budget.templatesEmptyBadge' => 'Belum ada template',
			'budget.templatesEmptyTitle' => 'Belum ada template',
			'budget.templatesEmptyBody' => 'Simpan susunan pos yang sering dipakai, misalnya belanja bulanan, supaya anggaran berikutnya tinggal dipakai.',
			'budget.templateNeedsWallet' => 'Buat dompet aktif dulu untuk memakai template.',
			'budget.templatesLoadError' => 'Template gagal dimuat',
			'budget.templateAddTitle' => 'Buat template',
			'budget.templateEditTitle' => 'Ubah template',
			'budget.templateRuleBody' => 'Template menyimpan susunan pos rencanamu. Dompet dan periodenya dipilih saat template dipakai.',
			'budget.templateNameHint' => 'Contoh: Belanja bulanan',
			'budget.templateEnabledLabel' => 'Tawarkan template ini',
			'budget.templateEnabledHelp' => 'Template nonaktif tetap tersimpan, tapi tidak bisa dipakai membuat anggaran.',
			'budget.templateSaveAction' => 'Simpan template',
			'budget.templateDeleteAction' => 'Hapus template',
			'budget.templateDeleteConfirmTitle' => 'Hapus template?',
			'budget.templateDeleteConfirmMessage' => ({required Object name}) => 'Template "${name}" akan dihapus. Anggaran yang pernah dibuat darinya tidak ikut terhapus.',
			'budget.templateSavedMessage' => 'Template tersimpan.',
			'budget.templateUpdatedMessage' => 'Perubahan template tersimpan.',
			'budget.templateDeletedMessage' => 'Template dihapus.',
			'budget.templateDuplicatedMessage' => 'Template digandakan.',
			'budget.templateCopyName' => ({required Object name}) => '${name} (salinan)',
			'budget.templateNameLabel' => 'Nama template',
			'budget.repeatLabel' => 'Ulangi tiap periode',
			'budget.repeatHelpMonthly' => ({required Object date}) => 'Lahir lagi tiap bulan mulai ${date} dengan pos yang sama.',
			'budget.repeatHelpWeekly' => ({required Object date}) => 'Lahir lagi tiap minggu mulai ${date} dengan pos yang sama.',
			'budget.repeatUnavailable' => 'Anggaran bulanan bisa diulang bila mulai tanggal 1–28.',
			'budget.repeatPastNote' => 'Periode ini sudah lewat. Perubahannya tidak memengaruhi periode berikutnya.',
			'budget.scopeTitle' => 'Berlaku untuk',
			'budget.scopeThisPeriod' => 'Hanya periode ini',
			'budget.scopeThisAndNext' => 'Periode ini dan berikutnya',
			'budget.recurringBadge' => 'Rutin',
			'budget.templateScheduledMonthly' => ({required Object wallet}) => 'Ulangi tiap bulan · ${wallet}',
			'budget.templateScheduledWeekly' => ({required Object wallet}) => 'Ulangi tiap minggu · ${wallet}',
			'budget.dayOfPeriod' => ({required Object day, required Object total}) => 'Hari ke-${day} dari ${total}',
			'freelance.title' => 'Freelance',
			'freelance.worklogTab' => ({required Object count}) => 'Jam kerja (${count})',
			'freelance.paymentsTab' => ({required Object count}) => 'Tagihan (${count})',
			'freelance.loadErrorTitle' => 'Data freelance gagal dimuat',
			'freelance.ruleTitle' => 'Cara Freelance mencatat',
			'freelance.ruleBody' => 'Jam kerja terkumpul jadi tagihan, dan saldo dompet bertambah saat tagihannya dicatat diterima.',
			'freelance.hoursValue' => ({required Object hours}) => '${hours} jam',
			'freelance.hourShort' => 'jam',
			'freelance.projectCount' => ({required Object count}) => '${count} proyek',
			'freelance.earnedLabel' => 'Total diperoleh',
			'freelance.paidLabel' => 'Sudah diterima',
			'freelance.unpaidLabel' => 'Belum diterima',
			'freelance.projectsLabel' => 'Proyek',
			'freelance.projectsEmpty' => 'Belum ada proyek. Tambahkan klien atau proyek beserta tarif per jamnya dulu.',
			'freelance.projectAddTitle' => 'Tambah proyek',
			'freelance.projectEditTitle' => 'Ubah proyek',
			'freelance.projectNameLabel' => 'Nama klien atau proyek',
			'freelance.projectNameHint' => 'Contoh: Studio Koding',
			'freelance.requiredHint' => 'Wajib',
			'freelance.hourlyRateLabel' => 'Tarif per jam',
			'freelance.hourlyRateHelp' => 'Tarif bawaan untuk jam kerja baru. Mengubahnya tidak mengubah jam kerja yang sudah dicatat.',
			'freelance.deductionsLabel' => 'Potongan',
			'freelance.deductionsHelp' => 'Dipotong dari gaji kotor setiap tagihan, misalnya pajak. Mengubahnya tidak mengubah tagihan yang sudah dibuat.',
			'freelance.deductionAddAction' => 'Tambah potongan',
			'freelance.deductionTitle' => 'Potongan',
			'freelance.deductionLabelLabel' => 'Nama potongan',
			'freelance.deductionLabelHint' => 'Contoh: Pajak',
			'freelance.deductionKindPercentage' => 'Persen',
			'freelance.deductionKindFixed' => 'Nominal tetap',
			'freelance.deductionPercentLabel' => 'Persen dari gaji kotor',
			'freelance.deductionPercentHelp' => 'Paling banyak satu angka di belakang koma, misalnya 2,5.',
			'freelance.deductionAmountLabel' => 'Nominal per tagihan',
			'freelance.deductionSaveAction' => 'Simpan potongan',
			'freelance.deductionRemoveAction' => 'Hapus potongan',
			'freelance.projectSaveAction' => 'Simpan proyek',
			'freelance.projectDeleteAction' => 'Hapus proyek',
			'freelance.projectDeleteLockedHint' => 'Proyek yang sudah punya jam kerja tidak bisa dihapus.',
			'freelance.projectDeleteConfirmTitle' => 'Hapus proyek?',
			'freelance.projectDeleteConfirmMessage' => ({required Object name}) => 'Proyek "${name}" akan dihapus.',
			'freelance.projectDeleteRefused' => 'Proyek ini sudah punya jam kerja, jadi tidak bisa dihapus.',
			'freelance.projectSavedMessage' => 'Proyek tersimpan.',
			'freelance.projectUpdatedMessage' => 'Perubahan proyek tersimpan.',
			'freelance.projectDeletedMessage' => 'Proyek dihapus.',
			'freelance.projectLabel' => 'Proyek',
			'freelance.projectPick' => 'Pilih proyek',
			'freelance.entryAddTitle' => 'Catat jam kerja',
			'freelance.entryEditTitle' => 'Ubah jam kerja',
			'freelance.entryRuleBody' => 'Jam kerja terkumpul jadi tagihan. Uangnya masuk ke saldo saat tagihannya dicatat diterima.',
			'freelance.workDateLabel' => 'Tanggal kerja',
			'freelance.hoursLabel' => 'Durasi pengerjaan',
			'freelance.entryRateHelp' => 'Terisi dari tarif proyek. Ubah kalau tarif kali ini berbeda.',
			'freelance.noteLabel' => 'Catatan',
			'freelance.noteHint' => 'Apa yang dikerjakan (opsional)',
			'freelance.entrySaveAction' => 'Simpan jam kerja',
			'freelance.entrySaveHint' => 'Nominal ini tercatat sebagai diperoleh, belum diterima.',
			'freelance.entryDeleteAction' => 'Hapus jam kerja',
			'freelance.entryDeleteConfirmTitle' => 'Hapus jam kerja ini?',
			'freelance.entryDeleteConfirmMessage' => 'Jam kerja ini dihapus. Saldo dompet tidak berubah.',
			'freelance.entryLockedMessage' => 'Jam kerja yang sudah masuk tagihan tidak bisa diubah atau dihapus.',
			'freelance.entrySavedMessage' => 'Jam kerja tercatat.',
			'freelance.entryUpdatedMessage' => 'Perubahan jam kerja tersimpan.',
			'freelance.entryDeletedMessage' => 'Jam kerja dihapus.',
			'freelance.hoursTimesRate' => ({required Object hours, required Object rate}) => '${hours} jam × ${rate}',
			'freelance.statusUnbilled' => 'Belum ditagih',
			'freelance.statusPending' => 'Tertunda',
			'freelance.statusPaid' => 'Diterima',
			'freelance.expectedOn' => ({required Object date}) => 'Perkiraan diterima ${date}',
			'freelance.receivedOn' => ({required Object date, required Object wallet}) => 'Diterima ${date} di ${wallet}',
			'freelance.unknownProject' => 'Proyek terhapus',
			'freelance.unknownWallet' => 'dompet terhapus',
			'freelance.pendingTotalLabel' => 'Tertunda (bersih)',
			'freelance.paymentAddTitle' => 'Buat tagihan',
			'freelance.paymentCreateRuleBody' => 'Tagihan mengelompokkan jam kerja yang belum ditagih. Saat dicatat diterima, saldo dompet bertambah.',
			'freelance.paymentEntriesLabel' => ({required Object count, required Object hours}) => 'Ditagih: ${count} catatan, ${hours} jam',
			'freelance.paymentEntriesSummary' => ({required Object count, required Object hours}) => '${count} catatan · ${hours} jam',
			'freelance.expectedDateLabel' => 'Perkiraan tanggal diterima',
			'freelance.grossPayLabel' => 'Gaji kotor',
			'freelance.netPayLabel' => 'Gaji bersih',
			'freelance.netPayNotPositive' => 'Potongan tidak boleh sama dengan atau melebihi gaji kotor.',
			'freelance.paymentCreateAction' => 'Buat tagihan',
			'freelance.paymentChangeDateAction' => 'Ubah tanggal',
			'freelance.paymentDeleteAction' => 'Hapus',
			'freelance.paymentDeleteConfirmTitle' => 'Hapus tagihan?',
			'freelance.paymentDeleteConfirmMessage' => 'Tagihan tertunda ini dihapus dan jam kerjanya kembali belum ditagih. Saldo dompet tidak berubah.',
			'freelance.paymentEntriesInvalid' => 'Jam kerja yang dipilih sudah ditagih atau bukan milik proyek ini.',
			'freelance.paymentPaidLocked' => 'Tagihan yang sudah diterima tidak bisa dihapus. Batalkan penerimaannya dulu.',
			'freelance.paymentAlreadyPaid' => 'Tagihan ini sudah dicatat diterima.',
			'freelance.paymentCreatedMessage' => 'Tagihan dibuat.',
			'freelance.paymentUpdatedMessage' => 'Tanggal tagihan diperbarui.',
			'freelance.paymentDeletedMessage' => 'Tagihan dihapus.',
			'freelance.receiveTitle' => 'Catat tagihan diterima',
			'freelance.receiveRuleTitle' => 'Honor sudah masuk',
			'freelance.receiveRuleBody' => 'Catat saat uangnya sudah kamu terima. Saldo dompet pilihan bertambah sebesar gaji bersih, dan tagihan ini tercatat lunas.',
			'freelance.receiveAmountLabel' => 'Nominal diterima',
			'freelance.receiveWalletLabel' => 'Dompet penerima',
			'freelance.receiveDateLabel' => 'Tanggal diterima',
			'freelance.receiveNoteDefault' => ({required Object project}) => 'Tagihan freelance ${project}',
			'freelance.receiveAction' => 'Catat diterima',
			'freelance.paymentReceivedMessage' => 'Tagihan dicatat diterima. Saldo dompet bertambah.',
			'freelance.receiptCancelAction' => 'Batalkan penerimaan',
			'freelance.receiptCancelConfirmTitle' => 'Batalkan penerimaan?',
			'freelance.receiptCancelConfirmMessage' => 'Pemasukannya dihapus dan saldo dompet berkurang kembali. Tagihan kembali tertunda.',
			'freelance.receiptCancelledMessage' => 'Penerimaan dibatalkan. Tagihan kembali tertunda.',
			'freelance.changeAction' => 'Ubah',
			'freelance.receiptCancelConfirmAction' => 'Hapus pemasukan',
			'freelance.billAction' => ({required Object count}) => 'Tagih (${count})',
			'freelance.entriesEmptyTitle' => 'Belum ada jam kerja',
			'freelance.entriesEmptyBody' => 'Jam kerja yang kamu catat jadi dasar tagihan proyek ini.',
			'freelance.entriesFilteredEmpty' => 'Tidak ada jam kerja dengan status ini.',
			_ => null,
		} ?? switch (path) {
			'freelance.entryAddShortAction' => 'Catat jam kerja',
			'freelance.filterAll' => 'Semua',
			'freelance.noDeductions' => 'Tanpa potongan',
			'freelance.projectTotals' => ({required Object hours, required Object amount}) => 'Total ${hours} jam · ${amount}',
			'freelance.projectsEmptyTitle' => 'Belum ada proyek',
			'freelance.unbilledLabel' => 'Belum ditagih',
			'freelance.paymentsEmptyTitle' => 'Belum ada tagihan',
			'freelance.paymentsEmptyBody' => 'Kumpulkan jam kerja yang belum ditagih jadi satu tagihan, lalu catat saat dibayar.',
			'freelance.paymentsFilteredEmpty' => 'Tidak ada tagihan dengan status ini.',
			'freelance.nextExpected' => ({required Object count, required Object date}) => '${count} tagihan · terdekat ${date}',
			'freelance.paymentWorkRange' => ({required Object range}) => 'Kerja ${range}',
			'freelance.paidOffBadge' => 'Lunas',
			'home.flowTitle' => ({required Object period}) => 'Arus ${period}',
			'home.loadErrorTitle' => 'Beranda gagal dimuat',
			'home.balanceLabel' => 'Total saldo',
			'home.walletCount' => ({required Object count}) => '${count} dompet aktif',
			'home.budgetTitle' => 'Anggaran aktif',
			'home.budgetRemaining' => 'Sisa',
			'home.budgetOver' => 'Lewat rencana',
			'home.budgetAction' => 'Lihat anggaran',
			'home.freelanceTitle' => 'Freelance',
			'home.freelanceAction' => 'Lihat Freelance',
			'home.recentTitle' => 'Transaksi terbaru',
			'home.seeAll' => 'Lihat semua',
			'home.firstTitle' => 'Mulai dari dompetmu',
			'home.firstBody' => 'Catat di mana uangmu berada sekarang. Setiap transaksi akan memperbarui saldonya.',
			'home.stepWalletTitle' => 'Tambah dompet pertama',
			'home.stepWalletBody' => 'Rekening bank, dompet digital, atau uang tunai beserta saldonya.',
			'home.stepRecordTitle' => 'Catat transaksi pertama',
			'home.stepRecordBody' => 'Pengeluaran, pemasukan, atau transfer. Bisa diketik atau diucapkan.',
			'home.stepBudgetTitle' => 'Buat anggaran',
			'home.stepBudgetBody' => 'Opsional. Rencanakan batas belanja dan lihat sisanya.',
			'home.stepDone' => 'Selesai',
			'home.stepsTitle' => 'Langkah awal',
			'home.emptyTitle' => 'Belum ada transaksi',
			'home.emptyBody' => 'Mulai dengan mencatat pemasukan, pengeluaran, atau transfer pertamamu.',
			'home.recordAction' => 'Catat transaksi',
			'home.createWalletAction' => 'Tambah dompet',
			'home.budgetLink' => 'Atau buat anggaran pengeluaran',
			'home.budgetSpentOf' => ({required Object spent, required Object planned}) => '${spent} terpakai dari ${planned}',
			'home.walletLink' => ({required Object count}) => 'Di ${count} dompet',
			'home.netLabel' => 'Selisih bulan ini',
			'home.hideAmounts' => 'Sembunyikan nominal',
			'home.showAmounts' => 'Tampilkan nominal',
			'home.budgetSafe' => 'Aman',
			'home.budgetNearlyOut' => 'Hampir habis',
			'home.budgetOverBy' => ({required Object amount}) => 'Lewat ${amount}',
			'home.freelanceRowTitle' => 'Belum diterima',
			'home.freelanceRowSub' => ({required Object count, required Object date}) => '${count} tagihan, perkiraan ${date}',
			'home.incomeStat' => 'Pemasukan',
			'home.expenseStat' => 'Pengeluaran',
			'onboarding.skipAction' => 'Lewati',
			'onboarding.nextAction' => 'Lanjut',
			'onboarding.closeAction' => 'Tutup',
			'onboarding.pageIndicatorLabel' => ({required Object current, required Object total}) => 'Halaman ${current} dari ${total}',
			'onboarding.page1Title' => 'Semua uangmu, satu buku',
			'onboarding.page1Body' => 'Lihat di mana uangmu berada, apa saja yang terjadi padanya, dan ke mana kamu merencanakannya — semuanya di satu buku catatan.',
			'onboarding.page2Title' => 'Tahu di mana uangmu',
			'onboarding.page2Body' => 'Rekening bank, e-wallet, dan uang tunai jadi dompet. Saldo tiap dompet dan totalnya selalu terlihat.',
			'onboarding.page3Title' => 'Catat dalam hitungan detik',
			'onboarding.page3Body' => 'Pemasukan, pengeluaran, atau pindah dompet — ketuk Catat. Dompet yang biasa kamu pakai dan kategori favoritmu sudah menunggu.',
			'onboarding.page4Title' => 'Rencanakan, lalu pantau',
			'onboarding.page4Body' => 'Susun anggaran per minggu atau bulan dengan pos-pos belanjamu. Saldo tetap utuh, dan kamu melihat berapa yang sudah terpakai dari rencana.',
			'onboarding.finalTitle' => 'Mulai dari dompet pertamamu',
			'onboarding.finalBody' => 'Tambahkan satu dompet, lalu catat transaksi pertamamu. Di tiap layar, tanuki akan menunjukkan jalannya.',
			'onboarding.createWalletAction' => 'Tambah dompet',
			'onboarding.laterAction' => 'Nanti saja',
			'onboarding.signInAction' => 'Sudah punya akun? Masuk',
			'onboarding.backAction' => 'Kembali',
			'onboarding.currencyTitle' => 'Pilih mata uangmu',
			'onboarding.currencyBody' => 'Semua nominal di Tanukonomy memakai mata uang ini. Nanti bisa diganti di layar Akun, tapi angka yang sudah dicatat tidak dikonversi.',
			'onboarding.currencySuggested' => 'Sesuai wilayah perangkatmu',
			'onboarding.currencyChooseFirst' => 'Pilih mata uang dulu',
			'onboarding.currencyConfirm' => ({required Object code}) => 'Pakai ${code}',
			'onboarding.languageTitle' => 'Pilih bahasa',
			'onboarding.languageBody' => 'Dipakai untuk tampilan aplikasi dan saat mencatat dengan suara. Bisa diubah lagi di layar Akun.',
			'onboarding.languageConfirm' => 'Lanjut',
			'tour.nextAction' => 'Lanjut',
			'tour.doneAction' => 'Selesai',
			'tour.skipAction' => 'Lewati tur',
			'tour.stepCounter' => ({required Object current, required Object total}) => '${current}/${total}',
			'tour.stepSemantics' => ({required Object current, required Object total, required Object title, required Object body}) => 'Langkah ${current} dari ${total}: ${title}. ${body}',
			'tour.homeBalanceTitle' => 'Total saldo tercatat',
			'tour.homeBalanceBody' => 'Jumlah saldo semua dompet aktif — posisi uangmu dalam sekali lihat.',
			'tour.homeRecordTitle' => 'Satu pintu mencatat',
			'tour.homeRecordBody' => 'Semua pemasukan, pengeluaran, dan transfer dicatat dari sini.',
			'tour.homeCashFlowTitle' => 'Arus bulan ini',
			'tour.homeCashFlowBody' => 'Uang yang benar-benar masuk dan keluar bulan ini.',
			'tour.homeBudgetTitle' => 'Sisa anggaran aktif',
			'tour.homeBudgetBody' => 'Sisa rencana dari anggaran yang sedang berjalan. Ketuk untuk rinciannya.',
			'tour.homeFreelanceTitle' => 'Ringkasan freelance',
			'tour.homeFreelanceBody' => 'Penghasilan yang sudah dikerjakan dan yang masih tertunda. Saldo dompet baru bertambah saat tagihan dicatat diterima.',
			'tour.homeRecentTitle' => 'Transaksi terbaru',
			'tour.homeRecentBody' => 'Catatan terakhirmu. Ketuk salah satunya untuk rincian, atau Lihat semua untuk riwayat per bulan.',
			'tour.recordKindTitle' => 'Pilih jenisnya',
			'tour.recordKindBody' => 'Pengeluaran mengurangi saldo, pemasukan menambah, dan transfer hanya memindahkan antardompet — totalmu tetap.',
			'tour.recordFreelanceTitle' => 'Honor freelance lewat jalur sendiri',
			'tour.recordFreelanceBody' => 'Honor proyek dicatat sebagai tagihan diterima di Freelance, jadi jam kerja dan tagihannya ikut lunas.',
			'tour.recordAmountTitle' => 'Nominal',
			'tour.recordAmountBody' => 'Ketik nominalnya dengan papan angka.',
			'tour.recordWalletTitle' => 'Dompet terisi otomatis',
			'tour.recordWalletBody' => 'Dompet terakhir yang kamu pakai sudah terpilih. Ganti kalau perlu.',
			'tour.recordBudgetItemTitle' => 'Tautkan ke anggaran',
			'tour.recordBudgetItemBody' => 'Opsional. Pengeluaran yang ditautkan menambah angka terpakai pos itu, selama tanggalnya di dalam periode anggaran.',
			'tour.walletSummaryTitle' => 'Total semua dompet',
			'tour.walletSummaryBody' => 'Jumlah saldo tercatat dompet aktif.',
			'tour.walletCardTitle' => 'Rincian dompet',
			'tour.walletCardBody' => 'Ketuk untuk melihat riwayat dompet ini dan mencatat langsung dari sana.',
			'tour.walletAddTitle' => 'Tambah dompet',
			'tour.walletAddBody' => 'Rekening, e-wallet, atau tunai. Saldo awalnya bisa diubah kapan saja, dan saldo tercatat ikut menyesuaikan.',
			'tour.txnMonthTitle' => 'Satu bulan per tampilan',
			'tour.txnMonthBody' => 'Geser bulan untuk melihat riwayat lain. Pemasukan dan pengeluaran di sini hanya untuk bulan yang tampil.',
			'tour.txnFilterTitle' => 'Cari dan saring',
			'tour.txnFilterBody' => 'Cari catatan atau kategori, lalu saring per dompet dan kategori lewat Filter. Kalau bulan ini kosong, pencarian bisa dilanjutkan ke bulan lain.',
			'tour.txnRowTitle' => 'Ubah atau hapus',
			'tour.txnRowBody' => 'Ketuk transaksi untuk rinciannya; dari sana bisa diubah, dicatat lagi, atau dihapus, dan saldo dihitung ulang.',
			'tour.budgetSummaryTitle' => 'Sisa semua anggaran aktif',
			'tour.budgetSummaryBody' => 'Rencana dikurangi terpakai — sisa ruang belanjamu di semua anggaran aktif.',
			'tour.budgetFilterTitle' => 'Aktif lebih dulu',
			'tour.budgetFilterBody' => 'Daftar menampilkan anggaran aktif. Pilih Selesai atau Nonaktif untuk melihat yang lama.',
			'tour.budgetTemplatesTitle' => 'Pakai template',
			'tour.budgetTemplatesBody' => 'Simpan susunan pos yang berulang, lalu buat anggaran baru darinya.',
			'tour.budgetDetailItemTitle' => 'Pos anggaran',
			'tour.budgetDetailItemBody' => 'Terpakai naik dari transaksi yang ditautkan ke pos ini dalam periode anggaran.',
			'tour.budgetDetailRecordTitle' => 'Catat dari pos',
			'tour.budgetDetailRecordBody' => 'Membuka Catat dengan pos ini sudah terpilih.',
			'tour.freelanceProjectTitle' => 'Proyek dan tarif',
			'tour.freelanceProjectBody' => 'Setiap proyek punya tarif per jam dan potongan. Ketuk proyek untuk mencatat jam kerja dan tagihannya.',
			'tour.freelanceWorklogTitle' => 'Jam kerja',
			'tour.freelanceWorklogBody' => 'Jam kerja adalah penghasilan yang sudah kamu peroleh. Kumpulkan jadi tagihan, lalu catat saat dibayar.',
			'tour.freelanceReceiveTitle' => 'Uang benar-benar masuk',
			'tour.freelanceReceiveBody' => 'Catat saat honornya masuk: saldo dompet bertambah dan tagihannya lunas.',
			'tour.homeVoiceTitle' => 'Catat pakai suara',
			'tour.homeVoiceBody' => 'Tekan lama tombol Catat, ucapkan satu transaksi, lalu periksa formulirnya sebelum dicatat.',
			'tour.planTabsTitle' => 'Rencana',
			'tour.planTabsBody' => 'Bulan ini, anggaran, dan transaksi rutin ada di sini. Ketuk untuk berpindah.',
			'tour.planUnplannedTitle' => 'Uang nganggur',
			'tour.planUnplannedBody' => 'Pemasukan bulan ini dikurangi semua yang sudah terikat.',
			'tour.planForecastTitle' => 'Saldo dompet ≈',
			'tour.planForecastBody' => 'Perkiraan saldo sampai akhir bulan, termasuk titik paling tipisnya.',
			'tour.homeForecastTitle' => 'Perkiraan saldo',
			'tour.homeForecastBody' => 'Saldo dompet perkiraan di akhir bulan dan titik paling tipisnya. Ketuk untuk rinciannya di Rencana.',
			'tour.homePendingTitle' => 'Menunggu dicatat',
			'tour.homePendingBody' => 'Tagihan dan pemasukan rutin yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati.',
			'tour.recordRepeatTitle' => 'Ulangi',
			'tour.recordRepeatBody' => 'Untuk tagihan, gaji, atau langganan. Kemunculan berikutnya akan menunggu kamu catat; tidak pernah dicatat diam-diam.',
			'tour.recurringStartersTitle' => 'Mulai cepat',
			'tour.recurringStartersBody' => 'Pilih yang paling sering, mis. gaji atau listrik. Formulirnya terisi, tinggal sesuaikan.',
			'tour.recurringSummaryTitle' => 'Sisa rutin keluar',
			'tour.recurringSummaryBody' => 'Tagihan rutin yang belum tercatat bulan ini — uang yang sudah ada tujuannya.',
			'tour.recurringPendingTitle' => 'Menunggu dicatat',
			'tour.recurringPendingBody' => 'Kemunculan yang sudah tiba. Catat satu ketuk, ubah dulu, atau Lewati yang ini.',
			'tour.recurringAddTitle' => 'Tambah rutin',
			'tour.recurringAddBody' => 'Bisa juga dari Catat lewat Ulangi, atau Jadikan rutin di rincian transaksi.',
			'tour.budgetRepeatTitle' => 'Ulangi tiap periode',
			'tour.budgetRepeatBody' => 'Nyalakan supaya anggaran ini lahir lagi tiap bulan dengan pos yang sama. Tidak ada uang yang dipindahkan.',
			'tour.planMonthPickerTitle' => 'Bulan depan',
			'tour.planMonthPickerBody' => 'Lihat perkiraan dua bulan ke depan. Angka di tiap bulan adalah perkiraan akhir bulannya.',
			'info.menuTooltip' => 'Info dan tur',
			'info.replayTourAction' => 'Tur layar ini',
			'info.showIntroAction' => 'Pengenalan Tanukonomy',
			'info.resetAllAction' => 'Setel ulang semua tutorial',
			'info.resetConfirmTitle' => 'Setel ulang tutorial?',
			'info.resetConfirmMessage' => 'Pengenalan dan semua tur akan tampil lagi seperti pertama kali. Data keuanganmu tidak tersentuh.',
			'info.resetConfirmAction' => 'Setel ulang',
			'info.resetDoneMessage' => 'Tutorial disetel ulang.',
			'account.title' => 'Akun',
			'account.signedOutTitle' => 'Siapkan akunmu',
			'account.signedOutBody' => 'Semua pencatatan berjalan penuh tanpa akun. Akun menyiapkan cadangan dan sinkronisasi antarperangkat yang sedang kami bangun.',
			'account.googleSignInAction' => 'Masuk dengan Google',
			'account.emailSignInToggle' => 'Masuk dengan email',
			'account.emailFormHint' => 'Untuk akun yang sudah dibuatkan khusus untukmu.',
			'account.emailLabel' => 'Email',
			'account.passwordLabel' => 'Kata sandi',
			'account.emailSignInAction' => 'Masuk',
			'account.emailRequired' => 'Isi email dan kata sandi dulu.',
			'account.signedInMessage' => 'Kamu sudah masuk.',
			'account.signedOutMessage' => 'Kamu sudah keluar.',
			'account.methodGoogle' => 'Masuk lewat Google',
			'account.methodPassword' => 'Masuk lewat email',
			'account.dataTitle' => 'Data kamu',
			'account.dataBody' => 'Dompet, transaksi, dan anggaran tersimpan di perangkat ini. Keluar atau menghapus akun tidak menyentuhnya.',
			'account.signOutAction' => 'Keluar',
			'account.dangerTitle' => 'Zona bahaya',
			'account.dangerBody' => 'Menghapus akun bersifat permanen dan tidak bisa dibatalkan.',
			'account.deleteAction' => 'Hapus akun',
			'account.deleteConfirmTitle' => 'Hapus akun?',
			'account.deleteConfirmBody' => 'Akunmu dihapus permanen. Dompet, transaksi, dan anggaran di perangkat ini tetap ada.',
			'account.deletePasswordTitle' => 'Masukkan kata sandi',
			'account.deletePasswordBody' => 'Demi keamanan, masukkan lagi kata sandimu untuk menghapus akun.',
			'account.deletedMessage' => 'Akun dihapus.',
			'account.errors.network' => 'Tidak bisa terhubung. Periksa koneksi internetmu, lalu coba lagi.',
			'account.errors.wrongCredentials' => 'Email atau kata sandi salah.',
			'account.errors.tooManyRequests' => 'Terlalu banyak percobaan. Tunggu sebentar, lalu coba lagi.',
			'account.errors.userDisabled' => 'Akun ini dinonaktifkan.',
			'account.errors.other' => 'Gagal masuk. Coba lagi.',
			'account.recordingSection' => 'Pencatatan',
			'account.displaySection' => 'Tampilan',
			'account.hideAmountsBody' => 'Ganti angka dengan titik di semua layar, mis. saat membuka aplikasi di depan orang lain.',
			'currency.settingsTitle' => 'Pengaturan',
			'currency.label' => 'Mata uang',
			'currency.pickerTitle' => 'Pilih mata uang',
			'currency.changeTitle' => ({required Object code}) => 'Ganti ke ${code}?',
			'currency.changeBody' => ({required Object before, required Object after}) => 'Angka yang sudah dicatat tidak dikonversi, hanya simbolnya yang berganti. Contoh: ${before} akan tampil sebagai ${after}.',
			'currency.changeAction' => 'Ganti',
			'currency.changedMessage' => ({required Object code}) => 'Mata uang diganti ke ${code}.',
			'currency.names.idr' => 'Rupiah Indonesia',
			'currency.names.usd' => 'Dolar AS',
			'currency.names.eur' => 'Euro',
			'currency.names.gbp' => 'Pound Inggris',
			'currency.names.jpy' => 'Yen Jepang',
			'currency.names.cny' => 'Yuan Tiongkok',
			'currency.names.krw' => 'Won Korea Selatan',
			'currency.names.inr' => 'Rupee India',
			'currency.names.sgd' => 'Dolar Singapura',
			'currency.names.myr' => 'Ringgit Malaysia',
			'currency.names.thb' => 'Baht Thailand',
			'currency.names.php' => 'Peso Filipina',
			'currency.names.vnd' => 'Dong Vietnam',
			'currency.names.aud' => 'Dolar Australia',
			'category.builtIn.food' => 'Makan & Minum',
			'category.builtIn.groceries' => 'Belanja Harian',
			'category.builtIn.transport' => 'Transportasi',
			'category.builtIn.bills' => 'Tagihan',
			'category.builtIn.internet' => 'Pulsa & Internet',
			'category.builtIn.health' => 'Kesehatan',
			'category.builtIn.entertainment' => 'Hiburan',
			'category.builtIn.shopping' => 'Belanja',
			'category.builtIn.education' => 'Pendidikan',
			'category.builtIn.family' => 'Keluarga',
			'category.builtIn.donation' => 'Donasi',
			'category.builtIn.expenseOther' => 'Lainnya',
			'category.builtIn.salary' => 'Gaji',
			'category.builtIn.freelance' => 'Freelance',
			'category.builtIn.bonus' => 'Bonus',
			'category.builtIn.gift' => 'Hadiah',
			'category.builtIn.incomeOther' => 'Lainnya',
			'category.title' => 'Kategori',
			'category.accountEntryTitle' => 'Kategori',
			'category.accountEntryBody' => 'Atur daftar kategori pemasukan dan pengeluaran.',
			'category.expenseTab' => 'Pengeluaran',
			'category.incomeTab' => 'Pemasukan',
			'category.addAction' => 'Tambah kategori',
			'category.addTitle' => 'Kategori baru',
			'category.renameTitle' => 'Ubah kategori',
			'category.iconLabel' => 'Ikon',
			'category.iconOption' => ({required Object n}) => 'Ikon ${n}',
			'category.nameHint' => 'Nama kategori',
			'category.archiveAction' => 'Arsipkan',
			'category.restoreAction' => 'Pulihkan',
			'category.archivedSection' => 'Terarsip',
			'category.archivedHint' => 'Tidak ditawarkan di Catat, tetapi transaksi lama tetap memakainya.',
			'category.emptyActive' => 'Belum ada kategori aktif.',
			'category.archivedMessage' => ({required Object name}) => 'Kategori "${name}" diarsipkan.',
			'category.restoredMessage' => ({required Object name}) => 'Kategori "${name}" dipulihkan.',
			'language.label' => 'Bahasa',
			'language.pickerTitle' => 'Pilih bahasa',
			'language.hint' => 'Tampilan aplikasi dan bahasa ucapan',
			'notificationCapture.accountEntryTitle' => 'Catat dari notifikasi',
			'notificationCapture.accountEntryBody' => 'Catat otomatis dari notifikasi bank dan e-wallet.',
			'notificationCapture.settingsTitle' => 'Catat dari notifikasi',
			'notificationCapture.enableLabel' => 'Aktifkan',
			'notificationCapture.accessMissingTitle' => 'Butuh izin membaca notifikasi',
			'notificationCapture.accessMissingBody' => 'Tanpa izin ini, Tanukonomy tidak bisa melihat notifikasi bank.',
			'notificationCapture.accessAction' => 'Beri izin',
			'notificationCapture.accessGranted' => 'Izin notifikasi aktif',
			'notificationCapture.disclosureTitle' => 'Sebelum memberi izin',
			'notificationCapture.disclosureBody' => 'Tanukonomy akan bisa membaca notifikasi di HP-mu.\n\n• Hanya dari aplikasi yang kamu pilih dan cocok dengan filternya.\n• Notifikasi OTP tidak pernah disimpan.\n• Teks yang sulit dibaca bisa dikirim ke Gemini (Google).\n• Teks notifikasi disimpan di HP paling lama 7 hari.',
			'notificationCapture.disclosureAccept' => 'Lanjut',
			'notificationCapture.reminderPermissionDenied' => 'Izin notifikasi ditolak. Nyalakan di setelan Android untuk menerima kabar.',
			'notificationCapture.sourcesTitle' => 'Aplikasi',
			'notificationCapture.sourcesEmpty' => 'Pilih aplikasi bank atau e-wallet yang notifikasinya mau dicatat.',
			'notificationCapture.addSource' => 'Tambah aplikasi',
			'notificationCapture.sourceNoWallet' => 'Dompet belum dipilih',
			'notificationCapture.sourcePaused' => 'Dijeda',
			'notificationCapture.pickAppTitle' => 'Pilih aplikasi',
			'notificationCapture.searchApps' => 'Cari aplikasi',
			'notificationCapture.builtInPatternsBadge' => 'Pola bawaan',
			'notificationCapture.appsLoadFailed' => 'Daftar aplikasi gagal dibaca.',
			'notificationCapture.appsEmpty' => 'Tidak ada aplikasi yang cocok.',
			'notificationCapture.sourceEnabled' => 'Dengarkan aplikasi ini',
			'notificationCapture.walletLabel' => 'Dompet',
			'notificationCapture.keywordsLabel' => 'Filter',
			'notificationCapture.keywordsHint' => 'Hanya notifikasi yang memuat salah satu frasa ini yang dibaca.',
			'notificationCapture.keywordField' => 'Tambah frasa',
			'notificationCapture.addKeyword' => 'Tambah',
			'notificationCapture.patternsTitle' => 'Pola',
			'notificationCapture.patternsHint' => 'Ajari Tanukonomy membaca format notifikasi aplikasi ini.',
			'notificationCapture.patternsEmpty' => 'Belum ada pola. Tanukonomy tetap membaca dengan aturan umum.',
			'notificationCapture.builtInUnverified' => 'Bawaan · hasilnya selalu kamu cek',
			'notificationCapture.builtInVerified' => 'Bawaan',
			'notificationCapture.newPattern' => 'Buat pola dari contoh',
			'notificationCapture.removeSource' => 'Hapus aplikasi ini',
			'notificationCapture.removeSourceConfirm' => ({required Object app}) => 'Berhenti membaca notifikasi ${app}?',
			'notificationCapture.save' => 'Simpan',
			'notificationCapture.patternTitle' => 'Buat pola',
			'notificationCapture.patternSampleLabel' => 'Contoh notifikasi',
			'notificationCapture.patternSampleHint' => 'Tempel teks notifikasi di sini',
			'notificationCapture.patternInstructions' => 'Pilih penanda, lalu ketuk katanya. Ketuk lagi untuk menghapus tanda.',
			'notificationCapture.roleAmount' => 'Nominal',
			'notificationCapture.roleNote' => 'Catatan',
			'notificationCapture.roleIgnore' => 'Abaikan',
			'notificationCapture.patternKindLabel' => 'Jenis',
			'notificationCapture.kindExpense' => 'Keluar',
			'notificationCapture.kindIncome' => 'Masuk',
			'notificationCapture.kindTransferOut' => 'Transfer keluar',
			'notificationCapture.kindTransferIn' => 'Transfer masuk',
			'notificationCapture.patternCategory' => 'Kategori',
			'notificationCapture.patternNoCategory' => 'Tanpa kategori',
			'notificationCapture.patternTransferWallet' => 'Dompet lawan',
			'notificationCapture.patternLabelField' => 'Nama pola (opsional)',
			'notificationCapture.patternPreview' => ({required Object amount}) => 'Terbaca: ${amount}',
			'notificationCapture.patternInvalid' => 'Tandai satu nominal. Kata Catatan harus berurutan.',
			'notificationCapture.deletePattern' => 'Hapus pola',
			'notificationCapture.inboxTitle' => 'Kotak masuk notifikasi',
			'notificationCapture.inboxPendingTitle' => 'Perlu dicek',
			'notificationCapture.inboxAutoTitle' => 'Otomatis',
			'notificationCapture.inboxEmpty' => 'Tidak ada yang perlu dicek.',
			'notificationCapture.inboxAutoEmpty' => 'Belum ada yang tercatat otomatis.',
			'notificationCapture.inboxRetention' => 'Daftar ini disimpan 7 hari.',
			'notificationCapture.amountUnknown' => 'Nominal belum terbaca',
			'notificationCapture.possibleDuplicate' => 'Mungkin sudah tercatat',
			'notificationCapture.reviewReason.autoRecordOff' => 'Catat otomatis mati',
			'notificationCapture.reviewReason.newPattern' => 'Pola baru, cek dulu',
			'notificationCapture.reviewReason.amountUnclear' => 'Nominal belum pasti',
			'notificationCapture.reviewReason.otherCurrency' => 'Mata uang lain',
			'notificationCapture.reviewReason.kindUnclear' => 'Jenis belum pasti',
			'notificationCapture.reviewReason.walletUnknown' => 'Dompet tidak dikenali',
			'notificationCapture.reviewReason.categoryUnclear' => 'Kategori belum jelas',
			'notificationCapture.reviewReason.dateUnclear' => 'Tanggal belum pasti',
			'notificationCapture.recordAction' => 'Catat',
			'notificationCapture.dismissAction' => 'Abaikan',
			'notificationCapture.makePatternAction' => 'Buat pola dari teks ini',
			'notificationCapture.reviewAction' => 'Lihat',
			'notificationCapture.undoAction' => 'Batalkan',
			'notificationCapture.undoConfirmTitle' => 'Batalkan transaksi?',
			'notificationCapture.undoConfirm' => 'Transaksinya dihapus dan saldo dompet kembali seperti sebelumnya.',
			'notificationCapture.undone' => 'Transaksi otomatis dibatalkan.',
			'notificationCapture.dismissed' => 'Notifikasi diabaikan.',
			'notificationCapture.banner' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${n} transaksi dari notifikasi menunggu dicek', ), 
			'notificationCapture.bannerAction' => 'Cek',
			'notificationCapture.autoRecordedSnack' => ({required Object amount, required Object app}) => 'Tercatat otomatis: ${amount} · ${app}',
			'notificationCapture.autoRecordedSnackMany' => ({required Object n}) => '${n} transaksi tercatat otomatis dari notifikasi',
			'notificationCapture.reminderChannel' => 'Catat dari notifikasi',
			'notificationCapture.reminderCapturedTitle' => 'Transaksi dari {app} tertangkap',
			'notificationCapture.reminderCapturedBody' => 'Ketuk untuk melihat.',
			'notificationCapture.reminderReviewTitle' => ({required Object amount, required Object app}) => 'Cek ${amount} dari ${app}',
			'notificationCapture.reminderReviewBody' => 'Ketuk untuk mencatat.',
			'notificationCapture.reminderRecordedTitle' => ({required Object amount, required Object app}) => 'Tercatat ${amount} · ${app}',
			'notificationCapture.reminderRecordedBody' => 'Ketuk untuk melihat.',
			'notificationCapture.debugSamplesTitle' => 'Contoh teks tertangkap (debug)',
			'notificationCapture.debugSamplesHint' => 'Ketuk untuk menyalin. Samarkan sebelum dibagikan.',
			'notificationCapture.debugSamplesEmpty' => 'Belum ada notifikasi dari aplikasi terdaftar.',
			'notificationCapture.debugShellSource' => 'Tambah sumber uji adb (com.android.shell)',
			'notificationCapture.copied' => 'Disalin.',
			'notificationCapture.keywordsEmptyWarning' => 'Tanpa filter, tidak ada notifikasi yang dibaca.',
			'notificationCapture.addDefaultKeywords' => 'Pakai filter bawaan',
			'notificationCapture.sourceKeywordsNone' => 'Filter kosong — tidak ada yang dibaca',
			'notificationCapture.enableHint' => 'Transaksi dari notifikasi bank dan e-wallet yang kamu pilih dicatat untukmu.',
			'notificationCapture.inboxEntryTitle' => 'Kotak masuk',
			'notificationCapture.inboxEntryBody' => 'Cek transaksi dari notifikasi dan batalkan yang tercatat otomatis.',
			'notificationCapture.behaviorTitle' => 'Saat transaksi tertangkap',
			'notificationCapture.autoRecordLabel' => 'Catat otomatis',
			'notificationCapture.autoRecordOffHint' => 'Semua menunggu kamu cek di kotak masuk.',
			'notificationCapture.autoRecordOnHint' => 'Yang terbaca jelas langsung tersimpan. Yang ragu tetap menunggu dicek.',
			'notificationCapture.autoRecordAnyCategoryLabel' => 'Walau kategori belum terbaca',
			'notificationCapture.autoRecordAnyCategoryHint' => 'Kategori bisa kamu isi belakangan.',
			'notificationCapture.reminderLabel' => 'Kabari lewat notifikasi',
			'notificationCapture.reminderHint' => 'Muncul notifikasi tiap ada transaksi tertangkap.',
			'notificationCapture.sourceWallet' => ({required Object name}) => 'Dompet ${name}',
			'notificationCapture.walletHelp' => 'Transaksi dari aplikasi ini dicatat di dompet ini.',
			'notificationCapture.advancedTitle' => 'Filter dan pola',
			'notificationCapture.advancedHint' => 'Opsional',
			'notificationCapture.patternMarkLabel' => 'Tandai bagiannya',
			'notificationCapture.patternNotAmount' => ({required Object word}) => '"${word}" bukan nominal. Nominal memakai Rp atau titik ribuan.',
			'notificationCapture.kindTransfer' => 'Transfer',
			'notificationCapture.transferDirectionLabel' => 'Arah transfer',
			'notificationCapture.patternTransferWalletNone' => 'Belum ditentukan',
			'notificationCapture.patternTemplateToggle' => 'Sunting templat',
			'notificationCapture.moreActions' => 'Lainnya',
			'recurring.starters.salary' => 'Gaji',
			'recurring.starters.rent' => 'Kos/Sewa',
			'recurring.starters.electricity' => 'Listrik',
			'recurring.starters.internet' => 'Internet',
			'recurring.starters.bpjs' => 'BPJS',
			'recurring.starters.installment' => 'Cicilan',
			'recurring.starters.paylater' => 'Paylater',
			'recurring.starters.subscription' => 'Langganan',
			'recurring.starters.parents' => 'Kirim ke orang tua',
			'recurring.starters.arisan' => 'Arisan',
			'recurring.starters.savings' => 'Tabungan',
			'recurring.subscriptionsLine' => ({required Object perMonth, required Object perYear}) => 'Langganan ${perMonth}/bln · ${perYear}/thn',
			'recurring.approxSemantics' => ({required Object amount}) => 'kira-kira ${amount}',
			'recurring.filterAll' => ({required Object n}) => 'Semua (${n})',
			'recurring.groupPending' => 'Menunggu dicatat',
			'recurring.groupThisMonth' => 'Bulan ini',
			'recurring.groupLater' => 'Nanti',
			'recurring.groupPaused' => 'Dijeda',
			'recurring.groupEnded' => 'Selesai',
			'recurring.missedMeta' => ({required Object n}) => '${n} terlewat',
			'recurring.paymentAutoDebit' => 'autodebet',
			'recurring.paymentManual' => 'bayar sendiri',
			'recurring.priceUp' => ({required Object amount, required Object usual}) => '${amount}, biasanya ${usual}',
			'recurring.emptyTitle' => 'Belum ada rutin',
			'recurring.emptyBody' => 'Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas.',
			'recurring.filteredEmpty' => 'Belum ada rutin di sini.',
			'recurring.showAllAction' => 'Tampilkan semua',
			'recurring.addAction' => 'Tambah rutin',
			'recurring.loadError' => 'Rutin gagal dimuat.',
			'recurring.retryAction' => 'Coba lagi',
			'recurring.nextTitle' => 'Berikutnya',
			'recurring.recordedTitle' => 'Tercatat',
			'recurring.skipAction' => 'Lewati',
			'recurring.unskipAction' => 'Batal lewati',
			'recurring.editAction' => 'Ubah',
			'recurring.pauseAction' => 'Jeda',
			'recurring.resumeAction' => 'Lanjutkan',
			'recurring.endAction' => 'Akhiri',
			'recurring.deleteAction' => 'Hapus',
			'recurring.moreActions' => 'Aksi lain',
			'recurring.deleteTitle' => 'Hapus rutin?',
			'recurring.deleteBody' => 'Transaksi yang sudah tercatat tidak ikut terhapus.',
			'recurring.detailSchedule' => 'Jadwal',
			'recurring.detailWallet' => 'Dompet',
			'recurring.detailEnds' => 'Berakhir',
			'recurring.detailPayment' => 'Cara bayar',
			'recurring.detailStatus' => 'Status',
			'recurring.settingsTitle' => 'Pengaturan',
			'recurring.progressLine' => ({required Object k, required Object n}) => '${k} dari ${n} tercatat',
			'recurring.countLine' => ({required Object n}) => '${n} kali',
			'recurring.pausedLine' => 'Dijeda',
			'recurring.reminderLine' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: 'Bayar sendiri · diingatkan H−${n}', ), 
			'recurring.autoDebitLine' => 'Autodebet',
			'recurring.pausedMessage' => ({required Object name}) => '${name} dijeda.',
			'recurring.resumedMessage' => ({required Object name}) => '${name} dilanjutkan.',
			'recurring.endedMessage' => ({required Object name}) => '${name} diakhiri.',
			'recurring.deletedMessage' => ({required Object name}) => '${name} dihapus.',
			'recurring.skippedMessage' => ({required Object date}) => '${date} dilewati.',
			'recurring.priceUpdateAction' => ({required Object amount}) => 'Perbarui ke ${amount}',
			'recurring.notFound' => 'Rutin ini sudah tidak ada.',
			'recurring.noRecorded' => 'Belum ada yang tercatat.',
			'recurring.recordedMessage' => ({required Object name}) => '${name} tercatat.',
			'recurring.recordedAllMessage' => ({required Object n}) => '${n} rutin tercatat.',
			'recurring.linkedMessage' => ({required Object name}) => '${name} ditautkan.',
			'recurring.undoAction' => 'Batalkan',
			'recurring.similarTitle' => 'Sudah tercatat?',
			'recurring.similarBody' => ({required Object name, required Object amount, required Object date}) => 'Mirip ${name} ${amount} · ${date} yang sudah tercatat.',
			'recurring.linkAction' => 'Tautkan',
			'recurring.recordNewAction' => 'Catat baru',
			'recurring.recordAction' => 'Catat',
			'recurring.editFirstAction' => 'Ubah dulu',
			'recurring.recordAllAction' => 'Catat semua',
			'recurring.seeAllAction' => 'Lihat semua',
			'recurring.pendingCardTitle' => 'Menunggu dicatat',
			'recurring.unusualAmountNotice' => ({required Object usual}) => 'Biasanya ${usual}. Periksa lagi nominalnya.',
			'recurring.farDateNotice' => ({required Object date}) => 'Jadwalnya ${date}. Pastikan tanggalnya benar.',
			'recurring.occurrenceNotice' => ({required Object name, required Object date}) => 'Mencatat ${name} · ${date}',
			'recurring.matchLabel' => ({required Object name, required Object date}) => 'Cocok dengan rutin ${name} · ${date}',
			'recurring.linkedTitle' => 'Tercocok dengan rutin',
			'recurring.unlinkAction' => 'Lepaskan',
			'recurring.unlinkedMessage' => 'Tautan dilepas. Kemunculannya kembali menunggu.',
			'recurring.reminderChannelName' => 'Pengingat rutin',
			'recurring.reminderChannelDescription' => 'Tagihan dan pemasukan rutin yang jatuh tempo.',
			'recurring.reminderSoonTitle' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('id'))(n, other: '${n} hari lagi', ), 
			'recurring.reminderTodayTitle' => 'Jatuh tempo hari ini',
			'recurring.reminderTodayManyTitle' => ({required Object n}) => '${n} rutin jatuh tempo hari ini',
			'recurring.alreadyRecordedMessage' => ({required Object name}) => '${name} sudah tercatat.',
			'recurring.remindersTitle' => 'Pengingat rutin',
			'recurring.remindersBody' => 'Diingatkan sehari sebelum tagihan yang dibayar sendiri, dan pada hari jatuh tempo.',
			'recurring.remindersDenied' => 'Izin notifikasi belum diberikan. Nyalakan di setelan sistem.',
			'recurring.ruleRemindersLabel' => 'Ingatkan',
			'recurring.positionMeta' => ({required Object k, required Object n}) => '${k} dari ${n}',
			'recurring.toWalletMeta' => ({required Object wallet}) => 'ke ${wallet}',
			'recurring.remainingTitle' => ({required Object month}) => 'Sisa rutin keluar · ${month}',
			'recurring.plannedLabel' => 'Rencana',
			'recurring.outLabel' => 'Sudah keluar',
			'recurring.chipAll' => 'Semua',
			'recurring.chipIncome' => 'Masuk',
			'recurring.chipExpense' => 'Keluar',
			'recurring.chipTransfer' => 'Transfer',
			'recurring.budgetLinkLabel' => 'Pos anggaran',
			'recurring.budgetLinkNone' => 'Belum tertaut. Tautkan supaya tidak terhitung dua kali dengan anggaran.',
			'recurring.budgetLinkValue' => ({required Object item, required Object budget}) => '${item} · ${budget}',
			'recurring.budgetLinkPickerTitle' => 'Tautkan ke pos anggaran rutin',
			'recurring.budgetLinkRemove' => 'Lepas tautan',
			'recurring.budgetLinkEmpty' => 'Belum ada pos anggaran rutin di dompet ini.',
			'recurring.budgetLinkedMessage' => ({required Object name, required Object item}) => '${name} tertaut ke pos ${item}.',
			'recurring.budgetUnlinkedMessage' => ({required Object name}) => 'Tautan pos ${name} dilepas.',
			'recurring.fundingTitle' => ({required Object wallet}) => 'Siapkan dana di ${wallet}',
			'recurring.fundingBody' => ({required Object name, required Object amount, required Object date, required Object shortfall}) => '${name} ${amount}, ${date}. Perkiraan kurang ≈${shortfall}.',
			'recurring.installmentFreeLine' => ({required Object month, required Object amount}) => 'Mulai ${month} ruang bebas +${amount}/bln.',
			'recurring.unseenLabel' => 'Belum terlihat di notifikasi',
			'recurring.notYetAction' => 'Belum terjadi',
			'recurring.snoozedMessage' => ({required Object name}) => '${name} ditanyakan lagi 2 hari lagi.',
			'recurring.idleTitle' => ({required Object name}) => 'Masih memakai ${name}?',
			'recurring.idleBody' => 'Dua kemunculan terakhir dilewati atau belum terlihat.',
			'recurring.idleKeep' => 'Biarkan',
			'recurring.autoRecordedOne' => ({required Object name}) => '${name} dicatat otomatis.',
			'recurring.autoRecordedMany' => ({required Object n}) => '${n} rutin dicatat otomatis.',
			'recurring.priceUpFound' => ({required Object name, required Object amount}) => '${name} tercatat ${amount}, naik dari rutin. Tautkan?',
			'recurring.priceUpUpdate' => 'Perbarui rutin',
			'recurring.priceUpKeep' => 'Biarkan',
			'recurring.suggestTitle' => 'Sepertinya rutin',
			'recurring.suggestLine' => ({required Object name, required Object amount, required Object day}) => '${name} ${amount}, sekitar tanggal ${day} tiga bulan terakhir.',
			'recurring.suggestAccept' => 'Jadikan rutin',
			'recurring.suggestDismiss' => 'Bukan rutin',
			'recurring.autoRecordedTitle' => 'Tercatat otomatis',
			'plan.recurringSegmentLabel' => 'Rutin',
			'plan.financialMonthTitle' => 'Awal bulan keuangan',
			'plan.financialMonthDay' => ({required Object day}) => 'Tanggal ${day}',
			'plan.financialMonthLastDay' => 'Hari terakhir bulan',
			'plan.financialMonthChange' => 'Ubah awal bulan keuangan',
			_ => null,
		} ?? switch (path) {
			'plan.financialMonthHint' => 'Biasanya tanggal gajian.',
			'plan.financialMonthPreviewTitle' => ({required Object day}) => 'Mulai tanggal ${day}',
			'plan.financialMonthPreviewTitleLastDay' => 'Mulai hari terakhir bulan',
			'plan.financialMonthPreviewTransition' => ({required Object range, required Object days, required Object next}) => 'Periode ini jadi ${range} (${days} hari), lalu ${next}.',
			'plan.financialMonthPreviewPast' => 'Periode sebelumnya tidak berubah.',
			'plan.financialMonthBudgetsTitle' => 'Anggaran rutin',
			'plan.financialMonthBudgetsHelp' => ({required Object next, required Object previous}) => 'Yang dicentang ikut mulai ${next}. Yang tidak, tetap mulai ${previous}.',
			'plan.financialMonthOnDay' => ({required Object day}) => 'tanggal ${day}',
			'plan.financialMonthOnLastDay' => 'hari terakhir bulan',
			'plan.financialMonthBudgetMoved' => ({required Object until, required Object next}) => 'Berjalan sampai ${until}, berikutnya mulai ${next}',
			'plan.financialMonthBudgetKept' => ({required Object start}) => 'Tetap mulai ${start}',
			'plan.financialMonthSelectAll' => 'Pilih semua',
			'plan.financialMonthClearAll' => 'Kosongkan',
			'plan.transitionLabel' => ({required Object days}) => 'Periode peralihan · ${days} hari',
			'plan.thisMonthSegmentLabel' => 'Bulan ini',
			'plan.unplannedTitle' => ({required Object month}) => 'Uang nganggur · ${month}',
			'plan.incomeRow' => 'Pemasukan',
			'plan.billsRow' => 'Tagihan rutin',
			'plan.budgetRow' => 'Anggaran',
			'plan.offPlanRow' => 'Di luar rencana',
			'plan.infoAction' => 'Penjelasan',
			'plan.infoTitle' => 'Uang nganggur',
			'plan.infoIncome' => '+ Pemasukan terencana',
			'plan.infoBills' => '− Tagihan rutin',
			'plan.infoBudget' => '− Anggaran',
			'plan.infoOffPlan' => '± Di luar rencana (sudah tercatat)',
			'plan.infoResult' => '= Uang nganggur',
			'plan.infoNotBalance' => 'Bukan saldo dompet.',
			'plan.balanceTitle' => 'Saldo dompet ≈',
			'plan.allWallets' => 'Semua',
			'plan.endOf' => ({required Object date}) => 'Akhir ${date}',
			'plan.lowestOn' => ({required Object date}) => 'Paling tipis · ${date}',
			'plan.detailsAction' => 'Rincian',
			'plan.todayLabel' => 'hari ini',
			'plan.approx' => ({required Object amount}) => 'kira-kira ${amount}',
			'plan.detailsTitle' => 'Perkiraan saldo',
			'plan.detailsNow' => 'Saldo sekarang',
			'plan.detailsIncome' => 'Pemasukan rutin',
			'plan.detailsBills' => 'Tagihan rutin',
			'plan.detailsBudget' => 'Sisa anggaran',
			'plan.detailsUnplanned' => ({required Object perDay}) => 'Di luar rencana · ${perDay}/hari',
			'plan.detailsUncertain' => 'Freelance belum dibayar (belum pasti)',
			'plan.detailsTransfers' => 'Transfer rutin',
			'plan.detailsEnd' => ({required Object date}) => 'Akhir ${date}',
			'plan.unplannedToggle' => 'Hitung jajan harian',
			'plan.unplannedUnavailable' => 'Butuh riwayat sebulan penuh.',
			'plan.nextTitle' => 'Berikutnya',
			'plan.seeAllRecurring' => 'Semua di Rutin',
			'plan.emptyTitle' => 'Rencanakan bulan ini',
			'plan.emptyBody' => 'Tambahkan yang pasti datang tiap bulan, lalu lihat berapa yang benar-benar bebas.',
			'plan.chartSemantics' => ({required Object low, required Object date, required Object end}) => 'Perkiraan saldo, paling tipis ${low} pada ${date}, akhir bulan ${end}',
			'plan.chartPoint' => ({required Object date, required Object amount}) => '${date} · ${amount}',
			'plan.forecastEndLabel' => ({required Object date}) => 'Perkiraan saldo ${date}',
			'plan.forecastLowest' => ({required Object amount, required Object date}) => 'Terendah ${amount} pada ${date}',
			'plan.approxAmount' => ({required Object amount}) => '≈${amount}',
			'plan.loadError' => 'Rencana bulan ini gagal dimuat.',
			'plan.forecastBadge' => 'Perkiraan',
			'plan.startOf' => ({required Object date}) => 'Awal ${date}',
			'plan.compactMillion' => ({required Object value}) => '${value} jt',
			'plan.compactThousand' => ({required Object value}) => '${value} rb',
			'plan.fundingTitle' => 'Siapkan dana',
			'plan.fundingBody' => ({required Object wallet, required Object shortfall, required Object name, required Object date}) => 'Saldo ${wallet} diperkirakan kurang ≈${shortfall} saat ${name}, ${date}. Siapkan dana di ${wallet} sebelum tanggal itu.',
			'plan.fundingAction' => ({required Object wallet}) => 'Lihat perkiraan ${wallet}',
			'plan.fundingMore' => ({required Object n}) => '+${n} lainnya',
			'plan.reviewTitle' => ({required Object month}) => '${month} dimulai',
			'plan.reviewProgress' => ({required Object done, required Object total}) => '${done}/${total}',
			'plan.reviewBudgets' => ({required Object amount}) => 'Anggaran rutin bulan ini ${amount}, lahir sendiri.',
			'plan.reviewEstimate' => ({required Object name, required Object amount}) => '${name} ≈${amount}, sesuai?',
			'plan.reviewLookback' => ({required Object month}) => 'Kilas balik ${month}',
			'plan.reviewOk' => 'Sesuai',
			'plan.reviewEdit' => 'Ubah',
			'plan.reviewEditEstimate' => 'Ubah perkiraan',
			'plan.reviewSee' => 'Lihat',
			'plan.reviewDone' => 'Selesai meninjau',
			'plan.reviewLater' => 'Nanti',
			'plan.reviewCollapsed' => ({required Object month, required Object done, required Object total}) => 'Tinjau rencana ${month} (${done}/${total})',
			'plan.reviewDoneMessage' => ({required Object month}) => 'Rencana ${month} siap.',
			'plan.homeReviewBody' => ({required Object income, required Object committed, required Object free}) => 'Pemasukan terjadwal ${income}, terikat ${committed}, nganggur ${free}.',
			'plan.homeReviewEstimates' => 'Ada rutin bernominal kira-kira yang perlu dicek.',
			'plan.homeReviewAction' => 'Tinjau rencana',
			'plan.lookbackTitle' => ({required Object month}) => 'Kilas balik ${month}',
			'plan.lookbackPlanned' => 'Rencana',
			'plan.lookbackActual' => 'Nyata',
			'plan.lookbackFree' => 'Uang nganggur',
			'plan.lookbackBiggest' => ({required Object line}) => 'Selisih terbesar: ${line}.',
			'plan.accuracyExact' => ({required Object month}) => 'Perkiraan ${month} tepat.',
			'plan.accuracyMissed' => ({required Object month, required Object amount}) => 'Perkiraan ${month} meleset ${amount}.',
			'plan.accuracyMissedBy' => ({required Object month, required Object amount, required Object line}) => 'Perkiraan ${month} meleset ${amount}, terbesar dari ${line}.',
			'plan.committedShare' => ({required Object percent, required Object month}) => '${percent}% pemasukan ${month} sudah terikat (rutin + anggaran).',
			'plan.committedShareVs' => ({required Object percent, required Object month, required Object previous}) => '${percent}% pemasukan ${month} sudah terikat (rutin + anggaran); bulan sebelumnya ${previous}%.',
			'plan.installmentFree' => ({required Object name, required Object month, required Object amount}) => 'Sesudah ${name} selesai, mulai ${month} ruang bebas +${amount}/bln.',
			_ => null,
		};
	}
}
