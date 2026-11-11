import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/medicament.dart';
import '../models/stock.dart';
import '../services/medicament_service.dart';
import '../services/session_service.dart';
import '../services/stock_admin_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import '../widgets/mema_widgets.dart';
import 'import_sheet.dart';

class _Donnees {
  final List<Stock> stocks;
  final List<Medicament> catalogue;
  _Donnees(this.stocks, this.catalogue);

  Medicament? medicament(int id) {
    for (final m in catalogue) {
      if (m.id == id) return m;
    }
    return null;
  }
}

class StockTab extends StatefulWidget {
  final VoidCallback onSessionExpiree;
  const StockTab({super.key, required this.onSessionExpiree});

  @override
  State<StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<StockTab> {
  final StockAdminService _stockService = StockAdminService();
  final MedicamentService _medicamentService = MedicamentService();
  late Future<_Donnees> _futur;

  int get _pharmacieId => SessionService.utilisateur?.pharmacieId ?? 0;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<_Donnees> _charger() async {
    final stocks = await _stockService.stocksDeLaPharmacie(_pharmacieId);
    final catalogue = await _medicamentService.listerTous();
    return _Donnees(stocks, catalogue);
  }

  void _recharger() {
    setState(() {
      _futur = _charger();
    });
  }

  bool _perime(Stock s) => DateTime.now().difference(s.dateMiseAJour).inHours >= 24;

  String _resume(int total, int ruptures, int perimes) {
    final morceaux = <String>['$total médicament${total > 1 ? 's' : ''}'];
    if (ruptures > 0) morceaux.add('$ruptures en rupture');
    if (perimes > 0) morceaux.add('$perimes à mettre à jour');
    return morceaux.join(' · ');
  }

  void _apresEnregistrement() {
    if (!mounted) return;
    _recharger();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stock enregistré.')),
    );
  }

