class DemandeMedicament {
  final int id;
  final String nom;
  final String pharmacieNom;
  final DateTime dateDemande;

  DemandeMedicament({
    required this.id,
    required this.nom,
    required this.pharmacieNom,
    required this.dateDemande,
  });

  factory DemandeMedicament.fromJson(Map<String, dynamic> json) {
    return DemandeMedicament(
      id: json['id'],
      nom: json['nom'],
      pharmacieNom: json['pharmacie']['nom'],
      dateDemande: DateTime.parse(json['dateDemande']),
    );
  }
}