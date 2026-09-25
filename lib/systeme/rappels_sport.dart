// lib/systeme/rappels_sport.dart
//
// QUOI notifier pour les SPORTS, et quand — en fonction pure (testée) :
// chaque séance enregistrée qui a un rappel, à son heure, les jours où elle
// est prévue, sur les [kJoursPlanifies] prochains jours — pas aujourd'hui si
// elle est déjà faite. Toucher la notification ouvre les Sports.
//
// L'interrupteur général des rappels (Rappels) coupe aussi ceux-ci.

import '../l10n/traductions.dart';
import '../modele/sports/calculs_sport.dart';
import '../modele/sports/sport.dart';
import '../utils/dates.dart';
import 'notifications.dart';
import 'rappels_habitudes.dart' show kJoursPlanifies;

/// Charge utile : ouvrir les Sports.
const String kChargeSports = 'sports';

/// Identifiant stable du rappel d'une séance le jour [jour] (0 = aujourd'hui)
/// — une plage à part de celle des habitudes (FNV-1a).
int idRappelSeance(String programmeId, int jour) {
  var h = 0x811c9dc5;
  for (final c in programmeId.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return 20000000 + (h % 1000000) * 16 + jour;
}

List<NotifTexte> notificationsSport({
  required EtatSport etat,
  required DateTime maintenant,
  required AppLocalizations tr,
  bool actifs = true,
}) {
  final resultat = <NotifTexte>[];
  if (!actifs) return resultat;
  final canal = CanalNotif(
    'seances',
    tr.canalSeancesNom,
    tr.canalSeancesDescription,
  );
  final auj = jourDe(maintenant);
  for (var i = 0; i < kJoursPlanifies; i++) {
    final jour = plusJours(auj, i);
    for (final p in etat.programmes) {
      final h = p.heure;
      if (!p.rappel || h == null || !p.prevuLe(jour)) continue;
      final quand = DateTime(jour.year, jour.month, jour.day, h ~/ 60, h % 60);
      if (!quand.isAfter(maintenant)) continue;
      if (i == 0 && faitLe(p, etat.journal, jour)) continue;
      resultat.add(
        NotifTexte(
          id: idRappelSeance(p.id, i),
          quand: quand,
          canal: canal,
          titre: p.nom,
          corps: tr.notifSeanceCorps(
            p.travail.length,
            (dureeEstimee(p.lignes).inSeconds / 60).round(),
          ),
          charge: kChargeSports,
        ),
      );
    }
  }
  return resultat;
}
