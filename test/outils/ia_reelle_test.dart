// test/outils/ia_reelle_test.dart
//
// L'assistant de l'Alimentation face au VRAI Groq (palier 4) : chaque
// demande de l'app part une fois, avec la vraie base du FCÉN, et le test
// écrit ce qui revient — le temps de réponse, les recettes, et pour chaque
// aliment ce que la base en a fait (l'aliment trouvé, la quantité, ses
// calories face à l'estimation de l'IA, ou « HORS BASE »). Ce qu'il faut
// JUGER à l'œil : la qualité, la correspondance, les délais. Hors de la
// suite (il consomme le quota gratuit) :
//   flutter test --dart-define=IA_REELLE=true --dart-define-from-file=cles.json test/outils/ia_reelle_test.dart

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/ia/cles_api.dart';
import 'package:rhythm/ia/ia_alimentation.dart';
import 'package:rhythm/modele/alimentation/alimentation.dart';
import 'package:rhythm/modele/alimentation/base_aliments.dart';
import 'package:rhythm/modele/alimentation/bilan_semaine.dart';
import 'package:rhythm/modele/alimentation/correspondance.dart';
import 'package:rhythm/modele/alimentation/courses.dart';
import 'package:rhythm/modele/alimentation/etat_recettes.dart';
import 'package:rhythm/modele/alimentation/nutriments.dart';
import 'package:rhythm/modele/alimentation/recettes.dart';
import 'package:rhythm/modele/modeles.dart';

const _reel = bool.fromEnvironment('IA_REELLE');
const _long = Timeout(Duration(minutes: 4));

final DateTime _maintenant = DateTime(2026, 9, 25, 17, 30);
late final BaseAliments _base;
late final List<Recette> _livre;

// ignore: avoid_print
void _ecrire(Object o) => print(o);

String _q(Ingredient i) {
  final g = i.grammes == null ? '' : '${i.grammes!.round()} g';
  if (i.mesure == null) return g;
  final n = i.nombre == null ? '' : '${(i.nombre! * 100).round() / 100} × ';
  return '$n${i.mesure} ($g)';
}

void _ecrireCorrespondances(List<Correspondance> cs) {
  var hors = 0;
  for (final c in cs) {
    final i = c.ingredient;
    if (c.propose.libre) {
      _ecrire('    · ${i.nom} — libre');
      continue;
    }
    if (c.horsBase) {
      hors++;
      _ecrire(
        '    ✗ ${i.nom} — HORS BASE (mots-clés : ${c.propose.recherche})',
      );
      continue;
    }
    final ia = c.propose.kcal?.round();
    final base = c.nutriments.kcal.round();
    final ecart = ia == null || ia == 0
        ? ''
        : (base / ia > 1.6 || base / ia < 0.6)
        ? '   ⚠ écart'
        : '';
    _ecrire(
      '    ✓ ${i.nom} → « ${c.aliment!.nom} » ${_q(i)} : '
      '$base kcal (IA $ia)$ecart',
    );
  }
  _ecrire('    → ${cs.length} aliments, $hors hors base');
}

void _ecrireRecette(RecetteProposee r) {
  _ecrire(
    '  « ${r.nom} » — ${r.region ?? 'sans région'}, '
    '${r.moments.map((m) => m.name).join('/')}, ${r.portions} portions, '
    '${r.preparation ?? '?'} + ${r.cuisson ?? '?'} min'
    '${r.seCongele ? ', se congèle' : ''}',
  );
  if (r.description case final d?) _ecrire('    $d');
  final cs = r.correspondances(_base);
  _ecrireCorrespondances(cs);
  final recette = r.versRecette(cs, id: 'essai', creee: _maintenant);
  final p = recette.parPortion;
  _ecrire(
    '    par portion (base) : ${p.kcal.round()} kcal, '
    '${p.proteines.round()} g prot., ${p.glucides.round()} g gluc., '
    '${p.lipides.round()} g lip.',
  );
  for (final (n, e) in r.etapes.indexed) {
    _ecrire('    ${n + 1}. $e');
  }
  if (r.note case final n?) _ecrire('    Note : $n');
}

