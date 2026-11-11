import 'package:url_launcher/url_launcher.dart';
import '../models/pharmacie.dart';

/// Ouvre Google Maps avec l'itinéraire jusqu'à la pharmacie.
Future<bool> ouvrirItineraire(Pharmacie p, {double? depuisLat, double? depuisLng}) {
  final params = <String, String>{
    'api': '1',
    'destination': '${p.latitude},${p.longitude}',
    'travelmode': 'driving',
  };
  if (depuisLat != null && depuisLng != null) {
    params['origin'] = '$depuisLat,$depuisLng';
  }
  final uri = Uri.https('www.google.com', '/maps/dir/', params);
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Ouvre Google Maps sur un point précis (pour vérifier un emplacement).
Future<bool> ouvrirCarte(double latitude, double longitude) {
  final uri = Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': '$latitude,$longitude',
  });
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Ouvre le numéro de la pharmacie dans l'application Téléphone.
Future<bool> appeler(String telephone) {
  return launchUrl(Uri(scheme: 'tel', path: telephone));
}