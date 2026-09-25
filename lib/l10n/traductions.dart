// lib/l10n/traductions.dart
//
// Accès court aux traductions générées (`context.tr.bonjour`) et aux formats
// dans la langue de l'app (`context.formats`). Source FR (`app_fr.arb`), EN
// dès le départ (`app_en.arb`) ; `flutter gen-l10n` régénère
// `app_localizations*.dart` (ne pas éditer à la main). Le CONTENU (versets,
// exercices, repas, habitudes) reste en français : c'est de la donnée, pas
// de l'interface.

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../modele/calculs_habitudes.dart';
import '../modele/modeles.dart';
import 'app_localizations.dart';

export 'app_localizations.dart' show AppLocalizations;

extension TraductionsContexte on BuildContext {
  AppLocalizations get tr => AppLocalizations.of(this);

  Formats get formats => Formats(Localizations.localeOf(this).languageCode);
}

/// Dates, heures et nombres dans la langue de l'app. Jamais d'espace fine
/// (U+202F) : les polices de la maquette ne l'ont pas — une insécable
/// (U+00A0) la remplace.
class Formats {
  const Formats(this.langue);

  final String langue;

  bool get _fr => langue == 'fr';
  String get _locale => _fr ? 'fr_CA' : 'en_CA';

  static String _majuscule(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static String _insecables(String s) => s.replaceAll(' ', ' ');

  /// « Jeudi 24 septembre » / « Thursday, September 24 » (« 1er » en
  /// français).
  String jourComplet(DateTime d) => _fr
      ? _majuscule(
          '${DateFormat('EEEE', _locale).format(d)} '
          '${d.day == 1 ? '1er' : d.day} '
          '${DateFormat('MMMM', _locale).format(d)}',
        )
      : DateFormat('EEEE, MMMM d', _locale).format(d);

  /// Initiale du jour : « L M M J V S D » / « M T W T F S S ».
  String initialeJour(DateTime d) =>
      DateFormat('EEEEE', _locale).format(d).toUpperCase();

  /// « 18 h 00 » / « 6:00 p.m. ».
  String heure(int h, int m) => _fr
      ? '$h h ${m.toString().padLeft(2, '0')}'
      : _insecables(DateFormat.jm(_locale).format(DateTime(2000, 1, 1, h, m)));

  /// « 1 640 » / « 1,640 ».
  String entier(int n) =>
      _insecables(NumberFormat.decimalPattern(_locale).format(n));

  /// « 1,25 » / « 1.25 » — deux décimales au plus, aucune si inutile.
  String decimal(double x) =>
      _insecables(NumberFormat('#,##0.##', _locale).format(x));

  /// Une heure en minutes depuis minuit (« 7 h 00 » / « 7:00 a.m. »).
  String heureMinutes(int minutes) => heure(minutes ~/ 60, minutes % 60);

  /// « lun » / « Mon » (1 = lundi).
  String jourCourt(int jourIso) {
    // Le 5 janvier 2026 est un lundi.
    final j = DateFormat('EEE', _locale).format(DateTime(2026, 1, 4 + jourIso));
    return j.endsWith('.') ? j.substring(0, j.length - 1) : j;
  }

  /// « Tous les jours » ou « lun · mer · ven ».
  String joursPrevus(Set<int> jours, AppLocalizations tr) =>
      jours.isEmpty || jours.length == 7
      ? tr.tousLesJours
      : [for (final j in (jours.toList()..sort())) jourCourt(j)].join(' · ');

  /// « 7 sept. » / « Sep 7 ».
  String dateCourte(DateTime d) => _insecables(
    DateFormat(_fr ? 'd MMM' : 'MMM d', _locale).format(d),
  ).replaceAll(' ', ' ');

  /// « sept. » / « Sep ».
  String moisCourt(DateTime d) => DateFormat('MMM', _locale).format(d);

  /// « 7 sept., 21 h 30 » / « Sep 7, 9:30 p.m. ».
  String dateHeure(DateTime d) =>
      '${dateCourte(d)}, ${heure(d.hour, d.minute)}';

  /// Une durée compacte : « 16 j 12 h », « 5 h 12 min », « 12 min ».
  String duree(Duration d) {
    final j = d.inDays, h = d.inHours % 24, m = d.inMinutes % 60;
    final u = _fr ? 'j' : 'd';
    if (j > 0) return h > 0 ? '$j $u $h h' : '$j $u';
    if (d.inHours > 0) return '$h h ${m.toString().padLeft(2, '0')}';
    return '$m min';
  }

  /// Une durée en toutes lettres, pour une phrase : « 16 jours », « 5 h 12 ».
  String dureePhrase(Duration d, AppLocalizations tr) =>
      d.inDays > 0 ? tr.jours(d.inDays) : duree(d);

  /// « 9:41 » (minuteur).
  String minuteur(Duration d) =>
      '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';

  /// « 84,50 $ » / « $84.50 » (sans décimales à partir de 100).
  String argent(double montant) => _insecables(
    NumberFormat.currency(
      locale: _locale,
      symbol: r'$',
      decimalDigits: montant >= 100 ? 0 : 2,
    ).format(montant),
  );

  /// « 87 % » / « 87% ».
  String pourcent(double part) =>
      _insecables(NumberFormat.percentPattern(_locale).format(part));

  /// Un palier de libération en mots : « 1 semaine », « 3 mois », « 1 an ».
  String palier(int jours, AppLocalizations tr) {
    if (jours >= 365 && jours % 365 == 0) return tr.dureeAns(jours ~/ 365);
    if (jours >= 30 && jours % 30 == 0) return tr.dureeMois(jours ~/ 30);
    if (jours >= 7 && jours % 7 == 0) return tr.dureeSemaines(jours ~/ 7);
    return tr.jours(jours);
  }
}

extension LibellesTranche on Tranche {
  String libelle(AppLocalizations tr) => switch (this) {
    Tranche.nuit => tr.trancheNuit,
    Tranche.matin => tr.trancheMatin,
    Tranche.apresMidi => tr.trancheApresMidi,
    Tranche.soir => tr.trancheSoir,
  };
}

extension LibellesRepas on MomentRepas {
  String libelle(AppLocalizations tr) => switch (this) {
    MomentRepas.dejeuner => tr.dejeuner,
    MomentRepas.diner => tr.diner,
    MomentRepas.collation => tr.collation,
    MomentRepas.souper => tr.souper,
  };
}

extension LibellesMacro on Macro {
  String libelle(AppLocalizations tr) => switch (this) {
    Macro.proteines => tr.proteines,
    Macro.glucides => tr.glucides,
    Macro.lipides => tr.lipides,
  };
}
