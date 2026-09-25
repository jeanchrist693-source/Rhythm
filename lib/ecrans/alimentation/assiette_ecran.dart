// lib/ecrans/alimentation/assiette_ecran.dart
//
// MON ASSIETTE : l'équilibre d'une journée selon le Guide alimentaire
// canadien (`modele/alimentation/assiette.dart`). En grand, l'assiette du
// Guide — la moitié gauche pour les légumes et fruits, en haut à droite les
// aliments protéinés, en bas à droite les grains — chaque part REMPLIE
// jusqu'à ce qu'elle atteint de ce que vise le Guide ; dessous, la phrase
// qui en découle, les trois parts (atteint sur visé), les grains entiers,
// ce qui est à limiter, ce qui n'a pas pu être réparti ; puis ce qu'il y a
// dans chaque part, aliment par aliment (une recette : ses ingrédients),
// l'assiette des 7 derniers jours, et ce que dit le Guide.
//
// [AssietteDessin] sert aussi, en petit, à la ligne « Mon assiette » de
// l'onglet.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_alimentation.dart';
import '../../l10n/traductions.dart';
import '../../modele/alimentation/alimentation.dart';
import '../../modele/alimentation/assiette.dart';
import '../../modele/alimentation/base_aliments.dart';
import '../../modele/alimentation/etat_alimentation.dart';
import '../../modele/alimentation/etat_recettes.dart';
import '../../modele/etat_sante.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/filets.dart';
import '../../widgets/jauges.dart';
import '../../widgets/page_secondaire.dart';
import 'pieces_alimentation.dart';

/// L'assiette de [entrees], si la base est chargée.
Assiette? assietteDuJournal(WidgetRef ref, Iterable<EntreeJournal> entrees) {
  final base = ref.watch(baseAlimentsProvider).value;
  if (base == null) return null;
  return assietteDe(
    entrees,
    base: base,
    produits: ref.watch(alimentationProvider).produits,
    recettes: ref.watch(recettesProvider).recettes,
  );
}

extension LibelleCategorieAssiette on CategorieAssiette {
  String libelle(AppLocalizations tr) => switch (this) {
    CategorieAssiette.legumesFruits => tr.assietteLegumesFruits,
    CategorieAssiette.proteines => tr.assietteProteines,
    CategorieAssiette.grains => tr.assietteGrains,
    CategorieAssiette.aLimiter => tr.assietteALimiter,
    CategorieAssiette.neutre => tr.assietteNeutre,
    CategorieAssiette.nonReparti => tr.assietteNonReparti,
  };

  String detail(AppLocalizations tr) => switch (this) {
    CategorieAssiette.legumesFruits => tr.assietteLegumesFruitsDetail,
    CategorieAssiette.proteines => tr.assietteProteinesDetail,
    CategorieAssiette.grains => tr.assietteGrainsDetail,
    CategorieAssiette.aLimiter => tr.assietteALimiterDetail,
    CategorieAssiette.neutre => tr.assietteNeutreDetail,
    CategorieAssiette.nonReparti => tr.assietteNonRepartiDetail,
  };
}

extension TexteConseilAssiette on ConseilAssiette {
  /// La phrase de l'écran.
  String phrase(AppLocalizations tr) => switch (this) {
    ConseilAssiette.vide => tr.assietteConseilVide,
    ConseilAssiette.plusDeLegumesFruits => tr.assietteConseilLegumesFruits,
    ConseilAssiette.plusDeProteines => tr.assietteConseilProteines,
    ConseilAssiette.plusDeGrains => tr.assietteConseilGrains,
    ConseilAssiette.moinsALimiter => tr.assietteConseilALimiter,
    ConseilAssiette.grainsEntiers => tr.assietteConseilEntiers,
    ConseilAssiette.equilibree => tr.assietteConseilEquilibree,
  };

  /// Le détail de la ligne de l'onglet.
  String court(AppLocalizations tr) => switch (this) {
    ConseilAssiette.vide => tr.assietteCourtVide,
    ConseilAssiette.plusDeLegumesFruits => tr.assietteCourtLegumesFruits,
    ConseilAssiette.plusDeProteines => tr.assietteCourtProteines,
    ConseilAssiette.plusDeGrains => tr.assietteCourtGrains,
    ConseilAssiette.moinsALimiter => tr.assietteCourtALimiter,
    ConseilAssiette.grainsEntiers => tr.assietteCourtEntiers,
    ConseilAssiette.equilibree => tr.assietteCourtEquilibree,
  };
}

class AssietteEcran extends ConsumerWidget {
  const AssietteEcran({super.key, required this.jour, required this.retour});

