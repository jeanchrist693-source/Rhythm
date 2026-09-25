// lib/ecrans/alimentation/recettes/pieces_recettes.dart
//
// Les pièces partagées des écrans de RECETTES, dans le langage de Rhythm
// (filets, capsules, disques ; ni cartes ni lueurs) :
// - [detailRecette] : « 4 portions · 35 min · 40 g de protéines » ;
// - [TexteEtape] : une étape, ses minuteurs soulignés en pêche — touchables
//   dans le mode cuisine ;
// - [BarreMinuteurs] : les minuteurs en cours, posés en bas du mode cuisine
//   (noir, un filet au-dessus — comme la caisse du magasin) ;
// - [SeptJours] : les sept jours à partir d'aujourd'hui (la semaine
//   prévue) ;
// - [RangeePuces] : un choix en capsules sur UNE rangée qui défile de côté
//   (les filtres du livre : une rangée chacun, pas trois).

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
  final List<TapGestureRecognizer> _gestes = [];

  void _liberer() {
    for (final g in _gestes) {
      g.dispose();
    }
    _gestes.clear();
  }

  @override
  void dispose() {
    _liberer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _liberer();
    final t = widget.texte;
    final reperes = minuteursDans(t);
    final morceaux = <InlineSpan>[];
    var i = 0;
    for (final r in reperes) {
      if (r.debut > i) morceaux.add(TextSpan(text: t.substring(i, r.debut)));
      TapGestureRecognizer? geste;
      if (widget.onMinuteur != null) {
        geste = TapGestureRecognizer()..onTap = () => widget.onMinuteur!(r);
        _gestes.add(geste);
      }
      morceaux.add(
        TextSpan(
          text: t.substring(r.debut, r.fin),
          recognizer: geste,
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

/// La hauteur de la barre des minuteurs (le bas de la page passe dessus).
double hauteurBarreMinuteurs(int n) => n == 0 ? 0 : 30.0 + 64 * n;

/// Les minuteurs en cours : ce qu'il reste (ou « C'est l'heure » en
/// corail), une minute de plus, arrêter.
class BarreMinuteurs extends StatelessWidget {
  const BarreMinuteurs({
    super.key,
    required this.minuteurs,
    required this.maintenant,
    required this.onPlus,
    required this.onArreter,
  });

  final List<MinuteurCuisine> minuteurs;
  final DateTime maintenant;
  final ValueChanged<String> onPlus;
  final ValueChanged<String> onArreter;

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
            const SizedBox(height: 6),
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
/// passent sous la marge jusqu'au bord de l'écran.
class RangeePuces<T> extends StatelessWidget {
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
  Widget build(BuildContext context) => SizedBox(
    height: 40,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      itemCount: options.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final (v, libelle) = options[i];
        return Center(
          child: Puce(
            libelle: libelle,
            choisie: v == valeur,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        );
      },
    ),
  );
}
