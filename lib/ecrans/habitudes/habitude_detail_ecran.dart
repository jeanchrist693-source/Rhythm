// lib/ecrans/habitudes/habitude_detail_ecran.dart
//
// La fiche d'une habitude (écran secondaire, sans cartes).
//
// À CONSTRUIRE : sa lettre et son nom ; série, record, taux sur 30 jours
// (une rangée à filets) ; le prochain palier et sa jauge ; l'HISTORIQUE —
// treize semaines en pastilles (faite = sa teinte, prévue et manquée =
// piste, non prévue = rien), où toucher un jour passé le coche après coup ;
// puis ses raisons : le pourquoi, le plan si-alors, la version minimale.
//
// En haut à droite : l'ÉPINGLE (en tête de sa liste, une seule à la fois)
// et le crayon.
//
// À LIBÉRER : le COMPTEUR qui vit (jours, puis heures, minutes, secondes) ;
// le prochain palier ; « J'ai une envie » ; record, économies, envies
// surmontées ; le pourquoi, les alternatives, les déclencheurs ; le JOURNAL
// des envies et ce qu'il apprend (le moment, le déclencheur le plus
// fréquent) — maintenir une entrée la retire (une rechute notée par
// erreur : le compteur retrouve sa période) ; « J'ai rechuté », qui mène
// au soutien, pas au reproche.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/traductions.dart';
import '../../modele/calculs_habitudes.dart';
import '../../modele/etat_habitudes.dart';
import '../../modele/etat_sante.dart';
import '../../modele/habitudes.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/boutons.dart';
import '../../widgets/filets.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/toast.dart';
import 'envie_ecran.dart';
import 'habitude_formulaire_ecran.dart';
import 'pieces_habitudes.dart';

