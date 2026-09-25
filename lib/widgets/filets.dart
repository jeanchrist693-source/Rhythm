// lib/widgets/filets.dart
//
// Le langage de Rhythm : PAS DE CARTES, PAS DE LUEURS.
//
// Pas de cartes — demande de l'utilisateur (24 septembre 2026) : les cartes
// en aplat « ne sont pas apaisantes à regarder », et il est « fatigué des
// cartes aux bords arrondis — on en a trop dans les applications. Avec
// Rhythm, je veux innover ». Pas de lueurs — essayées le même jour (une
// lueur de couleur derrière la section héros de chaque écran, une autre
// sous le doigt), puis RETIRÉES à sa demande : « réduis le glow
// considérablement », « même au toucher, j'aime pas le glow du tout »,
// « retire totalement ». Ne pas les réintroduire.
//
// Le contenu repose donc directement sur le noir OLED, et deux choses le
// structurent :
// - les FILETS — des lignes de 1 dp qui s'estompent à leurs deux bouts,
//   jamais le contour d'une boîte : entre les lignes d'une liste, entre les
//   cases d'une rangée, en croix au cœur d'une grille (`Filet`,
//   `RangeeFilets`, `GrilleFilets`) ;
// - l'AIR — plus d'espace entre les sections : le rythme vertical fait les
//   groupes que faisaient les boîtes.
// Au toucher : la légère pression d'échelle de toutes les apps
// (`PressionEchelle`), rien d'autre.

import 'package:flutter/material.dart';

import '../theme/rhythm_couleurs.dart';

/// Une ligne de 1 dp qui s'estompe à ses bouts ([fonduDebut], [fonduFin]).
/// [trace] (0 → 1) la dessine depuis [origine] — l'entrée de l'accueil
/// trace ainsi la croix de sa grille depuis son centre.
class Filet extends StatelessWidget {
  const Filet({
    super.key,
    this.vertical = false,
    this.fonduDebut = true,
    this.fonduFin = true,
    this.couleur = RhythmCouleurs.filet,
    this.trace = 1,
    this.origine = Alignment.center,
  });

  final bool vertical;
  final bool fonduDebut;
  final bool fonduFin;
  final Color couleur;
  final double trace;
  final Alignment origine;

  /// Part de la longueur sur laquelle un bout s'estompe.
  static const double _fondu = 0.22;

  @override
  Widget build(BuildContext context) {
    final transparent = couleur.withValues(alpha: 0);
    final ligne = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: vertical ? Alignment.topCenter : Alignment.centerLeft,
          end: vertical ? Alignment.bottomCenter : Alignment.centerRight,
          colors: [
            fonduDebut ? transparent : couleur,
            couleur,
            couleur,
            fonduFin ? transparent : couleur,
          ],
          stops: const [0, _fondu, 1 - _fondu, 1],
        ),
      ),
    );
    // Vertical : la hauteur vient de la rangée (étirée) — une hauteur infinie
    // ferait échouer le calcul intrinsèque d'`IntrinsicHeight`.
    return SizedBox(
      width: vertical ? 1 : double.infinity,
      height: vertical ? null : 1,
      // Le tracé est une ÉCHELLE de peinture, pas de mise en page : un
      // facteur de taille nul (début de l'entrée) rendrait une hauteur
      // intrinsèque infinie.
      child: trace >= 1
          ? ligne
          : Transform.scale(
              scaleX: vertical ? 1 : trace.clamp(0.0, 1.0),
              scaleY: vertical ? trace.clamp(0.0, 1.0) : 1,
              alignment: origine,
              child: ligne,
            ),
    );
  }
}

/// Des cases côte à côte, séparées par des filets verticaux (statistiques,
/// Prière | Méditation, et chaque rangée d'une `GrilleFilets`).
class RangeeFilets extends StatelessWidget {
  const RangeeFilets({
    super.key,
    required this.cases,
    this.ecart = 18,
    this.marges = EdgeInsets.zero,
    this.fonduHaut = true,
    this.fonduBas = true,
    this.origine = Alignment.center,
    this.trace = 1,
    this.couleur = RhythmCouleurs.filet,
  });

  final List<Widget> cases;

  /// Air de chaque côté d'un filet.
  final double ecart;

  /// Marges verticales des cases (le filet, lui, court sur toute la hauteur).
  final EdgeInsets marges;
  final bool fonduHaut;
  final bool fonduBas;
  final Alignment origine;
  final double trace;
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    final n = cases.length;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < n; i++) ...[
            if (i > 0)
              Filet(
                vertical: true,
                fonduDebut: fonduHaut,
                fonduFin: fonduBas,
                couleur: couleur,
                trace: trace,
                origine: origine,
              ),
            Expanded(
              child: Padding(
                padding: marges.copyWith(
                  left: i > 0 ? ecart : 0,
                  right: i < n - 1 ? ecart : 0,
                ),
                child: Align(alignment: Alignment.topLeft, child: cases[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Grille de 2 × 2 cases : une croix de filets en son cœur, qui s'estompe
/// vers l'extérieur — une fenêtre, pas quatre boîtes.
class GrilleFilets extends StatelessWidget {
  const GrilleFilets({
    super.key,
    required this.cases,
    this.ecart = 18,
    this.trace = 1,
  }) : assert(cases.length == 4);

  final List<Widget> cases;
  final double ecart;

  /// La croix se trace depuis son centre (0 → 1).
  final double trace;

  static const Color _couleur = RhythmCouleurs.filetGrille;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      RangeeFilets(
        cases: cases.sublist(0, 2),
        ecart: ecart,
        marges: EdgeInsets.only(bottom: ecart),
        fonduBas: false,
        origine: Alignment.bottomCenter,
        trace: trace,
        couleur: _couleur,
      ),
      Filet(couleur: _couleur, trace: trace),
      RangeeFilets(
        cases: cases.sublist(2),
        ecart: ecart,
        marges: EdgeInsets.only(top: ecart),
        fonduHaut: false,
        origine: Alignment.topCenter,
        trace: trace,
        couleur: _couleur,
      ),
    ],
  );
}
