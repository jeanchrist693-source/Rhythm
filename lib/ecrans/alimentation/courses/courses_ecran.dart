// lib/ecrans/alimentation/courses/courses_ecran.dart
//
// LA LISTE DE COURSES : combien d'articles, ce que ça devrait coûter à la
// caisse (d'après les derniers prix payés), le budget du mois ; « Au
// magasin » ; un champ pour ajouter (« 2 kg poulet », « lait x2 » — le
// rayon se devine, les doublons FUSIONNENT : les quantités s'additionnent)
// et les HABITUELS d'un toucher ; puis la liste PAR RAYON, dans l'ordre du
// magasin — chaque ligne dit d'où elle vient (« pour : chili ») et ce qu'il
// reste au garde-manger. En bas : le garde-manger, l'historique, les
// réglages, les taxes du Québec.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_courses.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/base_aliments.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/rayons.dart';
import '../../../modele/alimentation/taxes.dart';
import '../../../modele/etat_sante.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/jauges.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../../../widgets/pression_echelle.dart';
import '../../../widgets/suivi_clavier.dart';
import '../../../widgets/toast.dart';
import '../../sports/pieces_sports.dart';
import 'achats_ecran.dart';
import 'article_liste_ecran.dart';
import 'garde_manger_ecran.dart';
import 'magasin_ecran.dart';
import 'reglages_courses_ecran.dart';
import 'taxes_ecran.dart';

class CoursesEcran extends ConsumerStatefulWidget {
  const CoursesEcran({super.key, required this.retour});

  final String retour;

  @override
  ConsumerState<CoursesEcran> createState() => _CoursesEcranState();
}

class _CoursesEcranState extends ConsumerState<CoursesEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<CoursesEcran> {
  final _saisie = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focus);
  }

  @override
  void dispose() {
    libererClavier();
    _saisie.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _ajouter(String texte, {Rayon? rayon, bool garderFocus = true}) {
    final tr = context.tr;
    final f = context.formats;
    final (nom, q) = lireSaisie(texte);
    if (nom.isEmpty) return;
    final base = ref.read(baseAlimentsProvider).value;
    final (article, fusionne) = ref
        .read(coursesProvider.notifier)
        .ajouter(nom, rayon: rayon ?? rayonDe(nom, base), quantite: q);
    HapticFeedback.lightImpact();
    final quantite = article.quantites.isEmpty
        ? ''
        : ' · ${f.quantites(article.quantites, tr)}';
    montrerToast(
      context,
      fusionne
          ? tr.articleFusionne('${article.nom}$quantite')
          : tr.articleAjoute('${article.nom}$quantite'),
    );
    setState(_saisie.clear);
    if (garderFocus) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(coursesProvider);
    final maintenant = ref.watch(aujourdhuiProvider);
    final bareme = baremeAu(maintenant, etat.reglages.baremes);
    final estimation = estimationListe(etat.liste, etat.achats, bareme);
    final budget = etat.reglages.budgetMois;
    final depense = depenseDuMois(etat.achats, maintenant);
    final aProposer = habituels(etat.achats, etat.liste);
    final titre = tr.listeDeCourses;

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(titre: titre),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              etat.liste.isEmpty
                  ? tr.listeVide
                  : estimation.connus == 0
                  ? tr.articlesNombre(etat.liste.length)
                  : tr.articlesEstimation(
                      etat.liste.length,
                      f.prix(estimation.total),
                    ),
              style: RhythmTypo.texte(15, poids: 500),
            ),
            if (estimation.connus > 0 &&
                estimation.connus < etat.liste.length) ...[
              const SizedBox(height: 2),
              Text(
                tr.prixConnusPour(estimation.connus),
                style: RhythmTypo.petit,
              ),
            ],
            if (budget != null) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr.budgetDuMois(f.prix(depense), f.argent(budget)),
                      style: RhythmTypo.detail,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Jauge(
                progression: depense / budget,
                couleur: depense > budget
                    ? RhythmCouleurs.corail
                    : RhythmCouleurs.peche,
                hauteur: 4,
              ),
            ],
          ],
        ),
        BoutonCapsule(
          picto: Picto.panier,
          libelle: tr.auMagasin,
          plein: true,
          onTap: () => pousserEcran(context, MagasinEcran(retour: titre)),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: ChampRhythm(
                    controleur: _saisie,
                    focus: _focus,
                    indice: tr.indiceAjoutListe,
                    actionClavier: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onValider: _ajouter,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: BoutonRond(
                    couleur: RhythmCouleurs.peche,
                    libelle: tr.ajouter,
                    onTap: () => _ajouter(_saisie.text),
                    child: const PictoRhythm(
                      Picto.plus,
                      taille: 20,
                      epaisseur: 2.4,
                      couleur: RhythmCouleurs.noir,
                    ),
                  ),
                ),
              ],
            ),
            if (aProposer.isNotEmpty && _saisie.text.isEmpty) ...[
              const SizedBox(height: 14),
              Text(tr.tesHabituels, style: RhythmTypo.petit),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (nom, rayon) in aProposer)
                    Puce(
                      libelle: '+ $nom',
                      choisie: false,
                      onTap: () =>
                          _ajouter(nom, rayon: rayon, garderFocus: false),
                    ),
                ],
              ),
            ],
          ],
        ),
        for (final (rayon, articles) in parRayon(
          etat.liste,
          etat.reglages.ordreRayons,
        ))
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(rayon.libelle(tr)),
              for (final (i, a) in articles.indexed)
                _LigneListe(
                  article: a,
                  etat: etat,
                  filet: i > 0,
                  retour: titre,
                ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Filet(),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.frigo,
                couleur: RhythmCouleurs.peche,
              ),
              libelle: tr.gardeManger,
              detail: tr.alimentsNombre(etat.gardeManger.length),
              onTap: () =>
                  pousserEcran(context, GardeMangerEcran(retour: titre)),
            ),
            const Filet(),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.graphique,
                couleur: RhythmCouleurs.texte72,
              ),
              libelle: tr.historiqueEpiceries,
              detail: etat.achats.isEmpty
                  ? tr.aucuneEpicerie
                  : tr.depenseCeMois(f.prix(depense)),
              onTap: () => pousserEcran(context, AchatsEcran(retour: titre)),
            ),
            const Filet(),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.reglages,
                couleur: RhythmCouleurs.texte72,
              ),
              libelle: tr.rayonsMagasinsBudget,
              onTap: () =>
                  pousserEcran(context, ReglagesCoursesEcran(retour: titre)),
            ),
            const Filet(),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.balance,
                couleur: RhythmCouleurs.texte72,
              ),
              libelle: tr.taxesDuQuebec,
              detail: tr.taxesDuQuebecDetail,
              onTap: () => pousserEcran(context, TaxesEcran(retour: titre)),
            ),
          ],
        ),
        if (etat.liste.isNotEmpty)
          BoutonSuppression(
            libelle: tr.viderLaListe,
            confirmation: tr.toucherPourVider,
            couleur: RhythmCouleurs.blanc,
            onConfirme: () => ref.read(coursesProvider.notifier).viderListe(),
          ),
      ],
    );
  }
}

