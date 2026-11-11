import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/pharmacie.dart';
import '../models/utilisateur.dart';
import '../services/admin_service.dart';
import '../services/session_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../widgets/admin_widgets.dart';
import '../widgets/mema_widgets.dart';

class _Donnees {
  final List<Utilisateur> comptes;
  final List<Pharmacie> pharmacies;
  _Donnees(this.comptes, this.pharmacies);

  String nomPharmacie(int? id) {
    if (id == null) return 'Toutes les pharmacies';
    for (final p in pharmacies) {
      if (p.id == id) return p.nom;
    }
    return 'Pharmacie n°$id';
  }
}

class AdminComptesTab extends StatefulWidget {
  final VoidCallback onSessionExpiree;
  const AdminComptesTab({super.key, required this.onSessionExpiree});

  @override
  State<AdminComptesTab> createState() => _AdminComptesTabState();
}

class _AdminComptesTabState extends State<AdminComptesTab> {
  final AdminService _service = AdminService();
  late Future<_Donnees> _futur;

  @override
  void initState() {
    super.initState();
    _futur = _charger();
  }

  Future<_Donnees> _charger() => avecSession(() async {
    final comptes = await _service.comptes();
    final pharmacies = await _service.pharmacies();
    return _Donnees(comptes, pharmacies);
  }, widget.onSessionExpiree);

  void _recharger() {
    setState(() {
      _futur = _charger();
    });
  }

  Future<void> _creer(_Donnees donnees) async {
    await ouvrirFeuille<bool>(
      context,
          (_) => FeuilleCompte(
        pharmacies: donnees.pharmacies,
        onSessionExpiree: widget.onSessionExpiree,
      ),
    );
    if (mounted) _recharger();
  }

  Future<void> _supprimer(Utilisateur u) async {
    final ok = await confirmer(
      context,
      titre: 'Supprimer ce compte ?',
      message: '${u.nom} (${u.telephone}) ne pourra plus se connecter. '
          "Sa connexion en cours peut rester valable jusqu'à 12 h.",
      action: 'Supprimer',
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await avecSession(() => _service.supprimerCompte(u.id), widget.onSessionExpiree);
      if (mounted) _recharger();
    } catch (e) {
      if (mounted) afficherErreur(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Donnees>(
      future: _futur,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingList(count: 3);
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
        final comptes = [...donnees.comptes]..sort((a, b) => a.nom.compareTo(b.nom));
        final monId = SessionService.utilisateur?.id;

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
                label: 'Créer un compte',
                icon: Icons.person_add_alt_1_rounded,
                variant: 'accent',
                onPressed: () => _creer(donnees),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  '${comptes.length} compte${comptes.length > 1 ? 's' : ''}',
                  style: AppText.caption,
                ),
              ),
              for (var i = 0; i < comptes.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Reveal(
                    index: i,
                    child: _carte(comptes[i], donnees, comptes[i].id == monId),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _carte(Utilisateur u, _Donnees donnees, bool moi) {
    final admin = u.estAdmin;
    return MemaCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: admin ? AppColors.accentTint : AppColors.primaryTint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              admin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
              color: admin ? AppColors.accent : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.nom, style: AppText.title),
                const SizedBox(height: 2),
                Text(u.telephone, style: AppText.caption),
                Text(donnees.nomPharmacie(u.pharmacieId), style: AppText.caption),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    StatusChip(
                      label: u.libelleRole,
                      icon: admin ? Icons.shield_rounded : Icons.badge_rounded,
                      color: admin ? AppColors.primaryDark : AppColors.primary,
                      background: admin ? AppColors.accentTint : AppColors.primaryTint,
                    ),
                    if (moi)
                      const StatusChip(
                        label: 'Vous',
                        icon: Icons.person_pin_rounded,
                        color: AppColors.textSoft,
                        background: AppColors.border,
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (!moi)
            IconButton(
              onPressed: () => _supprimer(u),
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
            ),
        ],
      ),
    );
  }
}

/// Formulaire de création d'un compte, puis affichage des identifiants à transmettre.
class FeuilleCompte extends StatefulWidget {
  final List<Pharmacie> pharmacies;
  final Pharmacie? preselection;
  final VoidCallback onSessionExpiree;

  const FeuilleCompte({
    super.key,
    required this.pharmacies,
    this.preselection,
    required this.onSessionExpiree,
  });

  @override
  State<FeuilleCompte> createState() => _FeuilleCompteState();
}

class _FeuilleCompteState extends State<FeuilleCompte> {
  final TextEditingController _nom = TextEditingController();
  final TextEditingController _telephone = TextEditingController();
  final TextEditingController _motDePasse = TextEditingController();
  String _role = 'PHARMACIEN';
  Pharmacie? _pharmacie;
  bool _cacher = true;
  bool _enCours = false;
  String? _erreur;

  // Identifiants affichés après la création
  bool _cree = false;
  String _telephoneCree = '';
  String _motDePasseCree = '';

  @override
  void initState() {
    super.initState();
    _pharmacie = widget.preselection;
  }

  @override
  void dispose() {
    _nom.dispose();
    _telephone.dispose();
    _motDePasse.dispose();
    super.dispose();
  }

