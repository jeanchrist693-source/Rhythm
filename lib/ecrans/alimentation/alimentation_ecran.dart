// lib/ecrans/alimentation/alimentation_ecran.dart
//
// Alimentation (maquette « Alimentation »), sans cartes (`filets.dart`). Le
// HAUT reste celui de la maquette, désormais VIVANT (le journal) : les
// calories restantes dans un anneau (toucher → les objectifs), les trois
// macronutriments, les repas de la journée (toucher un repas → ce qu'il
// contient ; « + » → noter), l'hydratation en verres (toucher un verre le
// remplit, toucher le dernier le vide). Au-dessus, le CONSEIL DU JOUR et
// les sept derniers jours (toucher un jour passé l'affiche : on note après
// coup). Un repas encore vide dit ce qui est PRÉVU (« Prévu : chili sin
// carne »). Puis ce qui est À CONSOMMER BIENTÔT au garde-manger, mes
// recettes, ma semaine, la liste de courses, le garde-manger, les objectifs
// et « Mes produits ». Le gourmand mange en haut à droite.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_alimentation.dart';
import '../../l10n/traductions.dart';
import '../../modele/alimentation/alimentation.dart';
import '../../modele/alimentation/calculs_alimentation.dart';
import '../../modele/alimentation/etat_alimentation.dart';
import '../../modele/alimentation/nutriments.dart';
import '../../modele/etat_sante.dart';
import '../../modele/modeles.dart';
import '../../modele/sports/etat_sport.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/boutons.dart';
import '../../widgets/filets.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/jauges.dart';
import '../../widgets/mascottes.dart';
import '../../widgets/page_rhythm.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/toast.dart';
import '../sports/pieces_sports.dart';
import '../../l10n/libelles_courses.dart';
import '../../modele/alimentation/calculs_courses.dart';
import '../../modele/alimentation/calculs_recettes.dart';
import '../../modele/alimentation/etat_courses.dart';
import '../../modele/alimentation/etat_recettes.dart';
import '../../modele/alimentation/recettes.dart';
import '../../widgets/page_secondaire.dart';
import 'courses/article_garde_manger_ecran.dart';
import 'courses/courses_ecran.dart';
import 'courses/garde_manger_ecran.dart';
import 'courses/pieces_courses.dart';
import 'moment_ecran.dart';
import 'noter_ecran.dart';
import 'objectifs_ecran.dart';
import 'pieces_alimentation.dart';
import 'produits_ecran.dart';
import 'recettes/plan_ecran.dart';
import 'recettes/recettes_ecran.dart';

class AlimentationEcran extends ConsumerStatefulWidget {
  const AlimentationEcran({super.key});

  @override
  ConsumerState<AlimentationEcran> createState() => _AlimentationEcranState();
}

class _AlimentationEcranState extends ConsumerState<AlimentationEcran> {
  /// Le jour affiché ; `null` = aujourd'hui.
  DateTime? _choisi;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final maintenant = ref.watch(aujourdhuiProvider);
    final auj = jourDe(maintenant);
    var jour = _choisi ?? auj;
    if (jour.isAfter(auj) || joursEntre(jour, auj) > 6) jour = auj;
    final etat = ref.watch(alimentationProvider);
    final courses = ref.watch(coursesProvider);
    final recettes = ref.watch(recettesProvider);
    final bientot = aConsommerBientot(courses.gardeManger, maintenant);
    final aDecongeler = decongelationsDu(
      plusJours(auj, 1),
      recettes,
      courses.gardeManger,
    );
    final prevus = [
      for (final p in recettes.plan)
        if (!p.jour.isBefore(auj) && joursEntre(auj, p.jour) < 7) p,
    ];
    final besoins = ref.watch(besoinsProvider(jour));
    final entrees = etat.entreesDu(jour);
    final total = totalDe(entrees);
    final retour = tr.navAlimentation;

    Conseil? conseil;
    if (jour == auj) {
      final sport = ref.watch(sportProvider);
      conseil = conseilDuJour(
        besoins: besoins,
        total: total,
        entrees: entrees.length,
        verres: etat.eauDu(jour),
        seanceFaite: sport.journal.any((s) => jourDe(s.debut) == auj),
        profilComplet: etat.profil.complet,
        objectif: etat.profil.objectif,
        maintenant: maintenant,
        aConsommer: [
          for (final a in aConsommerBientot(
            courses.gardeManger,
            maintenant,
            jours: 1,
          ))
            a.nom,
        ],
        aDecongeler: [
          for (final d in aDecongeler)
            for (final a in d.articles) a.nom,
        ],
      );
    }

