// test/alimentation_test.dart
//
// L'Alimentation, palier 1 : la base d'aliments (le vrai fichier du FCÉN,
// sa recherche), les règles (besoins, macronutriments, ajustement
// automatique, eau, conseil du jour), le journal (quantités, JSON
// tolérant), l'état (démonstration = maquette, dépôt, lien avec l'habitude
// de l'eau) — des fonctions pures et un conteneur, sans écran.

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/modele/alimentation/alimentation.dart';
import 'package:rhythm/modele/alimentation/base_aliments.dart';
import 'package:rhythm/modele/alimentation/calculs_alimentation.dart';
import 'package:rhythm/modele/alimentation/etat_alimentation.dart';
import 'package:rhythm/modele/alimentation/nutriments.dart';
import 'package:rhythm/modele/calculs_habitudes.dart';
import 'package:rhythm/modele/depot.dart';
import 'package:rhythm/modele/etat_habitudes.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/modele/modeles.dart';
import 'package:rhythm/modele/sports/exercices.dart';
import 'package:rhythm/modele/sports/sport.dart';
import 'package:rhythm/utils/dates.dart';

/// Jeudi 24 septembre 2026, 8 h (la maquette).
final DateTime _auj = DateTime(2026, 9, 24, 8);

EntreeJournal _entree(
  String id,
  DateTime jour,
  double kcal, {
  MomentRepas moment = MomentRepas.diner,
  String nom = 'Repas',
}) => EntreeJournal(
  id: id,
  jour: jourDe(jour),
  moment: moment,
  nom: nom,
  source: SourceEntree.rapide,
  nutriments: Nutriments(kcal: kcal),
  ajoutee: jour,
);

