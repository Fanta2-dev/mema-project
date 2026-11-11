class Inscription {
  final int id;
  final String pharmacieNom;
  final String pharmacieAdresse;
  final double latitude;
  final double longitude;
  final String pharmacieTelephone;
  final String numeroAgrement;
  final String responsableNom;
  final String responsableTelephone;
  final DateTime dateDemande;

  Inscription({
    required this.id,
    required this.pharmacieNom,
    required this.pharmacieAdresse,
    required this.latitude,
    required this.longitude,
    required this.pharmacieTelephone,
    required this.numeroAgrement,
    required this.responsableNom,
    required this.responsableTelephone,
    required this.dateDemande,
  });

  factory Inscription.fromJson(Map<String, dynamic> json) {
    return Inscription(
      id: json['id'],
      pharmacieNom: json['pharmacieNom'],
      pharmacieAdresse: json['pharmacieAdresse'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      pharmacieTelephone: json['pharmacieTelephone'],
      numeroAgrement: json['numeroAgrement'],
      responsableNom: json['responsableNom'],
      responsableTelephone: json['responsableTelephone'],
      dateDemande: DateTime.parse(json['dateDemande']),
    );
  }
}