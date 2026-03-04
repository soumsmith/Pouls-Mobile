import '../models/parent_suggestion.dart';

abstract class ParentSuggestionService {
  /// Récupère toutes les suggestions d'un parent
  Future<List<ParentSuggestion>> getParentSuggestions(String parentId);
  
  /// Récupère toutes les suggestions pour un établissement
  Future<List<ParentSuggestion>> getEstablishmentSuggestions(String establishmentId);
  
  /// Récupère les suggestions par catégorie
  Future<List<ParentSuggestion>> getSuggestionsByCategory(SuggestionCategory category);
  
  /// Récupère les suggestions par statut
  Future<List<ParentSuggestion>> getSuggestionsByStatus(SuggestionStatus status);
  
  /// Récupère les suggestions récentes
  Future<List<ParentSuggestion>> getRecentSuggestions(int limit);
  
  /// Récupère les suggestions les plus votées
  Future<List<ParentSuggestion>> getTopVotedSuggestions(int limit);
  
  /// Crée une nouvelle suggestion
  Future<bool> createSuggestion(ParentSuggestion suggestion);
  
  /// Met à jour une suggestion existante
  Future<bool> updateSuggestion(ParentSuggestion suggestion);
  
  /// Supprime une suggestion
  Future<bool> deleteSuggestion(String suggestionId);
  
  /// Vote pour une suggestion (upvote)
  Future<bool> upvoteSuggestion(String suggestionId, String parentId);
  
  /// Vote contre une suggestion (downvote)
  Future<bool> downvoteSuggestion(String suggestionId, String parentId);
  
  /// Récupère les statistiques des suggestions
  Future<SuggestionStats> getSuggestionStats(String period, {String? establishmentId});
  
  /// Recherche des suggestions
  Future<List<ParentSuggestion>> searchSuggestions(String query, {
    SuggestionCategory? category,
    SuggestionStatus? status,
    SuggestionPriority? priority,
    String? establishmentId,
  });
  
  /// Exporte les suggestions au format CSV
  Future<String> exportSuggestionsToCSV({
    String? establishmentId,
    DateTime? startDate,
    DateTime? endDate,
  });
}

class MockParentSuggestionService implements ParentSuggestionService {
  static final MockParentSuggestionService _instance = MockParentSuggestionService._internal();
  factory MockParentSuggestionService() => _instance;
  MockParentSuggestionService._internal();

