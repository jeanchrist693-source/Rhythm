// lib/ecrans/alimentation/courses/article_garde_manger_ecran.dart
//
// UN ALIMENT DU GARDE-MANGER — sa fiche, ou l'ajout à la main :
// - l'échéance en grand (« à consommer d'ici demain ») ;
// - COMMENT LE GARDER : le conseil du guide et les durées (frigo,
//   congélateur, armoire, une fois ouvert) ;
// - où il est : le changer RECALCULE la date (au congélateur elle
//   s'allonge ; décongelé, 1 à 2 jours) ; la date elle-même ;
// - « Ouvert aujourd'hui » (la date ne peut que raccourcir) ; ce qu'il en
//   reste ; « essentiel » : fini, il revient seul sur la liste ;
// - « C'est fini », « Jeté » (en deux temps : sa valeur compte au
//   gaspillage, sans reproche), « Sur la liste », « Retirer » (une erreur).
// À l'ajout, le nom propose le rayon, l'emplacement et la date.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_courses.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/base_aliments.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/conservation.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/rayons.dart';
import '../../../modele/etat_sante.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/suivi_clavier.dart';
import '../../../widgets/toast.dart';
import '../pieces_alimentation.dart';
import '../recettes/portion_recette_ecran.dart';
import '../ia/conservation_ia.dart';
import 'pieces_courses.dart';

class ArticleGardeMangerEcran extends ConsumerStatefulWidget {
  const ArticleGardeMangerEcran({super.key, required this.retour, this.id});

  final String retour;

  /// L'aliment ; `null` : en ajouter un.
  final String? id;

  @override
  ConsumerState<ArticleGardeMangerEcran> createState() =>
      _ArticleGardeMangerEcranState();
}

