// lib/ecrans/habitudes/pieces_habitudes.dart
//
// Les petites pièces partagées par les écrans des habitudes : la pastille
// d'une habitude (sa lettre sur sa teinte), une horloge qui fait vivre les
// compteurs de libération, une statistique (libellé + chiffre), la jauge du
// prochain palier — et le BLOC LIBÉRATION, le même sur l'accueil et en tête
// des Habitudes.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/traductions.dart';
import '../../modele/calculs_habitudes.dart';
import '../../modele/etat_sante.dart';
import '../../modele/habitudes.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/filets.dart';
import '../../widgets/jauges.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';

/// La lettre d'une habitude sur sa teinte (un disque, jamais une boîte).
class PastilleHabitude extends StatelessWidget {
  const PastilleHabitude({super.key, required this.habitude, this.taille = 34});

  final Habitude habitude;
  final double taille;

  @override
  Widget build(BuildContext context) => Container(
    width: taille,
    height: taille,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: habitude.teinte.couleur,
      shape: BoxShape.circle,
    ),
    child: Text(
      habitude.lettre,
      style: RhythmTypo.texte(
        taille * 0.36,
        poids: 600,
        couleur: RhythmCouleurs.noir,
      ),
    ),
  );
}

/// Reconstruit [constructeur] toutes les [periode] avec l'heure qu'il est
/// (les compteurs de libération). En pause quand l'onglet est caché.
class Horloge extends ConsumerStatefulWidget {
  const Horloge({
    super.key,
    required this.constructeur,
    this.periode = const Duration(seconds: 30),
  });

  final Widget Function(BuildContext context, DateTime maintenant) constructeur;
  final Duration periode;

  @override
  ConsumerState<Horloge> createState() => _HorlogeState();
}

class _HorlogeState extends ConsumerState<Horloge> {
  Timer? _timer;

  /// L'onglet est visible (`TickerMode`) : lu à chaque construction.
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.periode, (_) {
      if (mounted && _visible) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _visible = TickerMode.valuesOf(context).enabled;
    return widget.constructeur(context, ref.read(horlogeProvider)());
  }
}

/// Une statistique : le libellé au-dessus, le chiffre en dessous.
class StatHabitude extends StatelessWidget {
  const StatHabitude({
    super.key,
    required this.libelle,
    required this.valeur,
    this.couleur = RhythmCouleurs.texte,
  });

  final String libelle;
  final String valeur;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(libelle, style: RhythmTypo.petit, maxLines: 1),
      ),
      const SizedBox(height: 4),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          valeur,
          maxLines: 1,
          style: RhythmTypo.chiffreStat.copyWith(color: couleur),
        ),
      ),
    ],
  );
}

/// « Prochain palier : 14 jours · encore 3 jours », et sa jauge.
class JaugePalier extends StatelessWidget {
  const JaugePalier({
    super.key,
    required this.titre,
    required this.detail,
    required this.progression,
    required this.couleur,
  });

  final String titre;
  final String detail;
  final double progression;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(titre, style: RhythmTypo.texte(15, poids: 500))),
          const SizedBox(width: 12),
          Text(detail, style: RhythmTypo.detail),
        ],
      ),
      const SizedBox(height: 10),
      Jauge(progression: progression, couleur: couleur, hauteur: 5),
    ],
  );
}

/// Le BLOC LIBÉRATION : pour chaque habitude à libérer, les jours en grand,
/// le nom et les heures qui vivent, la jauge du prochain palier, et
/// « Envie ? » qui ouvre le soutien. La ligne mène à la fiche. [comptage]
/// (0 → 1) fait compter les jours à l'entrée de l'accueil.
class BlocLiberation extends StatelessWidget {
  const BlocLiberation({
    super.key,
    required this.habitudes,
    required this.onOuvrir,
    required this.onEnvie,
    this.comptage,
  });

  final List<Habitude> habitudes;
  final ValueChanged<Habitude> onOuvrir;
  final ValueChanged<Habitude> onEnvie;
  final Animation<double>? comptage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const PictoRhythm(
              Picto.vague,
              taille: 16,
              epaisseur: 2.2,
              couleur: RhythmCouleurs.menthe,
            ),
            const SizedBox(width: 8),
            Text(
              context.tr.liberation.toUpperCase(),
              style: RhythmTypo.texte(
                13,
                poids: 600,
                couleur: RhythmCouleurs.menthe,
                espacement: 0.06,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < habitudes.length; i++) ...[
          if (i > 0) const Filet(),
          _CompteurLiberation(
            habitude: habitudes[i],
            comptage: comptage,
            onTap: () => onOuvrir(habitudes[i]),
            onEnvie: () => onEnvie(habitudes[i]),
          ),
        ],
      ],
    );
  }
}

class _CompteurLiberation extends StatelessWidget {
  const _CompteurLiberation({
    required this.habitude,
    required this.comptage,
    required this.onTap,
    required this.onEnvie,
  });

  final Habitude habitude;
  final Animation<double>? comptage;
  final VoidCallback onTap;
  final VoidCallback onEnvie;

  Widget _contenu(BuildContext context, DateTime maintenant, double p) {
    final tr = context.tr;
    final f = context.formats;
    final h = habitude;
    final libre = dureeLiberte(h, maintenant);
    final jours = libre.inMinutes / Duration.minutesPerDay;
    final palier = prochainPalier(kPaliersLiberte, jours);
    final fin = plusJoursInstant(h.debutLiberte, palier.suivant);
    final heures = libre.inHours % 24, minutes = libre.inMinutes % 60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '${(libre.inDays * p).round()}',
                    style: RhythmTypo.titre(40, poids: 500, espacement: -0.03),
                  ),
                  const SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      tr.joursLibresUnite(libre.inDays),
                      maxLines: 1,
                      style: RhythmTypo.titre(
                        17,
                        poids: 500,
                        couleur: RhythmCouleurs.texte72,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            BoutonEnvie(onTap: onEnvie),
          ],
        ),
        Text(
          '${h.nom} · $heures\u00a0h '
          '${minutes.toString().padLeft(2, '0')}\u00a0min',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: RhythmTypo.detail,
        ),
        const SizedBox(height: 10),
        Jauge(
          progression:
              (jours - palier.precedent) /
              (palier.suivant - palier.precedent) *
              p,
          couleur: RhythmCouleurs.menthe,
          hauteur: 4,
        ),
        const SizedBox(height: 6),
        Text(
          '${tr.prochainPalierDuree(f.palier(palier.suivant, tr))}'
          ' · ${tr.dansDuree(f.duree(fin.difference(maintenant)))}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: RhythmTypo.petit,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final comptage = this.comptage;
    return Semantics(
      button: true,
      label: habitude.nom,
      child: PressionEchelle(
        onTap: onTap,
        echelle: 0.985,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Horloge(
            constructeur: (context, maintenant) => comptage == null
                ? _contenu(context, maintenant, 1)
                : AnimatedBuilder(
                    animation: comptage,
                    builder: (context, _) =>
                        _contenu(context, maintenant, comptage.value),
                  ),
          ),
        ),
      ),
    );
  }
}

/// « Envie ? » : une capsule cerclée, qui ouvre le soutien.
class BoutonEnvie extends StatelessWidget {
  const BoutonEnvie({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: PressionEchelle(
      onTap: onTap,
      echelle: 0.94,
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: RhythmCouleurs.bordBouton),
        ),
        child: Text(
          context.tr.envieBouton,
          style: RhythmTypo.texte(14, poids: 600),
        ),
      ),
    ),
  );
}