    void objectifs() => pousserEcran(context, ObjectifsEcran(retour: retour));

    return PageRhythm(
      blocs: [
        EnTete(
          surtitre: Surtitre(jour == auj ? tr.aujourdhui : f.jourComplet(jour)),
          titre: tr.navAlimentation,
          mascotte: Mascotte.alimentation,
        ),
        if (conseil != null)
          _Conseil(
            texte: texteConseil(tr, conseil, f),
            onTap: conseil.genre == GenreConseil.profil ? objectifs : null,
          ),
        _Jours(
          aujourdhui: auj,
          choisi: jour,
          etat: etat,
          onChoisir: (j) {
            HapticFeedback.selectionClick();
            setState(() => _choisi = j == auj ? null : j);
          },
        ),
        _Calories(total: total, besoins: besoins, onTap: objectifs),
        _Repas(
          jour: jour,
          aujourdhui: maintenant,
          etat: etat,
          recettes: recettes,
        ),
        _Hydratation(jour: jour, bus: etat.eauDu(jour), vises: besoins.verres),
        if (bientot.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.aConsommerBientot, couleur: RhythmCouleurs.peche),
              for (final (i, a) in bientot.take(4).indexed)
                LigneCourse(
                  filet: i > 0,
                  nom: a.nom,
                  detail: a.emplacement.libelle(tr),
                  valeurWidget: Echeance(jours: joursRestants(a, maintenant)),
                  onTap: () => pousserEcran(
                    context,
                    ArticleGardeMangerEcran(id: a.id, retour: retour),
                  ),
                ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Filet(),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.couverts,
                couleur: RhythmCouleurs.peche,
              ),
              libelle: tr.mesRecettes,
              detail: recettes.recettes.isEmpty
                  ? tr.mesRecettesAide
                  : tr.recettesNombre(recettes.recettes.length),
              onTap: () => pousserEcran(context, RecettesEcran(retour: retour)),
            ),
            const Filet(),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.calendrier,
                couleur: RhythmCouleurs.peche,
              ),
              libelle: tr.maSemaine,
              detail: [
                prevus.isEmpty
                    ? tr.rienDePrevuSemaine
                    : tr.repasPrevusNombre(prevus.length),
                if (aDecongeler.isNotEmpty) tr.aDecongelerCeSoirCourt,
              ].join(' · '),
              onTap: () => pousserEcran(context, PlanEcran(retour: retour)),
            ),
            const Filet(),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.panier,
                couleur: RhythmCouleurs.peche,
              ),
              libelle: tr.listeDeCourses,
              detail: courses.liste.isEmpty
                  ? tr.listeVideCourt
                  : tr.articlesNombre(courses.liste.length),
              onTap: () => pousserEcran(context, CoursesEcran(retour: retour)),
            ),
            const Filet(),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.frigo,
                couleur: RhythmCouleurs.peche,
              ),
              libelle: tr.gardeManger,
              detail: courses.gardeManger.isEmpty
                  ? tr.gardeMangerVideCourt
                  : [
                      tr.alimentsNombre(courses.gardeManger.length),
                      if (bientot.isNotEmpty)
                        tr.aConsommerBientotNombre(bientot.length),
                    ].join(' · '),
              onTap: () =>
                  pousserEcran(context, GardeMangerEcran(retour: retour)),
            ),
            const Filet(),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.balance,
                couleur: RhythmCouleurs.peche,
              ),
              libelle: tr.mesObjectifs,
              detail: besoins.estimation
                  ? tr.objectifsEstimes
                  : tr.detailObjectifs(
                      f.kcalDe(besoins.kcal.toDouble(), tr),
                      f.g(besoins.proteines.toDouble(), tr),
                    ),
              onTap: objectifs,
            ),
            const Filet(),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.liste,
                couleur: RhythmCouleurs.texte72,
              ),
              libelle: tr.mesProduits,
              detail: etat.produits.isEmpty
                  ? tr.mesProduitsAide
                  : tr.produitsNombre(etat.produits.length),
              onTap: () => pousserEcran(context, ProduitsEcran(retour: retour)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Le conseil du jour : une phrase, en Bricolage (comme le mot du jour des
/// Habitudes), le point pêche devant.
class _Conseil extends StatelessWidget {
  const _Conseil({required this.texte, this.onTap});

  final String texte;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final phrase = AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      layoutBuilder: (actuel, precedents) => Stack(
        alignment: Alignment.topLeft,
        children: [...precedents, ?actuel],
      ),
      child: Text(
        texte,
        key: ValueKey(texte),
        style: RhythmTypo.titre(
          19,
          poids: 500,
          espacement: -0.01,
          hauteur: 1.3,
        ),
      ),
    );
    if (onTap == null) return phrase;
    return Semantics(
      button: true,
      child: PressionEchelle(echelle: 0.98, onTap: onTap, child: phrase),
    );
  }
}

