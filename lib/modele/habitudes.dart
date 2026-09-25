// lib/modele/habitudes.dart
//
// Les habitudes de Rhythm — le module Habitudes de Flow, réinventé. Deux
// GENRES :
// - **construire** : une habitude à prendre (prier, boire de l'eau, lire) —
//   prévue certains jours, cochée jour après jour ; d'où la série, le record,
//   le taux et la carte du mois ;
// - **libérer** : une dépendance dont on se libère — pas de coche mais un
//   COMPTEUR (le temps depuis le début ou la dernière rechute), un journal des
//   envies, les rechutes (qui remettent le compteur à zéro sans effacer le
//   record).
// Les deux portent les outils de motivation : le POURQUOI, le PLAN si-alors
// (« Quand …, je … »), la VERSION MINIMALE des jours difficiles (construire),
// les ALTERNATIVES et DÉCLENCHEURS connus (libérer).
//
// Tout se lit avec tolérance (`depuisJson`) : un champ absent ou abîmé prend
// sa valeur par défaut, jamais une exception.

import 'modeles.dart';
import '../utils/dates.dart';

enum GenreHabitude { construire, liberer }

/// L'ordre des listes : le sien (glisser-déposer), ou par heure de rappel
/// (celles sans rappel à la fin, dans leur ordre).
enum TriHabitudes { manuel, rappel }

/// Une envie notée (libérer) : quand, à quelle intensité, pourquoi, et si
/// elle a été tenue (sinon : une rechute).
class Envie {
  const Envie({
    required this.quand,
    this.intensite = 5,
    this.declencheur,
    this.tenue = true,
    this.note = '',
  });

  final DateTime quand;

  /// 1 (légère) à 10 (irrésistible).
  final int intensite;
  final String? declencheur;
  final bool tenue;
  final String note;

  Map<String, dynamic> versJson() => {
    'quand': quand.toIso8601String(),
    'intensite': intensite,
    'declencheur': ?declencheur,
    'tenue': tenue,
    if (note.isNotEmpty) 'note': note,
  };

  static Envie? depuisJson(Object? j) {
    if (j is! Map) return null;
    final quand = DateTime.tryParse('${j['quand']}');
    if (quand == null) return null;
    return Envie(
      quand: quand,
      intensite: ((j['intensite'] as num?)?.toInt() ?? 5).clamp(1, 10),
      declencheur: j['declencheur'] as String?,
      tenue: j['tenue'] != false,
      note: (j['note'] as String?) ?? '',
    );
  }
}

class Habitude {
  const Habitude({
    required this.id,
    required this.nom,
    required this.creeLe,
    this.genre = GenreHabitude.construire,
    this.teinte = Teinte.menthe,
    this.initiale = '',
    this.detail = '',
    this.jours = const {},
    this.rappel,
    this.pourquoi = '',
    this.plan = '',
    this.versionMinimale = '',
    this.ordre = 0,
    this.faits = const {},
    this.depuis,
    this.rechutes = const [],
    this.coutParJour,
    this.alternatives = const [],
    this.declencheurs = const [],
    this.envies = const [],
  });

  final String id;
  final String nom;
  final GenreHabitude genre;
  final Teinte teinte;

  /// La lettre de la pastille ; vide = la première du nom.
  final String initiale;

  /// La précision sous le nom (« Au réveil · 10 min »).
  final String detail;

  /// Jours prévus (1 = lundi … 7 = dimanche) ; VIDE = tous les jours.
  final Set<int> jours;

  /// Heure du rappel, en minutes depuis minuit ; `null` = pas de rappel.
  final int? rappel;

  final String pourquoi;

  /// Le plan si-alors : « Quand …, je … ».
  final String plan;

  /// Ce qu'on fait quand même les jours difficiles (règle des 2 minutes).
  final String versionMinimale;

  /// Le jour (minuit) depuis lequel l'habitude existe : rien ne compte avant.
  final DateTime creeLe;
  final int ordre;

  /// Construire : les jours faits (clés [cleJour]).
  final Set<int> faits;

  /// Libérer : le début DÉCLARÉ (« libre depuis le 3 mars », parfois avant
  /// l'app) ; `null` = [creeLe]. Ne bouge jamais : une rechute s'ajoute à
  /// [rechutes], et le compteur repart de la dernière.
  final DateTime? depuis;

  /// Libérer : les rechutes, dans l'ordre.
  final List<DateTime> rechutes;

  /// Libérer : ce que coûtait la dépendance par jour (les économies).
  final double? coutParJour;
  final List<String> alternatives;
  final List<String> declencheurs;
  final List<Envie> envies;

  bool get aLiberer => genre == GenreHabitude.liberer;

  bool get quotidienne => jours.isEmpty || jours.length == 7;

  String get lettre {
    if (initiale.trim().isNotEmpty) return initiale.trim();
    final n = nom.trim();
    if (n.isEmpty) return '?';
    return String.fromCharCode(n.runes.first).toUpperCase();
  }

