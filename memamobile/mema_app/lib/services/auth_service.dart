import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/utilisateur.dart';
import 'session_service.dart';

class AuthService {
  Future<void> connecter(String telephone, String motDePasse) async {
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'telephone': telephone, 'motDePasse': motDePasse}),
      );
    } catch (_) {
      throw Exception("Impossible de joindre le serveur. Vérifiez qu'il est démarré.");
    }

    dynamic corps;
    try {
      corps = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      corps = null;
    }

    if (response.statusCode != 200) {
      if (corps is Map && corps['erreur'] is String) {
        throw Exception(corps['erreur']);
      }
      throw Exception('Connexion impossible (code ${response.statusCode}).');
    }
    if (corps is! Map) {
      throw Exception('Réponse inattendue du serveur.');
    }

    final utilisateur = Utilisateur.fromJson(corps['utilisateur']);
    if (!utilisateur.estAdmin && utilisateur.pharmacieId == null) {
      throw Exception("Ce compte n'est rattaché à aucune pharmacie.");
    }
    SessionService.ouvrir(
      token: corps['token'],
      utilisateur: utilisateur,
      pharmacieNom: corps['pharmacieNom'],
    );
  }
}