// lib/ia/ia_alimentation.dart
//
// L'IA de l'ALIMENTATION (palier 4) : les demandes à Groq (`service_ia.dart`)
// et la lecture de ses réponses. Chaque fonction a trois temps — l'INVITE
// (pure : `invites…`, testée), l'appel, la LECTURE (pure : `lire…`,
// tolérante, testée).
//
// Les règles, pour toutes :
// - rien de CHIFFRÉ ne vient de l'IA : elle nomme des aliments, des
//   quantités et des mots-clés ; les calories et les macros sont calculées
//   sur le téléphone par la base du FCÉN (`correspondance.dart`) — ses
//   « kcal » estimées ne servent qu'à départager les aliments de la base ;
// - rien de personnel ne part : ni le nom, ni le poids, l'âge ou le sexe,
//   ni les habitudes ou les libérations — seulement des aliments, des
//   recettes, des objectifs du jour (kcal, protéines) et l'objectif
//   (perdre, maintenir, prendre) ;
// - jamais de taxe (le statut reste choisi par l'utilisateur), pas d'avis
//   médical (renvoi vers une diététiste-nutritionniste) ;
// - les textes nettoyés (`texte_ia.dart`) : typographie française, glyphes
//   des polices.

import '../modele/alimentation/alimentation.dart';
import '../modele/alimentation/base_aliments.dart' show motsDe;
import '../modele/alimentation/bilan_semaine.dart';
import '../modele/alimentation/conservation.dart';
import '../modele/alimentation/correspondance.dart';
import '../modele/alimentation/courses.dart';
import '../modele/alimentation/nutriments.dart';
import '../modele/alimentation/recettes.dart';
import '../modele/modeles.dart';
import '../utils/dates.dart';
import 'service_ia.dart';
import 'texte_ia.dart';

// ═══ Le socle ═══════════════════════════════════════════════════════════════

String _persona(bool francais) => '''
Tu es l'assistant cuisine et nutrition de Rhythm, une application santé utilisée au Québec. Tu aides à cuisiner, à planifier les repas, à faire l'épicerie sans gaspiller et à bien manger au quotidien.

Règles :
1. Réponds UNIQUEMENT par un objet JSON valide, selon le schéma demandé, sans texte autour.
2. N'écris jamais de calories ni de valeurs nutritives dans tes textes : l'application les calcule elle-même avec le Fichier canadien sur les éléments nutritifs (FCÉN). Tu donnes seulement une estimation dans les champs « kcal » prévus, qui servent à vérifier.
3. Pas d'avis médical : ni diagnostic ni régime thérapeutique. Si une maladie, une grossesse, un médicament, une allergie grave ou un trouble alimentaire est évoqué, invite avec douceur à consulter une diététiste-nutritionniste ou un médecin.
4. Ton chaleureux et simple, jamais culpabilisant ; tutoiement ; phrases courtes ; ni emoji ni Markdown.
5. Cuisine réaliste : des ingrédients faciles à trouver dans une épicerie du Québec, des unités métriques (g, ml), les températures en °C.
6. ${francais ? 'Rédige les textes en français (d\'ici), avec des apostrophes droites.' : 'Write every text for the user in English (Canadian). The "fcen" keywords stay in French.'}''';

/// Comment l'IA décrit un aliment (recettes, estimations, substitutions).
const String _schemaIngredient = '''
Chaque ingrédient : {"nom": "Oignon", "quantite": 1, "unite": "unite", "taille": "gros", "grammes": 150, "kcal": 60, "fcen": "oignon cru"}
- "unite" : "g", "ml" ou "unite". Convertis cuillères et tasses en ml (1 c. à soupe = 15 ml, 1 c. à thé = 5 ml, 1 tasse = 250 ml) ; une boîte de conserve en ml (ex. 540).
- "taille" : seulement pour "unite" — "petit", "moyen", "gros", "gousse", "tranche", "feuille"…
- "grammes" : le poids estimé de la quantité (toujours).
- "kcal" : tes calories estimées pour cette quantité (elles servent seulement à vérifier).
- "fcen" : 2 à 5 mots-clés EN FRANÇAIS pour trouver l'aliment dans le FCÉN — l'aliment générique, sans marque, puis son état tel qu'employé : « riz blanc cru », « poulet poitrine crue », « tomates conserve », « bouillon poulet prêt à servir », « pâtes alimentaires sèches », « haricots noirs conserve ».
- Sel, poivre, épices séchées, fines herbes en petite quantité, eau : {"nom": "Sel et poivre", "libre": true}.''';

