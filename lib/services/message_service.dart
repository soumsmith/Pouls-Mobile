import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class MessageService {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  /// Envoie un message texte simple
  Future<Map<String, dynamic>> sendTextMessage({
    required String userPhoneNumber,
    required String content,
    required String subject,
    required String codeEcole,
    required String matricule,
    int? conversationId,
  }) async {
    print('📤 MessageService.sendTextMessage appelé');
    
    final url = Uri.parse(
      'https://api2.vie-ecoles.com/api/vie-ecoles/messages/envoyer/$userPhoneNumber'
    );

    final body = {
      'content': content,
      'body': content,
      'subject': subject,
      'conversation_id': conversationId ?? 1,
      'code_ecole': codeEcole,
      'matricule': matricule,
      'sender_type': 'parent',
    };

    print('🌐 URL: $url');
    print('📦 Body: $body');

    try {
      print('📡 Envoi de la requête HTTP...');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(AppConfig.API_TIMEOUT);

      print('📥 Réponse reçue - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Message texte envoyé avec succès');
        return {
          'success': true,
          'message': 'Message envoyé avec succès',
          'data': json.decode(response.body),
        };
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Erreur lors de l\'envoi du message: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      print('💥 Exception dans sendTextMessage: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Envoie un message avec une image
  Future<Map<String, dynamic>> sendImageMessage({
    required String userPhoneNumber,
    required String content,
    required String subject,
    required String codeEcole,
    required String matricule,
    required File imageFile,
    int? conversationId,
  }) async {
    print('📤 MessageService.sendImageMessage appelé');
    
    final url = Uri.parse(
      'https://api2.vie-ecoles.com/api/vie-ecoles/messages/envoyer/$userPhoneNumber'
    );

    try {
      final request = http.MultipartRequest('POST', url);
      
      // Ajouter les champs texte
      request.fields['content'] = content;
      request.fields['body'] = content;
      request.fields['subject'] = subject;
      request.fields['conversation_id'] = (conversationId ?? 1).toString();
      request.fields['code_ecole'] = codeEcole;
      request.fields['matricule'] = matricule;
      request.fields['sender_type'] = 'parent';

      // Ajouter l'image
      final imageBytes = await imageFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'attachments[0]',
        imageBytes,
        filename: 'image_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      request.files.add(multipartFile);

      print('🌐 URL: $url');
      print('📦 Champs: ${request.fields}');
      print('📡 Envoi de la requête multipart...');

      final streamedResponse = await request.send().timeout(AppConfig.API_TIMEOUT);
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Réponse reçue - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Message avec image envoyé avec succès');
        return {
          'success': true,
          'message': 'Message avec image envoyé avec succès',
          'data': json.decode(response.body),
        };
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Erreur lors de l\'envoi du message: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      print('💥 Exception dans sendImageMessage: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }

  /// Envoie une note vocale
  Future<Map<String, dynamic>> sendVoiceMessage({
    required String userPhoneNumber,
    required String content,
    required String subject,
    required String codeEcole,
    required String matricule,
    required File audioFile,
    int? conversationId,
  }) async {
    print('📤 MessageService.sendVoiceMessage appelé');
    
    final url = Uri.parse(
      'https://api2.vie-ecoles.com/api/vie-ecoles/messages/envoyer/$userPhoneNumber'
    );

    try {
      final request = http.MultipartRequest('POST', url);
      
      // Ajouter les champs texte
      request.fields['content'] = content;
      request.fields['body'] = content;
      request.fields['subject'] = subject;
      request.fields['conversation_id'] = (conversationId ?? 1).toString();
      request.fields['code_ecole'] = codeEcole;
      request.fields['matricule'] = matricule;
      request.fields['sender_type'] = 'parent';

      // Ajouter le fichier audio
      final audioBytes = await audioFile.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes(
        'attachments[0]',
        audioBytes,
        filename: 'voice_${DateTime.now().millisecondsSinceEpoch}.webm',
      );
      request.files.add(multipartFile);

      print('🌐 URL: $url');
      print('📦 Champs: ${request.fields}');
      print('📡 Envoi de la requête multipart avec audio...');

      final streamedResponse = await request.send().timeout(AppConfig.API_TIMEOUT);
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Réponse reçue - Status: ${response.statusCode}');
      print('📄 Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Note vocale envoyée avec succès');
        return {
          'success': true,
          'message': 'Note vocale envoyée avec succès',
          'data': json.decode(response.body),
        };
      } else {
        print('❌ Erreur HTTP - Status: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Erreur lors de l\'envoi du message: ${response.statusCode}',
          'error': response.body,
        };
      }
    } catch (e) {
      print('💥 Exception dans sendVoiceMessage: $e');
      return {
        'success': false,
        'message': 'Erreur de connexion: $e',
      };
    }
  }
}
