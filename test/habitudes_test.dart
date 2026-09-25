// test/habitudes_test.dart
//
// Les habitudes, hors écran : les règles des séries (aujourd'hui toléré,
// jours non prévus sautés, bonus comptés), les journées complètes, les
// paliers, la libération (compteur, record, économies), la persistance
// (JSON, dépôt SQLite, premier lancement) et les notifications — dont la
// DISCRÉTION : jamais le nom de ce dont on se libère.

import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rhythm/l10n/app_localizations.dart';
import 'package:rhythm/l10n/libelles_habitudes.dart';
import 'package:rhythm/l10n/traductions.dart';
import 'package:rhythm/modele/calculs_habitudes.dart';
import 'package:rhythm/modele/depot.dart';
import 'package:rhythm/modele/etat_habitudes.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/modele/habitudes.dart';
import 'package:rhythm/systeme/rappels_habitudes.dart';
import 'package:rhythm/utils/dates.dart';

/// Le jeudi de la maquette.
final DateTime _auj = DateTime(2026, 9, 24);

DateTime _j(int decalage) => plusJours(_auj, decalage);

Habitude _h({
  Set<int> jours = const {},
  List<int> faits = const [],
  int creee = -30,
  int? rappel,
  String plan = '',
}) => Habitude(
  id: 'h',
  nom: 'Lire',
  creeLe: _j(creee),
  jours: jours,
  rappel: rappel,
  plan: plan,
  faits: {for (final d in faits) cleJour(_j(d))},
);

