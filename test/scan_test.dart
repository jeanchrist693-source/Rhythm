// test/scan_test.dart
//
// Le SCAN d'un produit, sans réseau : les codes-barres (clé de contrôle,
// UPC-A et UPC-E ramenés à l'EAN-13), la lecture TOLÉRANTE d'une réponse
// d'Open Food Facts (portion de l'emballage ou 100 g, kJ, sel, nombres en
// texte, produit inconnu, valeur nutritive absente), le code gardé avec le
// produit et retrouvé sans réseau.

import 'package:flutter_test/flutter_test.dart';
import 'package:rhythm/modele/alimentation/alimentation.dart';
import 'package:rhythm/modele/alimentation/nutriments.dart';
import 'package:rhythm/modele/alimentation/open_food_facts.dart';

Map<String, dynamic> _off(Map<String, dynamic> produit) => {
  'code': '0012345678905',
  'status': 1,
  'status_verbose': 'product found',
  'product': produit,
};

void main() {
  group('les codes-barres', () {
    test('EAN-13 : la clé de contrôle', () {
      expect(normaliserCode('3017620422003'), '3017620422003');
      expect(normaliserCode('3017620422004'), isNull);
    });

    test('UPC-A (Amérique du Nord) → l\'EAN-13 du même produit', () {
      expect(normaliserCode('012345678905'), '0012345678905');
      expect(normaliserCode('0 12345 67890 5'), '0012345678905');
      expect(normaliserCode('012345678906'), isNull);
    });

    test('EAN-8, et UPC-E déplié quand la caméra le dit', () {
      expect(normaliserCode('96385074'), '96385074');
      // 0 123456 5 → UPC-A 0 12345 00006 5 (l'exemple de référence) ; ce
      // code passe AUSSI la clé d'un EAN-8 : sans l'indication de la
      // caméra, il est lu comme tel.
      expect(normaliserCode('01234565', upcE: true), '0012345000065');
      expect(normaliserCode('01234565'), '01234565');
    });

    test('ni trop court, ni des lettres, ni un GTIN-14 de carton', () {
      expect(normaliserCode(''), isNull);
      expect(normaliserCode('12345'), isNull);
      expect(normaliserCode('abc'), isNull);
      expect(normaliserCode('10012345678902'), isNull);
      expect(normaliserCode('00012345678905'), '0012345678905');
    });

    test('lisible par groupes', () {
      expect(codeLisible('0012345678905'), '0 012345 678905');
      expect(codeLisible('96385074'), '9638 5074');
    });
  });

  group('la réponse d\'Open Food Facts', () {
    test('la portion de l\'emballage : les valeurs à la règle de trois', () {
      final b = brouillonDepuisOff(
        _off({
          'product_name': 'Chewy bar',
          'product_name_fr': 'Barre tendre aux pépites',
          'brands': 'Quaker, PepsiCo',
          'serving_size': '1 barre (24 g)',
          'serving_quantity': 24,
          'nutriments': {
            'energy-kcal_100g': 420,
            'proteins_100g': 6.5,
            'carbohydrates_100g': 70,
            'fat_100g': 12.5,
            'saturated-fat_100g': 3,
            'fiber_100g': 4,
            'sugars_100g': 29,
            'sodium_100g': 0.25,
          },
        }),
        code: '0012345678905',
      )!;
      final p = b.produit;
      expect(b.valeursConnues, isTrue);
      expect(p.nom, 'Barre tendre aux pépites');
      expect(p.marque, 'Quaker');
      expect(p.portion, '1 barre (24 g)');
      expect(p.grammesPortion, 24);
      expect(p.codeBarres, '0012345678905');
      expect(p.parPortion.kcal, 101); // 420 × 0,24
      expect(p.parPortion.proteines, 1.6);
      expect(p.parPortion.glucides, 16.8);
      expect(p.parPortion.lipides, 3);
      expect(p.parPortion.sodium, 60); // 0,25 g × 0,24 → 60 mg
    });

    test('la valeur de la portion, quand elle est donnée, passe devant', () {
      final p = brouillonDepuisOff(
        _off({
          'product_name': 'Yogourt grec',
          'serving_quantity': '175',
          'serving_size': '175 g',
          'nutriments': {
            'energy-kcal_100g': 97,
            'energy-kcal_serving': 170,
            'proteins_100g': '10,2',
          },
        }),
        code: '0012345678905',
      )!.produit;
      expect(p.parPortion.kcal, 170);
      expect(p.parPortion.proteines, 17.8); // « 10,2 » × 1,75 = 17,85
    });

    test('sans portion : 100 g ; les kJ et le sel à défaut', () {
      final p = brouillonDepuisOff(
        _off({
          'product_name': '  Craquelins   de blé ',
          'nutriments': {'energy_100g': 1700, 'salt_100g': 1.0},
        }),
        code: '96385074',
      )!.produit;
      expect(p.nom, 'Craquelins de blé');
      expect(p.portion, '100 g');
      expect(p.grammesPortion, 100);
      expect(p.marque, isNull);
      expect(p.parPortion.kcal, 406); // 1 700 kJ
      expect(p.parPortion.sodium, 400); // 1 g de sel
    });

    test('une boisson : la portion en ml', () {
      final p = brouillonDepuisOff(
        _off({
          'product_name': 'Boisson d\'avoine',
          'serving_quantity': 250,
          'serving_quantity_unit': 'ml',
          'nutriments': {'energy-kcal_100g': 45},
        }),
        code: '96385074',
      )!.produit;
      expect(p.portion, '250 ml');
      expect(p.parPortion.kcal, 113);
    });

    test('pas de valeur nutritive : rien d\'inventé, à recopier', () {
      final b = brouillonDepuisOff(
        _off({'product_name': 'Épices à steak'}),
        code: '96385074',
      )!;
      expect(b.valeursConnues, isFalse);
      expect(b.produit.parPortion.kcal, 0);
    });

    test('inconnu, vide ou abîmé : null', () {
      expect(
        brouillonDepuisOff({
          'status': 0,
          'status_verbose': 'product not found',
        }, code: '96385074'),
        isNull,
      );
      expect(brouillonDepuisOff(_off({}), code: '96385074'), isNull);
      expect(brouillonDepuisOff('texte', code: '96385074'), isNull);
      // Des nutriments faux sont ignorés, pas l'app.
      final p = brouillonDepuisOff(
        _off({
          'product_name': 'Test',
          'nutriments': {'energy-kcal_100g': -5, 'proteins_100g': 'beaucoup'},
        }),
        code: '96385074',
      )!.produit;
      expect(p.parPortion.kcal, 0);
      expect(p.parPortion.proteines, 0);
    });
  });

  group('le code gardé avec le produit', () {
    const p = Produit(
      id: 'prod-1',
      nom: 'Barre tendre',
      portion: '1 barre (24 g)',
      grammesPortion: 24,
      codeBarres: '0012345678905',
      parPortion: Nutriments(kcal: 101),
    );

    test('au JSON, aller et retour (et les anciens produits, sans code)', () {
      final relu = Produit.depuisJson(p.versJson())!;
      expect(relu.codeBarres, '0012345678905');
      final ancien = Produit.depuisJson({
        'id': 'prod-2',
        'nom': 'Yogourt',
        'portion': '175 g',
        'n': const Nutriments(kcal: 170).versJson(),
      })!;
      expect(ancien.codeBarres, isNull);
    });

    test('retrouvé par son code, sans réseau', () {
      const etat = EtatAlimentation(produits: [p]);
      expect(etat.produitDuCode('0012345678905')?.id, 'prod-1');
      expect(etat.produitDuCode('96385074'), isNull);
    });
  });
}