  final DateTime jour;
  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final j = jourDe(jour);
    final auj = jourDe(ref.watch(aujourdhuiProvider));
    final etat = ref.watch(alimentationProvider);
    final entrees = etat.entreesDu(j);
    final assiette = assietteDuJournal(ref, entrees);
    final semaine = assietteDuJournal(ref, [
      for (final e in etat.journal)
        if (!e.jour.isAfter(j) && joursEntre(e.jour, j) < 7) e,
    ]);

    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(
          titre: tr.monAssiette,
          surtitre: Text(
            j == auj ? tr.aujourdhui : f.jourComplet(j),
            style: RhythmTypo.surtitre,
          ),
        ),
        if (assiette == null)
          const SizedBox(height: 200)
        else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: AssietteDessin(assiette: assiette, taille: 196)),
              const SizedBox(height: 22),
              Text(
                entrees.isEmpty
                    ? tr.assietteRienDeNote
                    : assiette.conseil.phrase(tr),
                style: RhythmTypo.titre(
                  19,
                  poids: 500,
                  espacement: -0.01,
                  hauteur: 1.3,
                ),
              ),
            ],
          ),
          if (assiette.lisible) _Parts(assiette: assiette),
          if (entrees.isNotEmpty) _Reperes(assiette: assiette),
          for (final c in CategorieAssiette.values)
            if (assiette.elements.any((e) => e.categorie == c))
              _Contenu(assiette: assiette, categorie: c),
          if (semaine != null && semaine.lisible) _Semaine(assiette: semaine),
        ],
        const _Guide(),
      ],
    );
  }
}

/// Les trois parts : ce qu'elles font de l'assiette, sur ce que vise le
/// Guide ; la jauge = la part atteinte.
class _Parts extends StatelessWidget {
  const _Parts({required this.assiette});

  final Assiette assiette;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, c) in CategorieAssiette.parts.indexed) ...[
          if (i > 0) const SizedBox(height: 16),
          Row(
            children: [
              AssietteDessin(seule: c, taille: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  c.libelle(tr),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RhythmTypo.texte(14, couleur: RhythmCouleurs.texte72),
                ),
              ),
              Text.rich(
                TextSpan(
                  text: '${f.pourcent(assiette.partDe(c))} ',
                  children: [
                    TextSpan(
                      text: tr.assietteSur(f.pourcent(c.vise!)),
                      style: const TextStyle(color: RhythmCouleurs.texte64),
                    ),
                  ],
                ),
                style: RhythmTypo.texte(14),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Jauge(
            progression: assiette.atteinteDe(c),
            couleur: RhythmCouleurs.peche,
          ),
        ],
      ],
    );
  }
}

/// Les grains entiers, ce qui est à limiter, ce qui n'est pas réparti.
class _Reperes extends StatelessWidget {
  const _Reperes({required this.assiette});

  final Assiette assiette;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final entiers = assiette.partEntiers;
    final lignes = [
      if (entiers != null)
        (tr.assietteGrainsEntiers, tr.assietteDesGrains(f.pourcent(entiers))),
      (
        tr.assietteALimiter,
        tr.assietteDeCeQuiEstMange(f.pourcent(assiette.partALimiter)),
      ),
      if (assiette.nonReparties > 0)
        (
          tr.assietteNonReparti,
          tr.assietteNonRepartisNombre(assiette.nonReparties),
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (libelle, valeur)) in lignes.indexed)
          LigneAliment(filet: i > 0, nom: libelle, valeur: valeur),
      ],
    );
  }
}

/// Ce qu'il y a dans une catégorie, aliment par aliment (les plus lourds
/// d'abord ; un ingrédient dit sa recette).
class _Contenu extends StatelessWidget {
  const _Contenu({required this.assiette, required this.categorie});

  final Assiette assiette;
  final CategorieAssiette categorie;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final elements = [
      for (final e in assiette.elements)
        if (e.categorie == categorie) e,
    ]..sort((a, b) => b.grammes.compareTo(a.grammes));
    final pese =
        categorie != CategorieAssiette.nonReparti &&
        categorie != CategorieAssiette.neutre;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(
          categorie.libelle(tr),
          couleur: categorie.dansLAssiette ? RhythmCouleurs.peche : null,
        ),
        Text(categorie.detail(tr), style: RhythmTypo.detail),
        const SizedBox(height: 4),
        for (final e in elements)
          LigneAliment(
            nom: e.nom,
            detail: [
              ?e.recette,
              if (e.entier) tr.assietteGrainEntier,
            ].join(' · '),
            valeur: pese && e.grammes > 0 ? f.g(e.grammes, tr) : null,
          ),
      ],
    );
  }
}

/// L'assiette des 7 derniers jours, en petit.
class _Semaine extends StatelessWidget {
  const _Semaine({required this.assiette});

