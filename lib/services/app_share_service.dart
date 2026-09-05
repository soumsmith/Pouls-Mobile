import '../models/coulisse_excellence.dart';
import '../models/visite_guidee_video.dart';
import '../models/blog.dart';
import '../models/event.dart';
import '../models/astuce_conseil.dart';
import '../models/product.dart';
import '../config/app_config.dart';
import '../utils/unicode_style_normalizer.dart';

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

  // ─── Miniature pour les aperçus de lien (WhatsApp, e-mail, etc.) ──────────
  //
  // share/index.php et video/index.php sont exécutés en PHP nativement
  // (extension .php, sans dépendre d'un .htaccess AddType/AddHandler qui
  // s'est révélé non pris en compte sur l'hébergement — le serveur servait
  // le code PHP brut au lieu de l'exécuter) et lisent ces paramètres pour
  // générer dynamiquement les balises Open Graph (og:title/og:description/
  // og:image), afin que l'aperçu affiché par WhatsApp/Messenger/e-mail
  // montre la miniature réelle du contenu partagé plutôt que le logo
  // générique de l'application. Les anciens index.html restent en place en
  // simple redirection statique vers index.php, pour ne pas casser les
  // liens déjà partagés avant ce changement.
  static String _previewParams({
    required String title,
    String? desc,
    String? img,
  }) {
    final buffer = StringBuffer();

    // normalizeStylizedText : un titre en "texte stylé" (généré par les
    // outils de gras/italique Unicode des réseaux sociaux) pèse jusqu'à 4
    // octets par lettre — 12 caractères une fois encodés dans l'URL — et
    // peut à lui seul générer un lien de plusieurs centaines de caractères.
    // On ne touche qu'à ce qui part dans l'URL : le texte affiché ailleurs
    // dans l'app garde son style.
    final normalizedTitle = normalizeStylizedText(title);
    final truncatedTitle = normalizedTitle.length > 100
        ? '${normalizedTitle.substring(0, 100).trim()}…'
        : normalizedTitle;
    buffer.write('&title=${Uri.encodeQueryComponent(truncatedTitle)}');

    if (desc != null && desc.trim().isNotEmpty) {
      final cleaned = normalizeStylizedText(_stripHtmlAndFormat(desc));
      final truncated = cleaned.length > 160
          ? '${cleaned.substring(0, 160).trim()}…'
          : cleaned;
      if (truncated.isNotEmpty) {
        buffer.write('&desc=${Uri.encodeQueryComponent(truncated)}');
      }
    }
    if (img != null && img.trim().isNotEmpty) {
      buffer.write('&img=${Uri.encodeQueryComponent(img)}');
    }
    return buffer.toString();
  }

  /// Miniature YouTube pour une vidéo, à partir de son identifiant.
  static String? _youtubeThumbnail(String videoId) {
    if (videoId.isEmpty) return null;
    return 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
  }

  // ─── Génération de liens ──────────────────────────────────────────────────

  /// Génère le lien de partage pour une vidéo Coulisse d'Excellence.
  ///
  /// Inclut le code école quand il est disponible, pour que la résolution du
  /// lien côté app puisse charger la vidéo via le même appel scopé par école
  /// que la navigation classique (bien plus fiable qu'une recherche dans
  /// tout le catalogue toutes écoles confondues).
  static String buildCoulisseLink(CoulisseExcellence video) {
    var link = '$_baseUrl/share/index.php?type=coulisse&id=${video.id}';
    if (video.code.isNotEmpty) {
      link += '&ecole=${Uri.encodeQueryComponent(video.code)}';
    } else {
      print(
        '⚠️ [AppShareService] buildCoulisseLink: video.code est vide pour '
        'id=${video.id} ("${video.titre}") → lien généré sans paramètre '
        'ecole, la résolution retombera sur la recherche globale.',
      );
    }
    link += _previewParams(
      title: video.titre,
      desc: video.description,
      img: _youtubeThumbnail(video.youtubeVideoId),
    );
    print('🔗 [AppShareService] Lien coulisse généré: $link');
    return link;
  }

  /// Génère le lien de partage pour une vidéo Visite Guidée.
  ///
  /// Une vidéo "Astuce & Conseil" est aussi représentée par ce modèle
  /// (`typeVideo == 'astuce'`, voir tips_advice_screen.dart) — dans ce cas
  /// on génère un lien `type=tip`, pour que la résolution ouvre la bonne
  /// liste (Astuces & Conseils) et retrouve la vidéo dans le bon pool
  /// (l'endpoint "visiteguide" ne contient pas les astuces).
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

    final isAstuce = video.typeVideo == 'astuce';
    final type = isAstuce ? 'tip' : 'visite';
    var link = '$_baseUrl/share/index.php?type=$type&id=${video.id}';

    // Le paramètre ecole n'est utile que pour la résolution "visite guidée"
    // scopée par école (_loadVisiteGuideeVideo) — les astuces sont résolues
    // par pagination globale (_loadTip), inutile de l'ajouter dans ce cas.
    if (!isAstuce) {
      if (video.code.isNotEmpty) {
        link += '&ecole=${Uri.encodeQueryComponent(video.code)}';
      } else {
        print(
          '⚠️ [AppShareService] buildVisiteGuideeLink: video.code est vide pour '
          'id=${video.id} → lien généré sans paramètre ecole, la résolution '
          'retombera sur la recherche globale.',
        );
      }
    }

    link += _previewParams(
      title: video.title ?? (isAstuce ? 'Astuce & Conseil' : 'Visite Guidée'),
      desc: video.description,
      img: _youtubeThumbnail(video.youtubeVideoId),
    );
    print('🔗 [AppShareService] Lien ${isAstuce ? "astuce/conseil" : "visite guidée"} généré: $link');
    return link;
  }

  /// Génère le lien de partage pour un article de blog.
  static String buildArticleLink(Blog article) {
    var link = '$_baseUrl/share/index.php?type=article&id=${article.slug}';
    link += _previewParams(
      title: article.title,
      desc: article.content,
      img: article.image,
    );
    return link;
  }

  /// Génère le lien de partage pour un événement.
  static String buildEventLink(Event event) {
    var link = '$_baseUrl/share/index.php?type=event&id=${event.slug}';
    link += _previewParams(
      title: event.title,
      desc: event.content,
      img: event.image,
    );
    return link;
  }

  /// Génère le lien de partage pour une astuce/conseil.
  static String buildTipLink(AstuceConseil tip) {
    var link = '$_baseUrl/share/index.php?type=tip&id=${tip.id}';
    link += _previewParams(
      title: tip.title,
      desc: tip.content,
      img: _youtubeThumbnail(tip.youtubeVideoId) ?? tip.image,
    );
    return link;
  }

  /// Génère le lien de partage pour un produit (boutique).
  static String buildProductLink(Product product) {
    var link = '$_baseUrl/share/index.php?type=product&id=${product.id}';
    link += _previewParams(
      title: product.title,
      desc: product.description,
      img: product.imageUrl,
    );
    return link;
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

  /// Construit le texte de partage formaté, en deux sections distinctes :
  /// le contenu partagé (titre, description, lien) puis l'invitation à
  /// télécharger l'application, séparées par une ligne de séparation pour
  /// que le lecteur distingue clairement "ce qu'on partage" de "l'appel à
  /// l'action" — évite que les deux se mélangent visuellement dans les
  /// aperçus WhatsApp/e-mail.
  static String _buildShareText({
    required String title,
    required String description,
    required String link,
    required String hashtags,
    String action = 'Regardez ceci :',
  }) {
    final buffer = StringBuffer();

    // ─── Section 1 : le contenu partagé ───
    buffer.writeln('$action $title');

    final cleanedDescription = _dedupTitleInDescription(
      title: title,
      description: _stripHtmlAndFormat(description),
    );
    if (cleanedDescription.isNotEmpty) {
      buffer.writeln();
      buffer.writeln(cleanedDescription);
    }

    buffer.writeln();
    buffer.writeln('🔗 Accédez-y directement :');
    buffer.writeln(link);

    // ─── Section 2 : invitation à télécharger l'application ───
    buffer.writeln();
    buffer.writeln('▬▬▬▬▬▬▬▬▬▬▬▬▬▬▬');
    buffer.writeln();
    buffer.writeln(
      '📲 Pour aller plus loin, téléchargez "Parent Responsable" : '
      'encore plus de contenus pédagogiques comme celui-ci, et le suivi '
      'complet de la scolarité de votre enfant, en toute sérénité.',
    );
    buffer.writeln();
    buffer.writeln(AppConfig.storeUrl);

    buffer.writeln();
    buffer.write(hashtags);
    return buffer.toString();
  }

  /// Évite de répéter le titre s'il apparaît déjà en tête de la description
  /// (fréquent quand le contenu a été rédigé avec le titre repris comme
  /// première ligne), pour ne pas l'afficher deux fois de suite dans le
  /// message de partage.
  static String _dedupTitleInDescription({
    required String title,
    required String description,
  }) {
    final normalizedTitle = title.trim().toLowerCase();
    final lines = description.split('\n');
    if (lines.isNotEmpty &&
        normalizedTitle.isNotEmpty &&
        lines.first.trim().toLowerCase() == normalizedTitle) {
      return lines.skip(1).join('\n').trim();
    }
    return description;
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
