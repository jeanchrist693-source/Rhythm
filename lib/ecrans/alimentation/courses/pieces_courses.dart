// lib/ecrans/alimentation/courses/pieces_courses.dart
//
// Les pièces partagées des écrans d'achats, dans le langage de Rhythm (ni
// cartes ni lueurs) :
// - [LigneCourse] : un article (le cercle à gauche au magasin, le nom, un
//   détail, une valeur à droite) ;
// - [Echeance] : « demain » en pêche, « aujourd'hui » en corail ;
// - [ChoixDate] : une date en jours à partir d'aujourd'hui, − / + ;
// - [ChoixEmplacement] : frigo, congélateur, armoire, comptoir ;
// - [BarreCaisse] : le total à la caisse, posé en bas de l'écran du
//   magasin (noir, un filet au-dessus — pas de verre).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/libelles_courses.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/taxes.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_mesures.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/pictos.dart';
import '../../../widgets/pression_echelle.dart';

/// Un article dans une liste d'achats. [coche] : `null` sans cercle,
/// sinon vide (à prendre) ou plein (au panier).
class LigneCourse extends StatelessWidget {
  const LigneCourse({
    super.key,
    required this.nom,
    this.detail,
    this.detailCouleur,
    this.valeur,
    this.valeurWidget,
    this.coche,
    this.onTap,
    this.filet = true,
  });

  final String nom;
  final String? detail;
  final Color? detailCouleur;
  final String? valeur;
  final Widget? valeurWidget;
  final bool? coche;
  final VoidCallback? onTap;
  final bool filet;

  @override
  Widget build(BuildContext context) {
    final c = coche;
    final ligne = Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          if (c != null) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c ? RhythmCouleurs.menthe : null,
                border: c
                    ? null
                    : Border.all(color: RhythmCouleurs.cocheVide, width: 2),
              ),
              child: c
                  ? const Center(
                      child: PictoRhythm(
                        Picto.coche,
                        taille: 16,
                        epaisseur: 2.6,
                        couleur: RhythmCouleurs.noir,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: RhythmTypo.texte(
                    15,
                    poids: 500,
                    couleur: c == true
                        ? RhythmCouleurs.texte72
                        : RhythmCouleurs.texte,
                  ),
                ),
                if (detail != null && detail!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: RhythmTypo.texte(
                      13,
                      couleur: detailCouleur ?? RhythmCouleurs.texte64,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (valeurWidget != null) ...[
            const SizedBox(width: 12),
            valeurWidget!,
          ] else if (valeur != null) ...[
            const SizedBox(width: 12),
            Text(valeur!, style: RhythmTypo.texte(14)),
          ],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (filet) const Filet(),
        if (onTap == null)
          ligne
        else
          Semantics(
            button: true,
            child: PressionEchelle(echelle: 0.98, onTap: onTap, child: ligne),
          ),
      ],
    );
  }
}

/// La couleur d'une échéance : passée ou aujourd'hui en corail, dans 3
/// jours au plus en pêche, sinon discrète.
Color couleurEcheance(int? jours) => jours == null
    ? RhythmCouleurs.texte64
    : jours <= 0
    ? RhythmCouleurs.corail
    : jours <= 3
    ? RhythmCouleurs.peche
    : RhythmCouleurs.texte64;

class Echeance extends StatelessWidget {
  const Echeance({super.key, required this.jours, this.taille = 13});

  final int? jours;
  final double taille;

  @override
  Widget build(BuildContext context) {
    final j = jours;
    if (j == null) return const SizedBox.shrink();
    return Text(
      context.formats.echeance(j, context.tr),
      style: RhythmTypo.texte(
        taille,
        poids: j <= 3 ? 600 : 400,
        couleur: couleurEcheance(j),
      ),
    );
  }
}

