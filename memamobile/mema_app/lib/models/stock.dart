import 'pharmacie.dart';

class Stock {
  final int id;
  final Pharmacie pharmacie;
  final int medicamentId;
  final bool disponible;
  final bool surCommande;
  final String? source; // MANUEL, IMPORT_CSV ou CONNECTEUR
  final int? quantite; // absente quand un logiciel ne transmet que le statut
  final double? prix;
  final DateTime dateMiseAJour;

  Stock({
    required this.id,
    required this.pharmacie,
    required this.medicamentId,
    required this.disponible,
    required this.surCommande,
    required this.source,
    required this.quantite,
    required this.prix,
    required this.dateMiseAJour,
  });

  /// D'où vient la dernière mise à jour, en clair.
  String get libelleSource {
    switch (source) {
      case 'CONNECTEUR':
        return 'logiciel de la pharmacie';
      case 'IMPORT_CSV':
        return 'import de fichier';
      case 'MANUEL':
        return 'saisie manuelle';
      default:
        return '';
    }
  }

  factory Stock.fromJson(Map<String, dynamic> json) {
    return Stock(
      id: json['id'],
      pharmacie: Pharmacie.fromJson(json['pharmacie']),
      medicamentId: json['medicament']['id'],
      disponible: json['disponible'] ?? false,
      surCommande: json['surCommande'] ?? false,
      source: json['source'],
      quantite: (json['quantite'] as num?)?.toInt(),
      prix: (json['prix'] as num?)?.toDouble(),
      dateMiseAJour: DateTime.parse(json['dateMiseAJour']),
    );
  }
}