const String _schemaRecette = '''
Chaque recette : {"nom": "…", "description": "une phrase qui donne envie", "region": "la cuisine d'origine (ex. Québécoise, Sénégalaise, Italienne)", "moments": ["dejeuner" | "diner" | "collation" | "souper"], "portions": 4, "preparation": 15, "cuisson": 30, "congele": true, "ingredients": [ … ], "etapes": ["…", "…"], "note": "un conseil facultatif (conservation, variante)"}
- "diner" = le repas du midi, "souper" = celui du soir (usage québécois).
- "preparation" et "cuisson" en minutes ; "congele" : vrai si les restes se congèlent bien.
- "etapes" : une action par étape, sans numéro ; écris les durées en chiffres (« 10 minutes », « 1 h 30 ») — l'app en fait des minuteurs.''';

/// Les jours de la semaine (lundi = 1).
const _joursFr = [
  'lundi',
  'mardi',
  'mercredi',
  'jeudi',
  'vendredi',
  'samedi',
  'dimanche',
];

String _nomMoment(MomentRepas m) => m.name;

String _nombre(double x) {
  final r = (x * 10).round() / 10;
  return r == r.roundToDouble() ? '${r.round()}' : '$r'.replaceAll('.', ',');
}

List<MessageIa> _messages(bool francais, String demande) => [
  MessageIa('system', _persona(francais)),
  MessageIa('user', demande),
];

List<Map> _listeDe(Map<String, dynamic> j, String cle) => [
  if (j[cle] is List)
    for (final x in j[cle] as List)
      if (x is Map) x,
];

// ═══ Les idées de recettes (et l'anti-gaspillage) ═══════════════════════════

/// Le genre de plat demandé (facultatif).
enum GenrePlat { plat, soupe, salade, sandwich, bol, dessert, boisson }

String _genre(GenrePlat g) => switch (g) {
  GenrePlat.plat => 'un plat principal',
  GenrePlat.soupe => 'une soupe ou un potage',
  GenrePlat.salade => 'une salade-repas',
  GenrePlat.sandwich => 'un sandwich, un wrap ou un burger',
  GenrePlat.bol => 'un bol (grain, protéine, légumes)',
  GenrePlat.dessert => 'un dessert',
  GenrePlat.boisson => 'un smoothie ou une boisson',
};

class DemandeIdees {
  const DemandeIdees({
    this.region,
    this.moment,
    this.genre,
    this.portions = 4,
    this.rapide = false,
    this.proteinees = false,
    this.vegetarien = false,
    this.precisions = '',
    this.aUtiliser = const [],
    this.gardeManger = const [],
    this.aEviter = const [],
  });

  /// Une grande région (« Afrique de l'Ouest ») ou une cuisine
  /// (« Sénégalaise ») ; `null` : peu importe.
  final String? region;
  final MomentRepas? moment;
  final GenrePlat? genre;
  final int portions;

  /// 30 minutes ou moins en tout.
  final bool rapide;

  /// Au moins 30 g de protéines par portion.
  final bool proteinees;
  final bool vegetarien;

  /// Ce que l'utilisateur ajoute (« sans arachides », « au four »).
  final String precisions;

  /// Des aliments à UTILISER en priorité (ce qui presse au garde-manger).
  final List<String> aUtiliser;

  /// Le reste du garde-manger (à puiser dedans si possible).
  final List<String> gardeManger;

  /// Des recettes à ne pas reproposer (déjà au livre, déjà proposées).
  final List<String> aEviter;
}

