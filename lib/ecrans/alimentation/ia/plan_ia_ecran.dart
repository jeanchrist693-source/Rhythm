// lib/ecrans/alimentation/ia/plan_ia_ecran.dart
//
// PLANIFIER MA SEMAINE (palier 4) : l'IA remplit les cases LIBRES des sept
// jours (les moments choisis — dîner et souper d'emblée ; ni ce qui est
// passé, ni ce qui est déjà prévu ou noté) avec les recettes de MON LIVRE :
// les restes d'abord, de la variété, la cuisine en lot, ce qui presse au
// garde-manger. Chaque repas proposé se coche ou se décoche ; « Ajouter à
// ma semaine » les planifie (portions : le foyer, ou ce que l'IA propose),
// puis ouvre Ma semaine (la liste de la semaine, la cuisine en lot).
// Un livre de moins de trois recettes : des idées d'abord.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ia/ia_alimentation.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/modeles.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/toast.dart';
import '../courses/pieces_courses.dart';
import '../recettes/plan_ecran.dart';
import 'idees_ecran.dart';
import 'pieces_ia.dart';

class PlanIaEcran extends ConsumerStatefulWidget {
  const PlanIaEcran({super.key, required this.retour});

  final String retour;

  @override
  ConsumerState<PlanIaEcran> createState() => _PlanIaEcranState();
}

class _PlanIaEcranState extends ConsumerState<PlanIaEcran>
    with AppelIa<PlanIaEcran> {
  Set<MomentRepas> _moments = {MomentRepas.diner, MomentRepas.souper};
  PlanPropose? _plan;
  final _cleResultats = GlobalKey();

  /// Les repas proposés décochés.
  final Set<RepasPropose> _ecartes = {};

  DemandePlan _demande() {
    final recettes = ref.read(recettesProvider);
    final courses = ref.read(coursesProvider);
    final maintenant = ref.read(aujourdhuiProvider);
    final auj = jourDe(maintenant);
    final besoins = ref.read(besoinsProvider(auj));
    final journal = ref.read(alimentationProvider).entreesDu(auj);
    return DemandePlan(
      recettes: recettes.recettes,
      prevus: [
        for (final p in recettes.plan)
          if (!p.jour.isBefore(auj) && joursEntre(auj, p.jour) < 7) p,
      ],
      maintenant: maintenant,
      moments: _moments,
      personnes: recettes.reglages.personnes,
      restes: {
        for (final r in recettes.recettes)
          if (portionsEnRestes(courses.gardeManger, r.id) > 0)
            r.id: portionsEnRestes(courses.gardeManger, r.id),
      },
      aConsommer: [
        for (final a in aConsommerBientot(courses.gardeManger, maintenant))
          if (!a.restes) a.nom,
      ],
      dejaManges: {for (final e in journal) e.moment},
      kcalVisees: besoins.kcal,
      proteinesVisees: besoins.proteines,
    );
  }

  Future<void> _proposer() async {
    final francais = Localizations.localeOf(context).languageCode == 'fr';
    final d = _demande();
    final r = await appeler(() => planifierSemaine(d, francais: francais));
    if (r == null || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _plan = r;
      _ecartes.clear();
    });
    montrer(_cleResultats);
  }

  void _ajouter() {
    final plan = _plan;
    if (plan == null || transitionEnCours) return;
    final choisis = [
      for (final r in plan.repas)
        if (!_ecartes.contains(r)) r,
    ];
    if (choisis.isEmpty) return;
    final notifier = ref.read(recettesProvider.notifier);
    for (final r in choisis) {
      notifier.planifier(
        jour: r.jour,
        moment: r.moment,
        recetteId: r.recetteId,
        portions: r.portions,
      );
    }
    HapticFeedback.lightImpact();
    montrerToast(context, context.tr.iaRepasAjoutes(choisis.length));
    remplacerEcran(context, PlanEcran(retour: widget.retour));
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(recettesProvider);
    final titre = tr.iaPlanifier;
    final cases = _demande().cases;
    final plan = _plan;
    final choisis = plan == null
        ? 0
        : plan.repas.where((r) => !_ecartes.contains(r)).length;

    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(
          titre: titre,
          surtitre: Text(tr.iaPlanifierSurtitre, style: RhythmTypo.surtitre),
        ),
        if (etat.recettes.length < 3)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr.iaLivreTropPetit, style: RhythmTypo.texte(15)),
              const SizedBox(height: 14),
              BoutonPlein(
                libelle: tr.iaIdees,
                largeurPleine: true,
                hauteur: 52,
                taillePolice: 15,
                onTap: () => pousserEcran(context, IdeesEcran(retour: titre)),
              ),
            ],
          )
        else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.iaMomentsARemplir),
              PucesMultiples<MomentRepas>(
                options: [
                  for (final m in MomentRepas.values) (m, m.libelle(tr)),
                ],
                valeurs: _moments,
                onChanged: (m) => setState(() => _moments = m),
              ),
              const SizedBox(height: 10),
              Text(tr.iaCasesLibres(cases.length), style: RhythmTypo.petit),
            ],
          ),
          if (cases.isNotEmpty)
            BoutonPlein(
              libelle: plan == null ? tr.iaProposerSemaine : tr.iaReproposer,
              largeurPleine: true,
              hauteur: 52,
              taillePolice: 15,
              onTap: _proposer,
            ),
          if (enCours)
            AttenteIa(message: tr.iaAttenteSemaine)
          else if (erreur != null)
            ErreurIaBloc(erreur: erreur, onReessayer: _proposer),
          if (plan != null && !enCours) ...[
            if (plan.resume != null)
              Text(
                plan.resume!,
                key: _cleResultats,
                style: RhythmTypo.titre(19, poids: 500, hauteur: 1.3),
              ),
            if (plan.repas.isEmpty)
              Text(
                tr.iaRienAPlanifier,
                key: plan.resume == null ? _cleResultats : null,
                style: RhythmTypo.detail,
              )
            else
              for (final jour in {for (final r in plan.repas) r.jour})
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TitreSection(
                      jour == jourDe(ref.watch(aujourdhuiProvider))
                          ? tr.aujourdhui
                          : f.jourComplet(jour),
                    ),
                    for (final (i, r)
                        in plan.repas.where((r) => r.jour == jour).indexed)
                      Builder(
                        builder: (context) {
                          final recette = etat.recette(r.recetteId);
                          return LigneCourse(
                            filet: i > 0,
                            coche: !_ecartes.contains(r),
                            nom:
                                '${r.moment.libelle(tr)} · '
                                '${recette?.nom ?? ''}',
                            detail: [
                              f.portions(r.portions, tr),
                              ?r.pourquoi,
                            ].join(' · '),
                            onTap: () => setState(() {
                              HapticFeedback.selectionClick();
                              if (!_ecartes.remove(r)) _ecartes.add(r);
                            }),
                          );
                        },
                      ),
                  ],
                ),
            if (plan.repas.isNotEmpty)
              BoutonPlein(
                libelle: tr.iaAjouterASemaine(choisis),
                largeurPleine: true,
                hauteur: 52,
                taillePolice: 15,
                onTap: _ajouter,
              ),
          ],
        ],
        Text(
          tr.iaPlanDetail,
          style: RhythmTypo.texte(13, couleur: RhythmCouleurs.texte64),
        ),
        const MentionIa(),
      ],
    );
  }
}
