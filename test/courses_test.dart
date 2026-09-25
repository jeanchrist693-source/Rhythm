// test/courses_test.dart
//
// Les ACHATS (palier 2 de l'Alimentation) : les taxes du Québec (barème
// daté, trois statuts, la caisse au cent, la consigne, les suggestions),
// la saisie et les rayons, la fusion des doublons, le guide de
// conservation (Thermoguide), les prix et le mois, le garde-manger
// (ouvrir, déplacer, finir, jeter, réassort), le JSON tolérant, le dépôt,
// les rappels de péremption.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/l10n/app_localizations.dart';
import 'package:rhythm/modele/alimentation/calculs_courses.dart';
import 'package:rhythm/modele/alimentation/conservation.dart';
import 'package:rhythm/modele/alimentation/courses.dart';
import 'package:rhythm/modele/alimentation/etat_courses.dart';
import 'package:rhythm/modele/alimentation/rayons.dart';
import 'package:rhythm/modele/alimentation/taxes.dart';
import 'package:rhythm/modele/depot.dart';
import 'package:rhythm/modele/etat_habitudes.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/systeme/rappels_garde_manger.dart';
import 'package:rhythm/utils/dates.dart';

/// Jeudi 24 septembre 2026, 8 h.
final DateTime _auj = DateTime(2026, 9, 24, 8);

LigneAchat _ligne(
  String nom,
  double pu, {
  double n = 1,
  StatutTaxe statut = StatutTaxe.detaxe,
  Rayon rayon = Rayon.autre,
  bool auPoids = false,
}) => LigneAchat(
  nom: nom,
  rayon: rayon,
  panier: LignePanier(
    prixUnitaire: pu,
    nombre: n,
    statut: statut,
    auPoids: auPoids,
  ),
);

Achat _achat(String id, DateTime date, String magasin, List<LigneAchat> l) =>
    Achat(
      id: id,
      date: date,
      magasin: magasin,
      lignes: l,
      caisse: Caisse.de([
        for (final x in l)
          (prix: x.panier.prix, statut: x.panier.statut, consigne: 0.0),
      ], baremeAu(date)),
    );