List<MessageIa> invitesIdees(DemandeIdees d, {bool francais = true}) {
  final region = d.region;
  final grande = region == null
      ? null
      : kRegionsCulinaires.where((g) => g.nom == region).firstOrNull;
  final b = StringBuffer('Propose 3 recettes différentes.\n');
  if (grande != null) {
    b.writeln(
      'Cuisine : ${grande.nom} — choisis parmi ses cuisines '
      '(${grande.cuisines.join(', ')}) et varie-les ; mets la cuisine exacte '
      'dans "region".',
    );
  } else if (region != null) {
    b.writeln('Cuisine : $region (des plats authentiques de cette cuisine).');
  } else {
    b.writeln('Cuisine : au choix, variée.');
  }
  if (d.moment case final m?) {
    b.writeln('Moment : ${_nomMoment(m)} (mets-le dans "moments").');
  }
  if (d.genre case final g?) b.writeln('Genre : ${_genre(g)}.');
  b.writeln('Portions : ${d.portions}.');
  if (d.rapide) b.writeln('Rapide : 30 minutes ou moins en tout.');
  if (d.proteinees) {
    b.writeln('Riches en protéines : au moins 30 g par portion.');
  }
  if (d.vegetarien) {
    b.writeln('Végétariennes (œufs et produits laitiers permis).');
  }
  if (d.aUtiliser.isNotEmpty) {
    b.writeln(
      'À UTILISER en priorité, avant que ça se perde : '
      '${d.aUtiliser.join(', ')}. Chaque recette en emploie au moins un.',
    );
  }
  if (d.gardeManger.isNotEmpty) {
    b.writeln('Aussi au garde-manger : ${d.gardeManger.join(', ')}.');
  }
  if (d.aEviter.isNotEmpty) {
    b.writeln('Déjà connues, à ne pas reproposer : ${d.aEviter.join(', ')}.');
  }
  if (d.precisions.trim().isNotEmpty) {
    b.writeln('Précisions de l\'utilisateur : ${d.precisions.trim()}');
  }
  b
    ..writeln()
    ..writeln('Réponds en JSON : {"recettes": [ … 3 recettes … ]}')
    ..writeln(_schemaRecette)
    ..writeln(_schemaIngredient);
  return _messages(francais, b.toString());
}

List<RecetteProposee> lireIdees(
  Map<String, dynamic> j,
  DemandeIdees d, {
  bool francais = true,
}) => [
  for (final r in _listeDe(j, 'recettes'))
    ?RecetteProposee.depuisJson(
      r,
      francais: francais,
      region: d.region,
      moment: d.moment,
    ),
];

Future<List<RecetteProposee>> idees(
  DemandeIdees d, {
  bool francais = true,
}) async {
  final j = await ServiceIa.instance.json(
    invitesIdees(d, francais: francais),
    effort: Effort.moyen,
    temperature: 0.9,
    maxTokens: 12000,
  );
  final r = lireIdees(j, d, francais: francais);
  if (r.isEmpty) throw const ExceptionIa(ErreurIa.illisible);
  return r;
}

// ═══ Importer une recette collée ════════════════════════════════════════════

List<MessageIa> invitesImport(String texte, {bool francais = true}) =>
    _messages(francais, '''
Voici une recette copiée d'un site, d'un courriel ou d'un livre. Structure-la SANS RIEN INVENTER : garde ses ingrédients, ses quantités et ses étapes ; convertis les unités impériales en métrique ; si le nombre de portions ou les temps manquent, estime-les raisonnablement ; si elle est dans une autre langue, traduis-la.
Si le texte n'est pas une recette, réponds {"recette": null}.

Réponds en JSON : {"recette": { … }}
$_schemaRecette
$_schemaIngredient

LA RECETTE :
"""
${texte.trim()}
"""''');

RecetteProposee? lireImport(Map<String, dynamic> j, {bool francais = true}) =>
    RecetteProposee.depuisJson(j['recette'], francais: francais);

/// `null` : ce n'était pas une recette.
Future<RecetteProposee?> importer(String texte, {bool francais = true}) async {
  final j = await ServiceIa.instance.json(
    invitesImport(texte, francais: francais),
    effort: Effort.bas,
    temperature: 0.2,
    maxTokens: 8000,
  );
  return lireImport(j, francais: francais);
}

// ═══ Le bilan de la semaine ═════════════════════════════════════════════════

class BilanIa {
  const BilanIa({required this.resume, required this.pistes});

  final String resume;
  final List<String> pistes;

  Map<String, dynamic> versJson() => {'resume': resume, 'pistes': pistes};

  static BilanIa? depuisJson(Object? j, {bool francais = true}) {
    if (j is! Map) return null;
    final resume = texteIa(j['resume'], francais: francais);
    if (resume.isEmpty) return null;
    return BilanIa(
      resume: resume,
      pistes: textesIa(j['pistes'], francais: francais).take(4).toList(),
    );
  }
}

