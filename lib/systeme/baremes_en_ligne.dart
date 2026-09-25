// lib/systeme/baremes_en_ligne.dart
//
// La lecture du FICHIER DES BARÈMES en ligne (`kUrlBaremes`, dans le dépôt
// public de Rhythm) : au plus une fois par mois, au lancement ou au retour
// dans l'app (`synchro.dart`). Rien ne part (une simple lecture). Sans
// réseau, un fichier absent ou abîmé : rien ne change, le barème embarqué
// suffit, et on réessaiera au prochain retour. `ServiceBaremes.instance` se
// remplace dans les tests (aucun réseau).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../modele/alimentation/taxes.dart';

class ServiceBaremes {
  /// Le service en usage ; remplacé par un faux dans les tests.
  static ServiceBaremes instance = ServiceBaremes();

  /// Les barèmes publiés (une liste vide : rien à ajouter) ; `null` : rien
  /// reçu.
  Future<List<Bareme>?> telecharger() async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final req = await client.getUrl(Uri.parse(kUrlBaremes));
      final resp = await req.close().timeout(const Duration(seconds: 15));
      final texte = await resp.transform(utf8.decoder).join();
      if (resp.statusCode != 200) return null;
      final j = jsonDecode(texte);
      if (j is! Map || j['baremes'] is! List) return null;
      return baremesDepuis(j);
    } catch (_) {
      // Pas de réseau, délai dépassé, fichier abîmé : on réessaiera.
      return null;
    } finally {
      client?.close();
    }
  }
}