  String _generer() {
    const caracteres = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final hasard = Random.secure();
    return List.generate(10, (_) => caracteres[hasard.nextInt(caracteres.length)]).join();
  }

  Future<void> _enregistrer() async {
    final nom = _nom.text.trim();
    final telephone = _telephone.text.trim();
    final motDePasse = _motDePasse.text;
    if (nom.isEmpty || telephone.isEmpty) {
      setState(() => _erreur = 'Le nom et le téléphone sont obligatoires.');
      return;
    }
    if (motDePasse.length < 8) {
      setState(() => _erreur = 'Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    if (_role != 'ADMIN' && _pharmacie == null) {
      setState(() => _erreur = 'Choisissez la pharmacie de ce compte.');
      return;
    }

    setState(() {
      _enCours = true;
      _erreur = null;
    });
    try {
      await AdminService().creerCompte(
        pharmacieId: _role == 'ADMIN' ? null : _pharmacie!.id,
        nom: nom,
        telephone: telephone,
        motDePasse: motDePasse,
        role: _role,
      );
      if (!mounted) return;
      setState(() {
        _cree = true;
        _telephoneCree = telephone;
        _motDePasseCree = motDePasse;
        _enCours = false;
      });
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
    return CorpsFeuille(children: _cree ? _vueIdentifiants() : _vueFormulaire());
  }

  List<Widget> _vueFormulaire() {
    return [
      const Text('Nouveau compte', style: AppText.h2),
      const SizedBox(height: 18),
      const EtiquetteChamp('Rôle'),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final r in const [
            ['PHARMACIEN', 'Pharmacien'],
            ['AGENT', 'Agent'],
            ['ADMIN', 'Administrateur'],
          ])
            ChoiceChip(
              label: Text(r[1]),
              selected: _role == r[0],
              selectedColor: AppColors.primaryTint,
              onSelected: (_) => setState(() => _role = r[0]),
            ),
        ],
      ),
      const SizedBox(height: 16),
      if (_role != 'ADMIN') ...[
        const EtiquetteChamp('Pharmacie'),
        DropdownButtonFormField<Pharmacie>(
          value: _pharmacie,
          isExpanded: true,
          decoration: const InputDecoration(hintText: 'Choisir la pharmacie'),
          items: widget.pharmacies
              .map((p) => DropdownMenuItem<Pharmacie>(
            value: p,
            child: Text(p.nom, overflow: TextOverflow.ellipsis),
          ))
              .toList(),
          onChanged: (p) => setState(() => _pharmacie = p),
        ),
        const SizedBox(height: 14),
      ],
      TextField(
        controller: _nom,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          hintText: 'Nom complet',
          prefixIcon: Icon(Icons.person_rounded, color: AppColors.primary),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _telephone,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          hintText: 'Téléphone (sert d\'identifiant)',
          prefixIcon: Icon(Icons.phone_rounded, color: AppColors.primary),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _motDePasse,
        obscureText: _cacher,
        decoration: InputDecoration(
          hintText: 'Mot de passe (8 caractères minimum)',
          prefixIcon: const Icon(Icons.lock_rounded, color: AppColors.primary),
          suffixIcon: IconButton(
            icon: Icon(
              _cacher ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: AppColors.textSoft,
            ),
            onPressed: () => setState(() => _cacher = !_cacher),
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => setState(() {
            _motDePasse.text = _generer();
            _cacher = false;
          }),
          icon: const Icon(Icons.auto_awesome_rounded, size: 18),
          label: const Text('Générer un mot de passe'),
        ),
      ),
      if (_erreur != null) ...[
        const SizedBox(height: 4),
        BoiteMessage.erreur(_erreur!),
      ],
      const SizedBox(height: 14),
      MemaButton(
        label: 'Créer le compte',
        icon: Icons.check_rounded,
        loading: _enCours,
        onPressed: _enregistrer,
      ),
    ];
  }

  List<Widget> _vueIdentifiants() {
    final texte = 'Application MEMA\nTéléphone : $_telephoneCree\nMot de passe : $_motDePasseCree';
    return [
      const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 28),
          SizedBox(width: 10),
          Expanded(child: Text('Compte créé', style: AppText.h2)),
        ],
      ),
      const SizedBox(height: 14),
      const BoiteMessage.info(
        "Notez ces identifiants maintenant et transmettez-les à la personne : le mot de passe "
            "ne pourra plus être affiché ensuite.",
      ),
      const SizedBox(height: 12),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Téléphone', style: AppText.caption),
            Text(_telephoneCree,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 10),
            const Text('Mot de passe', style: AppText.caption),
            Text(_motDePasseCree,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'monospace')),
          ],
        ),
      ),
      const SizedBox(height: 14),
      MemaButton(
        label: 'Copier les identifiants',
        icon: Icons.copy_rounded,
        variant: 'outline',
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: texte));
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Identifiants copiés.')),
          );
        },
      ),
      const SizedBox(height: 10),
      MemaButton(
        label: 'Terminer',
        icon: Icons.check_rounded,
        onPressed: () => Navigator.of(context).pop(true),
      ),
    ];
  }
}