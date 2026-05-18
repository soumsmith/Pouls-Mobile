import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../config/app_colors.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/custom_loader.dart';

class PDFViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String title;

  const PDFViewerScreen({super.key, required this.pdfUrl, required this.title});

  @override
  State<PDFViewerScreen> createState() => _PDFViewerScreenState();
}

class _PDFViewerScreenState extends State<PDFViewerScreen> {
  bool isLoading = true;
  String? errorMessage;
  int totalPages = 0;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  // ValueNotifier pour le numéro de page → pas de setState → pas de rebuild du viewer
  late final ValueNotifier<int> _pageNotifier = ValueNotifier(0);

  // Widget PDF construit une seule fois via late final → jamais rebuild → plus de clignotement
  late final Widget _pdfWidget = SfPdfViewer.network(
    widget.pdfUrl,
    key: _pdfViewerKey,
    onDocumentLoaded: (PdfDocumentLoadedDetails details) {
      if (!mounted) return;
      setState(() {
        totalPages = details.document.pages.count;
        isLoading = false;
      });
    },
    onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
      if (!mounted) return;
      setState(() {
        errorMessage = details.description;
        isLoading = false;
      });
    },
    onPageChanged: (PdfPageChangedDetails details) {
      // ValueNotifier → pas de setState → pas de rebuild du viewer
      _pageNotifier.value = details.newPageNumber;
    },
    canShowScrollHead: true,
    canShowScrollStatus: true,
    enableDoubleTapZooming: true,
    pageLayoutMode: PdfPageLayoutMode.continuous,
  );

  @override
  void dispose() {
    _pageNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: widget.title,
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: AppColors.screenBg(context),
            surfaceTintColor: Colors.transparent,
          ),
          SliverFillRemaining(
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.black
                  : Colors.white,
              child: errorMessage != null
                  ? _buildErrorState()
                  : Stack(
                      children: [
                        // Le viewer ne rebuild JAMAIS grâce au late final
                        _pdfWidget,

                        // Loader overlay — disparaît une fois le doc chargé
                        if (isLoading)
                          Container(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                ? Colors.black
                                : Colors.white,
                            child: Center(
                              child: CustomLoader(
                                message: 'Chargement du PDF...',
                                loaderColor: AppColors.screenOrange,
                                size: 56.0,
                                showBackground: true,
                                backgroundColor:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[800]
                                    : Colors.white,
                              ),
                            ),
                          ),

                        // Indicateur de page isolé — se met à jour sans toucher au viewer
                        if (!isLoading && totalPages > 0)
                          Positioned(
                            bottom: 16,
                            right: 16,
                            child: ValueListenableBuilder<int>(
                              valueListenable: _pageNotifier,
                              builder: (context, page, _) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${page + 1} / $totalPages',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.error_outline,
                        size: 40,
                        color: Colors.red[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Erreur de chargement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.screenTextPrimaryThemed(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage ?? 'Impossible de charger le fichier PDF',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.screenTextSecondaryThemed(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.screenOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Retour'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
