// lib/ecrans/alimentation/portion_ecran.dart
//
// COMBIEN : la quantité d'un aliment, avant de l'ajouter à un repas (ou
// pour la modifier). Quatre entrées :
// - [PortionEcran.aliment] : un aliment de la base — ses portions du FCÉN
//   (« 1 moyen · 118 g », « 250 ml · 185 g »), 100 g, ou les grammes tapés ;
//   le nom inscrit au journal se modifie (proposé : le mot cherché) ;
// - [PortionEcran.produit] : un de mes produits — le nombre de portions ;
// - [PortionEcran.modele] : un aliment récent, à ajouter de nouveau ;
// - [PortionEcran.edition] : une entrée du journal (quantité, moment ;
//   « Retirer du repas » en deux temps).
// Un compteur par demi-portion, les calories et les macronutriments en
// direct, le moment ; « Ajouter au dîner ».

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_alimentation.dart';
import '../../l10n/traductions.dart';
import '../../modele/alimentation/alimentation.dart';
import '../../modele/alimentation/base_aliments.dart';
import '../../modele/alimentation/etat_alimentation.dart';
import '../../modele/alimentation/nutriments.dart';
import '../../modele/etat_sante.dart';
import '../../modele/modeles.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/boutons.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/suivi_clavier.dart';
import '../../widgets/toast.dart';
import 'pieces_alimentation.dart';

class PortionEcran extends ConsumerStatefulWidget {
  const PortionEcran.aliment({
    super.key,
    required AlimentBase this.aliment,
    required this.jour,
    required this.moment,
    required this.retour,
    this.nomPropose,
  }) : produit = null,
       modele = null,
       edition = false;

  const PortionEcran.produit({
    super.key,
    required Produit this.produit,
    required this.jour,
    required this.moment,
    required this.retour,
  }) : aliment = null,
       modele = null,
       nomPropose = null,
       edition = false;

  const PortionEcran.modele({
    super.key,
    required EntreeJournal this.modele,
    required this.jour,
    required this.moment,
    required this.retour,
  }) : aliment = null,
       produit = null,
       nomPropose = null,
       edition = false;

  PortionEcran.edition({
    super.key,
    required EntreeJournal entree,
    required this.retour,
  }) : modele = entree,
       jour = entree.jour,
       moment = entree.moment,
       aliment = null,
       produit = null,
       nomPropose = null,
       edition = true;

  final AlimentBase? aliment;
  final Produit? produit;
  final EntreeJournal? modele;
  final bool edition;
  final DateTime jour;
  final MomentRepas moment;
  final String retour;

  /// Le nom à inscrire au journal (le mot cherché).
  final String? nomPropose;

  @override
  ConsumerState<PortionEcran> createState() => _PortionEcranState();
}

class _PortionEcranState extends ConsumerState<PortionEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<PortionEcran> {
  final _grammes = TextEditingController();
  final _focusGrammes = FocusNode();
  late final TextEditingController _nom;
  final _focusNom = FocusNode();

  late MomentRepas _moment = widget.moment;

  /// Les portions proposées (aliment de la base) et la choisie.
  late final List<Portion> _portions;
  int _choisie = 0;

  /// Le nombre de portions, en demis (2 = une portion).
  int _demis = 2;