  Future<void> _ouvrirImport() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => FeuilleImport(
        pharmacieId: _pharmacieId,
        onSessionExpiree: widget.onSessionExpiree,
      ),
    );
    // Quoi qu'il arrive (même si la fenêtre a été fermée en la glissant), on recharge la liste.
    if (mounted) _recharger();
  }

  Future<void> _ouvrirEdition(Stock s, Medicament? m) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _FeuilleStock(
        titre: 'Modifier le stock',
        medicament: m,
        quantiteInitiale: s.quantite ?? 0,
        prixInitial: s.prix,
        onSessionExpiree: widget.onSessionExpiree,
        onEnregistrer: (medicament, quantite, prix) => _stockService.modifier(
          stockId: s.id,
          pharmacieId: _pharmacieId,
          medicamentId: s.medicamentId,
          quantite: quantite,
          prix: prix,
        ),
      ),
    );
    if (ok == true) _apresEnregistrement();
  }

  Future<void> _ouvrirAjout(_Donnees donnees) async {
    final dejaLa = donnees.stocks.map((s) => s.medicamentId).toSet();
    final choix = donnees.catalogue.where((m) => !dejaLa.contains(m.id)).toList();
    if (choix.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tous les médicaments sont déjà dans votre liste.')),
      );
      return;
    }
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _FeuilleStock(
        titre: 'Ajouter un médicament',
        choix: choix,
        onSessionExpiree: widget.onSessionExpiree,
        onEnregistrer: (medicament, quantite, prix) => _stockService.creer(
          pharmacieId: _pharmacieId,
          medicamentId: medicament!.id,
          quantite: quantite,
          prix: prix,
        ),
      ),
    );
    if (ok == true) _apresEnregistrement();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Donnees>(
      future: _futur,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingList(count: 4);
        }
        if (snapshot.hasError) {
          return StateView(
            icon: Icons.cloud_off_rounded,
            danger: true,
            title: 'Chargement impossible',
            message: messageErreur(snapshot.error!),
            actionLabel: 'Réessayer',
            onAction: _recharger,
          );
        }

        final donnees = snapshot.data!;
        final stocks = [...donnees.stocks]
          ..sort((a, b) => (donnees.medicament(a.medicamentId)?.nom ?? '')
              .toLowerCase()
              .compareTo((donnees.medicament(b.medicamentId)?.nom ?? '').toLowerCase()));
        final nbRuptures = stocks.where((s) => !s.disponible).length;
        final nbPerimes = stocks.where(_perime).length;

        return RefreshIndicator(
          onRefresh: () async {
            _recharger();
            try {
              await _futur;
            } catch (_) {
              // l'erreur est affichée par l'écran lui-même
            }
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              MemaButton(
                label: 'Importer un fichier',
                icon: Icons.upload_file_rounded,
                onPressed: _ouvrirImport,
              ),
              const SizedBox(height: 10),
              MemaButton(
                label: 'Ajouter un médicament',
                icon: Icons.add_rounded,
                variant: 'outline',
                onPressed: () => _ouvrirAjout(donnees),
              ),
              const SizedBox(height: 14),
              if (stocks.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 10),
                  child: Text(_resume(stocks.length, nbRuptures, nbPerimes),
                      style: AppText.caption),
                ),
              if (stocks.isEmpty)
                const StateView(
                  icon: Icons.inventory_2_outlined,
                  title: 'Aucun médicament',
                  message:
                  'Importez un fichier ou ajoutez les médicaments de votre pharmacie pour que les patients puissent les trouver.',
                )
              else
                for (var i = 0; i < stocks.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Reveal(
                      index: i,
                      child: _carte(stocks[i], donnees.medicament(stocks[i].medicamentId)),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _carte(Stock s, Medicament? m) {
    final dispo = s.disponible;
    final surCommande = s.surCommande;
    final couleur = dispo
        ? AppColors.primary
        : (surCommande ? AppColors.primaryDark : AppColors.danger);
    final fond = dispo
        ? AppColors.primaryTint
        : (surCommande ? AppColors.accentTint : AppColors.dangerTint);
    final etiquette = dispo ? 'Disponible' : (surCommande ? 'Sur commande' : 'Rupture');
    final icone = dispo
        ? Icons.check_circle_rounded
        : (surCommande ? Icons.local_shipping_outlined : Icons.cancel_rounded);
    final quantite = s.quantite;
    final prix = s.prix;
    final origine = s.libelleSource;

    return MemaCard(
      onTap: () => _ouvrirEdition(s, m),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: fond,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.medication_liquid_rounded, color: couleur),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m?.nom ?? 'Médicament n°${s.medicamentId}', style: AppText.title),
                if (m != null) ...[
                  const SizedBox(height: 2),
                  Text(m.dosage, style: AppText.caption),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusChip(
                      label: etiquette,
                      icon: icone,
                      color: couleur,
                      background: fond,
                    ),
                    if (_perime(s))
                      const StatusChip(
                        label: 'À mettre à jour',
                        icon: Icons.update_rounded,
                        color: AppColors.primaryDark,
                        background: AppColors.accentTint,
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Mis à jour ${tempsEcoule(s.dateMiseAJour)}'
                      '${origine.isNotEmpty ? ' · $origine' : ''}',
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                quantite != null ? '$quantite' : '—',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: couleur),
              ),
              Text(quantite != null ? 'en stock' : 'quantité inconnue',
                  style: AppText.caption),
              const SizedBox(height: 6),
              Text(prix != null ? formatPrix(prix) : 'prix non renseigné',
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fenêtre du bas, utilisée pour modifier un stock ou en créer un.
class _FeuilleStock extends StatefulWidget {
  final String titre;
  final List<Medicament>? choix; // renseigné seulement pour une création
  final Medicament? medicament; // renseigné seulement pour une modification
  final int quantiteInitiale;
  final double? prixInitial;
  final VoidCallback onSessionExpiree;
  final Future<void> Function(Medicament? medicament, int quantite, double prix) onEnregistrer;

  const _FeuilleStock({
    required this.titre,
    this.choix,
    this.medicament,
    this.quantiteInitiale = 0,
    this.prixInitial,
    required this.onSessionExpiree,
    required this.onEnregistrer,
  });

  @override
  State<_FeuilleStock> createState() => _FeuilleStockState();
}

class _FeuilleStockState extends State<_FeuilleStock> {
  late final TextEditingController _quantite =
  TextEditingController(text: '${widget.quantiteInitiale}');
  late final TextEditingController _prix = TextEditingController(text: _prixEnTexte());
  Medicament? _choisi;
  bool _enCours = false;
  String? _erreur;

  String _prixEnTexte() {
    final p = widget.prixInitial;
    if (p == null) return '';
    return p == p.roundToDouble() ? p.round().toString() : p.toString();
  }

  @override
  void dispose() {
    _quantite.dispose();
    _prix.dispose();
    super.dispose();
  }

  void _ajuster(int delta) {
    final actuel = int.tryParse(_quantite.text.trim()) ?? 0;
    final int nouveau = (actuel + delta).clamp(0, 100000).toInt();
    _quantite.text = '$nouveau';
  }

  Future<void> _enregistrer({bool rupture = false}) async {
    final medicament = widget.medicament ?? _choisi;
    if (widget.choix != null && medicament == null) {
      setState(() => _erreur = 'Choisissez un médicament.');
      return;
    }
    final quantite = rupture ? 0 : int.tryParse(_quantite.text.trim());
    final prix = double.tryParse(_prix.text.trim().replaceAll(' ', '').replaceAll(',', '.'));
    if (quantite == null || quantite < 0) {
      setState(() => _erreur = 'La quantité doit être un nombre entier (0 ou plus).');
      return;
    }
    if (prix == null || prix < 0) {
      setState(() => _erreur = 'Entrez un prix valide, par exemple 1500.');
      return;
    }

    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await widget.onEnregistrer(medicament, quantite, prix);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      if (e is SessionExpireeException) {
        Navigator.of(context).pop(false);
        widget.onSessionExpiree();
        return;
      }
      setState(() {
        _erreur = messageErreur(e);
        _enCours = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final modification = widget.choix == null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.titre, style: AppText.h2),
            if (modification && widget.medicament != null) ...[
              const SizedBox(height: 4),
              Text('${widget.medicament!.nom} · ${widget.medicament!.dosage}',
                  style: AppText.body),
            ],
            const SizedBox(height: 18),
            if (!modification) ...[
              DropdownButtonFormField<Medicament>(
                value: _choisi,
                isExpanded: true,
                decoration: const InputDecoration(hintText: 'Choisir un médicament'),
                items: widget.choix!
                    .map((m) => DropdownMenuItem<Medicament>(
                  value: m,
                  child: Text('${m.nom} · ${m.dosage}',
                      overflow: TextOverflow.ellipsis),
                ))
                    .toList(),
                onChanged: (m) => setState(() => _choisi = m),
              ),
              const SizedBox(height: 16),
            ],
            Text('Quantité en stock',
                style: AppText.caption
                    .copyWith(fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            Row(
              children: [
                _BoutonRond(icon: Icons.remove_rounded, onTap: () => _ajuster(-1)),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: _quantite,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                _BoutonRond(icon: Icons.add_rounded, onTap: () => _ajuster(1)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Prix',
                style: AppText.caption
                    .copyWith(fontWeight: FontWeight.w700, color: AppColors.text)),
            const SizedBox(height: 8),
            TextField(
              controller: _prix,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(hintText: 'Ex. 1500', suffixText: 'FCFA'),
            ),
            if (_erreur != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.dangerTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: AppColors.danger, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_erreur!,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13, height: 1.4)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            MemaButton(
              label: 'Enregistrer',
              icon: Icons.check_rounded,
              loading: _enCours,
              onPressed: () => _enregistrer(),
            ),
            if (modification)
              Center(
                child: TextButton(
                  onPressed: _enCours ? null : () => _enregistrer(rupture: true),
                  child: const Text('Mettre en rupture',
                      style: TextStyle(
                          color: AppColors.danger, fontWeight: FontWeight.w700)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BoutonRond extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _BoutonRond({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primaryTint,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon, color: AppColors.primary),
        ),
      ),
    );
  }
}