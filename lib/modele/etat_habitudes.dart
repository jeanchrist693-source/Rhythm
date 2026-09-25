// lib/modele/etat_habitudes.dart
//
// L'état des habitudes (Riverpod) et sa PERSISTANCE : chaque changement est
// écrit dans le dépôt SQLite (`depot.dart`, seule la ligne qui change).
//
// Premier lancement : la base est vide, les six habitudes de la maquette y
// sont posées UNE fois (sans historique : rien n'est coché, aucune série
// n'est inventée), puis tout se modifie dans l'app — les supprimer toutes
// ne les fait pas revenir. Sans dépôt (tests, captures), c'est la
// DÉMONSTRATION : les mêmes six, deux mois d'historique (la maquette : 4 sur
// 6 aujourd'hui, 12 jours d'affilée, record 21) et une habitude à libérer.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/dates.dart';
import 'calculs_habitudes.dart';
import 'depot.dart';
import 'etat_sante.dart';
import 'habitudes.dart';
import 'modeles.dart';

/// Le dépôt de l'app (remplacé dans `main`) ; `null` = tout en mémoire,
/// sur la démonstration (tests, captures).
final depotProvider = Provider<Depot?>((ref) => null);

final habitudesProvider = NotifierProvider<HabitudesNotifier, EtatHabitudes>(
  HabitudesNotifier.new,
);

/// Ce qu'un toucher sur une coche vient de faire (retour tactile, fête).
class ResultatBascule {
  const ResultatBascule({
    required this.faite,
    required this.serie,
    this.palier,
    this.journeeComplete = false,
  });

  final bool faite;
  final int serie;

  /// Le palier de série atteint à l'instant (aujourd'hui seulement).
  final int? palier;

  /// La journée vient de devenir complète.
  final bool journeeComplete;
}

class HabitudesNotifier extends Notifier<EtatHabitudes> {
  Depot? _depot;
  int _compteur = 0;

  @override
  EtatHabitudes build() {
    // `read` : un nouveau jour ne relit pas la base (et, en mémoire, ne
    // remet pas la démonstration à zéro).
    final auj = jourDe(ref.read(aujourdhuiProvider));
    _depot = ref.watch(depotProvider);
    final depot = _depot;
    if (depot == null) return GraineHabitudes.demonstration(auj);
    try {
      final document = depot.lire();
      if (document != null && document.containsKey('versionHabitudes')) {
        return EtatHabitudes.depuisDocument(document);
      }
    } catch (_) {
      // Base illisible : l'app démarre plutôt que de ne pas démarrer.
      return GraineHabitudes.premierLancement(auj);
    }
    final graine = GraineHabitudes.premierLancement(auj);
    depot.ecrire(graine.versDocument());
    return graine;
  }

  /// Un identifiant neuf (« hab-1727…-3 »).
  String nouvelId() =>
      'hab-${DateTime.now().microsecondsSinceEpoch}-${++_compteur}';

  void _muter(EtatHabitudes nouvel) {
    state = nouvel;
    try {
      _depot?.ecrire(nouvel.versDocument());
    } catch (_) {}
  }

  void _remplacer(Habitude h) => _muter(
    state.copierAvec(
      habitudes: [for (final x in state.habitudes) x.id == h.id ? h : x],
    ),
  );

  // ── Construire ────────────────────────────────────────────────────────────

  /// Coche ou décoche [id] le [jour] (jamais un jour à venir). Un jour
  /// coché avant la création la recule : l'historique se rattrape.
  ResultatBascule? basculer(String id, DateTime jour) {
    final h = state.parId(id);
    final auj = jourDe(ref.read(aujourdhuiProvider));
    final j = jourDe(jour);
    if (h == null || h.aLiberer || j.isAfter(auj)) return null;
    final avant = journee(state.habitudes, j);
    final cle = cleJour(j);
    final faite = !h.faits.contains(cle);
    final nouvelle = h.copierAvec(
      faits: faite ? {...h.faits, cle} : ({...h.faits}..remove(cle)),
      creeLe: j.isBefore(h.creeLe) ? j : null,
    );
    _remplacer(nouvelle);
    final n = serie(nouvelle, auj);
    final apres = journee(state.habitudes, j);
    return ResultatBascule(
      faite: faite,
      serie: n,
      palier: faite && j == auj ? palierAtteint(kPaliersSerie, n) : null,
      journeeComplete: faite && !avant.complete && apres.complete,
    );
  }