void main() {
  late BaseAliments base;
  setUpAll(() {
    base = BaseAliments.analyser(
      File('assets/donnees/fcen.txt').readAsStringSync(),
    );
  });

  group('la base (FCÉN 2026)', () {
    test('5 894 aliments, leurs nutriments et leurs portions', () {
      expect(base.aliments.length, 5894);
      final banane = base.parCode(1704)!;
      expect(banane.nom, 'Banane, crue');
      expect(banane.pour100g.kcal, 89);
      expect(banane.pour100g.glucides, closeTo(22.8, 0.01));
      final moyen = banane.portions.firstWhere(
        (p) => p.libelle.startsWith('1 moyen'),
      );
      expect(moyen.grammes, 118);
      expect(banane.pour(118).kcal, closeTo(105, 0.1));
    });

    test('la recherche : accents, pluriels, mots vides, classement', () {
      String premier(String q) => base.rechercher(q).first.nom;
      expect(premier('banane'), 'Banane, crue');
      expect(premier('BANANES'), 'Banane, crue');
      expect(premier('oeufs'), startsWith('Oeuf'));
      expect(premier('œuf'), startsWith('Oeuf'));
      expect(premier("beurre d'arachide"), startsWith("Beurre d'arachides"));
      expect(premier('bleuets'), 'Bleuet, cru');
      expect(premier('poulet'), 'Poulet à griller, poitrine, viande, rôti');
      expect(premier('gruau'), contains('avoine (gruau)'));
      expect(premier('pomme'), startsWith('Pomme, crue'));
      final riz = base.rechercher('riz blanc cuit');
      expect(riz, isNotEmpty);
      expect(riz.first.nom, contains('cuit'));
      expect(base.rechercher('zzzqqq'), isEmpty);
      expect(base.rechercher('   '), isEmpty);
    });

    test('ce qu’on mange souvent passe devant', () {
      final sans = base.rechercher('lait');
      final code = sans[5].code;
      final avec = base.rechercher('lait', frequents: {code: 3});
      expect(avec.first.code, code);
    });

    test('simplifier et les mots d’une recherche', () {
      expect(simplifier('Crème Brûlée'), 'creme brulee');
      expect(motsRecherche("Beurre d'arachides"), ['beurre', 'arachide']);
      expect(motsRecherche('riz'), ['riz']);
    });
  });

  group('les besoins', () {
    const homme = ProfilNutrition(
      sexe: Sexe.homme,
      anneeNaissance: 1996,
      taille: 175,
    );

    Besoins besoins(
      ProfilNutrition p, {
      double? poids = 70,
      List<SeanceFaite> seances = const [],
      List<EntreeJournal> journal = const [],
      List<MesureCorps> mesures = const [],
    }) => besoinsDu(
      profil: p,
      poids: poids,
      seances: seances,
      programmes: const [],
      journal: journal,
      mesures: mesures,
      jour: jourDe(_auj),
      aujourdhui: _auj,
    );

    test('Mifflin-St Jeor', () {
      expect(
        metabolismeBase(sexe: Sexe.homme, poids: 70, taille: 175, age: 30),
        1648.75,
      );
      expect(
        metabolismeBase(sexe: Sexe.femme, poids: 60, taille: 165, age: 30),
        1320.25,
      );
    });

    test('maintenir, assis, sans sport : métabolisme × 1,2', () {
      final b = besoins(homme);
      expect(b.kcal, 1980);
      expect(b.proteines, 112); // 1,6 g/kg
      expect(b.lipides, 66); // 30 %
      expect(b.glucides, 235); // le reste
      expect(b.estimation, isFalse);
      expect(b.verres, 8);
    });

    test('prendre du poids : + 275 kcal pour 0,25 kg par semaine', () {
      final b = besoins(homme.copierAvec(objectif: ObjectifPoids.prendre));
      expect(b.kcal, 2250);
      expect(b.proteines, 126); // 1,8 g/kg
      final vite = besoins(
        homme.copierAvec(objectif: ObjectifPoids.prendre, rythme: 0.5),
      );
      expect(vite.kcal, 2530);
    });

    test('perdre : jamais sous le plancher', () {
      final b = besoins(
        const ProfilNutrition(
          sexe: Sexe.femme,
          anneeNaissance: 1996,
          taille: 150,
          objectif: ObjectifPoids.perdre,
          rythme: 0.5,
        ),
        poids: 45,
      );
      expect(b.kcal, greaterThanOrEqualTo(1200));
    });

    test('les séances : moyenne de 14 jours ; jour de séance = plus de '
        'glucides', () {
      final seances = [
        for (var k = 1; k <= 7; k++)
          SeanceFaite(
            id: 's$k',
            nom: 'Course',
            debut: plusJours(_auj, -k * 2),
            dureeSec: 1800,
            style: StyleSport.cardio,
            kcal: 400,
          ),
      ];
      final b = besoins(homme, seances: seances);
      expect(b.sport, 200); // 7 × 400 / 14
      expect(b.jourDeSeance, isFalse);
      final aujourdhui = [
        ...seances,
        SeanceFaite(
          id: 'auj',
          nom: 'Course',
          debut: _auj,
          dureeSec: 2700,
          style: StyleSport.cardio,
          kcal: 400,
        ),
      ];
      final s = besoins(homme, seances: aujourdhui);
      expect(s.jourDeSeance, isTrue);
      expect(s.lipides, lessThan(b.lipides));
      expect(s.glucides, greaterThan(b.glucides));
      // Un verre de plus par demi-heure de sport du jour.
      expect(s.verres, b.verres + 1);
      final sans = besoins(
        homme.copierAvec(compterSeances: false),
        seances: seances,
      );
      expect(sans.sport, 0);
    });

    test('profil incomplet ou poids inconnu : une estimation', () {
      expect(besoins(const ProfilNutrition()).estimation, isTrue);
      expect(besoins(homme, poids: null).estimation, isTrue);
    });

    test('objectifs fixés à la main', () {
      final b = besoins(
        homme.copierAvec(
          manuels: () => const ObjectifsManuels(
            kcal: 2200,
            proteines: 150,
            glucides: 260,
            lipides: 70,
          ),
        ),
      );
      expect(
        [b.kcal, b.proteines, b.glucides, b.lipides],
        [2200, 150, 260, 70],
      );
      expect(b.manuel, isTrue);
    });
  });

  group("l'ajustement automatique", () {
    List<EntreeJournal> journees(int n, double kcal) => [
      for (var k = 1; k <= n; k++) ...[
        _entree('a$k', plusJours(_auj, -k), kcal / 2),
        _entree('b$k', plusJours(_auj, -k), kcal / 2),
      ],
    ];
    List<MesureCorps> pesees(double parSemaine) => [
      for (final k in const [20, 13, 6, 1])
        MesureCorps(
          id: 'm$k',
          date: plusJours(_auj, -k),
          poids: 70 + (20 - k) * parSemaine / 7,
        ),
    ];

    test('pas assez de données : rien ne change', () {
      final a = ajustementAdaptatif(
        journal: journees(6, 2500),
        mesures: pesees(0),
        jour: _auj,
        depenseFormule: 2000,
      );
      expect(a.etat, EtatAjustement.donneesInsuffisantes);
      expect(a.kcal, 0);
      expect(a.joursNotes, 6);
    });

    test('poids stable à 2 500 kcal : la dépense réelle est 2 500', () {
      final a = ajustementAdaptatif(
        journal: journees(14, 2500),
        mesures: pesees(0),
        jour: _auj,
        depenseFormule: 2000,
      );
      expect(a.etat, EtatAjustement.actif);
      expect(a.depenseReelle, closeTo(2500, 1));
      expect(a.kcal, 250); // la moitié de l'écart
    });

    test('on prend 0,5 kg par semaine : la dépense réelle est plus basse', () {
      final a = ajustementAdaptatif(
        journal: journees(14, 2500),
        mesures: pesees(0.5),
        jour: _auj,
        depenseFormule: 2000,
      );
      expect(a.rythmeReel, closeTo(0.5, 0.01));
      expect(a.depenseReelle, closeTo(1950, 2));
      expect(a.kcal, anyOf(-20, -30));
    });

    test('bornée à ± 400, et désactivable', () {
      final a = ajustementAdaptatif(
        journal: journees(14, 4000),
        mesures: pesees(0),
        jour: _auj,
        depenseFormule: 2000,
      );
      expect(a.kcal, 400);
      final off = ajustementAdaptatif(
        journal: journees(14, 4000),
        mesures: pesees(0),
        jour: _auj,
        depenseFormule: 2000,
        actif: false,
      );
      expect(off.etat, EtatAjustement.desactive);
      expect(off.kcal, 0);
    });
  });

  group('le journal', () {
    test('le moment selon l’heure', () {
      MomentRepas a(int h, [int m = 0]) =>
          momentPourHeure(DateTime(2026, 9, 24, h, m));
      expect(a(7), MomentRepas.dejeuner);
      expect(a(10, 29), MomentRepas.dejeuner);
      expect(a(12), MomentRepas.diner);
      expect(a(15), MomentRepas.collation);
      expect(a(18), MomentRepas.souper);
      expect(a(22), MomentRepas.collation);
    });

    test('le contenu d’un repas en une phrase', () {
      expect(
        contenuDe([
          _entree('1', _auj, 1, nom: 'Gruau'),
          _entree('2', _auj, 1, nom: 'Banane'),
          _entree('3', _auj, 1, nom: "Beurre d'arachide"),
          _entree('4', _auj, 1, nom: 'Banane'),
          _entree('5', _auj, 1, nom: 'BBQ maison'),
        ]),
        "Gruau, banane, beurre d'arachide, BBQ maison",
      );
    });

    test('changer la quantité : règle de trois', () {
      final e = EntreeJournal(
        id: 'x',
        jour: jourDe(_auj),
        moment: MomentRepas.collation,
        nom: 'Yogourt',
        source: SourceEntree.produit,
        produitId: 'p',
        grammes: 175,
        portions: 1,
        portion: '175 g',
        nutriments: const Nutriments(kcal: 145, proteines: 16),
        ajoutee: _auj,
      );
      final deux = e.avecQuantite(portions: 2);
      expect(deux.nutriments.kcal, 290);
      expect(deux.grammes, 350);
      final cent = e.avecQuantite(grammes: 100);
      expect(cent.nutriments.proteines, closeTo(9.14, 0.01));
    });

    test('les récents : un par aliment, le plus récent d’abord', () {
      final j = [
        _entree('1', plusJours(_auj, -2), 100, nom: 'Pomme'),
        _entree('2', plusJours(_auj, -1), 200, nom: 'Riz'),
        _entree('3', _auj, 110, nom: 'Pomme'),
      ];
      final r = recents(j);
      expect(r.map((e) => e.nom), ['Pomme', 'Riz']);
      expect(r.first.nutriments.kcal, 110);
    });

    test('JSON : aller-retour, et lecture tolérante', () {
      final etat = GraineAlimentation.demonstration(_auj);
      final relu = EtatAlimentation.depuisDocument(etat.versDocument());
      expect(relu.journal.length, etat.journal.length);
      expect(relu.produits.length, 2);
      expect(relu.eauDu(_auj), 5);
      expect(relu.profil.manuels?.kcal, 2200);
      expect(
        totalDe(relu.entreesDu(_auj)).kcal,
        totalDe(etat.entreesDu(_auj)).kcal,
      );
      final abime = EtatAlimentation.depuisDocument({
        'journalAlim': [
          42,
          {'id': 'a'},
          {'id': 'b', 'nom': 'X', 'jour': 20260924, 'moment': 'brunch'},
          {
            'id': 'c',
            'nom': 'Pain',
            'jour': 20260924,
            'moment': 'dejeuner',
            'source': 'rapide',
            'n': {'kcal': 'beaucoup', 'p': 8},
          },
        ],
        'profilAlim': {'sexe': 'autre', 'taille': -3, 'rythme': 'vite'},
        'eauAlim': [
          {'id': '20260924', 'verres': 3},
          {'id': 'x', 'verres': 2},
        ],
      });
      expect(abime.journal.single.nom, 'Pain');
      expect(abime.journal.single.nutriments.kcal, 0);
      expect(abime.journal.single.nutriments.proteines, 8);
      expect(abime.profil.sexe, isNull);
      expect(abime.profil.taille, isNull);
      expect(abime.profil.rythme, 0.25);
      expect(abime.eau, {20260924: 3});
    });
  });

  group("l'état", () {
    test('la démonstration retombe sur la maquette', () {
      final c = ProviderContainer(
        overrides: [aujourdhuiProvider.overrideWithValue(_auj)],
      );
      addTearDown(c.dispose);
      final etat = c.read(alimentationProvider);
      final total = totalDe(etat.entreesDu(_auj));
      expect(total.kcal, 1640);
      expect(total.proteines, 112);
      expect(total.glucides, 190);
      expect(total.lipides, 48);
      expect(etat.eauDu(_auj), 5);
      final b = c.read(besoinsProvider(jourDe(_auj)));
      expect(
        [b.kcal, b.proteines, b.glucides, b.lipides, b.verres],
        [2200, 150, 260, 70, 8],
      );
      expect(
        contenuDe(etat.entreesDu(_auj, MomentRepas.dejeuner)),
        "Gruau, banane, beurre d'arachide",
      );
      expect(totalDe(etat.entreesDu(_auj, MomentRepas.diner)).kcal, 740);
      expect(etat.entreesDu(_auj, MomentRepas.souper), isEmpty);
    });

    test('dépôt : premier lancement vide, tout est relu', () {
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
      expect(c.read(alimentationProvider).journal, isEmpty);
      final n = c.read(alimentationProvider.notifier);
      n.ajouter(_entree(n.nouvelId('ent'), _auj, 300, nom: 'Soupe'));
      n.enregistrerProduit(
        const Produit(
          id: 'p1',
          nom: 'Barre',
          portion: '1 barre',
          parPortion: Nutriments(kcal: 200),
        ),
      );
      n.modifierProfil(const ProfilNutrition(sexe: Sexe.femme, taille: 160));
      c.read(alimentationProvider.notifier).fixerEau(_auj, 3);

      final document = depot.lire()!;
      final relu = EtatAlimentation.depuisDocument(document);
      expect(relu.journal.single.nom, 'Soupe');
      expect(relu.produits.single.nom, 'Barre');
      expect(relu.profil.sexe, Sexe.femme);
      expect(relu.eauDu(_auj), 3);
      expect(document['versionAlim'], kVersionAlim);
    });

    test("l'objectif d'eau atteint coche « Boire 2 L d'eau »", () {
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
      final auj = jourDe(_auj);
      final vises = c.read(besoinsProvider(auj)).verres;
      final n = c.read(alimentationProvider.notifier);
      expect(n.fixerEau(auj, vises - 1), isNull);
      final eau = c.read(habitudesProvider).parId('hab-eau')!;
      expect(estFaite(eau, auj), isFalse);
      expect(n.fixerEau(auj, vises), "Boire 2 L d'eau");
      expect(
        estFaite(c.read(habitudesProvider).parId('hab-eau')!, auj),
        isTrue,
      );
      // Déjà cochée : rien de plus.
      expect(n.fixerEau(auj, vises + 1), isNull);
    });
  });

  group('le conseil du jour', () {
    const b = Besoins(
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
      poids: 72,
      estimation: false,
      manuel: false,
      jourDeSeance: false,
    );
    GenreConseil genre({
      Nutriments total = Nutriments.zero,
      int entrees = 0,
      int verres = 0,
      bool seance = false,
      bool complet = true,
      ObjectifPoids objectif = ObjectifPoids.maintenir,
      required DateTime quand,
    }) => conseilDuJour(
      besoins: b,
      total: total,
      entrees: entrees,
      verres: verres,
      seanceFaite: seance,
      profilComplet: complet,
      objectif: objectif,
      maintenant: quand,
    ).genre;

    DateTime a(int h) => DateTime(2026, 9, 24, h);

    test('dans l’ordre', () {
      expect(genre(complet: false, quand: a(8)), GenreConseil.profil);
      expect(genre(quand: a(8)), GenreConseil.dejeuner);
      expect(
        genre(
          total: const Nutriments(kcal: 2700, proteines: 100),
          entrees: 5,
          quand: a(20),
        ),
        GenreConseil.depasse,
      );
      expect(
        genre(
          total: const Nutriments(kcal: 2100, proteines: 140),
          entrees: 5,
          quand: a(20),
        ),
        GenreConseil.atteint,
      );
      expect(
        genre(
          total: const Nutriments(kcal: 900, proteines: 40),
          entrees: 3,
          seance: true,
          verres: 6,
          quand: a(13),
        ),
        GenreConseil.apresSeance,
      );
      expect(
        genre(
          total: const Nutriments(kcal: 900, proteines: 60),
          entrees: 3,
          verres: 1,
          quand: a(15),
        ),
        GenreConseil.eau,
      );
      expect(
        genre(
          total: const Nutriments(kcal: 1200, proteines: 60),
          entrees: 3,
          verres: 8,
          objectif: ObjectifPoids.prendre,
          quand: a(20),
        ),
        GenreConseil.prendreSoir,
      );
      expect(
        genre(
          total: const Nutriments(kcal: 1700, proteines: 90),
          entrees: 4,
          verres: 8,
          quand: a(18),
        ),
        GenreConseil.proteinesSoir,
      );
      expect(
        genre(
          total: const Nutriments(kcal: 1000, proteines: 60),
          entrees: 2,
          verres: 4,
          quand: a(11),
        ),
        GenreConseil.general,
      );
    });
  });
}
