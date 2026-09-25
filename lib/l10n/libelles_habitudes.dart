// lib/l10n/libelles_habitudes.dart
//
// Le MOT DU JOUR des habitudes : une phrase qui parle de LA journée en
// cours, choisie dans cet ordre —
// 1. un PALIER atteint aujourd'hui (« Une semaine entière de … ») ;
// 2. la journée COMPLÈTE (avec la série si elle compte) ;
// 3. « JAMAIS DEUX FOIS » : une habitude a sauté son dernier jour prévu et
//    attend encore aujourd'hui ;
// 4. le moment : le matin sans rien de fait (lancer la journée), l'après-
//    midi, le soir (la version minimale compte), la nuit (se reposer) ;
// 5. sinon, la progression (« Plus que 2 »).
// Plusieurs tournures par situation : la variante change chaque jour et
// reste stable dans la journée (elle ne saute pas à chaque coche).
// Tutoiement, formes neutres (jamais « prêt / prête »).

import '../modele/calculs_habitudes.dart';
import '../modele/habitudes.dart';
import '../utils/dates.dart';
import 'app_localizations.dart';

/// La phrase du jour ; `null` quand il n'y a rien à construire (les
/// libérations ont leurs compteurs).
String? motDuJour(
  AppLocalizations tr,
  EtatHabitudes etat,
  DateTime maintenant,
) {
  if (etat.habitudes.isEmpty) return tr.coachAucune;
  final construire = etat.aConstruire;
  if (construire.isEmpty) return null;
  final auj = jourDe(maintenant);
  final graine = joursEntre(DateTime(2026), auj);
  String une(List<String> variantes, [int sel = 0]) =>
      variantes[(graine + sel) % variantes.length];

  for (final h in construire) {
    if (!estFaite(h, auj)) continue;
    final p = palierAtteint(kPaliersSerie, serie(h, auj));
    if (p != null) return commentairePalier(tr, p, h.nom);
  }

  final jour = journee(construire, auj);
  if (jour.complete) {
    final n = serieGlobale(construire, auj);
    if (n >= 2 && graine.isEven) return tr.coachCompleteSerie(n);
    return une([tr.coachComplete1, tr.coachComplete2, tr.coachComplete3]);
  }
  if (jour.vide) return tr.coachRienPrevu;

  final tranche = trancheDe(maintenant);
  final manquee = manqueeHier(construire, auj);
  if (manquee != null && tranche != Tranche.nuit) {
    return une([
      tr.coachJamaisDeuxFois1(manquee.nom),
      tr.coachJamaisDeuxFois2(manquee.nom),
    ], 1);
  }
  switch (tranche) {
    case Tranche.nuit:
      return tr.coachNuit;
    case Tranche.soir:
      return jour.entamee ? tr.coachSoir(jour.reste) : tr.coachSoirRien;
    case Tranche.matin when !jour.entamee:
      return une([tr.coachMatin1, tr.coachMatin2, tr.coachMatin3]);
    case Tranche.apresMidi when !jour.entamee:
      return tr.coachApresMidi;
    case Tranche.matin || Tranche.apresMidi:
      return une([
        tr.coachPartiel1(jour.reste),
        tr.coachPartiel2,
        tr.coachPartiel3(jour.reste),
      ], 2);
  }
}

/// Ce que dit le palier [palier] d'une série de « [nom] ».
String commentairePalier(AppLocalizations tr, int palier, String nom) =>
    switch (palier) {
      3 => tr.coachPalier3(nom),
      7 => tr.coachPalier7(nom),
      14 => tr.coachPalier14(nom),
      21 => tr.coachPalier21(nom),
      30 => tr.coachPalier30(nom),
      50 => tr.coachPalier50(nom),
      66 => tr.coachPalier66(nom),
      100 => tr.coachPalier100(nom),
      365 => tr.coachPalier365(nom),
      _ => tr.coachPalierAutre(palier, nom),
    };
