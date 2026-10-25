import 'package:saldough/core/foundation/entitlement/entitlement.dart';
import 'package:url_launcher/url_launcher.dart';

/// Alamat langganan di Play Store untuk "Kelola di Play Store".
final Uri playSubscriptionsUri = Uri.parse('https://play.google.com/store/account/subscriptions');

/// Membuka [uri] di luar aplikasi.
Future<bool> launchPlaySubscriptions(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);

/// Pengguna sudah berlangganan lewat pembelian: paywall tidak menawarkan
/// pilihan paket lagi. Uji coba, hak promosi, dan pra-peluncuran bukan
/// langganan, jadi tetap boleh membeli bila Plus sudah dijual.
bool isSubscribed(PlanState plan) => plan is PlusPlan && plan.source == PlanSource.purchase;