class HabitudeDetailEcran extends ConsumerWidget {
  const HabitudeDetailEcran({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final h = ref.watch(habitudesProvider.select((e) => e.parId(id)));
    final epinglee = ref.watch(
      habitudesProvider.select((e) => e.reglages.epinglee == id),
    );
    // Supprimée depuis le formulaire : l'écran se referme.
    if (h == null) return const SizedBox.shrink();
    return PageSecondaire(
      retour: tr.navHabitudes,
      actions: [
        BoutonPicto(
          picto: Picto.epingle,
          libelle: epinglee ? tr.desepingler : tr.epingler,
          couleur: epinglee ? RhythmCouleurs.menthe : RhythmCouleurs.texte,
          onTap: () {
            HapticFeedback.mediumImpact();
            ref.read(habitudesProvider.notifier).epingler(epinglee ? null : id);
            montrerToast(
              context,
              epinglee ? tr.toastDesepinglee : tr.toastEpinglee,
            );
          },
        ),
        BoutonPicto(
          picto: Picto.crayon,
          libelle: tr.modifier,
          onTap: () => pousserEcran(context, HabitudeFormulaireEcran(id: id)),
        ),
      ],
      enfants: h.aLiberer
          ? _liberer(context, ref, h)
          : _construire(context, ref, h),
    );
  }

  Widget _titre(BuildContext context, Habitude h, String sousTitre) =>
      TitreSecondaire(
        gauche: PastilleHabitude(habitude: h, taille: 48),
        surtitre: Text(sousTitre, style: RhythmTypo.surtitre),
        titre: h.nom,
      );

  // ── À construire ──────────────────────────────────────────────────────────

  List<Widget> _construire(BuildContext context, WidgetRef ref, Habitude h) {
    final tr = context.tr;
    final f = context.formats;
    final auj = jourDe(ref.watch(aujourdhuiProvider));
    final n = serie(h, auj);
    final meilleur = record(h, auj);
    final t = taux(h, auj);
    String valeur(int v) =>
        h.quotidienne ? tr.serieCourte(v) : tr.valeurFois(v);
    final palier = prochainPalier(kPaliersSerie, n);
    final sousTitre = [
      if (h.detail.isNotEmpty) h.detail,
      f.joursPrevus(h.jours, tr),
      if (h.rappel != null) tr.rappelA(f.heureMinutes(h.rappel!)),
    ].join(' · ');
    final motivation =
        h.pourquoi.isNotEmpty ||
        h.plan.isNotEmpty ||
        h.versionMinimale.isNotEmpty;
    return [
      _titre(context, h, sousTitre),
      RangeeFilets(
        cases: [
          StatHabitude(
            libelle: tr.serie,
            valeur: valeur(n),
            couleur: n > 0 ? RhythmCouleurs.corail : RhythmCouleurs.texte,
          ),
          StatHabitude(libelle: tr.record, valeur: valeur(meilleur)),
          StatHabitude(
            libelle: tr.sur30Jours,
            valeur: t == null ? '—' : f.pourcent(t),
          ),
        ],
      ),
      JaugePalier(
        titre: tr.prochainPalier(palier.suivant),
        detail: tr.encoreJours(palier.suivant - n),
        progression:
            (n - palier.precedent) / (palier.suivant - palier.precedent),
        couleur: h.teinte.couleur,
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitreSection(tr.historique),
          _Historique(habitude: h, aujourdhui: auj),
          const SizedBox(height: 10),
          Text(tr.historiqueAide, style: RhythmTypo.petit),
        ],
      ),
      if (h.pourquoi.isNotEmpty)
        _Bloc(titre: tr.pourquoi, texte: h.pourquoi, grand: true),
      if (h.plan.isNotEmpty) _Bloc(titre: tr.monPlan, texte: h.plan),
      if (h.versionMinimale.isNotEmpty)
        _Bloc(
          titre: tr.versionMinimale,
          texte: h.versionMinimale,
          aide: tr.versionMinimaleAide,
        ),
      if (!motivation)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tr.ajouterMotivation, style: RhythmTypo.detail),
            const SizedBox(height: 14),
            BoutonContour(
              libelle: tr.modifier,
              onTap: () =>
                  pousserEcran(context, HabitudeFormulaireEcran(id: h.id)),
            ),
          ],
        ),
    ];
  }

  // ── À libérer ─────────────────────────────────────────────────────────────

  List<Widget> _liberer(BuildContext context, WidgetRef ref, Habitude h) {
    final tr = context.tr;
    final f = context.formats;
    final sousTitre = [
      if (h.detail.isNotEmpty) h.detail else tr.liberation,
      if (h.rappel != null) tr.rappelA(f.heureMinutes(h.rappel!)),
    ].join(' · ');
    final frequente = trancheFrequente(h);
    final declencheur = declencheurFrequent(h);
    final envies = h.envies.reversed.take(8).toList();
    return [
      _titre(context, h, sousTitre),
      Horloge(
        periode: const Duration(seconds: 1),
        constructeur: (context, maintenant) =>
            _GrandCompteur(habitude: h, maintenant: maintenant),
      ),
      Horloge(
        periode: const Duration(minutes: 1),
        constructeur: (context, maintenant) {
          final libre = dureeLiberte(h, maintenant);
          final jours = libre.inMinutes / Duration.minutesPerDay;
          final p = prochainPalier(kPaliersLiberte, jours);
          final fin = plusJoursInstant(h.debutLiberte, p.suivant);
          return JaugePalier(
            titre: tr.prochainPalierDuree(f.palier(p.suivant, tr)),
            detail: tr.dansDuree(f.duree(fin.difference(maintenant))),
            progression: (jours - p.precedent) / (p.suivant - p.precedent),
            couleur: RhythmCouleurs.menthe,
          );
        },
      ),
      BoutonPlein(
        libelle: tr.jaiUneEnvie,
        largeurPleine: true,
        hauteur: 52,
        taillePolice: 16,
        onTap: () => pousserEcran(context, EnvieEcran(id: h.id)),
      ),
      Horloge(
        periode: const Duration(minutes: 1),
        constructeur: (context, maintenant) {
          final eco = economies(h, maintenant);
          return RangeeFilets(
            cases: [
              StatHabitude(
                libelle: tr.record,
                valeur: f.duree(recordLiberte(h, maintenant)),
              ),
              if (eco != null)
                StatHabitude(
                  libelle: tr.economise,
                  valeur: f.argent(eco),
                  couleur: RhythmCouleurs.menthe,
                ),
              StatHabitude(
                libelle: tr.enviesSurmontees,
                valeur: '${enviesSurmontees(h)}',
              ),
            ],
          );
        },
      ),
      if (h.pourquoi.isNotEmpty)
        _Bloc(titre: tr.pourquoi, texte: h.pourquoi, grand: true),
      if (h.plan.isNotEmpty) _Bloc(titre: tr.monPlan, texte: h.plan),
      if (h.alternatives.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.mesAlternatives),
            for (var i = 0; i < h.alternatives.length; i++) ...[
              if (i > 0) const Filet(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(h.alternatives[i], style: RhythmTypo.ligne),
              ),
            ],
          ],
        ),
      if (h.declencheurs.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.mesDeclencheurs),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in h.declencheurs)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: RhythmCouleurs.capsule,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      d,
                      style: RhythmTypo.texte(
                        14,
                        couleur: RhythmCouleurs.texte72,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitreSection(
            tr.journalEnvies,
            droite: Text(
              tr.rechutesCompte(h.rechutes.length),
              style: RhythmTypo.petit,
            ),
          ),
          if (frequente != null || declencheur != null) ...[
            Text(
              [
                if (frequente != null) tr.enviesSurtout(frequente.libelle(tr)),
                if (declencheur != null) tr.declencheurPrincipal(declencheur),
              ].join(' '),
              style: RhythmTypo.texte(15, couleur: RhythmCouleurs.texte72),
            ),
            const SizedBox(height: 10),
          ],
          if (envies.isEmpty)
            Text(tr.aucuneEnvie, style: RhythmTypo.detail)
          else ...[
            for (var i = 0; i < envies.length; i++) ...[
              if (i > 0) const Filet(),
              _LigneEnvie(
                key: ObjectKey(envies[i]),
                envie: envies[i],
                onRetirer: () {
                  HapticFeedback.mediumImpact();
                  ref
                      .read(habitudesProvider.notifier)
                      .retirerEnvie(h.id, envies[i]);
                },
              ),
            ],
            const SizedBox(height: 8),
            Text(
              tr.journalAide,
              style: RhythmTypo.texte(12, couleur: RhythmCouleurs.texte40),
            ),
          ],
        ],
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          child: PressionEchelle(
            onTap: () =>
                pousserEcran(context, EnvieEcran(id: h.id, rechute: true)),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                tr.jaiRechute,
                style: RhythmTypo.texte(
                  14,
                  poids: 500,
                  couleur: RhythmCouleurs.texte64,
                ),
              ),
            ),
          ),
        ),
      ),
    ];
  }
}

