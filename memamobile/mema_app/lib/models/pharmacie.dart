class Pharmacie {
  final int id;
  final String nom;
  final String adresse;
  final double latitude;
  final double longitude;
  final String telephone;
  final bool agreee;
  final String? numeroAgrement;

  Pharmacie({
    required this.id,
    required this.nom,
    required this.adresse,
    required this.latitude,
    required this.longitude,
    required this.telephone,
    required this.agreee,
    this.numeroAgrement,
  });

  factory Pharmacie.fromJson(Map<String, dynamic> json) {
    return Pharmacie(
      id: json['id'],
      nom: json['nom'],
      adresse: json['adresse'],
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      telephone: json['telephone'] ?? '',
      agreee: json['agreee'] ?? false,
      numeroAgrement: json['numeroAgrement'],
    );
  }
}