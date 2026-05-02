import 'dart:async';
import '../models/child.dart';
import '../models/note.dart';
import '../models/timetable_entry.dart';
import '../models/message.dart';
import '../models/fee.dart';
import 'api_service.dart';
import '../services/database_service.dart';
import '../config/app_config.dart';
import 'package:flutter/material.dart';

/// Implémentation MOCK de ApiService
/// Retourne des données statiques pour le développement
class MockApiService implements ApiService {
  // Liste mutable pour stocker les enfants ajoutés
  final Map<String, List<Child>> _childrenByParent = {};
  
  // Simule un délai réseau
  Future<void> _simulateDelay() async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<Child>> getChildrenForParent(String parentId) async {
    await _simulateDelay();
    
    // Charger depuis la base de données locale en priorité
    try {
      final dbChildren = await DatabaseService.instance.getChildrenByParent(parentId);
      if (dbChildren.isNotEmpty) {
        // Synchroniser avec le cache en mémoire
        _childrenByParent[parentId] = List.from(dbChildren);
        return dbChildren;
      }
    } catch (e) {
      print('Erreur lors du chargement depuis la base de données: $e');
    }
    
    // Si pas d'enfants en base de données, vérifier le cache en mémoire
    if (_childrenByParent.containsKey(parentId)) {
      return _childrenByParent[parentId]!;
    }
    
    // Si aucun enfant trouvé, retourner une liste vide
    // (plus de données de test par défaut)
    _childrenByParent[parentId] = [];
    return [];
  }

  @override
  Future<List<Note>> getNotesForChild(String childId, {String? trimester, String? year}) async {
    await _simulateDelay();
    
    final now = DateTime.now();
    // Enrichir les données pour remplir le tableau selon les maquettes
    return [
      // MATH - 4 devoirs pour remplir les colonnes
      Note(
        id: 'note1',
        childId: childId,
        subject: 'MATH',
        grade: 15.5,
        coefficient: 3.0,
        date: now.subtract(const Duration(days: 30)),
        assignmentNumber: '1',
      ),
      Note(
        id: 'note2',
        childId: childId,
        subject: 'MATH',
        grade: 14.0,
        coefficient: 3.0,
        date: now.subtract(const Duration(days: 20)),
        assignmentNumber: '2',
      ),
      Note(
        id: 'note3',
        childId: childId,
        subject: 'MATH',
        grade: 16.5,
        coefficient: 3.0,
        date: now.subtract(const Duration(days: 10)),
        assignmentNumber: '3',
      ),
      Note(
        id: 'note4',
        childId: childId,
        subject: 'MATH',
        grade: 15.0,
        coefficient: 3.0,
        date: now.subtract(const Duration(days: 5)),
        assignmentNumber: '4',
      ),
      // PC - 2 devoirs
      Note(
        id: 'note5',
        childId: childId,
        subject: 'PC',
        grade: 16.0,
        coefficient: 2.0,
        date: now.subtract(const Duration(days: 25)),
        assignmentNumber: '1',
      ),
      Note(
        id: 'note6',
        childId: childId,
        subject: 'PC',
        grade: 17.5,
        coefficient: 2.0,
        date: now.subtract(const Duration(days: 15)),
        assignmentNumber: '2',
      ),
      // SVT - 1 devoir
      Note(
        id: 'note7',
        childId: childId,
        subject: 'SVT',
        grade: 13.5,
        coefficient: 2.0,
        date: now.subtract(const Duration(days: 22)),
        assignmentNumber: '1',
      ),
      // FRANÇAIS - 3 devoirs
      Note(
        id: 'note8',
        childId: childId,
        subject: 'FRANÇAIS',
        grade: 17.0,
        coefficient: 4.0,
        date: now.subtract(const Duration(days: 28)),
        assignmentNumber: '1',
      ),
      Note(
        id: 'note9',
        childId: childId,
        subject: 'FRANÇAIS',
        grade: 16.5,
        coefficient: 4.0,
        date: now.subtract(const Duration(days: 18)),
        assignmentNumber: '2',
      ),
      Note(
        id: 'note10',
        childId: childId,
        subject: 'FRANÇAIS',
        grade: 18.0,
        coefficient: 4.0,
        date: now.subtract(const Duration(days: 8)),
        assignmentNumber: '3',
      ),
      // HISTOIRE - 2 devoirs
      Note(
        id: 'note11',
        childId: childId,
        subject: 'HISTOIRE',
        grade: 14.5,
        coefficient: 2.0,
        date: now.subtract(const Duration(days: 24)),
        assignmentNumber: '1',
      ),
      Note(
        id: 'note12',
        childId: childId,
        subject: 'HISTOIRE',
        grade: 15.0,
        coefficient: 2.0,
        date: now.subtract(const Duration(days: 12)),
        assignmentNumber: '2',
      ),
      // ANGLAIS - 2 devoirs
      Note(
        id: 'note13',
        childId: childId,
        subject: 'ANGLAIS',
        grade: 16.0,
        coefficient: 2.0,
        date: now.subtract(const Duration(days: 26)),
        assignmentNumber: '1',
      ),
      Note(
        id: 'note14',
        childId: childId,
        subject: 'ANGLAIS',
        grade: 15.5,
        coefficient: 2.0,
        date: now.subtract(const Duration(days: 14)),
        assignmentNumber: '2',
      ),
    ];
  }

