// test/recettes_test.dart
//
// Les RECETTES (palier 3 de l'Alimentation) : les étapes et les minuteurs
// repérés dans le texte, les quantités d'un ingrédient, les besoins pour la
// liste (moins le garde-manger et la liste), la semaine et la cuisine en
// lot, le décompte du garde-manger, les restes, la décongélation, le livre
// (recherche, tri), l'état (cuisiner → journal + restes + garde-manger,
// noter depuis les restes, planifier, recettes de départ), le JSON
// tolérant, le dépôt, les rappels (décongélation, minuteurs) et le conseil
// du soir.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/l10n/app_localizations.dart';
import 'package:rhythm/modele/alimentation/alimentation.dart';
import 'package:rhythm/modele/alimentation/base_aliments.dart' show motsDe;
import 'package:rhythm/modele/alimentation/calculs_alimentation.dart';
import 'package:rhythm/modele/alimentation/calculs_recettes.dart';
import 'package:rhythm/modele/alimentation/courses.dart';
import 'package:rhythm/modele/alimentation/etat_alimentation.dart';
import 'package:rhythm/modele/alimentation/etat_courses.dart';
import 'package:rhythm/modele/alimentation/etat_recettes.dart';
import 'package:rhythm/modele/alimentation/nutriments.dart';
import 'package:rhythm/modele/alimentation/recettes.dart';
import 'package:rhythm/modele/depot.dart';
import 'package:rhythm/modele/etat_habitudes.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/modele/modeles.dart';
import 'package:rhythm/systeme/rappels_recettes.dart';

/// Jeudi 24 septembre 2026, 8 h.
final DateTime _auj = DateTime(2026, 9, 24, 8);

const _nb = ' ';

Ingredient _base(
  String nom,
  double grammes, {
  double? nombre,
  String? mesure,
  double kcal = 100,
}) => Ingredient(
  nom: nom,
  source: SourceIngredient.base,
  code: 1,
  grammes: grammes,
  nombre: nombre,
  mesure: mesure,
  nutriments: Nutriments(kcal: kcal, proteines: kcal / 10),
);

Recette _recette(
  String id,
  String nom,
  List<Ingredient> ingredients, {
  int portions = 4,
  Set<MomentRepas> moments = const {MomentRepas.souper},
}) => Recette(
  id: id,
  nom: nom,
  creee: DateTime(2026, 9, 1),
  moments: moments,
  portions: portions,
  ingredients: ingredients,
);

ArticleGardeManger _gm(
  String id,
  String nom, {
  Quantite? quantite,
  Emplacement ou = Emplacement.frigo,
  DateTime? peremption,
  String? recette,
}) => ArticleGardeManger(
  id: id,
  nom: nom,
  emplacement: ou,
  rayon: Rayon.autre,
  entre: _auj,
  quantite: quantite,
  peremption: peremption,
  recetteId: recette,
);

