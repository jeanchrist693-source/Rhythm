// lib/systeme/rappels_habitudes.dart
//
// QUOI notifier, et quand — en fonction pure (testée), la synchro se charge
// du reste. Sur les [kJoursPlanifies] prochains jours :
//
// - le RAPPEL de chaque habitude à construire qui en a un, les jours où
//   elle est prévue — pas aujourd'hui si elle est déjà faite. Son texte
//   motive À SA FAÇON : la série en cours (aujourd'hui), le plan si-alors,
//   la version minimale, sinon le pourquoi ;
// - le BILAN DU SOIR (si réglé) : aujourd'hui, ce qui reste — rien s'il ne
//   reste rien ; les jours suivants, une invitation à faire le point ;
// - pour une habitude à LIBÉRER qui a une heure : un mot de SOUTIEN
//   discret, et chaque PALIER à l'instant exact où il tombe. Jamais le nom
//   de ce dont on se libère : titre « Rhythm », canal privé.
//
// L'interrupteur général des rappels coupe tout.

import '../l10n/traductions.dart';
import '../modele/calculs_habitudes.dart';
import '../modele/habitudes.dart';
import '../utils/dates.dart';
import 'notifications.dart';

/// Jours planifiés à l'avance (replanifiés à chaque ouverture).
const int kJoursPlanifies = 10;

/// Charge utile : ouvrir les Habitudes.
const String kChargeHabitudes = 'habitudes';

/// Identifiant stable d'une habitude pour Android (FNV-1a) : le rappel du
/// jour [jour] (0 = aujourd'hui) a toujours le même numéro — on peut le
/// retirer quand l'habitude est cochée.
int idRappel(String habitudeId, int jour) {
  var h = 0x811c9dc5;
  for (final c in habitudeId.codeUnits) {
    h = ((h ^ c) * 0x01000193) & 0xffffffff;
  }
  return 100000 + (h % 1000000) * 16 + jour;
}

int _idBilan(int jour) => 1000 + jour;
int _idPalier(int rang) => 2000 + rang;

/// Les trois canaux, dans la langue de l'app.
class CanauxHabitudes {
  CanauxHabitudes(AppLocalizations tr)
    : rappels = CanalNotif(
        'rappels_habitudes',
        tr.canalRappelsNom,
        tr.canalRappelsDescription,
      ),
      bilan = CanalNotif(
        'bilan_soir',
        tr.canalBilanNom,
        tr.canalBilanDescription,
      ),
      soutien = CanalNotif(
        'soutien_discret',
        tr.canalSoutienNom,
        tr.canalSoutienDescription,
        prive: true,
      );

  final CanalNotif rappels;
  final CanalNotif bilan;
  final CanalNotif soutien;
}

List<NotifTexte> notificationsHabitudes({
  required EtatHabitudes etat,
  required DateTime maintenant,
  required AppLocalizations tr,
  required Formats formats,
}) {
  final resultat = <NotifTexte>[];
  if (!etat.reglages.rappels) return resultat;
  final canaux = CanauxHabitudes(tr);
  final auj = jourDe(maintenant);
  final soutiens = [tr.notifSoutien1, tr.notifSoutien2, tr.notifSoutien3];

  DateTime a(DateTime jour, int minutes) =>
      DateTime(jour.year, jour.month, jour.day, minutes ~/ 60, minutes % 60);

  for (var i = 0; i < kJoursPlanifies; i++) {
    final jour = plusJours(auj, i);
    for (final h in etat.habitudes) {
      final rappel = h.rappel;
      if (rappel == null) continue;
      final quand = a(jour, rappel);
      if (!quand.isAfter(maintenant)) continue;
      if (h.aLiberer) {
        resultat.add(
          NotifTexte(
            id: idRappel(h.id, i),
            quand: quand,
            canal: canaux.soutien,
            titre: tr.titreApp,
            corps: soutiens[joursEntre(DateTime(2026), jour) % soutiens.length],
            charge: kChargeHabitudes,
          ),
        );
        continue;
      }
      if (!estPrevue(h, jour) || (i == 0 && estFaite(h, jour))) continue;
      resultat.add(
        NotifTexte(
          id: idRappel(h.id, i),
          quand: quand,
          canal: canaux.rappels,
          titre: h.nom,
          corps: corpsRappel(h, aujourdhui: i == 0 ? auj : null, tr: tr),
          charge: kChargeHabitudes,
        ),
      );
    }

    final bilan = etat.reglages.bilanSoir;
    if (bilan != null && a(jour, bilan).isAfter(maintenant)) {
      if (i == 0) {
        final restantes = [
          for (final h in etat.aConstruire)
            if (estPrevue(h, jour) && !estFaite(h, jour)) h.nom,
        ];
        if (restantes.isNotEmpty) {
          resultat.add(
            NotifTexte(
              id: _idBilan(i),
              quand: a(jour, bilan),
              canal: canaux.bilan,
              titre: tr.bilanDuSoir,
              corps: tr.notifBilanReste(restantes.length, restantes.join(', ')),
              charge: kChargeHabitudes,
            ),
          );
        }
      } else if (!journee(etat.habitudes, jour).vide) {
        resultat.add(
          NotifTexte(
            id: _idBilan(i),
            quand: a(jour, bilan),
            canal: canaux.bilan,
            titre: tr.bilanDuSoir,
            corps: tr.notifBilanGenerique,
            charge: kChargeHabitudes,
          ),
        );
      }
    }
  }

  // Les paliers de libération, à l'instant exact.
  final horizon = plusJours(auj, kJoursPlanifies);
  final liberer = etat.aLiberer;
  for (var k = 0; k < liberer.length; k++) {
    final h = liberer[k];
    if (h.rappel == null) continue;
    final debut = h.debutLiberte;
    final jours =
        dureeLiberte(h, maintenant).inMinutes / Duration.minutesPerDay;
    final palier = prochainPalier(kPaliersLiberte, jours).suivant;
    final quand = plusJoursInstant(debut, palier);
    if (!quand.isAfter(maintenant) || !quand.isBefore(horizon)) continue;
    resultat.add(
      NotifTexte(
        id: _idPalier(k),
        quand: quand,
        canal: canaux.soutien,
        titre: tr.notifPalierTitre,
        corps: tr.notifPalierCorps(formats.palier(palier, tr)),
        charge: kChargeHabitudes,
      ),
    );
  }
  return resultat;
}

/// Le texte du rappel de [h] : la série en cours ([aujourdhui] seulement),
/// le plan si-alors, la version minimale — sinon le pourquoi, sinon une
/// invitation. Deux lignes au plus.
String corpsRappel(
  Habitude h, {
  required DateTime? aujourdhui,
  required AppLocalizations tr,
}) {
  final lignes = <String>[];
  if (aujourdhui != null) {
    final n = serie(h, aujourdhui);
    if (n >= 2) lignes.add(tr.notifSerie(n));
  }
  if (h.plan.trim().isNotEmpty) lignes.add(h.plan.trim());
  if (h.versionMinimale.trim().isNotEmpty) {
    lignes.add(tr.notifMinimale(h.versionMinimale.trim()));
  }
  if (lignes.isEmpty && h.pourquoi.trim().isNotEmpty) {
    lignes.add(tr.notifPourquoi(h.pourquoi.trim()));
  }
  if (lignes.isEmpty) lignes.add(tr.notifGenerique);
  return lignes.take(2).join('\n');
}
