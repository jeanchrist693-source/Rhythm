// test/sports_test.dart
//
// Les Sports : la banque (cohérence), puis les règles d'entraînement
// (dosage, ordre, échauffement, progression, records, récupération,
// statistiques) — des fonctions pures.

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/l10n/app_localizations.dart';
import 'package:rhythm/modele/calculs_habitudes.dart';
import 'package:rhythm/modele/depot.dart';
import 'package:rhythm/modele/etat_habitudes.dart';
import 'package:rhythm/modele/etat_sante.dart';
import 'package:rhythm/modele/sports/calculs_sport.dart';
import 'package:rhythm/modele/sports/catalogue.dart';
import 'package:rhythm/modele/sports/deroulement.dart';
import 'package:rhythm/modele/sports/etat_sport.dart';
import 'package:rhythm/modele/sports/exercices.dart';
import 'package:rhythm/modele/sports/muscles.dart';
import 'package:rhythm/modele/sports/plans.dart';
import 'package:rhythm/modele/sports/sport.dart';
import 'package:rhythm/systeme/rappels_sport.dart';
import 'package:rhythm/utils/dates.dart';
import 'package:rhythm/widgets/corps/animations_corps.dart';

/// Jeudi 24 septembre 2026, 8 h (la maquette).
final DateTime _auj = DateTime(2026, 9, 24, 8);

SerieFaite _r(int reps, [double? charge, Ressenti? ressenti]) =>
    SerieFaite(reps: reps, charge: charge, ressenti: ressenti);

SeanceFaite _seance(
  String id,
  DateTime debut,
  List<ExerciceFait> exercices, {
  int minutes = 45,
  String? programme,
}) => SeanceFaite(
  id: id,
  nom: 'Test',
  debut: debut,
  dureeSec: minutes * 60,
  style: StyleSport.musculation,
  exercices: exercices,
  kcal: minutes * 8,
  programmeId: programme,
);

