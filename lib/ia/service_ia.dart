// lib/ia/service_ia.dart
//
// Appels au modèle : Groq (API compatible OpenAI), repris de Studio
// (`Studio/lib/ia/service_ia.dart`, lui-même venu de Net Worth et de Flow) —
// cascade gpt-oss-120b → gpt-oss-20b (quotas séparés), deux essais par
// modèle avec pause sur surcharge, réponse forcée en JSON. Les erreurs sont
// typées (`ErreurIa`) et traduites par l'écran (`pieces_ia.dart`).
// Éprouvé sur le vrai Groq (`test/outils/ia_reelle_test.dart`) : le palier
// gratuit limite chaque modèle à 8 000 JETONS PAR MINUTE — une demande
// d'idées en prend 5 000 à 6 000 : deux de suite passent au modèle de
// secours, une troisième attend ce que Groq demande (quelques secondes) ;
// une réponse illisible (rare) est redemandée une fois.
// `ServiceIa.instance` se remplace dans les tests (aucun réseau).
//
// Ce qui part : la demande de l'écran, jamais le nom de l'utilisateur, son
// poids, ses habitudes ni ses libérations (`ia_alimentation.dart`).

import 'dart:convert';
import 'dart:io';

import 'cles_api.dart';

const _kModele = 'openai/gpt-oss-120b';
const _kModeleSecours = 'openai/gpt-oss-20b';
const _kBase = 'https://api.groq.com/openai/v1/chat/completions';

enum ErreurIa {
  quota,
  surcharge,
  nonAutorise,
  modeleIndisponible,
  illisible,

  /// Aucune connexion (socket, DNS, TLS) — pas la peine d'insister.
  reseau,

  /// L'app a été construite sans clé (`cles_api.dart`).
  sansCle,
}

class ExceptionIa implements Exception {
  const ExceptionIa(this.erreur, [this.code, this.attente]);

  final ErreurIa erreur;
  final int? code;

  /// Quota : le délai que Groq demande avant de réessayer (`retry-after`).
  final Duration? attente;

  @override
  String toString() =>
      'ExceptionIa(${erreur.name}${code == null ? '' : ' $code'})';
}

/// Message d'une conversation (rôle OpenAI : system, user, assistant).
class MessageIa {
  const MessageIa(this.role, this.contenu);

  final String role;
  final String contenu;

  Map<String, String> toJson() => {'role': role, 'content': contenu};
}

/// L'effort de raisonnement du modèle : `bas` pour ce qui est court
/// (conservation, substitutions), `moyen` pour composer (recettes, semaine).
enum Effort { bas, moyen }

class _Transitoire implements Exception {}

class ServiceIa {
  ServiceIa({this.cle = kCleGroq, this.adresse = _kBase});

  /// Le service en usage ; remplacé par un faux dans les tests.
  static ServiceIa instance = ServiceIa();

  final String cle;

  /// L'adresse de l'API (un serveur local dans les tests du service).
  final String adresse;

  /// Au-delà, on n'attend pas la fin d'un quota : l'erreur le dit.
  static const attenteMax = Duration(seconds: 20);

  /// Réponse JSON décodée (le mode `json_object` de l'API exige le mot
  /// « JSON » dans les messages : les invites l'écrivent).
  Future<Map<String, dynamic>> json(
    List<MessageIa> messages, {
    Effort effort = Effort.bas,
    double temperature = 0.4,
    int maxTokens = 4096,
  }) async {
    // Une réponse illisible (rare : JSON mal fermé) est redemandée une fois.
    for (var essai = 1; ; essai++) {
      final texte = await _generer(
        messages,
        effort: effort,
        temperature: temperature,
        maxTokens: maxTokens,
      );
      try {
        return decoderJson(texte);
      } on ExceptionIa {
        if (essai == 2) rethrow;
      }
    }
  }

  /// Tolère du texte parasite autour de l'objet.
  static Map<String, dynamic> decoderJson(String texte) {
    try {
      return jsonDecode(texte) as Map<String, dynamic>;
    } catch (_) {
      final debut = texte.indexOf('{');
      final fin = texte.lastIndexOf('}');
      if (debut >= 0 && fin > debut) {
        try {
          return jsonDecode(texte.substring(debut, fin + 1))
              as Map<String, dynamic>;
        } catch (_) {
          // Tombe sur l'exception ci-dessous.
        }
      }
      throw const ExceptionIa(ErreurIa.illisible);
    }
  }

