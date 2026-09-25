// lib/ecrans/sports/journal_ecran.dart
//
// Le JOURNAL des séances : toutes, de la plus récente à la plus ancienne,
// regroupées par mois ; chacune s'ouvre (exercices série par série, durée,
// distance, calories, ressenti, note) et peut être retirée (en deux temps).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_sport.dart';
import '../../l10n/traductions.dart';
import '../../modele/sports/catalogue.dart';
import '../../modele/sports/etat_sport.dart';
import '../../modele/sports/exercices.dart';
import '../../modele/sports/sport.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/filets.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import 'exercice_ecran.dart';
import 'pieces_sports.dart';
import 'stats_ecran.dart';

/// Le pictogramme d'une séance faite.
Picto pictoSeance(SeanceFaite s) => switch (s.activite) {
  'velo' || 'velo_interieur' => Picto.velo,
  'marche' || 'marche_rapide' || 'marche_cote' || 'randonnee' => Picto.traces,
  String() => Picto.chrono,
  null => switch (s.style) {
    StyleSport.mobilite => Picto.corps,
    StyleSport.hiit => Picto.eclair,
    _ => Picto.haltere,
  },
};

/// « 42 min · 6,8 km · 340 kcal ».
String detailSeance(SeanceFaite s, AppLocalizations tr, Formats f) => [
  f.dureeSeance(s.dureeSec),
  if (s.distanceKm != null) f.km(s.distanceKm!, tr),
  if (s.kcal > 0) tr.kcal(f.entier(s.kcal)),
].join(' · ');

/// Une ligne du journal.
class LigneSeanceFaite extends StatelessWidget {
  const LigneSeanceFaite({
    super.key,
    required this.seance,
    this.filet = true,
    this.onTap,
  });

  final SeanceFaite seance;
  final bool filet;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final s = seance;
    return Column(
      children: [
        if (filet) const Filet(),
        PressionEchelle(
          echelle: 0.98,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                PictoCercle(pictoSeance(s), couleur: couleurStyle(s.style)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.nom,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: RhythmTypo.texte(15, poids: 600),
                      ),
                      const SizedBox(height: 2),
                      Text(detailSeance(s, tr, f), style: RhythmTypo.petit),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text(f.dateCourte(s.debut), style: RhythmTypo.detail),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class JournalEcran extends ConsumerWidget {
  const JournalEcran({super.key, required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final journal = ref.watch(sportProvider.select((s) => s.journal));
    final parMois = <String, List<SeanceFaite>>{};
    for (final s in journal.reversed) {
      final cle = '${f.moisCourt(s.debut)} ${s.debut.year}';
      (parMois[cle] ??= []).add(s);
    }
    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(titre: tr.journalSport),
        if (journal.isEmpty) Text(tr.journalVide, style: RhythmTypo.detail),
        for (final e in parMois.entries)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(e.key),
              for (final (i, s) in e.value.indexed)
                LigneSeanceFaite(
                  seance: s,
                  filet: i > 0,
                  onTap: () => pousserEcran(
                    context,
                    SeanceFaiteEcran(id: s.id, retour: tr.journalSport),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class SeanceFaiteEcran extends ConsumerWidget {
  const SeanceFaiteEcran({super.key, required this.id, required this.retour});

  final String id;
  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final s = ref
        .watch(sportProvider.select((e) => e.journal))
        .where((x) => x.id == id)
        .firstOrNull;
    if (s == null) return PageSecondaire(retour: retour, enfants: const []);
    final aPied = s.activite != null && !s.activite!.startsWith('velo');
    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(
          titre: s.nom,
          surtitre: Text(
            '${f.jourComplet(s.debut)} · ${f.heure(s.debut.hour, s.debut.minute)}',
            style: RhythmTypo.surtitre,
          ),
        ),
        RangeeFilets(
          cases: [
            StatSport(
              libelle: tr.duree,
              valeur: f.dureeSeance(s.dureeSec),
              couleur: RhythmCouleurs.corail,
            ),
            if (s.distanceKm != null)
              StatSport(libelle: tr.distance, valeur: f.km(s.distanceKm!, tr))
            else if (s.volume > 0)
              StatSport(
                libelle: tr.volume,
                valeur: f.kg(s.volume.roundToDouble(), tr),
              )
            else
              StatSport(libelle: tr.seriesFaites, valeur: '${s.nombreSeries}'),
            StatSport(
              libelle: tr.calories,
              valeur: f.entier(s.kcal),
              couleur: RhythmCouleurs.peche,
            ),
          ],
        ),
        if (s.distanceKm != null && (aPied ? s.allure : s.vitesse) != null)
          StatSport(
            libelle: aPied ? tr.allure : tr.vitesse,
            valeur: aPied
                ? tr.allureValeur(f.chrono(s.allure!))
                : tr.vitesseValeur(f.decimal((s.vitesse! * 10).round() / 10)),
          ),
        if (s.exercices.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.lesExercices),
              for (final (i, x) in s.exercices.indexed)
                if (Catalogue.de(x.exercice) case final e?)
                  LigneExercice(
                    exercice: e,
                    filet: i > 0,
                    surtitre: x.role == RoleLigne.travail
                        ? null
                        : x.role.libelle(tr).toUpperCase(),
                    detail: f.series(x, tr),
                    onTap: () => pousserEcran(
                      context,
                      ExerciceEcran(id: e.id, retour: s.nom),
                    ),
                  ),
            ],
          ),
        if (s.ressenti != null)
          StatSport(
            libelle: tr.ressentiGlobal,
            valeur: libelleEffort(tr, s.ressenti!),
          ),
        if (s.note.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.note),
              Text(s.note, style: RhythmTypo.texte(15)),
            ],
          ),
        BoutonSuppression(
          libelle: tr.retirerDuJournal,
          confirmation: tr.toucherPourRetirer,
          onConfirme: () {
            ref.read(sportProvider.notifier).supprimerSeance(s.id);
            retirerEcran(context);
          },
        ),
      ],
    );
  }
}
