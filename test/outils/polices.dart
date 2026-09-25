// test/outils/polices.dart
//
// Les VRAIES polices de l'app pour les tests. Sans elles, flutter_test
// dessine chaque glyphe d'un cadratin de large : les textes s'allongent et
// inventent des débordements (piège noté dans Studio).

import 'dart:io';

import 'package:flutter/services.dart';

Future<void> chargerPolices() async {
  Future<void> charger(String famille, String fichier) async {
    final octets = File('assets/polices/$fichier').readAsBytesSync();
    final chargeur = FontLoader(famille)
      ..addFont(Future.value(ByteData.sublistView(octets)));
    await chargeur.load();
  }

  await charger('BricolageGrotesque', 'BricolageGrotesque-Variable.ttf');
  await charger('DMSans', 'DMSans-Variable.ttf');
}
