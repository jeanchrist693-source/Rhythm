// lib/ecrans/coquille/coquille_ecran.dart
//
// Coquille des cinq écrans (Accueil, Sports, Alimentation, Habitudes,
// Biblique) : des ONGLETS dans un `IndexedStack` — chacun garde son
// défilement — et la barre flottante par-dessus.
//
// Entrée d'un onglet reprise de MyTV / Net Worth / Studio : l'`IndexedStack`
// reste, et une animation est rejouée PAR-DESSUS à chaque bascule — fondu
// `easeOutCubic` + montée de 12 px, 240 ms. Chaque onglet caché est mis en
// `TickerMode` éteint : l'`IndexedStack` garde les animations des onglets
// invisibles en marche, et quatre mascottes y tourneraient pour rien.
//
// OUVERTURE (une fois par lancement) : quand le logo de la scène d'ouverture
// commence à s'effacer (signal `SceneOuverture.ouvert`), l'accueil entre
// selon sa partition (`EntreeAccueil`) — blocs en cascade, anneaux,
// compteurs, pastilles — et la barre MONTE depuis le bas. Tout de suite
// quand la scène ne joue pas (tests).
//
// Retour d'Android : depuis un autre onglet, il ramène d'abord à l'accueil.
// Une notification touchée (un rappel d'habitude) ouvre les Habitudes.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/traductions.dart';
import '../../systeme/notifications.dart';
import '../../systeme/rappels_habitudes.dart';
import '../../systeme/rappels_garde_manger.dart';
import '../../systeme/rappels_sport.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_mesures.dart';
import '../../theme/rhythm_theme.dart';
import '../../widgets/barre_navigation.dart';
import '../../widgets/pictos.dart';
import '../../widgets/scene_ouverture.dart';
import '../accueil/accueil_ecran.dart';
import '../alimentation/alimentation_ecran.dart';
import '../biblique/biblique_ecran.dart';
import '../habitudes/habitudes_ecran.dart';
import '../sports/sports_ecran.dart';
import 'entree_accueil.dart';
import 'onglets.dart';

class CoquilleEcran extends StatefulWidget {
  const CoquilleEcran({super.key});

  @override
  State<CoquilleEcran> createState() => _CoquilleEcranState();
}

class _CoquilleEcranState extends State<CoquilleEcran>
    with TickerProviderStateMixin {
  int _onglet = Onglets.accueil;

  late final AnimationController _entree = AnimationController(
    vsync: this,
    duration: RhythmDurees.entreeOnglet,
    value: 1,
  );

  /// L'entrée de l'accueil à l'ouverture : 0 = caché, 1 = en place.
  late final AnimationController _ouverture = AnimationController(
    vsync: this,
    duration: EntreeAccueil.duree,
  );

  @override
  void initState() {
    super.initState();
    if (!SceneOuverture.active || SceneOuverture.ouvert.value) {
      _ouverture.forward();
    } else {
      SceneOuverture.ouvert.addListener(_surOuverture);
    }
    NotificationsSysteme.touchee.addListener(_surNotification);
    WidgetsBinding.instance.addPostFrameCallback((_) => _surNotification());
  }

  /// Une notification touchée : les Habitudes, ou les Sports (sans rejouer
  /// l'accueil).
  void _surNotification() {
    if (!mounted) return;
    final charge = NotificationsSysteme.touchee.value;
    final onglet = switch (charge) {
      kChargeHabitudes => Onglets.habitudes,
      kChargeSports => Onglets.sports,
      kChargeAlimentation => Onglets.alimentation,
      _ => null,
    };
    if (onglet == null) return;
    NotificationsSysteme.touchee.value = null;
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
    _aller(onglet);
  }

  void _surOuverture() {
    if (!SceneOuverture.ouvert.value) return;
    SceneOuverture.ouvert.removeListener(_surOuverture);
    if (mounted) _ouverture.forward();
  }

  @override
  void dispose() {
    NotificationsSysteme.touchee.removeListener(_surNotification);
    SceneOuverture.ouvert.removeListener(_surOuverture);
    _ouverture.dispose();
    _entree.dispose();
    super.dispose();
  }

  void _aller(int onglet) {
    if (onglet == _onglet) return;
    setState(() => _onglet = onglet);
    _entree
      ..value = 0
      ..forward();
  }

  /// Depuis une tuile ou une carte : même bascule, avec son retour tactile.
  void _allerDepuisContenu(int onglet) {
    HapticFeedback.selectionClick();
    _aller(onglet);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final onglets = <Widget>[
      AccueilEcran(entree: _ouverture, onAller: _allerDepuisContenu),
      const SportsEcran(),
      const AlimentationEcran(),
      const HabitudesEcran(),
      const BibliqueEcran(),
    ];

    return PopScope(
      canPop: _onglet == Onglets.accueil,
      onPopInvokedWithResult: (sorti, _) {
        if (!sorti) _aller(Onglets.accueil);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: RhythmTheme.barresSysteme,
        child: Scaffold(
          backgroundColor: RhythmCouleurs.fond,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _entree,
                  child: RepaintBoundary(
                    child: IndexedStack(
                      index: _onglet,
                      children: [
                        for (var i = 0; i < onglets.length; i++)
                          TickerMode(enabled: i == _onglet, child: onglets[i]),
                      ],
                    ),
                  ),
                  // ⚠️ Toujours la même forme d'arbre (Opacity + Transform,
                  // même au repos) : rendre l'enfant nu en fin de fondu
                  // recréait TOUS les onglets à chaque bascule — mascottes
                  // remises à zéro, défilement perdu (régression testée).
                  builder: (_, enfant) {
                    final v = Curves.easeOutCubic.transform(_entree.value);
                    return Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 12 * (1 - v)),
                        child: enfant,
                      ),
                    );
                  },
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: AnimatedBuilder(
                  animation: _ouverture,
                  builder: (context, barre) {
                    final b = EntreeAccueil.barre.transform(_ouverture.value);
                    // Sous le bord de l'écran au départ, puis à sa place.
                    final course =
                        RhythmEspaces.basBarre(context) +
                        RhythmEspaces.hauteurBarre +
                        16;
                    return Transform.translate(
                      offset: Offset(0, course * (1 - b)),
                      child: barre,
                    );
                  },
                  child: BarreNavigation(
                    index: _onglet,
                    onChange: _aller,
                    libelle: tr.navigationPrincipale,
                    destinations: [
                      DestinationNav(
                        picto: Picto.maison,
                        libelle: tr.navAccueil,
                      ),
                      DestinationNav(
                        picto: Picto.haltere,
                        libelle: tr.navSports,
                      ),
                      DestinationNav(
                        picto: Picto.couverts,
                        libelle: tr.navAlimentation,
                      ),
                      DestinationNav(
                        picto: Picto.cocheCercle,
                        libelle: tr.navHabitudes,
                      ),
                      DestinationNav(
                        picto: Picto.livre,
                        libelle: tr.navBiblique,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
