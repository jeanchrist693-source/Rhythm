// lib/modele/depot.dart
//
// Persistance locale de Rhythm : UNE base SQLite (`package:sqlite3`,
// synchrone — tout est local, rien n'est en ligne), le dépôt de Studio et
// Net Worth repris tel quel. Une table par famille (`id` + document JSON)
// et une table de réglages (clé → JSON). `ecrire` reçoit le document entier
// et n'écrit QUE ce qui a changé (diff par id, dans une transaction) : cocher
// une habitude coûte une ligne. Une famille absente du document n'est pas
// touchée (un module n'efface jamais les tables d'un autre).
//
// Fichier : `<documents de l'app>/rhythm/rhythm.db` — le dossier que la
// sauvegarde automatique d'Android emporte (`res/xml/*_rules.xml`).
// Les écrans ne voient jamais le dépôt : ils passent par les notifiers.

import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

class Depot {
  Depot._(this._db) {
    _preparer();
  }

  /// Ouvre (ou crée) la base.
  factory Depot.ouvrir(String chemin) {
    File(chemin).parent.createSync(recursive: true);
    return Depot._(sqlite3.open(chemin));
  }

  /// Base en mémoire (tests, captures).
  factory Depot.memoire() => Depot._(sqlite3.openInMemory());

  final Database _db;
  bool _ferme = false;

  /// Les familles du document, dans l'ordre.
  static const tables = [
    'habitudes',
    'programmesSport',
    'journalSport',
    'mesuresSport',
    'journalAlim',
    'produitsAlim',
    'eauAlim',
    'listeCourses',
    'gardeManger',
    'achatsAlim',
    'sortiesAlim',
    'recettesAlim',
    'planAlim',
    'conservationIa',
  ];

  /// Ce qui est en base, par table puis par id (le JSON tel qu'écrit) : le
  /// diff d'une écriture se fait contre cette image.
  final Map<String, Map<String, String>> _enBase = {};
  final Map<String, String> _reglagesEnBase = {};

  void _preparer() {
    for (final t in tables) {
      _db.execute(
        'CREATE TABLE IF NOT EXISTS $t (id TEXT PRIMARY KEY, donnees TEXT NOT NULL)',
      );
    }
    _db.execute(
      'CREATE TABLE IF NOT EXISTS reglages (cle TEXT PRIMARY KEY, valeur TEXT NOT NULL)',
    );
  }

  /// Le document complet, ou `null` si la base n'a jamais été écrite.
  Map<String, dynamic>? lire() {
    final document = <String, dynamic>{};
    _reglagesEnBase.clear();
    for (final r in _db.select('SELECT cle, valeur FROM reglages')) {
      final cle = r['cle'] as String;
      final valeur = r['valeur'] as String;
      _reglagesEnBase[cle] = valeur;
      document[cle] = jsonDecode(valeur);
    }
    var vide = document.isEmpty;
    for (final t in tables) {
      final image = _enBase[t] = {};
      final liste = <Map<String, dynamic>>[];
      for (final r in _db.select('SELECT id, donnees FROM $t')) {
        final donnees = r['donnees'] as String;
        image[r['id'] as String] = donnees;
        liste.add(jsonDecode(donnees) as Map<String, dynamic>);
      }
      if (liste.isNotEmpty) vide = false;
      document[t] = liste;
    }
    return vide ? null : document;
  }

  /// Écrit ce qui a changé depuis la dernière lecture / écriture.
  void ecrire(Map<String, dynamic> document) {
    if (_ferme) return;
    _db.execute('BEGIN');
    try {
      for (final t in tables) {
        // Une famille absente du document n'est pas touchée : chaque module
        // (habitudes, puis sports, alimentation…) écrit les siennes.
        if (!document.containsKey(t)) continue;
        final nouveaux = <String, String>{
          for (final r in (document[t] as List? ?? const []))
            (r as Map)['id'] as String: jsonEncode(r),
        };
        final anciens = _enBase[t] ?? const <String, String>{};
        final upsert = _db.prepare(
          'INSERT OR REPLACE INTO $t (id, donnees) VALUES (?, ?)',
        );
        final retrait = _db.prepare('DELETE FROM $t WHERE id = ?');
        try {
          for (final e in nouveaux.entries) {
            if (anciens[e.key] != e.value) upsert.execute([e.key, e.value]);
          }
          for (final id in anciens.keys) {
            if (!nouveaux.containsKey(id)) retrait.execute([id]);
          }
        } finally {
          upsert.close();
          retrait.close();
        }
        _enBase[t] = nouveaux;
      }
      final upsert = _db.prepare(
        'INSERT OR REPLACE INTO reglages (cle, valeur) VALUES (?, ?)',
      );
      try {
        for (final e in document.entries) {
          if (tables.contains(e.key)) continue;
          final valeur = jsonEncode(e.value);
          if (_reglagesEnBase[e.key] == valeur) continue;
          upsert.execute([e.key, valeur]);
          _reglagesEnBase[e.key] = valeur;
        }
      } finally {
        upsert.close();
      }
      _db.execute('COMMIT');
    } catch (_) {
      _db.execute('ROLLBACK');
      rethrow;
    }
  }

  void fermer() {
    if (_ferme) return;
    _ferme = true;
    _db.close();
  }
}