List<MessageIa> invitesBilan(
  BilanSemaine b, {
  required ObjectifPoids objectif,
  List<String> aConsommer = const [],
  bool francais = true,
}) {
  final m = b.moyenne;
  final t = StringBuffer()
    ..writeln(
      'Voici la semaine alimentaire (7 jours, aujourd\'hui compris), '
      'CALCULÉE par l\'application. Commente ces chiffres sans les recalculer '
      'ni en inventer d\'autres.',
    )
    ..writeln('- Journées notées : ${b.joursNotes} sur 7.')
    ..writeln(
      '- Par journée notée : ${m.kcal.round()} kcal '
      '(objectif ${b.kcalVisees}), protéines ${m.proteines.round()} g '
      '(objectif ${b.proteinesVisees}), glucides ${m.glucides.round()} g, '
      'lipides ${m.lipides.round()} g.',
    )
    ..writeln(
      b.microsConnus
          ? '- Fibres ${m.fibres.round()} g (repère '
                '${kFibresVisees.round()}), sodium ${m.sodium.round()} mg '
                '(limite ${kSodiumLimite.round()}), sucres '
                '${m.sucres.round()} g, gras saturés ${m.satures.round()} g.'
          : "- Fibres, sodium et sucres : inconnus (beaucoup d'entrées "
                "rapides) — n'en parle pas.",
    )
    ..writeln(
      '- Eau : ${_nombre(b.verresMoyens)} verres par jour '
      '(objectif ${b.verresVises}).',
    )
    ..writeln('- Séances de sport : ${b.seances}.')
    ..writeln(
      '- Objectif de poids : ${switch (objectif) {
        ObjectifPoids.perdre => 'perdre',
        ObjectifPoids.maintenir => 'maintenir',
        ObjectifPoids.prendre => 'prendre',
      }}.',
    );
  if (b.frequents.isNotEmpty) {
    t.writeln(
      '- Aliments les plus fréquents : '
      '${b.frequents.map((f) => '${f.$1} (${f.$2} fois)').join(', ')}.',
    );
  }
  if (b.jetes.isNotEmpty) t.writeln('- Jetés : ${b.jetes.join(', ')}.');
  if (aConsommer.isNotEmpty) {
    t.writeln('- À consommer bientôt : ${aConsommer.join(', ')}.');
  }
  t
    ..writeln()
    ..writeln(
      'Réponds en JSON : {"resume": "3 ou 4 phrases : ce qui va bien '
      'd\'abord, puis ce qui peut s\'améliorer, sans jugement", "pistes": '
      '["3 pistes concrètes et faisables cette semaine, une phrase chacune"]}',
    );
  if (!b.suffisant) {
    t.writeln(
      'Peu de journées sont notées : dis-le simplement, encourage à noter '
      'davantage et reste prudent dans tes conclusions.',
    );
  }
  return _messages(francais, t.toString());
}

Future<BilanIa> commenterBilan(
  BilanSemaine b, {
  required ObjectifPoids objectif,
  List<String> aConsommer = const [],
  bool francais = true,
}) async {
  final j = await ServiceIa.instance.json(
    invitesBilan(
      b,
      objectif: objectif,
      aConsommer: aConsommer,
      francais: francais,
    ),
    temperature: 0.6,
  );
  return BilanIa.depuisJson(j, francais: francais) ??
      (throw const ExceptionIa(ErreurIa.illisible));
}

// ═══ Planifier la semaine ═══════════════════════════════════════════════════

class RepasPropose {
  const RepasPropose({
    required this.jour,
    required this.moment,
    required this.recetteId,
    required this.portions,
    this.pourquoi,
  });

  /// Le jour (minuit).
  final DateTime jour;
  final MomentRepas moment;
  final String recetteId;
  final double portions;
  final String? pourquoi;
}

class PlanPropose {
  const PlanPropose({required this.repas, this.resume});

  final List<RepasPropose> repas;
  final String? resume;
}

class DemandePlan {
  const DemandePlan({
    required this.recettes,
    required this.prevus,
    required this.maintenant,
    required this.moments,
    this.personnes = 1,
    this.restes = const {},
    this.aConsommer = const [],
    this.dejaManges = const {},
    this.kcalVisees,
    this.proteinesVisees,
  });

  /// Le livre.
  final List<Recette> recettes;

  /// Les repas déjà prévus (ils restent).
  final List<RepasPrevu> prevus;
  final DateTime maintenant;

  /// Les moments à remplir.
  final Set<MomentRepas> moments;
  final int personnes;

  /// Les restes au garde-manger : recette → portions.
  final Map<String, double> restes;
  final List<String> aConsommer;

  /// Les moments d'aujourd'hui déjà notés au journal.
  final Set<MomentRepas> dejaManges;
  final int? kcalVisees, proteinesVisees;

  /// Les cases à remplir : 7 jours dès aujourd'hui, les [moments] choisis,
  /// ni passés (aujourd'hui), ni déjà notés, ni déjà prévus.
  List<(DateTime, MomentRepas)> get cases {
    final auj = jourDe(maintenant);
    final actuel = momentDuJour(maintenant);
    return [
      for (var i = 0; i < 7; i++)
        for (final m in MomentRepas.values)
          if (moments.contains(m) &&
              !(i == 0 && (m.index < actuel.index || dejaManges.contains(m))) &&
              !prevus.any((p) => p.jour == plusJours(auj, i) && p.moment == m))
            (plusJours(auj, i), m),
    ];
  }
}

