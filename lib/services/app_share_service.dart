import '../models/coulisse_excellence.dart';
import '../models/visite_guidee_video.dart';
import '../models/blog.dart';
import '../models/event.dart';
import '../models/astuce_conseil.dart';
import '../models/product.dart';
import '../config/app_config.dart';

/// Service de génération de liens de partage pour l'application.
///
/// Génère des liens interceptables par les Universal Links (iOS) et App Links (Android)
/// pour ouvrir directement le contenu dans l'application.
class AppShareService {
  // ─── Configuration ────────────────────────────────────────────────────────
  static String get _baseUrl {
    final uri = Uri.parse(AppConfig.VIE_ECOLES_API_BASE_URL);
    return '${uri.scheme}://${uri.host}/deep-link-hosting';
  }

  // ─── Génération de liens ──────────────────────────────────────────────────

  /// Génère le lien de partage pour une vidéo Coulisse d'Excellence.
  ///
  /// Inclut le code école quand il est disponible, pour que la résolution du
  /// lien côté app puisse charger la vidéo via le même appel scopé par école
  /// que la navigation classique (bien plus fiable qu'une recherche dans
  /// tout le catalogue toutes écoles confondues).
  static String buildCoulisseLink(CoulisseExcellence video) {
    var link = '$_baseUrl/share/index.html?type=coulisse&id=${video.id}';
    if (video.code.isNotEmpty) {
      link += '&ecole=${Uri.encodeQueryComponent(video.code)}';
    } else {
      print(
        '⚠️ [AppShareService] buildCoulisseLink: video.code est vide pour '
        'id=${video.id} ("${video.titre}") → lien généré sans paramètre '
        'ecole, la résolution retombera sur la recherche globale.',
      );
    }
    print('🔗 [AppShareService] Lien coulisse généré: $link');
    return link;
  }

  /// Génère le lien de partage pour une vidéo Visite Guidée.
  ///
  /// Retourne `null` si la vidéo n'a pas d'identifiant exploitable (cas rare
  /// où `video.id` est absent) — appelant responsable d'empêcher le partage
  /// dans ce cas plutôt que de générer un lien cassé (`id=null`).
  static String? buildVisiteGuideeLink(VisiteGuideeVideo video) {
    if (video.id == null) {
      print(
        '⚠️ [AppShareService] buildVisiteGuideeLink: video.id est null '
        '(typeVideo="${video.typeVideo}", title="${video.title}") → partage refusé.',
      );
      return null;
    }
    var link = '$_baseUrl/share/index.html?type=visite&id=${video.id}';
    if (video.code.isNotEmpty) {
      link += '&ecole=${Uri.encodeQueryComponent(video.code)}';
    } else {
      print(
        '⚠️ [AppShareService] buildVisiteGuideeLink: video.code est vide pour '
        'id=${video.id} → lien généré sans paramètre ecole, la résolution '
        'retombera sur la recherche globale.',
      );
    }
    print('🔗 [AppShareService] Lien visite guidée généré: $link');
    return link;
  }

  /// Génère le lien de partage pour un article de blog.
  static String buildArticleLink(Blog article) {
    return '$_baseUrl/share/index.html?type=article&id=${article.slug}';
  }

  /// Génère le lien de partage pour un événement.
  static String buildEventLink(Event event) {
    return '$_baseUrl/share/index.html?type=event&id=${event.slug}';
  }

  /// Génère le lien de partage pour une astuce/conseil.
  static String buildTipLink(AstuceConseil tip) {
    return '$_baseUrl/share/index.html?type=tip&id=${tip.id}';
  }

  /// Génère le lien de partage pour un produit (boutique).
  static String buildProductLink(Product product) {
    return '$_baseUrl/share/index.html?type=product&id=${product.id}';
  }

  // ─── Textes de partage ────────────────────────────────────────────────────

