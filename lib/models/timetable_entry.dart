// Import nécessaire pour TimeOfDay
import 'package:flutter/material.dart';

/// Modèle représentant une entrée d'emploi du temps
class TimetableEntry {
  final String id;
  final String childId;
  final String dayOfWeek; // Jour de la semaine
  final TimeOfDay startTime; // Heure de début
  final TimeOfDay endTime; // Heure de fin
  final String subject; // Matière
  final String? room; // Salle
  final String? teacher; // Professeur

  TimetableEntry({
    required this.id,
    required this.childId,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.room,
    this.teacher,
  });

  String get timeRange => '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')} - ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    final startStr = json['startTime']?.toString() ?? '00:00';
    final endStr = json['endTime']?.toString() ?? '00:00';
    final startParts = startStr.split(':');
    final endParts = endStr.split(':');
    
    return TimetableEntry(
      id: json['id']?.toString() ?? '',
      childId: json['childId']?.toString() ?? '',
      dayOfWeek: json['dayOfWeek']?.toString() ?? '',
      startTime: TimeOfDay(
        hour: int.tryParse(startParts[0]) ?? 0,
        minute: startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 0) : 0,
      ),
      endTime: TimeOfDay(
        hour: int.tryParse(endParts[0]) ?? 0,
        minute: endParts.length > 1 ? (int.tryParse(endParts[1]) ?? 0) : 0,
      ),
      subject: json['subject']?.toString() ?? '',
      room: json['room']?.toString(),
      teacher: json['teacher']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'childId': childId,
      'dayOfWeek': dayOfWeek,
      'startTime': '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      'endTime': '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      'subject': subject,
      'room': room,
      'teacher': teacher,
    };
  }
}

