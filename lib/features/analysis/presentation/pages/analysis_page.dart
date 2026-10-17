import 'package:flutter/material.dart';
import 'package:saldough/core/i18n/strings.g.dart';
import 'package:saldough/core/presentation/spotlight/spotlight.dart';
import 'package:saldough/core/tutorial/tutorial.dart';
import 'package:saldough/features/analysis/presentation/widgets/analysis_view.dart';

/// Analisis sebagai halaman penuh (dari kartu Arus Beranda dan kilas balik):
/// keluar lewat tombol kembali (FINANCIAL_ANALYSIS F1).
class AnalysisPage extends StatelessWidget {
  /// Membuat [AnalysisPage].
  const AnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          t.analysis.segment,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        centerTitle: false,
        actions: const [TutorialInfoButton(tour: TourId.analysis)],
      ),
      body: const SafeArea(child: AnalysisView()),
    );
  }
}
