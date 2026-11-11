import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../models/medicament.dart';

class ResultatScan {
  final String texte;
  final List<Medicament> detectes;
  ResultatScan(this.texte, this.detectes);
}

/// Lit le texte d'une photo d'ordonnance (sur le téléphone, sans envoyer
/// la photo nulle part) puis retrouve les médicaments connus de MEMA.
class OrdonnanceService {
  /// La lecture de texte (ML Kit) fonctionne sur Android et iOS, pas sur Chrome.
  static bool get disponible => !kIsWeb;

  Future<ResultatScan> analyser(String cheminImage, List<Medicament> catalogue) async {
    final lecteur = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final res = await lecteur.processImage(InputImage.fromFilePath(cheminImage));
      return ResultatScan(res.text, detecter(res.text, catalogue));
    } finally {
      await lecteur.close();
    }
  }

  /// Cherche chaque médicament (nom ou DCI) dans le texte, en tolérant
  /// 1 à 2 lettres mal lues (l'écriture manuscrite est souvent mal reconnue).
  List<Medicament> detecter(String texte, List<Medicament> catalogue) {
    final texteNorm = normaliser(texte);
    final mots = texteNorm.split(' ').where((m) => m.isNotEmpty).toList();
    final trouves = <Medicament>[];
    for (final m in catalogue) {
      final candidats = [m.nom, if (m.dci != null) m.dci!];
      if (candidats.any((c) => _correspond(c, texteNorm, mots))) trouves.add(m);
    }
    return trouves;
  }

  static const _accents = {
    'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a',
    'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
    'î': 'i', 'ï': 'i', 'í': 'i',
    'ô': 'o', 'ö': 'o', 'ó': 'o',
    'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
    'ç': 'c', 'ñ': 'n', 'œ': 'oe',
  };

  static String normaliser(String s) {
    final buf = StringBuffer();
    for (final r in s.toLowerCase().runes) {
      final c = String.fromCharCode(r);
      buf.write(_accents[c] ?? c);
    }
    return buf.toString().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
  }

  bool _correspond(String candidat, String texteNorm, List<String> mots) {
    final c = normaliser(candidat);
    if (c.isEmpty) return false;
    if (' $texteNorm '.contains(' $c ')) return true;
    final parties = c.split(' ').where((w) => w.length >= 4).toList();
    if (parties.isEmpty) return false;
    return parties.every((w) => mots.any((m) => _proche(w, m)));
  }

  bool _proche(String a, String b) {
    if (a == b) return true;
    if (a.length < 5 || b.length < 5) return false;
    final tolerance = a.length >= 8 ? 2 : 1;
    return (a.length - b.length).abs() <= tolerance && _levenshtein(a, b) <= tolerance;
  }

  int _levenshtein(String a, String b) {
    final prev = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 1; i <= a.length; i++) {
      var diagonale = prev[0];
      prev[0] = i;
      for (var j = 1; j <= b.length; j++) {
        final temp = prev[j];
        final cout = a[i - 1] == b[j - 1] ? 0 : 1;
        prev[j] = [prev[j] + 1, prev[j - 1] + 1, diagonale + cout].reduce((x, y) => x < y ? x : y);
        diagonale = temp;
      }
    }
    return prev[b.length];
  }
}