/// Le moment de [maintenant] : déjeuner avant 10 h 30, dîner avant 14 h 30,
/// collation avant 17 h, souper ensuite (la planification ne revient pas à
/// la collation du soir).
MomentRepas momentDuJour(DateTime maintenant) {
  final m = maintenant.hour * 60 + maintenant.minute;
  if (m < 10 * 60 + 30) return MomentRepas.dejeuner;
  if (m < 14 * 60 + 30) return MomentRepas.diner;
  if (m < 17 * 60) return MomentRepas.collation;
  return MomentRepas.souper;
}

String _ligneRecette(Recette r, {double? restes}) {
  final p = r.parPortion;
  return [
    'id: ${r.id}',
    r.nom,
    if (r.moments.isNotEmpty)
      'moments: ${r.moments.map(_nomMoment).join(', ')}',
    'par portion: ${p.kcal.round()} kcal, ${p.proteines.round()} g de protéines',
    'donne ${r.portions} portions',
    if (r.dureeTotale != null) '${r.dureeTotale} min',
    if (r.seCongele) 'se congèle',
    if (restes != null && restes > 0)
      'RESTES au garde-manger: ${_nombre(restes)} portions',
  ].join(' | ');
}

List<MessageIa> invitesPlan(DemandePlan d, {bool francais = true}) {
  final auj = jourDe(d.maintenant);
  final t = StringBuffer()
    ..writeln(
      'Planifie les repas de la semaine avec les recettes de MON LIVRE '
      'seulement (par leur id).',
    )
    ..writeln('Les jours : ')
    ..writeln(
      [
        for (var i = 0; i < 7; i++)
          '$i = ${_joursFr[plusJours(auj, i).weekday - 1]}'
              '${i == 0 ? ' (aujourd\'hui)' : ''}',
      ].join(', '),
    )
    ..writeln('Cases à remplir (jour, moment) :')
    ..writeln(
      [
        for (final (j, m) in d.cases)
          '(${joursEntre(auj, j)}, ${_nomMoment(m)})',
      ].join(' '),
    )
    ..writeln('Foyer : ${d.personnes} portion(s) par repas.');
  if (d.kcalVisees != null) {
    t.writeln(
      'Objectifs du jour de l\'utilisateur : ${d.kcalVisees} kcal, '
      '${d.proteinesVisees} g de protéines.',
    );
  }
  t
    ..writeln('Mon livre :')
    ..writeln(
      [
        for (final r in d.recettes)
          '- ${_ligneRecette(r, restes: d.restes[r.id])}',
      ].join('\n'),
    );
  if (d.prevus.isNotEmpty) {
    t.writeln('Déjà prévu (ne pas toucher) :');
    for (final p in d.prevus) {
      final nom = d.recettes.where((r) => r.id == p.recetteId).firstOrNull?.nom;
      t.writeln(
        '- (${joursEntre(auj, p.jour)}, ${_nomMoment(p.moment)}) '
        '${nom ?? p.libre ?? 'un produit'}',
      );
    }
  }
  if (d.aConsommer.isNotEmpty) {
    t.writeln('À consommer bientôt : ${d.aConsommer.join(', ')}.');
  }
  t
    ..writeln()
    ..writeln(
      'Règles : les RESTES d\'abord (dans les 2 ou 3 jours) ; varie (pas la '
      'même recette deux jours de suite, sauf des restes) ; une recette qui '
      'donne beaucoup de portions peut revenir plus tard dans la semaine '
      '(cuisine en lot) ; respecte les moments des recettes ; les recettes '
      'rapides les soirs de semaine ; privilégie celles qui utilisent ce qui '
      'est à consommer bientôt. Laisse une case vide plutôt que de forcer.',
    )
    ..writeln(
      'Réponds en JSON : {"repas": [{"jour": 0, "moment": "souper", '
      '"recette": "id", "portions": ${d.personnes}, "pourquoi": "quelques '
      'mots"}], "resume": "une ou deux phrases sur l\'esprit de la semaine"}',
    );
  return _messages(francais, t.toString());
}

