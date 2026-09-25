// lib/ecrans/alimentation/pieces_alimentation.dart
//
// Les pièces partagées des écrans de l'Alimentation, dans le langage de
// Rhythm (filets, capsules, disques ; ni cartes ni lueurs) :
// - [JourCapsule] : un jour de la bande des sept derniers jours ;
// - [LigneAliment] : un aliment dans une liste (nom, détail, calories, et
//   une action à droite) ;
// - [ApercuNutriments] : les calories en grand et les trois
//   macronutriments, séparés par des filets ;
// - [ChampNombre] : un champ numérique (décimales à la virgule).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/libelles_alimentation.dart';
import '../../l10n/traductions.dart';
import '../../modele/alimentation/nutriments.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/filets.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/pression_echelle.dart';

/// Un jour : initiale, date, point. Le jour affiché est dans une capsule
/// blanche ; aujourd'hui, s'il ne l'est pas, garde un contour.
class JourCapsule extends StatelessWidget {
  const JourCapsule({
    super.key,
    required this.initiale,
    required this.numero,
    required this.aujourdhui,
    required this.choisi,
    required this.point,
    required this.onTap,
  });

  final String initiale;
  final int numero;
  final bool aujourdhui;
  final bool choisi;

  /// La couleur du point ; `null` : pas de point.
  final Color? point;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: choisi,
      child: PressionEchelle(
        onTap: onTap,
        echelle: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: choisi ? RhythmCouleurs.blanc : null,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: aujourdhui && !choisi
                  ? RhythmCouleurs.bordBouton
                  : const Color(0x00FFFFFF),
            ),
          ),
          child: Column(
            children: [
              Text(
                initiale,
                style: RhythmTypo.texte(
                  11,
                  couleur: choisi
                      ? RhythmCouleurs.noir
                      : RhythmCouleurs.texte64,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$numero',
                style: RhythmTypo.texte(
                  15,
                  poids: 600,
                  couleur: choisi ? RhythmCouleurs.noir : RhythmCouleurs.texte,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: point == null
                      ? null
                      : (choisi ? RhythmCouleurs.noir : point),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Un aliment dans une liste : son nom, un détail, ses calories ; à droite,
/// une action (« + » d'un récent). Filet au-dessus si [filet].
class LigneAliment extends StatelessWidget {
  const LigneAliment({
    super.key,
    required this.nom,
    this.detail,
    this.valeur,
    this.droite,
    this.onTap,
    this.onLongPress,
    this.filet = true,
  });

  final String nom;
  final String? detail;

  /// « 105 kcal ».
  final String? valeur;
  final Widget? droite;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool filet;

  @override
  Widget build(BuildContext context) {
    final ligne = Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: RhythmTypo.texte(15, poids: 500),
                ),
                if (detail != null && detail!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    detail!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: RhythmTypo.detail,
                  ),
                ],
              ],
            ),
          ),
          if (valeur != null) ...[
            const SizedBox(width: 12),
            Text(valeur!, style: RhythmTypo.texte(14)),
          ],
          if (droite != null) ...[const SizedBox(width: 10), droite!],
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (filet) const Filet(),
        if (onTap == null && onLongPress == null)
          ligne
        else
          GestureDetector(
            onLongPress: onLongPress == null
                ? null
                : () {
                    HapticFeedback.mediumImpact();
                    onLongPress!();
                  },
            child: PressionEchelle(echelle: 0.98, onTap: onTap, child: ligne),
          ),
      ],
    );
  }
}

/// Les calories en grand, puis protéines | glucides | lipides.
class ApercuNutriments extends StatelessWidget {
  const ApercuNutriments({super.key, required this.nutriments});

  final Nutriments nutriments;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    Widget macro(String libelle, double g, Color couleur) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(libelle, style: RhythmTypo.petit),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            f.g(g, tr),
            maxLines: 1,
            style: RhythmTypo.titre(22, couleur: couleur),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              f.entier(nutriments.kcal.round()),
              style: RhythmTypo.titre(40),
            ),
            const SizedBox(width: 6),
            Text(
              'kcal',
              style: RhythmTypo.texte(14, couleur: RhythmCouleurs.texte64),
            ),
          ],
        ),
        const SizedBox(height: 14),
        RangeeFilets(
          cases: [
            macro(tr.proteines, nutriments.proteines, RhythmCouleurs.corail),
            macro(tr.glucides, nutriments.glucides, RhythmCouleurs.peche),
            macro(tr.lipides, nutriments.lipides, RhythmCouleurs.menthe),
          ],
        ),
      ],
    );
  }
}

/// Un champ numérique : chiffres et UNE décimale (virgule ou point).
class ChampNombre extends StatelessWidget {
  const ChampNombre({
    super.key,
    required this.controleur,
    required this.focus,
    this.indice,
    this.suffixe,
    this.decimales = 1,
    this.onChanged,
    this.onValider,
    this.actionClavier = TextInputAction.next,
  });

  final TextEditingController controleur;
  final FocusNode focus;
  final String? indice;
  final String? suffixe;
  final int decimales;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onValider;
  final TextInputAction actionClavier;

  /// La valeur lue (virgule acceptée) ; `null` si vide ou illisible.
  static double? lire(TextEditingController c) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
    return v == null || v < 0 || !v.isFinite ? null : v;
  }

  @override
  Widget build(BuildContext context) {
    final motif = decimales == 0
        ? RegExp(r'^[0-9]*$')
        : RegExp('^[0-9]*[.,]?[0-9]{0,$decimales}\$');
    return ChampRhythm(
      controleur: controleur,
      focus: focus,
      indice: indice,
      suffixe: suffixe,
      clavier: TextInputType.numberWithOptions(decimal: decimales > 0),
      formateurs: [
        TextInputFormatter.withFunction(
          (a, b) => motif.hasMatch(b.text) ? b : a,
        ),
      ],
      onChanged: onChanged,
      onValider: onValider,
      actionClavier: actionClavier,
    );
  }
}
