import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/recherche.dart';

/// Recherche publique : le serveur trie et renvoie directement les meilleures pharmacies.
class RechercheService {
  Future<ResultatRecherche> rechercher({
    required List<int> ids,
    double? latitude,
    double? longitude,
    int? limite,
  }) async {
    final params = <String, String>{'ids': ids.join(',')};
    if (latitude != null && longitude != null) {
      params['latitude'] = '$latitude';
      params['longitude'] = '$longitude';
    }
    if (limite != null) {
      params['limite'] = '$limite';
    }
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/recherche').replace(queryParameters: params);

    final response = await http.get(uri);
    if (response.statusCode != 200) {
      String? message;
      try {
        final corps = jsonDecode(utf8.decode(response.bodyBytes));
        if (corps is Map && corps['erreur'] is String) {
          message = corps['erreur'] as String;
        }
      } catch (_) {
        // corps illisible : message par défaut
      }
      throw Exception(message ?? 'Recherche impossible (code ${response.statusCode}).');
    }
    return ResultatRecherche.fromJson(jsonDecode(utf8.decode(response.bodyBytes)));
  }
}