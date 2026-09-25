// test/ia_test.dart
//
// L'ASSISTANT de l'Alimentation (palier 4), sans réseau : les textes de
// l'IA nettoyés (typographie française, glyphes des polices) ; la
// CORRESPONDANCE avec la vraie base du FCÉN (l'aliment, la quantité, les
// calories vraisemblables) ; la lecture TOLÉRANTE et VÉRIFIÉE des réponses
// (recettes, semaine, écart, estimation, remplaçants, conservation, bilan) ;
// les invites (ce qui part — et ce qui ne part pas) ; le bilan de la
// semaine ; les repères de conservation appris, gardés au dépôt.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/ia/ia_alimentation.dart';
import 'package:rhythm/ia/service_ia.dart';
import 'package:rhythm/ia/texte_ia.dart';
import 'package:rhythm/modele/alimentation/alimentation.dart';
import 'package:rhythm/modele/alimentation/base_aliments.dart';
import 'package:rhythm/modele/alimentation/bilan_semaine.dart';
import 'package:rhythm/modele/alimentation/calculs_recettes.dart';
import 'package:rhythm/modele/alimentation/conservation.dart';
import 'package:rhythm/modele/alimentation/correspondance.dart';
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
import 'package:rhythm/modele/sports/etat_sport.dart';
import 'package:rhythm/utils/dates.dart';

const _n = ' ';
final DateTime _auj = DateTime(2026, 9, 24, 17, 30);
final BaseAliments _base = BaseAliments.analyser(
  File('assets/donnees/fcen.txt').readAsStringSync(),
);

IngredientPropose _p(Map<String, Object?> j) =>
    IngredientPropose.depuisJson(j)!;

Correspondance _c(Map<String, Object?> j) => correspondre(_p(j), _base);

/// Le vrai réseau (celui du faux Groq local), quoi que fasse l'outil de test.
class _ReseauReel extends HttpOverrides {}