  /// Construit le texte de partage complet pour une vidéo Coulisse.
  static String buildCoulisseShareText(CoulisseExcellence video) {
    final link = buildCoulisseLink(video);
    return _buildShareText(
      title: video.titre,
      description: video.description,
      link: link,
      hashtags: '#CoulissesExcellence #Éducation #ParentResponsable',
    );
  }

  /// Construit le texte de partage complet pour une vidéo Visite Guidée.
  /// Retourne `null` si la vidéo n'a pas d'identifiant exploitable (voir
  /// [buildVisiteGuideeLink]) — l'appelant doit alors empêcher le partage.
  static String? buildVisiteGuideeShareText(VisiteGuideeVideo video) {
    final link = buildVisiteGuideeLink(video);
    if (link == null) return null;
    final title = video.title ?? 'Visite Guidée';
    final description = video.description ?? '';
    return _buildShareText(
      title: title,
      description: description,
      link: link,
      hashtags: '#VisiteGuidée #Éducation #ParentResponsable',
      action: '🎬 Regarde cette vidéo incroyable :',
    );
  }

  /// Construit le texte de partage pour un article de blog.
  static String buildArticleShareText(Blog article) {
    final link = buildArticleLink(article);
    final title = article.title ?? 'Article';
    final description = article.content;
    return _buildShareText(
      title: title,
      description: description,
      link: link,
      hashtags: '#Blog #Éducation #ParentResponsable',
      action: '📰 Lisez cet article intéressant :',
    );
  }

  /// Construit le texte de partage pour un événement.
  static String buildEventShareText(Event event) {
    final link = buildEventLink(event);
    final title = event.title ?? 'Événement';
    final description = event.content;
    return _buildShareText(
      title: title,
      description: description,
      link: link,
      hashtags: '#Événement #École #ParentResponsable',
      action: '📅 Découvrez cet événement à venir :',
    );
  }

  /// Construit le texte de partage pour une astuce.
  static String buildTipShareText(AstuceConseil tip) {
    final link = buildTipLink(tip);
    final title = tip.title ?? 'Astuce';
    final description = tip.content ?? '';
    return _buildShareText(
      title: title,
      description: description,
      link: link,
      hashtags: '#Astuce #Conseil #ParentResponsable',
      action: '💡 Découvrez ce conseil utile :',
    );
  }

  /// Construit le texte de partage pour un produit.
  static String buildProductShareText(Product product) {
    final link = buildProductLink(product);
    final title = product.title;
    final description = product.description;
    return _buildShareText(
      title: title,
      description: description,
      link: link,
      hashtags: '#Boutique #MatérielScolaire #ParentResponsable',
      action: '🛍️ Découvrez ce produit :',
    );
  }

  /// Construit le texte de partage formaté.
  static String _buildShareText({
    required String title,
    required String description,
    required String link,
    required String hashtags,
    String action = 'Regardez ceci :',
  }) {
    final buffer = StringBuffer();
    buffer.writeln('$action $title');
    
    if (description.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(_stripHtmlAndFormat(description));
    }
    
    buffer.writeln();
    buffer.writeln('👉 Cliquez ici : $link');
    buffer.writeln();
    buffer.writeln('📲 Téléchargez l\'application ici : ${AppConfig.storeUrl}');
    buffer.writeln();
    buffer.write(hashtags);
    return buffer.toString();
  }

  /// Nettoie les balises HTML et structure le texte en paragraphes.
  static String _stripHtmlAndFormat(String text) {
    // Remplace les sauts de ligne HTML par des retours à la ligne
    String formatted = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    // Remplace les fins de paragraphe par un double retour à la ligne
    formatted = formatted.replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n');
    // Supprime toutes les autres balises HTML restantes
    formatted = formatted.replaceAll(RegExp(r'<[^>]*>', multiLine: true, caseSensitive: false), '');
    // Nettoie les espaces multiples et les retours à la ligne excessifs (max 2)
    formatted = formatted.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    
    return formatted.trim();
  }
}