void main() {
  group('la banque', () {
    test('plus de 250 exercices, identifiants uniques', () {
      final ids = Catalogue.tous.map((e) => e.id).toList();
      expect(ids.length, greaterThanOrEqualTo(250));
      expect(ids.toSet().length, ids.length, reason: 'id en double');
    });

    test('chaque exercice a un corps animé, des étapes et des erreurs', () {
      for (final e in Catalogue.tous) {
        expect(
          Mouvements.de(e.mouvement),
          isNotNull,
          reason: '${e.id} : mouvement « ${e.mouvement} » inconnu',
        );
        expect(e.principaux, isNotEmpty, reason: e.id);
        expect(e.etapes.length, greaterThanOrEqualTo(3), reason: e.id);
        expect(e.erreurs.length, greaterThanOrEqualTo(2), reason: e.id);
      }
    });

    test('les chaînes de variantes : des exercices connus, une seule fois', () {
      final vus = <String>{};
      for (final c in Catalogue.chaines) {
        for (final id in c) {
          expect(Catalogue.de(id), isNotNull, reason: id);
          expect(vus.add(id), isTrue, reason: '$id dans deux chaînes');
        }
      }
      expect(Catalogue.plusFacile('pompe')!.id, 'pompe_genoux');
      expect(Catalogue.plusDur('pompe')!.id, 'pompe_declinee');
      expect(Catalogue.plusFacile('pompe_murale'), isNull);
    });

    test('tous les styles et tout le matériel sont couverts', () {
      for (final s in StyleSport.values) {
        expect(
          Catalogue.tous.where((e) => e.style == s).length,
          greaterThanOrEqualTo(10),
          reason: s.name,
        );
      }
      for (final m in Materiel.values) {
        expect(
          Catalogue.tous.any((e) => e.materiel.contains(m)),
          isTrue,
          reason: m.name,
        );
      }
      // Avec des haltères seulement, il y a de quoi faire.
      final halteres = Catalogue.tous
          .where((e) => e.faisableAvec({Materiel.halteres}))
          .length;
      expect(halteres, greaterThan(150));
    });
  });

  group("les règles d'entraînement", () {
    test("le dosage suit l'objectif", () {
      final squat = Catalogue.de('squat_goblet')!;
      final force = doser(squat, Objectif.force);
      final volume = doser(squat, Objectif.volume);
      final endurance = doser(squat, Objectif.endurance);
      expect(force.reps, inInclusiveRange(4, 6));
      expect(volume.reps, inInclusiveRange(8, 12));
      expect(endurance.reps, inInclusiveRange(15, 20));
      expect(force.repos, greaterThan(volume.repos));
      expect(volume.repos, inInclusiveRange(60, 90));
      expect(endurance.repos, lessThan(volume.repos));
      // Un exercice en durée se dose en secondes.
      final planche = doser(Catalogue.de('planche')!, Objectif.volume);
      expect(planche.secondes, isNotNull);
      expect(planche.reps, isNull);
    });

    test("l'ordre : polyarticulaires et lourds d'abord, gainage à la fin", () {
      final lignes = [
        for (final id in [
          'planche',
          'curl',
          'elevation_laterale',
          'squat_barre',
          'developpe_couche',
          'rowing_un_bras',
        ])
          doser(Catalogue.de(id)!, Objectif.volume),
      ];
      final ordre = organiser(lignes).map((l) => l.exercice).toList();
      expect(ordre.first, 'squat_barre');
      expect(ordre.last, 'planche');
      expect(
        ordre.indexOf('developpe_couche'),
        lessThan(ordre.indexOf('curl')),
      );
      expect(
        ordre.indexOf('rowing_un_bras'),
        lessThan(ordre.indexOf('elevation_laterale')),
      );
    });

    test("les exercices opposés s'enchaînent en paires sans repos", () {
      final lignes = [
        for (final id in [
          'developpe_couche',
          'rowing_un_bras',
          'curl',
          'kickback',
        ])
          doser(Catalogue.de(id)!, Objectif.volume),
      ];
      final r = organiser(lignes, enchainer: true);
      final dc = r.indexWhere((l) => l.exercice == 'developpe_couche');
      expect(r[dc].groupe, isNotNull);
      expect(r[dc + 1].exercice, 'rowing_un_bras');
      expect(r[dc + 1].groupe, r[dc].groupe);
      expect(r[dc].repos, 15, reason: 'pas de vrai repos entre A1 et A2');
      final curl = r.indexWhere((l) => l.exercice == 'curl');
      expect(r[curl + 1].exercice, 'kickback');

      // Le déroulé alterne A1 / A2.
      final etapes = etapesDe(r);
      expect(etapes.take(4).map((e) => r[e.ligne].exercice), [
        'developpe_couche',
        'rowing_un_bras',
        'developpe_couche',
        'rowing_un_bras',
      ]);
      expect(reposApres(etapes, 0, r), 15);
      expect(reposApres(etapes, 1, r), greaterThan(15));
      expect(reposApres(etapes, etapes.length - 1, r), 0);
      // Passer un exercice saute toutes ses séries.
      final sansRowing = suivante(etapes, 0, {etapes[1].ligne});
      expect(r[etapes[sansRowing].ligne].exercice, 'developpe_couche');
    });

    test(
      'échauffement selon les articulations, retour au calme selon les muscles',
      () {
        final haut = echauffement(['developpe_couche', 'curl']);
        expect(haut.first.exercice, 'jumping_jack');
        expect(haut.map((l) => l.exercice), contains('cercles_bras'));
        expect(haut.every((l) => l.role == RoleLigne.echauffement), isTrue);
        final bas = echauffement(['squat_barre']);
        expect(bas.first.exercice, 'montees_genoux');
        expect(bas.map((l) => l.exercice), contains('rotation_hanches'));

        final calme = retourAuCalme([
          doser(Catalogue.de('squat_barre')!, Objectif.volume),
        ]);
        expect(calme.map((l) => l.exercice), contains('etirement_quadriceps'));
        expect(calme.every((l) => l.role == RoleLigne.retourCalme), isTrue);
      },
    );

    test('« Compléter » : équilibré, avec son matériel, sans les muscles '
        'en récupération', () {
      final r = completer(
        zones: {Muscle.pectoraux, Muscle.dos},
        deja: const [],
        materiel: {Materiel.halteres},
        niveau: Niveau.intermediaire,
      );
      expect(r, isNotEmpty);
      final exos = r.map((id) => Catalogue.de(id)!).toList();
      expect(exos.every((e) => e.faisableAvec({Materiel.halteres})), isTrue);
      expect(exos.any((e) => e.principaux.contains(Muscle.pectoraux)), isTrue);
      expect(exos.any((e) => e.principaux.contains(Muscle.dos)), isTrue);
      expect(exos.first.poly, isTrue);

      final sansPecs = completer(
        zones: const {},
        deja: const [],
        materiel: {Materiel.halteres},
        niveau: Niveau.intermediaire,
        enRecuperation: {Muscle.pectoraux},
      );
      expect(
        sansPecs.every(
          (id) => !Catalogue.de(id)!.principaux.contains(Muscle.pectoraux),
        ),
        isTrue,
      );
      // Débutant : rien d'avancé.
      final debutant = completer(
        zones: const {},
        deja: const [],
        materiel: const {},
        niveau: Niveau.debutant,
      );
      expect(
        debutant.every((id) => Catalogue.de(id)!.niveau == Niveau.debutant),
        isTrue,
      );
    });

    test('la séance construite : échauffement, travail, retour au calme', () {
      final lignes = construireSeance([
        'developpe_sol',
        'rowing_un_bras',
        'planche',
      ], objectif: Objectif.volume);
      expect(lignes.first.role, RoleLigne.echauffement);
      expect(lignes.last.role, RoleLigne.retourCalme);
      final travail = lignes.where((l) => l.role == RoleLigne.travail).toList();
      expect(travail.length, 3);
      expect(travail.last.exercice, 'planche');
      final minutes = dureeEstimee(lignes).inMinutes;
      expect(minutes, inInclusiveRange(20, 50));
      final series = seriesParMuscle(lignes);
      expect(series[Muscle.pectoraux], greaterThanOrEqualTo(4));
    });

    test('la progression automatique (double progression)', () {
      final e = Catalogue.de('developpe_sol')!;
      final ligne = doser(e, Objectif.volume).copierAvec(reps: () => 10);
      SeanceFaite fois(List<SerieFaite> s, {int cible = 10}) => _seance(
        'x',
        _auj.subtract(const Duration(days: 3)),
        [ExerciceFait(exercice: e.id, series: s, cibleReps: cible)],
      );

      // Première fois.
      expect(
        proposer(ligne, e, const [], Objectif.volume).progres,
        Progres.premiereFois,
      );
      // Tout réussi : une répétition de plus, même charge.
      var p = proposer(ligne, e, [
        fois([_r(10, 20), _r(10, 20), _r(10, 20)]),
      ], Objectif.volume);
      expect(p.progres, Progres.repDePlus);
      expect(p.reps, 11);
      expect(p.charge, 20);
      // En haut de la plage : plus lourd, retour en bas de la plage.
      p = proposer(ligne, e, [
        fois([_r(12, 20), _r(12, 20), _r(12, 20)], cible: 12),
      ], Objectif.volume);
      expect(p.progres, Progres.plusDeCharge);
      expect(p.charge, 22);
      expect(p.reps, Objectif.volume.repsMin);
      // Un échec : pareil.
      p = proposer(ligne, e, [
        fois([_r(10, 20), _r(8, 20, Ressenti.echec)]),
      ], Objectif.volume);
      expect(p.progres, Progres.pareil);
      expect(p.reps, 10);
      // En durée : 5 secondes de plus.
      final planche = Catalogue.de('planche')!;
      final lp = doser(planche, Objectif.volume);
      p = proposer(lp, planche, [
        _seance('y', _auj, [
          ExerciceFait(
            exercice: 'planche',
            series: [
              SerieFaite(secondes: lp.secondes),
              SerieFaite(secondes: lp.secondes),
            ],
          ),
        ]),
      ], Objectif.volume);
      expect(p.progres, Progres.plusLong);
      expect(p.secondes, lp.secondes! + 5);
    });

    test('les records : charge, répétitions, force estimée, battus', () {
      final avant = [
        _seance('a', DateTime(2026, 9, 1), [
          ExerciceFait(
            exercice: 'developpe_couche_barre',
            series: [_r(8, 55), _r(8, 55)],
          ),
        ]),
      ];
      final r = recordsDe('developpe_couche_barre', avant);
      expect(r.charge, 55);
      expect(r.reps, 8);
      expect(r.force, closeTo(55 * (1 + 8 / 30), 0.01));

      final nouvelle = _seance('b', DateTime(2026, 9, 8), [
        ExerciceFait(
          exercice: 'developpe_couche_barre',
          series: [_r(8, 60), _r(6, 60)],
        ),
      ]);
      final battus = recordsBattus(nouvelle, avant);
      expect(battus.map((b) => b.type), contains(TypeRecord.charge));
      expect(battus.firstWhere((b) => b.type == TypeRecord.charge).valeur, 60);
      // La première fois n'est pas un record.
      expect(recordsBattus(avant.first, const []), isEmpty);
    });

    test('la récupération : 48 h après un travail lourd', () {
      final bas = _seance('b', _auj.subtract(const Duration(hours: 20)), [
        ExerciceFait(
          exercice: 'squat_barre',
          series: [_r(8, 70), _r(8, 70), _r(8, 70)],
        ),
        ExerciceFait(exercice: 'curl', series: [_r(10, 10)]),
      ]);
      final r = enRecuperation([bas], _auj);
      expect(r.keys, containsAll([Muscle.quadriceps, Muscle.fessiers]));
      expect(r.containsKey(Muscle.biceps), isFalse, reason: 'une seule série');
      expect(r[Muscle.quadriceps], bas.fin.add(const Duration(hours: 48)));
      expect(
        enRecuperation([bas], _auj.add(const Duration(hours: 40))),
        isEmpty,
      );
    });

    test('la démonstration retombe sur la maquette', () {
      final demo = GraineSport.demonstration(_auj);
      final s = semaineDe(demo.journal, _auj);
      expect(s.minutes, [45, 0, 60, 42, null, null, null]);
      expect(s.seances, 3);
      expect(s.kcal, 1180);
      expect(serieSemaines(demo.journal, _auj), 5);
      final jour = seanceDuJour(demo.programmes, demo.journal, _auj);
      expect(jour?.nom, 'Haut du corps');
      final prochaine = prochaineSeance(demo.programmes, demo.journal, _auj)!;
      expect(prochaine.$2, DateTime(2026, 9, 24, 18));
      // Mercredi, le bas du corps : jambes en récupération jeudi matin.
      expect(
        enRecuperation(demo.journal, _auj).keys,
        contains(Muscle.quadriceps),
      );
    });

    test('les statistiques sur 30 jours et les muscles négligés', () {
      final demo = GraineSport.demonstration(_auj);
      final s = stats30(demo.journal, _auj);
      expect(s.minutes.length, 30);
      expect(s.minutes.last, 42);
      expect(s.totalSeances, greaterThan(8));
      expect(s.seancesAvant, greaterThan(0));
      expect(s.parStyle[StyleSport.musculation], greaterThan(0));
      expect(s.records, isNotEmpty, reason: 'les charges montent');
      // La démo travaille tout (en principal ou en secondaire).
      expect(musclesNegliges(s, _auj), isEmpty);

      // Rien que des jambes depuis neuf jours : le haut est « à ne pas
      // oublier », le dos depuis neuf jours, le reste jamais.
      final jambes = [
        _seance('d', _auj.subtract(const Duration(days: 9)), [
          ExerciceFait(exercice: 'rowing_un_bras', series: [_r(10, 20)]),
        ]),
        _seance('j', _auj.subtract(const Duration(days: 1)), [
          ExerciceFait(exercice: 'squat_barre', series: [_r(8, 70)]),
          ExerciceFait(exercice: 'mollets_debout', series: [_r(15)]),
          ExerciceFait(exercice: 'planche', series: [SerieFaite(secondes: 40)]),
        ]),
      ];
      final n = musclesNegliges(stats30(jambes, _auj), _auj);
      final muscles = n.map((x) => x.$1).toList();
      expect(muscles, containsAll([Muscle.pectoraux, Muscle.dos]));
      expect(muscles, isNot(contains(Muscle.quadriceps)));
      expect(n.firstWhere((x) => x.$1 == Muscle.dos).$2, 9);
      expect(n.firstWhere((x) => x.$1 == Muscle.pectoraux).$2, isNull);
    });

    test('les défis, les programmes de course, les routines sont complets', () {
      for (final d in Defis.tous) {
        expect(d.etapes, 12, reason: d.id);
        expect(Catalogue.de(d.exercice), isNotNull, reason: d.id);
      }
      expect(Defis.total(Defis.de('pompes100')!.series.last), 100);
      expect(Defis.de('gainage3')!.series.last, [180]);
      for (final p in ProgrammesCourse.tous) {
        expect(p.seances.length % 3, 0, reason: p.id);
        expect(Catalogue.de(p.activite), isNotNull, reason: p.id);
      }
      expect(ProgrammesCourse.de('courir30')!.semaines, 8);
      final dernier = ProgrammesCourse.de('courir30')!.seances.last;
      expect(dernier.effort, 30 * 60);
      for (final r in Routines.tous) {
        expect(r.total, inInclusiveRange(240, 360), reason: r.id);
        for (final (id, _) in r.etapes) {
          expect(Catalogue.de(id), isNotNull, reason: id);
        }
      }
    });
  });

  group("l'état des sports", () {
    test('JSON : un aller-retour sans perte, un document abîmé tolérés', () {
      final demo = GraineSport.demonstration(_auj);
      final relu = EtatSport.depuisDocument(demo.versDocument());
      expect(relu.journal.length, demo.journal.length);
      expect(
        relu.programmes.first.lignes.length,
        demo.programmes.first.lignes.length,
      );
      expect(relu.profil.materiel, demo.profil.materiel);
      expect(relu.mesures.length, demo.mesures.length);
      expect(relu.defis.first.faites, demo.defis.first.faites);
      expect(
        relu.journal.last.exercices.length,
        demo.journal.last.exercices.length,
      );
      final abime = EtatSport.depuisDocument({
        'journalSport': [
          {'id': 'x'},
          42,
          {'id': 'y', 'debut': '2026-09-01T10:00:00', 'dureeSec': 'mauvais'},
        ],
        'profilSport': 'mauvais',
      });
      expect(abime.journal.length, 1);
      expect(abime.profil.objectif, Objectif.volume);
    });

    test('le dépôt : premier lancement une fois, séance persistée', () {
      final depot = Depot.memoire();
      addTearDown(depot.fermer);
      ProviderContainer conteneur() => ProviderContainer(
        overrides: [
          depotProvider.overrideWithValue(depot),
          aujourdhuiProvider.overrideWithValue(_auj),
        ],
      );
      final a = conteneur();
      final etat = a.read(sportProvider);
      expect(etat.programmes.single.nom, 'Haut du corps');
      expect(etat.journal, isEmpty);
      expect(etat.profil.materiel, {Materiel.halteres});
      final n = a.read(sportProvider.notifier);
      n.enregistrerSeance(
        _seance('s1', _auj, [
          ExerciceFait(exercice: 'curl', series: [_r(10, 10)]),
        ]),
      );
      n.supprimerProgramme(etat.programmes.single.id);
      a.dispose();

      final b = conteneur();
      addTearDown(b.dispose);
      expect(b.read(sportProvider).journal.single.id, 's1');
      expect(
        b.read(sportProvider).programmes,
        isEmpty,
        reason: 'la graine ne revient pas',
      );
    });

    test("une séance enregistrée coche l'habitude « Entraînement »", () {
      final c = ProviderContainer(
        overrides: [aujourdhuiProvider.overrideWithValue(_auj)],
      );
      addTearDown(c.dispose);
      final jour = jourDe(_auj);
      final h = c.read(habitudesProvider).parId('hab-entrainement')!;
      if (estFaite(h, jour)) {
        c.read(habitudesProvider.notifier).basculer(h.id, jour);
      }
      final r = c
          .read(sportProvider.notifier)
          .enregistrerSeance(
            _seance('s', _auj, [
              ExerciceFait(exercice: 'curl', series: [_r(10, 10)]),
            ]),
          );
      expect(r.habitudeCochee, 'Entraînement');
      expect(
        estFaite(c.read(habitudesProvider).parId('hab-entrainement')!, jour),
        isTrue,
      );
      // Une seconde séance ne la décoche pas.
      final r2 = c
          .read(sportProvider.notifier)
          .enregistrerSeance(
            _seance('s2', _auj.add(const Duration(hours: 2)), const []),
          );
      expect(r2.habitudeCochee, isNull);
      expect(
        estFaite(c.read(habitudesProvider).parId('hab-entrainement')!, jour),
        isTrue,
      );
    });

    test('une séance de défi valide son étape', () {
      final c = ProviderContainer(
        overrides: [aujourdhuiProvider.overrideWithValue(_auj)],
      );
      addTearDown(c.dispose);
      final n = c.read(sportProvider.notifier);
      n.commencerDefi('squats150', _auj);
      final r = n.enregistrerSeance(
        SeanceFaite(
          id: 'd',
          nom: '150 squats',
          debut: _auj,
          dureeSec: 600,
          style: StyleSport.poidsDuCorps,
          defi: 'squats150',
          etape: 0,
        ),
      );
      expect(r.etapeValidee, isTrue);
      expect(c.read(sportProvider).defi('squats150')!.faites, {0});
    });

    test(
      "les rappels de séance : à l'heure, les jours prévus, pas si faite",
      () {
        final tr = lookupAppLocalizations(const Locale('fr'));
        final p = Programme(
          id: 'p',
          nom: 'Haut du corps',
          lignes: construireSeance(['curl'], objectif: Objectif.volume),
          jours: const {4},
          heure: 18 * 60,
          rappel: true,
          creeLe: _auj,
        );
        var etat = EtatSport(programmes: [p]);
        final notifs = notificationsSport(etat: etat, maintenant: _auj, tr: tr);
        expect(notifs.first.quand, DateTime(2026, 9, 24, 18));
        expect(notifs.every((n) => n.quand.weekday == 4), isTrue);
        expect(notifs.first.titre, 'Haut du corps');
        expect(notifs.first.charge, kChargeSports);
        // Déjà faite aujourd'hui : pas de rappel aujourd'hui.
        etat = etat.copierAvec(
          journal: [_seance('f', _auj, const [], programme: 'p')],
        );
        final apres = notificationsSport(etat: etat, maintenant: _auj, tr: tr);
        expect(apres.first.quand, DateTime(2026, 10, 1, 18));
        // Interrupteur général coupé : rien.
        expect(
          notificationsSport(
            etat: etat,
            maintenant: _auj,
            tr: tr,
            actifs: false,
          ),
          isEmpty,
        );
      },
    );
  });
}
