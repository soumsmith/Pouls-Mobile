import 'package:flutter/material.dart';
import '../config/app_colors.dart';

/// Widget de rendu de contenu HTML formaté (h1, h2, h3, p, strong, b, em, i, u, li, br, etc.)
class HtmlTextWidget extends StatelessWidget {
  final String html;
  final TextStyle? defaultStyle;

  const HtmlTextWidget({
    Key? key,
    required this.html,
    this.defaultStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (html.trim().isEmpty) return const SizedBox.shrink();

    final baseStyle = defaultStyle ??
        TextStyle(
          fontSize: 15.0,
          color: AppColors.screenTextPrimaryThemed(context),
          height: 1.6,
        );

    final blocks = _parseHtmlToBlocks(html, baseStyle);

    if (blocks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: blocks,
    );
  }

  static List<Widget> _parseHtmlToBlocks(String htmlString, TextStyle baseStyle) {
    List<Widget> widgets = [];

    // Décodage des entités HTML
    String cleanHtml = _decodeHtmlEntities(htmlString);

    // Expression régulière pour séparer les éléments de bloc
    final blockRegExp = RegExp(
      r'<(h[1-6]|p|li|div|ul|ol)[^>]*>(.*?)</\1>|<br\s*/?>',
      caseSensitive: false,
      dotAll: true,
    );

    Iterable<RegExpMatch> matches = blockRegExp.allMatches(cleanHtml);

    if (matches.isEmpty) {
      // Aucun bloc HTML trouvé, interprétation inline globale
      final inlineSpans = _parseInlineSpans(cleanHtml, baseStyle);
      if (inlineSpans.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: RichText(
              textAlign: TextAlign.justify,
              text: TextSpan(children: inlineSpans, style: baseStyle),
            ),
          ),
        );
      }
      return widgets;
    }

    int lastIndex = 0;

    for (final match in matches) {
      // Texte brut situé avant le bloc HTML matché
      if (match.start > lastIndex) {
        String leadingText = cleanHtml
            .substring(lastIndex, match.start)
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .trim();
        if (leadingText.isNotEmpty) {
          widgets.add(
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(leadingText, style: baseStyle, textAlign: TextAlign.justify),
            ),
          );
        }
      }
      lastIndex = match.end;

      final tag = match.group(1)?.toLowerCase();
      final innerContent = match.group(2) ?? '';

      if (tag == null) {
        // Balise <br> seule
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // Ignorer les paragraphes vides tels que <p><br></p> ou <p>&nbsp;</p>
      String strippedInner = innerContent
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '')
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .replaceAll('&nbsp;', '')
          .trim();

      if (strippedInner.isEmpty && tag == 'p') {
        continue;
      }

      TextStyle blockStyle = baseStyle;
      double topPadding = 0.0;
      double bottomPadding = 10.0;
      String prefix = '';
      TextAlign alignment = TextAlign.justify;

