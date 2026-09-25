// lib/ecrans/sports/stats_ecran.dart
//
// Les STATISTIQUES sur 30 jours :
// - minutes, séances, calories — et la comparaison avec les 30 jours
//   d'avant ;
// - les minutes par jour (trente barres, aujourd'hui en blanc) ;
// - la RÉGULARITÉ : un calendrier, un point par jour actif ;
// - la répartition par STYLE ;
// - la SILHOUETTE des muscles travaillés (plus c'est coloré, plus il y a eu
//   de séries) et ce qui est NÉGLIGÉ (« Dos : rien depuis 9 jours ») ;
// - les RECORDS récents.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_sport.dart';
import '../../l10n/traductions.dart';
import '../../modele/etat_sante.dart';
import '../../modele/sports/calculs_sport.dart';
import '../../modele/sports/catalogue.dart';
import '../../modele/sports/etat_sport.dart';
import '../../modele/sports/exercices.dart';
import '../../modele/sports/muscles.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/corps/silhouette.dart';
import '../../widgets/filets.dart';
import '../../widgets/jauges.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import 'pieces_sports.dart';

/// La couleur de chaque style dans les répartitions.
Color couleurStyle(StyleSport s) => switch (s) {
  StyleSport.musculation => RhythmCouleurs.corail,
  StyleSport.poidsDuCorps => RhythmCouleurs.peche,
  StyleSport.gainage => RhythmCouleurs.lavande,
  StyleSport.hiit => const Color(0xFFFFB27A),
  StyleSport.mobilite => RhythmCouleurs.menthe,
  StyleSport.cardio => RhythmCouleurs.ciel,
};

