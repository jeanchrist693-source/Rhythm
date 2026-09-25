// lib/ecrans/sports/exercice_ecran.dart
//
// La FICHE d'un exercice : son corps en mouvement (les muscles travaillés
// colorés), le niveau, le type (polyarticulaire / isolation), le matériel ;
// les muscles sur la silhouette ; les étapes, les erreurs fréquentes, la
// respiration ; l'échelle des VARIANTES (plus facile ← ici → plus dur) ;
// tes records et ton historique ; « Ajouter à une séance ».

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_sport.dart';
import '../../l10n/traductions.dart';
import '../../modele/sports/calculs_sport.dart';
import '../../modele/sports/catalogue.dart';
import '../../modele/sports/etat_sport.dart';
import '../../modele/sports/exercices.dart';
import '../../modele/sports/muscles.dart';
import '../../modele/sports/sport.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/boutons.dart';
import '../../widgets/corps/silhouette.dart';
import '../../widgets/filets.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/toast.dart';
import 'constructeur_ecran.dart';
import 'pieces_sports.dart';

class ExerciceEcran extends ConsumerWidget {
  const ExerciceEcran({super.key, required this.id, required this.retour});

  final String id;

  /// Le nom de l'écran d'où l'on vient.
  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final e = Catalogue.de(id);
    if (e == null) {
      return PageSecondaire(retour: retour, enfants: const []);
    }
    final journal = ref.watch(sportProvider.select((s) => s.journal));
    final records = recordsDe(e.id, journal);
    final historique = <(DateTime, ExerciceFait)>[
      for (final s in journal.reversed)
        for (final x in s.exercices)
          if (x.exercice == e.id && x.role == RoleLigne.travail) (s.debut, x),
    ].take(6).toList();
    final chaine = Catalogue.chaineDe(e.id);

    return PageSecondaire(
      retour: retour,
      enfants: [
        // Le corps, en grand, qui fait l'exercice.
        LayoutBuilder(
          builder: (context, c) => Center(
            child: FigureDe(
              e,
              taille: c.maxWidth.clamp(0, 380).toDouble(),
              hauteurMax: 330,
              cadree: true,
              animer: true,
            ),
          ),
        ),
        TitreSecondaire(
          titre: e.nom,
          surtitre: Text(
            e.style.libelle(tr).toUpperCase(),
            style: RhythmTypo.texte(
              12,
              poids: 600,
              couleur: RhythmCouleurs.corail,
              espacement: 0.06,
            ),
          ),
        ),
        RangeeFilets(
          cases: [
            _Fait(
              libelle: tr.niveau,
              enfant: Row(
                children: [
                  PointsNiveau(e.niveau),
                  const SizedBox(width: 8),
                  Flexible(child: Text(e.niveau.libelle(tr), style: _valeur)),
                ],
              ),
            ),
            _Fait(
              libelle: tr.materiel,
              enfant: Text(
                e.materiel.isEmpty
                    ? tr.aucunMateriel
                    : e.materiel.map((m) => m.libelle(tr)).join(', '),
                style: _valeur,
              ),
            ),
            _Fait(
              libelle: e.parCote ? tr.deChaqueCote : ' ',
              enfant: Text(
                e.poly ? tr.polyarticulaire : tr.isolation,
                style: _valeur,
              ),
            ),
          ],
        ),
        _Muscles(exercice: e),
        _Liste(titre: tr.etapes, lignes: e.etapes, numerotee: true),
        _Liste(titre: tr.erreursFrequentes, lignes: e.erreurs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TitreSection(tr.respiration),
            Text(e.respiration.texte, style: RhythmTypo.texte(15)),
          ],
        ),
        if (chaine.length > 1)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.variantes),
              for (final (i, v) in chaine.indexed)
                LigneExercice(
                  exercice: v,
                  filet: i > 0,
                  detail: v.id == e.id
                      ? tr.tuEsIci
                      : (chaine.indexWhere((x) => x.id == e.id) > i
                            ? tr.plusFacile
                            : tr.plusDur),
                  droite: v.id == e.id
                      ? const PictoRhythm(
                          Picto.coche,
                          taille: 20,
                          couleur: RhythmCouleurs.corail,
                          epaisseur: 2.4,
                        )
                      : PointsNiveau(v.niveau),
                  onTap: v.id == e.id
                      ? null
                      : () => pousserEcran(
                          context,
                          ExerciceEcran(id: v.id, retour: e.nom),
                        ),
                ),
            ],
          ),
        if (!records.vide)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.tesRecords),
              RangeeFilets(
                cases: [
                  if (records.charge != null)
                    StatSport(
                      libelle: tr.recordCharge,
                      valeur: f.record(TypeRecord.charge, records.charge!, tr),
                      couleur: RhythmCouleurs.corail,
                    ),
                  if (records.reps != null)
                    StatSport(
                      libelle: tr.recordReps,
                      valeur: '${records.reps}',
                    ),
                  if (records.force != null)
                    StatSport(
                      libelle: tr.recordForce,
                      valeur: f.record(TypeRecord.force, records.force!, tr),
                    ),
                  if (records.duree != null)
                    StatSport(
                      libelle: tr.recordDuree,
                      valeur: f.secondes(records.duree!),
                      couleur: RhythmCouleurs.corail,
                    ),
                ],
              ),
            ],
          ),
        if (historique.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.historique),
              for (final (i, (quand, fait)) in historique.indexed) ...[
                if (i > 0) const Filet(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 84,
                        child: Text(
                          f.dateCourte(quand),
                          style: RhythmTypo.detail,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          f.series(fait, tr),
                          style: RhythmTypo.texte(15),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        BoutonPlein(
          libelle: tr.ajouterASeance,
          largeurPleine: true,
          hauteur: 50,
          taillePolice: 15,
          onTap: () => pousserEcran(
            context,
            _ChoixSeanceEcran(exercice: e, retour: e.nom),
          ),
        ),
      ],
    );
  }

  static TextStyle get _valeur => RhythmTypo.texte(14, poids: 500);
}