  /// Le début déclaré (libérer).
  DateTime get debutDeclare => depuis ?? creeLe;

  /// Début du compteur (libérer) : la dernière rechute, sinon le début
  /// déclaré.
  DateTime get debutLiberte => rechutes.isEmpty ? debutDeclare : rechutes.last;

  Habitude copierAvec({
    String? nom,
    GenreHabitude? genre,
    Teinte? teinte,
    String? initiale,
    String? detail,
    Set<int>? jours,
    int? Function()? rappel,
    String? pourquoi,
    String? plan,
    String? versionMinimale,
    DateTime? creeLe,
    int? ordre,
    Set<int>? faits,
    DateTime? Function()? depuis,
    List<DateTime>? rechutes,
    double? Function()? coutParJour,
    List<String>? alternatives,
    List<String>? declencheurs,
    List<Envie>? envies,
  }) => Habitude(
    id: id,
    nom: nom ?? this.nom,
    genre: genre ?? this.genre,
    teinte: teinte ?? this.teinte,
    initiale: initiale ?? this.initiale,
    detail: detail ?? this.detail,
    jours: jours ?? this.jours,
    rappel: rappel == null ? this.rappel : rappel(),
    pourquoi: pourquoi ?? this.pourquoi,
    plan: plan ?? this.plan,
    versionMinimale: versionMinimale ?? this.versionMinimale,
    creeLe: creeLe ?? this.creeLe,
    ordre: ordre ?? this.ordre,
    faits: faits ?? this.faits,
    depuis: depuis == null ? this.depuis : depuis(),
    rechutes: rechutes ?? this.rechutes,
    coutParJour: coutParJour == null ? this.coutParJour : coutParJour(),
    alternatives: alternatives ?? this.alternatives,
    declencheurs: declencheurs ?? this.declencheurs,
    envies: envies ?? this.envies,
  );

  Map<String, dynamic> versJson() => {
    'id': id,
    'nom': nom,
    'genre': genre.name,
    'teinte': teinte.name,
    if (initiale.isNotEmpty) 'initiale': initiale,
    if (detail.isNotEmpty) 'detail': detail,
    if (jours.isNotEmpty) 'jours': (jours.toList()..sort()),
    'rappel': ?rappel,
    if (pourquoi.isNotEmpty) 'pourquoi': pourquoi,
    if (plan.isNotEmpty) 'plan': plan,
    if (versionMinimale.isNotEmpty) 'versionMinimale': versionMinimale,
    'creeLe': cleJour(creeLe),
    'ordre': ordre,
    if (faits.isNotEmpty) 'faits': (faits.toList()..sort()),
    if (depuis != null) 'depuis': depuis!.toIso8601String(),
    if (rechutes.isNotEmpty)
      'rechutes': [for (final r in rechutes) r.toIso8601String()],
    'coutParJour': ?coutParJour,
    if (alternatives.isNotEmpty) 'alternatives': alternatives,
    if (declencheurs.isNotEmpty) 'declencheurs': declencheurs,
    if (envies.isNotEmpty) 'envies': [for (final e in envies) e.versJson()],
  };

  static Habitude? depuisJson(Object? j) {
    if (j is! Map) return null;
    final id = j['id'];
    if (id is! String || id.isEmpty) return null;
    List<String> textes(Object? v) => v is List
        ? [
            for (final e in v)
              if (e is String && e.trim().isNotEmpty) e,
          ]
        : const [];
    final cree = (j['creeLe'] as num?)?.toInt();
    return Habitude(
      id: id,
      nom: (j['nom'] as String?) ?? '',
      genre:
          GenreHabitude.values.asNameMap()[j['genre']] ??
          GenreHabitude.construire,
      teinte: Teinte.values.asNameMap()[j['teinte']] ?? Teinte.menthe,
      initiale: (j['initiale'] as String?) ?? '',
      detail: (j['detail'] as String?) ?? '',
      jours: {
        if (j['jours'] is List)
          for (final e in j['jours'] as List)
            if (e is num && e >= 1 && e <= 7) e.toInt(),
      },
      rappel: (j['rappel'] as num?)?.toInt(),
      pourquoi: (j['pourquoi'] as String?) ?? '',
      plan: (j['plan'] as String?) ?? '',
      versionMinimale: (j['versionMinimale'] as String?) ?? '',
      creeLe: cree == null ? jourDe(DateTime.now()) : jourDeCle(cree),
      ordre: (j['ordre'] as num?)?.toInt() ?? 0,
      faits: {
        if (j['faits'] is List)
          for (final e in j['faits'] as List)
            if (e is num) e.toInt(),
      },
      depuis: DateTime.tryParse('${j['depuis']}'),
      rechutes: [
        if (j['rechutes'] is List)
          for (final e in j['rechutes'] as List) ?DateTime.tryParse('$e'),
      ]..sort(),
      coutParJour: (j['coutParJour'] as num?)?.toDouble(),
      alternatives: textes(j['alternatives']),
      declencheurs: textes(j['declencheurs']),
      envies: [
        if (j['envies'] is List)
          for (final e in j['envies'] as List) ?Envie.depuisJson(e),
      ],
    );
  }
}