  // ── Ajout, modification, suppression ─────────────────────────────────────

  void ajouter(Habitude h) =>
      _muter(state.copierAvec(habitudes: [...state.habitudes, h]));

  void modifier(Habitude h) => _remplacer(h);

  void supprimer(String id) => _muter(
    state.copierAvec(
      habitudes: [
        for (final h in state.habitudes)
          if (h.id != id) h,
      ],
      reglages: state.reglages.epinglee == id
          ? state.reglages.copierAvec(epinglee: () => null)
          : null,
    ),
  );

  // ── L'ordre ───────────────────────────────────────────────────────────────

  /// Une partie des habitudes (celles d'une liste affichée) prend l'ordre
  /// [ids] ; les autres gardent leur place.
  void reordonner(List<String> ids) => _muter(
    state.copierAvec(habitudes: reordonnerListe(state.habitudes, ids)),
  );

  void trier(TriHabitudes tri) =>
      modifierReglages(state.reglages.copierAvec(tri: tri));

  /// Épingle [id] en tête (une seule à la fois) ; `null` désépingle.
  void epingler(String? id) =>
      modifierReglages(state.reglages.copierAvec(epinglee: () => id));

  // ── Libérer ───────────────────────────────────────────────────────────────

  /// Note une envie. Non tenue, c'est aussi une rechute : le compteur
  /// repart de [Envie.quand].
  void noterEnvie(String id, Envie envie) {
    final h = state.parId(id);
    if (h == null) return;
    _remplacer(
      h.copierAvec(
        envies: [...h.envies, envie],
        rechutes: envie.tenue ? null : ([...h.rechutes, envie.quand]..sort()),
      ),
    );
  }

  /// Retire une envie du journal (notée par erreur) ; si c'était une
  /// rechute, le compteur retrouve la période d'avant.
  void retirerEnvie(String id, Envie envie) {
    final h = state.parId(id);
    if (h == null) return;
    _remplacer(
      h.copierAvec(
        envies: [
          for (final e in h.envies)
            if (!identical(e, envie)) e,
        ],
        rechutes: envie.tenue
            ? null
            : [
                for (final r in h.rechutes)
                  if (r != envie.quand) r,
              ],
      ),
    );
  }

  // ── Réglages ──────────────────────────────────────────────────────────────

  void modifierReglages(ReglagesHabitudes r) =>
      _muter(state.copierAvec(reglages: r));
}

/// Les habitudes de la maquette, et leur démonstration.
abstract final class GraineHabitudes {
  /// Les six de la maquette, plan et version minimale en exemples (tout se
  /// modifie dans l'app).
  static List<Habitude> _six(DateTime creeLe) => [
    Habitude(
      id: 'hab-priere',
      nom: 'Prière du matin',
      detail: 'Au réveil · 10 min',
      teinte: Teinte.lavande,
      initiale: 'P',
      creeLe: creeLe,
      plan: 'Quand je me lève, je prie avant de toucher mon téléphone.',
      versionMinimale: 'Une minute de gratitude',
    ),
    Habitude(
      id: 'hab-eau',
      nom: "Boire 2 L d'eau",
      detail: '8 verres',
      teinte: Teinte.ciel,
      initiale: 'E',
      creeLe: creeLe,
      plan: "Quand je m'assois pour manger, je bois un verre d'eau.",
      versionMinimale: 'Un grand verre maintenant',
    ),
    Habitude(
      id: 'hab-lecture',
      nom: 'Lecture biblique',
      detail: '1 chapitre',
      teinte: Teinte.lavande,
      initiale: 'B',
      creeLe: creeLe,
      plan: 'Quand je finis de déjeuner, je lis un chapitre.',
      versionMinimale: 'Un seul verset',
    ),
    Habitude(
      id: 'hab-entrainement',
      nom: 'Entraînement',
      detail: '45 min',
      teinte: Teinte.corail,
      initiale: 'S',
      creeLe: creeLe,
      plan: 'Quand je rentre, je me change tout de suite pour bouger.',
      versionMinimale: '10 minutes de marche',
    ),
    Habitude(
      id: 'hab-ecrans',
      nom: "Pas d'écran après 23 h",
      detail: 'Sommeil',
      teinte: Teinte.menthe,
      initiale: 'É',
      creeLe: creeLe,
      plan: 'Quand il est 22 h 45, je branche mon téléphone loin du lit.',
      versionMinimale: 'Pas de téléphone au lit',
    ),
    Habitude(
      id: 'hab-etirements',
      nom: 'Étirements',
      detail: 'Le soir · 10 min',
      teinte: Teinte.peche,
      initiale: 'É',
      creeLe: creeLe,
      plan: "Quand je me brosse les dents le soir, je m'étire juste après.",
      versionMinimale: 'Un seul étirement, une minute',
    ),
  ];

