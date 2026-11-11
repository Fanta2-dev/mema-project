class Medicament {
  final int id;
  final String nom;
  final String? dci;
  final String dosage;
  final String categorie;

  Medicament({
    required this.id,
    required this.nom,
    this.dci,
    required this.dosage,
    required this.categorie,
  });

  factory Medicament.fromJson(Map<String, dynamic> json) {
    return Medicament(
      id: json['id'],
      nom: json['nom'],
      dci: json['dci'],
      dosage: json['dosage'],
      categorie: json['categorie'],
    );
  }
}
