class Utilisateur {
  final int id;
  final int? pharmacieId;
  final String nom;
  final String telephone;
  final String role;

  Utilisateur({
    required this.id,
    this.pharmacieId,
    required this.nom,
    required this.telephone,
    required this.role,
  });

  bool get estAdmin => role == 'ADMIN';

  String get libelleRole {
    switch (role) {
      case 'ADMIN':
        return 'Administrateur';
      case 'AGENT':
        return 'Agent';
      default:
        return 'Pharmacien';
    }
  }

  factory Utilisateur.fromJson(Map<String, dynamic> json) {
    return Utilisateur(
      id: json['id'],
      pharmacieId: json['pharmacieId'],
      nom: json['nom'],
      telephone: json['telephone'],
      role: json['role'],
    );
  }
}