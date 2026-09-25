// lib/ecrans/alimentation/recettes/repas_prevu_ecran.dart
//
// UN REPAS PRÉVU (le souper de vendredi) : ce qu'il apportera, ses
// portions ; ce qu'il faut sortir du congélateur la veille ; les restes qui
// peuvent le servir ; « Cuisiner » (le mode cuisine), « Noter comme
// mangé » (au journal, pris dans les restes s'il y en a), « Voir la
// recette » ; le DÉPLACER (un autre jour, un autre moment) ; le retirer du
// plan (deux temps).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/nutriments.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/modeles.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../entree_rapide_ecran.dart';
import '../pieces_alimentation.dart';
import '../portion_ecran.dart';
import 'cuisine_ecran.dart';
import 'pieces_recettes.dart';
import 'portion_recette_ecran.dart';
import 'recette_ecran.dart';

class RepasPrevuEcran extends ConsumerWidget {
  const RepasPrevuEcran({super.key, required this.id, required this.retour});

  final String id;
  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(recettesProvider);
    final p = etat.prevu(id);
    if (p == null) return PageSecondaire(retour: retour, enfants: const []);
    final notifier = ref.read(recettesProvider.notifier);
    final alimentation = ref.watch(alimentationProvider);
    final courses = ref.watch(coursesProvider);
    final auj = jourDe(ref.watch(aujourdhuiProvider));
    final r = etat.recette(p.recetteId);
    final produit = alimentation.produit(p.produitId ?? '');
    final nom = r?.nom ?? produit?.nom ?? p.libre ?? '—';
    final note = prevuNote(p, alimentation.journal);
    final restes = r == null
        ? 0.0
        : portionsEnRestes(courses.gardeManger, r.id);
    final List<ArticleGardeManger> decongeler = r == null
        ? const []
        : decongelationsDu(
            p.jour,
            etat,
            courses.gardeManger,
          ).where((d) => d.repas.id == p.id).expand((d) => d.articles).toList();
    final Nutriments? apport = r != null
        ? r.parPortion * p.portions
        : produit?.parPortion == null
        ? null
        : produit!.parPortion * p.portions;
    final titre = nom;

    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(
          titre: nom,
          surtitre: Text(
            '${p.moment.libelle(tr)} · '
            '${p.jour == auj ? tr.aujourdhui : f.jourComplet(p.jour)}',
            style: RhythmTypo.surtitre,
          ),
        ),
        if (note)
          Text(
            tr.dejaNoteAuJournal,
            style: RhythmTypo.texte(14, couleur: RhythmCouleurs.menthe),
          ),
        if (apport != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ApercuNutriments(nutriments: apport),
              const SizedBox(height: 6),
              LigneReglage(
                libelle: tr.portionsPrevues,
                droite: CompteurRhythm(
                  valeur: (p.portions * 2).round(),
                  min: 1,
                  max: 48,
                  largeurValeur: 64,
                  affichage: (d) => f.fraction(d / 2),
                  onChanged: (d) =>
                      notifier.modifierPrevu(p.copierAvec(portions: d / 2)),
                ),
              ),
            ],
          ),
        if (decongeler.isNotEmpty || restes > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (decongeler.isNotEmpty)
                Text(
                  tr.aSortirLaVeille(
                    enPhrase([
                      for (final a in decongeler) a.nom,
                    ], premiere: false),
                  ),
                  style: RhythmTypo.texte(14, couleur: RhythmCouleurs.peche),
                ),
              if (decongeler.isNotEmpty && restes > 0)
                const SizedBox(height: 6),
              if (restes > 0)
                Text(
                  tr.restesDisponibles(f.portions(restes, tr)),
                  style: RhythmTypo.texte(14, couleur: RhythmCouleurs.menthe),
                ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (r != null) ...[
              BoutonCapsule(
                picto: Picto.couverts,
                libelle: tr.cuisiner,
                plein: true,
                hauteur: 50,
                onTap: () => pousserEcran(
                  context,
                  CuisineEcran(
                    recette: r,
                    portions: r.portions,
                    moment: p.moment,
                    retour: titre,
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                BoutonCapsule(
                  picto: Picto.coche,
                  libelle: tr.noterCommeMange,
                  plein: r == null,
                  onTap: () => pousserEcran(
                    context,
                    r != null
                        ? PortionRecetteEcran(
                            recette: r,
                            jour: p.jour,
                            moment: p.moment,
                            portions: p.portions,
                            retour: titre,
                          )
                        : produit != null
                        ? PortionEcran.produit(
                            produit: produit,
                            jour: p.jour,
                            moment: p.moment,
                            retour: titre,
                          )
                        : EntreeRapideEcran(
                            jour: p.jour,
                            moment: p.moment,
                            retour: titre,
                            nom: p.libre,
                          ),
                  ),
                ),
                if (r != null)
                  BoutonCapsule(
                    picto: Picto.livre,
                    libelle: tr.voirLaRecette,
                    onTap: () => pousserEcran(
                      context,
                      RecetteEcran(id: r.id, retour: titre),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.deplacer),
            SeptJours(
              aujourdhui: auj,
              choisi: p.jour,
              aDesRepas: (j) => etat.prevusLe(j).isNotEmpty,
              onChoisir: (j) {
                HapticFeedback.selectionClick();
                notifier.modifierPrevu(p.copierAvec(jour: j));
              },
            ),
            const SizedBox(height: 12),
            PucesChoix<MomentRepas>(
              options: [for (final m in MomentRepas.values) (m, m.libelle(tr))],
              valeur: p.moment,
              onChanged: (m) => notifier.modifierPrevu(p.copierAvec(moment: m)),
            ),
          ],
        ),
        BoutonSuppression(
          libelle: tr.retirerDuPlan,
          confirmation: tr.toucherPourRetirer,
          onConfirme: () {
            notifier.retirerPrevu(p.id);
            retirerEcran(context);
          },
        ),
      ],
    );
  }
}
