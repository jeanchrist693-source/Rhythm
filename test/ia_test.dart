// test/ia_test.dart
//
// L'ASSISTANT de l'Alimentation (palier 4), sans réseau : les textes de
// l'IA nettoyés (typographie française, glyphes des polices) ; la
// CORRESPONDANCE avec la vraie base du FCÉN (l'aliment, la quantité, les
// calories vraisemblables) ; la lecture TOLÉRANTE et VÉRIFIÉE des réponses
// (recettes, semaine, écart, estimation, remplaçants, conservation, bilan) ;
// les invites (ce qui part — et ce qui ne part pas) ; le bilan de la
// semaine ; les repères de conservation appris, gardés au dépôt.

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
      final m = invitesBilan(b, objectif: etat.profil.objectif);
      final tout = m.map((x) => x.contenu).join('\n');
      expect(tout, contains('${b.joursNotes} sur 7'));
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