/// Une date choisie en jours à partir d'aujourd'hui (− / +, appui long
/// pour défiler) ; la date écrite dessous.
class ChoixDate extends StatelessWidget {
  const ChoixDate({
    super.key,
    required this.aujourdhui,
    required this.date,
    required this.onChanged,
    this.libelle,
  });

  final DateTime aujourdhui;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;
  final String? libelle;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final auj = jourDe(aujourdhui);
    final d = date;
    final jours = d == null ? null : joursEntre(auj, d);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                libelle ?? tr.aConsommerAvant,
                style: RhythmTypo.texte(15, poids: 500),
              ),
              const SizedBox(height: 2),
              Text(
                d == null ? tr.sansDate : f.dateCourte(d),
                style: RhythmTypo.texte(13, couleur: couleurEcheance(jours)),
              ),
            ],
          ),
        ),
        CompteurRhythm(
          valeur: jours ?? 7,
          min: -30,
          max: 1000,
          largeurValeur: 96,
          affichage: (j) => d == null ? '—' : f.echeance(j, tr),
          onChanged: (j) => onChanged(plusJours(auj, j)),
        ),
      ],
    );
  }
}

/// Frigo, congélateur, armoire, comptoir : quatre capsules de même largeur,
/// sur une ligne (comme les jours d'une habitude).
class ChoixEmplacement extends StatelessWidget {
  const ChoixEmplacement({
    super.key,
    required this.valeur,
    required this.onChanged,
  });

  final Emplacement valeur;
  final ValueChanged<Emplacement> onChanged;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Row(
      children: [
        for (final (i, e) in Emplacement.values.indexed) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: Semantics(
              button: true,
              selected: e == valeur,
              child: PressionEchelle(
                echelle: 0.94,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(e);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 40,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: e == valeur
                        ? RhythmCouleurs.blanc
                        : RhythmCouleurs.capsule,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      e.libelle(tr),
                      maxLines: 1,
                      style: RhythmTypo.texte(
                        14,
                        poids: 500,
                        couleur: e == valeur
                            ? RhythmCouleurs.noir
                            : RhythmCouleurs.texte72,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Le total à la caisse, en bas de l'écran du magasin : sous-total, TPS,
/// TVQ, consigne, et le bouton de fin.
class BarreCaisse extends StatelessWidget {
  const BarreCaisse({
    super.key,
    required this.caisse,
    required this.bouton,
    this.budgetRestant,
  });

  final Caisse caisse;
  final Widget bouton;
  final double? budgetRestant;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final bas = MediaQuery.viewPaddingOf(context).bottom;
    final details = [
      tr.sousTotalValeur(f.prix(caisse.sousTotal)),
      tr.tpsValeur(f.prix(caisse.tps)),
      tr.tvqValeur(f.prix(caisse.tvq)),
      if (caisse.consigne > 0) tr.consigneValeur(f.prix(caisse.consigne)),
    ].join(' · ');
    // Posée par-dessus la page, hors de son Scaffold : sans ce Material,
    // le texte prendrait le style d'erreur (souligné jaune).
    return Material(
      color: RhythmCouleurs.fond,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          RhythmEspaces.marge,
          0,
          RhythmEspaces.marge,
          bas + 14,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Filet(couleur: RhythmCouleurs.filetGrille),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.totalCaisse, style: RhythmTypo.petit),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          f.prix(caisse.total),
                          style: RhythmTypo.titre(30),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                bouton,
              ],
            ),
            const SizedBox(height: 6),
            Text(details, style: RhythmTypo.petit),
            if (budgetRestant != null) ...[
              const SizedBox(height: 2),
              Text(
                budgetRestant! >= 0
                    ? tr.budgetRestant(f.prix(budgetRestant!))
                    : tr.budgetDepasse(f.prix(-budgetRestant!)),
                style: RhythmTypo.texte(
                  12,
                  couleur: budgetRestant! >= 0
                      ? RhythmCouleurs.menthe
                      : RhythmCouleurs.corail,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
