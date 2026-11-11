import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/utilisateur.dart';

class SessionExpireeException implements Exception {
  @override
  String toString() => 'Votre session a expiré. Reconnectez-vous.';
}

class SessionService {
  static String? _token;
  static Utilisateur? utilisateur;
  static String? pharmacieNom;

  static bool get connecte => _token != null && utilisateur != null;

  static void ouvrir({
    required String token,
    required Utilisateur utilisateur,
    String? pharmacieNom,
  }) {
    _token = token;
    SessionService.utilisateur = utilisateur;
    SessionService.pharmacieNom = pharmacieNom;
  }

  static void fermer() {
    _token = null;
    utilisateur = null;
    pharmacieNom = null;
  }

  /// En-têtes à envoyer pour toute action réservée au personnel.
  static Map<String, String> get entetes => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  /// Seulement l'autorisation (pour l'envoi de fichiers, où le type est géré automatiquement).
  static Map<String, String> get entetesAutorisation => {
    if (_token != null) 'Authorization': 'Bearer $_token',
  };
}

/// Vérifie une réponse du serveur. En cas d'erreur, lève une exception avec un message lisible.
void verifierReponse(http.Response response) {
  if (response.statusCode >= 200 && response.statusCode < 300) {
    return;
  }
  if (response.statusCode == 401) {
    SessionService.fermer();
    throw SessionExpireeException();
  }
  String? message;
  try {
    final corps = jsonDecode(utf8.decode(response.bodyBytes));
    if (corps is Map && corps['erreur'] is String) {
      message = corps['erreur'] as String;
    }
  } catch (_) {
    // corps illisible : on utilisera un message par défaut
  }
  if (response.statusCode == 403) {
    message ??= "Vous n'avez pas le droit de faire cette action.";
  }
  throw Exception(message ?? 'Erreur du serveur (code ${response.statusCode}).');
}

/// Transforme n'importe quelle erreur en phrase compréhensible.
String messageErreur(Object e) {
  final texte = e.toString();
  if (e is http.ClientException ||
      texte.contains('XMLHttpRequest') ||
      texte.contains('SocketException') ||
      texte.contains('Failed host lookup')) {
    return 'Impossible de joindre le serveur. Vérifiez votre connexion.';
  }
  return texte.replaceFirst('Exception: ', '');
}