class _Fait extends StatelessWidget {
  const _Fait({required this.libelle, required this.enfant});

  final String libelle;
  final Widget enfant;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(libelle, style: RhythmTypo.petit, maxLines: 1),
      const SizedBox(height: 6),
      enfant,
    ],
  );
}

/// Les muscles : en mots, et sur la silhouette (face et dos).
class _Muscles extends StatelessWidget {
  const _Muscles({required this.exercice});

  final ExerciceSport exercice;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final e = exercice;
    final couleurs = <Muscle, Color>{
      for (final m in e.secondaires)
        m: RhythmCouleurs.corail.withValues(alpha: 0.45),
      for (final m in e.principaux) m: RhythmCouleurs.corail,
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TitreSection(tr.musclesPrincipaux),
              Text(
                e.principaux.map((m) => m.libelle(tr)).join(', '),
                style: RhythmTypo.texte(
                  15,
                  poids: 600,
                  couleur: RhythmCouleurs.corail,
                ),
              ),
              if (e.secondaires.isNotEmpty) ...[
                const SizedBox(height: 18),
                TitreSection(tr.musclesSecondaires),
                Text(
                  e.secondaires.map((m) => m.libelle(tr)).join(', '),
                  style: RhythmTypo.texte(
                    15,
                    couleur: RhythmCouleurs.corail.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 130,
          child: Row(
            children: [
              for (final c in CoteSilhouette.values) ...[
                if (c == CoteSilhouette.dos) const SizedBox(width: 6),
                Expanded(
                  child: SilhouetteMuscles(cote: c, couleurs: couleurs),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Liste extends StatelessWidget {
  const _Liste({
    required this.titre,
    required this.lignes,
    this.numerotee = false,
  });

  final String titre;
  final List<String> lignes;
  final bool numerotee;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TitreSection(titre),
      for (final (i, l) in lignes.indexed)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 26,
                child: numerotee
                    ? Text(
                        '${i + 1}',
                        style: RhythmTypo.titre(
                          16,
                          couleur: RhythmCouleurs.corail,
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.only(top: 8, left: 2),
                        child: Container(
                          width: 5,
                          height: 5,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: RhythmCouleurs.texte40,
                          ),
                        ),
                      ),
              ),
              Expanded(child: Text(l, style: RhythmTypo.texte(15))),
            ],
          ),
        ),
    ],
  );
}

/// « Ajouter à une séance » : une séance enregistrée, ou une nouvelle.
class _ChoixSeanceEcran extends ConsumerWidget {
  const _ChoixSeanceEcran({required this.exercice, required this.retour});

  final ExerciceSport exercice;
  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(sportProvider);
    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(titre: tr.ajouterASeance),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, p) in etat.programmes.indexed) ...[
              if (i > 0) const Filet(),
              PressionEchelle(
                echelle: 0.98,
                onTap: () {
                  final l = doser(exercice, p.objectif);
                  final travail = [...p.travail, l];
                  final ranges = organiser(travail);
                  final lignes = [
                    for (final x in p.lignes)
                      if (x.role == RoleLigne.echauffement) x,
                    ...ranges,
                    ...retourAuCalme(ranges),
                  ];
                  ref
                      .read(sportProvider.notifier)
                      .enregistrerProgramme(p.copierAvec(lignes: lignes));
                  montrerToast(context, tr.toastAjouteA(p.nom));
                  retirerEcran(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.nom,
                              style: RhythmTypo.texte(16, poids: 600),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.jours.isEmpty
                                  ? tr.aLaDemande
                                  : f.joursPrevus(p.jours, tr),
                              style: RhythmTypo.petit,
                            ),
                          ],
                        ),
                      ),
                      const PictoRhythm(
                        Picto.plus,
                        taille: 20,
                        couleur: RhythmCouleurs.corail,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        BoutonCapsule(
          picto: Picto.plus,
          libelle: tr.nouvelleSeance,
          plein: true,
          onTap: () => pousserEcran(
            context,
            ConstructeurEcran(depart: [exercice.id], retour: retour),
          ),
        ),
      ],
    );
  }
}
