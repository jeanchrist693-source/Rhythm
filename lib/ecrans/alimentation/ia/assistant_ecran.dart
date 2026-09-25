// lib/ecrans/alimentation/ia/assistant_ecran.dart
//
// L'ASSISTANT de l'Alimentation (palier 4 : l'IA, en ligne) — ce qu'il
// sait faire, chaque ligne avec ce qui la rend utile MAINTENANT :
// - des idées de recettes (région, moment, genre de plat…) ;
// - avec ce qui presse au garde-manger (anti-gaspillage) ;
// - combler l'écart (« il te reste 560 kcal ») ;
// - planifier ma semaine avec mon livre ;
// - estimer un repas sans recette ;
// - importer une recette collée ;
// - le bilan de la semaine.
// Remplacer un ingrédient se fait depuis une recette ; la conservation d'un
// aliment hors du guide, depuis le garde-manger. En bas : ce qui part, ce
// qui reste sur le téléphone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/etat_sante.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../../sports/pieces_sports.dart';
import 'bilan_ecran.dart';
import 'ecart_ecran.dart';
import 'estimer_ecran.dart';
import 'idees_ecran.dart';
import 'importer_ecran.dart';
import 'pieces_ia.dart';
import 'plan_ia_ecran.dart';

class AssistantEcran extends ConsumerWidget {
  const AssistantEcran({super.key, required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final maintenant = ref.watch(aujourdhuiProvider);
    final auj = jourDe(maintenant);
    final courses = ref.watch(coursesProvider);
    final pressants = [
      for (final a in aConsommerBientot(courses.gardeManger, maintenant))
        if (!a.restes) a.nom,
    ];
    final besoins = ref.watch(besoinsProvider(auj));
    final mange = totalDe(ref.watch(alimentationProvider).entreesDu(auj));
    final reste = besoins.kcal - mange.kcal.round();
    final livre = ref.watch(recettesProvider).recettes.length;
    final bilan = ref.watch(bilanSemaineProvider);
    final titre = tr.iaAssistant;

    Widget ligne(
      Picto picto,
      String libelle,
      String detail,
      Widget Function() ecran,
    ) => LigneReglage(
      gauche: PictoCercle(picto, couleur: RhythmCouleurs.peche),
      libelle: libelle,
      detail: detail,
      onTap: () => pousserEcran(context, ecran()),
    );

    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(
          titre: titre,
          surtitre: Text(tr.iaAssistantSurtitre, style: RhythmTypo.surtitre),
        ),
        Text(
          tr.iaAssistantIntro,
          style: RhythmTypo.titre(19, poids: 500, hauteur: 1.3),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ligne(
              Picto.etincelles,
              tr.iaIdees,
              tr.iaIdeesDetail,
              () => IdeesEcran(retour: titre),
            ),
            const Filet(),
            ligne(
              Picto.frigo,
              tr.iaAvecCeQuiPresse,
              pressants.isEmpty
                  ? tr.iaRienNePresse
                  : enPhrase(pressants.take(3)) +
                        (pressants.length > 3
                            ? ' (+${pressants.length - 3})'
                            : ''),
              () => IdeesEcran(retour: titre, antiGaspillage: true),
            ),
            const Filet(),
            ligne(
              Picto.balance,
              tr.iaEcart,
              reste > 0
                  ? tr.iaIlTeReste(f.kcalDe(reste.toDouble(), tr))
                  : tr.iaObjectifAtteint,
              () => EcartEcran(retour: titre),
            ),
            const Filet(),
            ligne(
              Picto.calendrier,
              tr.iaPlanifier,
              livre < 3 ? tr.iaLivreTropPetitCourt : tr.iaPlanifierDetail,
              () => PlanIaEcran(retour: titre),
            ),
            const Filet(),
            ligne(
              Picto.couverts,
              tr.iaEstimer,
              tr.iaEstimerDetailCourt,
              () => EstimerEcran(
                jour: auj,
                moment: momentPourHeure(maintenant),
                retour: titre,
              ),
            ),
            const Filet(),
            ligne(
              Picto.liste,
              tr.iaImporter,
              tr.iaImporterDetailCourt,
              () => ImporterEcran(retour: titre),
            ),
            const Filet(),
            ligne(
              Picto.graphique,
              tr.iaBilan,
              tr.iaBilanDetail(bilan.joursNotes),
              () => BilanEcran(retour: titre),
            ),
          ],
        ),
        Text(
          tr.iaAilleurs,
          style: RhythmTypo.texte(13, couleur: RhythmCouleurs.texte64),
        ),
        const MentionIa(),
      ],
    );
  }
}