void main() {
  group('les étapes et les minuteurs', () {
    test('une étape par ligne, sans numéro', () {
      expect(
        lireEtapes(
          '1. Hacher l\'oignon.\n2) Cuire\n\n- Servir\n• Goûter\n'
          'Étape 5 : Manger\n10 minutes au four',
        ),
        [
          "Hacher l'oignon.",
          'Cuire',
          'Servir',
          'Goûter',
          'Manger',
          '10 minutes au four',
        ],
      );
    });

    Duration seul(String t) {
      final m = minuteursDans(t);
      expect(m, hasLength(1), reason: t);
      return m.single.duree;
    }

    test('les durées d\'une étape, en français', () {
      expect(seul('Cuire 5 minutes à feu doux.'), const Duration(minutes: 5));
      expect(seul('Cuire 5${_nb}minutes.'), const Duration(minutes: 5));
      expect(seul('Cuire 8 min'), const Duration(minutes: 8));
      // Un intervalle : la plus courte (on vérifie tôt).
      final t = 'Laisser mijoter 25 à 30 minutes à feu doux.';
      final m = minuteursDans(t).single;
      expect(m.duree, const Duration(minutes: 25));
      expect(t.substring(m.debut, m.fin), '25 à 30 minutes');
      expect(seul('Rôtir 1 h 30.'), const Duration(minutes: 90));
      expect(seul('Rôtir 1h15'), const Duration(minutes: 75));
      expect(seul('Mijoter 2 heures'), const Duration(hours: 2));
      expect(seul('Mélanger 30 secondes'), const Duration(seconds: 30));
      expect(seul('Reposer une demi-heure'), const Duration(minutes: 30));
      expect(seul('Cuire une heure et demie'), const Duration(minutes: 90));
      expect(seul('Cook for 10 minutes'), const Duration(minutes: 10));
    });

    test('ni les températures, ni les quantités', () {
      final t = 'Cuire au four à 190 °C (375 °F) 30 minutes.';
      expect(minuteursDans(t).single.duree, const Duration(minutes: 30));
      expect(minuteursDans('Ajouter 2 carottes hachées et 3 gousses'), isEmpty);
      expect(minuteursDans('Pour 4 personnes, 500 ml de lait'), isEmpty);
      // Deux minuteurs dans une étape, dans l'ordre.
      expect(
        minuteursDans(
          'Rôtir 1 h 30, puis laisser reposer 10 min.',
        ).map((m) => m.duree),
        const [Duration(minutes: 90), Duration(minutes: 10)],
      );
    });
  });

  group('les quantités', () {
    test('millilitres, unités, grammes, libre', () {
      expect(
        quantiteDe(_base('Lait', 515, nombre: 2, mesure: '250 ml')),
        const Quantite(500, Unite.ml),
      );
      expect(
        quantiteDe(_base('Lait', 1031, nombre: 4, mesure: '250 ml')),
        const Quantite(1, Unite.l),
      );
      expect(
        quantiteDe(
          _base('Banane', 236, nombre: 2, mesure: '1 moyen (18cm à 20cm long)'),
        ),
        const Quantite(2),
      );
      expect(
        quantiteDe(
          _base(
            'Poulet',
            180,
            nombre: 2,
            mesure: '1 portion du guide alimentaire = 90g',
          ),
        ),
        const Quantite(180, Unite.g),
      );
      expect(quantiteDe(_base('Poulet', 600)), const Quantite(600, Unite.g));
      expect(quantiteDe(_base('Patates', 1000)), const Quantite(1, Unite.kg));
      expect(
        quantiteDe(
          const Ingredient(nom: 'Tomates', quantite: Quantite(1, Unite.paquet)),
        ),
        const Quantite(1, Unite.paquet),
      );
      expect(quantiteDe(const Ingredient(nom: 'Sel')), isNull);
      // Une partie d'aliment (des gousses) : en grammes pour les courses.
      expect(
        quantiteDe(_base('Ail', 6, nombre: 2, mesure: '1 gousse')),
        const Quantite(6, Unite.g),
      );
    });

    test('une recette à l\'échelle, par portion', () {
      final r = _recette('r', 'Chili', [
        _base('Haricots', 334, nombre: 2, mesure: '250 ml', kcal: 400),
        _base('Oignon', 150, nombre: 1, mesure: '1 gros', kcal: 60),
        const Ingredient(nom: 'Cumin'),
      ]);
      expect(r.total.kcal, 460);
      expect(r.parPortion.kcal, 115);
      final double = r.ingredients.first.fois(2);
      expect(double.nombre, 4);
      expect(double.grammes, 668);
      expect(double.nutriments.kcal, 800);
      expect(quantiteDe(double), const Quantite(1, Unite.l));
    });
  });

  group('la liste (les besoins)', () {
    final chili = _recette('chili', 'Chili', [
      _base('Oignon', 150, nombre: 1, mesure: '1 gros'),
      _base('Riz', 195, nombre: 1, mesure: '250 ml'),
      const Ingredient(nom: 'Sel et poivre'),
      const Ingredient(nom: 'Coriandre fraîche'),
      const Ingredient(nom: 'Eau', quantite: Quantite(750, Unite.ml)),
    ]);
    final bol = _recette('bol', 'Bol poulet', [
      _base('Oignon', 150, nombre: 1, mesure: '1 gros'),
      _base('Poitrines de poulet', 600),
      _base('Lait 2 %', 257, nombre: 2, mesure: '250 ml'),
      _base('Carottes', 263),
      _base('Huile de canola', 14, nombre: 1, mesure: '15 ml'),
      _base('Ail', 6, nombre: 2, mesure: '1 gousse'),
    ]);

    test('additionnés, moins le garde-manger et la liste', () {
      final besoins = besoinsDe(
        [(chili, 1), (bol, 1)],
        gardeManger: [
          _gm('o', 'Oignons', quantite: const Quantite(1)),
          _gm(
            'p',
            'Poitrines de poulet',
            quantite: const Quantite(900, Unite.g),
          ),
          _gm('r', 'Riz basmati', quantite: const Quantite(1, Unite.paquet)),
          // Des restes ne comptent pas comme un stock d'ingrédient.
          _gm('x', 'Carottes (restes)', recette: 'autre'),
        ],
        liste: [
          ArticleListe(
            id: 'l',
            nom: 'Lait 2 %',
            rayon: Rayon.laitiers,
            ajoute: _auj,
            quantites: const [Quantite(2, Unite.l)],
          ),
        ],
      );
      Besoin b(String nom) => besoins.firstWhere((x) => x.nom == nom);
      // L'eau ne va jamais sur la liste.
      expect(besoins.any((x) => x.nom == 'Eau'), isFalse);
      // Deux oignons, un au garde-manger : il en manque un.
      expect(b('Oignon').requis, const [Quantite(2)]);
      expect(b('Oignon').aAcheter, const [Quantite(1)]);
      expect(b('Oignon').origines, ['Chili', 'Bol poulet']);
      expect(b('Oignon').aProposer, isTrue);
      // 600 g sur 900 : couvert.
      expect(b('Poitrines de poulet').aProposer, isFalse);
      // Un paquet de riz couvre 250 ml (on ne compare pas).
      expect(b('Riz').aProposer, isFalse);
      // Déjà 2 L de lait sur la liste.
      expect(b('Lait 2 %').aProposer, isFalse);
      // Les carottes manquent, arrondies à 5 g près.
      expect(b('Carottes').aAcheter, const [Quantite(265, Unite.g)]);
      // L'huile, d'habitude au placard : à vérifier, pas cochée.
      expect(b('Huile de canola').aVerifier, isTrue);
      expect(b('Huile de canola').aProposer, isFalse);
      // Sans quantité : la coriandre manque, le sel et le poivre non.
      expect(b('Coriandre fraîche').aProposer, isTrue);
      expect(b('Sel et poivre').aProposer, isFalse);
    });
  });

  group('la semaine et la cuisine en lot', () {
    test('par demi-recette, au-dessus', () {
      final r = _recette('r', 'R', const [], portions: 4);
      expect(lotsPour(r, 0), 0);
      expect(lotsPour(r, 1), 0.5);
      expect(lotsPour(r, 3), 1);
      expect(lotsPour(r, 4), 1);
      expect(lotsPour(r, 5), 1.5);
    });

    test('la démonstration : le chili trois fois, une seule recette', () {
      final etat = GraineRecettes.demonstration(_auj);
      final semaine = recettesDeLaSemaine(
        etat,
        debut: _auj,
        journal: const [],
        gardeManger: const [],
      );
      final chili = semaine.firstWhere((s) => s.recette.id == 'depart-chili');
      expect(chili.repas, hasLength(3));
      expect(chili.portions, 3);
      expect(chili.lots, 1);
      // Deux portions de restes au frigo : il n'en manque plus qu'une.
      final avecRestes = recettesDeLaSemaine(
        etat,
        debut: _auj,
        journal: const [],
        gardeManger: [
          _gm(
            'c',
            'Chili sin carne (restes)',
            quantite: const Quantite(2),
            recette: 'depart-chili',
          ),
        ],
      ).firstWhere((s) => s.recette.id == 'depart-chili');
      expect(avecRestes.aCuisiner, 1);
      expect(avecRestes.lots, 0.5);
      // Un repas déjà noté ne compte plus.
      final premier = chili.repas.first;
      final note = recettesDeLaSemaine(
        etat,
        debut: _auj,
        journal: [
          entreeDeRecette(
            id: 'e',
            recette: chili.recette,
            portions: 1,
            jour: premier.jour,
            moment: premier.moment,
            ajoutee: _auj,
          ),
        ],
        gardeManger: const [],
      ).firstWhere((s) => s.recette.id == 'depart-chili');
      expect(note.repas, hasLength(2));
    });

    test('les ingrédients partagés, à préparer en une fois', () {
      final depart = GraineRecettes.depart(_auj);
      final partages = ingredientsPartages(depart);
      final oignon = partages.firstWhere((p) => p.$1 == 'Oignon');
      expect(oignon.$2, containsAll(['Chili sin carne', 'Pâté chinois']));
      // L'huile se sort, elle ne se prépare pas.
      expect(partages.any((p) => p.$1.startsWith('Huile')), isFalse);
    });
  });

  group('le garde-manger après la cuisine', () {
    test('ce qu\'il en restera', () {
      final d = decompteGardeManger(
        [
          _base('Poitrines de poulet', 600),
          _base('Œufs', 137, nombre: 3, mesure: '1 oeuf moyen'),
          _base('Épinards', 32, nombre: 1, mesure: '250 ml'),
        ],
        [
          _gm(
            'p',
            'Poitrines de poulet',
            quantite: const Quantite(900, Unite.g),
          ),
          _gm('o', 'Œufs', quantite: const Quantite(8)),
          _gm('e', 'Épinards'),
          _gm('r', 'Poulet (restes)', recette: 'x'),
        ],
      );
      expect(d.map((x) => x.article.id), ['p', 'o', 'e']);
      expect(d[0].calcule, isTrue);
      expect(d[0].reste, const Quantite(300, Unite.g));
      expect(d[0].fini, isFalse);
      expect(d[1].reste, const Quantite(5));
      // Sans quantité : à la personne de dire s'il est fini.
      expect(d[2].calcule, isFalse);
      // Tout utilisé : fini.
      final tout = decompteGardeManger(
        [_base('Poulet', 900)],
        [_gm('p', 'Poulet', quantite: const Quantite(0.9, Unite.kg))],
      ).single;
      expect(tout.fini, isTrue);
    });

    test('les restes : 3 jours au frigo, 3 mois au congélateur', () {
      expect(restesJusquau(_auj, Emplacement.frigo), DateTime(2026, 9, 27));
      expect(
        restesJusquau(_auj, Emplacement.congelateur),
        DateTime(2026, 12, 23),
      );
    });

    test('la décongélation : ce qui n\'est qu\'au congélateur', () {
      final pate = GraineRecettes.depart(
        _auj,
      ).firstWhere((r) => r.id == 'depart-pate-chinois');
      final congele = _gm(
        'b',
        'Bœuf haché maigre',
        quantite: const Quantite(450, Unite.g),
        ou: Emplacement.congelateur,
      );
      expect(aDecongelerPour(pate, [congele]).single.id, 'b');
      // Il y en a aussi au frigo : rien à sortir.
      expect(aDecongelerPour(pate, [congele, _gm('f', 'Bœuf haché')]), isEmpty);
      // Le repas prévu demain.
      final etat = EtatRecettes(
        recettes: [pate],
        plan: [
          RepasPrevu(
            id: 'p',
            jour: DateTime(2026, 9, 25),
            moment: MomentRepas.souper,
            recetteId: pate.id,
          ),
        ],
      );
      final d = decongelationsDu(DateTime(2026, 9, 25), etat, [congele]);
      expect(d.single.articles.single.nom, 'Bœuf haché maigre');
      // Des restes congelés suffisent : ce sont eux qu'on sort.
      final restes = _gm(
        'r',
        'Pâté chinois (restes)',
        quantite: const Quantite(2),
        ou: Emplacement.congelateur,
        recette: pate.id,
      );
      expect(
        decongelationsDu(DateTime(2026, 9, 25), etat, [
          congele,
          restes,
        ]).single.articles.single.id,
        'r',
      );
    });
  });

  group('le livre', () {
    final livre = GraineRecettes.demonstration(_auj).recettes;

    test('la recherche : nom, région, ingrédients', () {
      List<String> ids(String q) => [
        for (final r in livre)
          if (recetteRepond(r, q)) r.id,
      ];
      expect(ids('chili'), ['depart-chili']);
      expect(ids('haitienne'), ['depart-riz-colle']);
      expect(ids('boeuf'), ['depart-pate-chinois']);
      expect(ids(''), hasLength(8));
      // La grande région aussi : le riz collé est haïtien, donc des
      // Caraïbes.
      expect(ids('caraibes'), ['depart-riz-colle']);
    });

    test('les régions : une cuisine et sa grande région', () {
      expect(grandeRegionDe('Sénégalaise')?.nom, "Afrique de l'Ouest");
      expect(grandeRegionDe('senegalaise')?.nom, "Afrique de l'Ouest");
      expect(grandeRegionDe("Afrique de l'Ouest")?.nom, "Afrique de l'Ouest");
      expect(grandeRegionDe('Québécoise')?.nom, 'Amérique du Nord');
      expect(grandeRegionDe('Haïtienne')?.nom, 'Caraïbes');
      expect(grandeRegionDe('Créole'), isNull);
      expect(grandeRegionDe(null), isNull);
      expect(dansLaRegion('Sénégalaise', "Afrique de l'Ouest"), isTrue);
      expect(dansLaRegion('Sénégalaise', 'Sénégalaise'), isTrue);
      expect(dansLaRegion("Afrique de l'Ouest", 'Sénégalaise'), isFalse);
      expect(dansLaRegion('Marocaine', "Afrique de l'Ouest"), isFalse);
      expect(dansLaRegion('Créole', 'Créole'), isTrue);
      expect(dansLaRegion(null, 'Europe'), isFalse);
      // Les cinq Afriques, l'Europe, les Amériques, l'Asie.
      final noms = [for (final g in kRegionsCulinaires) g.nom];
      expect(
        noms,
        containsAll([
          "Afrique de l'Ouest",
          'Afrique du Nord',
          'Afrique centrale',
          "Afrique de l'Est",
          'Afrique australe',
          'Europe',
          'Amérique du Nord',
          'Amérique latine',
          'Caraïbes',
          "Asie de l'Est",
          'Asie du Sud',
          'Asie du Sud-Est',
        ]),
      );
    });

    test('les régions : une donnée propre', () {
      final vues = <String>{};
      for (final g in kRegionsCulinaires) {
        expect(g.cuisines, isNotEmpty, reason: g.nom);
        for (final nom in [g.nom, ...g.cuisines]) {
          // Chaque nom une seule fois (une cuisine n'a qu'une grande
          // région), apostrophes droites, pas d'espace fine.
          expect(vues.add(motsDe(nom).join(' ')), isTrue, reason: nom);
          expect(nom.contains('’') || nom.contains(' '), isFalse);
          expect(nom.trim(), nom);
        }
      }
      // Les anciennes régions sont relues sous leur nouveau nom.
      final r = Recette.depuisJson({
        'id': 'r',
        'nom': 'Thiéboudienne',
        'region': 'Ouest-africaine',
      })!;
      expect(r.region, "Afrique de l'Ouest");
    });

    test('le tri', () {
      expect(
        trierRecettes(livre, TriRecettes.recentes).first.id,
        'depart-omelette',
      );
      expect(
        trierRecettes(livre, TriRecettes.alphabetique).first.id,
        'depart-bol-poulet',
      );
      expect(
        trierRecettes(livre, TriRecettes.proteines).first.id,
        'depart-bol-poulet',
      );
      expect(
        trierRecettes(livre, TriRecettes.rapides).first.id,
        'depart-smoothie',
      );
      final calories = trierRecettes(livre, TriRecettes.calories);
      expect(
        calories.first.parPortion.kcal,
        lessThanOrEqualTo(calories.last.parPortion.kcal),
      );
    });

    test('les recettes de départ : des valeurs du FCÉN plausibles', () {
      for (final r in GraineRecettes.depart(_auj)) {
        final p = r.parPortion;
        expect(p.kcal, inInclusiveRange(150, 700), reason: r.nom);
        // 4 kcal / g de protéines et de glucides, 9 de lipides : à 15 %.
        final estime = p.proteines * 4 + p.glucides * 4 + p.lipides * 9;
        expect((estime - p.kcal).abs() / p.kcal, lessThan(0.15), reason: r.nom);
        expect(r.etapes, isNotEmpty, reason: r.nom);
      }
    });
  });

  group("l'état", () {
    ProviderContainer conteneur(Depot? depot) {
      final c = ProviderContainer(
        overrides: [
          aujourdhuiProvider.overrideWithValue(_auj),
          horlogeProvider.overrideWithValue(() => _auj),
          if (depot != null) depotProvider.overrideWithValue(depot),
        ],
      );
      addTearDown(c.dispose);
      return c;
    }

    test('la démonstration : huit recettes, une semaine prévue', () {
      final c = conteneur(null);
      final e = c.read(recettesProvider);
      expect(e.recettes, hasLength(8));
      expect(e.plan, hasLength(13));
      // Le souper d'aujourd'hui reste « À planifier » (la maquette).
      expect(e.prevusLe(_auj, MomentRepas.souper), isEmpty);
      expect(e.recette('depart-chili')!.cuisinee, hasLength(2));
    });

    test('cuisiner : journal, restes, garde-manger décompté', () {
      final depot = Depot.memoire();
      addTearDown(depot.fermer);
      final c = conteneur(depot);
      final n = c.read(recettesProvider.notifier);
      expect(c.read(recettesProvider).recettes, isEmpty);
      expect(n.ajouterRecettesDeDepart(), 8);
      expect(n.ajouterRecettesDeDepart(), 0);
      final chili = c.read(recettesProvider).recette('depart-chili')!;

      final courses = c.read(coursesProvider.notifier);
      courses.ranger([
        _gm('oignons', 'Oignons', quantite: const Quantite(3)),
        _gm('mais', 'Maïs en grains surgelé', ou: Emplacement.congelateur),
      ]);
      final decomptes = decompteGardeManger(
        chili.ingredients,
        c.read(coursesProvider).gardeManger,
      );
      expect(decomptes.map((d) => d.article.id), ['oignons', 'mais']);

      final e = n.cuisiner(
        recette: chili,
        portions: 4,
        mangees: 1,
        moment: MomentRepas.souper,
        restesA: Emplacement.frigo,
        nomRestes: 'Chili sin carne (restes)',
        decomptes: decomptes,
      )!;
      // Au journal : une portion, sa valeur par portion.
      expect(e.source, SourceEntree.recette);
      expect(e.recetteId, 'depart-chili');
      expect(e.portions, 1);
      expect(e.nutriments.kcal, closeTo(chili.parPortion.kcal, 0.01));
      expect(c.read(alimentationProvider).entreesDu(_auj), hasLength(1));
      // Les restes : trois portions au frigo, 3 jours.
      final gm = c.read(coursesProvider).gardeManger;
      final restes = gm.firstWhere((a) => a.restes);
      expect(restes.quantite, const Quantite(3));
      expect(restes.recetteId, 'depart-chili');
      expect(restes.peremption, DateTime(2026, 9, 27));
      // Le garde-manger décompté : 2 oignons ; le maïs (sans quantité) fini.
      expect(
        gm.firstWhere((a) => a.id == 'oignons').quantite,
        const Quantite(2),
      );
      expect(gm.any((a) => a.id == 'mais'), isFalse);
      expect(c.read(recettesProvider).recette('depart-chili')!.cuisinee, [
        DateTime(2026, 9, 24),
      ]);

      // Manger les restes : 1, puis 2 (il n'en reste plus).
      n.noter(
        recette: chili,
        portions: 1,
        jour: _auj,
        moment: MomentRepas.diner,
        depuisRestes: true,
      );
      expect(
        portionsEnRestes(c.read(coursesProvider).gardeManger, chili.id),
        2,
      );
      n.noter(
        recette: chili,
        portions: 2,
        jour: _auj,
        moment: MomentRepas.souper,
        depuisRestes: true,
      );
      expect(c.read(coursesProvider).gardeManger.any((a) => a.restes), isFalse);

      // Relu depuis le dépôt.
      final relu = EtatRecettes.depuisDocument(depot.lire()!);
      expect(relu.recettes, hasLength(8));
      expect(relu.recette('depart-chili')!.cuisinee, hasLength(1));
      expect(
        relu.recette('depart-chili')!.parPortion.kcal,
        closeTo(chili.parPortion.kcal, 0.5),
      );
    });

    test('planifier, déplacer, retirer ; supprimer une recette', () {
      final depot = Depot.memoire();
      addTearDown(depot.fermer);
      final c = conteneur(depot);
      final n = c.read(recettesProvider.notifier);
      n.ajouterRecettesDeDepart();
      n.modifierReglages(const ReglagesRecettes(personnes: 2));
      final p = n.planifier(
        jour: DateTime(2026, 9, 26, 14),
        moment: MomentRepas.souper,
        recetteId: 'depart-chili',
      );
      expect(p.jour, DateTime(2026, 9, 26));
      expect(p.portions, 2);
      n.modifierPrevu(p.copierAvec(moment: MomentRepas.diner));
      expect(
        c.read(recettesProvider).prevusLe(DateTime(2026, 9, 26)).single.moment,
        MomentRepas.diner,
      );
      n.planifier(
        jour: _auj,
        moment: MomentRepas.collation,
        libre: 'Souper chez des amis',
      );
      expect(EtatRecettes.depuisDocument(depot.lire()!).plan, hasLength(2));
      n.supprimer('depart-chili');
      final e = c.read(recettesProvider);
      expect(e.recette('depart-chili'), isNull);
      expect(e.plan.single.libre, 'Souper chez des amis');
      n.retirerPrevu(e.plan.single.id);
      expect(c.read(recettesProvider).plan, isEmpty);
    });

    test('À la liste : fusionné, avec ses origines', () {
      final c = conteneur(null);
      final courses = c.read(coursesProvider.notifier);
      final avant = c.read(coursesProvider).liste.length;
      courses.ajouterBesoins([
        ('Oignons', Rayon.legumes, const [Quantite(2)], ['Chili', 'Pâté']),
        ('Coriandre', Rayon.legumes, const [], ['Chili']),
      ]);
      final liste = c.read(coursesProvider).liste;
      // Les oignons étaient déjà sur la liste (3, pour : chili) : fusionnés.
      final oignons = liste.firstWhere((a) => a.nom == 'Oignons');
      expect(oignons.quantites, const [Quantite(5)]);
      expect(oignons.origines, containsAll(['Chili', 'Pâté']));
      expect(liste.length, avant + 1);
    });

    test('les minuteurs', () {
      final c = conteneur(null);
      final n = c.read(minuteursProvider.notifier);
      final m = n.demarrer('Riz', const Duration(minutes: 18));
      expect(m.fin, _auj.add(const Duration(minutes: 18)));
      n.ajouterMinute(m.id);
      expect(
        c.read(minuteursProvider).single.fin,
        _auj.add(const Duration(minutes: 19)),
      );
      n.sonner(m.id);
      expect(c.read(minuteursProvider).single.sonne, isTrue);
      n.arreter(m.id);
      expect(c.read(minuteursProvider), isEmpty);
    });
  });

  group('le JSON tolérant', () {
    test('ce qui est abîmé est sauté, jamais l\'app', () {
      final e = EtatRecettes.depuisDocument({
        'versionRecettes': 1,
        'recettesAlim': [
          'n\'importe quoi',
          {'id': 'a'},
          {
            'id': 'b',
            'nom': 'Soupe',
            'portions': -2,
            'moments': ['souper', 'minuit'],
            'ingredients': [
              {'nom': 'Pois', 'source': 'base', 'g': 200, 'nut': 'x'},
              {'source': 'libre'},
            ],
            'etapes': ['Cuire 2 heures', 3, ''],
            'prep': 0,
            'cuisinee': [20260920, 'hier'],
          },
        ],
        'planAlim': [
          {'id': 'p', 'jour': 20260925, 'moment': 'souper'},
          {'id': 'q', 'jour': 20260925, 'moment': 'souper', 'recette': 'b'},
        ],
        'reglagesRecettes': {'personnes': 99, 'heure': 5000, 'tri': 'x'},
      });
      final r = e.recettes.single;
      expect(r.portions, 4);
      expect(r.moments, {MomentRepas.souper});
      expect(r.ingredients.single.nom, 'Pois');
      expect(r.ingredients.single.nutriments, Nutriments.zero);
      expect(r.etapes, ['Cuire 2 heures']);
      expect(r.preparation, isNull);
      expect(r.cuisinee, [DateTime(2026, 9, 20)]);
      // Un repas prévu sans plat est sauté.
      expect(e.plan.single.id, 'q');
      expect(e.reglages.personnes, 1);
      expect(e.reglages.heureDecongelation, 20 * 60);
      expect(e.reglages.tri, TriRecettes.recentes);
    });

    test('aller-retour', () {
      final e = GraineRecettes.demonstration(_auj);
      final relu = EtatRecettes.depuisDocument(e.versDocument());
      expect(relu.recettes.length, e.recettes.length);
      expect(relu.plan.length, e.plan.length);
      final a = e.recette('depart-pate-chinois')!;
      final b = relu.recette('depart-pate-chinois')!;
      expect(b.region, 'Québécoise');
      expect(b.seCongele, isTrue);
      expect(b.etapes, a.etapes);
      expect(b.ingredients.length, a.ingredients.length);
      expect(b.parPortion.kcal, closeTo(a.parPortion.kcal, 0.5));
      // Une entrée de recette au journal garde sa recette.
      final entree = EntreeJournal.depuisJson(
        entreeDeRecette(
          id: 'e',
          recette: a,
          portions: 1.5,
          jour: _auj,
          moment: MomentRepas.souper,
          ajoutee: _auj,
        ).versJson(),
      )!;
      expect(entree.source, SourceEntree.recette);
      expect(entree.recetteId, a.id);
      expect(entree.cleSource, 'recette:${a.id}');
      // Des restes au garde-manger gardent leur recette.
      final gm = ArticleGardeManger.depuisJson(
        _gm('r', 'Restes', recette: a.id).versJson(),
      )!;
      expect(gm.recetteId, a.id);
      expect(gm.restes, isTrue);
    });
  });

  group('les rappels et le conseil du soir', () {
    late AppLocalizations tr;
    setUpAll(() async {
      tr = await AppLocalizations.delegate.load(const Locale('fr'));
    });

    test('la décongélation, la veille à 20 h', () {
      final recettes = GraineRecettes.demonstration(_auj);
      final gm = GraineCourses.demonstration(_auj).gardeManger;
      final n = notificationsDecongelation(
        recettes: recettes,
        gardeManger: gm,
        maintenant: _auj,
        tr: tr,
      );
      // Demain, le pâté chinois : le bœuf haché est au congélateur.
      final ce = n.firstWhere((x) => x.quand == DateTime(2026, 9, 24, 20));
      expect(ce.corps, contains('bœuf haché maigre'));
      expect(ce.corps, contains('pâté chinois'));
      expect(
        notificationsDecongelation(
          recettes: recettes,
          gardeManger: gm,
          maintenant: _auj,
          tr: tr,
          actifs: false,
        ),
        isEmpty,
      );
      expect(
        notificationsDecongelation(
          recettes: recettes.copierAvec(
            reglages: const ReglagesRecettes(rappelsDecongelation: false),
          ),
          gardeManger: gm,
          maintenant: _auj,
          tr: tr,
        ),
        isEmpty,
      );
    });

    test('les minuteurs deviennent des notifications', () {
      final n = notificationsMinuteurs(
        minuteurs: [
          MinuteurCuisine(
            id: 'a',
            libelle: 'Riz',
            fin: _auj.add(const Duration(minutes: 18)),
            duree: const Duration(minutes: 18),
          ),
          MinuteurCuisine(
            id: 'b',
            libelle: 'Fini',
            fin: _auj.subtract(const Duration(minutes: 1)),
            duree: const Duration(minutes: 1),
          ),
        ],
        maintenant: _auj,
        tr: tr,
      );
      expect(n.single.corps, 'Riz');
      expect(n.single.id, idMinuteur('a'));
    });

    test('le soir, ce qui doit décongeler passe en premier', () {
      const besoins = Besoins(
        metabolisme: 1700,
        activite: 340,
        sport: 0,
        objectif: 0,
        ajustement: Ajustement(etat: EtatAjustement.desactive),
        kcal: 2200,
        proteines: 150,
        glucides: 260,
        lipides: 70,
        verres: 8,
        poids: 75,
        estimation: false,
        manuel: true,
        jourDeSeance: false,
      );
      Conseil a(int h) => conseilDuJour(
        besoins: besoins,
        total: const Nutriments(kcal: 1200, proteines: 80),
        entrees: 4,
        verres: 6,
        seanceFaite: false,
        profilComplet: true,
        objectif: ObjectifPoids.maintenir,
        maintenant: DateTime(2026, 9, 24, h),
        aConsommer: const ['Épinards'],
        aDecongeler: const ['Bœuf haché maigre'],
      );
      expect(a(18).genre, GenreConseil.decongeler);
      expect(a(18).noms, 'bœuf haché maigre');
      expect(a(10).genre, GenreConseil.peremption);
    });
  });
}
