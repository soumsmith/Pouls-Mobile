import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdfx/pdfx.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
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
  String? localFilePath;
  PdfController? _pdfController;

  @override
  void initState() {
    super.initState();
    _loadAndPreparePDF();
  }

  Future<void> _loadAndPreparePDF() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Download PDF from URL
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        // Get temporary directory
        final tempDir = await getTemporaryDirectory();
        final fileName = widget.pdfUrl.split('/').last ?? 'document.pdf';
        final file = File('${tempDir.path}/$fileName');

        // Write PDF to local file
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          localFilePath = file.path;
          _pdfController = PdfController(
            document: PdfDocument.openFile(file.path),
          );
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage =
              'Impossible de télécharger le PDF (Code: ${response.statusCode})';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement du PDF: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return CustomScrollView(
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
            child: isLoading
                ? Center(
                    child: CustomLoader(
                    message: 'Chargement du PDF...',
                    loaderColor: AppColors.screenOrange,
                    size: 56.0,
                    showBackground: true,
                    backgroundColor: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.grey[800] 
                        : Colors.white,
                  ),
                  )
                : errorMessage != null
                ? _buildErrorState()
                : Container(
                    child: _pdfController != null
                        ? PdfView(
                            controller: _pdfController!,
                            builders: PdfViewBuilders<DefaultBuilderOptions>(
                              options: const DefaultBuilderOptions(),
                              documentLoaderBuilder: (_) => Center(
                                child: CustomLoader(
                                  message: 'Chargement du document...',
                                  loaderColor: AppColors.screenOrange,
                                  size: 40.0,
                                  showBackground: false,
                                ),
                              ),
                              pageLoaderBuilder: (_) => Center(
                                child: CustomLoader(
                                  message: 'Chargement de la page...',
                                  loaderColor: AppColors.screenOrange,
                                  size: 32.0,
                                  showBackground: false,
                                ),
                              ),
                            ),
                            onPageChanged: (page) {
                              print('Page actuelle: ${page + 1}');
                            },
                          )
                        : const Center(child: Text('PDF non disponible')),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.error_outline, size: 40, color: Colors.red[600]),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Retour'),
          ),
        ],
      ),
    );
  }
}