class _ArticleGardeMangerEcranState
    extends ConsumerState<ArticleGardeMangerEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<ArticleGardeMangerEcran> {
  final _nom = TextEditingController();
  final _quantite = TextEditingController();
  final _prix = TextEditingController();
  final _focus = List.generate(3, (_) => FocusNode());

  // L'ajout : le brouillon.
  Rayon _rayon = Rayon.autre;
  Emplacement _ou = Emplacement.frigo;
  bool _ouChoisi = false;
  DateTime? _date;
  bool _dateChoisie = false;
  Unite _unite = Unite.unite;
  bool _essentiel = false;

  bool get _ajout => widget.id == null;

  static String _texte(double x) =>
      x == x.roundToDouble() ? '${x.round()}' : '$x'.replaceAll('.', ',');

  @override
  void initState() {
    super.initState();
    for (final f in _focus) {
      surveillerClavier(f);
    }
    final a = widget.id == null
        ? null
        : ref.read(coursesProvider).enReserve(widget.id!);
    if (a?.quantite != null) _quantite.text = _texte(a!.quantite!.valeur);
  }

  @override
  void dispose() {
    libererClavier();
    _nom.dispose();
    _quantite.dispose();
    _prix.dispose();
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  /// Le nom change : rayon, emplacement et date suivent (tant qu'on ne les
  /// a pas choisis soi-même).
  void _nomChange(String nom) {
    final base = ref.read(baseAlimentsProvider).value;
    final auj = jourDe(ref.read(aujourdhuiProvider));
    setState(() {
      _rayon = rayonDe(nom, base);
      final g = conservationDe(
        nom,
        _rayon,
        apprises: ref.read(coursesProvider).conservations,
      );
      if (!_ouChoisi) {
        _ou = g.expressions.isEmpty
            ? (_rayon.emplacement ?? Emplacement.armoire)
            : g.ideal;
      }
      if (!_dateChoisie) _date = peremptionProposee(g, _ou, auj);
    });
  }

  void _ranger() {
    if (transitionEnCours) return;
    final tr = context.tr;
    final nom = _nom.text.trim();
    if (nom.isEmpty) {
      montrerToast(context, tr.nomRequis);
      return;
    }
    final q = ChampNombre.lire(_quantite);
    final notifier = ref.read(coursesProvider.notifier);
    notifier.ranger([
      ArticleGardeManger(
        id: notifier.nouvelId('gm'),
        nom: nom[0].toUpperCase() + nom.substring(1),
        emplacement: _ou,
        rayon: _rayon,
        entre: ref.read(horlogeProvider)(),
        quantite: q == null || q <= 0 ? null : Quantite(q, _unite),
        peremption: _date,
        prix: ChampNombre.lire(_prix),
        essentiel: _essentiel,
      ),
    ]);
    HapticFeedback.lightImpact();
    montrerToast(context, tr.alimentRange(nom));
    retirerEcran(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final auj = ref.watch(aujourdhuiProvider);
    if (_ajout) return _formulaire(tr, auj);
    final a = ref.watch(coursesProvider).enReserve(widget.id!);
    if (a == null) {
      return PageSecondaire(retour: widget.retour, enfants: const []);
    }
    return _fiche(tr, auj, a);
  }

  // ═══ L'ajout ════════════════════════════════════════════════════════════

  Widget _formulaire(AppLocalizations tr, DateTime auj) {
    final apprises = ref.watch(coursesProvider).conservations;
    final g = conservationDe(_nom.text, _rayon, apprises: apprises);
    final nom = _nom.text.trim();
    String unite(Unite u) =>
        u.symbole ?? (u == Unite.paquet ? tr.unitePaquet : tr.uniteUnite);
    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(titre: tr.ajouterAuGardeManger),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.nomProduit),
            ChampRhythm(
              controleur: _nom,
              focus: _focus[0],
              indice: tr.indiceAlimentGardeManger,
              actionClavier: TextInputAction.next,
              onChanged: _nomChange,
            ),
            if (nom.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                g.conseil,
                style: RhythmTypo.texte(13, couleur: RhythmCouleurs.peche),
              ),
              if (repereDeLIa(nom, apprises)) ...[
                const SizedBox(height: 4),
                Text(tr.iaRepereDeLIa, style: RhythmTypo.petit),
              ] else if (nom.length >= 3 && horsDuGuide(nom, apprises)) ...[
                const SizedBox(height: 12),
                DemandeConservation(
                  nom: nom,
                  rayon: _rayon,
                  onAppris: (c) => setState(() {
                    if (!_ouChoisi) _ou = c.ideal;
                    if (!_dateChoisie) {
                      _date = peremptionProposee(c, _ou, jourDe(auj));
                    }
                  }),
                ),
              ],
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.quantiteFacultatif),
            ChampNombre(controleur: _quantite, focus: _focus[1], decimales: 2),
            const SizedBox(height: 12),
            PucesChoix<Unite>(
              options: [for (final u in Unite.values) (u, unite(u))],
              valeur: _unite,
              onChanged: (u) => setState(() => _unite = u),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.ou),
            ChoixEmplacement(
              valeur: _ou,
              onChanged: (e) => setState(() {
                _ou = e;
                _ouChoisi = true;
                if (!_dateChoisie) {
                  _date = peremptionProposee(g, e, jourDe(auj));
                }
              }),
            ),
            const SizedBox(height: 8),
            ChoixDate(
              aujourdhui: auj,
              date: _date,
              onChanged: (d) => setState(() {
                _date = d;
                _dateChoisie = true;
              }),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.prixPayeFacultatif),
            ChampNombre(
              controleur: _prix,
              focus: _focus[2],
              decimales: 2,
              suffixe: r'$',
              actionClavier: TextInputAction.done,
            ),
          ],
        ),
        LigneReglage(
          libelle: tr.essentiel,
          detail: tr.essentielDetail,
          droite: Interrupteur(
            valeur: _essentiel,
            onChanged: (v) => setState(() => _essentiel = v),
          ),
        ),
        BoutonPlein(
          libelle: tr.ranger,
          largeurPleine: true,
          hauteur: 52,
          taillePolice: 15,
          onTap: _ranger,
        ),
      ],
    );
  }

  // ═══ La fiche ═══════════════════════════════════════════════════════════

  Widget _fiche(AppLocalizations tr, DateTime auj, ArticleGardeManger a) {
    final f = context.formats;
    final notifier = ref.read(coursesProvider.notifier);
    final apprises = ref.watch(coursesProvider).conservations;
    final g = conservationDArticle(a, apprises: apprises);
    final jours = joursRestants(a, auj);
    final q = a.quantite;
    final recette = ref.watch(recettesProvider).recette(a.recetteId);

    void finir() {
      final revenu = notifier.finir(a.id);
      HapticFeedback.lightImpact();
      montrerToast(
        context,
        revenu == null ? tr.finiNote(a.nom) : tr.finiReassort(a.nom),
      );
      retirerEcran(context);
    }

    final durees = [
      if (g.frigo != null)
        tr.dureeA(tr.emplacementFrigo, f.dureeGuide(g.frigo!, tr)),
      if (g.congelo != null)
        tr.dureeA(tr.emplacementCongelateur, f.dureeGuide(g.congelo!, tr)),
      if (g.ambiant != null)
        tr.dureeA(tr.aTemperatureAmbiante, f.dureeGuide(g.ambiant!, tr)),
      if (g.ouvert != null)
        tr.dureeA(tr.uneFoisOuvert, f.dureeGuide(g.ouvert!, tr)),
    ];

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: a.nom,
          surtitre: Text(
            [
              a.emplacement.libelle(tr),
              if (a.ouvertLe != null) tr.ouvertLe(f.dateCourte(a.ouvertLe!)),
            ].join(' · '),
            style: RhythmTypo.surtitre,
          ),
        ),
        Text(
          jours == null
              ? tr.sansDate
              : jours < 0
              ? tr.datePassee(-jours)
              : jours <= 1
              ? tr.aConsommerDici(f.echeance(jours, tr))
              : tr.encoreJours(jours),
          style: RhythmTypo.titre(24, couleur: couleurEcheance(jours)),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.commentLeGarder),
            Text(g.conseil, style: RhythmTypo.texte(15)),
            if (durees.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(durees.join('\n'), style: RhythmTypo.detail),
            ],
            if (!a.restes && repereDeLIa(a.nom, apprises)) ...[
              const SizedBox(height: 8),
              Text(tr.iaRepereDeLIa, style: RhythmTypo.petit),
            ] else if (!a.restes && horsDuGuide(a.nom, apprises)) ...[
              const SizedBox(height: 14),
              DemandeConservation(
                nom: a.nom,
                rayon: a.rayon,
                onAppris: (c) {
                  // La date proposée par le rayon (pas choisie à la main)
                  // suit le nouveau repère.
                  final entre = jourDe(a.entre);
                  final avant = peremptionProposee(
                    conservationDuRayon(a.rayon),
                    a.emplacement,
                    entre,
                  );
                  final apres = peremptionProposee(c, a.emplacement, entre);
                  if (apres != null && a.peremption == avant) {
                    notifier.modifierRange(
                      a.copierAvec(peremption: () => apres),
                    );
                  }
                },
              ),
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.ou),
            ChoixEmplacement(
              valeur: a.emplacement,
              onChanged: (e) {
                notifier.deplacer(a.id, e);
                final n = ref.read(coursesProvider).enReserve(a.id);
                if (n?.peremption != null) {
                  montrerToast(
                    context,
                    tr.deplaceJusquau(
                      e.libelle(tr),
                      f.dateCourte(n!.peremption!),
                    ),
                  );
                }
              },
            ),
            const SizedBox(height: 8),
            ChoixDate(
              aujourdhui: auj,
              date: a.peremption,
              onChanged: (d) =>
                  notifier.modifierRange(a.copierAvec(peremption: () => d)),
            ),
            if (a.ouvertLe == null) ...[
              const Filet(),
              LigneReglage(
                libelle: tr.ouvertAujourdhui,
                detail: g.ouvert == null
                    ? null
                    : tr.ouvertDetail(f.dureeGuide(g.ouvert!, tr)),
                onTap: () {
                  notifier.ouvrir(a.id);
                  HapticFeedback.selectionClick();
                },
              ),
            ],
          ],
        ),
        if (q != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.ilEnReste),
              if (q.unite == Unite.unite)
                LigneReglage(
                  libelle: a.restes ? tr.nombreDePortions : tr.combien,
                  droite: CompteurRhythm(
                    valeur: q.valeur.round(),
                    min: 0,
                    max: 99,
                    largeurValeur: 44,
                    affichage: (v) => '$v',
                    onChanged: (v) {
                      if (v == 0) {
                        finir();
                      } else {
                        notifier.utiliser(a.id, v.toDouble());
                      }
                    },
                  ),
                )
              else
                ChampNombre(
                  controleur: _quantite,
                  focus: _focus[1],
                  decimales: 2,
                  suffixe: q.unite.symbole ?? tr.unitePaquet,
                  actionClavier: TextInputAction.done,
                  onValider: (_) {
                    final v = ChampNombre.lire(_quantite);
                    if (v == null) return;
                    if (v <= 0) {
                      finir();
                    } else {
                      notifier.utiliser(a.id, v);
                      montrerToast(context, tr.quantiteMiseAJour);
                    }
                  },
                ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (recette != null)
              LigneReglage(
                libelle: tr.mangerUnePortionCourt,
                detail: tr.mangerUnePortionDetail,
                onTap: () => pousserEcran(
                  context,
                  PortionRecetteEcran(
                    recette: recette,
                    jour: auj,
                    moment: momentPourHeure(auj),
                    retour: a.nom,
                  ),
                ),
              )
            else if (!a.restes) ...[
              LigneReglage(
                libelle: tr.essentiel,
                detail: tr.essentielDetail,
                droite: Interrupteur(
                  valeur: a.essentiel,
                  onChanged: (v) =>
                      notifier.modifierRange(a.copierAvec(essentiel: v)),
                ),
              ),
              const Filet(),
              LigneReglage(
                libelle: tr.surLaListeAction,
                detail: tr.surLaListeDetail,
                onTap: () {
                  notifier.remettreSurLaListe(a);
                  HapticFeedback.lightImpact();
                  montrerToast(context, tr.articleAjoute(a.nom));
                },
              ),
            ],
            if (a.prix != null) ...[
              const Filet(),
              LigneReglage(
                libelle: tr.prixPaye,
                valeur: f.prix(a.prix!),
                detail: a.magasin,
              ),
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoutonPlein(
              libelle: tr.cestFini,
              largeurPleine: true,
              hauteur: 52,
              taillePolice: 15,
              onTap: finir,
            ),
            const SizedBox(height: 12),
            BoutonSuppression(
              libelle: tr.jete,
              confirmation: tr.toucherPourJeter,
              couleur: RhythmCouleurs.blanc,
              onConfirme: () {
                notifier.jeter(a.id);
                montrerToast(
                  context,
                  a.prix == null ? tr.jeteNote : tr.jeteValeur(f.prix(a.prix!)),
                );
                retirerEcran(context);
              },
            ),
            const SizedBox(height: 12),
            BoutonSuppression(
              libelle: tr.retirerErreur,
              confirmation: tr.toucherPourRetirer,
              onConfirme: () {
                notifier.retirerDuGardeManger(a.id);
                retirerEcran(context);
              },
            ),
          ],
        ),
      ],
    );
  }
}
