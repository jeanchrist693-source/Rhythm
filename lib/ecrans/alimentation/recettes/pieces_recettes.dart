// lib/ecrans/alimentation/recettes/pieces_recettes.dart
//
// Les pièces partagées des écrans de RECETTES, dans le langage de Rhythm
// (filets, capsules, disques ; ni cartes ni lueurs) :
// - [detailRecette] : « 4 portions · 35 min · 40 g de protéines » ;
// - [TexteEtape] : une étape, ses minuteurs soulignés en pêche — touchables
//   dans le mode cuisine ;
// - [BarreCuisine] : le bas FIXE du mode cuisine — les minuteurs en cours,
//   puis « Précédente » / « Suivante » (noir, un filet au-dessus — comme la
//   caisse du magasin) ;
// - [SeptJours] : les sept jours à partir d'aujourd'hui (la semaine
//   prévue) ;
// - [RangeePuces] : un choix en capsules sur UNE rangée qui défile de côté
//   (les filtres du livre : une rangée chacun, pas trois) ;
// - [ChoixRegion] : la région en deux rangées — la grande région, puis ses
//   cuisines.

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/recettes.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_mesures.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../pieces_alimentation.dart';

/// « 4 portions · 35 min · 40 g de protéines ».
String detailRecette(Recette r, Formats f, AppLocalizations tr) => [
  f.portions(r.portions.toDouble(), tr),
  if (r.dureeTotale != null) f.minutes(r.dureeTotale!),
  if (r.parPortion.proteines >= 1)
    tr.proteinesDe(f.g(r.parPortion.proteines, tr)),
  ?r.region,
].join(' · ');

/// Une étape : ses minuteurs soulignés (pêche) ; touchables si
/// [onMinuteur].
class TexteEtape extends StatefulWidget {
  const TexteEtape({
    super.key,
    required this.texte,
    required this.style,
    this.onMinuteur,
    this.maxLignes,
  });

  final String texte;
  final TextStyle style;
  final ValueChanged<RepereMinuteur>? onMinuteur;
  final int? maxLignes;

  @override
  State<TexteEtape> createState() => _TexteEtapeState();
}

class _TexteEtapeState extends State<TexteEtape> {
  /// Les minuteurs repérés et leurs gestes, gardés tant que le texte ne
  /// change pas : le mode cuisine se redessine toutes les 250 ms quand un
  /// minuteur tourne, et un geste recréé à chaque fois annulait le toucher
  /// en cours (« 10 minutes » ne réagissait qu'une fois sur deux).
  late List<RepereMinuteur> _reperes;
  List<TapGestureRecognizer?> _gestes = const [];

  @override
  void initState() {
    super.initState();
    _preparer();
  }

  @override
  void didUpdateWidget(TexteEtape ancien) {
    super.didUpdateWidget(ancien);
    if (ancien.texte != widget.texte ||
        (ancien.onMinuteur == null) != (widget.onMinuteur == null)) {
      _liberer();
      _preparer();
    }
  }

  void _preparer() {
    _reperes = minuteursDans(widget.texte);
    _gestes = [
      for (final r in _reperes)
        widget.onMinuteur == null
            ? null
            // Le rappel lu au moment du toucher : toujours le dernier.
            : (TapGestureRecognizer()
                ..onTap = () => widget.onMinuteur?.call(r)),
    ];
  }

  void _liberer() {
    for (final g in _gestes) {
      g?.dispose();
    }
    _gestes = const [];
  }

  @override
  void dispose() {
    _liberer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.texte;
    final morceaux = <InlineSpan>[];
    var i = 0;
    for (final (k, r) in _reperes.indexed) {
      if (r.debut > i) morceaux.add(TextSpan(text: t.substring(i, r.debut)));
      morceaux.add(
        TextSpan(
          text: t.substring(r.debut, r.fin),
          recognizer: _gestes[k],
          style: const TextStyle(
            color: RhythmCouleurs.peche,
            decoration: TextDecoration.underline,
            decorationColor: Color(0x73FFD3A8),
          ),
        ),
      );
      i = r.fin;
    }
    if (i < t.length) morceaux.add(TextSpan(text: t.substring(i)));
    return Text.rich(
      TextSpan(children: morceaux),
      style: widget.style,
      maxLines: widget.maxLignes,
      overflow: widget.maxLignes == null ? null : TextOverflow.ellipsis,
    );
  }
}