void main() {
  setUpAll(initializeDateFormatting);

  group('séries', () {
    test("aujourd'hui est toléré, puis compte", () {
      expect(serie(_h(faits: [-1, -2, -3]), _auj), 3);
      expect(serie(_h(faits: [0, -1, -2, -3]), _auj), 4);
      // Un trou avant-hier casse la série.
      expect(serie(_h(faits: [-1, -3]), _auj), 1);
    });

    test('un jour non prévu ne casse rien ; fait quand même, il compte', () {
      // Lundi, mercredi, vendredi ; le jeudi 24 n'est pas prévu.
      const lmv = {1, 3, 5};
      // Mer. 23, lun. 21, ven. 18 : trois de suite malgré les trous.
      expect(serie(_h(jours: lmv, faits: [-1, -3, -6]), _auj), 3);
      // Le mardi 22 (non prévu) fait en bonus s'ajoute.
      expect(serie(_h(jours: lmv, faits: [-1, -2, -3, -6]), _auj), 4);
    });

    test('rien ne compte avant la création', () {
      expect(serie(_h(faits: [-1, -2], creee: -2), _auj), 2);
      expect(record(_h(faits: [-1, -2], creee: -2), _auj), 2);
    });

    test('le record et le taux', () {
      final h = _h(faits: [-1, -2, -5, -6, -7, -8], creee: -9);
      expect(record(h, _auj), 4);
      // 9 jours prévus avant aujourd'hui (non fait : exclu), 6 faits.
      expect(taux(h, _auj), closeTo(6 / 9, 1e-9));
      expect(taux(_h(creee: 0), _auj), isNull);
    });

    test('jamais deux fois : le dernier jour prévu a sauté', () {
      final manquee = _h(faits: [-2, -3]);
      expect(manqueeHier([manquee], _auj)?.id, 'h');
      expect(
        manqueeHier([
          _h(faits: [-1]),
        ], _auj),
        isNull,
      );
      // Faite aujourd'hui : plus rien à rattraper.
      expect(
        manqueeHier([
          _h(faits: [0, -2]),
        ], _auj),
        isNull,
      );
    });
  });

  group('la démonstration retombe sur la maquette', () {
    final demo = GraineHabitudes.demonstration(_auj);

    test('4 sur 6, 12 journées complètes, record 21', () {
      final jour = journee(demo.habitudes, _auj);
      expect((jour.faites, jour.prevues), (4, 6));
      expect(serieGlobale(demo.habitudes, _auj), 12);
      expect(recordGlobal(demo.habitudes, _auj), 21);
      expect(serie(demo.habitudes.first, _auj), 35);
      expect(serie(demo.habitudes[5], _auj), 12);
    });

    test('une habitude à libérer, avec son histoire', () {
      final l = demo.aLiberer.single;
      final maintenant = DateTime(2026, 9, 24, 9, 30);
      // Rechute le 7 septembre à 21 h 30.
      expect(dureeLiberte(l, maintenant), const Duration(days: 16, hours: 12));
      // Du 15 août 8 h au 7 septembre 21 h 30.
      expect(
        recordLiberte(l, maintenant),
        const Duration(days: 23, hours: 13, minutes: 30),
      );
      expect(enviesSurmontees(l), 5);
      expect(declencheurFrequent(l), 'Après le dîner');
      expect(trancheFrequente(l), Tranche.apresMidi);
      // 40 jours et 1 h 30, moins un jour de rechute, à 4,50 $.
      expect(
        economies(l, maintenant),
        closeTo(4.5 * (40 + 1.5 / 24 - 1), 1e-6),
      );
    });
  });

  group('paliers', () {
    test('atteint exactement', () {
      expect(palierAtteint(kPaliersSerie, 7), 7);
      expect(palierAtteint(kPaliersSerie, 8), isNull);
      expect(palierAtteint(kPaliersSerie, 730), 730);
    });

    test('le prochain, et celui d’avant', () {
      expect(prochainPalier(kPaliersSerie, 0), (precedent: 0, suivant: 3));
      expect(prochainPalier(kPaliersSerie, 12), (precedent: 7, suivant: 14));
      expect(prochainPalier(kPaliersSerie, 400), (
        precedent: 365,
        suivant: 730,
      ));
      expect(prochainPalier(kPaliersLiberte, 16.5), (
        precedent: 14,
        suivant: 21,
      ));
    });
  });

  group('persistance', () {
    test('le JSON fait l’aller-retour', () {
      final demo = GraineHabitudes.demonstration(_auj);
      final document = jsonDecode(jsonEncode(demo.versDocument()));
      final relu = EtatHabitudes.depuisDocument(
        document as Map<String, dynamic>,
      );
      expect(jsonEncode(relu.versDocument()), jsonEncode(demo.versDocument()));
      expect(relu.aLiberer.single.rechutes.length, 1);
      expect(relu.reglages.bilanSoir, 21 * 60);
    });

    test('une lecture tolérante : champs absents ou abîmés', () {
      final h = Habitude.depuisJson({
        'id': 'x',
        'nom': 'Eau',
        'genre': 'inconnu',
        'jours': [1, 9, 'lundi'],
        'faits': [20260924, 'hier'],
        'envies': [
          {'quand': 'pas une date'},
          {'quand': '2026-09-20T10:00:00.000', 'intensite': 42},
        ],
      })!;
      expect(h.genre, GenreHabitude.construire);
      expect(h.jours, {1});
      expect(h.faits, {20260924});
      expect(h.envies.single.intensite, 10);
      expect(Habitude.depuisJson({'nom': 'sans id'}), isNull);
    });

    test('premier lancement : les six, sans historique, une seule fois', () {
      final depot = Depot.memoire();
      addTearDown(depot.fermer);
      ProviderContainer conteneur() => ProviderContainer(
        overrides: [
          depotProvider.overrideWithValue(depot),
          aujourdhuiProvider.overrideWithValue(_auj),
        ],
      );

      final premier = conteneur();
      final etat = premier.read(habitudesProvider);
      expect(etat.habitudes.length, 6);
      expect(etat.habitudes.every((h) => h.faits.isEmpty), isTrue);
      // Cocher, supprimer : c'est écrit.
      final notif = premier.read(habitudesProvider.notifier);
      final r = notif.basculer('hab-priere', _auj)!;
      expect((r.faite, r.serie), (true, 1));
      notif.supprimer('hab-etirements');
      premier.dispose();

      // Relu : rien n'est revenu, la coche est là.
      final second = conteneur();
      addTearDown(second.dispose);
      final relu = second.read(habitudesProvider);
      expect(relu.habitudes.length, 5);
      expect(estFaite(relu.parId('hab-priere')!, _auj), isTrue);
    });

    test('cocher avant la création la recule ; jamais un jour à venir', () {
      final conteneur = ProviderContainer(
        overrides: [aujourdhuiProvider.overrideWithValue(_auj)],
      );
      addTearDown(conteneur.dispose);
      final notif = conteneur.read(habitudesProvider.notifier);
      notif.ajouter(_h(creee: 0));
      expect(notif.basculer('h', _j(1)), isNull);
      notif.basculer('h', _j(-3));
      expect(conteneur.read(habitudesProvider).parId('h')!.creeLe, _j(-3));
    });

    test('une envie non tenue est une rechute', () {
      final conteneur = ProviderContainer(
        overrides: [aujourdhuiProvider.overrideWithValue(_auj)],
      );
      addTearDown(conteneur.dispose);
      final notif = conteneur.read(habitudesProvider.notifier);
      final quand = DateTime(2026, 9, 24, 15);
      notif.noterEnvie(
        'hab-energisantes',
        Envie(quand: quand, intensite: 8, tenue: false),
      );
      final l = conteneur.read(habitudesProvider).parId('hab-energisantes')!;
      expect(l.debutLiberte, quand);
      expect(
        dureeLiberte(l, DateTime(2026, 9, 24, 16)),
        const Duration(hours: 1),
      );
    });
  });

  group('notifications', () {
    final tr = lookupAppLocalizations(const Locale('fr'));
    const f = Formats('fr');
    final maintenant = DateTime(2026, 9, 24, 8);

    List<dynamic> notifs(EtatHabitudes etat) => notificationsHabitudes(
      etat: etat,
      maintenant: maintenant,
      tr: tr,
      formats: f,
    );

    test('le rappel : les jours prévus, pas si c’est déjà fait', () {
      final etat = EtatHabitudes(
        habitudes: [
          _h(
            rappel: 20 * 60,
            faits: [0, -1, -2],
            plan: 'Quand je me couche, je lis.',
          ),
        ],
      );
      final liste = notificationsHabitudes(
        etat: etat,
        maintenant: maintenant,
        tr: tr,
        formats: f,
      );
      // Faite aujourd'hui : demain et les huit jours suivants.
      expect(liste.length, kJoursPlanifies - 1);
      expect(liste.first.quand, DateTime(2026, 9, 25, 20));
      expect(liste.first.titre, 'Lire');
      expect(liste.first.corps, 'Quand je me couche, je lis.');
      expect(liste.map((n) => n.id).toSet().length, liste.length);
    });

    test('aujourd’hui, le rappel parle de la série', () {
      final h = _h(rappel: 20 * 60, faits: [-1, -2, -3]);
      expect(
        corpsRappel(h, aujourdhui: _auj, tr: tr),
        'Série de 3 jours — garde le rythme.',
      );
      expect(corpsRappel(h, aujourdhui: null, tr: tr), tr.notifGenerique);
    });

    test('le bilan du soir nomme ce qui reste', () {
      final demo = GraineHabitudes.demonstration(_auj);
      final bilan = notifs(demo).where((n) => n.titre == 'Bilan du soir');
      expect(
        bilan.first.corps,
        'Il te reste 2 habitudes : Pas d\'écran après 23 h, Étirements.',
      );
    });

    test('libération : discret, jamais son nom', () {
      final demo = GraineHabitudes.demonstration(_auj);
      final l = demo.aLiberer.single;
      final soutien = notifs(demo).where((n) => n.canal.prive).toList();
      expect(soutien, isNotEmpty);
      for (final n in soutien) {
        expect(n.titre.contains(l.nom), isFalse);
        expect(n.corps.contains(l.nom), isFalse);
        expect(n.corps.toLowerCase().contains('énergisante'), isFalse);
      }
      // Le palier de 21 jours tombe le 28 septembre à 21 h 30.
      final palier = soutien.where((n) => n.titre == tr.notifPalierTitre);
      expect(palier.single.quand, DateTime(2026, 9, 28, 21, 30));
      expect(palier.single.corps, '3 semaines — bravo. Continue.');
    });

    test('l’interrupteur général coupe tout', () {
      final demo = GraineHabitudes.demonstration(_auj);
      final coupe = demo.copierAvec(
        reglages: demo.reglages.copierAvec(rappels: false),
      );
      expect(notifs(coupe), isEmpty);
    });

    test('un identifiant stable par habitude et par jour', () {
      expect(idRappel('hab-priere', 0), idRappel('hab-priere', 0));
      expect(idRappel('hab-priere', 0), isNot(idRappel('hab-priere', 1)));
      expect(idRappel('hab-priere', 0), isNot(idRappel('hab-eau', 0)));
      expect(idRappel('hab-priere', 15), lessThan(1 << 31));
    });
  });

  group('le mot du jour', () {
    final tr = lookupAppLocalizations(const Locale('fr'));

    test('un palier atteint aujourd’hui passe avant tout', () {
      final etat = EtatHabitudes(
        habitudes: [
          _h(faits: [0, -1, -2, -3, -4, -5, -6]),
        ],
      );
      expect(
        motDuJour(tr, etat, DateTime(2026, 9, 24, 9)),
        tr.coachPalier7('Lire'),
      );
    });

    test('jamais deux fois, puis le moment de la journée', () {
      final manquee = EtatHabitudes(
        habitudes: [
          _h(faits: [-2, -3]),
        ],
      );
      final mot = motDuJour(tr, manquee, DateTime(2026, 9, 24, 9))!;
      expect(mot.contains('Lire'), isTrue);
      final nuit = motDuJour(tr, manquee, DateTime(2026, 9, 24, 23, 30));
      expect(nuit, tr.coachNuit);
      expect(motDuJour(tr, const EtatHabitudes(), _auj), tr.coachAucune);
    });
  });

  group('l’ordre', () {
    Habitude h(String id, {int? rappel}) =>
        Habitude(id: id, nom: id, creeLe: _auj, rappel: rappel);
    final a = h('a', rappel: 20 * 60), b = h('b'), c = h('c', rappel: 7 * 60);
    final d = h('d', rappel: 7 * 60), e = h('e');
    List<String> ids(List<Habitude> l) => [for (final x in l) x.id];

    test('mon ordre, par heure, l’épinglée toujours en tête', () {
      expect(ids(ordonner([a, b, c, d], const ReglagesHabitudes())), [
        'a',
        'b',
        'c',
        'd',
      ]);
      const parHeure = ReglagesHabitudes(tri: TriHabitudes.rappel);
      // Par heure : 7 h (dans leur ordre), 20 h, puis sans rappel.
      expect(ids(ordonner([a, b, c, d], parHeure)), ['c', 'd', 'a', 'b']);
      expect(
        ids(ordonner([a, b, c, d], parHeure.copierAvec(epinglee: () => 'b'))),
        ['b', 'c', 'd', 'a'],
      );
    });

    test('réordonner une partie : les autres gardent leur place', () {
      // Affichées : b, d, e — déplacées en e, b, d.
      expect(ids(reordonnerListe([a, b, c, d, e], ['e', 'b', 'd'])), [
        'a',
        'e',
        'c',
        'b',
        'd',
      ]);
    });

    test('l’ordre et l’épingle sont écrits ; supprimer désépingle', () {
      final depot = Depot.memoire();
      addTearDown(depot.fermer);
      ProviderContainer conteneur() => ProviderContainer(
        overrides: [
          depotProvider.overrideWithValue(depot),
          aujourdhuiProvider.overrideWithValue(_auj),
        ],
      );
      final premier = conteneur();
      final notif = premier.read(habitudesProvider.notifier);
      notif.reordonner(['hab-etirements', 'hab-priere']);
      notif.trier(TriHabitudes.rappel);
      notif.epingler('hab-eau');
      premier.dispose();

      final second = conteneur();
      addTearDown(second.dispose);
      final etat = second.read(habitudesProvider);
      expect(etat.habitudes.first.id, 'hab-etirements');
      expect(etat.reglages.tri, TriHabitudes.rappel);
      expect(etat.reglages.epinglee, 'hab-eau');
      second.read(habitudesProvider.notifier).supprimer('hab-eau');
      expect(second.read(habitudesProvider).reglages.epinglee, isNull);
    });

    test('une rechute notée par erreur, retirée : le compteur revient', () {
      final conteneur = ProviderContainer(
        overrides: [aujourdhuiProvider.overrideWithValue(_auj)],
      );
      addTearDown(conteneur.dispose);
      final notif = conteneur.read(habitudesProvider.notifier);
      final avant = conteneur
          .read(habitudesProvider)
          .parId('hab-energisantes')!
          .debutLiberte;
      notif.noterEnvie(
        'hab-energisantes',
        Envie(quand: DateTime(2026, 9, 24, 15), tenue: false),
      );
      final erreur = conteneur
          .read(habitudesProvider)
          .parId('hab-energisantes')!
          .envies
          .last;
      notif.retirerEnvie('hab-energisantes', erreur);
      final l = conteneur.read(habitudesProvider).parId('hab-energisantes')!;
      expect(l.debutLiberte, avant);
      expect(l.envies.length, 6);
    });
  });
}
