class Scolarite {
  final String? branche;
  final String? rubrique;
  final String? dateLimite;
  final String? statut;
  final int? totalMontant;

  Scolarite({
    this.branche,
    this.rubrique,
    this.dateLimite,
    this.statut,
    this.totalMontant,
  });

  factory Scolarite.fromJson(Map<String, dynamic> json) {
    return Scolarite(
      branche: json['branche'] as String?,
      rubrique: json['rubrique'] as String?,
      dateLimite: json['datelimite'] as String?,
      statut: json['statut'] as String?,
      totalMontant: json['total_montant'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'branche': branche,
      'rubrique': rubrique,
      'datelimite': dateLimite,
      'statut': statut,
      'total_montant': totalMontant,
    };
  }

  bool get isAffecte => statut == 'AFF';
  bool get isNonAffecte => statut == 'NAFF';
  bool get isEcolier => statut == 'ECOLIER';
  bool get shouldDisplay => !isEcolier; // N'affiche pas les statuts ECOLIER

  String get rubriqueLibelle {
    switch (rubrique) {
      case 'INS':
        return 'Inscription';
      case 'SCO':
        return 'Scolarité';
      default:
        return rubrique ?? 'Autre';
    }
  }

  DateTime? get dateLimiteParsed {
    if (dateLimite == null || dateLimite!.isEmpty) return null;
    try {
      return DateTime.parse(dateLimite!);
    } catch (e) {
      return null;
    }
  }

  String get dateLimiteFormatee {
    final date = dateLimiteParsed;
    if (date == null) return dateLimite ?? 'Date inconnue';
    
    return '${date.day.toString().padLeft(2, '0')}-${date.month.toString().padLeft(2, '0')}-${date.year}';
  }

  @override
  String toString() {
    return 'Scolarite(branche: $branche, rubrique: $rubrique, statut: $statut, montant: $totalMontant)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Scolarite &&
        other.branche == branche &&
        other.rubrique == rubrique &&
        other.dateLimite == dateLimite &&
        other.statut == statut &&
        other.totalMontant == totalMontant;
  }

  @override
  int get hashCode {
    return branche.hashCode ^
        rubrique.hashCode ^
        dateLimite.hashCode ^
        statut.hashCode ^
        totalMontant.hashCode;
  }
}

class ScolariteResponse {
  final int currentPage;
  final List<Scolarite> data;
  final String? firstPageUrl;
  final int? from;
  final int lastPage;
  final String? lastPageUrl;
  final List<Link>? links;
  final String? nextPageUrl;
  final String? path;
  final int? perPage;
  final String? prevPageUrl;
  final int? to;
  final int total;

  ScolariteResponse({
    required this.currentPage,
    required this.data,
    this.firstPageUrl,
    this.from,
    required this.lastPage,
    this.lastPageUrl,
    this.links,
    this.nextPageUrl,
    this.path,
    this.perPage,
    this.prevPageUrl,
    this.to,
    required this.total,
  });

  factory ScolariteResponse.fromJson(Map<String, dynamic> json) {
    return ScolariteResponse(
      currentPage: json['current_page'] as int? ?? 1,
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => Scolarite.fromJson(item as Map<String, dynamic>))
          .toList() ?? [],
      firstPageUrl: json['first_page_url'] as String?,
      from: json['from'] as int?,
      lastPage: json['last_page'] as int? ?? 1,
      lastPageUrl: json['last_page_url'] as String?,
      links: (json['links'] as List<dynamic>?)
          ?.map((item) => Link.fromJson(item as Map<String, dynamic>))
          .toList(),
      nextPageUrl: json['next_page_url'] as String?,
      path: json['path'] as String?,
      perPage: json['per_page'] as int?,
      prevPageUrl: json['prev_page_url'] as String?,
      to: json['to'] as int?,
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'data': data.map((item) => item.toJson()).toList(),
      'first_page_url': firstPageUrl,
      'from': from,
      'last_page': lastPage,
      'last_page_url': lastPageUrl,
      'links': links?.map((item) => item.toJson()).toList(),
      'next_page_url': nextPageUrl,
      'path': path,
      'per_page': perPage,
      'prev_page_url': prevPageUrl,
      'to': to,
      'total': total,
    };
  }
}

class Link {
  final String? url;
  final String? label;
  final bool? active;

  Link({
    this.url,
    this.label,
    this.active,
  });

  factory Link.fromJson(Map<String, dynamic> json) {
    return Link(
      url: json['url'] as String?,
      label: json['label'] as String?,
      active: json['active'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'label': label,
      'active': active,
    };
  }
}
