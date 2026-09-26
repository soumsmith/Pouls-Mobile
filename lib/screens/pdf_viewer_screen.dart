import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:file_picker/file_picker.dart';
import 'package:parents_responsable/utils/app_http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import '../config/app_colors.dart';
import '../utils/notification_helper.dart';
import '../widgets/custom_sliver_app_bar.dart';
import '../widgets/custom_loader.dart';
import '../widgets/components/custom_error_state.dart';

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
  GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();

  // ValueNotifier pour le numéro de page → pas de setState → pas de rebuild du viewer
  late final ValueNotifier<int> _pageNotifier = ValueNotifier(0);

  late Widget _pdfWidget;

  @override
  void initState() {
    super.initState();
    _initPdfWidget();
  }

  void _initPdfWidget() {
    _pdfViewerKey = GlobalKey();
    _pdfWidget = widget.pdfUrl.startsWith('assets/')
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
  }

  void _retryLoading() {
    setState(() {
      isLoading = true;
      errorMessage = null;
      _initPdfWidget();
    });
  }

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

  bool _isDownloading = false;

  /// Enregistre le PDF directement sur l'appareil via le sélecteur natif
  /// (« Sur mon iPhone », iCloud Drive, stockage Android...) plutôt que de
  /// passer par la feuille de partage : c'est un vrai téléchargement, pas
  /// juste un envoi vers une autre app.
  Future<void> _downloadPdf() async {
    if (_isDownloading) return;
    setState(() => _isDownloading = true);
    try {
      final Uint8List bytes;
      if (widget.pdfUrl.startsWith('http')) {
        final response = await http.get(Uri.parse(widget.pdfUrl));
        if (response.statusCode != 200) {
          throw Exception('Erreur ${response.statusCode} lors du téléchargement');
        }
        bytes = response.bodyBytes;
      } else if (widget.pdfUrl.startsWith('assets/')) {
        final data = await rootBundle.load(widget.pdfUrl);
        bytes = data.buffer.asUint8List();
      } else {
        final file = File(widget.pdfUrl);
        if (!await file.exists()) {
          throw Exception('Fichier introuvable');
        }
        bytes = await file.readAsBytes();
      }

      final sanitizedTitle = widget.title.trim().isEmpty
          ? 'document'
          : widget.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
      final fileName = sanitizedTitle.toLowerCase().endsWith('.pdf')
          ? sanitizedTitle
          : '$sanitizedTitle.pdf';

      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );

      if (!mounted) return;
      if (savedPath != null) {
        NotificationHelper.showSuccess('PDF enregistré sur votre appareil');
      }
    } catch (e) {
      if (!mounted) return;
      NotificationHelper.showError(
        'Impossible de télécharger le PDF : ${e.toString().replaceFirst('Exception: ', '')}',
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
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
            surfaceTintColor: Colors.transparent,
            actions: [
              IconButton(
                icon: _isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined),
                onPressed: _isDownloading ? null : _downloadPdf,
                tooltip: 'Télécharger',
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
    return CustomErrorState(
      title: 'Erreur de chargement',
      message: errorMessage ?? 'Impossible de charger le fichier PDF',
      onRetry: _retryLoading,
      buttonIsLight: true,
      buttonWidth: 200,
    );
  }
}
