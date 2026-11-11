import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/demande_medicament.dart';
import '../models/inscription.dart';
import '../models/pharmacie.dart';
import '../models/utilisateur.dart';
import 'session_service.dart';

class ResultatCatalogue {
  final int lignesLues;
  final int medicamentsCrees;
  final int doublonsIgnores;
  final int demandesFermees;
  final List<String> erreurs;

  ResultatCatalogue({
    required this.lignesLues,
    required this.medicamentsCrees,
    required this.doublonsIgnores,
    required this.demandesFermees,
    required this.erreurs,
  });

  factory ResultatCatalogue.fromJson(Map<String, dynamic> json) {
    return ResultatCatalogue(
      lignesLues: json['lignesLues'] ?? 0,
      medicamentsCrees: json['medicamentsCrees'] ?? 0,
      doublonsIgnores: json['doublonsIgnores'] ?? 0,
      demandesFermees: json['demandesFermees'] ?? 0,
      erreurs: ((json['erreurs'] as List<dynamic>?) ?? []).map((e) => e.toString()).toList(),
    );
  }
}

/// Tous les appels réservés à l'administrateur.
class AdminService {
  dynamic _json(http.Response r) => jsonDecode(utf8.decode(r.bodyBytes));

  // ---------- Inscriptions de pharmacies ----------

  Future<List<Inscription>> inscriptions() async {
    final r = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/inscriptions'),
      headers: SessionService.entetes,
    );
    verifierReponse(r);
    return (_json(r) as List<dynamic>).map((j) => Inscription.fromJson(j)).toList();
  }

  Future<void> validerInscription(int id) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/inscriptions/$id/valider'),
      headers: SessionService.entetes,
    );
    verifierReponse(r);
  }

  Future<void> refuserInscription(int id, String motif) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/inscriptions/$id/refuser'),
      headers: SessionService.entetes,
      body: jsonEncode({'motif': motif}),
    );
    verifierReponse(r);
  }

  // ---------- Demandes de médicaments ----------

  Future<List<DemandeMedicament>> demandes() async {
    final r = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/demandes-medicaments'),
      headers: SessionService.entetes,
    );
    verifierReponse(r);
    return (_json(r) as List<dynamic>).map((j) => DemandeMedicament.fromJson(j)).toList();
  }

  Future<void> traiterDemande(int id) async {
    final r = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/demandes-medicaments/$id/traiter'),
      headers: SessionService.entetes,
    );
    verifierReponse(r);
  }

  // ---------- Pharmacies ----------

  Future<List<Pharmacie>> pharmacies() async {
    final r = await http.get(Uri.parse('${ApiConfig.baseUrl}/pharmacies'));
    verifierReponse(r);
    return (_json(r) as List<dynamic>).map((j) => Pharmacie.fromJson(j)).toList();
  }

  Future<Pharmacie> creerPharmacie({
    required String nom,
    required String adresse,
    required String telephone,
    required double latitude,
    required double longitude,
    required bool agreee,
    String? numeroAgrement,
  }) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/pharmacies'),
      headers: SessionService.entetes,
      body: jsonEncode({
        'nom': nom,
        'adresse': adresse,
        'telephone': telephone,
        'latitude': latitude,
        'longitude': longitude,
        'agreee': agreee,
        'numeroAgrement': numeroAgrement,
      }),
    );
    verifierReponse(r);
    return Pharmacie.fromJson(_json(r));
  }

  Future<void> definirAgrement(Pharmacie p, bool agreee) async {
    final r = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/pharmacies/${p.id}'),
      headers: SessionService.entetes,
      body: jsonEncode({
        'nom': p.nom,
        'adresse': p.adresse,
        'telephone': p.telephone,
        'latitude': p.latitude,
        'longitude': p.longitude,
        'agreee': agreee,
        'numeroAgrement': p.numeroAgrement,
      }),
    );
    verifierReponse(r);
  }

  // ---------- Comptes ----------

  Future<List<Utilisateur>> comptes() async {
    final r = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/utilisateurs'),
      headers: SessionService.entetes,
    );
    verifierReponse(r);
    return (_json(r) as List<dynamic>).map((j) => Utilisateur.fromJson(j)).toList();
  }

  Future<void> creerCompte({
    required int? pharmacieId,
    required String nom,
    required String telephone,
    required String motDePasse,
    required String role,
  }) async {
    final r = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/utilisateurs'),
      headers: SessionService.entetes,
      body: jsonEncode({
        'pharmacieId': pharmacieId,
        'nom': nom,
        'telephone': telephone,
        'motDePasse': motDePasse,
        'role': role,
      }),
    );
    verifierReponse(r);
  }

  Future<void> supprimerCompte(int id) async {
    final r = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/utilisateurs/$id'),
      headers: SessionService.entetes,
    );
    verifierReponse(r);
  }

  // ---------- Catalogue ----------

  Future<ResultatCatalogue> importerCatalogue(List<int> octets, String nomFichier) async {
    final requete = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/medicaments/import'),
    )
      ..headers.addAll(SessionService.entetesAutorisation)
      ..files.add(http.MultipartFile.fromBytes('fichier', octets, filename: nomFichier));

    final flux = await requete.send();
    final r = await http.Response.fromStream(flux);
    verifierReponse(r);
    return ResultatCatalogue.fromJson(_json(r));
  }
}