class StatsEcran extends ConsumerWidget {
  const StatsEcran({super.key, required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final auj = ref.watch(aujourdhuiProvider);
    final journal = ref.watch(sportProvider.select((s) => s.journal));
    final s = stats30(journal, auj);
    final negliges = musclesNegliges(s, auj);

    String variation(int maintenant, int avant) {
      if (avant == 0) return maintenant == 0 ? '=' : '+';
      final p = (maintenant - avant) / avant;
      final signe = p >= 0 ? '+' : '−';
      return '$signe${f.pourcent(p.abs())}';
    }

    final maxMuscle = s.seriesMuscles.values.fold(0.0, math.max);
    final couleurs = <Muscle, Color>{
      for (final e in s.seriesMuscles.entries)
        if (e.value > 0)
          e.key: RhythmCouleurs.corail.withValues(
            alpha: 0.28 + 0.72 * (e.value / math.max(1, maxMuscle)),
          ),
    };
    final styles = s.parStyle.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalStyles = styles.fold(0, (t, e) => t + e.value);

    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(
          titre: tr.statistiques,
          surtitre: Text(tr.trenteDerniersJours, style: RhythmTypo.surtitre),
        ),
        RangeeFilets(
          cases: [
            StatSport(
              libelle: tr.minutesTitre,
              valeur: f.entier(s.totalMinutes),
              couleur: RhythmCouleurs.corail,
              detail: variation(s.totalMinutes, s.minutesAvant),
            ),
            StatSport(
              libelle: tr.seances,
              valeur: '${s.totalSeances}',
              detail: variation(s.totalSeances, s.seancesAvant),
            ),
            StatSport(
              libelle: tr.calories,
              valeur: f.entier(s.kcal),
              couleur: RhythmCouleurs.peche,
              detail: variation(s.kcal, s.kcalAvant),
            ),
          ],
        ),
        Text(
          tr.parRapportAvant(variation(s.totalMinutes, s.minutesAvant)),
          style: RhythmTypo.petit,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.minutesEtSeancesParJour),
            SizedBox(
              height: 110,
              child: CustomPaint(painter: _Barres(s.minutes)),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(f.dateCourte(s.debut), style: RhythmTypo.petit),
                const Spacer(),
                Text(tr.aujourdhui, style: RhythmTypo.petit),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(
              tr.regularite,
              droite: Text(
                tr.joursActifs(s.joursActifs),
                style: RhythmTypo.texte(13, couleur: RhythmCouleurs.corail),
              ),
            ),
            _Calendrier(debut: s.debut, seances: s.seances),
          ],
        ),
        if (styles.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.parStyle),
              for (final e in styles)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              e.key.libelle(tr),
                              style: RhythmTypo.texte(14),
                            ),
                          ),
                          Text(
                            '${tr.dureeMinutesCourt(e.value)} · '
                            '${f.pourcent(e.value / math.max(1, totalStyles))}',
                            style: RhythmTypo.texte(
                              13,
                              couleur: RhythmCouleurs.texte64,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Jauge(
                        progression: e.value / math.max(1, totalStyles),
                        couleur: couleurStyle(e.key),
                        hauteur: 5,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.musclesTravailles),
            SizedBox(
              height: 300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final c in CoteSilhouette.values) ...[
                    if (c == CoteSilhouette.dos) const SizedBox(width: 24),
                    SilhouetteMuscles(cote: c, couleurs: couleurs),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final a in const [0.3, 0.55, 0.8, 1.0]) ...[
                  Container(
                    width: 18,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: RhythmCouleurs.corail.withValues(alpha: a),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
                const SizedBox(width: 8),
                Text(tr.peuPlusBeaucoup, style: RhythmTypo.petit),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.aNePasOublier, couleur: RhythmCouleurs.peche),
            if (negliges.isEmpty)
              Text(tr.toutEstTravaille, style: RhythmTypo.texte(15))
            else
              for (final (m, jours) in negliges.take(6))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: RhythmCouleurs.peche,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          jours == null || jours >= 30
                              ? tr.rienEn30Jours(m.libelle(tr))
                              : tr.rienDepuis(m.libelle(tr), jours),
                          style: RhythmTypo.texte(15),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.recordsRecents, couleur: RhythmCouleurs.menthe),
            if (s.records.isEmpty)
              Text(tr.aucunRecord, style: RhythmTypo.detail)
            else
              for (final (i, r) in s.records.take(8).indexed) ...[
                if (i > 0) const Filet(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      const PictoRhythm(
                        Picto.trophee,
                        taille: 20,
                        couleur: RhythmCouleurs.menthe,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              Catalogue.de(r.exercice)?.nom ?? '',
                              style: RhythmTypo.texte(15, poids: 500),
                            ),
                            Text(
                              '${r.type.libelle(tr)} · '
                              '${r.quand == null ? '' : f.dateCourte(r.quand!)}',
                              style: RhythmTypo.petit,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        f.record(r.type, r.valeur, tr),
                        style: RhythmTypo.titre(
                          17,
                          couleur: RhythmCouleurs.menthe,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ),
      ],
    );
  }
}

/// Trente barres fines (arrondies), aujourd'hui en blanc.
class _Barres extends CustomPainter {
  _Barres(this.minutes);

  final List<int> minutes;

  @override
  void paint(Canvas canvas, Size size) {
    final n = minutes.length;
    final max = math.max(30, minutes.fold(0, math.max));
    final ecart = 3.0;
    final l = (size.width - ecart * (n - 1)) / n;
    for (var i = 0; i < n; i++) {
      final m = minutes[i];
      final h = m == 0 ? 3.0 : math.max(4.0, m / max * size.height);
      final x = i * (l + ecart);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, size.height - h, l, h),
          Radius.circular(math.min(l / 2, 3)),
        ),
        Paint()
          ..color = m == 0
              ? RhythmCouleurs.piste
              : (i == n - 1 ? RhythmCouleurs.blanc : RhythmCouleurs.corail),
      );
    }
  }

  @override
  bool shouldRepaint(_Barres a) => a.minutes != minutes;
}

/// Le calendrier des 30 jours : une colonne par jour de la semaine, un
/// point plein par jour actif.
class _Calendrier extends StatelessWidget {
  const _Calendrier({required this.debut, required this.seances});

  final DateTime debut;
  final List<int> seances;

  @override
  Widget build(BuildContext context) {
    final f = context.formats;
    final lundi = lundiDe(debut);
    final decalage = joursEntre(lundi, debut);
    final cases = decalage + seances.length;
    final rangees = (cases / 7).ceil();
    return Column(
      children: [
        Row(
          children: [
            for (var j = 0; j < 7; j++)
              Expanded(
                child: Center(
                  child: Text(
                    f.initialeJour(plusJours(lundi, j)),
                    style: RhythmTypo.petit,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (var r = 0; r < rangees; r++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                for (var j = 0; j < 7; j++)
                  Expanded(child: Center(child: _point(r * 7 + j - decalage))),
              ],
            ),
          ),
      ],
    );
  }

  Widget _point(int i) {
    if (i < 0 || i >= seances.length) return const SizedBox(height: 22);
    final actif = seances[i] > 0;
    final aujourdhui = i == seances.length - 1;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: actif ? RhythmCouleurs.corail : RhythmCouleurs.capsule,
        border: aujourdhui
            ? Border.all(color: RhythmCouleurs.blanc, width: 1.5)
            : null,
      ),
    );
  }
}
