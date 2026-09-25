// test/outils/faux_ia.dart
//
// Un FAUX service d'IA (aucun réseau), qui répond comme Groq aux demandes
// de l'assistant de l'Alimentation : des idées (poulet yassa, mafé…), une
// recette importée, un bilan, une semaine, l'écart du soir, une
// estimation, des remplaçants, une conservation. Il garde ce qu'on lui
// envoie (pour vérifier que rien de personnel ne part). Partagé par
// `ia_ecrans_test.dart` et `captures_ia_test.dart`.

import 'package:rhythm/ia/service_ia.dart';

Map<String, dynamic> ingredientIa(
  String nom,
  num quantite,
  String unite,
  num kcal,
  String fcen, {
  String? taille,
  num? grammes,
}) => {
  'nom': nom,
  'quantite': quantite,
  'unite': unite,
  'taille': ?taille,
  'grammes': grammes ?? quantite,
  'kcal': kcal,
  'fcen': fcen,
};

final Map<String, dynamic> recetteYassa = {
  'nom': 'Poulet yassa',
  'description': 'Poulet mariné au citron et aux oignons, fondant et acidulé.',
  'region': 'Sénégalaise',
  'moments': ['souper'],
  'portions': 4,
  'preparation': 20,
  'cuisson': 45,
  'congele': true,
  'ingredients': [
    ingredientIa('Poitrines de poulet', 600, 'g', 720, 'poulet poitrine crue'),
    ingredientIa(
      'Oignons',
      3,
      'unite',
      180,
      'oignon cru',
      taille: 'gros',
      grammes: 450,
    ),
    ingredientIa('Jus de citron', 60, 'ml', 13, 'jus de citron'),
    ingredientIa('Huile de canola', 30, 'ml', 250, 'huile canola'),
    ingredientIa('Riz blanc', 250, 'ml', 710, 'riz blanc grain long cru'),
    {'nom': 'Sel et poivre', 'libre': true},
  ],
  'etapes': [
    '1. Mariner le poulet dans le citron et les oignons 2 heures.',
    'Faire dorer le poulet 10 minutes.',
    'Ajouter la marinade et mijoter 30 minutes.',
    'Servir avec le riz.',
  ],
  'note': 'Encore meilleur le lendemain.',
};

Map<String, dynamic> _simple(String nom, String region, String description) => {
  'nom': nom,
  'description': description,
  'region': region,
  'moments': ['souper'],
  'portions': 4,
  'preparation': 15,
  'cuisson': 30,
  'ingredients': [
    ingredientIa('Bœuf haché', 450, 'g', 1000, 'boeuf haché maigre cru'),
    ingredientIa('Oignon', 1, 'unite', 60, 'oignon cru', taille: 'gros'),
    ingredientIa("Beurre d'arachide", 60, 'ml', 380, "beurre d'arachide"),
  ],
  'etapes': ['Cuire 20 minutes.'],
};

class FauxServiceIa extends ServiceIa {
  FauxServiceIa({this.erreur}) : super(cle: 'test');

  /// Toutes les demandes échouent ainsi.
  final ErreurIa? erreur;
  final List<List<MessageIa>> appels = [];

  /// Tout ce qui est parti vers l'IA, en un texte.
  String get envoye => appels.expand((m) => m).map((m) => m.contenu).join('\n');

  @override
  Future<Map<String, dynamic>> json(
    List<MessageIa> messages, {
    Effort effort = Effort.bas,
    double temperature = 0.4,
    int maxTokens = 4096,
  }) async {
    appels.add(messages);
    if (erreur != null) throw ExceptionIa(erreur!);
    final d = messages.last.contenu;
    if (d.contains('Propose 3 recettes')) {
      return {
        'recettes': [
          recetteYassa,
          _simple(
            'Mafé au bœuf',
            'Malienne',
            'Un ragoût à la sauce d\'arachide, réconfortant.',
          ),
          _simple('Tiep bou yapp', 'Italienne', 'Riz à la viande, épicé.'),
        ],
      };
    }
    if (d.contains('Structure-la')) return {'recette': recetteYassa};
    if (d.contains('semaine alimentaire')) {
      return {
        'resume':
            'Tu as noté presque tous tes repas : bravo ! Les protéines '
            'suivent bien ; les fibres restent un peu basses.',
        'pistes': [
          'Ajoute des légumineuses deux fois cette semaine.',
          'Garde une bouteille d\'eau près de toi : un verre de plus.',
          'Les épinards pressent : une omelette ce soir ?',
        ],
      };
    }
    if (d.contains('Planifie les repas')) {
      return {
        'repas': [
          {
            'jour': 0,
            'moment': 'souper',
            'recette': 'depart-saumon',
            'portions': 2,
            'pourquoi': 'rapide un soir de semaine',
          },
          {
            'jour': 2,
            'moment': 'diner',
            'recette': 'depart-bol-poulet',
            'pourquoi': 'se prépare la veille',
          },
          {'jour': 2, 'moment': 'souper', 'recette': 'depart-chili'},
        ],
        'resume': 'Du poisson, du poulet, et les restes au bon moment.',
      };
    }
    if (d.contains('Il reste un repas')) {
      return {
        'options': [
          {
            'titre': 'Omelette et rôties',
            'pourquoi': 'Des protéines, vite, avec les œufs du frigo.',
            'recette': null,
            'aliments': [
              ingredientIa(
                'Œufs',
                2,
                'unite',
                140,
                'oeuf entier cru',
                grammes: 100,
              ),
              ingredientIa(
                'Pain de blé entier',
                2,
                'unite',
                180,
                'pain blé entier',
                taille: 'tranche',
                grammes: 70,
              ),
            ],
          },
          {
            'titre': 'Le chili',
            'pourquoi': 'Une portion des restes, rien à cuisiner.',
            'recette': 'depart-chili',
            'portions': 1,
          },
        ],
      };
    }
    if (d.contains('Décompose ce repas')) {
      return {
        'titre': 'Rôties et banane',
        'aliments': [
          ingredientIa(
            'Pain de blé entier',
            2,
            'unite',
            180,
            'pain blé entier',
            taille: 'tranche',
            grammes: 70,
          ),
          ingredientIa("Beurre d'arachide", 30, 'g', 180, "beurre d'arachide"),
          ingredientIa('Banane', 1, 'unite', 105, 'banane crue', grammes: 118),
          ingredientIa('Zzqwx', 10, 'g', 10, 'zzqwx'),
        ],
      };
    }
    if (d.contains('remplaçants')) {
      return {
        'options': [
          {
            'ingredient': ingredientIa('Feta', 20, 'g', 53, 'fromage feta'),
            'pourquoi': 'Plus salée, elle fond moins.',
          },
          {
            'ingredient': ingredientIa(
              'Levure alimentaire',
              10,
              'g',
              33,
              'levure alimentaire',
            ),
            'pourquoi': 'Un goût de fromage, sans lactose.',
          },
        ],
      };
    }
    if (d.contains('Comment conserver')) {
      return {
        'ideal': 'frigo',
        'frigo': [3, 5],
        'congelateur': [30, 60],
        'ambiant': null,
        'ouvert': null,
        'conseil': 'Au frigo, dans un contenant bien fermé.',
      };
    }
    throw const ExceptionIa(ErreurIa.illisible);
  }
}
