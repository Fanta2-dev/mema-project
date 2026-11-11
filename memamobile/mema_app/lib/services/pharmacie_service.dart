import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class PharmacieService {
  /// Vrai si la pharmacie est actuellement de garde (le serveur répond 200),
  /// faux sinon (404) ou en cas de problème réseau.
  Future<bool> estDeGarde(int pharmacieId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/periodes-garde/pharmacie/$pharmacieId/active'),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}