/// La réponse, vérifiée : une case à remplir, une recette du livre qui
/// convient au moment, une fois par case.
PlanPropose lirePlan(
  Map<String, dynamic> j,
  DemandePlan d, {
  bool francais = true,
}) {
  final auj = jourDe(d.maintenant);
  final libres = d.cases.toSet();
  final pris = <(DateTime, MomentRepas)>{};
  final repas = <RepasPropose>[];
  for (final x in _listeDe(j, 'repas')) {
    final i = x['jour'];
    final moment = momentDe(x['moment']);
    if (i is! num || moment == null) continue;
    final jour = plusJours(auj, i.round());
    final recette = d.recettes.where((r) => r.id == x['recette']).firstOrNull;
    if (recette == null ||
        !recette.pour(moment) ||
        !libres.contains((jour, moment)) ||
        !pris.add((jour, moment))) {
      continue;
    }
    final p = x['portions'];
    final pourquoi = texteIa(x['pourquoi'], francais: francais);
    repas.add(
      RepasPropose(
        jour: jour,
        moment: moment,
        recetteId: recette.id,
        portions: p is num && p >= 0.5 && p <= 12
            ? (p * 2).round() / 2
            : d.personnes.toDouble(),
        pourquoi: pourquoi.isEmpty ? null : pourquoi,
      ),
    );
  }
  repas.sort((a, b) {
    final c = a.jour.compareTo(b.jour);
    return c != 0 ? c : a.moment.index.compareTo(b.moment.index);
  });
  final resume = texteIa(j['resume'], francais: francais);
  return PlanPropose(repas: repas, resume: resume.isEmpty ? null : resume);
}

Future<PlanPropose> planifierSemaine(
  DemandePlan d, {
  bool francais = true,
}) async {
  final j = await ServiceIa.instance.json(
    invitesPlan(d, francais: francais),
    effort: Effort.moyen,
    temperature: 0.5,
    maxTokens: 8000,
  );
  return lirePlan(j, d, francais: francais);
}

// ═══ Combler l'écart ════════════════════════════════════════════════════════

class OptionEcart {
  const OptionEcart({
    required this.titre,
    this.pourquoi,
    this.aliments = const [],
    this.recetteId,
    this.portions = 1,
  });

  final String titre;
  final String? pourquoi;

  /// Des aliments à manger (cherchés dans la base) ; ou…
  final List<IngredientPropose> aliments;

  /// … une recette du livre (ou ses restes), [portions] portions.
  final String? recetteId;
  final double portions;
}

class DemandeEcart {
  const DemandeEcart({
    required this.moment,
    required this.reste,
    required this.visees,
    this.recettes = const [],
    this.restes = const {},
    this.gardeManger = const [],
    this.aConsommer = const [],
  });

  /// Le repas à composer (souper, collation).
  final MomentRepas moment;

  /// Ce qu'il reste pour la journée (kcal, protéines, glucides, lipides).
  final Nutriments reste;

  /// Les objectifs de la journée.
  final Nutriments visees;
  final List<Recette> recettes;
  final Map<String, double> restes;
  final List<String> gardeManger;
  final List<String> aConsommer;
}

List<MessageIa> invitesEcart(DemandeEcart d, {bool francais = true}) {
  final r = d.reste;
  final t = StringBuffer()
    ..writeln(
      'Il reste un repas à prendre aujourd\'hui : ${_nomMoment(d.moment)}. '
      'Propose 3 options simples pour s\'approcher de ce qui reste de la '
      'journée, sans le dépasser de beaucoup.',
    )
    ..writeln(
      'Il reste : ${r.kcal.round()} kcal, protéines ${r.proteines.round()} g, '
      'glucides ${r.glucides.round()} g, lipides ${r.lipides.round()} g '
      '(objectifs de la journée : ${d.visees.kcal.round()} kcal, '
      '${d.visees.proteines.round()} g de protéines).',
    );
  if (d.aConsommer.isNotEmpty) {
    t.writeln('À consommer bientôt : ${d.aConsommer.join(', ')}.');
  }
  if (d.gardeManger.isNotEmpty) {
    t.writeln('Au garde-manger : ${d.gardeManger.join(', ')}.');
  }
  if (d.recettes.isNotEmpty) {
    t
      ..writeln('Mon livre (une option peut être une recette, par son id) :')
      ..writeln(
        [
          for (final x in d.recettes)
            '- ${_ligneRecette(x, restes: d.restes[x.id])}',
        ].join('\n'),
      );
  }
  t
    ..writeln()
    ..writeln(
      'Privilégie ce qui est déjà là (les restes d\'abord). Une option est '
      'SOIT une recette du livre ("recette" + "portions"), SOIT une liste '
      'd\'aliments simples à assembler ("aliments").',
    )
    ..writeln(
      'Réponds en JSON : {"options": [{"titre": "…", "pourquoi": "une '
      'phrase", "recette": "id ou null", "portions": 1, "aliments": [ … ]}]}',
    )
    ..writeln(_schemaIngredient);
  return _messages(francais, t.toString());
}