void main() {
  group('les taxes du Québec', () {
    test('le barème en vigueur : TPS 5 %, TVQ 9,975 %', () {
      final b = baremeAu(_auj);
      expect(b.tps, 0.05);
      expect(b.tvq, 0.09975);
      // Un barème futur s'applique seul, à sa date.
      final futur = [
        ...kBaremesQuebec,
        Bareme(depuis: DateTime(2027, 1, 1), tps: 0.05, tvq: 0.1),
      ];
      expect(baremeAu(DateTime(2026, 12, 31), futur).tvq, 0.09975);
      expect(baremeAu(DateTime(2027, 1, 1), futur).tvq, 0.1);
    });

    test('la caisse : chaque taxe sur ce qui y est soumis, au cent', () {
      final c = Caisse.de([
        (prix: 10.0, statut: StatutTaxe.detaxe, consigne: 0.0),
        (prix: 4.49, statut: StatutTaxe.tpsTvq, consigne: 0.0),
        (prix: 3.99, statut: StatutTaxe.tps, consigne: 0.0),
        (prix: 7.74, statut: StatutTaxe.tpsTvq, consigne: 0.60),
      ], baremeAu(_auj));
      expect(c.sousTotal, 26.22);
      // TPS sur 4,49 + 3,99 + 7,74 = 16,22 → 0,811 → 0,81.
      expect(c.tps, 0.81);
      // TVQ sur 4,49 + 7,74 = 12,23 → 1,2199 → 1,22.
      expect(c.tvq, 1.22);
      expect(c.consigne, 0.60);
      expect(c.total, 28.85);
      expect(Caisse.avecTaxes(10, StatutTaxe.tpsTvq, baremeAu(_auj)), 11.5);
      expect(Caisse.avecTaxes(10, StatutTaxe.tps, baremeAu(_auj)), 10.5);
    });

    test('les suggestions : aliments de base, grignotines, TVQ abolie', () {
      StatutTaxe s(String nom, [Rayon r = Rayon.autre]) =>
          suggererStatut(nom, r.taxe, nonAlimentaire: !r.alimentaire).statut;
      expect(s('Bananes', Rayon.fruits), StatutTaxe.detaxe);
      expect(s('Croustilles BBQ'), StatutTaxe.tpsTvq);
      expect(s('Boisson gazeuse'), StatutTaxe.tpsTvq);
      expect(s('Chocolat noir 70 %'), StatutTaxe.tpsTvq);
      expect(s('Lait au chocolat', Rayon.laitiers), StatutTaxe.detaxe);
      expect(s('Céréales au chocolat', Rayon.cereales), StatutTaxe.detaxe);
      expect(s('Barres tendres'), StatutTaxe.tps);
      expect(s('Granola'), StatutTaxe.tps);
      expect(s('Noix salées'), StatutTaxe.tps);
      expect(s('Papier hygiénique', Rayon.hygiene), StatutTaxe.tps);
      expect(s('Muffin aux bleuets'), StatutTaxe.tps);
      expect(s('Bière', Rayon.boissons), StatutTaxe.tpsTvq);
      expect(s('Savon à vaisselle', Rayon.entretien), StatutTaxe.tpsTvq);
      expect(s('Tampons', Rayon.hygiene), StatutTaxe.detaxe);
      expect(
        suggererStatut('Barres tendres', StatutTaxe.detaxe).raison,
        RaisonTaxe.tvqAbolie,
      );
    });

    test('la consigne proposée', () {
      expect(consigneSuggeree('Canettes de cola'), 0.10);
      expect(consigneSuggeree('Eau pétillante'), 0.10);
      expect(consigneSuggeree('Lait 2 %'), 0);
    });

    test(
      'un barème reçu en ligne : les taux invraisemblables sont refusés',
      () {
        final b = baremesDepuis({
          'baremes': [
            {'depuis': '2027-01-01', 'tps': 0.05, 'tvq': 0.1},
            {'depuis': '2027-01-01', 'tps': 5, 'tvq': 0.1},
            {'depuis': 'demain', 'tps': 0.05, 'tvq': 0.1},
            42,
          ],
        });
        expect(b, hasLength(1));
        expect(b.single.tvq, 0.1);
      },
    );
  });

  group('la saisie et les rayons', () {
    test('lire une saisie', () {
      (String, Quantite?) l(String t) => lireSaisie(t);
      expect(l('2 kg poulet'), ('Poulet', const Quantite(2, Unite.kg)));
      expect(l('poulet 2 kg'), ('Poulet', const Quantite(2, Unite.kg)));
      expect(l('6 œufs'), ('Œufs', const Quantite(6)));
      expect(l('lait x2'), ('Lait', const Quantite(2)));
      expect(l("500 g de bœuf haché"), (
        'Bœuf haché',
        const Quantite(500, Unite.g),
      ));
      expect(l('3 litres de lait'), ('Lait', const Quantite(3, Unite.l)));
      expect(l('1,5 lb de raisins'), (
        'Raisins',
        const Quantite(1.5, Unite.lb),
      ));
      expect(l('7up'), ('7up', null));
      expect(l('bananes'), ('Bananes', null));
    });

    test('le rayon deviné', () {
      expect(rayonDe('Bananes'), Rayon.fruits);
      expect(rayonDe('Pommes de terre'), Rayon.legumes);
      expect(rayonDe("Beurre d'arachide"), Rayon.condiments);
      expect(rayonDe('Beurre'), Rayon.laitiers);
      expect(rayonDe('Cuisses de poulet'), Rayon.viandes);
      expect(rayonDe('Savon à vaisselle'), Rayon.entretien);
      expect(rayonDe('Papier hygiénique'), Rayon.hygiene);
      expect(rayonDe('Crème glacée'), Rayon.surgeles);
      expect(rayonDe('Lait de coco'), Rayon.conserves);
      expect(rayonDe('Thé vert'), Rayon.boissons);
      expect(rayonDe('Zzzz'), Rayon.autre);
    });

    test('les quantités s’additionnent dans la même famille', () {
      expect(
        const Quantite(500, Unite.g).plus(const Quantite(1, Unite.kg)),
        const Quantite(1.5, Unite.kg),
      );
      expect(const Quantite(2).plus(const Quantite(1)), const Quantite(3));
      expect(
        additionner(const [Quantite(2)], const Quantite(150, Unite.g)),
        const [Quantite(2), Quantite(150, Unite.g)],
      );
    });
  });

  group('la liste', () {
    test('fusion des doublons, quantités et origines', () {
      var (liste, a, f) = ajouterALaListe(
        const [],
        id: '1',
        nom: 'Bananes',
        rayon: Rayon.fruits,
        maintenant: _auj,
        quantite: const Quantite(6),
        origine: 'Smoothie',
      );
      expect(f, isFalse);
      (liste, a, f) = ajouterALaListe(
        liste,
        id: '2',
        nom: 'banane',
        rayon: Rayon.fruits,
        maintenant: _auj,
        quantite: const Quantite(3),
        origine: 'Muffins',
      );
      expect(f, isTrue);
      expect(liste, hasLength(1));
      expect(a.quantites, const [Quantite(9)]);
      expect(a.origines, ['Smoothie', 'Muffins']);
      // Sans quantité : un de plus s'il est compté à l'unité.
      (liste, a, f) = ajouterALaListe(
        liste,
        id: '3',
        nom: 'BANANES',
        rayon: Rayon.fruits,
        maintenant: _auj,
      );
      expect(a.quantites, const [Quantite(10)]);
      // Au panier, il ne fusionne plus : une nouvelle ligne.
      liste = [
        liste.single.copierAvec(
          panier: () => const LignePanier(
            prixUnitaire: 1,
            nombre: 1,
            statut: StatutTaxe.detaxe,
          ),
        ),
      ];
      (liste, a, f) = ajouterALaListe(
        liste,
        id: '4',
        nom: 'Bananes',
        rayon: Rayon.fruits,
        maintenant: _auj,
      );
      expect(f, isFalse);
      expect(liste, hasLength(2));
    });

    test('par rayon, dans l’ordre du magasin', () {
      final liste = [
        ArticleListe(id: '1', nom: 'Lait', rayon: Rayon.laitiers, ajoute: _auj),
        ArticleListe(id: '2', nom: 'Pomme', rayon: Rayon.fruits, ajoute: _auj),
        ArticleListe(
          id: '3',
          nom: 'Yogourt',
          rayon: Rayon.laitiers,
          ajoute: _auj,
        ),
      ];
      final r = parRayon(liste, const [Rayon.laitiers, Rayon.fruits]);
      expect(r.map((x) => x.$1), [Rayon.laitiers, Rayon.fruits]);
      expect(r.first.$2.map((a) => a.nom), ['Lait', 'Yogourt']);
    });

    test('déjà au garde-manger', () {
      final gm = [
        ArticleGardeManger(
          id: 'a',
          nom: 'Lait 2 %',
          emplacement: Emplacement.frigo,
          rayon: Rayon.laitiers,
          entre: _auj,
        ),
      ];
      expect(dejaAuGardeManger(gm, 'lait'), hasLength(1));
      expect(dejaAuGardeManger(gm, 'Laitue'), isEmpty);
    });

    test('estimation, historique et meilleur prix, habituels', () {
      final achats = [
        _achat('a', DateTime(2026, 9, 1), 'Maxi', [
          _ligne('Lait 2 %', 6.49),
          _ligne('Croustilles', 4.49, statut: StatutTaxe.tpsTvq),
        ]),
        _achat('b', DateTime(2026, 9, 15), 'IGA', [
          _ligne('Lait 2 %', 6.99),
          _ligne('Bananes', 1.69, n: 1.2, auPoids: true),
        ]),
      ];
      final h = historiquePrix(achats, 'lait 2 %');
      expect(h.map((p) => p.magasin), ['IGA', 'Maxi']);
      expect(meilleurPrix(h)!.magasin, 'Maxi');
      final liste = [
        ArticleListe(
          id: '1',
          nom: 'Lait 2 %',
          rayon: Rayon.laitiers,
          ajoute: _auj,
        ),
        ArticleListe(
          id: '2',
          nom: 'Croustilles',
          rayon: Rayon.collations,
          ajoute: _auj,
        ),
        ArticleListe(id: '3', nom: 'Kiwi', rayon: Rayon.fruits, ajoute: _auj),
      ];
      final e = estimationListe(liste, achats, baremeAu(_auj));
      expect(e.connus, 2);
      expect(e.total, closeTo(6.99 + 4.49 * 1.14975, 0.01));
      expect(habituels(achats, const []).map((x) => x.$1), ['Lait 2 %']);
      expect(habituels(achats, liste), isEmpty);
    });

    test('le mois : dépensé et gaspillé', () {
      final achats = [
        _achat('a', DateTime(2026, 8, 30), 'Maxi', [_ligne('X', 50)]),
        _achat('b', DateTime(2026, 9, 3), 'Maxi', [_ligne('Y', 40)]),
      ];
      expect(depenseDuMois(achats, _auj), 40);
      final g = gaspillageDuMois([
        Sortie(
          id: '1',
          date: DateTime(2026, 9, 2),
          nom: 'A',
          rayon: Rayon.fruits,
          jete: true,
          valeur: 2.5,
        ),
        Sortie(
          id: '2',
          date: DateTime(2026, 9, 3),
          nom: 'B',
          rayon: Rayon.fruits,
          jete: false,
        ),
        Sortie(
          id: '3',
          date: DateTime(2026, 8, 3),
          nom: 'C',
          rayon: Rayon.fruits,
          jete: true,
          valeur: 9,
        ),
      ], _auj);
      expect(g.valeur, 2.5);
      expect(g.nombre, 1);
    });
  });

  group('le guide de conservation (Thermoguide)', () {
    test('reconnaître un aliment : la plus longue expression gagne', () {
      expect(guideDe('Bananes')!.ideal, Emplacement.comptoir);
      expect(guideDe('Pommes de terre')!.ideal, Emplacement.armoire);
      expect(guideDe('Pommes Cortland')!.ideal, Emplacement.frigo);
      expect(guideDe("Beurre d'arachide")!.rayon, Rayon.condiments);
      expect(guideDe('Beurre salé')!.rayon, Rayon.laitiers);
      expect(guideDe('Fromage cottage')!.frigo, (3, 5));
      expect(guideDe('Crème glacée')!.ideal, Emplacement.congelateur);
      expect(guideDe('Lait 2 %')!.ouvert, (3, 5));
      expect(guideDe('Laitue romaine')!.rayon, Rayon.legumes);
      expect(guideDe('Pâtes')!.rayon, Rayon.cereales);
      expect(guideDe('Patates')!.ideal, Emplacement.armoire);
      expect(guideDe('Ail')!.rayon, Rayon.legumes);
      expect(guideDe('Ailes de poulet')!.rayon, Rayon.viandes);
      expect(guideDe('Bœuf haché maigre')!.frigo, (1, 2));
      expect(guideDe('Bleuets surgelés')!.ideal, Emplacement.congelateur);
      expect(guideDe('Zzzz'), isNull);
    });

    test('la date proposée : la durée la plus prudente', () {
      final g = guideDe('Bœuf haché')!;
      final le = DateTime(2026, 9, 24);
      expect(
        peremptionProposee(g, Emplacement.frigo, le),
        DateTime(2026, 9, 25),
      );
      expect(
        peremptionProposee(g, Emplacement.congelateur, le),
        DateTime(2026, 12, 23),
      );
      expect(peremptionProposee(g, Emplacement.armoire, le), isNull);
    });

    test('ouvert : la date ne peut que raccourcir', () {
      final g = guideDe('Lait')!;
      final le = DateTime(2026, 9, 24);
      expect(
        peremptionApresOuverture(g, DateTime(2026, 10, 5), le),
        DateTime(2026, 9, 27),
      );
      expect(
        peremptionApresOuverture(g, DateTime(2026, 9, 25), le),
        DateTime(2026, 9, 25),
      );
    });

    test('un repère pour chaque rayon', () {
      for (final r in Rayon.values) {
        expect(conservationDuRayon(r).rayon, r);
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

    test('au magasin → terminer → ranger → le garde-manger', () {
      final depot = Depot.memoire();
      addTearDown(depot.fermer);
      final c = conteneur(depot);
      final n = c.read(coursesProvider.notifier);
      expect(c.read(coursesProvider).liste, isEmpty);
      final (poulet, _) = n.ajouter(
        'Poitrines de poulet',
        rayon: Rayon.viandes,
        quantite: const Quantite(1, Unite.kg),
      );
      final (savon, _) = n.ajouter('Savon à vaisselle', rayon: Rayon.entretien);
      n.ajouter('Kiwis', rayon: Rayon.fruits);
      n.mettreAuPanier(
        poulet.id,
        const LignePanier(
          prixUnitaire: 13.2,
          nombre: 0.9,
          auPoids: true,
          statut: StatutTaxe.detaxe,
        ),
      );
      n.mettreAuPanier(
        savon.id,
        const LignePanier(
          prixUnitaire: 3.79,
          nombre: 1,
          statut: StatutTaxe.tpsTvq,
        ),
      );
      final achat = n.terminer(magasin: 'Maxi')!;
      expect(achat.lignes, hasLength(2));
      expect(achat.caisse.sousTotal, 15.67);
      expect(achat.caisse.total, closeTo(11.88 + 3.79 * 1.14975, 0.01));
      // Ce qui n'est pas pris reste sur la liste.
      expect(c.read(coursesProvider).liste.single.nom, 'Kiwis');

      final ranges = [
        for (final l in achat.lignes)
          ?rangementPropose(
            l,
            id: n.nouvelId('gm'),
            date: jourDe(achat.date),
            bareme: baremeAu(achat.date),
            magasin: achat.magasin,
          ),
      ];
      // Le savon ne va pas au garde-manger.
      expect(ranges.single.nom, 'Poitrines de poulet');
      expect(ranges.single.emplacement, Emplacement.frigo);
      expect(ranges.single.peremption, DateTime(2026, 9, 25));
      expect(ranges.single.prix, 11.88);
      n.ranger(ranges);

      final relu = EtatCourses.depuisDocument(depot.lire()!);
      expect(relu.gardeManger.single.nom, 'Poitrines de poulet');
      expect(relu.achats.single.magasin, 'Maxi');
      expect(relu.liste.single.nom, 'Kiwis');
    });

    test('ouvrir, déplacer, décongeler, jeter, finir (réassort)', () {
      final depot = Depot.memoire();
      addTearDown(depot.fermer);
      final c = conteneur(depot);
      final n = c.read(coursesProvider.notifier);
      n.ranger([
        ArticleGardeManger(
          id: 'lait',
          nom: 'Lait 2 %',
          emplacement: Emplacement.frigo,
          rayon: Rayon.laitiers,
          entre: _auj,
          peremption: DateTime(2026, 10, 5),
          prix: 6.49,
          essentiel: true,
        ),
        ArticleGardeManger(
          id: 'boeuf',
          nom: 'Bœuf haché',
          emplacement: Emplacement.frigo,
          rayon: Rayon.viandes,
          entre: _auj,
          peremption: DateTime(2026, 9, 25),
          prix: 8,
        ),
      ]);
      n.ouvrir('lait');
      expect(
        c.read(coursesProvider).enReserve('lait')!.peremption,
        DateTime(2026, 9, 27),
      );
      n.deplacer('boeuf', Emplacement.congelateur);
      expect(
        c.read(coursesProvider).enReserve('boeuf')!.peremption,
        DateTime(2026, 12, 23),
      );
      n.deplacer('boeuf', Emplacement.frigo);
      expect(
        c.read(coursesProvider).enReserve('boeuf')!.peremption,
        DateTime(2026, 9, 25),
      );
      n.jeter('boeuf');
      expect(gaspillageDuMois(c.read(coursesProvider).sorties, _auj).valeur, 8);
      final revenu = n.finir('lait');
      expect(revenu?.nom, 'Lait 2 %');
      expect(revenu?.origines, [kOrigineReassort]);
      final etat = c.read(coursesProvider);
      expect(etat.gardeManger, isEmpty);
      expect(etat.liste.single.nom, 'Lait 2 %');
      expect(etat.sorties, hasLength(2));
    });

    test('la démonstration : trois aliments à consommer d’ici demain', () {
      final c = conteneur(null);
      final etat = c.read(coursesProvider);
      final urgents = aConsommerBientot(etat.gardeManger, _auj, jours: 1);
      expect(urgents.map((a) => a.nom), [
        'Épinards',
        'Yogourt grec',
        'Bananes',
      ]);
      expect(etat.achats, hasLength(8));
      expect(etat.reglages.budgetMois, 600);
    });

    test('JSON tolérant', () {
      final relu = EtatCourses.depuisDocument({
        'listeCourses': [
          42,
          {'id': 'a'},
          {
            'id': 'b',
            'nom': 'Pain',
            'rayon': 'inconnu',
            'q': [
              {'v': 2, 'u': 'kg'},
              {'v': -1, 'u': 'g'},
            ],
            'panier': {'pu': 'cher', 'n': 1},
          },
        ],
        'gardeManger': [
          {'id': 'c', 'nom': 'Lait', 'ou': 'grenier', 'peremption': 'hier'},
        ],
        'achatsAlim': [
          {'id': 'd', 'date': '2026-09-01T10:00:00.000'},
        ],
        'reglagesCourses': {
          'budget': -5,
          'rayons': ['fruits', 'rien'],
          'heure': 5000,
        },
      });
      final pain = relu.liste.single;
      expect(pain.rayon, Rayon.autre);
      expect(pain.quantites, const [Quantite(2, Unite.kg)]);
      expect(pain.panier, isNull);
      expect(relu.gardeManger.single.emplacement, Emplacement.armoire);
      expect(relu.gardeManger.single.peremption, isNull);
      expect(relu.achats, isEmpty);
      expect(relu.reglages.budgetMois, isNull);
      expect(relu.reglages.ordreRayons.first, Rayon.fruits);
      expect(relu.reglages.ordreRayons, hasLength(Rayon.values.length));
      expect(relu.reglages.heureRappel, 9 * 60);
    });
  });

  group('les rappels de péremption', () {
    late AppLocalizations tr;
    setUpAll(() async {
      tr = await AppLocalizations.delegate.load(const Locale('fr'));
    });

    test('un rappel par matin où quelque chose presse', () {
      final etat = EtatCourses(
        gardeManger: [
          ArticleGardeManger(
            id: 'y',
            nom: 'Yogourt grec',
            emplacement: Emplacement.frigo,
            rayon: Rayon.laitiers,
            entre: _auj,
            peremption: DateTime(2026, 9, 25),
          ),
          ArticleGardeManger(
            id: 'r',
            nom: 'Riz',
            emplacement: Emplacement.armoire,
            rayon: Rayon.cereales,
            entre: _auj,
            peremption: DateTime(2027, 9, 25),
          ),
        ],
      );
      // 8 h : le rappel de 9 h aujourd'hui (demain : le yogourt) et celui de
      // demain (aujourd'hui : le yogourt).
      final n = notificationsGardeManger(etat: etat, maintenant: _auj, tr: tr);
      expect(n.map((x) => x.quand.day), [24, 25]);
      expect(n.first.corps, contains('Yogourt grec'));
      expect(n.first.charge, kChargeAlimentation);
      // Coupés : rien.
      expect(
        notificationsGardeManger(
          etat: etat,
          maintenant: _auj,
          tr: tr,
          actifs: false,
        ),
        isEmpty,
      );
      expect(
        notificationsGardeManger(
          etat: etat.copierAvec(
            reglages: const ReglagesCourses(rappelsPeremption: false),
          ),
          maintenant: _auj,
          tr: tr,
        ),
        isEmpty,
      );
    });
  });
}