  @override
  Future<List<SubjectAverage>> getSubjectAveragesForChild(String childId, {String? trimester, String? year}) async {
    await _simulateDelay();
    
    // Debug: vérifier le childId
    print('🔍 getSubjectAveragesForChild appelé avec childId: $childId');
    
    final notes = await getNotesForChild(childId, trimester: trimester, year: year);
    
    // Debug: vérifier les notes
    print('📝 Notes récupérées: ${notes.length} notes');
    if (notes.isNotEmpty) {
      print('📝 Matières dans les notes: ${notes.map((n) => n.subject).toSet().join(", ")}');
    }
    
    // Grouper par matière et trier les notes par numéro de devoir
    final Map<String, List<Note>> notesBySubject = {};
    for (var note in notes) {
      notesBySubject.putIfAbsent(note.subject, () => []).add(note);
    }
    
    // Trier les notes par numéro de devoir pour chaque matière
    for (var notesList in notesBySubject.values) {
      notesList.sort((a, b) => a.assignmentNumber.compareTo(b.assignmentNumber));
    }
    
    final List<SubjectAverage> averages = [];
    int rankCounter = 1;
    
    for (var entry in notesBySubject.entries) {
      final subjectNotes = entry.value;
      final sum = subjectNotes.fold<double>(0.0, (sum, note) => sum + note.grade);
      final avg = sum / subjectNotes.length;
      final coef = subjectNotes.first.coefficient;
      final weightedAvg = avg * coef;
      
      // Déterminer le statut "viewed" selon les maquettes
      // MATH = V (vu), PC = X (non vu), autres = vide
      bool viewed = false;
      if (entry.key == 'MATH') {
        viewed = true;
      } else if (entry.key == 'PC') {
        viewed = false;
      }
      
      averages.add(SubjectAverage(
        subject: entry.key,
        notes: subjectNotes,
        average: avg,
        coefficient: coef,
        weightedAverage: weightedAvg,
        rank: rankCounter++,
        totalStudents: 25,
        viewed: viewed,
      ));
    }
    
    // Trier par moyenne pondérée décroissante pour le classement
    averages.sort((a, b) => b.weightedAverage.compareTo(a.weightedAverage));
    
    // Réassigner les rangs après tri en créant de nouveaux objets
    final List<SubjectAverage> rankedAverages = [];
    for (int i = 0; i < averages.length; i++) {
      rankedAverages.add(SubjectAverage(
        subject: averages[i].subject,
        notes: averages[i].notes,
        average: averages[i].average,
        coefficient: averages[i].coefficient,
        weightedAverage: averages[i].weightedAverage,
        rank: i + 1,
        totalStudents: averages[i].totalStudents,
        viewed: averages[i].viewed,
      ));
    }
    
    // Debug: vérifier les moyennes retournées
    print('✅ SubjectAverages retournées: ${rankedAverages.length} matières');
    if (rankedAverages.isNotEmpty) {
      print('✅ Matières: ${rankedAverages.map((a) => a.subject).join(", ")}');
    }
    
    return rankedAverages;
  }

