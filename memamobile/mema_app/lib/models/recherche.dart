import 'pharmacie.dart';

/// Un médicament de la recherche.
class MedicamentCherche {
  final int id;
  final String? code;
  final String nom;
  final String dosage;
  final bool top100;

  MedicamentCherche({
    required this.id,
    required this.code,
    required this.nom,
    required this.dosage,
    required this.top100,
  });

  factory MedicamentCherche.fromJson(Map<String, dynamic> json) {
    return MedicamentCherche(
      id: json['id'],
      code: json['code'],
      nom: json['nom'],
      dosage: json['dosage'] ?? '',
      top100: json['top100'] ?? false,
    );
  }
}

/// L'état d'un médicament dans une pharmacie. Jamais de quantité.
/// statut : DISPONIBLE, INDISPONIBLE, SUR_COMMANDE ou NON_REFERENCE.
class LigneStatut {
  final int medicamentId;
  final String statut;
  final bool aVerifier;
  final double? prix;
  final DateTime? dateMiseAJour;

  LigneStatut({
    required this.medicamentId,
    required this.statut,
    required this.aVerifier,
    required this.prix,
    required this.dateMiseAJour,
  });

  bool get disponible => statut == 'DISPONIBLE';

  factory LigneStatut.fromJson(Map<String, dynamic> json) {
    final date = json['dateMiseAJour'];
    return LigneStatut(
      medicamentId: json['medicamentId'],
      statut: json['statut'] ?? 'NON_REFERENCE',
      aVerifier: json['aVerifier'] ?? false,
      prix: (json['prix'] as num?)?.toDouble(),
      dateMiseAJour: date == null ? null : DateTime.parse(date),
    );
  }
}

/// Une pharmacie proposée par le serveur, déjà classée.
class PharmacieTrouvee {
  final Pharmacie pharmacie;
  final bool deGarde;
  final double? distanceKm;
  final int nbDisponibles;
  final List<LigneStatut> lignes;

  PharmacieTrouvee({
    required this.pharmacie,
    required this.deGarde,
    required this.distanceKm,
    required this.nbDisponibles,
    required this.lignes,
  });

  LigneStatut? ligne(int medicamentId) {
    for (final l in lignes) {
      if (l.medicamentId == medicamentId) return l;
    }
    return null;
  }

  /// Au moins un médicament annoncé disponible dont l'information date de plus de 24 h.
  bool get infoAncienne => lignes.any((l) => l.disponible && l.aVerifier);

  factory PharmacieTrouvee.fromJson(Map<String, dynamic> json) {
    return PharmacieTrouvee(
      pharmacie: Pharmacie.fromJson(json),
      deGarde: json['deGarde'] ?? false,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      nbDisponibles: json['nbDisponibles'] ?? 0,
      lignes: ((json['medicaments'] as List<dynamic>?) ?? [])
          .map((l) => LigneStatut.fromJson(l))
          .toList(),
    );
  }
}

class ResultatRecherche {
  final List<MedicamentCherche> medicaments;
  final List<PharmacieTrouvee> pharmacies;

  ResultatRecherche({required this.medicaments, required this.pharmacies});

  factory ResultatRecherche.fromJson(Map<String, dynamic> json) {
    return ResultatRecherche(
      medicaments: ((json['medicaments'] as List<dynamic>?) ?? [])
          .map((m) => MedicamentCherche.fromJson(m))
          .toList(),
      pharmacies: ((json['pharmacies'] as List<dynamic>?) ?? [])
          .map((p) => PharmacieTrouvee.fromJson(p))
          .toList(),
    );
  }
}