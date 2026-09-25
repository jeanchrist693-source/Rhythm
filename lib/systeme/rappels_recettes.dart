// lib/systeme/rappels_recettes.dart
//
// QUOI notifier pour les RECETTES, et quand — en fonctions pures (testées) :
// - la DÉCONGÉLATION : la veille d'un repas prévu qui demande un aliment
//   qui n'est qu'au congélateur (ou des restes congelés), à l'heure choisie
//   (20 h) : « Sors-les du congélateur ce soir : bœuf haché maigre. » —
//   au frigo, il décongèle en sécurité. Coupé par l'interrupteur général des
//   rappels ou celui de la décongélation ;
// - les MINUTEURS du mode cuisine : à la fin de chacun, si l'app est
//   passée derrière (dans l'app, l'écran vibre lui-même). Jamais coupés :
//   on les a lancés soi-même.
// Toucher la notification ouvre l'Alimentation.

import '../l10n/traductions.dart';
import '../modele/alimentation/calculs_alimentation.dart' show enPhrase;
import '../modele/alimentation/calculs_recettes.dart';
import '../modele/alimentation/courses.dart';
import '../modele/alimentation/etat_recettes.dart';
import '../modele/alimentation/recettes.dart';
import '../utils/dates.dart';
import 'notifications.dart';
import 'rappels_garde_manger.dart' show kChargeAlimentation;
import 'rappels_habitudes.dart' show kJoursPlanifies;

/// Identifiant du rappel de décongélation pour le repas du jour [jour]
/// (1 = demain) : sa plage.
int idRappelDecongelation(int jour) => 40000000 + jour;

/// Identifiant stable d'un minuteur (FNV-1a), dans sa plage.
int idMinuteur(String id) {
  var h = 0x811c9dc5;
  for (final c in id.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return 50000000 + h % 1000000;
}

List<NotifTexte> notificationsDecongelation({
  required EtatRecettes recettes,
  required List<ArticleGardeManger> gardeManger,
  required DateTime maintenant,
  required AppLocalizations tr,
  bool actifs = true,
}) {
  final resultat = <NotifTexte>[];
  final r = recettes.reglages;
  if (!actifs || !r.rappelsDecongelation || recettes.plan.isEmpty) {
    return resultat;
  }
  final canal = CanalNotif(
    'decongelation',
    tr.canalDecongelationNom,
    tr.canalDecongelationDescription,
  );
  final auj = jourDe(maintenant);
  for (var i = 1; i <= kJoursPlanifies; i++) {
    final jour = plusJours(auj, i);
    final veille = plusJours(jour, -1);
    final quand = DateTime(
      veille.year,
      veille.month,
      veille.day,
      r.heureDecongelation ~/ 60,
      r.heureDecongelation % 60,
    );
    if (!quand.isAfter(maintenant)) continue;
    final liste = decongelationsDu(jour, recettes, gardeManger);
    if (liste.isEmpty) continue;
    final articles = enPhrase([
      for (final d in liste)
        for (final a in d.articles) a.nom,
    ], premiere: false);
    final plats = enPhrase([
      for (final d in liste) d.recette.nom,
    ], premiere: false);
    resultat.add(
      NotifTexte(
        id: idRappelDecongelation(i),
        quand: quand,
        canal: canal,
        titre: tr.notifDecongelationTitre,
        corps:
            '${tr.notifDecongelationCorps(articles)}\n'
            '${tr.notifDecongelationPour(plats)}',
        charge: kChargeAlimentation,
      ),
    );
  }
  return resultat;
}

List<NotifTexte> notificationsMinuteurs({
  required List<MinuteurCuisine> minuteurs,
  required DateTime maintenant,
  required AppLocalizations tr,
}) {
  final canal = CanalNotif(
    'minuteurs',
    tr.canalMinuteursNom,
    tr.canalMinuteursDescription,
  );
  return [
    for (final m in minuteurs)
      if (m.fin.isAfter(maintenant))
        NotifTexte(
          id: idMinuteur(m.id),
          quand: m.fin,
          canal: canal,
          titre: tr.notifMinuteurTitre,
          corps: m.libelle,
          charge: kChargeAlimentation,
        ),
  ];
}
