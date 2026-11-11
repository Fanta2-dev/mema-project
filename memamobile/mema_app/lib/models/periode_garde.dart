import 'pharmacie.dart';

class PeriodeGarde {
  final int id;
  final Pharmacie pharmacie;
  final String zone;
  final DateTime dateDebut;
  final DateTime dateFin;
  final String? source;

  PeriodeGarde({
    required this.id,
    required this.pharmacie,
    required this.zone,
    required this.dateDebut,
    required this.dateFin,
    this.source,
  });

  int get pharmacieId => pharmacie.id;

  factory PeriodeGarde.fromJson(Map<String, dynamic> json) {
    return PeriodeGarde(
      id: json['id'],
      pharmacie: Pharmacie.fromJson(json['pharmacie']),
      zone: json['zone'],
      dateDebut: DateTime.parse(json['dateDebut']),
      dateFin: DateTime.parse(json['dateFin']),
      source: json['source'],
    );
  }

  bool get enCours {
    final maintenant = DateTime.now();
    return !maintenant.isBefore(dateDebut) && !maintenant.isAfter(dateFin);
  }

  bool get terminee => DateTime.now().isAfter(dateFin);
}