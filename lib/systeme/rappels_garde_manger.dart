// lib/systeme/rappels_garde_manger.dart
//
// QUOI notifier pour le GARDE-MANGER, et quand — en fonction pure (testée) :
// chaque matin des [kJoursPlanifies] prochains jours, à l'heure choisie, un
// rappel s'il y a des aliments à consommer le jour même ou le lendemain :
// « Yogourt grec, épinards : à consommer d'ici demain. » Rien s'il n'y a
// rien. Toucher la notification ouvre l'Alimentation. Coupé par l'interrupteur général des rappels ou celui du
// garde-manger.

import '../l10n/traductions.dart';
import '../modele/alimentation/courses.dart';
import '../utils/dates.dart';
import 'notifications.dart';
import 'rappels_habitudes.dart' show kJoursPlanifies;

/// Charge utile : ouvrir l'Alimentation.
const String kChargeAlimentation = 'alimentation';

/// Identifiant du rappel du jour [jour] (0 = aujourd'hui) : sa plage.
int idRappelPeremption(int jour) => 30000000 + jour;

List<NotifTexte> notificationsGardeManger({
  required EtatCourses etat,
  required DateTime maintenant,
  required AppLocalizations tr,
  bool actifs = true,
}) {
  final resultat = <NotifTexte>[];
  final r = etat.reglages;
  if (!actifs || !r.rappelsPeremption || etat.gardeManger.isEmpty) {
    return resultat;
  }
  final canal = CanalNotif(
    'garde_manger',
    tr.canalGardeMangerNom,
    tr.canalGardeMangerDescription,
  );
  final auj = jourDe(maintenant);
  for (var i = 0; i < kJoursPlanifies; i++) {
    final jour = plusJours(auj, i);
    final quand = DateTime(
      jour.year,
      jour.month,
      jour.day,
      r.heureRappel ~/ 60,
      r.heureRappel % 60,
    );
    if (!quand.isAfter(maintenant)) continue;
    final urgents = [
      for (final a in etat.gardeManger)
        // Aujourd'hui ou demain : une date passée ne relance pas chaque
        // matin (l'app la montre en corail).
        if (a.peremption != null &&
            joursEntre(jour, a.peremption!) >= 0 &&
            joursEntre(jour, a.peremption!) <= 1)
          a,
    ]..sort((a, b) => a.peremption!.compareTo(b.peremption!));
    if (urgents.isEmpty) continue;
    final noms = urgents.take(3).map((a) => a.nom).join(', ');
    resultat.add(
      NotifTexte(
        id: idRappelPeremption(i),
        quand: quand,
        canal: canal,
        titre: tr.notifPeremptionTitre(urgents.length),
        corps: urgents.length > 3
            ? tr.notifPeremptionCorpsPlus(noms, urgents.length - 3)
            : tr.notifPeremptionCorps(noms),
        charge: kChargeAlimentation,
      ),
    );
  }
  return resultat;
}