/// Une ligne de la liste : les quantités, d'où elle vient, ce qu'il reste
/// au garde-manger.
class _LigneListe extends StatelessWidget {
  const _LigneListe({
    required this.article,
    required this.etat,
    required this.filet,
    required this.retour,
  });

  final ArticleListe article;
  final EtatCourses etat;
  final bool filet;
  final String retour;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final a = article;
    final deja = dejaAuGardeManger(etat.gardeManger, a.nom);
    final detail = [
      if (a.quantites.isNotEmpty) f.quantites(a.quantites, tr),
      if (a.origines.contains(kOrigineReassort)) tr.revenuSeul,
      if (a.origines.any((o) => o != kOrigineReassort))
        tr.pourOrigines(
          a.origines.where((o) => o != kOrigineReassort).join(', '),
        ),
      if (a.panier != null) tr.auPanierPrix(f.prix(a.panier!.prix)),
    ].join(' · ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LigneCourseListe(
          nom: a.nom,
          detail: detail,
          deja: deja.isEmpty
              ? null
              : tr.dejaAuGardeManger(
                  deja
                      .map(
                        (x) => x.quantite == null
                            ? x.nom
                            : '${x.nom} (${f.quantite(x.quantite!, tr)})',
                      )
                      .join(', '),
                ),
          filet: filet,
          onTap: () => pousserEcran(
            context,
            ArticleListeEcran(id: a.id, retour: retour),
          ),
        ),
      ],
    );
  }
}

/// La ligne d'un article de la liste (avec, en menthe, ce qu'on a déjà).
class LigneCourseListe extends StatelessWidget {
  const LigneCourseListe({
    super.key,
    required this.nom,
    required this.detail,
    required this.deja,
    required this.filet,
    required this.onTap,
  });

  final String nom;
  final String detail;
  final String? deja;
  final bool filet;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (filet) const Filet(),
        Semantics(
          button: true,
          child: PressionEchelle(
            echelle: 0.98,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 11),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nom, style: RhythmTypo.texte(15, poids: 500)),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(detail, style: RhythmTypo.detail),
                  ],
                  if (deja != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      deja!,
                      style: RhythmTypo.texte(
                        13,
                        couleur: RhythmCouleurs.menthe,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
