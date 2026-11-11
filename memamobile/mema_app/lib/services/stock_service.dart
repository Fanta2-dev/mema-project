import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/disponibilite.dart';

/// Disponibilités vues par les patients (lecture publique, sans quantité).
class StockService {
  Future<List<Disponibilite>> listerTous() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/stocks'));
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Disponibilite.fromJson(json)).toList();
    }
    throw Exception('Échec de la récupération des disponibilités (code ${response.statusCode})');
  }
}