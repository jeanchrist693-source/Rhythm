// lib/modele/sports/catalogue.dart
//
// La BANQUE d'exercices, toute entière hors ligne : les familles
// (`catalogue/*.dart`) réunies, cherchables par identifiant, et les CHAÎNES
// de variantes — du plus facile au plus dur (« pompes contre le mur →
// inclinées → sur les genoux → pompes → déclinées → archer → claquées »).
// Un exercice appartient au plus à une chaîne : sa fiche montre toute
// l'échelle et sa place dessus.

import 'catalogue/cardio.dart';
import 'catalogue/jambes.dart';
import 'catalogue/mobilite.dart';
import 'catalogue/poussee.dart';
import 'catalogue/tirage.dart';
import 'catalogue/tronc.dart';
import 'catalogue/variantes.dart';
import 'exercices.dart';

abstract final class Catalogue {
  static final List<ExerciceSport> tous = [
    ...exercicesJambes,
    ...exercicesPoussee,
    ...exercicesTirage,
    ...exercicesTronc,
    ...exercicesCardio,
    ...exercicesMobilite,
    ...exercicesVariantes,
  ];

  static final Map<String, ExerciceSport> _parId = {
    for (final e in tous) e.id: e,
  };

  static ExerciceSport? de(String id) => _parId[id];

  /// Les échelles de progression, du plus facile au plus dur.
  static const List<List<String>> chaines = [
    [
      'pompe_murale',
      'pompe_inclinee',
      'pompe_genoux',
      'pompe',
      'pompe_declinee',
      'pompe_archer',
      'pompe_explosive',
    ],
    [
      'squat_chaise',
      'squat',
      'squat_pause',
      'squat_bulgare',
      'squat_une_jambe_chaise',
      'pistol',
    ],
    [
      'suspension',
      'suspension_active',
      'tirage_table',
      'traction_negative',
      'traction_supination',
      'traction',
      'traction_large',
    ],
    ['planche_genoux', 'planche', 'planche_toucher', 'planche_dynamique'],
    ['planche_laterale_genoux', 'planche_laterale', 'planche_laterale_hanche'],
    ['toucher_talons', 'crunch', 'crunch_velo', 'v_up'],
    ['dead_bug', 'hollow', 'hollow_rock'],
    ['fente_arriere', 'fente_avant', 'fente_marchee', 'fente_sautee'],
    ['pont_fessier', 'pont_une_jambe', 'hip_thrust'],
    ['dips_chaise', 'dips_jambes_tendues'],
    ['burpee_sans_saut', 'burpee', 'burpee_pompe', 'burpee_saut_groupe'],
    ['pompe_pike', 'pompe_pike_surelevee'],
    ['mollets_debout', 'mollets_marche', 'mollets_une_jambe'],
    ['souleve_une_jambe_pdc', 'souleve_une_jambe'],
    ['releve_jambes', 'releve_genoux_suspendu', 'releve_jambes_suspendu'],
    ['jacks_sans_saut', 'jumping_jack', 'star_jump', 'saut_groupe'],
    ['marche', 'marche_rapide', 'course'],
    ['corde_a_sauter', 'corde_double'],
    ['chaise_murale', 'chaise_murale_une_jambe'],
    ['squat_goblet', 'squat_bulgare_halteres'],
    ['developpe_sol', 'developpe_couche', 'developpe_couche_barre'],
    ['curl_elastique', 'curl', 'curl_21'],
    ['superman', 'superman_nageur'],
  ];

  /// L'échelle de [id] (vide s'il n'est sur aucune).
  static List<ExerciceSport> chaineDe(String id) {
    for (final c in chaines) {
      if (c.contains(id)) return [for (final x in c) ?de(x)];
    }
    return const [];
  }

  static ExerciceSport? plusFacile(String id) {
    final c = chaineDe(id);
    final i = c.indexWhere((e) => e.id == id);
    return i > 0 ? c[i - 1] : null;
  }

  static ExerciceSport? plusDur(String id) {
    final c = chaineDe(id);
    final i = c.indexWhere((e) => e.id == id);
    return i >= 0 && i < c.length - 1 ? c[i + 1] : null;
  }
}
