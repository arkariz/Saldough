/// Offering RevenueCat yang ditawarkan (ADR-041 §3.5). [id] adalah
/// identifier offering di dasbor RevenueCat.
enum OfferingId {
  /// Harga biasa (bulanan dan tahunan).
  standard('default'),

  /// Harga Pendiri: tahunan terkunci selamanya, hanya selama jendela
  /// `founder_until` (90 hari sejak rilis publik).
  founder('founder'),

  /// Penawaran 48 jam sesudah uji coba berakhir: harga perkenalan tahun
  /// pertama (KT-P12).
  postTrial('post_trial');

  const OfferingId(this.id);

  /// Identifier di RevenueCat.
  final String id;
}

/// Memilih offering untuk saat ini (ADR-041 §3.5): [OfferingId.founder] bila
/// jendela Pendiri belum lewat ([founderUntil]), lalu [OfferingId.postTrial]
/// dalam [postTrialHours] jam sesudah uji coba berakhir, selain itu
/// [OfferingId.standard]. Pendiri didahulukan karena harganya terkunci
/// selamanya, jadi lebih baik bagi pembeli.
///
/// [trialEndsOn] adalah hari terakhir uji coba (inklusif); penawaran mulai
/// tengah malam sesudahnya. Murni: tidak membaca jam.
OfferingId selectOffering({
  required DateTime now,
  required int postTrialHours,
  DateTime? founderUntil,
  DateTime? trialEndsOn,
}) {
  if (founderUntil != null && !now.isAfter(founderUntil)) {
    return OfferingId.founder;
  }
  if (trialEndsOn != null) {
    final from = DateTime(
      trialEndsOn.year,
      trialEndsOn.month,
      trialEndsOn.day + 1,
    );
    final until = from.add(Duration(hours: postTrialHours));
    if (!now.isBefore(from) && now.isBefore(until)) return OfferingId.postTrial;
  }
  return OfferingId.standard;
}
