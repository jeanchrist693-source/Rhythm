// lib/ecrans/alimentation/recettes/recette_ecran.dart
//
// UNE RECETTE : ses moments et sa région, les PORTIONS ajustables (les
// quantités suivent), ce qu'une portion apporte (calculé par la base), ses
// temps ; « Cuisiner » (le mode cuisine), « À la liste » (ce qui manque,
// moins le garde-manger), « Planifier », « Noter au journal » ; les
// ingrédients (en menthe, ce qu'on a déjà), les étapes (minuteurs
// soulignés), la note ; ses restes au garde-manger, combien de fois elle a
// été cuisinée. Le crayon la modifie. « Remplacer un ingrédient » demande
// des remplaçants à l'IA (palier 4).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/libelles_courses.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/modeles.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../courses/pieces_courses.dart';
import '../ia/substitution_ecran.dart';
import '../pieces_alimentation.dart';
import 'ajout_liste_ecran.dart';
import 'cuisine_ecran.dart';
import 'pieces_recettes.dart';
import 'planifier_ecran.dart';
import 'portion_recette_ecran.dart';
import 'recette_formulaire_ecran.dart';

class RecetteEcran extends ConsumerStatefulWidget {
  const RecetteEcran({super.key, required this.id, required this.retour});

  final String id;
  final String retour;

  @override
  ConsumerState<RecetteEcran> createState() => _RecetteEcranState();
}

class _RecetteEcranState extends ConsumerState<RecetteEcran> {
  /// Les portions affichées ; `null` : celles de la recette.
  int? _portions;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final r = ref.watch(recettesProvider).recette(widget.id);
    if (r == null) {
      return PageSecondaire(retour: widget.retour, enfants: const []);
    }
    final courses = ref.watch(coursesProvider);
    final auj = ref.watch(aujourdhuiProvider);
    final portions = _portions ?? r.portions;
    final facteur = portions / r.portions;
    final ingredients = [for (final i in r.ingredients) i.fois(facteur)];
    final stock = [
      for (final a in courses.gardeManger)
        if (!a.restes) a,
    ];
    final restes = restesDe(courses.gardeManger, r.id);
    final enRestes = portionsEnRestes(courses.gardeManger, r.id);
    final libres = [
      for (final i in r.ingredients)
        if (i.libre) i.nom,
    ];
    final titre = r.nom;

    return PageSecondaire(
      retour: widget.retour,
      actions: [
        BoutonPicto(
          picto: Picto.crayon,
          libelle: tr.modifierRecette,
          onTap: () => pousserEcran(
            context,
            RecetteFormulaireEcran(recette: r, retour: titre),
          ),
        ),
      ],
      enfants: [
        TitreSecondaire(
          titre: r.nom,
          surtitre: r.moments.isEmpty && r.region == null
              ? null
              : Text(
                  [
                    for (final m in MomentRepas.values)
                      if (r.moments.contains(m)) m.libelle(tr),
                    ?r.region,
                  ].join(' · '),
                  style: RhythmTypo.surtitre,
                ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ApercuNutriments(nutriments: r.parPortion),
            const SizedBox(height: 10),
            Text(
              [
                tr.parPortion,
                if (r.dureeTotale != null)
                  [
                    if (r.preparation != null)
                      tr.preparationDe(f.minutes(r.preparation!)),
                    if (r.cuisson != null) tr.cuissonDe(f.minutes(r.cuisson!)),
                  ].join(' · '),
              ].join(' · '),
              style: RhythmTypo.petit,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoutonCapsule(
              picto: Picto.couverts,
              libelle: tr.cuisiner,
              plein: true,
              hauteur: 50,
              onTap: () => pousserEcran(
                context,
                CuisineEcran(recette: r, portions: portions, retour: titre),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                BoutonCapsule(
                  picto: Picto.panier,
                  libelle: tr.aLaListe,
                  onTap: () => pousserEcran(
                    context,
                    AjoutListeEcran(
                      titre: tr.aLaListe,
                      sousTitre: tr.pourRecettePortions(
                        r.nom,
                        f.portions(portions.toDouble(), tr),
                      ),
                      recettes: [(r, facteur)],
                      retour: titre,
                    ),
                  ),
                ),
                BoutonCapsule(
                  picto: Picto.calendrier,
                  libelle: tr.planifier,
                  onTap: () => pousserEcran(
                    context,
                    PlanifierEcran(recette: r, retour: titre),
                  ),
                ),
                BoutonCapsule(
                  picto: Picto.plus,
                  libelle: tr.noterAuJournal,
                  onTap: () => pousserEcran(
                    context,
                    PortionRecetteEcran(
                      recette: r,
                      jour: auj,
                      moment: momentPourHeure(auj),
                      retour: titre,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        if (restes.isNotEmpty)
          Text(
            tr.restesAuGardeManger(
              f.portions(enRestes, tr),
              [
                restes.first.emplacement.libelle(tr),
                if (restes.first.peremption != null)
                  f.echeance(
                    joursEntre(jourDe(auj), restes.first.peremption!),
                    tr,
                  ),
              ].join(' · '),
            ),
            style: RhythmTypo.texte(14, couleur: RhythmCouleurs.menthe),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(
              tr.ingredients,
              droite: CompteurRhythm(
                valeur: portions,
                min: 1,
                max: 48,
                largeurValeur: 104,
                affichage: (p) => f.portions(p.toDouble(), tr),
                onChanged: (p) => setState(() => _portions = p),
              ),
            ),
            if (ingredients.isEmpty)
              Text(tr.aucunIngredient, style: RhythmTypo.detail),
            for (final (i, ing) in ingredients.indexed)
              Builder(
                builder: (context) {
                  final deja = stock.any((a) => memeAliment(ing.nom, a.nom));
                  return LigneCourse(
                    filet: i > 0,
                    nom: ing.nom,
                    detail: [
                      f.quantiteIngredient(ing, tr),
                      if (deja) tr.dejaLa,
                    ].where((s) => s.isNotEmpty).join(' · '),
                    detailCouleur: deja ? RhythmCouleurs.menthe : null,
                    valeur: ing.libre
                        ? null
                        : f.kcalDe(ing.nutriments.kcal, tr),
                  );
                },
              ),
            if (libres.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                tr.sansValeurNutritive(enPhrase(libres, premiere: false)),
                style: RhythmTypo.petit,
              ),
            ],
            if (r.ingredients.isNotEmpty) ...[
              const SizedBox(height: 6),
              const Filet(),
              LigneReglage(
                libelle: tr.iaRemplacer,
                detail: tr.iaRemplacerCourt,
                onTap: () => pousserEcran(
                  context,
                  SubstitutionEcran(recetteId: r.id, retour: titre),
                ),
              ),
            ],
          ],
        ),
        if (r.etapes.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.etapes),
              for (final (i, e) in r.etapes.indexed) ...[
                if (i > 0) const Filet(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${i + 1}',
                          style: RhythmTypo.titre(
                            17,
                            couleur: RhythmCouleurs.peche,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TexteEtape(
                          texte: e,
                          style: RhythmTypo.texte(15, hauteur: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        if (r.note != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.note),
              Text(r.note!, style: RhythmTypo.texte(15, hauteur: 1.4)),
            ],
          ),
        Text(
          [
            r.cuisinee.isEmpty
                ? tr.jamaisCuisinee
                : tr.cuisineeFois(
                    r.cuisinee.length,
                    f.dateCourte(r.derniereFois!),
                  ),
            if (r.seCongele) tr.seCongeleBien,
          ].join(' · '),
          style: RhythmTypo.petit,
        ),
      ],
    );
  }
}
