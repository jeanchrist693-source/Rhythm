// lib/widgets/boutons.dart
//
// Les boutons de la maquette, tous en capsule :
// - **BoutonPlein** : blanc, texte noir 600 — l'action principale
//   (« Commencer », « Continuer · Jean 3 → ») ;
// - **BoutonContour** : transparent, filet blanc 20 % (« Partager ») ;
// - **BoutonRond** : disque de couleur, pictogramme ou signe noir
//   (« + » d'un repas) ;
// - **BoutonCapsule** : pictogramme + libellé, blanche (l'action
//   principale) ou cerclée — « + Nouvelle habitude », « Rappels »,
//   « Créer une séance ».

import 'package:flutter/material.dart';

import '../theme/rhythm_couleurs.dart';
import '../theme/rhythm_typo.dart';
import 'pictos.dart';
import 'pression_echelle.dart';

class BoutonPlein extends StatelessWidget {
  const BoutonPlein({
    super.key,
    required this.libelle,
    required this.onTap,
    this.hauteur = 44,
    this.taillePolice = 14,
    this.largeurPleine = false,
    this.fleche = false,
  });

  final String libelle;
  final VoidCallback onTap;
  final double hauteur;
  final double taillePolice;

  /// Toute la largeur disponible (« Continuer »), sinon celle du texte.
  final bool largeurPleine;

  /// Une flèche après le libellé.
  final bool fleche;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: PressionEchelle(
      onTap: onTap,
      child: Container(
        height: hauteur,
        width: largeurPleine ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: RhythmCouleurs.blanc,
          borderRadius: BorderRadius.circular(hauteur / 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                libelle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RhythmTypo.texte(
                  taillePolice,
                  poids: 600,
                  couleur: RhythmCouleurs.noir,
                ),
              ),
            ),
            if (fleche) ...[
              const SizedBox(width: 8),
              const PictoRhythm(
                Picto.fleche,
                taille: 18,
                couleur: RhythmCouleurs.noir,
                epaisseur: 2,
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class BoutonContour extends StatelessWidget {
  const BoutonContour({super.key, required this.libelle, required this.onTap});

  final String libelle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: PressionEchelle(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: RhythmCouleurs.bordBouton),
        ),
        child: Text(libelle, style: RhythmTypo.texte(13, poids: 500)),
      ),
    ),
  );
}

class BoutonRond extends StatelessWidget {
  const BoutonRond({
    super.key,
    required this.couleur,
    required this.libelle,
    required this.onTap,
    required this.child,
  });

  final Color couleur;

  /// Pour le lecteur d'écran (« Ajouter un repas »).
  final String libelle;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: libelle,
    excludeSemantics: true,
    child: PressionEchelle(
      onTap: onTap,
      echelle: 0.92,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
        child: child,
      ),
    ),
  );
}

class BoutonCapsule extends StatelessWidget {
  const BoutonCapsule({
    super.key,
    required this.picto,
    required this.libelle,
    required this.onTap,
    this.plein = false,
    this.hauteur = 44,
  });

  final Picto picto;
  final String libelle;
  final VoidCallback onTap;

  /// Blanche, texte noir (l'action principale) ; sinon cerclée.
  final bool plein;
  final double hauteur;

  @override
  Widget build(BuildContext context) {
    final encre = plein ? RhythmCouleurs.noir : RhythmCouleurs.texte;
    return Semantics(
      button: true,
      child: PressionEchelle(
        onTap: onTap,
        echelle: 0.96,
        child: Container(
          height: hauteur,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: plein ? RhythmCouleurs.blanc : null,
            borderRadius: BorderRadius.circular(hauteur / 2),
            border: plein ? null : Border.all(color: RhythmCouleurs.bordBouton),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PictoRhythm(picto, taille: 18, epaisseur: 2.2, couleur: encre),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  libelle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RhythmTypo.texte(14, poids: 600, couleur: encre),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
