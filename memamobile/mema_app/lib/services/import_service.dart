import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'session_service.dart';

class ResultatImport {
  final int lignesLues;
  final int stocksMisAJour;
  final int stocksCrees;
  final int stocksMisEnRupture;
  final bool remplacementApplique;
  final List<String> medicamentsInconnus;
  final int demandesEnregistrees;
  final List<String> erreurs;

  ResultatImport({
    required this.lignesLues,
    required this.stocksMisAJour,
    required this.stocksCrees,
    required this.stocksMisEnRupture,
    required this.remplacementApplique,
    required this.medicamentsInconnus,
    required this.demandesEnregistrees,
    required this.erreurs,
  });

  factory ResultatImport.fromJson(Map<String, dynamic> json) {
    List<String> liste(dynamic valeur) =>
        ((valeur as List<dynamic>?) ?? []).map((e) => e.toString()).toList();

    return ResultatImport(
      lignesLues: json['lignesLues'] ?? 0,
      stocksMisAJour: json['stocksMisAJour'] ?? 0,
      stocksCrees: json['stocksCrees'] ?? 0,
      stocksMisEnRupture: json['stocksMisEnRupture'] ?? 0,
      remplacementApplique: json['remplacementApplique'] ?? false,
      medicamentsInconnus: liste(json['medicamentsInconnus']),
      demandesEnregistrees: json['demandesEnregistrees'] ?? 0,
      erreurs: liste(json['erreurs']),
    );
  }
}

class ImportService {
  Future<ResultatImport> importer({
    required int pharmacieId,
    required List<int> octets,
    required String nomFichier,
    required bool remplacer,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/pharmacies/$pharmacieId/stock/import')
        .replace(queryParameters: {'remplacer': remplacer.toString()});

    final requete = http.MultipartRequest('POST', uri)
      ..headers.addAll(SessionService.entetesAutorisation)
      ..files.add(http.MultipartFile.fromBytes('fichier', octets, filename: nomFichier));

    final flux = await requete.send();
    final response = await http.Response.fromStream(flux);
    verifierReponse(response);
    return ResultatImport.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  }
}