/// Une section de texte (« Pourquoi », « Mon plan ») : son titre, les mots
/// de l'utilisateur, une aide.
class _Bloc extends StatelessWidget {
  const _Bloc({
    required this.titre,
    required this.texte,
    this.aide,
    this.grand = false,
  });

  final String titre;
  final String texte;
  final String? aide;

  /// Le pourquoi, en grand (Bricolage).
  final bool grand;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TitreSection(titre),
      Text(
        texte,
        style: grand
            ? RhythmTypo.titre(21, poids: 500, espacement: -0.01, hauteur: 1.3)
            : RhythmTypo.texte(17, hauteur: 1.4),
      ),
      if (aide != null) ...[
        const SizedBox(height: 8),
        Text(aide!, style: RhythmTypo.petit),
      ],
    ],
  );
}

/// Treize semaines en pastilles, lundi en haut ; les mois au-dessus.
/// Toucher un jour passé le coche (ou le décoche) après coup.
class _Historique extends ConsumerWidget {
  const _Historique({required this.habitude, required this.aujourdhui});

  final Habitude habitude;
  final DateTime aujourdhui;

  static const int _semaines = 13;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = context.formats;
    final h = habitude;
    final lundiFin = lundiDe(aujourdhui);
    final lundiDebut = plusJours(lundiFin, -7 * (_semaines - 1));
    return LayoutBuilder(
      builder: (context, contraintes) {
        const marge = 18.0, ecart = 4.0;
        final cote = math.min(
          22.0,
          (contraintes.maxWidth - marge - ecart * (_semaines - 1)) / _semaines,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Les mois : au-dessus de la semaine qui contient le 1er.
            SizedBox(
              height: 16,
              child: Stack(
                children: [
                  for (var s = 0; s < _semaines; s++)
                    if (_contientUnPremier(plusJours(lundiDebut, 7 * s)) ||
                        s == 0)
                      Positioned(
                        left: marge + s * (cote + ecart),
                        child: Text(
                          f.moisCourt(
                            _premierDuMois(plusJours(lundiDebut, 7 * s)),
                          ),
                          style: RhythmTypo.texte(
                            11,
                            couleur: RhythmCouleurs.texte64,
                          ),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            for (var j = 0; j < 7; j++) ...[
              if (j > 0) const SizedBox(height: ecart),
              Row(
                children: [
                  SizedBox(
                    width: marge,
                    child: Text(
                      f.initialeJour(plusJours(lundiDebut, j)),
                      style: RhythmTypo.texte(
                        10,
                        couleur: RhythmCouleurs.texte40,
                      ),
                    ),
                  ),
                  for (var s = 0; s < _semaines; s++) ...[
                    if (s > 0) const SizedBox(width: ecart),
                    _Case(
                      habitude: h,
                      jour: plusJours(lundiDebut, 7 * s + j),
                      aujourdhui: aujourdhui,
                      cote: cote,
                      onTap: (jour) {
                        HapticFeedback.selectionClick();
                        ref
                            .read(habitudesProvider.notifier)
                            .basculer(h.id, jour);
                      },
                    ),
                  ],
                ],
              ),
            ],
          ],
        );
      },
    );
  }

  static bool _contientUnPremier(DateTime lundi) {
    for (var i = 0; i < 7; i++) {
      if (plusJours(lundi, i).day == 1) return true;
    }
    return false;
  }

  /// Le 1er du mois dans la semaine de [lundi], sinon ce lundi.
  static DateTime _premierDuMois(DateTime lundi) {
    for (var i = 0; i < 7; i++) {
      final j = plusJours(lundi, i);
      if (j.day == 1) return j;
    }
    return lundi;
  }
}

class _Case extends StatelessWidget {
  const _Case({
    required this.habitude,
    required this.jour,
    required this.aujourdhui,
    required this.cote,
    required this.onTap,
  });

  final Habitude habitude;
  final DateTime jour;
  final DateTime aujourdhui;
  final double cote;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final aVenir = jour.isAfter(aujourdhui);
    final faite = estFaite(habitude, jour);
    final prevue = estPrevue(habitude, jour);
    final Color? fond = aVenir
        ? null
        : faite
        ? habitude.teinte.couleur
        : prevue && jour != aujourdhui
        ? RhythmCouleurs.piste
        : null;
    final pastille = Container(
      width: cote,
      height: cote,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fond,
        shape: BoxShape.circle,
        border: jour == aujourdhui
            ? Border.all(color: RhythmCouleurs.filetActif, width: 1.5)
            : null,
      ),
      // Un jour non prévu, ou avant la création : un point, à peine.
      child: fond == null && !aVenir && jour != aujourdhui
          ? Container(
              width: 3,
              height: 3,
              decoration: const BoxDecoration(
                color: RhythmCouleurs.filet,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
    if (aVenir) return pastille;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onTap(jour),
      child: pastille,
    );
  }
}

/// Les jours libres en grand, puis heures, minutes, secondes.
class _GrandCompteur extends StatelessWidget {
  const _GrandCompteur({required this.habitude, required this.maintenant});

  final Habitude habitude;
  final DateTime maintenant;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final d = dureeLiberte(habitude, maintenant);
    String deux(int v) => v.toString().padLeft(2, '0');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '${d.inDays}',
              style: RhythmTypo.titre(72, poids: 500, espacement: -0.03),
            ),
            const SizedBox(width: 10),
            Text(
              tr.joursLibresUnite(d.inDays),
              style: RhythmTypo.titre(24, poids: 500),
            ),
          ],
        ),
        Text(
          '${d.inHours % 24} h ${deux(d.inMinutes % 60)} min '
          '${deux(d.inSeconds % 60)} s',
          style: RhythmTypo.texte(
            17,
            poids: 500,
            couleur: RhythmCouleurs.menthe,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr.depuisLe(f.dateHeure(habitude.debutLiberte)),
          style: RhythmTypo.detail,
        ),
      ],
    );
  }
}