/// La hauteur de la barre du mode cuisine, marge du système en moins (le
/// bas de la page passe dessus) : un filet, les minuteurs (64 chacun), la
/// rangée du [BarreCuisine.pied] (48).
double hauteurBarreCuisine(int minuteurs) => 73.0 + 64 * minuteurs;

/// Le bas FIXE du mode cuisine : les minuteurs en cours — ce qu'il reste (ou
/// « C'est l'heure » en corail), une minute de plus, arrêter —, puis le
/// [pied] (« Précédente » / « Suivante »), toujours au même endroit, quelle
/// que soit l'étape.
class BarreCuisine extends StatelessWidget {
  const BarreCuisine({
    super.key,
    required this.minuteurs,
    required this.maintenant,
    required this.onPlus,
    required this.onArreter,
    required this.pied,
  });

  final List<MinuteurCuisine> minuteurs;
  final DateTime maintenant;
  final ValueChanged<String> onPlus;
  final ValueChanged<String> onArreter;

  /// Une rangée de 48 de haut.
  final Widget pied;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final bas = MediaQuery.viewPaddingOf(context).bottom;
    // Posée par-dessus la page, hors de son Scaffold : sans ce Material,
    // le texte prendrait le style d'erreur (souligné jaune).
    return Material(
      color: RhythmCouleurs.fond,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          RhythmEspaces.marge,
          0,
          RhythmEspaces.marge,
          bas + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Filet(couleur: RhythmCouleurs.filetGrille),
            SizedBox(height: minuteurs.isEmpty ? 12 : 6),
            for (final m in minuteurs)
              SizedBox(
                height: 64,
                child: Row(
                  children: [
                    const PictoRhythm(
                      Picto.chrono,
                      taille: 20,
                      couleur: RhythmCouleurs.peche,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.libelle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: RhythmTypo.petit,
                          ),
                          Text(
                            m.fin.isAfter(maintenant)
                                ? f.minuteur(
                                    m.fin.difference(maintenant) +
                                        const Duration(milliseconds: 999),
                                  )
                                : tr.cestLHeure,
                            maxLines: 1,
                            style: RhythmTypo.titre(
                              24,
                              couleur: m.fin.isAfter(maintenant)
                                  ? RhythmCouleurs.texte
                                  : RhythmCouleurs.corail,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Puce(
                      libelle: tr.plusUneMinute,
                      choisie: false,
                      onTap: () => onPlus(m.id),
                    ),
                    BoutonPicto(
                      picto: Picto.croix,
                      libelle: tr.arreterMinuteur,
                      couleur: RhythmCouleurs.texte72,
                      onTap: () => onArreter(m.id),
                    ),
                  ],
                ),
              ),
            if (minuteurs.isNotEmpty) const SizedBox(height: 6),
            SizedBox(height: 48, child: pied),
          ],
        ),
      ),
    );
  }
}

/// Les sept jours à partir d'aujourd'hui : [choisi] en capsule blanche, un
/// point pêche les jours où un repas est prévu.
class SeptJours extends StatelessWidget {
  const SeptJours({
    super.key,
    required this.aujourdhui,
    required this.choisi,
    required this.aDesRepas,
    required this.onChoisir,
  });

  final DateTime aujourdhui;
  final DateTime choisi;
  final bool Function(DateTime) aDesRepas;
  final ValueChanged<DateTime> onChoisir;

