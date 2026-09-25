// lib/l10n/libelles_courses.dart
//
// Les libellés des ACHATS : rayons, emplacements, statuts de taxe et leur
// raison, et les formats (prix au cent, quantités « 2 + 150 g »,
// échéances « demain », durées du guide « 3 à 4 mois »).

import 'package:intl/intl.dart';

import '../modele/alimentation/conservation.dart';
import '../modele/alimentation/courses.dart';
import '../modele/alimentation/taxes.dart';
import 'traductions.dart';

extension LibelleRayon on Rayon {
  String libelle(AppLocalizations tr) => switch (this) {
    Rayon.fruits => tr.rayonFruits,
    Rayon.legumes => tr.rayonLegumes,
    Rayon.viandes => tr.rayonViandes,
    Rayon.poissons => tr.rayonPoissons,
    Rayon.laitiers => tr.rayonLaitiers,
    Rayon.boulangerie => tr.rayonBoulangerie,
    Rayon.cereales => tr.rayonCereales,
    Rayon.legumineuses => tr.rayonLegumineuses,
    Rayon.conserves => tr.rayonConserves,
    Rayon.condiments => tr.rayonCondiments,
    Rayon.epices => tr.rayonEpices,
    Rayon.collations => tr.rayonCollations,
    Rayon.boissons => tr.rayonBoissons,
    Rayon.surgeles => tr.rayonSurgeles,
    Rayon.entretien => tr.rayonEntretien,
    Rayon.hygiene => tr.rayonHygiene,
    Rayon.autre => tr.rayonAutre,
  };
}

extension LibelleEmplacement on Emplacement {
  String libelle(AppLocalizations tr) => switch (this) {
    Emplacement.frigo => tr.emplacementFrigo,
    Emplacement.congelateur => tr.emplacementCongelateur,
    Emplacement.armoire => tr.emplacementArmoire,
    Emplacement.comptoir => tr.emplacementComptoir,
  };
}

extension LibelleStatutTaxe on StatutTaxe {
  String libelle(AppLocalizations tr) => switch (this) {
    StatutTaxe.detaxe => tr.taxeDetaxe,
    StatutTaxe.tps => tr.taxeTps,
    StatutTaxe.tpsTvq => tr.taxeTpsTvq,
  };
}

extension LibelleRaisonTaxe on RaisonTaxe {
  String texte(AppLocalizations tr) => switch (this) {
    RaisonTaxe.base => tr.raisonBase,
    RaisonTaxe.grignotines => tr.raisonGrignotines,
    RaisonTaxe.alcool => tr.raisonAlcool,
    RaisonTaxe.tvqAbolie => tr.raisonTvqAbolie,
    RaisonTaxe.alUnite => tr.raisonAlUnite,
    RaisonTaxe.nonAlimentaire => tr.raisonNonAlimentaire,
    RaisonTaxe.hygieneDetaxee => tr.raisonHygieneDetaxee,
  };
}

extension FormatsCourses on Formats {
  bool get _fr => langue == 'fr';

  /// Un prix au cent : « 4,99 $ », « 1 204,50 $ » / « $4.99 ».
  String prix(double x) => NumberFormat.currency(
    locale: _fr ? 'fr_CA' : 'en_CA',
    symbol: r'$',
    decimalDigits: 2,
  ).format(x).replaceAll(' ', ' ').replaceAll(' ', ' ');

  /// Un taux au millième : « 9,975 % » / « 9.975% ».
  String taux(double x) {
    final t = NumberFormat(
      '#,##0.###',
      _fr ? 'fr_CA' : 'en_CA',
    ).format(x * 100);
    return _fr ? '$t %' : '$t%';
  }

  /// « 2 kg », « 1,5 L », « 3 », « 2 paquets ».
  String quantite(Quantite q, AppLocalizations tr) {
    final v = decimal(q.valeur);
    final s = q.unite.symbole;
    if (s != null) return '$v $s';
    if (q.unite == Unite.paquet) return tr.paquets(q.valeur.ceil(), v);
    return v;
  }

  /// « 2 + 150 g ».
  String quantites(List<Quantite> q, AppLocalizations tr) =>
      q.map((x) => quantite(x, tr)).join(' + ');

  /// « aujourd'hui », « demain », « dans 3 jours », « hier », « passée
  /// depuis 4 jours ».
  String echeance(int jours, AppLocalizations tr) => switch (jours) {
    0 => tr.echeanceAujourdhui,
    1 => tr.echeanceDemain,
    -1 => tr.echeanceHier,
    > 1 => tr.echeanceDans(jours),
    _ => tr.echeancePassee(-jours),
  };

  /// Une durée du guide : « 1 à 2 jours », « 3 à 4 mois », « 1 an ».
  String dureeGuide(Duree d, AppLocalizations tr) {
    final (a, b) = d;
    final (ua, na) = _unite(a);
    final (ub, nb) = _unite(b);
    String dire(String u, int n) => switch (u) {
      'a' => tr.dureeAns(n),
      'm' => tr.dureeMois(n),
      's' => tr.dureeSemaines(n),
      _ => tr.jours(n),
    };
    if (a == b) return dire(ua, na);
    if (ua == ub) {
      return tr.intervalle('$na', dire(ub, nb));
    }
    return tr.intervalle(dire(ua, na), dire(ub, nb));
  }

  static (String, int) _unite(int jours) {
    if (jours >= 365 && jours % 365 == 0) return ('a', jours ~/ 365);
    if (jours >= 30 && jours % 30 == 0) return ('m', jours ~/ 30);
    if (jours >= 7 && jours % 7 == 0) return ('s', jours ~/ 7);
    return ('j', jours);
  }
}