Future<T> _chrono<T>(String titre, Future<T> Function() f) async {
  _ecrire('\n═══ $titre');
  final debut = DateTime.now();
  try {
    return await f();
  } finally {
    final ms = DateTime.now().difference(debut).inMilliseconds;
    _ecrire('  ⏱ ${(ms / 100).round() / 10} s');
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = null;
    _base = BaseAliments.analyser(
      File('assets/donnees/fcen.txt').readAsStringSync(),
    );
    _livre = GraineRecettes.depart(_maintenant);
  });
  // Espacées comme un vrai usage : le palier gratuit, 8 000 jetons par
  // minute et par modèle (une demande d'idées en prend 5 000 à 6 000).
  tearDown(() => Future<void>.delayed(const Duration(seconds: 20)));

  group('l\'IA réelle', skip: !_reel || kCleGroq.isEmpty, () {
    test('idées : Afrique de l\'Ouest, souper, plat', timeout: _long, () async {
      final r = await _chrono(
        'Idées — Afrique de l\'Ouest, souper, plat, 4 portions',
        () => idees(
          DemandeIdees(
            region: "Afrique de l'Ouest",
            moment: MomentRepas.souper,
            genre: GenrePlat.plat,
            aEviter: [for (final r in _livre) r.nom],
          ),
        ),
      );
      expect(r, isNotEmpty);
      r.forEach(_ecrireRecette);
    });

    test(
      'idées : anti-gaspillage, rapide, végétarien',
      timeout: _long,
      () async {
        final r = await _chrono(
          'Idées — anti-gaspillage (épinards, yogourt grec), rapide, végé',
          () => idees(
            const DemandeIdees(
              rapide: true,
              vegetarien: true,
              portions: 2,
              aUtiliser: ['Épinards', 'Yogourt grec'],
              gardeManger: ['Oeufs', 'Riz basmati', 'Oignons', 'Fromage feta'],
            ),
          ),
        );
        expect(r, isNotEmpty);
        r.forEach(_ecrireRecette);
      },
    );

    test(
      'importer une recette collée (unités impériales)',
      timeout: _long,
      () async {
        final r = await _chrono(
          'Importer — soupe aux pois (tasses, livres)',
          () => importer('''
Soupe aux pois de grand-maman
Pour 6 personnes
Ingrédients :
- 2 tasses de pois jaunes secs
- 1 lb de jambon fumé en cubes
- 1 oignon haché
- 2 carottes en dés
- 1 branche de céleri
- 10 tasses d'eau
- 2 feuilles de laurier
- 1 c. à thé de sarriette
Préparation :
Faire tremper les pois toute la nuit. Rincer.
Mettre tous les ingrédients dans une grande casserole et porter à ébullition.
Laisser mijoter 2 heures à feu doux en brassant de temps en temps.
Retirer le laurier, saler et poivrer au goût.
'''),
        );
        expect(r, isNotNull);
        _ecrireRecette(r!);
      },
    );

    test('importer : pas une recette', timeout: _long, () async {
      final r = await _chrono(
        'Importer — un texte qui n\'est pas une recette',
        () => importer(
          'Bonjour Julie, on se voit mardi pour le café ? Apporte les '
          'photos du chalet, j\'ai hâte de les voir. À bientôt !',
        ),
      );
      _ecrire(
        '  → ${r == null ? 'null (bien vu)' : 'RECETTE INVENTÉE : ${r.nom}'}',
      );
      expect(r, isNull);
    });

    test('bilan de la semaine', timeout: _long, () async {
      final b = BilanSemaine(
        debut: DateTime(2026, 9, 19),
        fin: DateTime(2026, 9, 25),
        joursNotes: 5,
        moyenne: const Nutriments(
          kcal: 1980,
          proteines: 96,
          glucides: 240,
          lipides: 72,
          fibres: 17,
          sucres: 68,
          sodium: 2900,
          satures: 24,
        ),
        kcalVisees: 2200,
        proteinesVisees: 150,
        verresMoyens: 5.4,
        verresVises: 8,
        seances: 3,
        frequents: const [('Café', 7), ('Banane', 4), ('Pain de blé', 4)],
        jetes: const ['Épinards'],
      );
      final r = await _chrono(
        'Bilan — 5 jours notés, protéines basses, sodium haut',
        () => commenterBilan(
          b,
          objectif: ObjectifPoids.perdre,
          aConsommer: const ['Yogourt grec'],
        ),
      );
      _ecrire('  ${r.resume}');
      for (final p in r.pistes) {
        _ecrire('  • $p');
      }
      expect(r.pistes, isNotEmpty);
    });

    test('planifier la semaine avec le livre', timeout: _long, () async {
      final d = DemandePlan(
        recettes: _livre,
        prevus: const [],
        maintenant: _maintenant,
        moments: const {MomentRepas.diner, MomentRepas.souper},
        personnes: 2,
        restes: {_livre.firstWhere((r) => r.nom.contains('Chili')).id: 3},
        aConsommer: const ['Épinards'],
        kcalVisees: 2200,
        proteinesVisees: 150,
      );
      final r = await _chrono(
        'Planifier — dîners et soupers, 2 personnes, restes de chili',
        () => planifierSemaine(d),
      );
      _ecrire('  ${d.cases.length} cases libres, ${r.repas.length} remplies');
      if (r.resume case final s?) _ecrire('  $s');
      for (final x in r.repas) {
        final nom = _livre.firstWhere((l) => l.id == x.recetteId).nom;
        _ecrire(
          '  J+${x.jour.difference(DateTime(2026, 9, 25)).inDays} '
          '${x.moment.name} : $nom × ${x.portions}'
          '${x.pourquoi == null ? '' : ' — ${x.pourquoi}'}',
        );
      }
      expect(r.repas, isNotEmpty);
    });

    test('combler l\'écart du soir', timeout: _long, () async {
      final d = DemandeEcart(
        moment: MomentRepas.souper,
        reste: const Nutriments(
          kcal: 640,
          proteines: 48,
          glucides: 60,
          lipides: 20,
        ),
        visees: const Nutriments(kcal: 2200, proteines: 150),
        recettes: [
          for (final r in _livre)
            if (r.pour(MomentRepas.souper)) r,
        ],
        gardeManger: const ['Poulet', 'Brocoli', 'Riz basmati', 'Oeufs'],
        aConsommer: const ['Épinards'],
      );
      final r = await _chrono(
        'Écart — souper, reste 640 kcal / 48 g de protéines',
        () => comblerEcart(d),
      );
      for (final o in r) {
        _ecrire(
          '  « ${o.titre} »${o.pourquoi == null ? '' : ' — ${o.pourquoi}'}',
        );
        if (o.recetteId case final id?) {
          final rec = _livre.firstWhere((l) => l.id == id);
          final p = rec.parPortion * o.portions;
          _ecrire(
            '    recette du livre : ${rec.nom} × ${o.portions} → '
            '${p.kcal.round()} kcal, ${p.proteines.round()} g prot.',
          );
        } else {
          final cs = [for (final a in o.aliments) correspondre(a, _base)];
          _ecrireCorrespondances(cs);
          final t = Nutriments.somme(cs.map((c) => c.nutriments));
          _ecrire(
            '    total (base) : ${t.kcal.round()} kcal, '
            '${t.proteines.round()} g prot.',
          );
        }
      }
      expect(r, isNotEmpty);
    });

    test('estimer un repas (français puis anglais)', timeout: _long, () async {
      for (final (texte, fr) in const [
        ('une poutine moyenne et un Pepsi', true),
        ('two slices of pepperoni pizza and a caesar salad', false),
      ]) {
        final r = await _chrono(
          'Estimer — « $texte »',
          () => estimerRepas(texte, francais: fr),
        );
        _ecrire('  titre : ${r.titre}');
        final cs = [for (final a in r.aliments) correspondre(a, _base)];
        _ecrireCorrespondances(cs);
        final t = Nutriments.somme(cs.map((c) => c.nutriments));
        _ecrire('    total (base) : ${t.kcal.round()} kcal');
        expect(r.aliments, isNotEmpty);
      }
    });

    test('remplacer un ingrédient', timeout: _long, () async {
      final pate = _livre.firstWhere((r) => r.nom.contains('chinois'));
      final i = pate.ingredients.firstWhere(
        (x) => x.nom.toLowerCase().contains('bœuf'),
        orElse: () => pate.ingredients.first,
      );
      final r = await _chrono(
        'Remplacer — « ${i.nom} » du ${pate.nom}, plus léger',
        () => substituer(pate, i, raison: RaisonSubstitution.plusLeger),
      );
      _ecrire(
        '  l\'original : ${_q(i)} → ${i.nutriments.kcal.round()} kcal, '
        '${i.nutriments.proteines.round()} g prot.',
      );
      for (final s in r) {
        final c = correspondre(s.ingredient, _base);
        _ecrireCorrespondances([c]);
        _ecrire(
          '      ${c.nutriments.proteines.round()} g prot.'
          '${s.pourquoi == null ? '' : ' — ${s.pourquoi}'}',
        );
      }
      expect(r, isNotEmpty);
    });

    test('conservation hors du guide', timeout: _long, () async {
      for (final (nom, rayon) in const [
        ('Kimchi', Rayon.condiments),
        ('Tofu soyeux', Rayon.autre),
      ]) {
        final c = await _chrono(
          'Conservation — $nom',
          () => conservationIa(nom, rayon),
        );
        _ecrire(
          '  idéal : ${c!.ideal.name} ; frigo ${c.frigo} ; congélo '
          '${c.congelo} ; ambiant ${c.ambiant} ; ouvert ${c.ouvert}',
        );
        _ecrire('  ${c.conseil}');
      }
    });
  });
}