  /// Le tout premier lancement : les six, créées aujourd'hui, rien de fait.
  static EtatHabitudes premierLancement(DateTime aujourdhui) =>
      EtatHabitudes(habitudes: _six(jourDe(aujourdhui)));

  /// La démonstration (tests, captures) : deux mois d'historique réglés
  /// pour retomber sur la maquette — 4 sur 6 aujourd'hui, 12 journées
  /// complètes d'affilée, record de 21 —, et une habitude à libérer.
  static EtatHabitudes demonstration(DateTime aujourdhui) {
    final auj = jourDe(aujourdhui);
    final debut = plusJours(auj, -60);
    final six = _six(debut);
    final habitudes = <Habitude>[
      for (var i = 0; i < six.length; i++)
        six[i].copierAvec(
          faits: {
            for (var k = 0; k <= 60; k++)
              if (_faitDemo(i, k)) cleJour(plusJours(auj, -k)),
          },
        ),
    ];
    DateTime a(int jours, int h, int m) {
      final j = plusJours(auj, -jours);
      return DateTime(j.year, j.month, j.day, h, m);
    }

    habitudes.add(
      Habitude(
        id: 'hab-energisantes',
        nom: 'Boissons énergisantes',
        genre: GenreHabitude.liberer,
        detail: 'Un café noir à la place',
        teinte: Teinte.peche,
        creeLe: plusJours(auj, -40),
        depuis: a(40, 8, 0),
        rechutes: [a(17, 21, 30)],
        coutParJour: 4.5,
        rappel: 14 * 60,
        pourquoi: "Dormir mieux et ne plus sentir mon cœur s'emballer.",
        plan: 'Quand la fatigue de 14 h arrive, je sors marcher 5 minutes.',
        alternatives: const [
          "Un grand verre d'eau froide",
          'Marcher 5 minutes dehors',
          'Un café noir',
        ],
        declencheurs: const ['Fatigue', 'Après le dîner', 'Examens'],
        envies: [
          Envie(quand: a(30, 15, 10), intensite: 6, declencheur: 'Fatigue'),
          Envie(
            quand: a(24, 14, 40),
            intensite: 7,
            declencheur: 'Après le dîner',
          ),
          Envie(
            quand: a(17, 21, 30),
            intensite: 9,
            declencheur: 'Examens',
            tenue: false,
          ),
          Envie(
            quand: a(9, 14, 20),
            intensite: 5,
            declencheur: 'Après le dîner',
          ),
          Envie(quand: a(4, 16, 5), intensite: 4, declencheur: 'Fatigue'),
          Envie(
            quand: a(1, 14, 50),
            intensite: 3,
            declencheur: 'Après le dîner',
          ),
        ],
      ),
    );
    return EtatHabitudes(
      habitudes: habitudes,
      reglages: const ReglagesHabitudes(bilanSoir: 21 * 60),
    );
  }

  /// L'habitude [i] faite il y a [k] jours ? Aujourd'hui : les quatre
  /// premières ; 1 à 12 : tout (la série) ; 13 : les quatre premières
  /// (cassure) ; 14 à 34 : tout (le record, 21) ; 35 : rien ; avant : trois
  /// sur quatre environ.
  static bool _faitDemo(int i, int k) => switch (k) {
    0 || 13 => i < 4,
    <= 12 => true,
    <= 34 => true,
    35 => false,
    _ => (k * 7 + i * 3) % 4 != 0,
  };
}
