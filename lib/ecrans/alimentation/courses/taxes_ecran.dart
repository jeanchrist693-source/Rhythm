// lib/ecrans/alimentation/courses/taxes_ecran.dart
//
// LES TAXES DU QUÉBEC, expliquées : les taux en vigueur (et depuis quand),
// les trois statuts avec des exemples, ce qui a changé le 15 juillet 2026,
// la consigne, et le principe de Rhythm : l'app propose, tu décides. Les
// taux sont relus en ligne une fois par mois (`kUrlBaremes`) : la date de
// la dernière lecture est dite sous eux.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_courses.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/taxes.dart';
import '../../../modele/etat_sante.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/page_secondaire.dart';

class TaxesEcran extends ConsumerWidget {
  const TaxesEcran({super.key, required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final reglages = ref.watch(coursesProvider).reglages;
    final b = baremeAu(ref.watch(aujourdhuiProvider), reglages.baremes);

    Widget statut(StatutTaxe s, String taux, String exemples) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.libelle(tr),
                style: RhythmTypo.texte(16, poids: 600),
              ),
            ),
            Text(
              taux,
              style: RhythmTypo.texte(14, couleur: RhythmCouleurs.peche),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(exemples, style: RhythmTypo.detail),
      ],
    );

    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(titre: tr.taxesDuQuebec),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tr.tauxEnVigueur(
                f.taux(b.tps),
                f.taux(b.tvq),
                f.taux(b.tps + b.tvq),
              ),
              style: RhythmTypo.titre(19, poids: 500, hauteur: 1.3),
            ),
            const SizedBox(height: 8),
            Text(tr.tauxExplication, style: RhythmTypo.detail),
            const SizedBox(height: 8),
            Text(switch (reglages.baremesVerifies) {
              final v? => tr.tauxVerifiesLe(f.dateCourte(v)),
              null => tr.tauxPasEncoreVerifies,
            }, style: RhythmTypo.petit),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            statut(StatutTaxe.detaxe, '0 %', tr.exemplesDetaxe),
            const SizedBox(height: 14),
            const Filet(),
            const SizedBox(height: 14),
            statut(StatutTaxe.tps, f.taux(b.tps), tr.exemplesTps),
            const SizedBox(height: 14),
            const Filet(),
            const SizedBox(height: 14),
            statut(StatutTaxe.tpsTvq, f.taux(b.tps + b.tvq), tr.exemplesTpsTvq),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.changement15Juillet),
            Text(tr.changement15JuilletTexte, style: RhythmTypo.texte(15)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.consigne),
            Text(tr.consigneTexte, style: RhythmTypo.texte(15)),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.tuDecides),
            Text(tr.tuDecidesTexte, style: RhythmTypo.texte(15)),
          ],
        ),
        Text(
          tr.sourcesTaxes,
          style: RhythmTypo.texte(11, couleur: RhythmCouleurs.texte40),
        ),
      ],
    );
  }
}
