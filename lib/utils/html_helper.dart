class HtmlHelper {
  static String stripHtmlTags(String htmlString) {
    if (htmlString.isEmpty) return htmlString;
    
    // Remplacer les <br> par des sauts de ligne
    var text = htmlString.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    
    // Remplacer les fins de paragraphes suivies de débuts de paragraphes par un double saut de ligne
    text = text.replaceAll(RegExp(r'</p>\s*<p[^>]*>', caseSensitive: false), '\n\n');
    
    // Remplacer les éléments de liste par des puces
    text = text.replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '\n• ');
    
    // Supprimer toutes les autres balises HTML
    text = text.replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false), '');
    
    // Décoder les entités HTML courantes
    text = text.replaceAll('&nbsp;', ' ')
               .replaceAll('&amp;', '&')
               .replaceAll('&lt;', '<')
               .replaceAll('&gt;', '>')
               .replaceAll('&quot;', '"')
               .replaceAll('&#39;', "'");
               
    // Nettoyer les sauts de ligne excessifs (plus de 2 sauts de ligne deviennent 2)
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return text.trim();
  }
}
