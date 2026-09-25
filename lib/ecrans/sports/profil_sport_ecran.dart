// lib/ecrans/sports/profil_sport_ecran.dart
//
// MATÉRIEL ET OBJECTIFS : ce qu'on a sous la main (la banque montre d'abord
// ce qu'on peut faire), l'objectif (le dosage), le niveau, le poids du corps
// (les calories), les minutes visées, l'enchaînement des exercices opposés,
// le lien avec l'habitude « Entraînement ». Tout s'applique à l'instant.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_sport.dart';
import '../../l10n/traductions.dart';
import '../../modele/sports/etat_sport.dart';
import '../../modele/sports/exercices.dart';
import '../../modele/sports/sport.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/filets.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';

class ProfilSportEcran extends ConsumerWidget {
  const ProfilSportEcran({super.key, required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(sportProvider);
    final p = etat.profil;
    void modifier(ProfilSportif n) =>
        ref.read(sportProvider.notifier).modifierProfil(n);

    Widget ligne(String libelle, Widget droite, {String? detail}) =>
        LigneReglage(libelle: libelle, detail: detail, droite: droite);

    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(titre: tr.materielEtObjectifs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.monMateriel),
            Text(tr.materielAide, style: RhythmTypo.detail),
            const SizedBox(height: 12),
            PucesMultiples<Materiel>(
              options: [for (final m in Materiel.values) (m, m.libelle(tr))],
              valeurs: p.materiel,
              onChanged: (v) =>
                  modifier(p.copierAvec(materiel: v, materielDeclare: true)),
            ),
            if (p.materiel.isEmpty) ...[
              const SizedBox(height: 8),
              Text(tr.sansMaterielDu, style: RhythmTypo.petit),
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.objectif),
            PucesChoix<Objectif>(
              options: [for (final o in Objectif.values) (o, o.libelle(tr))],
              valeur: p.objectif,
              onChanged: (o) => modifier(p.copierAvec(objectif: o)),
            ),
            const SizedBox(height: 8),
            Text(p.objectif.detail(tr), style: RhythmTypo.detail),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.niveau),
            PucesChoix<Niveau>(
              options: [for (final n in Niveau.values) (n, n.libelle(tr))],
              valeur: p.niveau,
              onChanged: (n) => modifier(p.copierAvec(niveau: n)),
            ),
          ],
        ),
        Column(
          children: [
            ligne(
              tr.poidsDuCorps,
              CompteurRhythm(
                valeur: etat.poidsCorps.round(),
                min: 30,
                max: 250,
                affichage: (v) => f.kg(v.toDouble(), tr),
                largeurValeur: 76,
                onChanged: (v) =>
                    modifier(p.copierAvec(poids: () => v.toDouble())),
              ),
              detail: tr.poidsAide,
            ),
            const Filet(),
            ligne(
              tr.minutesParSemaine,
              CompteurRhythm(
                valeur: p.objectifSemaine,
                min: 30,
                max: 1200,
                pas: 10,
                affichage: (v) => tr.dureeMinutesCourt(v),
                largeurValeur: 76,
                onChanged: (v) => modifier(p.copierAvec(objectifSemaine: v)),
              ),
            ),
            const Filet(),
            ligne(
              tr.minutesParJour,
              CompteurRhythm(
                valeur: p.objectifJour,
                min: 10,
                max: 300,
                pas: 5,
                affichage: (v) => tr.dureeMinutesCourt(v),
                largeurValeur: 76,
                onChanged: (v) => modifier(p.copierAvec(objectifJour: v)),
              ),
            ),
            const Filet(),
            ligne(
              tr.enchainerOpposes,
              Interrupteur(
                valeur: p.enchainements,
                onChanged: (v) => modifier(p.copierAvec(enchainements: v)),
              ),
              detail: tr.enchainerAide,
            ),
            const Filet(),
            ligne(
              tr.lienHabitude,
              Interrupteur(
                valeur: p.lienHabitude,
                onChanged: (v) => modifier(p.copierAvec(lienHabitude: v)),
              ),
              detail: tr.lienHabitudeAide,
            ),
          ],
        ),
      ],
    );
  }
}
