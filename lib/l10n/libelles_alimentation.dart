// lib/l10n/libelles_alimentation.dart
//
// Les libellés de l'ALIMENTATION : les énumérations du modèle dans la langue
// de l'app, le CONSEIL DU JOUR en mots (le genre est choisi par
// `calculs_alimentation.dart` : profil à compléter > le soir, ce qui doit
// décongeler pour demain > ce qui est à consommer > journée dépassée >
// objectifs atteints > le matin sans déjeuner > après une séance > l'eau en
// retard > prendre du poids le soir > les protéines du soir > un repère du
// Guide alimentaire canadien), et les formats (grammes, portions).
// Tutoiement, formes neutres, jamais de reproche.

import '../modele/alimentation/alimentation.dart';
import '../modele/alimentation/calculs_alimentation.dart';
import 'libelles_recettes.dart';
import 'traductions.dart';

extension LibelleSexe on Sexe {
  String libelle(AppLocalizations tr) => switch (this) {
    Sexe.homme => tr.sexeHomme,
    Sexe.femme => tr.sexeFemme,
  };
}

extension LibelleActivite on ActiviteQuotidienne {
  String libelle(AppLocalizations tr) => switch (this) {
    ActiviteQuotidienne.sedentaire => tr.activiteSedentaire,
    ActiviteQuotidienne.debout => tr.activiteDebout,
    ActiviteQuotidienne.physique => tr.activitePhysique,
  };

  String detail(AppLocalizations tr) => switch (this) {
    ActiviteQuotidienne.sedentaire => tr.activiteSedentaireDetail,
    ActiviteQuotidienne.debout => tr.activiteDeboutDetail,
    ActiviteQuotidienne.physique => tr.activitePhysiqueDetail,
  };
}

extension LibelleObjectifPoids on ObjectifPoids {
  String libelle(AppLocalizations tr) => switch (this) {
    ObjectifPoids.perdre => tr.objectifPerdre,
    ObjectifPoids.maintenir => tr.objectifMaintenir,
    ObjectifPoids.prendre => tr.objectifPrendre,
  };
}

/// Le conseil du jour, en une phrase.
String texteConseil(AppLocalizations tr, Conseil c, Formats f) {
  String une(List<String> v) => v[c.variante % v.length];
  return switch (c.genre) {
    GenreConseil.profil => tr.conseilProfil,
    GenreConseil.decongeler => tr.conseilDecongeler(
      c.n > 2 ? '${c.noms} (+${c.n - 2})' : c.noms,
    ),
    GenreConseil.peremption => tr.conseilPeremption(
      c.n > 2 ? '${c.noms} (+${c.n - 2})' : c.noms,
    ),
    GenreConseil.dejeuner => une([tr.conseilDejeuner1, tr.conseilDejeuner2]),
    GenreConseil.apresSeance => tr.conseilApresSeance(c.n),
    GenreConseil.eau => tr.conseilEau(c.n, c.m),
    GenreConseil.prendreSoir => tr.conseilPrendreSoir(f.entier(c.n)),
    GenreConseil.proteinesSoir => tr.conseilProteinesSoir(c.n),
    GenreConseil.depasse => une([tr.conseilDepasse1, tr.conseilDepasse2]),
    GenreConseil.atteint => une([
      tr.conseilAtteint1,
      tr.conseilAtteint2,
      tr.conseilAtteint3,
    ]),
    GenreConseil.general => une([
      tr.conseilGuide1,
      tr.conseilGuide2,
      tr.conseilGuide3,
      tr.conseilGuide4,
      tr.conseilGuide5,
      tr.conseilGuide6,
      tr.conseilGuide7,
    ]),
  };
}

/// Une portion du FCÉN sans ses précisions entre parenthèses : « 1 moyen
/// (18cm à 20cm long) » → « 1 moyen ».
String portionCourte(String libelle) {
  final t = libelle.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
  return t.isEmpty ? libelle : t;
}

/// Les formats de l'alimentation.
extension FormatsAlimentation on Formats {
  /// « 118 g », « 0,5 g » (une décimale sous 10).
  String g(double x, AppLocalizations tr) =>
      tr.gValeur(decimal(x >= 10 ? x.roundToDouble() : (x * 10).round() / 10));

  /// « 1 640 kcal ».
  String kcalDe(double x, AppLocalizations tr) => tr.kcal(entier(x.round()));

  /// « 1 », « 1,5 », « ½ ».
  String nombre(double n) => n == 0.5 ? '½' : decimal(n);

  /// La quantité d'une entrée : « 118 g », « 2 × 175 g », « 1 moyen »,
  /// « 2 portions » (une recette).
  String quantite(EntreeJournal e, AppLocalizations tr) {
    final p = e.portion, n = e.portions;
    if (e.source == SourceEntree.recette && n != null) {
      return portions(n, tr);
    }
    if (p != null && n != null) {
      final court = portionCourte(p);
      return n == 1 ? court : '${nombre(n)} × $court';
    }
    final gr = e.grammes;
    return gr == null ? '' : g(gr, tr);
  }
}