      switch (tag) {
        case 'h1':
          blockStyle = baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 15) * 1.25,
            fontWeight: FontWeight.w700,
            height: 1.3,
          );
          topPadding = 14.0;
          bottomPadding = 6.0;
          alignment = TextAlign.left;
          break;
        case 'h2':
          blockStyle = baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 15) * 1.15,
            fontWeight: FontWeight.w700,
            height: 1.3,
          );
          topPadding = 12.0;
          bottomPadding = 5.0;
          alignment = TextAlign.left;
          break;
        case 'h3':
          blockStyle = baseStyle.copyWith(
            fontSize: (baseStyle.fontSize ?? 15) * 1.06,
            fontWeight: FontWeight.w600,
            height: 1.3,
          );
          topPadding = 10.0;
          bottomPadding = 4.0;
          alignment = TextAlign.left;
          break;
        case 'h4':
        case 'h5':
        case 'h6':
          blockStyle = baseStyle.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.3,
          );
          topPadding = 8.0;
          bottomPadding = 3.0;
          alignment = TextAlign.left;
          break;
        case 'li':
          prefix = '• ';
          bottomPadding = 6.0;
          alignment = TextAlign.justify;
          break;
        case 'p':
        default:
          bottomPadding = 10.0;
          alignment = TextAlign.justify;
          break;
      }

      final spans = _parseInlineSpans(innerContent, blockStyle);

      if (spans.isNotEmpty) {
        List<InlineSpan> finalSpans = [];
        if (prefix.isNotEmpty) {
          finalSpans.add(
            TextSpan(
              text: prefix,
              style: blockStyle.copyWith(fontWeight: FontWeight.bold),
            ),
          );
        }
        finalSpans.addAll(spans);

        widgets.add(
          Padding(
            padding: EdgeInsets.only(top: topPadding, bottom: bottomPadding),
            child: RichText(
              textAlign: alignment,
              text: TextSpan(children: finalSpans, style: blockStyle),
            ),
          ),
        );
      }
    }

    // Texte restant après le dernier match
    if (lastIndex < cleanHtml.length) {
      String trailingText = cleanHtml
          .substring(lastIndex)
          .replaceAll(RegExp(r'<[^>]*>'), '')
          .trim();
      if (trailingText.isNotEmpty) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(trailingText, style: baseStyle, textAlign: TextAlign.justify),
          ),
        );
      }
    }

    return widgets;
  }

  static List<InlineSpan> _parseInlineSpans(String content, TextStyle currentStyle) {
    List<InlineSpan> spans = [];

    // Expression régulière pour les balises inline (strong, b, em, i, u, span, br)
    final inlineRegex = RegExp(
      r'<(strong|b|em|i|u|span)[^>]*>(.*?)</\1>|<br\s*/?>',
      caseSensitive: false,
      dotAll: true,
    );

    int lastIndex = 0;
    Iterable<RegExpMatch> matches = inlineRegex.allMatches(content);

    for (final match in matches) {
      if (match.start > lastIndex) {
        String plainText = content
            .substring(lastIndex, match.start)
            .replaceAll(RegExp(r'<[^>]*>'), '');
        if (plainText.isNotEmpty) {
          spans.add(TextSpan(text: plainText, style: currentStyle));
        }
      }
      lastIndex = match.end;

      final tag = match.group(1)?.toLowerCase();
      final innerText = match.group(2) ?? '';

      if (tag == null) {
        spans.add(const TextSpan(text: '\n'));
        continue;
      }

      TextStyle innerStyle = currentStyle;
      if (tag == 'strong' || tag == 'b') {
        innerStyle = innerStyle.copyWith(fontWeight: FontWeight.bold);
      } else if (tag == 'em' || tag == 'i') {
        innerStyle = innerStyle.copyWith(fontStyle: FontStyle.italic);
      } else if (tag == 'u') {
        innerStyle = innerStyle.copyWith(decoration: TextDecoration.underline);
      }

      // Analyse récursive pour les balises imbriquées (ex: <h1><strong>Texte</strong></h1>)
      spans.addAll(_parseInlineSpans(innerText, innerStyle));
    }

    if (lastIndex < content.length) {
      String plainText = content
          .substring(lastIndex)
          .replaceAll(RegExp(r'<[^>]*>'), '');
      if (plainText.isNotEmpty) {
        spans.add(TextSpan(text: plainText, style: currentStyle));
      }
    }

    return spans;
  }

  static String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&apos;', "'");
  }
}

/// Widget extensible pour les textes HTML longs avec bouton "Lire la suite" / "Voir moins"
class ExpandableHtmlTextWidget extends StatefulWidget {
  final String html;
  final double maxHeight;
  final TextStyle? style;
  final Color? accentColor;

  const ExpandableHtmlTextWidget({
    Key? key,
    required this.html,
    this.maxHeight = 220,
    this.style,
    this.accentColor,
  }) : super(key: key);

  @override
  State<ExpandableHtmlTextWidget> createState() => _ExpandableHtmlTextWidgetState();
}

class _ExpandableHtmlTextWidgetState extends State<ExpandableHtmlTextWidget> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.maxHeight),
            child: ClipRect(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: HtmlTextWidget(
                      html: widget.html,
                      defaultStyle: widget.style,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.screenCardThemed(context).withOpacity(0.0),
                            AppColors.screenCardThemed(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          secondChild: HtmlTextWidget(
            html: widget.html,
            defaultStyle: widget.style,
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _expanded ? 'Voir moins' : 'Lire la suite',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
              const SizedBox(width: 3),
              AnimatedRotation(
                duration: const Duration(milliseconds: 250),
                turns: _expanded ? 0.5 : 0,
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
