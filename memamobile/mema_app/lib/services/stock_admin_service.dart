import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/stock.dart';
import 'session_service.dart';

class StockAdminService {
  /// Le stock complet (avec quantités) de la pharmacie connectée : réservé à son personnel.
  Future<List<Stock>> stocksDeLaPharmacie(int pharmacieId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/pharmacies/$pharmacieId/stock'),
      headers: SessionService.entetes,
    );
    verifierReponse(response);
    final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
    return data.map((json) => Stock.fromJson(json)).toList();
  }

  Future<void> creer({
    required int pharmacieId,
    required int medicamentId,
    required int quantite,
    required double prix,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/stocks'),
      headers: SessionService.entetes,
      body: jsonEncode({
        'pharmacieId': pharmacieId,
        'medicamentId': medicamentId,
        'quantite': quantite,
        'prix': prix,
      }),
    );
    verifierReponse(response);
  }

  Future<void> modifier({
    required int stockId,
    required int pharmacieId,
    required int medicamentId,
    required int quantite,
    required double prix,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/stocks/$stockId'),
      headers: SessionService.entetes,
      body: jsonEncode({
        'pharmacieId': pharmacieId,
        'medicamentId': medicamentId,
        'quantite': quantite,
        'prix': prix,
      }),
    );
    verifierReponse(response);
  }
}