  /// Les grammes tapés remplacent la portion.
  bool get _enGrammes => ChampNombre.lire(_grammes) != null;

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focusNom);
    surveillerClavier(_focusGrammes);
    final a = widget.aliment;
    _nom = TextEditingController(
      text: widget.nomPropose ?? (a == null ? '' : _premierePartie(a.nom)),
    );
    if (a != null) {
      // Les unités (« 1 moyen ») d'abord, puis les volumes ; sans les
      // portions en grammes (le champ les remplace) ni les doublons.
      final vues = <String>{};
      final utiles = [
        for (final p in a.portions)
          if (vues.add(portionCourte(p.libelle)) &&
              !RegExp(r'^\d+(\.\d+)? ?g$').hasMatch(portionCourte(p.libelle)))
            p,
      ];
      bool estUnite(Portion p) =>
          p.libelle.startsWith('1 ') && !p.libelle.contains('ml');
      _portions = [
        const Portion('100 g', 100),
        ...utiles.where(estUnite),
        ...utiles.where((p) => !estUnite(p)),
      ].take(9).toList();
      // Choisie d'emblée : « 1 moyen », sinon une autre unité, sinon 100 g.
      final moyen = _portions.indexWhere(
        (p) => estUnite(p) && p.libelle.contains('moyen'),
      );
      final une = _portions.indexWhere(estUnite);
      _choisie = moyen >= 0 ? moyen : (une >= 0 ? une : 0);
    } else {
      _portions = const [];
      final m = widget.modele;
      if (m != null) {
        if (m.portions != null && m.portion != null) {
          _demis = (m.portions! * 2).round().clamp(1, 40);
        } else if (m.grammes != null) {
          _grammes.text = _texte(m.grammes!);
        }
      }
    }
  }

  @override
  void dispose() {
    libererClavier();
    _grammes.dispose();
    _focusGrammes.dispose();
    _nom.dispose();
    _focusNom.dispose();
    super.dispose();
  }

  static String _premierePartie(String nom) {
    final i = nom.indexOf(',');
    return i < 0 ? nom : nom.substring(0, i);
  }

  static String _texte(double x) =>
      x == x.roundToDouble() ? '${x.round()}' : x.toStringAsFixed(1);

  /// Un modèle (récent, édition) sans portion : seuls les grammes comptent.
  bool get _modeleEnGrammes {
    final m = widget.modele;
    return m != null && (m.portions == null || m.portion == null);
  }

  double get _nombre => _demis / 2;

  /// Les grammes, quand on les connaît.
  double? get _grammesCalcules {
    final saisis = ChampNombre.lire(_grammes);
    if (saisis != null) return saisis;
    final a = widget.aliment, p = widget.produit, m = widget.modele;
    if (a != null) return _portions[_choisie].grammes * _nombre;
    if (p != null && p.grammesPortion != null) {
      return p.grammesPortion! * _nombre;
    }
    if (m != null && m.grammes != null && m.portions != null) {
      return m.grammes! / m.portions! * _nombre;
    }
    return m?.grammes;
  }

  Nutriments get _nutriments {
    final a = widget.aliment, p = widget.produit, m = widget.modele;
    if (a != null) return a.pour(_grammesCalcules ?? 0);
    if (p != null) {
      final g = ChampNombre.lire(_grammes);
      final n = g != null && p.grammesPortion != null
          ? g / p.grammesPortion!
          : _nombre;
      return p.parPortion * n;
    }
    if (m == null) return Nutriments.zero;
    return _entreeModele(m).nutriments;
  }

  EntreeJournal _entreeModele(EntreeJournal m) {
    final g = ChampNombre.lire(_grammes);
    if (g != null && m.grammes != null) return m.avecQuantite(grammes: g);
    if (!_modeleEnGrammes) return m.avecQuantite(portions: _nombre);
    return m;
  }

  void _enregistrer() {
    if (transitionEnCours) return;
    final tr = context.tr;
    final f = context.formats;
    final notifier = ref.read(alimentationProvider.notifier);
    final maintenant = ref.read(horlogeProvider)();
    final a = widget.aliment, p = widget.produit, m = widget.modele;
    final n = _nutriments;
    if (n.kcal <= 0 && (_grammesCalcules ?? 0) <= 0) {
      montrerToast(context, tr.quantiteRequise);
      return;
    }
    final EntreeJournal entree;
    if (a != null) {
      final saisis = ChampNombre.lire(_grammes);
      final portion = _portions[_choisie];
      final nom = _nom.text.trim();
      entree = EntreeJournal(
        id: notifier.nouvelId('ent'),
        jour: jourDe(widget.jour),
        moment: _moment,
        nom: nom.isEmpty ? _premierePartie(a.nom) : nom,
        source: SourceEntree.base,
        code: a.code,
        grammes: _grammesCalcules,
        portions: saisis == null && _choisie > 0 ? _nombre : null,
        portion: saisis == null && _choisie > 0 ? portion.libelle : null,
        nutriments: n,
        ajoutee: maintenant,
      );
    } else if (p != null) {
      final saisis = ChampNombre.lire(_grammes);
      final nombre = saisis != null && p.grammesPortion != null
          ? saisis / p.grammesPortion!
          : _nombre;
      entree = EntreeJournal(
        id: notifier.nouvelId('ent'),
        jour: jourDe(widget.jour),
        moment: _moment,
        nom: p.nom,
        source: SourceEntree.produit,
        produitId: p.id,
        grammes: p.grammesPortion == null ? null : p.grammesPortion! * nombre,
        portions: nombre,
        portion: p.portion,
        nutriments: n,
        ajoutee: maintenant,
      );
    } else {
      final base = _entreeModele(m!);
      entree = widget.edition
          ? EntreeJournal(
              id: m.id,
              jour: m.jour,
              moment: _moment,
              nom: m.nom,
              source: m.source,
              code: m.code,
              produitId: m.produitId,
              grammes: base.grammes,
              portions: base.portions,
              portion: base.portion,
              nutriments: base.nutriments,
              ajoutee: m.ajoutee,
            )
          : base.copiee(
              id: notifier.nouvelId('ent'),
              jour: jourDe(widget.jour),
              moment: _moment,
              ajoutee: maintenant,
            );
    }
    if (widget.edition) {
      notifier.modifier(entree);
      HapticFeedback.selectionClick();
    } else {
      notifier.ajouter(entree);
      HapticFeedback.lightImpact();
      montrerToast(
        context,
        tr.ajouteA(
          tr.auMoment(_moment.name),
          f.kcalDe(entree.nutriments.kcal, tr),
        ),
      );
    }
    retirerEcran(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final a = widget.aliment, p = widget.produit, m = widget.modele;
    final titre = a != null
        ? (_nom.text.trim().isEmpty ? _premierePartie(a.nom) : _nom.text.trim())
        : (p?.nom ?? m!.nom);
    final sousTitre = a?.nom ?? p?.marque;
    // Le libellé de l'unité comptée.
    final String? unite = a != null
        ? null
        : p != null
        ? portionCourte(p.portion)
        : (_modeleEnGrammes || m!.source == SourceEntree.recette
              ? null
              : portionCourte(m.portion!));
    final grammesConnus =
        a != null || p?.grammesPortion != null || m?.grammes != null;
    final g = _grammesCalcules;

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: titre,
          surtitre: sousTitre == null
              ? null
              : Text(sousTitre, style: RhythmTypo.surtitre),
        ),
        if (a != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EtiquetteChamp(tr.nomDansJournal),
              ChampRhythm(
                controleur: _nom,
                focus: _focusNom,
                indice: _premierePartie(a.nom),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.quantite),
            if (a != null) ...[
              PucesChoix<int>(
                options: [
                  for (final (i, q) in _portions.indexed)
                    (
                      i,
                      i == 0
                          ? q.libelle
                          : '${portionCourte(q.libelle)} · '
                                '${f.g(q.grammes, tr)}',
                    ),
                ],
                valeur: _enGrammes ? null : _choisie,
                onChanged: (i) => setState(() {
                  _choisie = i;
                  _grammes.clear();
                }),
              ),
              const SizedBox(height: 14),
            ],
            if (!_modeleEnGrammes || a != null || p != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      unite == null ? tr.nombreDePortions : tr.nombreDe(unite),
                      maxLines: 2,
                      style: RhythmTypo.texte(15, poids: 500),
                    ),
                  ),
                  Opacity(
                    opacity: _enGrammes ? 0.4 : 1,
                    child: CompteurRhythm(
                      valeur: _demis,
                      min: 1,
                      max: 40,
                      affichage: (d) => f.nombre(d / 2),
                      onChanged: (d) => setState(() {
                        _demis = d;
                        _grammes.clear();
                      }),
                    ),
                  ),
                ],
              ),
            if (grammesConnus) ...[
              const SizedBox(height: 14),
              EtiquetteChamp(
                _modeleEnGrammes && a == null && p == null
                    ? tr.enGrammes
                    : tr.ouEnGrammes,
              ),
              ChampNombre(
                controleur: _grammes,
                focus: _focusGrammes,
                indice: g == null ? null : _texte(g),
                suffixe: 'g',
                actionClavier: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
        ApercuNutriments(nutriments: _nutriments),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.moment),
            PucesChoix<MomentRepas>(
              options: [for (final x in MomentRepas.values) (x, x.libelle(tr))],
              valeur: _moment,
              onChanged: (x) => setState(() => _moment = x),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoutonPlein(
              libelle: widget.edition
                  ? tr.enregistrer
                  : tr.ajouterAu(tr.auMoment(_moment.name)),
              largeurPleine: true,
              hauteur: 52,
              taillePolice: 15,
              onTap: _enregistrer,
            ),
            if (widget.edition) ...[
              const SizedBox(height: 12),
              BoutonSuppression(
                libelle: tr.retirerDuRepas,
                confirmation: tr.toucherPourRetirer,
                onConfirme: () {
                  ref.read(alimentationProvider.notifier).retirer(m!.id);
                  retirerEcran(context, true);
                },
              ),
            ],
          ],
        ),
        if (a != null)
          Text(
            tr.sourceFcen,
            style: RhythmTypo.texte(11, couleur: RhythmCouleurs.texte40),
          ),
      ],
    );
  }
}