  @override
  Widget build(BuildContext context) {
    final f = context.formats;
    final auj = jourDe(aujourdhui);
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Builder(
              builder: (context) {
                final jour = plusJours(auj, i);
                return JourCapsule(
                  initiale: f.initialeJour(jour),
                  numero: jour.day,
                  aujourdhui: i == 0,
                  choisi: jour == jourDe(choisi),
                  point: aDesRepas(jour) ? RhythmCouleurs.peche : null,
                  onTap: () => onChoisir(jour),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// Un choix en capsules sur une rangée qui défile de côté ; les capsules
/// passent sous la marge jusqu'au bord de l'écran. À l'ouverture, la
/// capsule choisie est ramenée dans la rangée si elle était au loin
/// (« Vietnamienne », en modifiant une recette).
class RangeePuces<T> extends StatefulWidget {
  const RangeePuces({
    super.key,
    required this.options,
    required this.valeur,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T? valeur;
  final ValueChanged<T> onChanged;

  @override
  State<RangeePuces<T>> createState() => _RangeePucesState<T>();
}

class _RangeePucesState<T> extends State<RangeePuces<T>> {
  final _defilement = ScrollController();
  final _choisie = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _montrerChoisie());
  }

  @override
  void dispose() {
    _defilement.dispose();
    super.dispose();
  }

  /// Seulement la rangée défile (pas la page : `Scrollable.ensureVisible`
  /// ferait aussi descendre le formulaire jusqu'à elle).
  void _montrerChoisie() {
    final puce = _choisie.currentContext?.findRenderObject();
    final rangee = context.findRenderObject();
    if (!mounted ||
        puce is! RenderBox ||
        rangee is! RenderBox ||
        !_defilement.hasClients) {
      return;
    }
    final x = puce.localToGlobal(Offset.zero, ancestor: rangee).dx;
    if (x >= 0 && x + puce.size.width <= rangee.size.width) return;
    final p = _defilement.position;
    _defilement.jumpTo(
      (p.pixels + x - 24).clamp(p.minScrollExtent, p.maxScrollExtent),
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: SingleChildScrollView(
      controller: _defilement,
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (i, (v, libelle)) in widget.options.indexed) ...[
            if (i > 0) const SizedBox(width: 8),
            Puce(
              key: v == widget.valeur ? _choisie : null,
              libelle: libelle,
              choisie: v == widget.valeur,
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onChanged(v);
              },
            ),
          ],
        ],
      ),
    ),
  );
}

/// La RÉGION en deux rangées : les grandes régions (« Afrique de
/// l'Ouest »), puis, l'une choisie, ses cuisines (« Sénégalaise »).
/// Retirer un choix : toucher de nouveau la capsule choisie — une cuisine
/// rend sa grande région, une grande région rend [aucune] — ou toucher
/// [aucune], la première capsule.
class ChoixRegion extends StatelessWidget {
  const ChoixRegion({
    super.key,
    required this.valeur,
    required this.aucune,
    required this.onChanged,
    this.regions = kRegionsCulinaires,
    this.autres = const [],
  });

  /// La région choisie ; `null` ou vide : aucune.
  final String? valeur;

  /// La première capsule (« Aucune », « Toutes les régions »).
  final String aucune;
  final ValueChanged<String?> onChanged;
  final List<RegionCulinaire> regions;

  /// Des régions à soi, hors des grandes régions (« Créole »).
  final List<String> autres;

  @override
  Widget build(BuildContext context) {
    final v = valeur?.trim() ?? '';
    final choisie = v.isEmpty
        ? null
        : regions.where((g) => dansLaRegion(v, g.nom)).firstOrNull;
    final autre = v.isEmpty || choisie != null
        ? null
        : autres.where((a) => memeRegion(a, v)).firstOrNull;
    // '' : la capsule « aucune » ; `null` : rien de choisi à l'écran (une
    // région tapée à la main, pas encore dans les capsules).
    final enHaut = v.isEmpty ? '' : choisie?.nom ?? autre;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RangeePuces<String>(
          options: [
            ('', aucune),
            for (final g in regions) (g.nom, g.nom),
            for (final a in autres) (a, a),
          ],
          valeur: enHaut,
          onChanged: (x) {
            if (x.isEmpty) {
              onChanged(null);
            } else if (x != enHaut) {
              onChanged(x);
            } else {
              // La capsule choisie, touchée de nouveau : une cuisine
              // remonte à sa grande région, la grande région s'efface.
              onChanged(memeRegion(v, x) ? null : x);
            }
          },
        ),
        if (choisie != null && choisie.cuisines.isNotEmpty) ...[
          const SizedBox(height: 8),
          RangeePuces<String>(
            key: ValueKey(choisie.nom),
            options: [for (final c in choisie.cuisines) (c, c)],
            valeur: choisie.cuisines.where((c) => memeRegion(c, v)).firstOrNull,
            onChanged: (c) => onChanged(memeRegion(c, v) ? choisie.nom : c),
          ),
        ],
      ],
    );
  }
}