List<OptionEcart> lireEcart(
  Map<String, dynamic> j,
  DemandeEcart d, {
  bool francais = true,
}) {
  final options = <OptionEcart>[];
  for (final x in _listeDe(j, 'options')) {
    final titre = texteIa(x['titre'], francais: francais);
    if (titre.isEmpty) continue;
    final recette = d.recettes.where((r) => r.id == x['recette']).firstOrNull;
    final aliments = [
      if (x['aliments'] is List)
        for (final a in x['aliments'] as List)
          ?IngredientPropose.depuisJson(a, francais: francais),
    ];
    if (recette == null && aliments.isEmpty) continue;
    final p = x['portions'];
    final pourquoi = texteIa(x['pourquoi'], francais: francais);
    options.add(
      OptionEcart(
        titre: titre,
        pourquoi: pourquoi.isEmpty ? null : pourquoi,
        recetteId: recette?.id,
        aliments: recette == null ? aliments : const [],
        portions: p is num && p >= 0.5 && p <= 4 ? (p * 2).round() / 2 : 1,
      ),
    );
  }
  return options.take(3).toList();
}

Future<List<OptionEcart>> comblerEcart(
  DemandeEcart d, {
  bool francais = true,
}) async {
  final j = await ServiceIa.instance.json(
    invitesEcart(d, francais: francais),
    effort: Effort.moyen,
    temperature: 0.6,
    maxTokens: 8000,
  );
  final r = lireEcart(j, d, francais: francais);
  if (r.isEmpty) throw const ExceptionIa(ErreurIa.illisible);
  return r;
}

// ═══ Estimer un repas sans recette ══════════════════════════════════════════

List<MessageIa> invitesEstimation(String repas, {bool francais = true}) =>
    _messages(francais, '''
Décompose ce repas en aliments simples, avec des quantités réalistes pour UNE personne (portion habituelle au Québec si rien n'est précisé). Un plat composé (pizza, poutine, pâté chinois) se décompose en ses ingrédients principaux.
Si ce n'est pas un repas, réponds {"aliments": []}.

Réponds en JSON : {"titre": "le repas en quelques mots", "aliments": [ … ]}
$_schemaIngredient

LE REPAS : ${repas.trim()}''');

({String titre, List<IngredientPropose> aliments}) lireEstimation(
  Map<String, dynamic> j, {
  bool francais = true,
}) => (
  titre: texteIa(j['titre'], francais: francais),
  aliments: [
    for (final a in _listeDe(j, 'aliments'))
      if (IngredientPropose.depuisJson(a, francais: francais) case final i?
          when !i.libre)
        i,
  ],
);

Future<({String titre, List<IngredientPropose> aliments})> estimerRepas(
  String repas, {
  bool francais = true,
}) async {
  final j = await ServiceIa.instance.json(
    invitesEstimation(repas, francais: francais),
    temperature: 0.3,
  );
  return lireEstimation(j, francais: francais);
}

// ═══ Substitutions ══════════════════════════════════════════════════════════

/// Pourquoi remplacer un ingrédient.
enum RaisonSubstitution {
  manque,
  plusLeger,
  plusProteine,
  vegetarien,
  allergie,
}

String _raison(RaisonSubstitution r) => switch (r) {
  RaisonSubstitution.manque => "je n'en ai pas sous la main",
  RaisonSubstitution.plusLeger => 'je veux une version plus légère',
  RaisonSubstitution.plusProteine => 'je veux plus de protéines',
  RaisonSubstitution.vegetarien => 'je veux une version végétarienne',
  RaisonSubstitution.allergie =>
    "une allergie ou une intolérance (propose des remplaçants sûrs et "
        "rappelle de vérifier les étiquettes)",
};

class Substitution {
  const Substitution({required this.ingredient, this.pourquoi});

  final IngredientPropose ingredient;
  final String? pourquoi;
}

