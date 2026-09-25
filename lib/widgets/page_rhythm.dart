// lib/widgets/page_rhythm.dart
//
// Squelette d'un écran principal : un en-tête (surtitre, titre, mascotte ou
// bouton) puis des sections posées sur le noir, sans cartes, séparées par de
// l'air (28), le tout dans une liste qui défile — la maquette tient en 844
// de haut, le téléphone pas toujours. La dernière section peut remonter
// au-dessus de la barre flottante ; un voile noir fixe protège la barre
// d'état du contenu qui passe dessous.

import 'package:flutter/material.dart';

import '../theme/rhythm_couleurs.dart';
import '../theme/rhythm_mesures.dart';
import '../theme/rhythm_typo.dart';
import 'mascottes.dart';

class PageRhythm extends StatelessWidget {
  const PageRhythm({super.key, required this.blocs});

  /// En-tête compris (le premier) : 22 sous lui, puis 28 entre chaque
  /// section.
  final List<Widget> blocs;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ListView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            padding: EdgeInsets.fromLTRB(
              RhythmEspaces.marge,
              RhythmEspaces.haut(context),
              RhythmEspaces.marge,
              RhythmEspaces.degagementBarre(context),
            ),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: RhythmEspaces.largeurMaxContenu,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < blocs.length; i++) ...[
                        if (i > 0)
                          SizedBox(
                            height: i == 1
                                ? RhythmEspaces.ecartEnTete
                                : RhythmEspaces.ecart,
                          ),
                        blocs[i],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Positioned(top: 0, left: 0, right: 0, child: VoileBarreEtat()),
      ],
    );
  }
}

/// Voile noir statique derrière la barre d'état (repris de Studio) : ce qui
/// défile dessous s'y fond au lieu de heurter l'heure et les icônes.
class VoileBarreEtat extends StatelessWidget {
  const VoileBarreEtat({super.key});

  @override
  Widget build(BuildContext context) {
    final haut = MediaQuery.viewPaddingOf(context).top;
    return IgnorePointer(
      child: Container(
        height: haut + 14,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [RhythmCouleurs.fond, Color(0x00000000)],
            stops: [haut / (haut + 14), 1],
          ),
        ),
      ),
    );
  }
}

/// L'en-tête d'un écran : surtitre + titre à gauche, mascotte (ou bouton) à
/// droite. La mascotte (112 × 90) déborde comme dans la maquette (marges
/// −16 en haut et en bas, −8 à droite) : elle ne grandit pas l'en-tête.
class EnTete extends StatelessWidget {
  const EnTete({
    super.key,
    required this.surtitre,
    required this.titre,
    this.mascotte,
    this.action,
  });

  final Widget surtitre;
  final String titre;
  final Mascotte? mascotte;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              surtitre,
              const SizedBox(height: 4),
              // Un titre long (« Alimentation ») sur un écran étroit se
              // resserre au lieu de passer à la ligne.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Semantics(
                  header: true,
                  child: Text(
                    titre,
                    maxLines: 1,
                    softWrap: false,
                    style: RhythmTypo.titreEcran,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (mascotte != null)
          SizedBox(
            width: MascotteAnimee.taille.width - 8,
            height: MascotteAnimee.taille.height - 32,
            child: OverflowBox(
              minWidth: MascotteAnimee.taille.width,
              maxWidth: MascotteAnimee.taille.width,
              minHeight: MascotteAnimee.taille.height,
              maxHeight: MascotteAnimee.taille.height,
              alignment: Alignment.centerLeft,
              child: ExcludeSemantics(child: MascotteAnimee(mascotte!)),
            ),
          ),
        ?action,
      ],
    );
  }
}

/// Le surtitre simple d'un écran (« Semaine 39 »).
class Surtitre extends StatelessWidget {
  const Surtitre(this.texte, {super.key});

  final String texte;

  @override
  Widget build(BuildContext context) => Text(texte, style: RhythmTypo.surtitre);
}