  Future<String> _generer(
    List<MessageIa> messages, {
    required Effort effort,
    required double temperature,
    required int maxTokens,
  }) async {
    if (cle.isEmpty) throw const ExceptionIa(ErreurIa.sansCle);
    ExceptionIa? quota;
    for (var tour = 1; tour <= 2; tour++) {
      quota = null;
      Duration? attente;
      for (final modele in const [_kModele, _kModeleSecours]) {
        for (var essai = 1; essai <= 2; essai++) {
          try {
            return await _tenter(
              messages,
              modele,
              effort: effort,
              temperature: temperature,
              maxTokens: maxTokens,
            );
          } on ExceptionIa catch (e) {
            if (e.erreur == ErreurIa.quota) {
              quota = e;
              final a = e.attente;
              if (a != null && (attente == null || a < attente)) attente = a;
              break; // inutile d'insister sur ce modèle → suivant
            }
            rethrow;
          } on _Transitoire {
            if (essai == 2) break; // modèle surchargé → modèle suivant
            await Future<void>.delayed(Duration(milliseconds: 600 * essai));
          }
        }
      }
      // Les deux modèles au bout de leur quota À LA MINUTE : Groq dit quand
      // reprendre ; si c'est court, on attend, une fois.
      if (quota == null || attente == null || attente > attenteMax) break;
      if (tour == 1) {
        await Future<void>.delayed(attente + const Duration(milliseconds: 250));
      }
    }
    throw quota ?? const ExceptionIa(ErreurIa.surcharge);
  }

  Future<String> _tenter(
    List<MessageIa> messages,
    String modele, {
    required Effort effort,
    required double temperature,
    required int maxTokens,
  }) async {
    final corps = jsonEncode({
      'model': modele,
      'messages': [for (final m in messages) m.toJson()],
      'temperature': temperature,
      'max_tokens': maxTokens,
      'reasoning_effort': switch (effort) {
        Effort.bas => 'low',
        Effort.moyen => 'medium',
      },
      'response_format': {'type': 'json_object'},
    });
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
      final req = await client.postUrl(Uri.parse(adresse));
      req.headers.contentType = ContentType.json;
      req.headers.set('Authorization', 'Bearer $cle');
      req.add(utf8.encode(corps));
      final resp = await req.close().timeout(const Duration(seconds: 90));
      final texte = await resp.transform(utf8.decoder).join();
      if (resp.statusCode != 200) {
        if (resp.statusCode == 429) {
          final s = double.tryParse(resp.headers.value('retry-after') ?? '');
          throw ExceptionIa(
            ErreurIa.quota,
            429,
            s == null || !s.isFinite || s < 0
                ? null
                : Duration(milliseconds: (s * 1000).round()),
          );
        }
        if (const [500, 502, 503, 504].contains(resp.statusCode)) {
          throw _Transitoire();
        }
        if (resp.statusCode == 404) {
          throw const ExceptionIa(ErreurIa.modeleIndisponible, 404);
        }
        throw ExceptionIa(ErreurIa.nonAutorise, resp.statusCode);
      }
      final j = jsonDecode(texte) as Map<String, dynamic>;
      final choix = j['choices'] as List?;
      if (choix == null || choix.isEmpty) throw _Transitoire();
      final message = (choix.first as Map)['message'] as Map<String, dynamic>?;
      final contenu = ((message?['content'] ?? '') as String).trim();
      if (contenu.isEmpty) throw _Transitoire();
      return contenu;
    } on ExceptionIa {
      rethrow;
    } on _Transitoire {
      rethrow;
    } on SocketException {
      // Pas de réseau : inutile de réessayer ni de changer de modèle.
      throw const ExceptionIa(ErreurIa.reseau);
    } on HandshakeException {
      throw const ExceptionIa(ErreurIa.reseau);
    } catch (_) {
      // Délai dépassé, réponse tronquée : transitoire, on réessaie.
      throw _Transitoire();
    } finally {
      client?.close();
    }
  }
}
