import 'pharmacie.dart';

/// Ce que voit un patient : si le médicament est disponible, jamais la quantité exacte.
class Disponibilite {
  final int id;
  final Pharmacie pharmacie;
  final int medicamentId;
  final bool disponible;
  final String statut; // DISPONIBLE ou INDISPONIBLE
  final bool aVerifier; // plus de 24 h sans mise à jour (calculé par le serveur)
  final double? prix; // peut être absent si le prix est masqué
  final DateTime dateMiseAJour;

  Disponibilite({
    required this.id,
    required this.pharmacie,
    required this.medicamentId,
    required this.disponible,
    required this.statut,
    required this.aVerifier,
    required this.prix,
    required this.dateMiseAJour,
  });

  factory Disponibilite.fromJson(Map<String, dynamic> json) {
    final bool dispo = json['disponible'] ?? false;
    return Disponibilite(
      id: json['id'],
      pharmacie: Pharmacie.fromJson(json['pharmacie']),
      medicamentId: json['medicament']['id'],
      disponible: dispo,
      statut: json['statut'] ?? (dispo ? 'DISPONIBLE' : 'INDISPONIBLE'),
      aVerifier: json['aVerifier'] ?? false,
      prix: (json['prix'] as num?)?.toDouble(),
      dateMiseAJour: DateTime.parse(json['dateMiseAJour']),
    );
  }
}