void main() {
  group('les textes de l\'IA', () {
    test('typographie française et glyphes des polices', () {
      expect(texteIa('Bon appétit !'), 'Bon appétit$_n!');
      expect(
        texteIa('Pourquoi ? Parce que : voilà ; ok'),
        'Pourquoi$_n? Parce que$_n: voilà$_n; ok',
      );
      expect(
        texteIa('Cuire 20 minutes à 190 °C'),
        'Cuire 20${_n}minutes à 190$_n°C',
      );
      expect(texteIa('Ajouter 250 ml de lait'), 'Ajouter 250${_n}ml de lait');
      expect(texteIa('« Miam »'), '«${_n}Miam$_n»');
      expect(texteIa('“Miam”'), '«${_n}Miam$_n»');
      // U+202F (absente des polices) → U+00A0.
      expect(texteIa('Prêt !'), 'Prêt$_n!');
      expect(texteIa('≈ 30 g'), 'env. 30${_n}g');
      expect(texteIa('≈ 30 g', francais: false), 'about 30 g');
      expect(texteIa('C’est **bon** 🍲'), "C'est bon");
      expect(texteIa('- un\n- deux'), '• un\n• deux');
      // Pas d'insécable dans une heure ni une adresse.
      expect(texteIa('à 18:30'), 'à 18:30');
      expect(texteIa(42), '');
    });

    test('les étapes : numéros retirés, minuteurs toujours repérés', () {
      final e = textesIa([
        '1. Couper les oignons.',
        'Étape 2 : Cuire 20 minutes.',
        '',
        3,
      ]);
      expect(e, ['Couper les oignons.', 'Cuire 20${_n}minutes.']);
      expect(minuteursDans(e[1]).single.duree, const Duration(minutes: 20));
    });
  });

  group('la correspondance avec la base du FCÉN', () {
    test('les unités de cuisine deviennent des ml ou des g', () {
      expect(
        _p({'nom': 'Huile', 'quantite': 2, 'unite': 'c. à soupe'}).quantite,
        30,
      );
      expect(
        _p({'nom': 'Lait', 'quantite': 1, 'unite': 'tasse'}).quantite,
        250,
      );
      expect(
        _p({'nom': 'Farine', 'quantite': '0,5', 'unite': 'kg'}).quantite,
        500,
      );
      expect(
        _p({'nom': 'Eau', 'quantite': 1.5, 'unite': 'L'}).unite,
        UniteProposee.ml,
      );
      expect(IngredientPropose.depuisJson({'quantite': 2}), isNull);
      expect(IngredientPropose.depuisJson('oignon'), isNull);
    });

    test('un aliment compté prend la portion du FCÉN', () {
      final c = _c({
        'nom': 'Oignon',
        'quantite': 1,
        'unite': 'unite',
        'taille': 'gros',
        'grammes': 150,
        'kcal': 60,
        'fcen': 'oignon cru',
      });
      expect(c.aliment!.code, 2401);
      expect(c.ingredient.mesure, '1 gros');
      expect(c.ingredient.nombre, 1);
      expect(c.ingredient.grammes, 150);
      expect(c.ingredient.nutriments.kcal, closeTo(60, 1));
      expect(c.horsBase, isFalse);
    });

    test('un volume prend la densité de la base', () {
      final riz = _c({
        'nom': 'Riz blanc',
        'quantite': 375,
        'unite': 'ml',
        'grammes': 300,
        'kcal': 1080,
        'fcen': 'riz blanc grain long cru',
      });
      expect(riz.ingredient.mesure, '250 ml');
      expect(riz.ingredient.nombre, 1.5);
      expect(riz.aliment!.nom, contains('riz blanc'));
      expect(riz.nutriments.kcal, greaterThan(900));
      expect(quantiteDe(riz.ingredient), const Quantite(375, Unite.ml));
      // Sans portion « en quarts » : « 1 × 100 ml ».
      final coco = _c({
        'nom': 'Lait de coco',
        'quantite': 100,
        'unite': 'ml',
        'grammes': 100,
        'kcal': 190,
        'fcen': 'lait de coco conserve',
      });
      expect(quantiteDe(coco.ingredient), const Quantite(100, Unite.ml));
    });

    test('les calories estimées départagent les aliments de la base', () {
      // « bouillon » : le prêt-à-servir, pas le déshydraté.
      final b = _c({
        'nom': 'Bouillon de poulet',
        'quantite': 500,
        'unite': 'ml',
        'grammes': 500,
        'kcal': 30,
        'fcen': 'bouillon poulet',
      });
      expect(b.nutriments.kcal, lessThan(80));
      expect(b.aliment!.nom.toLowerCase(), contains('bouillon'));
      // Les crevettes crues, pas bouillies.
      final cr = _c({
        'nom': 'Crevettes',
        'quantite': 400,
        'unite': 'g',
        'kcal': 340,
        'fcen': 'crevettes crues',
      });
      expect(cr.aliment!.nom, contains('crue'));
      // Ce qu'est l'aliment compte plus que son état : des haricots NOIRS.
      final h = _c({
        'nom': 'Haricots noirs',
        'quantite': 540,
        'unite': 'ml',
        'kcal': 360,
        'fcen': 'haricots noirs conserve',
      });
      expect(h.aliment!.nom, startsWith('Haricots, noirs'));
    });

    test('les pièges vus sur le vrai Groq', () {
      // « pois » n'est pas « poisson », même quand l'IA sous-estime les
      // calories (170 pour 2 tasses de pois secs : 1 500 dans la base).
      final pois = _c({
        'nom': 'Pois jaunes secs',
        'quantite': 500,
        'unite': 'ml',
        'grammes': 400,
        'kcal': 170,
        'fcen': 'pois jaunes secs',
      });
      expect(pois.aliment!.nom, startsWith('Pois, cassés'));
      // Le riz d'une recette est cru (« sec » dans le FCÉN), pas cuit.
      final riz = _c({
        'nom': 'Riz basmati',
        'quantite': 120,
        'unite': 'g',
        'kcal': 360,
        'fcen': 'riz basmati cru',
      });
      expect(riz.aliment!.nom, contains('riz blanc'));
      expect(riz.aliment!.nom, endsWith('sec'));
      // Un oignon moyen n'est pas « 1 tranche moyenne » ; sans taille, un
      // oignon entier.
      Correspondance oignon(Map<String, Object?> plus) => _c({
        'nom': 'Oignon haché',
        'quantite': 1,
        'unite': 'unite',
        'grammes': 110,
        'kcal': 44,
        'fcen': 'oignon cru',
        ...plus,
      });
      final moyen = oignon({'taille': 'moyen'});
      expect(moyen.aliment!.code, 2401);
      expect(moyen.ingredient.mesure, '1 moyen');
      expect(moyen.ingredient.grammes, 110);
      expect(oignon({}).ingredient.mesure, '1 gros');
      // Un mot que le FCÉN écrit autrement ; un mot inconnu ne laisse pas
      // la place à un autre aliment (« Tomate, poudre »).
      final cari = _c({
        'nom': 'Curry en poudre',
        'quantite': 5,
        'unite': 'ml',
        'grammes': 2,
        'kcal': 10,
        'fcen': 'curry poudre',
      });
      expect(cari.aliment!.nom, 'Épices, cari, poudre');
      expect(
        _c({
          'nom': 'Zzqwx en poudre',
          'quantite': 5,
          'unite': 'ml',
          'fcen': 'zzqwx poudre',
        }).horsBase,
        isTrue,
      );
      // L'eau, même oubliée par l'IA, est libre (pas une eau aromatisée).
      final eau = _c({
        'nom': 'Eau bouillante',
        'quantite': 250,
        'unite': 'ml',
        'fcen': 'eau',
      });
      expect(eau.ingredient.libre, isTrue);
      expect(eau.horsBase, isFalse);
      expect(_p({'nom': 'Eau de coco', 'fcen': 'eau coco'}).libre, isFalse);
      // La poitrine crue sans la peau, pas la charcuterie ni la peau.
      final poulet = _c({
        'nom': 'Poitrines de poulet',
        'quantite': 600,
        'unite': 'g',
        'kcal': 720,
        'fcen': 'poulet poitrine crue',
      });
      expect(poulet.aliment!.code, 841);
      // Des pâtes sèches ordinaires, pas de maïs.
      final pates = _c({
        'nom': 'Pâtes',
        'quantite': 350,
        'unite': 'g',
        'kcal': 1260,
        'fcen': 'pâtes alimentaires sèches',
      });
      expect(pates.aliment!.nom, startsWith('Pâtes (spaghetti'));
      // Une quantité pas convertie (« 2 » ml pour 2 tasses) : le poids
      // estimé fait foi.
      final brut = _c({
        'nom': 'Pois jaunes secs',
        'quantite': 2,
        'unite': 'ml',
        'grammes': 400,
        'kcal': 1400,
        'fcen': 'pois cassés secs',
      });
      expect(brut.ingredient.grammes, 400);
      expect(brut.nutriments.kcal, greaterThan(1200));
    });

    test('pâte, pâtes et pâté ; ce qu\'un aliment a « avec » ou « sans »', () {
      Correspondance c(String nom, num q, String unite, num kcal, String f) =>
          _c({
            'nom': nom,
            'quantite': q,
            'unite': unite,
            'grammes': q,
            'kcal': kcal,
            'fcen': f,
          });
      expect(
        c(
          "Pâte d'arachide",
          200,
          'g',
          1120,
          "beurre d'arachide naturel",
        ).aliment!.nom,
        startsWith("Beurre d'arachides"),
      );
      expect(
        c('Pâte de tomate', 30, 'ml', 25, 'pâte de tomate').aliment!.nom,
        contains('tomates'),
      );
      // Ce que la base n'a pas reste hors de la base : ni pâte d'amandes,
      // ni pâté, ni spaghetti.
      expect(
        c('Pâte à pizza', 200, 'g', 520, 'pâte à pizza crue').horsBase,
        isTrue,
      );
      expect(
        c('Pâte de curry rouge', 15, 'ml', 15, 'pâte de curry').horsBase,
        isTrue,
      );
      // Des tomates en conserve, pas « avec piments verts ».
      expect(
        c(
          'Tomates concassées en conserve',
          400,
          'ml',
          80,
          'tomates conserve',
        ).aliment!.nom,
        isNot(contains('piments')),
      );
      expect(
        c('Courge butternut', 300, 'g', 120, 'courge crue').aliment!.nom,
        contains('musquée'),
      );
      // Le bouillon de POISSON, pas celui de boeuf « prêt à servir ».
      expect(
        c(
          'Bouillon de poisson prêt à servir',
          500,
          'ml',
          30,
          'bouillon poisson prêt à servir',
        ).aliment!.nom,
        contains('poisson'),
      );
      // Un plat courant reste entier (l'estimation d'un repas).
      expect(c('Poutine', 650, 'g', 1400, 'poutine').aliment!.nom, 'Poutine');
    });

    test('le balayage : les confusions corrigées ne reviennent pas', () {
      String nom(String n, num q, String unite, num kcal, String f) =>
          _c({
            'nom': n,
            'quantite': q,
            'unite': unite,
            'grammes': q,
            'kcal': kcal,
            'fcen': f,
          }).aliment?.nom ??
          'HORS BASE';
      // Un mot entier, pas son début : du vin, pas du vinaigre.
      expect(nom('Vin rouge', 150, 'ml', 125, 'vin rouge'), contains('vin'));
      expect(
        nom('Vin rouge', 150, 'ml', 125, 'vin rouge'),
        isNot(contains('Vinaigre')),
      );
      // « Épices, … » : de la cannelle, pas une pomme cannelle.
      expect(
        nom('Cannelle', 5, 'ml', 6, 'cannelle moulue'),
        'Épices, cannelle, moulue',
      );
      // Ce qu'un aliment contient n'est pas ce qu'il est.
      expect(nom('Sauce soya', 30, 'ml', 20, 'sauce soya'), startsWith('Soya'));
      // La partie de la plante, seulement si on la demande.
      expect(
        nom('Betteraves', 250, 'g', 108, 'betterave crue'),
        'Betteraves, crues',
      );
      // « Sans peau », « non salé » : ce que la proposition ne veut pas.
      expect(
        nom('Hauts de cuisse', 600, 'g', 720, 'poulet cuisse sans peau crue'),
        'Poulet à griller, haut de cuisse, viande, cru',
      );
      expect(
        nom('Beurre non salé', 30, 'g', 215, 'beurre non salé'),
        'Beurre, sans sel',
      );
      // Sec n'est pas cru : des raisins secs.
      expect(
        nom('Raisins secs', 40, 'g', 130, 'raisins secs'),
        startsWith('Raisin sec'),
      );
      // « Écrémé » n'est pas « partiellement écrémé ».
      expect(
        nom('Lait écrémé', 250, 'ml', 90, 'lait écrémé'),
        'Lait, liquide, écrémé, 0.1% M.G.',
      );
      // Les mots d'ici.
      expect(
        nom('Haricots verts', 250, 'g', 78, 'haricots verts crus'),
        'Haricots italiens, jaunes ou verts, crus',
      );
      expect(nom('Chou vert', 500, 'g', 125, 'chou vert cru'), 'Chou, cru');
      // Un produit reste ce produit : de la confiture, pas des fraises.
      expect(
        nom('Confiture de fraises', 20, 'g', 50, 'confiture fraises'),
        startsWith('Confiseries, confitures'),
      );
      // Ce que la base n'a pas : hors de la base, pas un autre fromage.
      expect(
        nom('Mascarpone', 125, 'g', 540, 'fromage mascarpone'),
        'HORS BASE',
      );
      // L'eau, la poudre à pâte : libres.
      expect(_p({'nom': 'Poudre à pâte', 'quantite': 5}).libre, isTrue);
      // Vus sur le vrai Groq : l'huile d'olive (l'IA l'estimait à 40 kcal
      // les 15 ml), pas des anchois « avec huile d'olive ».
      expect(
        nom("Huile d'olive", 15, 'ml', 40, "huile d'olive"),
        'Huile végétale, olive',
      );
      // Une marque que les mots-clés expliquent.
      expect(nom('Pepsi', 355, 'ml', 150, 'boisson cola'), contains('cola'));
      expect(
        nom('Concentré de tomate', 30, 'ml', 30, 'concentré de tomate'),
        contains('pâte'),
      );
      expect(
        nom('Boeuf à braiser', 400, 'g', 800, 'boeuf à braiser cru'),
        contains('ragout'),
      );
      expect(
        nom('Tofu ferme', 400, 'g', 320, 'tofu ferme'),
        isNot(contains('soyeux')),
      );
    });

    test('le bilan : les verdicts calculés sur le téléphone', () {
      final b = BilanSemaine(
        debut: DateTime(2026, 9, 19),
        fin: DateTime(2026, 9, 25),
        joursNotes: 5,
        moyenne: const Nutriments(
          kcal: 1980,
          proteines: 96,
          fibres: 17,
          sodium: 2900,
        ),
        kcalVisees: 2200,
        proteinesVisees: 150,
        verresMoyens: 5.4,
        verresVises: 8,
        seances: 3,
        frequents: const [],
        jetes: const [],
      );
      final u = invitesBilan(b, objectif: ObjectifPoids.perdre).last.contenu;
      // Vu sur le vrai Groq : « tu as atteint tes objectifs de protéines »
      // pour 96 g sur 150 — le verdict est donné, pas à deviner.
      expect(u, contains("objectif 150 : 64 %, EN DESSOUS de l'objectif"));
      expect(u, contains('objectif 2200 : 90 %, atteint'));
      expect(u, contains('limite 2300 : 126 %, AU-DESSUS de la limite'));
      expect(u, contains('ne les contredis jamais'));
    });

    test('libre, introuvable, sans quantité', () {
      final sel = _c({'nom': 'Sel et poivre', 'libre': true});
      expect(sel.ingredient.libre, isTrue);
      expect(sel.horsBase, isFalse);
      final x = _c({
        'nom': 'Zzqwx',
        'quantite': 100,
        'unite': 'g',
        'fcen': 'zzqwx',
      });
      expect(x.horsBase, isTrue);
      expect(x.ingredient.libre, isTrue);
      expect(x.ingredient.quantite, const Quantite(100, Unite.g));
      // Une unité sans portion ni poids : on ne sait pas la chiffrer.
      final q = _c({'nom': 'Pomme', 'fcen': 'pomme crue'});
      expect(q.horsBase, isTrue);
    });

    test('une entrée du journal chiffrée par la base', () {
      final c = _c({
        'nom': 'Banane',
        'quantite': 1,
        'unite': 'unite',
        'grammes': 118,
        'kcal': 105,
        'fcen': 'banane crue',
      });
      final e = entreeDeCorrespondance(
        c,
        id: 'e1',
        jour: jourDe(_auj),
        moment: MomentRepas.collation,
        ajoutee: _auj,
      );
      expect(e.source, SourceEntree.base);
      expect(e.code, c.aliment!.code);
      expect(e.nutriments, c.nutriments);
      expect(e.portions, 1);
    });
  });

  group('les réponses lues et vérifiées', () {
    Map<String, dynamic> recette({
      String nom = 'Poulet yassa',
      Object? region = 'senegalaise',
      Object? moments = const ['souper'],
    }) => {
      'nom': nom,
      'description': 'Poulet au citron et aux oignons.',
      'region': region,
      'moments': moments,
      'portions': 4,
      'preparation': 20,
      'cuisson': 45,
      'congele': true,
      'ingredients': [
        {
          'nom': 'Poitrines de poulet',
          'quantite': 600,
          'unite': 'g',
          'kcal': 720,
          'fcen': 'poulet poitrine crue',
        },
        {
          'nom': 'Oignons',
          'quantite': 3,
          'unite': 'unite',
          'taille': 'gros',
          'grammes': 450,
          'kcal': 180,
          'fcen': 'oignon cru',
        },
        {'nom': 'Sel et poivre', 'libre': true},
        {'quantite': 3},
      ],
      'etapes': ['1. Mariner 2 heures.', 'Cuire 30 minutes.'],
    };

    test('une recette : région, moments, portions, macros par la base', () {
      final p = RecetteProposee.depuisJson(
        recette(),
        region: "Afrique de l'Ouest",
        moment: MomentRepas.diner,
      )!;
      expect(p.region, 'Sénégalaise');
      expect(p.moments, {MomentRepas.souper, MomentRepas.diner});
      expect(p.ingredients, hasLength(3));
      expect(p.etapes.first, 'Mariner 2${_n}heures.');
      final c = p.correspondances(_base);
      final r = p.versRecette(c, id: 'r1', creee: _auj);
      expect(r.seCongele, isTrue);
      expect(r.note, 'Poulet au citron et aux oignons.');
      expect(
        r.total.kcal,
        closeTo(Nutriments.somme(c.map((x) => x.nutriments)).kcal, 0.01),
      );
      expect(r.parPortion.proteines, greaterThan(25));
      // Hors de la région demandée : la région demandée.
      expect(
        RecetteProposee.depuisJson(
          recette(region: 'Italienne'),
          region: "Afrique de l'Ouest",
        )!.region,
        "Afrique de l'Ouest",
      );
      // Sans région demandée, une inconnue est oubliée.
      expect(
        RecetteProposee.depuisJson(recette(region: 'Fusion'))!.region,
        isNull,
      );
      expect(RecetteProposee.depuisJson({'nom': 'Rien'}), isNull);
    });

    test('les idées : les recettes illisibles sont sautées', () {
      final d = const DemandeIdees(region: 'Italienne');
      final l = lireIdees({
        'recettes': [
          recette(region: 'Italienne'),
          'rien',
          {'nom': ''},
        ],
      }, d);
      expect(l.single.region, 'Italienne');
      expect(lireIdees({'autre': 1}, d), isEmpty);
    });

    test('la semaine : seulement des cases libres, des recettes du livre', () {
      final livre = GraineRecettes.depart(_auj);
      final auj = jourDe(_auj);
      final d = DemandePlan(
        recettes: livre,
        prevus: [
          RepasPrevu(
            id: 'p1',
            jour: plusJours(auj, 1),
            moment: MomentRepas.souper,
            recetteId: 'depart-chili',
          ),
        ],
        maintenant: _auj, // 17 h 30 : le dîner d'aujourd'hui est passé
        moments: {MomentRepas.diner, MomentRepas.souper},
        personnes: 2,
      );
      // 7 × 2 cases, moins le dîner d'aujourd'hui, moins le souper prévu.
      expect(d.cases, hasLength(12));
      final plan = lirePlan({
        'repas': [
          {'jour': 0, 'moment': 'souper', 'recette': 'depart-saumon'},
          {'jour': 0, 'moment': 'diner', 'recette': 'depart-chili'}, // passé
          {'jour': 1, 'moment': 'souper', 'recette': 'depart-chili'}, // prévu
          {'jour': 2, 'moment': 'diner', 'recette': 'inconnue'},
          {'jour': 2, 'moment': 'souper', 'recette': 'depart-gruau'}, // déj.
          {
            'jour': 3,
            'moment': 'souper',
            'recette': 'depart-riz-colle',
            'portions': 3,
            'pourquoi': 'Pour les restes',
          },
          {'jour': 3, 'moment': 'souper', 'recette': 'depart-chili'}, // doublon
          {'jour': 4, 'moment': 'collation', 'recette': 'depart-smoothie'},
        ],
        'resume': 'Une semaine simple.',
      }, d);
      expect(plan.repas.map((r) => r.recetteId), [
        'depart-saumon',
        'depart-riz-colle',
      ]);
      expect(plan.repas.first.portions, 2);
      expect(plan.repas.last.portions, 3);
      expect(plan.repas.last.pourquoi, 'Pour les restes');
      expect(plan.resume, 'Une semaine simple.');
    });

    test("l'écart : une recette du livre OU des aliments", () {
      final livre = GraineRecettes.depart(_auj);
      final d = DemandeEcart(
        moment: MomentRepas.souper,
        reste: const Nutriments(kcal: 600, proteines: 40),
        visees: const Nutriments(kcal: 2200, proteines: 150),
        recettes: livre,
      );
      final o = lireEcart({
        'options': [
          {
            'titre': 'Les restes de chili',
            'recette': 'depart-chili',
            'portions': 1.5,
          },
          {
            'titre': 'Omelette express',
            'recette': null,
            'aliments': [
              {
                'nom': 'Œufs',
                'quantite': 3,
                'unite': 'unite',
                'grammes': 150,
                'fcen': 'oeuf entier cru',
              },
            ],
          },
          {'titre': 'Rien', 'recette': 'inconnue'},
          {'titre': '', 'recette': 'depart-chili'},
        ],
      }, d);
      expect(o, hasLength(2));
      expect(o.first.recetteId, 'depart-chili');
      expect(o.first.portions, 1.5);
      expect(o.last.aliments.single.nom, 'Œufs');
    });

    test("l'estimation : sans les ingrédients libres", () {
      final e = lireEstimation({
        'titre': 'Pizza et salade',
        'aliments': [
          {
            'nom': 'Pizza toute garnie',
            'quantite': 2,
            'unite': 'unite',
            'taille': 'pointe',
            'grammes': 240,
            'fcen': 'pizza pepperoni',
          },
          {'nom': 'Sel', 'libre': true},
        ],
      });
      expect(e.titre, 'Pizza et salade');
      expect(e.aliments.single.nom, 'Pizza toute garnie');
    });

    test('les remplaçants et la conservation', () {
      final s = lireSubstitutions({
        'options': [
          {
            'ingredient': {
              'nom': 'Yogourt grec',
              'quantite': 125,
              'unite': 'g',
              'fcen': 'yogourt grec nature',
            },
            'pourquoi': 'Plus léger.',
          },
          {'ingredient': null},
        ],
      });
      expect(s.single.ingredient.nom, 'Yogourt grec');
      expect(s.single.pourquoi, 'Plus léger.');

      final c = lireConservation(
        {
          'ideal': 'Réfrigérateur',
          'frigo': [10, 3], // à rebours : remis dans l'ordre
          'congelateur': [0, 0],
          'ambiant': null,
          'ouvert': [5, 9999],
          'conseil': 'Au frigo, bien fermé.',
        },
        'Attiéké',
        Rayon.boissons,
      )!;
      expect(c.ideal, Emplacement.frigo);
      expect(c.frigo, (3, 10));
      expect(c.congelo, isNull);
      expect(c.ouvert, (5, 730));
      expect(c.expressions, [cleConservation('Attiéké')]);
      expect(lireConservation({'ideal': 'frigo'}, 'X', Rayon.autre), isNull);
    });

    test('le bilan lu', () {
      final b = BilanIa.depuisJson({
        'resume': 'Belle semaine !',
        'pistes': ['1. Plus de légumes', 'Boire un verre de plus', ''],
      })!;
      expect(b.resume, 'Belle semaine$_n!');
      expect(b.pistes, ['Plus de légumes', 'Boire un verre de plus']);
      expect(BilanIa.depuisJson({'pistes': []}), isNull);
    });
  });

  group('les invites', () {
    test(
      'les étapes : détaillées pour une idée, telles quelles à l\'import',
      () {
        // Vu sur le vrai Groq : « une action par étape » donnait six lignes
        // bâclées pour un thiéboudienne.
        final idees = invitesIdees(const DemandeIdees()).last.contenu;
        expect(idees, contains('de 6 à 12 étapes'));
        expect(idees, contains('le signe que c\'est prêt'));
        expect(idees, isNot(contains('une action par étape')));
        final import = invitesImport('Pâté chinois : boeuf, maïs, patates.');
        expect(import.last.contenu, isNot(contains('de 6 à 12 étapes')));
        expect(import.last.contenu, contains('sans en ajouter'));
      },
    );

    test('les idées : la région et ses cuisines, le garde-manger, JSON', () {
      final m = invitesIdees(
        const DemandeIdees(
          region: "Afrique de l'Ouest",
          moment: MomentRepas.souper,
          genre: GenrePlat.soupe,
          rapide: true,
          aUtiliser: ['Épinards'],
          aEviter: ['Chili sin carne'],
        ),
      );
      expect(m.first.role, 'system');
      final u = m.last.contenu;
      expect(u, contains('Sénégalaise'));
      expect(u, contains('souper'));
      expect(u, contains('soupe'));
      expect(u, contains('Épinards'));
      expect(u, contains('Chili sin carne'));
      expect(u, contains('JSON'));
      expect(m.first.contenu, contains('diététiste'));
      // En anglais : les textes en anglais, les mots-clés en français.
      expect(
        invitesIdees(const DemandeIdees(), francais: false).first.contenu,
        contains('English'),
      );
    });

    test('rien de personnel ne part dans le bilan', () {
      final c = ProviderContainer(
        overrides: [
          aujourdhuiProvider.overrideWithValue(_auj),
          horlogeProvider.overrideWithValue(() => _auj),
        ],
      );
      addTearDown(c.dispose);
      final etat = c.read(alimentationProvider);
      final b = bilanDeLaSemaine(
        journal: etat.journal,
        eau: etat.eau,
        besoins: c.read(besoinsProvider(jourDe(_auj))),
        seances: c.read(sportProvider).journal,
        sorties: c.read(coursesProvider).sorties,
        aujourdhui: _auj,
      );
      expect(b.joursNotes, inInclusiveRange(1, 7));
      expect(b.moyenne.kcal, greaterThan(1000));
      // Surtout des entrées rapides : fibres et sodium inconnus.
      expect(b.microsConnus, isFalse);
      final m = invitesBilan(b, objectif: etat.profil.objectif);
      final tout = m.map((x) => x.contenu).join('\n');
      expect(tout, contains('${b.joursNotes} sur 7'));
      expect(tout, contains("n'en parle pas"));
      // Ni poids, ni libération, ni nom.
      expect(tout, isNot(contains('kg')));
      expect(tout, isNot(contains('énergisantes')));
    });

    test('la semaine : le livre par id, les restes, les cases', () {
      final d = DemandePlan(
        recettes: GraineRecettes.depart(_auj),
        prevus: const [],
        maintenant: _auj,
        moments: {MomentRepas.souper},
        restes: {'depart-chili': 3},
      );
      final u = invitesPlan(d).last.contenu;
      expect(u, contains('id: depart-chili'));
      expect(u, contains('RESTES au garde-manger: 3 portions'));
      expect(u, contains('(0, souper)'));
      expect(u, contains('0 = jeudi'));
    });
  });

  group('le service', () {
    test('sans clé : une erreur claire, sans réseau', () async {
      await expectLater(
        ServiceIa(cle: '').json(const [MessageIa('user', 'JSON')]),
        throwsA(
          isA<ExceptionIa>().having(
            (e) => e.erreur,
            'erreur',
            ErreurIa.sansCle,
          ),
        ),
      );
    });

    test('une réponse entourée de texte se lit quand même', () {
      expect(ServiceIa.decoderJson('Voici : {"a": 1} merci'), {'a': 1});
      expect(() => ServiceIa.decoderJson('rien'), throwsA(isA<ExceptionIa>()));
    });

    // Un faux Groq local : chaque appel reçoit la réponse suivante.
    Future<(ServiceIa, List<int>, HttpServer)> faux(
      List<(int, String, String?)> reponses,
    ) async {
      final serveur = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final codes = <int>[];
      serveur.listen((r) async {
        await utf8.decoder.bind(r).join();
        final (code, contenu, apres) = reponses[codes.length];
        codes.add(code);
        r.response.statusCode = code;
        if (apres != null) r.response.headers.set('retry-after', apres);
        r.response.headers.contentType = ContentType.json;
        r.response.write(
          jsonEncode({
            'choices': [
              {
                'message': {'content': contenu},
              },
            ],
          }),
        );
        await r.response.close();
      });
      return (
        ServiceIa(cle: 'k', adresse: 'http://127.0.0.1:${serveur.port}/'),
        codes,
        serveur,
      );
    }

    Future<T> reel<T>(Future<T> Function() f) =>
        HttpOverrides.runWithHttpOverrides(f, _ReseauReel());

    test(
      'quota à la minute : on attend ce que Groq demande, une fois',
      () async {
        final (s, codes, serveur) = await faux([
          (429, '', '1'),
          (429, '', '1'),
          (200, '{"ok": true}', null),
        ]);
        addTearDown(() => serveur.close(force: true));
        expect(await reel(() => s.json(const [MessageIa('user', 'JSON')])), {
          'ok': true,
        });
        expect(codes, [429, 429, 200]);
      },
    );

    test('quota plus long : l\'erreur le dit sans attendre', () async {
      final (s, codes, serveur) = await faux([
        (429, '', '3600'),
        (429, '', '3600'),
      ]);
      addTearDown(() => serveur.close(force: true));
      await expectLater(
        reel(() => s.json(const [MessageIa('user', 'JSON')])),
        throwsA(
          isA<ExceptionIa>().having((e) => e.erreur, 'erreur', ErreurIa.quota),
        ),
      );
      expect(codes, [429, 429]);
    });

    test('une réponse illisible est redemandée une fois', () async {
      final (s, codes, serveur) = await faux([
        (200, '{"recettes": [{"nom": "Mafé"', null),
        (200, '{"recettes": []}', null),
      ]);
      addTearDown(() => serveur.close(force: true));
      expect(await reel(() => s.json(const [MessageIa('user', 'JSON')])), {
        'recettes': [],
      });
      expect(codes, [200, 200]);
    });
  });

  group('la conservation apprise', () {
    const attieke = Conservation(
      ['attieke'],
      Rayon.boissons,
      Emplacement.frigo,
      'Au frigo, bien fermé.',
      frigo: (3, 10),
      ouvert: (3, 5),
    );

    test('après le guide, avant le rayon', () {
      expect(horsDuGuide('Attiéké', const {}), isTrue);
      final apprises = {cleConservation('Attiéké'): attieke};
      expect(horsDuGuide('Attiéké', apprises), isFalse);
      expect(
        conservationDe('Attiéké', Rayon.boissons, apprises: apprises).conseil,
        'Au frigo, bien fermé.',
      );
      // Le guide passe toujours devant.
      expect(
        conservationDe(
          'Lait',
          Rayon.laitiers,
          apprises: {cleConservation('Lait'): attieke},
        ).conseil,
        isNot('Au frigo, bien fermé.'),
      );
      final relu = Conservation.depuisJson(attieke.versJson())!;
      expect(relu.frigo, (3, 10));
      expect(relu.ouvert, (3, 5));
      expect(relu.ideal, Emplacement.frigo);
      expect(Conservation.depuisJson({'id': ''}), isNull);
    });

    test('gardée au dépôt, elle date le rangement', () {
      final depot = Depot.memoire();
      addTearDown(depot.fermer);
      final c = ProviderContainer(
        overrides: [
          aujourdhuiProvider.overrideWithValue(_auj),
          horlogeProvider.overrideWithValue(() => _auj),
          depotProvider.overrideWithValue(depot),
        ],
      );
      addTearDown(c.dispose);
      c
          .read(coursesProvider.notifier)
          .apprendreConservation('Attiéké frais', attieke);
      final relu = EtatCourses.depuisDocument(depot.lire()!);
      final g = relu.conservations[cleConservation('attiéké frais')]!;
      expect(g.conseil, 'Au frigo, bien fermé.');
      expect(
        peremptionProposee(
          conservationDe(
            'Attiéké frais',
            Rayon.boissons,
            apprises: relu.conservations,
          ),
          Emplacement.frigo,
          jourDe(_auj),
        ),
        plusJours(jourDe(_auj), 3),
      );
    });
  });
}
