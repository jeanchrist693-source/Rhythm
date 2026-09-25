// lib/widgets/page_secondaire.dart
//
// Squelette d'un écran SECONDAIRE (sans barre de navigation) : fiche d'une
// habitude, formulaire, « J'ai une envie », rappels. Composition de Studio,
// dans la langue de Rhythm : en haut à gauche le retour (chevron + nom de
// l'écran d'où l'on vient), à droite les boutons de l'écran ; puis les
// sections posées sur le noir, séparées par de l'air (28), qui défilent
// sous le voile de la barre d'état. Ni cartes ni lueurs.
//
// Le clavier se ferme en touchant un VIDE de la page — pas en défilant, pas
// en touchant un champ ou un bouton (ils gagnent le geste).
//
// Un formulaire branche ici le suivi du clavier (`SuiviClavierMixin`) :
// [controleur] = son `defilementClavier`, [basSupplementaire] = son
// `paddingBasClavier`. Le Scaffold ne se redimensionne jamais au clavier.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/transitions.dart';
import '../theme/rhythm_couleurs.dart';
import '../theme/rhythm_mesures.dart';
import '../theme/rhythm_theme.dart';
import '../theme/rhythm_typo.dart';
import 'page_rhythm.dart';
import 'pictos.dart';
import 'pression_echelle.dart';

class PageSecondaire extends StatelessWidget {
  const PageSecondaire({
    super.key,
    required this.retour,
    required this.enfants,
    this.onRetour,
    this.actions = const [],
    this.ecart = RhythmEspaces.ecart,
    this.controleur,
    this.basSupplementaire = 0,
  });

  /// Nom de l'écran précédent, à côté du chevron (« Habitudes »).
  final String retour;
  final VoidCallback? onRetour;
  final List<Widget> actions;
  final List<Widget> enfants;
  final double ecart;
  final ScrollController? controleur;
  final double basSupplementaire;

  @override
  Widget build(BuildContext context) {
    final haut = MediaQuery.viewPaddingOf(context).top;
    final bas = MediaQuery.viewPaddingOf(context).bottom;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: RhythmTheme.barresSysteme,
      child: Scaffold(
        backgroundColor: RhythmCouleurs.fond,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: _liste(haut, bas),
              ),
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: VoileBarreEtat(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _liste(double haut, double bas) => ListView(
    controller: controleur,
    physics: const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    ),
    padding: EdgeInsets.fromLTRB(
      RhythmEspaces.marge,
      haut + 12,
      RhythmEspaces.marge,
      bas + 40 + basSupplementaire,
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
              BarreRetour(
                libelle: retour,
                onRetour: onRetour,
                actions: actions,
              ),
              const SizedBox(height: 14),
              for (var i = 0; i < enfants.length; i++) ...[
                if (i > 0) SizedBox(height: ecart),
                enfants[i],
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

/// Retour (chevron + libellé) à gauche, boutons à droite.
class BarreRetour extends StatelessWidget {
  const BarreRetour({
    super.key,
    required this.libelle,
    this.onRetour,
    this.actions = const [],
  });

  final String libelle;
  final VoidCallback? onRetour;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                button: true,
                child: PressionEchelle(
                  onTap: onRetour ?? () => retirerEcran(context),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const PictoRhythm(
                          Picto.retour,
                          taille: 22,
                          epaisseur: 2,
                          couleur: RhythmCouleurs.texte72,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            libelle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: RhythmTypo.texte(
                              15,
                              couleur: RhythmCouleurs.texte72,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            actions[i],
          ],
        ],
      ),
    );
  }
}

/// Un pictogramme seul, en bouton (crayon d'une fiche).
class BoutonPicto extends StatelessWidget {
  const BoutonPicto({
    super.key,
    required this.picto,
    required this.libelle,
    required this.onTap,
    this.couleur = RhythmCouleurs.texte,
  });

  final Picto picto;
  final Color couleur;

  /// Pour le lecteur d'écran.
  final String libelle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: libelle,
    excludeSemantics: true,
    child: PressionEchelle(
      onTap: onTap,
      echelle: 0.92,
      child: SizedBox.square(
        dimension: 48,
        child: Center(child: PictoRhythm(picto, taille: 22, couleur: couleur)),
      ),
    ),
  );
}

/// Le titre d'un écran secondaire : un surtitre, puis le titre (Bricolage
/// 30), sur toute la largeur.
class TitreSecondaire extends StatelessWidget {
  const TitreSecondaire({
    super.key,
    required this.titre,
    this.surtitre,
    this.gauche,
  });

  final String titre;
  final Widget? surtitre;

  /// Une pastille avant le titre (la lettre d'une habitude).
  final Widget? gauche;

  @override
  Widget build(BuildContext context) {
    final textes = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (surtitre != null) ...[surtitre!, const SizedBox(height: 4)],
        Semantics(
          header: true,
          child: Text(titre, style: RhythmTypo.titre(30, hauteur: 1.1)),
        ),
      ],
    );
    if (gauche == null) return textes;
    return Row(
      children: [
        gauche!,
        const SizedBox(width: 16),
        Expanded(child: textes),
      ],
    );
  }
}

/// Le titre d'une section (« Pourquoi », « Historique ») : petites
/// capitales, rien autour.
class TitreSection extends StatelessWidget {
  const TitreSection(this.texte, {super.key, this.couleur, this.droite});

  final String texte;
  final Color? couleur;
  final Widget? droite;

  @override
  Widget build(BuildContext context) {
    final t = Text(
      texte.toUpperCase(),
      style: RhythmTypo.texte(
        13,
        poids: 600,
        couleur: couleur ?? RhythmCouleurs.texte64,
        espacement: 0.06,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: droite == null
          ? t
          : Row(
              children: [
                Expanded(child: t),
                droite!,
              ],
            ),
    );
  }
}
