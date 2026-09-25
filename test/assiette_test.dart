// test/assiette_test.dart
//
// L'assiette du Guide alimentaire canadien (lot 5 de l'Alimentation) : le
// rangement des aliments du FCÉN (la vraie base), le poids cuit des grains
// secs, une journée (base, produit, recette répartie ingrédient par
// ingrédient, entrée rapide non répartie), les conseils, la démonstration.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/modele/alimentation/alimentation.dart';
import 'package:rhythm/modele/alimentation/assiette.dart';
import 'package:rhythm/modele/alimentation/base_aliments.dart';
import 'package:rhythm/modele/alimentation/etat_alimentation.dart';
import 'package:rhythm/modele/alimentation/etat_recettes.dart';
import 'package:rhythm/modele/alimentation/nutriments.dart';
import 'package:rhythm/modele/alimentation/recettes.dart';
import 'package:rhythm/modele/modeles.dart';
import 'package:rhythm/utils/dates.dart';

final DateTime _auj = DateTime(2026, 9, 24, 8);

void main() {
  late BaseAliments base;
  setUpAll(() {
    base = BaseAliments.analyser(
      File('assets/donnees/fcen.txt').readAsStringSync(),
    );
  });

  CategorieAssiette cat(int code) {
    final a = base.parCode(code)!;
    return categorieDe(a.groupe, a.nom);
  }

  var n = 0;
  EntreeJournal entree(
    String nom, {
    SourceEntree source = SourceEntree.base,
    int? code,
    double? grammes,
    String? produit,
    String? recette,
    double? portions,
    double kcal = 100,
  }) => EntreeJournal(
    id: 'e${++n}',
    jour: jourDe(_auj),
    moment: MomentRepas.diner,
    nom: nom,
    source: source,
    code: code,
    produitId: produit,
    recetteId: recette,
    grammes: grammes,
    portions: portions,
    nutriments: Nutriments(kcal: kcal),
    ajoutee: _auj,
  );

  Assiette assiette(
    List<EntreeJournal> entrees, {
    List<Produit> produits = const [],
    List<Recette> recettes = const [],
  }) => assietteDe(entrees, base: base, produits: produits, recettes: recettes);

  group('ranger un aliment', () {
    test('les parts, hors de l\'assiette, non réparti', () {
      expect(cat(1704), CategorieAssiette.legumesFruits); // banane
      expect(cat(2374), CategorieAssiette.legumesFruits); // brocoli
      expect(cat(842), CategorieAssiette.proteines); // poulet
      expect(cat(6289), CategorieAssiette.proteines); // beurre d'arachide
      expect(cat(4497), CategorieAssiette.grains); // riz brun
      expect(cat(3906), CategorieAssiette.grains); // muffin anglais
      expect(cat(3882), CategorieAssiette.aLimiter); // croissant
      expect(cat(5288), CategorieAssiette.aLimiter); // cola
      expect(cat(61), CategorieAssiette.neutre); // lait à boire
      expect(cat(422), CategorieAssiette.neutre); // huile
      expect(cat(4962), CategorieAssiette.nonReparti); // pizza (plat)
    });

    test('grains entiers ; le sec compte cuit', () {
      expect(grainEntier(base.parCode(4497)!.nom), isTrue); // riz brun
      expect(grainEntier(base.parCode(4523)!.nom), isFalse); // riz blanc
      expect(grainEntier(base.parCode(1414)!.nom), isTrue); // gruau
      final sec = base.parCode(4471)!; // riz blanc sec
      expect(grammesAssiette(sec.groupe, sec.nom, 60), 150);
      final cuit = base.parCode(4523)!;
      expect(grammesAssiette(cuit.groupe, cuit.nom, 150), 150);
      final haricots = base.parCode(3376)!; // haricots noirs secs
      expect(grammesAssiette(haricots.groupe, haricots.nom, 100), 250);
    });
  });

  group('une journée', () {
    test('base, produit, recette répartie, entrée rapide', () {
      final bol = Recette(
        id: 'bol',
        nom: 'Bol poulet',
        creee: DateTime(2026),
        portions: 2,
        ingredients: [
          Ingredient(
            nom: 'Poulet',
            source: SourceIngredient.base,
            code: 842,
            grammes: 240,
          ),
          Ingredient(
            nom: 'Riz blanc',
            source: SourceIngredient.base,
            code: 4471,
            grammes: 120,
          ),
          Ingredient(
            nom: 'Brocoli',
            source: SourceIngredient.base,
            code: 2374,
            grammes: 300,
          ),
          Ingredient(
            nom: 'Huile',
            source: SourceIngredient.base,
            code: 422,
            grammes: 20,
          ),
          Ingredient(nom: 'Sel'),
        ],
      );
      const yogourt = Produit(
        id: 'yog',
        nom: 'Yogourt grec nature 2 %',
        portion: '175 g',
        grammesPortion: 175,
        parPortion: Nutriments(kcal: 145),
      );
      final a = assiette(
        [
          entree('Banane', code: 1704, grammes: 118),
          entree('Carotte', code: 2380, grammes: 82),
          entree(
            'Yogourt grec',
            source: SourceEntree.produit,
            produit: 'yog',
            portions: 1,
          ),
          entree(
            'Bol poulet',
            source: SourceEntree.recette,
            recette: 'bol',
            portions: 1,
          ),
          entree('Poutine', source: SourceEntree.rapide),
        ],
        produits: [yogourt],
        recettes: [bol],
      );
      // La moitié du bol : 120 g de poulet, 60 g de riz sec (150 cuit),
      // 150 g de brocoli ; l'huile ne compte pas, le sel est libre.
      expect(a.grammesDe(CategorieAssiette.legumesFruits), 118 + 82 + 150);
      expect(a.grammesDe(CategorieAssiette.proteines), 175 + 120);
      expect(a.grammesDe(CategorieAssiette.grains), 150);
      expect(a.grammesDe(CategorieAssiette.neutre), 10);
      expect(a.nonReparties, 1);
      expect(a.partEntiers, 0);
      final riz = a.elements.firstWhere((e) => e.nom == 'Riz blanc');
      expect(riz.recette, 'Bol poulet');
      expect(a.total, 795);
      expect(
        a.partDe(CategorieAssiette.legumesFruits),
        closeTo(350 / 795, 1e-9),
      );
    });

    test('une recette sans portions se répartit selon les calories', () {
      final r = Recette(
        id: 'r',
        nom: 'Salade',
        creee: DateTime(2026),
        portions: 4,
        ingredients: [
          Ingredient(
            nom: 'Carotte',
            source: SourceIngredient.base,
            code: 2380,
            grammes: 400,
            nutriments: Nutriments(kcal: 164),
          ),
        ],
      );
      final a = assiette(
        [
          entree(
            'Salade',
            source: SourceEntree.recette,
            recette: 'r',
            kcal: 41,
          ),
        ],
        recettes: [r],
      );
      expect(a.grammesDe(CategorieAssiette.legumesFruits), closeTo(100, 1e-9));
      // Une recette effacée : non répartie.
      final b = assiette([
        entree('Disparue', source: SourceEntree.recette, recette: 'x'),
      ]);
      expect(b.nonReparties, 1);
    });
  });

  group('les conseils', () {
    Assiette de(Map<CategorieAssiette, double> g, {bool entiers = true}) =>
        Assiette([
          for (final e in g.entries)
            ElementAssiette(
              nom: e.key.name,
              categorie: e.key,
              grammes: e.value,
              entier: entiers,
            ),
        ]);

    test('équilibrée, puis ce qui manque le plus', () {
      expect(
        de({
          CategorieAssiette.legumesFruits: 400,
          CategorieAssiette.proteines: 200,
          CategorieAssiette.grains: 200,
        }).conseil,
        ConseilAssiette.equilibree,
      );
      expect(
        de({
          CategorieAssiette.legumesFruits: 200,
          CategorieAssiette.proteines: 300,
          CategorieAssiette.grains: 300,
        }).conseil,
        ConseilAssiette.plusDeLegumesFruits,
      );
      expect(
        de({
          CategorieAssiette.legumesFruits: 500,
          CategorieAssiette.proteines: 60,
          CategorieAssiette.grains: 240,
        }).conseil,
        ConseilAssiette.plusDeProteines,
      );
      expect(
        de({
          CategorieAssiette.legumesFruits: 500,
          CategorieAssiette.proteines: 300,
        }).conseil,
        ConseilAssiette.plusDeGrains,
      );
    });

    test('à limiter, grains entiers, trop peu', () {
      expect(
        de({
          CategorieAssiette.legumesFruits: 400,
          CategorieAssiette.proteines: 200,
          CategorieAssiette.grains: 200,
          CategorieAssiette.aLimiter: 400,
        }).conseil,
        ConseilAssiette.moinsALimiter,
      );
      expect(
        de({
          CategorieAssiette.legumesFruits: 400,
          CategorieAssiette.proteines: 200,
          CategorieAssiette.grains: 200,
        }, entiers: false).conseil,
        ConseilAssiette.grainsEntiers,
      );
      expect(
        de({CategorieAssiette.legumesFruits: 60}).conseil,
        ConseilAssiette.vide,
      );
    });
  });

  test('la démonstration : il manque des légumes et des fruits', () {
    final etat = GraineAlimentation.demonstration(_auj);
    final recettes = GraineRecettes.demonstration(_auj);
    final a = assiette(
      etat.entreesDu(_auj),
      produits: etat.produits,
      recettes: recettes.recettes,
    );
    expect(a.lisible, isTrue);
    expect(a.nonReparties, 1); // le bol, en entrée rapide
    expect(a.partEntiers, 1); // le gruau
    expect(a.conseil, ConseilAssiette.plusDeLegumesFruits);
  });
}
