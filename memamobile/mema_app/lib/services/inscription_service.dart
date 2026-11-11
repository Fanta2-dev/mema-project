import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'session_service.dart';

/// Dépôt d'une demande d'inscription (aucune connexion nécessaire).
class InscriptionService {
  Future<void> envoyer({
    required String pharmacieNom,
    required String pharmacieAdresse,
    required double latitude,
    required double longitude,
    required String pharmacieTelephone,
    required String numeroAgrement,
    required String responsableNom,
    required String responsableTelephone,
    required String motDePasse,
  }) async {
    final http.Response reponse;
    try {
      reponse = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/inscriptions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'pharmacieNom': pharmacieNom,
          'pharmacieAdresse': pharmacieAdresse,
          'latitude': latitude,
          'longitude': longitude,
          'pharmacieTelephone': pharmacieTelephone,
          'numeroAgrement': numeroAgrement,
          'responsableNom': responsableNom,
          'responsableTelephone': responsableTelephone,
          'motDePasse': motDePasse,
        }),
      );
    } catch (_) {
      throw Exception("Impossible de joindre le serveur. Vérifiez votre connexion.");
    }
    verifierReponse(reponse);
  }
}