import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/medicament.dart';

class MedicamentService {
  Future<List<Medicament>> listerTous() async {
    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/medicaments'));
    if (response.statusCode == 200) {
      // utf8.decode : pour que les accents (é, è...) s'affichent correctement
      final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
      return data.map((json) => Medicament.fromJson(json)).toList();
    }
    throw Exception('Échec de la récupération des médicaments (code ${response.statusCode})');
  }
}