/// Les sept derniers jours (aujourd'hui à droite) : initiale, date, point
/// (pêche = objectif de calories atteint, pâle = entamé). Le jour affiché
/// est dans une capsule blanche.
class _Jours extends ConsumerWidget {
  const _Jours({
    required this.aujourdhui,
    required this.choisi,
    required this.etat,
    required this.onChoisir,
  });

  final DateTime aujourdhui;
  final DateTime choisi;
  final EtatAlimentation etat;
  final ValueChanged<DateTime> onChoisir;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = context.formats;
    return Row(
      children: [
        for (var i = 6; i >= 0; i--) ...[
          if (i < 6) const SizedBox(width: 4),
          Expanded(
            child: Builder(
              builder: (context) {
                final jour = plusJours(aujourdhui, -i);
                final entrees = etat.entreesDu(jour);
                double? part;
                if (entrees.isNotEmpty) {
                  final kcal = totalDe(entrees).kcal;
                  part = kcal / ref.watch(besoinsProvider(jour)).kcal;
                }
                return JourCapsule(
                  initiale: f.initialeJour(jour),
                  numero: jour.day,
                  aujourdhui: i == 0,
                  choisi: jour == choisi,
                  point: part == null
                      ? null
                      : part >= 0.9
                      ? RhythmCouleurs.peche
                      : const Color(0x73FFD3A8),
                  onTap: () => onChoisir(jour),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Les couleurs des macronutriments, dans l'ordre de la maquette.
Color couleurMacro(Macro macro) => switch (macro) {
  Macro.proteines => RhythmCouleurs.corail,
  Macro.glucides => RhythmCouleurs.peche,
  Macro.lipides => RhythmCouleurs.menthe,
};

class _Calories extends StatelessWidget {
  const _Calories({
    required this.total,
    required this.besoins,
    required this.onTap,
  });

  final Nutriments total;
  final Besoins besoins;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final reste = besoins.kcal - total.kcal.round();
    return Row(
      children: [
        Semantics(
          button: true,
          child: PressionEchelle(
            onTap: onTap,
            echelle: 0.96,
            child: SizedBox.square(
              dimension: 124,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Anneau(
                    taille: 124,
                    rayon: 54,
                    epaisseur: 11,
                    progression: total.kcal / besoins.kcal,
                    couleur: RhythmCouleurs.peche,
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(f.entier(reste.abs()), style: RhythmTypo.titre(28)),
                      Text(
                        reste >= 0 ? tr.kcalRestantes : tr.kcalEnPlus,
                        style: RhythmTypo.texte(
                          11,
                          couleur: RhythmCouleurs.texte64,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              for (final (i, m) in Macro.values.indexed) ...[
                if (i > 0) const SizedBox(height: 12),
                _Macro(
                  apport: ApportMacro(
                    m,
                    valeurDe(total, m).round(),
                    besoins.objectifDe(m),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Macro extends StatelessWidget {
  const _Macro({required this.apport});

  final ApportMacro apport;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                apport.macro.libelle(tr),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RhythmTypo.texte(13, couleur: RhythmCouleurs.texte72),
              ),
            ),
            Text.rich(
              TextSpan(
                text: '${tr.grammes(apport.grammes)} ',
                children: [
                  TextSpan(
                    text: tr.surGrammes(apport.objectif),
                    style: const TextStyle(color: RhythmCouleurs.texte64),
                  ),
                ],
              ),
              style: RhythmTypo.texte(13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Jauge(
          progression: apport.objectif <= 0 ? 0 : apport.progression,
          couleur: couleurMacro(apport.macro),
        ),
      ],
    );
  }
}

class _Repas extends StatelessWidget {
  const _Repas({
    required this.jour,
    required this.aujourdhui,
    required this.etat,
    required this.recettes,
  });

  final DateTime jour;
  final DateTime aujourdhui;
  final EtatAlimentation etat;
  final EtatRecettes recettes;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final auj = jourDe(aujourdhui);
    final maintenant = momentPourHeure(aujourdhui);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(tr.repas, style: RhythmTypo.titreCarte),
            BoutonRond(
              couleur: RhythmCouleurs.peche,
              libelle: tr.ajouterRepas,
              onTap: () => pousserEcran(
                context,
                NoterEcran(
                  jour: jour,
                  moment: jour == auj ? maintenant : MomentRepas.dejeuner,
                  retour: tr.navAlimentation,
                ),
              ),
              child: Text(
                '+',
                style: RhythmTypo.texte(
                  24,
                  couleur: RhythmCouleurs.noir,
                  hauteur: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final m in MomentRepas.values)
          Builder(
            builder: (context) {
              final entrees = etat.entreesDu(jour, m);
              final kcal = entrees.isEmpty ? null : totalDe(entrees).kcal;
              final aVenir =
                  jour == auj && m.index >= maintenant.index && entrees.isEmpty;
              // Un repas vide dit ce qui est prévu (s'il l'est).
              final prevus = [
                for (final p in recettes.prevusLe(jour, m))
                  recettes.recette(p.recetteId)?.nom ??
                      etat.produit(p.produitId ?? '')?.nom ??
                      p.libre ??
                      '',
              ].where((n) => n.isNotEmpty);
              return _LigneRepas(
                moment: m,
                contenu: entrees.isNotEmpty
                    ? contenuDe(entrees)
                    : prevus.isNotEmpty
                    ? tr.prevuNoms(enPhrase(prevus, premiere: false))
                    : (aVenir ? tr.aPlanifier : tr.rienDeNote),
                kcal: kcal == null ? null : f.kcalDe(kcal, tr),
                onTap: () => pousserEcran(
                  context,
                  MomentEcran(
                    jour: jour,
                    moment: m,
                    retour: tr.navAlimentation,
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _LigneRepas extends StatelessWidget {
  const _LigneRepas({
    required this.moment,
    required this.contenu,
    required this.kcal,
    required this.onTap,
  });

  final MomentRepas moment;
  final String contenu;
  final String? kcal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Column(
      children: [
        const Filet(),
        PressionEchelle(
          echelle: 0.98,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kcal != null
                        ? RhythmCouleurs.peche
                        : RhythmCouleurs.pointVide,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        moment.libelle(tr),
                        style: RhythmTypo.texte(15, poids: 500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        contenu,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: RhythmTypo.detail,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  kcal ?? '—',
                  style: RhythmTypo.texte(
                    14,
                    couleur: kcal == null
                        ? RhythmCouleurs.texte64
                        : RhythmCouleurs.texte,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Hydratation extends ConsumerWidget {
  const _Hydratation({
    required this.jour,
    required this.bus,
    required this.vises,
  });

  final DateTime jour;
  final int bus;
  final int vises;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    // Un verre de plus se montre une fois l'objectif atteint (on peut boire
    // davantage) ; au plus 16.
    final total = (bus >= vises ? bus + 1 : vises).clamp(1, 16);
    void fixer(int n) {
      final nom = ref.read(alimentationProvider.notifier).fixerEau(jour, n);
      if (n > bus) {
        if (n == vises) {
          HapticFeedback.heavyImpact();
          montrerToast(
            context,
            nom == null ? tr.eauAtteinte : tr.eauAtteinteHabitude(nom),
          );
        } else {
          HapticFeedback.lightImpact();
        }
      } else {
        HapticFeedback.selectionClick();
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const PictoRhythm(
              Picto.goutte,
              taille: 18,
              couleur: RhythmCouleurs.ciel,
              epaisseur: 2,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                tr.hydratation,
                style: RhythmTypo.texte(15, poids: 600),
              ),
            ),
            Text(
              tr.litresSur(
                f.decimal(bus * kLitresParVerre),
                f.decimal(vises * kLitresParVerre),
              ),
              style: RhythmTypo.detail,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          key: const ValueKey('verres'),
          label: tr.verresSur(bus, vises),
          child: Row(
            children: [
              for (var i = 0; i < total; i++) ...[
                if (i > 0) const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    // Toucher le dernier verre plein le vide ; un autre
                    // remplit jusqu'à lui.
                    onTap: () => fixer(i + 1 == bus ? i : i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        height: 28,
                        decoration: BoxDecoration(
                          color: i < bus
                              ? RhythmCouleurs.ciel
                              : RhythmCouleurs.piste,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
