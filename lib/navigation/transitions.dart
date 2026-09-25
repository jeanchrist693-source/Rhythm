// lib/navigation/transitions.dart
//
// Transition des écrans secondaires, reprise telle quelle de Net Worth et
// Studio (même sensation dans les trois apps) : le « fade forwards »
// Material — fondu + léger glissement, page du dessous qui recule — ralenti
// à 550 ms.
//
// Plomberie invisible héritée de MyTV / Flow : clavier refermé 280 ms AVANT
// la transition (sinon l'écran de destination arrive décalé), verrou pour
// qu'un second appui pendant l'animation n'empile pas deux fois le même
// écran, poussée toujours sur le Navigator racine. Toujours
// `pousserEcran` / `retirerEcran`, jamais `Navigator.push/pop` directs.

import 'package:flutter/material.dart';

/// Durée du fondu-glissement (Flutter : 450 ms).
const Duration kDureeTransition = Duration(milliseconds: 550);

/// Temps laissé au clavier pour disparaître avant qu'une transition démarre.
const Duration kDelaiClavier = Duration(milliseconds: 280);

/// Le « fade forwards » Material, ralenti. Installé dans le thème.
class FonduAvantLent extends FadeForwardsPageTransitionsBuilder {
  const FonduAvantLent({super.backgroundColor});

  @override
  Duration get transitionDuration => kDureeTransition;

  @override
  Duration get reverseTransitionDuration => kDureeTransition;
}

/// Pousse un sous-écran sur le Navigator RACINE (le bouton retour du
/// système ne s'adresse qu'à lui), clavier refermé d'abord s'il est ouvert.
Future<T?> pousserEcran<T>(BuildContext context, Widget enfant) async {
  if (!reserverTransition(context)) return null;
  final navigateur = Navigator.of(context, rootNavigator: true);
  await fermerClavier(context);
  if (!navigateur.mounted) return null;
  return navigateur.push<T>(MaterialPageRoute<T>(builder: (_) => enfant));
}

/// Referme un sous-écran avec la même politesse que [pousserEcran].
Future<void> retirerEcran<T extends Object?>(
  BuildContext context, [
  T? resultat,
]) async {
  if (!reserverTransition(context)) return;
  final navigateur = Navigator.of(context);
  await fermerClavier(context);
  if (navigateur.mounted) navigateur.pop(resultat);
}

/// Referme [n] sous-écrans d'un coup (une recette supprimée depuis son
/// formulaire : on revient au livre, pas à sa fiche vide).
Future<void> retirerEcrans(BuildContext context, int n) async {
  if (!reserverTransition(context)) return;
  final navigateur = Navigator.of(context);
  await fermerClavier(context);
  if (!navigateur.mounted) return;
  var i = 0;
  navigateur.popUntil((_) => i++ >= n);
}

/// Remplace l'écran du dessus par [enfant] (le magasin cède la place au
/// rangement : le retour mène à la liste, pas au panier vidé).
Future<T?> remplacerEcran<T>(BuildContext context, Widget enfant) async {
  if (!reserverTransition(context)) return null;
  final navigateur = Navigator.of(context, rootNavigator: true);
  await fermerClavier(context);
  if (!navigateur.mounted) return null;
  return navigateur.pushReplacement<T, Object?>(
    MaterialPageRoute<T>(builder: (_) => enfant),
  );
}

// ── Verrou : une transition à la fois ──────────────────────────────────────
// La libération est programmée dès la prise (jamais dans un `finally`) :
// mieux vaut relâcher trop tôt que bloquer la navigation.

bool _transitionEnCours = false;

bool reserverTransition(BuildContext context) {
  if (_transitionEnCours) return false;
  _transitionEnCours = true;
  final clavier = MediaQuery.viewInsetsOf(context).bottom > 0;
  final duree = clavier ? kDelaiClavier + kDureeTransition : kDureeTransition;
  Future<void>.delayed(duree, () => _transitionEnCours = false);
  return true;
}

/// Referme le clavier et lui laisse le temps de descendre — seulement s'il
/// est réellement ouvert.
Future<void> fermerClavier(BuildContext context) async {
  if (MediaQuery.viewInsetsOf(context).bottom <= 0) return;
  FocusManager.instance.primaryFocus?.unfocus();
  await Future<void>.delayed(kDelaiClavier);
}