  @override
  Future<GlobalAverage> getGlobalAveragesForChild(String childId, {String? trimester, String? year}) async {
    await _simulateDelay();
    
    return GlobalAverage(
      trimesterAverage: 12.20,
      trimesterRank: 1,
      trimesterMention: 'Bien',
      annualAverage: 12.20,
      annualRank: 1,
      annualMention: 'Assez-Bien',
    );
  }

  @override
  Future<List<TimetableEntry>> getTimetableForChild(String childId) async {
    await _simulateDelay();
    
    return [
      TimetableEntry(
        id: 'tt1',
        childId: childId,
        dayOfWeek: 'Lundi',
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 9, minute: 0),
        subject: 'MATH',
        room: 'Salle 101',
        teacher: 'M. Martin',
      ),
      TimetableEntry(
        id: 'tt2',
        childId: childId,
        dayOfWeek: 'Lundi',
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        subject: 'FRANÇAIS',
        room: 'Salle 205',
        teacher: 'Mme. Dubois',
      ),
      TimetableEntry(
        id: 'tt3',
        childId: childId,
        dayOfWeek: 'Lundi',
        startTime: const TimeOfDay(hour: 10, minute: 15),
        endTime: const TimeOfDay(hour: 11, minute: 15),
        subject: 'PC',
        room: 'Labo 1',
        teacher: 'M. Bernard',
      ),
      TimetableEntry(
        id: 'tt4',
        childId: childId,
        dayOfWeek: 'Mardi',
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 9, minute: 0),
        subject: 'SVT',
        room: 'Labo 2',
        teacher: 'Mme. Leroy',
      ),
      TimetableEntry(
        id: 'tt5',
        childId: childId,
        dayOfWeek: 'Mardi',
        startTime: const TimeOfDay(hour: 9, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        subject: 'HISTOIRE',
        room: 'Salle 103',
        teacher: 'M. Petit',
      ),
      TimetableEntry(
        id: 'tt6',
        childId: childId,
        dayOfWeek: 'Mercredi',
        startTime: const TimeOfDay(hour: 8, minute: 0),
        endTime: const TimeOfDay(hour: 10, minute: 0),
        subject: 'MATH',
        room: 'Salle 101',
        teacher: 'M. Martin',
      ),
    ];
  }

  @override
  Future<List<Message>> getMessages(String parentId) async {
    await _simulateDelay();
    
    final now = DateTime.now();
    return [
      Message(
        id: 'msg1',
        parentId: parentId,
        subject: 'Réunion parents-professeurs',
        content: 'Chers parents, nous vous convions à une réunion parents-professeurs le 15 mars à 18h00 dans la salle polyvalente. Cette réunion permettra de faire le point sur le premier trimestre.',
        date: now.subtract(const Duration(days: 2)),
        sender: 'Direction de l\'établissement',
        isRead: true,
        type: MessageType.announcement,
      ),
      Message(
        id: 'msg2',
        parentId: parentId,
        subject: 'Absence non justifiée',
        content: 'Votre enfant a été absent le 10 mars sans justification. Merci de nous fournir un justificatif dans les plus brefs délais.',
        date: now.subtract(const Duration(days: 5)),
        sender: 'Secrétariat',
        isRead: false,
        type: MessageType.absence,
      ),
      Message(
        id: 'msg3',
        parentId: parentId,
        subject: 'Nouvelle note disponible',
        content: 'Une nouvelle note en Mathématiques a été ajoutée au bulletin de votre enfant. Vous pouvez la consulter dans l\'application.',
        date: now.subtract(const Duration(days: 1)),
        sender: 'Système de notes',
        isRead: false,
        type: MessageType.grade,
      ),
      Message(
        id: 'msg4',
        parentId: parentId,
        subject: 'Rappel : Frais de scolarité',
        content: 'Rappel : Les frais de scolarité du deuxième trimestre sont à régler avant le 30 mars. Vous pouvez effectuer le paiement via l\'application.',
        date: now.subtract(const Duration(days: 3)),
        sender: 'Comptabilité',
        isRead: true,
        type: MessageType.fee,
      ),
    ];
  }

  @override
  Future<List<Fee>> getFeesForChild(String childId) async {
    await _simulateDelay();
    
    final now = DateTime.now();
    return [
      Fee(
        id: 'fee1',
        childId: childId,
        type: 'Inscription',
        amount: 50000.0,
        dueDate: now.subtract(const Duration(days: 60)),
        paidDate: now.subtract(const Duration(days: 55)),
        isPaid: true,
        paymentMethod: 'Virement bancaire',
        reference: 'REF-2024-001',
      ),
      Fee(
        id: 'fee2',
        childId: childId,
        type: 'Frais de scolarité - Trimestre 1',
        amount: 150000.0,
        dueDate: now.subtract(const Duration(days: 30)),
        paidDate: now.subtract(const Duration(days: 25)),
        isPaid: true,
        paymentMethod: 'Carte bancaire',
        reference: 'REF-2024-002',
      ),
      Fee(
        id: 'fee3',
        childId: childId,
        type: 'Frais de scolarité - Trimestre 2',
        amount: 150000.0,
        dueDate: now.add(const Duration(days: 10)),
        isPaid: false,
      ),
      Fee(
        id: 'fee4',
        childId: childId,
        type: 'Frais de scolarité - Trimestre 3',
        amount: 150000.0,
        dueDate: now.add(const Duration(days: 70)),
        isPaid: false,
      ),
    ];
  }

  @override
  Future<bool> addChild(String parentId, Child child) async {
    print('═══════════════════════════════════════════════════════════');
    print('🔌 API REQUEST - ADD CHILD');
    print('═══════════════════════════════════════════════════════════');
    print('👤 Parent ID: $parentId');
    print('👶 Child ID: ${child.id}');
    print('📝 Child Name: ${child.firstName} ${child.lastName}');
    print('🏫 Establishment: ${child.establishment}');
    print('📚 Grade: ${child.grade}');
    print('🔗 URL: POST ${AppConfig.API_BASE_URL}/parents/$parentId/children');
    print('⏱️  Timestamp: ${DateTime.now().toIso8601String()}');
    print('═══════════════════════════════════════════════════════════');
    
    await _simulateDelay();
    
    try {
      // L'enfant devrait déjà être sauvegardé dans la base de données
      // par AddChildScreen avant d'appeler cette méthode
      // Vérifier s'il existe déjà
      final existingChild = await DatabaseService.instance.getChildById(child.id);
      print('🔍 Vérification existence enfant: ${existingChild != null ? "Déjà existant" : "Nouveau"}');
      
      if (existingChild == null) {
        // Si l'enfant n'existe pas encore en base, le sauvegarder
        // (normalement cela ne devrait pas arriver car AddChildScreen le fait déjà)
        await DatabaseService.instance.saveChild(child);
      }
      
      // Mettre à jour le cache en mémoire
      if (!_childrenByParent.containsKey(parentId)) {
        _childrenByParent[parentId] = [];
      }
      
      final list = _childrenByParent[parentId]!;
      final existingIndex = list.indexWhere((c) => c.id == child.id);
      if (existingIndex >= 0) {
        list[existingIndex] = child;
        print('🔄 Enfant mis à jour dans le cache');
      } else {
        list.add(child);
        print('➕ Enfant ajouté au cache');
      }
      
      print('═══════════════════════════════════════════════════════════');
      print('✅ API RESPONSE - ADD CHILD SUCCESS');
      print('═══════════════════════════════════════════════════════════');
      print('📊 Status Code: 201 (Created)');
      print('📄 Body Length: ${child.toString().length} characters');
      print('👶 Child Added: ${child.firstName} ${child.lastName}');
      print('📚 Total children for parent: ${list.length}');
      print('═══════════════════════════════════════════════════════════');
      
      return true;
    } catch (e) {
      print('═══════════════════════════════════════════════════════════');
      print('❌ API RESPONSE - ADD CHILD ERROR');
      print('═══════════════════════════════════════════════════════════');
      print('📊 Status Code: 500 (Internal Server Error)');
      print('💥 Error: $e');
      print('═══════════════════════════════════════════════════════════');
      return false;
    }
  }
}

