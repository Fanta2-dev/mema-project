import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/periode_garde.dart';
import 'session_service.dart';

class GardeService {
  /// Pharmacies de garde en ce moment (lecture publique, aucune connexion nécessaire).
  Future<List<PeriodeGarde>> listerActives() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/periodes-garde/actives'));
    if (response.statusCode != 200) {
      throw Exception('Échec de la récupération des pharmacies de garde (code ${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((json) => PeriodeGarde.fromJson(json)).toList();
  }

  Future<List<PeriodeGarde>> listerPourPharmacie(int pharmacieId) async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/periodes-garde'));
    if (response.statusCode != 200) {
      throw Exception('Échec de la récupération des gardes (code ${response.statusCode})');
    }
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data
        .map((json) => PeriodeGarde.fromJson(json))
        .where((p) => p.pharmacieId == pharmacieId)
        .toList();
  }

  Future<void> creer({
    required int pharmacieId,
    required String zone,
    required DateTime debut,
    required DateTime fin,
    String? source,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/periodes-garde'),
      headers: SessionService.entetes,
      body: jsonEncode({
        'pharmacieId': pharmacieId,
        'zone': zone,
        'dateDebut': _iso(debut),
        'dateFin': _iso(fin),
        'source': source,
      }),
    );
    verifierReponse(response);
  }

  Future<void> supprimer(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/periodes-garde/$id'),
      headers: SessionService.entetes,
    );
    verifierReponse(response);
  }

  /// Format attendu par le serveur : 2026-11-03T20:00:00
  static String _iso(DateTime d) {
    String p(int n) => n.toString().padLeft(2, '0');
    return '${d.year.toString().padLeft(4, '0')}-${p(d.month)}-${p(d.day)}T${p(d.hour)}:${p(d.minute)}:00';
  }
}