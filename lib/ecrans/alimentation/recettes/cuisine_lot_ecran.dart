// lib/ecrans/alimentation/recettes/cuisine_lot_ecran.dart
//
// LA CUISINE EN LOT — cuisiner une fois, manger plusieurs fois : les
// recettes prévues cette semaine, combien de repas chacune, ce qu'il faut
// cuisiner (par demi-recette, moins les restes déjà au frigo) — un toucher
// ouvre le mode cuisine pour tout le lot ; les ingrédients que plusieurs
// recettes partagent (à laver, couper, cuire en une fois) ; et comment
// garder les restes (Thermoguide).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/etat_sante.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/page_secondaire.dart';
import '../pieces_alimentation.dart';
import 'cuisine_ecran.dart';

class CuisineLotEcran extends ConsumerWidget {
  const CuisineLotEcran({super.key, required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final auj = jourDe(ref.watch(aujourdhuiProvider));
    final semaine = recettesDeLaSemaine(
      ref.watch(recettesProvider),
      debut: auj,
      journal: ref.watch(alimentationProvider).journal,
      gardeManger: ref.watch(coursesProvider).gardeManger,
    );
    // Les plus mangées d'abord : c'est là qu'un lot fait gagner du temps.
    final tries = [...semaine]
      ..sort((a, b) => b.repas.length.compareTo(a.repas.length));
    final partages = ingredientsPartages([
      for (final s in semaine)
        if (s.lots > 0) s.recette,
    ]);
    final titre = tr.cuisineEnLot;

    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(
          titre: titre,
          surtitre: Text(tr.cuisineEnLotDetail, style: RhythmTypo.surtitre),
        ),
        if (semaine.isEmpty)
          Text(tr.cuisineEnLotVide, style: RhythmTypo.detail)
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.aCuisinerCetteSemaine),
              for (final (i, s) in tries.indexed)
                LigneAliment(
                  filet: i > 0,
                  nom: s.recette.nom,
                  detail: [
                    tr.repasNombreJours(
                      s.repas.length,
                      {
                        for (final p in s.repas) f.jourCourt(p.jour.weekday),
                      }.join(', '),
                    ),
                    if (s.lots > 0)
                      tr.unLotDe(
                        f.fraction(s.lots),
                        f.portions(s.lots * s.recette.portions, tr),
                      )
                    else
                      tr.dejaEnRestes,
                    if (s.recette.seCongele) tr.seCongeleBien,
                  ].join(' · '),
                  onTap: s.lots <= 0
                      ? null
                      : () => pousserEcran(
                          context,
                          CuisineEcran(
                            recette: s.recette,
                            portions: (s.lots * s.recette.portions).round(),
                            retour: titre,
                          ),
                        ),
                ),
            ],
          ),
        if (partages.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.aPreparerEnUneFois),
              for (final (i, (nom, recettes)) in partages.indexed)
                LigneAliment(
                  filet: i > 0,
                  nom: nom,
                  detail: tr.pourOrigines(enPhrase(recettes, premiere: false)),
                ),
            ],
          ),
        Text(
          tr.restesConseil,
          style: RhythmTypo.texte(13, couleur: RhythmCouleurs.texte64),
        ),
      ],
    );
  }
}