/// Une envie du journal : quand, l'intensité, le déclencheur, tenue ou non.
/// Maintenue, elle propose de la retirer (« Retirer » / « Garder »).
class _LigneEnvie extends StatefulWidget {
  const _LigneEnvie({super.key, required this.envie, required this.onRetirer});

  final Envie envie;
  final VoidCallback onRetirer;

  @override
  State<_LigneEnvie> createState() => _LigneEnvieState();
}

class _LigneEnvieState extends State<_LigneEnvie> {
  bool _confirmer = false;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: _confirmer
          ? Padding(
              key: const ValueKey(true),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr.retirerEntree,
                      style: RhythmTypo.texte(15, poids: 500),
                    ),
                  ),
                  PressionEchelle(
                    onTap: () => setState(() => _confirmer = false),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Text(
                        tr.garder,
                        style: RhythmTypo.texte(
                          14,
                          poids: 600,
                          couleur: RhythmCouleurs.texte64,
                        ),
                      ),
                    ),
                  ),
                  BoutonPlein(
                    libelle: tr.retirer,
                    hauteur: 36,
                    taillePolice: 13,
                    onTap: widget.onRetirer,
                  ),
                ],
              ),
            )
          : GestureDetector(
              key: const ValueKey(false),
              behavior: HitTestBehavior.opaque,
              onLongPress: () {
                HapticFeedback.selectionClick();
                setState(() => _confirmer = true);
              },
              child: _ligne(context),
            ),
    );
  }

  Widget _ligne(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final e = widget.envie;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: e.tenue ? RhythmCouleurs.menthe : RhythmCouleurs.corail,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.dateHeure(e.quand), style: RhythmTypo.texte(15)),
                const SizedBox(height: 2),
                Text(
                  [
                    tr.intensiteSur10(e.intensite),
                    if (e.declencheur != null) e.declencheur!,
                  ].join(' · '),
                  style: RhythmTypo.petit,
                ),
              ],
            ),
          ),
          Text(
            e.tenue ? tr.tenue : tr.rechute,
            style: RhythmTypo.texte(
              13,
              poids: 600,
              couleur: e.tenue ? RhythmCouleurs.menthe : RhythmCouleurs.corail,
            ),
          ),
        ],
      ),
    );
  }
}
