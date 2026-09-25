// lib/ecrans/alimentation/moment_ecran.dart
//
// UN REPAS d'un jour (le déjeuner du 24 septembre) : ce qu'il apporte en
// tout ; ce qui était PRÉVU et n'est pas encore noté (toucher : le repas
// prévu — cuisiner, noter) ; puis ses aliments — toucher un aliment modifie
// sa quantité (ou le retire). « Ajouter un aliment » ; « Comme hier »
// recopie le même repas de la veille d'un toucher (on mange souvent pareil
// le matin).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_alimentation.dart';
import '../../l10n/traductions.dart';
import '../../modele/alimentation/alimentation.dart';
import '../../modele/alimentation/calculs_alimentation.dart';
import '../../modele/alimentation/calculs_recettes.dart';
import '../../modele/alimentation/etat_alimentation.dart';
import '../../modele/alimentation/etat_recettes.dart';
import '../../modele/etat_sante.dart';
import '../../modele/modeles.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/boutons.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/toast.dart';
import 'entree_rapide_ecran.dart';
import 'noter_ecran.dart';
import 'pieces_alimentation.dart';
import 'portion_ecran.dart';
import 'recettes/repas_prevu_ecran.dart';

class MomentEcran extends ConsumerWidget {
  const MomentEcran({
    super.key,
    required this.jour,
    required this.moment,
    required this.retour,
  });

  final DateTime jour;
  final MomentRepas moment;
  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(alimentationProvider);
    final auj = jourDe(ref.watch(aujourdhuiProvider));
    final j = jourDe(jour);
    final entrees = etat.entreesDu(j, moment);
    final hier = etat.entreesDu(plusJours(j, -1), moment);
    final titre = moment.libelle(tr);
    final recettes = ref.watch(recettesProvider);
    final prevus = [
      for (final p in recettes.prevusLe(j, moment))
        if (!prevuNote(p, etat.journal)) p,
    ];

    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(
          titre: titre,
          surtitre: Text(
            j == auj ? tr.aujourdhui : f.jourComplet(j),
            style: RhythmTypo.surtitre,
          ),
        ),
        if (entrees.isNotEmpty) ApercuNutriments(nutriments: totalDe(entrees)),
        if (prevus.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.prevu, couleur: RhythmCouleurs.peche),
              for (final (i, p) in prevus.indexed)
                Builder(
                  builder: (context) {
                    final r = recettes.recette(p.recetteId);
                    final produit = etat.produit(p.produitId ?? '');
                    final kcal = r != null
                        ? r.parPortion.kcal * p.portions
                        : produit?.parPortion.kcal == null
                        ? null
                        : produit!.parPortion.kcal * p.portions;
                    return LigneAliment(
                      filet: i > 0,
                      nom: r?.nom ?? produit?.nom ?? p.libre ?? '—',
                      detail: tr.prevuToucher,
                      valeur: kcal == null ? null : f.kcalDe(kcal, tr),
                      onTap: () => pousserEcran(
                        context,
                        RepasPrevuEcran(id: p.id, retour: titre),
                      ),
                    );
                  },
                ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.aliments),
            if (entrees.isEmpty) Text(tr.repasVide, style: RhythmTypo.detail),
            for (final (i, e) in entrees.indexed)
              LigneAliment(
                filet: i > 0,
                nom: e.nom,
                detail: f.quantite(e, tr),
                valeur: f.kcalDe(e.nutriments.kcal, tr),
                onTap: () => pousserEcran(
                  context,
                  e.source == SourceEntree.rapide
                      ? EntreeRapideEcran(
                          jour: j,
                          moment: moment,
                          retour: titre,
                          edition: e,
                        )
                      : PortionEcran.edition(entree: e, retour: titre),
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoutonCapsule(
              picto: Picto.plus,
              libelle: tr.ajouterUnAliment,
              plein: true,
              onTap: () => pousserEcran(
                context,
                NoterEcran(jour: j, moment: moment, retour: titre),
              ),
            ),
            if (hier.isNotEmpty) ...[
              const SizedBox(height: 10),
              BoutonCapsule(
                picto: Picto.repete,
                libelle: tr.commeHier(contenuDe(hier)),
                onTap: () {
                  final n = ref
                      .read(alimentationProvider.notifier)
                      .copierMoment(plusJours(j, -1), j, moment);
                  HapticFeedback.lightImpact();
                  montrerToast(context, tr.alimentsAjoutes(n));
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
