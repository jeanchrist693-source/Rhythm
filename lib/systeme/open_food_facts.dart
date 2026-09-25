// lib/systeme/open_food_facts.dart
//
// L'appel à OPEN FOOD FACTS (en ligne, sans clé) : un code-barres → ce que
// la base sait du produit (`modele/alimentation/open_food_facts.dart` le
// lit). Seul le CODE part — rien de personnel. Les erreurs sont typées
// (`ErreurOff`) et dites par l'écran du scan. `ServiceOff.instance` se
// remplace dans les tests (aucun réseau).

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../modele/alimentation/open_food_facts.dart';

enum ErreurOff {
  /// Aucune connexion (socket, DNS, TLS, délai dépassé).
  reseau,

  /// Le service a répondu autre chose qu'un produit ou « inconnu ».
  service,
}

class ExceptionOff implements Exception {
  const ExceptionOff(this.erreur);

  final ErreurOff erreur;

  @override
  String toString() => 'ExceptionOff(${erreur.name})';
}

class ServiceOff {
  /// Le service en usage ; remplacé par un faux dans les tests.
  static ServiceOff instance = ServiceOff();

  static const _base = 'https://world.openfoodfacts.org/api/v2/product';

  /// La politique d'Open Food Facts demande qu'une app se nomme.
  static const _agent = 'Rhythm/0.1 (Android; application personnelle)';

  /// Ce que la base sait du produit [code] (normalisé) ; `null` : inconnu.
  Future<BrouillonOff?> chercher(String code) async {
    final reponse = await document(code);
    return reponse == null ? null : brouillonDepuisOff(reponse, code: code);
  }

  /// La réponse brute de l'API (`null` : produit inconnu).
  Future<Map<String, dynamic>?> document(String code) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
      final uri = Uri.parse('$_base/$code.json?fields=$kChampsOff');
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.userAgentHeader, _agent);
      final resp = await req.close().timeout(const Duration(seconds: 15));
      final texte = await resp.transform(utf8.decoder).join();
      // Inconnu : 404 (et « status »: 0 dans le corps).
      if (resp.statusCode == 404) return null;
      if (resp.statusCode != 200) throw const ExceptionOff(ErreurOff.service);
      final j = jsonDecode(texte);
      if (j is! Map<String, dynamic>) {
        throw const ExceptionOff(ErreurOff.service);
      }
      return j['status'] == 0 ? null : j;
    } on ExceptionOff {
      rethrow;
    } on SocketException {
      throw const ExceptionOff(ErreurOff.reseau);
    } on HandshakeException {
      throw const ExceptionOff(ErreurOff.reseau);
    } on TimeoutException {
      throw const ExceptionOff(ErreurOff.reseau);
    } on HttpException {
      throw const ExceptionOff(ErreurOff.reseau);
    } on FormatException {
      throw const ExceptionOff(ErreurOff.service);
    } finally {
      client?.close();
    }
  }
}