List<MessageIa> invitesSubstitution(
  Recette r,
  Ingredient i, {
  RaisonSubstitution? raison,
  bool francais = true,
}) => _messages(francais, '''
Dans la recette « ${r.nom} » (${r.portions} portions), propose 3 remplaçants pour l'ingrédient « ${i.nom} »${i.grammes == null ? '' : ' (${i.grammes!.round()} g)'}${raison == null ? '' : ', parce que ${_raison(raison)}'}.
Les autres ingrédients : ${[for (final x in r.ingredients)
  if (x.nom != i.nom) x.nom].join(', ')}.
Donne la quantité qui remplace celle de la recette, et en une phrase ce que ça change (goût, texture, cuisson).

Réponds en JSON : {"options": [{"ingredient": { … }, "pourquoi": "…"}]}
$_schemaIngredient''');

List<Substitution> lireSubstitutions(
  Map<String, dynamic> j, {
  bool francais = true,
}) => [
  for (final x in _listeDe(j, 'options'))
    if (IngredientPropose.depuisJson(x['ingredient'], francais: francais)
        case final i?)
      Substitution(
        ingredient: i,
        pourquoi: switch (texteIa(x['pourquoi'], francais: francais)) {
          '' => null,
          final p => p,
        },
      ),
].take(3).toList();

Future<List<Substitution>> substituer(
  Recette r,
  Ingredient i, {
  RaisonSubstitution? raison,
  bool francais = true,
}) async {
  final j = await ServiceIa.instance.json(
    invitesSubstitution(r, i, raison: raison, francais: francais),
    temperature: 0.5,
  );
  final s = lireSubstitutions(j, francais: francais);
  if (s.isEmpty) throw const ExceptionIa(ErreurIa.illisible);
  return s;
}

// ═══ La conservation d'un aliment hors du guide ═════════════════════════════

List<MessageIa> invitesConservation(
  String nom,
  Rayon rayon, {
  bool francais = true,
}) => _messages(
  francais,
  '''
Comment conserver « ${nom.trim()} » (rayon : ${rayon.name}) à la maison ? Suis les repères prudents du Thermoguide du MAPAQ (frigo à 4 °C, congélateur à −18 °C).
Durées en JOURS, [la plus courte, la plus longue], ou null si l'aliment ne se garde pas là. "ambiant" = à l'armoire ou sur le comptoir. "ouvert" = une fois l'emballage ouvert (au frigo, sauf mention).

Réponds en JSON : {"ideal": "frigo" | "congelateur" | "armoire" | "comptoir", "frigo": [3, 5], "congelateur": [60, 90], "ambiant": null, "ouvert": null, "conseil": "où et comment le garder, en une ou deux phrases"}''',
);

/// Le repère lu (durées bornées à deux ans, jamais à rebours) ; `null`
/// sans conseil ni durée.
Conservation? lireConservation(
  Map<String, dynamic> j,
  String nom,
  Rayon rayon, {
  bool francais = true,
}) {
  Duree? duree(Object? v) {
    if (v is! List || v.length != 2) return null;
    final a = v[0], b = v[1];
    if (a is! num || b is! num || !a.isFinite || !b.isFinite) return null;
    final x = a.round().clamp(0, 730), y = b.round().clamp(0, 730);
    if (x == 0 && y == 0) return null;
    return x <= y ? (x, y) : (y, x);
  }

  final conseil = texteIa(j['conseil'], francais: francais);
  final frigo = duree(j['frigo']);
  final congelo = duree(j['congelateur']);
  final ambiant = duree(j['ambiant']);
  final ouvert = duree(j['ouvert']);
  if (conseil.isEmpty && frigo == null && congelo == null && ambiant == null) {
    return null;
  }
  final ideal = switch (motsDe('${j['ideal']}').join(' ')) {
    'frigo' || 'refrigerateur' || 'fridge' => Emplacement.frigo,
    'congelateur' || 'freezer' => Emplacement.congelateur,
    'armoire' || 'garde manger' || 'pantry' => Emplacement.armoire,
    'comptoir' || 'counter' => Emplacement.comptoir,
    _ => null,
  };
  return Conservation(
    [cleConservation(nom)],
    rayon,
    ideal ??
        (frigo != null
            ? Emplacement.frigo
            : ambiant != null
            ? Emplacement.armoire
            : Emplacement.congelateur),
    conseil,
    frigo: frigo,
    congelo: congelo,
    ambiant: ambiant,
    ouvert: ouvert,
  );
}

Future<Conservation?> conservationIa(
  String nom,
  Rayon rayon, {
  bool francais = true,
}) async {
  final j = await ServiceIa.instance.json(
    invitesConservation(nom, rayon, francais: francais),
    temperature: 0.2,
  );
  return lireConservation(j, nom, rayon, francais: francais) ??
      (throw const ExceptionIa(ErreurIa.illisible));
}
