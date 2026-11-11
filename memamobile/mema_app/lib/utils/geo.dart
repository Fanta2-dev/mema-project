import 'dart:math' as math;

/// Distance à vol d'oiseau entre deux points (formule de Haversine), en km.
double distanceKm(double lat1, double lon1, double lat2, double lon2) {
  const rayonTerre = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1);
  final dLon = rad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) * math.cos(rad(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
  return 2 * rayonTerre * math.asin(math.sqrt(a));
}

String formatDistance(double km) {
  if (km < 1) return '${(km * 1000).round()} m';
  return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
}