import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
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
  late final Widget _pdfWidget = widget.pdfUrl.startsWith('assets/')
      ? SfPdfViewer.asset(
          widget.pdfUrl,
          key: _pdfViewerKey,
          onDocumentLoaded: _onDocumentLoaded,
          onDocumentLoadFailed: _onDocumentLoadFailed,
          onPageChanged: _onPageChanged,
          canShowScrollHead: true,
          canShowScrollStatus: true,
          enableDoubleTapZooming: true,
          pageLayoutMode: PdfPageLayoutMode.continuous,
        )
      : widget.pdfUrl.startsWith('http')
          ? SfPdfViewer.network(
              widget.pdfUrl,
              key: _pdfViewerKey,
              onDocumentLoaded: _onDocumentLoaded,
              onDocumentLoadFailed: _onDocumentLoadFailed,
              onPageChanged: _onPageChanged,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
              pageLayoutMode: PdfPageLayoutMode.continuous,
            )
          : SfPdfViewer.file(
              File(widget.pdfUrl),
              key: _pdfViewerKey,
              onDocumentLoaded: _onDocumentLoaded,
              onDocumentLoadFailed: _onDocumentLoadFailed,
              onPageChanged: _onPageChanged,
              canShowScrollHead: true,
              canShowScrollStatus: true,
              enableDoubleTapZooming: true,
              pageLayoutMode: PdfPageLayoutMode.continuous,
            );

  void _onDocumentLoaded(PdfDocumentLoadedDetails details) {
    if (!mounted) return;
    setState(() {
      totalPages = details.document.pages.count;
      isLoading = false;
    });
  }

  void _onDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    if (!mounted) return;
    setState(() {
      errorMessage = details.description;
      isLoading = false;
    });
  }

  void _onPageChanged(PdfPageChangedDetails details) {
    _pageNotifier.value = details.newPageNumber;
  }

  @override
  void dispose() {
    _pageNotifier.dispose();
    super.dispose();
  }

  void _downloadPdf() async {
    if (!widget.pdfUrl.startsWith('http') && !widget.pdfUrl.startsWith('assets/')) {
      final file = File(widget.pdfUrl);
      if (await file.exists()) {
        await Share.shareXFiles([XFile(file.path)], text: 'Mon ticket');
      }
    } else {
      Share.share(widget.pdfUrl, subject: 'Mon ticket');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       backgroundColor: AppColors.screenBg(context),
      body: CustomScrollView(
        slivers: [
          CustomSliverAppBar(
            title: widget.title,
            pinned: true,
            floating: false,
            elevation: 0,
            backgroundColor: AppColors.screenBg(context),
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.file_download_outlined),
                onPressed: _downloadPdf,
                tooltip: 'Télécharger / Partager',
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverFillRemaining(
            child: Container(
              color: AppColors.screenBg(context),
              child: errorMessage != null
                  ? _buildErrorState()
                  : Stack(
                      children: [
                        // Le viewer ne rebuild JAMAIS grâce au late final
                        SfPdfViewerTheme(
                          data: SfPdfViewerThemeData(
                            backgroundColor: AppColors.screenBg(context),
                          ),
                          child: _pdfWidget,
                        ),

                        // Loader overlay — disparaît une fois le doc chargé
                        if (isLoading)
                          Container(
                            color: AppColors.screenBg(context),
                            child: Center(
                              child: CustomLoader(
                                message: 'Chargement du PDF...',
                                loaderColor: AppColors.screenOrange,
                                size: 56.0,
                                showBackground: false,
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