  static final List<ParentSuggestion> _mockSuggestions = [
    ParentSuggestion(
      id: '1',
      parentId: 'parent1',
      parentName: 'Marie Dupont',
      childId: 'child1',
      childName: 'Jean Dupont',
      title: 'Améliorer la cantine scolaire',
      description: 'Il serait bénéfique d\'ajouter plus d\'options végétariennes et de proposer des menus équilibrés. Les enfants actuels se plaignent du manque de variété.',
      category: SuggestionCategory.nutrition,
      type: SuggestionType.improvement,
      priority: SuggestionPriority.medium,
      status: SuggestionStatus.underReview,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 2)),
      reviewedBy: 'Directeur',
      reviewComment: 'Excellente suggestion, nous étudions les options avec notre service de restauration.',
      upvotes: 15,
      downvotes: 2,
      establishmentId: 'school1',
      establishmentName: 'École Primaire Jean Jaurès',
      targetDepartment: 'Restauration',
    ),
    ParentSuggestion(
      id: '2',
      parentId: 'parent2',
      parentName: 'Pierre Martin',
      childId: 'child2',
      childName: 'Sophie Martin',
      title: 'Installer des caméras de sécurité',
      description: 'Pour renforcer la sécurité des élèves, il faudrait installer des caméras aux points d\'entrée et de sortie de l\'établissement.',
      category: SuggestionCategory.security,
      type: SuggestionType.newFeature,
      priority: SuggestionPriority.high,
      status: SuggestionStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
      reviewedBy: 'Conseil d\'administration',
      reviewComment: 'Projet approuvé, budget en cours d\'allocation.',
      upvotes: 25,
      downvotes: 5,
      establishmentId: 'school1',
      establishmentName: 'École Primaire Jean Jaurès',
      targetDepartment: 'Administration',
    ),
    ParentSuggestion(
      id: '3',
      parentId: 'parent3',
      parentName: 'Sophie Bernard',
      childId: 'child3',
      childName: 'Lucas Bernard',
      title: 'Créer un club de programmation',
      description: 'Proposer des activités de programmation et de robotique pour initier les enfants au codage dès le primaire.',
      category: SuggestionCategory.activities,
      type: SuggestionType.idea,
      priority: SuggestionPriority.medium,
      status: SuggestionStatus.pending,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      upvotes: 8,
      downvotes: 1,
      establishmentId: 'school2',
      establishmentName: 'Collège Victor Hugo',
      targetDepartment: 'Activités périscolaires',
    ),
    ParentSuggestion(
      id: '4',
      parentId: 'parent1',
      parentName: 'Marie Dupont',
      childId: 'child1',
      childName: 'Jean Dupont',
      title: 'Problème de chauffage dans la classe B12',
      description: 'La classe B12 est souvent froide, surtout en hiver. Les élèves ont du mal à se concentrer.',
      category: SuggestionCategory.infrastructure,
      type: SuggestionType.problem,
      priority: SuggestionPriority.urgent,
      status: SuggestionStatus.implemented,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 7)),
      reviewedBy: 'Service technique',
      reviewComment: 'Problème résolu, nouveau système de chauffage installé.',
      upvotes: 12,
      downvotes: 0,
      establishmentId: 'school1',
      establishmentName: 'École Primaire Jean Jaurès',
      targetDepartment: 'Maintenance',
    ),
    ParentSuggestion(
      id: '5',
      parentId: 'parent4',
      parentName: 'Thomas Petit',
      childId: 'child4',
      childName: 'Emma Petit',
      title: 'Application mobile pour les parents',
      description: 'Développer une application mobile pour suivre les devoirs, les notes et les communications avec les enseignants.',
      category: SuggestionCategory.technology,
      type: SuggestionType.newFeature,
      priority: SuggestionPriority.high,
      status: SuggestionStatus.underReview,
      createdAt: DateTime.now().subtract(const Duration(days: 7)),
      upvotes: 30,
      downvotes: 3,
      isAnonymous: true,
      establishmentId: 'school1',
      establishmentName: 'École Primaire Jean Jaurès',
      targetDepartment: 'Informatique',
    ),
    ParentSuggestion(
      id: '6',
      parentId: 'parent5',
      parentName: 'Isabelle Laurent',
      childId: 'child5',
      childName: 'Hugo Laurent',
      title: 'Féliciter le personnel enseignant',
      description: 'Les enseignants de l\'école font un travail remarquable. Je souhaite les féliciter pour leur dévouement.',
      category: SuggestionCategory.staff,
      type: SuggestionType.compliment,
      priority: SuggestionPriority.low,
      status: SuggestionStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
      reviewedBy: 'Direction',
      reviewComment: 'Merci pour votre retour positif, nous transmettrons vos félicitations à l\'équipe.',
      upvotes: 18,
      downvotes: 0,
      establishmentId: 'school1',
      establishmentName: 'École Primaire Jean Jaurès',
    ),
    ParentSuggestion(
      id: '7',
      parentId: 'parent6',
      parentName: 'François Rousseau',
      childId: 'child6',
      childName: 'Chloé Rousseau',
      title: 'Réduire les frais de scolarité',
      description: 'Les frais de scolarité sont élevés. Serait-il possible de revoir les tarifs ou d\'offrir des bourses ?',
      category: SuggestionCategory.finance,
      type: SuggestionType.question,
      priority: SuggestionPriority.medium,
      status: SuggestionStatus.underReview,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      upvotes: 22,
      downvotes: 8,
      establishmentId: 'school2',
      establishmentName: 'Collège Victor Hugo',
      targetDepartment: 'Finance',
    ),
    ParentSuggestion(
      id: '8',
      parentId: 'parent7',
      parentName: 'Claire Dubois',
      childId: 'child7',
      childName: 'Louis Dubois',
      title: 'Améliorer la communication parents-enseignants',
      description: 'Il faudrait plus de réunions parents-enseignants et des rapports plus fréquents sur le progrès des élèves.',
      category: SuggestionCategory.communication,
      type: SuggestionType.improvement,
      priority: SuggestionPriority.medium,
      status: SuggestionStatus.approved,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      reviewedAt: DateTime.now().subtract(const Duration(days: 3)),
      reviewedBy: 'Pédagogie',
      reviewComment: 'Nous allons organiser des réunions mensuelles et envoyer des rapports bimensuels.',
      upvotes: 20,
      downvotes: 2,
      establishmentId: 'school1',
      establishmentName: 'École Primaire Jean Jaurès',
      targetDepartment: 'Pédagogie',
    ),
  ];

  @override
  Future<List<ParentSuggestion>> getParentSuggestions(String parentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockSuggestions.where((suggestion) => suggestion.parentId == parentId).toList();
  }

  @override
  Future<List<ParentSuggestion>> getEstablishmentSuggestions(String establishmentId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockSuggestions.where((suggestion) => suggestion.establishmentId == establishmentId).toList();
  }

  @override
  Future<List<ParentSuggestion>> getSuggestionsByCategory(SuggestionCategory category) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockSuggestions.where((suggestion) => suggestion.category == category).toList();
  }

  @override
  Future<List<ParentSuggestion>> getSuggestionsByStatus(SuggestionStatus status) async {
    await Future.delayed(const Duration(milliseconds: 400));
    return _mockSuggestions.where((suggestion) => suggestion.status == status).toList();
  }

  @override
  Future<List<ParentSuggestion>> getRecentSuggestions(int limit) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sortedSuggestions = List<ParentSuggestion>.from(_mockSuggestions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedSuggestions.take(limit).toList();
  }

  @override
  Future<List<ParentSuggestion>> getTopVotedSuggestions(int limit) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final sortedSuggestions = List<ParentSuggestion>.from(_mockSuggestions)
      ..sort((a, b) => b.voteScore.compareTo(a.voteScore));
    return sortedSuggestions.take(limit).toList();
  }

  @override
  Future<bool> createSuggestion(ParentSuggestion suggestion) async {
    await Future.delayed(const Duration(milliseconds: 600));
    try {
      _mockSuggestions.add(suggestion);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> updateSuggestion(ParentSuggestion suggestion) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      final index = _mockSuggestions.indexWhere((s) => s.id == suggestion.id);
      if (index != -1) {
        _mockSuggestions[index] = suggestion;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteSuggestion(String suggestionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      _mockSuggestions.removeWhere((suggestion) => suggestion.id == suggestionId);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> upvoteSuggestion(String suggestionId, String parentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final suggestion = _mockSuggestions.firstWhere((s) => s.id == suggestionId);
      final updatedSuggestion = suggestion.copyWith(upvotes: (suggestion.upvotes ?? 0) + 1);
      final index = _mockSuggestions.indexWhere((s) => s.id == suggestionId);
      if (index != -1) {
        _mockSuggestions[index] = updatedSuggestion;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> downvoteSuggestion(String suggestionId, String parentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final suggestion = _mockSuggestions.firstWhere((s) => s.id == suggestionId);
      final updatedSuggestion = suggestion.copyWith(downvotes: (suggestion.downvotes ?? 0) + 1);
      final index = _mockSuggestions.indexWhere((s) => s.id == suggestionId);
      if (index != -1) {
        _mockSuggestions[index] = updatedSuggestion;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<SuggestionStats> getSuggestionStats(String period, {String? establishmentId}) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    var filteredSuggestions = establishmentId != null
        ? _mockSuggestions.where((s) => s.establishmentId == establishmentId).toList()
        : _mockSuggestions;
    
    final totalSuggestions = filteredSuggestions.length;
    final pendingSuggestions = filteredSuggestions.where((s) => s.status == SuggestionStatus.pending).length;
    final approvedSuggestions = filteredSuggestions.where((s) => s.status == SuggestionStatus.approved).length;
    final rejectedSuggestions = filteredSuggestions.where((s) => s.status == SuggestionStatus.rejected).length;
    final implementedSuggestions = filteredSuggestions.where((s) => s.status == SuggestionStatus.implemented).length;
    
    // Statistiques par catégorie
    final suggestionsByCategory = <SuggestionCategory, int>{};
    for (final category in SuggestionCategory.values) {
      suggestionsByCategory[category] = filteredSuggestions.where((s) => s.category == category).length;
    }
    
    // Top suggestions votées
    final topVotedSuggestions = List<ParentSuggestion>.from(filteredSuggestions)
      ..sort((a, b) => b.voteScore.compareTo(a.voteScore));
    
    // Suggestions récentes
    final recentSuggestions = List<ParentSuggestion>.from(filteredSuggestions)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    return SuggestionStats(
      period: period,
      totalSuggestions: totalSuggestions,
      pendingSuggestions: pendingSuggestions,
      approvedSuggestions: approvedSuggestions,
      rejectedSuggestions: rejectedSuggestions,
      implementedSuggestions: implementedSuggestions,
      suggestionsByCategory: suggestionsByCategory,
      topVotedSuggestions: topVotedSuggestions.take(5).toList(),
      recentSuggestions: recentSuggestions.take(10).toList(),
    );
  }

  @override
  Future<List<ParentSuggestion>> searchSuggestions(String query, {
    SuggestionCategory? category,
    SuggestionStatus? status,
    SuggestionPriority? priority,
    String? establishmentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    var filteredSuggestions = _mockSuggestions;
    
    if (establishmentId != null) {
      filteredSuggestions = filteredSuggestions.where((s) => s.establishmentId == establishmentId).toList();
    }
    
    if (category != null) {
      filteredSuggestions = filteredSuggestions.where((s) => s.category == category).toList();
    }
    
    if (status != null) {
      filteredSuggestions = filteredSuggestions.where((s) => s.status == status).toList();
    }
    
    if (priority != null) {
      filteredSuggestions = filteredSuggestions.where((s) => s.priority == priority).toList();
    }
    
    if (query.isNotEmpty) {
      final searchQuery = query.toLowerCase();
      filteredSuggestions = filteredSuggestions.where((suggestion) =>
        suggestion.title.toLowerCase().contains(searchQuery) ||
        suggestion.description.toLowerCase().contains(searchQuery) ||
        suggestion.parentName.toLowerCase().contains(searchQuery)
      ).toList();
    }
    
    return filteredSuggestions;
  }

  @override
  Future<String> exportSuggestionsToCSV({
    String? establishmentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    var filteredSuggestions = _mockSuggestions;
    
    if (establishmentId != null) {
      filteredSuggestions = filteredSuggestions.where((s) => s.establishmentId == establishmentId).toList();
    }
    
    if (startDate != null) {
      filteredSuggestions = filteredSuggestions.where((s) => s.createdAt.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      filteredSuggestions = filteredSuggestions.where((s) => s.createdAt.isBefore(endDate)).toList();
    }
    
    final csvData = StringBuffer();
    csvData.writeln('Titre,Catégorie,Type,Priorité,Statut,Auteur,Date de création,Votes positifs,Votes négatifs');
    
    for (final suggestion in filteredSuggestions) {
      csvData.writeln(
        '"${suggestion.title}",'
        '"${suggestion.category.displayName}",'
        '"${suggestion.type.displayName}",'
        '"${suggestion.priority.displayName}",'
        '"${suggestion.status.displayName}",'
        '"${suggestion.displayName}",'
        '${suggestion.formattedCreatedAt},'
        '${suggestion.upvotes ?? 0},'
        '${suggestion.downvotes ?? 0}'
      );
    }
    
    return csvData.toString();
  }

  /// Méthode utilitaire pour générer des suggestions de test
  Future<void> generateTestSuggestions(String parentId, String parentName, int count) async {
    final categories = SuggestionCategory.values;
    final types = SuggestionType.values;
    final priorities = SuggestionPriority.values;
    
    for (int i = 0; i < count; i++) {
      final suggestion = ParentSuggestion(
        id: 'test_suggestion_${parentId}_$i',
        parentId: parentId,
        parentName: parentName,
        childId: 'child_test',
        childName: 'Enfant test',
        title: 'Suggestion test #$i',
        description: 'Ceci est une suggestion de test générée automatiquement pour le développement.',
        category: categories[i % categories.length],
        type: types[i % types.length],
        priority: priorities[i % priorities.length],
        status: SuggestionStatus.pending,
        createdAt: DateTime.now().subtract(Duration(days: i)),
        upvotes: i % 5,
        downvotes: i % 3,
        establishmentId: 'school_test',
        establishmentName: 'École test',
      );
      
      _mockSuggestions.add(suggestion);
    }
  }
}