/// Une personne à appeler quand l'envie est forte.
class Contact {
  const Contact({required this.nom, required this.telephone});

  final String nom;
  final String telephone;

  Map<String, dynamic> versJson() => {'nom': nom, 'telephone': telephone};

  static Contact? depuisJson(Object? j) {
    if (j is! Map) return null;
    final nom = j['nom'], tel = j['telephone'];
    if (nom is! String || tel is! String || tel.trim().isEmpty) return null;
    return Contact(nom: nom, telephone: tel);
  }
}

class ReglagesHabitudes {
  const ReglagesHabitudes({
    this.rappels = true,
    this.bilanSoir,
    this.contacts = const [],
    this.autorisationDemandee = false,
    this.tri = TriHabitudes.manuel,
    this.epinglee,
  });

  /// L'interrupteur général des rappels.
  final bool rappels;

  /// Heure du bilan du soir (minutes depuis minuit) ; `null` = aucun.
  final int? bilanSoir;

  /// Les personnes de confiance de « J'ai une envie ».
  final List<Contact> contacts;

  /// L'autorisation des notifications a déjà été demandée à Android.
  final bool autorisationDemandee;

  /// L'ordre des listes.
  final TriHabitudes tri;

  /// L'habitude épinglée en tête de sa liste (une seule).
  final String? epinglee;

  ReglagesHabitudes copierAvec({
    bool? rappels,
    int? Function()? bilanSoir,
    List<Contact>? contacts,
    bool? autorisationDemandee,
    TriHabitudes? tri,
    String? Function()? epinglee,
  }) => ReglagesHabitudes(
    rappels: rappels ?? this.rappels,
    bilanSoir: bilanSoir == null ? this.bilanSoir : bilanSoir(),
    contacts: contacts ?? this.contacts,
    autorisationDemandee: autorisationDemandee ?? this.autorisationDemandee,
    tri: tri ?? this.tri,
    epinglee: epinglee == null ? this.epinglee : epinglee(),
  );

  Map<String, dynamic> versJson() => {
    'rappels': rappels,
    'bilanSoir': ?bilanSoir,
    if (contacts.isNotEmpty)
      'contacts': [for (final c in contacts) c.versJson()],
    'autorisationDemandee': autorisationDemandee,
    'tri': tri.name,
    'epinglee': ?epinglee,
  };

  static ReglagesHabitudes depuisJson(Object? j) {
    if (j is! Map) return const ReglagesHabitudes();
    return ReglagesHabitudes(
      rappels: j['rappels'] != false,
      bilanSoir: (j['bilanSoir'] as num?)?.toInt(),
      contacts: [
        if (j['contacts'] is List)
          for (final c in j['contacts'] as List) ?Contact.depuisJson(c),
      ],
      autorisationDemandee: j['autorisationDemandee'] == true,
      tri: TriHabitudes.values.asNameMap()[j['tri']] ?? TriHabitudes.manuel,
      epinglee: j['epinglee'] as String?,
    );
  }
}

/// Version du document des habitudes écrit dans le dépôt.
const int kVersionHabitudes = 1;

/// Tout le module : les habitudes (dans l'ordre d'affichage) et ses
/// réglages.
class EtatHabitudes {
  const EtatHabitudes({
    this.habitudes = const [],
    this.reglages = const ReglagesHabitudes(),
  });

  final List<Habitude> habitudes;
  final ReglagesHabitudes reglages;

  List<Habitude> get aConstruire => [
    for (final h in habitudes)
      if (!h.aLiberer) h,
  ];

  List<Habitude> get aLiberer => [
    for (final h in habitudes)
      if (h.aLiberer) h,
  ];

  Habitude? parId(String id) {
    for (final h in habitudes) {
      if (h.id == id) return h;
    }
    return null;
  }

  EtatHabitudes copierAvec({
    List<Habitude>? habitudes,
    ReglagesHabitudes? reglages,
  }) => EtatHabitudes(
    habitudes: habitudes ?? this.habitudes,
    reglages: reglages ?? this.reglages,
  );

  /// Le document du dépôt : la table `habitudes`, et deux réglages.
  Map<String, dynamic> versDocument() => {
    'versionHabitudes': kVersionHabitudes,
    'habitudes': [
      for (var i = 0; i < habitudes.length; i++)
        habitudes[i].copierAvec(ordre: i).versJson(),
    ],
    'reglagesHabitudes': reglages.versJson(),
  };

  static EtatHabitudes depuisDocument(Map<String, dynamic> document) {
    final habitudes = [
      if (document['habitudes'] is List)
        for (final j in document['habitudes'] as List) ?Habitude.depuisJson(j),
    ]..sort((a, b) => a.ordre.compareTo(b.ordre));
    return EtatHabitudes(
      habitudes: habitudes,
      reglages: ReglagesHabitudes.depuisJson(document['reglagesHabitudes']),
    );
  }
}