  final Assiette assiette;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    String p(CategorieAssiette c) => f.pourcent(assiette.partDe(c));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(tr.assietteSeptJours),
        Row(
          children: [
            AssietteDessin(assiette: assiette, taille: 56),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assiette.conseil.court(tr),
                    style: RhythmTypo.texte(15, poids: 500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr.assietteSeptJoursDetail(
                      p(CategorieAssiette.legumesFruits),
                      p(CategorieAssiette.proteines),
                      p(CategorieAssiette.grains),
                    ),
                    style: RhythmTypo.detail,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ce que dit le Guide, et ce qu'est ce calcul.
class _Guide extends StatelessWidget {
  const _Guide();

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(tr.assietteLeGuide),
        for (final (i, l) in [
          tr.assietteGuide1,
          tr.assietteGuide2,
          tr.assietteGuide3,
          tr.assietteGuide4,
        ].indexed) ...[
          if (i > 0) const Filet(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Text(l, style: RhythmTypo.texte(15)),
          ),
        ],
        const SizedBox(height: 12),
        Text(tr.assietteEstimation, style: RhythmTypo.petit),
      ],
    );
  }
}

// ═══ Le dessin ══════════════════════════════════════════════════════════════

/// L'assiette du Guide, vue de dessus : la moitié gauche (légumes et
/// fruits), le quart en haut à droite (aliments protéinés), le quart en bas
/// à droite (grains). Chaque part se REMPLIT de pêche (en surface) jusqu'à
/// ce qu'elle atteint de ce que vise le Guide ; les parts sont séparées par
/// un trait de noir, comme les capsules du logo. [seule] : la légende d'une
/// part (elle seule, pleine). Grande (≥ 100), l'assiette a son marli.
class AssietteDessin extends StatelessWidget {
  const AssietteDessin({
    super.key,
    this.assiette,
    this.seule,
    required this.taille,
  });

  final Assiette? assiette;
  final CategorieAssiette? seule;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final a = assiette;
    final cibles = [
      for (final c in CategorieAssiette.parts)
        seule != null
            ? (c == seule ? 1.0 : 0.0)
            : a == null || !a.lisible
            ? 0.0
            : a.atteinteDe(c).clamp(0.0, 1.0),
    ];
    final reduit = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: seule != null || reduit
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => CustomPaint(
        size: Size.square(taille),
        painter: _PeintreAssiette([for (final c in cibles) c * t]),
      ),
    );
  }
}

class _PeintreAssiette extends CustomPainter {
  _PeintreAssiette(this.remplis);

  /// Légumes et fruits, protéinés, grains : 0 → 1.
  final List<double> remplis;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final r = size.width / 2;
    final grande = size.width >= 100;
    final trait = Paint()..style = PaintingStyle.stroke;
    final double fond;
    if (grande) {
      // Le bord et le marli.
      canvas.drawCircle(
        centre,
        r - 0.5,
        trait
          ..strokeWidth = 1
          ..color = RhythmCouleurs.filetGrille,
      );
      fond = r * 0.8;
      canvas.drawCircle(
        centre,
        fond + 0.5,
        trait
          ..strokeWidth = 1
          ..color = RhythmCouleurs.filet,
      );
    } else if (size.width >= 30) {
      canvas.drawCircle(
        centre,
        r - 0.75,
        trait
          ..strokeWidth = 1.5
          ..color = RhythmCouleurs.cocheVide,
      );
      fond = r - 4.5;
    } else {
      fond = r;
    }

    // (départ, balayage) de chaque part ; 0 = à droite, sens horaire.
    const secteurs = [
      (math.pi / 2, math.pi), // Légumes et fruits : la moitié gauche.
      (-math.pi / 2, math.pi / 2), // Protéinés : en haut à droite.
      (0.0, math.pi / 2), // Grains : en bas à droite.
    ];
    final vide = Paint()..color = const Color(0x12FFFFFF);
    final plein = Paint()..color = RhythmCouleurs.peche;
    for (final (i, (depart, balayage)) in secteurs.indexed) {
      final rect = Rect.fromCircle(center: centre, radius: fond);
      canvas.drawArc(rect, depart, balayage, true, vide);
      final rempli = remplis[i];
      if (rempli <= 0.001) continue;
      // En SURFACE : le rayon suit la racine.
      final rr = fond * math.sqrt(rempli.clamp(0.0, 1.0));
      canvas.drawArc(
        Rect.fromCircle(center: centre, radius: rr),
        depart,
        balayage,
        true,
        plein,
      );
    }

    // Les séparations : un trait de noir.
    final coupe = Paint()
      ..color = RhythmCouleurs.fond
      ..strokeWidth = math.max(1.5, size.width / 70);
    canvas.drawLine(
      centre.translate(0, -fond - 1),
      centre.translate(0, fond + 1),
      coupe,
    );
    canvas.drawLine(centre, centre.translate(fond + 1, 0), coupe);
  }

  @override
  bool shouldRepaint(_PeintreAssiette ancien) {
    for (var i = 0; i < remplis.length; i++) {
      if (ancien.remplis[i] != remplis[i]) return true;
    }
    return false;
  }
}
