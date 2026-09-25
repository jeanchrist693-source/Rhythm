// lib/ecrans/alimentation/recettes/portion_recette_ecran.dart
//
// NOTER UNE RECETTE au journal : combien de portions (par demi), ce
// qu'elles apportent (la valeur par portion de la recette), le moment ;
// s'il y a des RESTES de cette recette au garde-manger, ils sont pris
// d'abord (décomptés, le plus pressé en premier) — on peut dire non.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/recettes.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/modeles.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/toast.dart';
import '../pieces_alimentation.dart';

class PortionRecetteEcran extends ConsumerStatefulWidget {
  const PortionRecetteEcran({
    super.key,
    required this.recette,
    required this.jour,
    required this.moment,
    required this.retour,
    this.portions = 1,
  });

  final Recette recette;
  final DateTime jour;
  final MomentRepas moment;
  final String retour;
  final double portions;

  @override
  ConsumerState<PortionRecetteEcran> createState() =>
      _PortionRecetteEcranState();
}

class _PortionRecetteEcranState extends ConsumerState<PortionRecetteEcran> {
  late int _demis = (widget.portions * 2).round().clamp(1, 48);
  late MomentRepas _moment = widget.moment;
  bool _depuisRestes = true;

  void _ajouter(bool restes) {
    final tr = context.tr;
    final f = context.formats;
    final e = ref
        .read(recettesProvider.notifier)
        .noter(
          recette: widget.recette,
          portions: _demis / 2,
          jour: widget.jour,
          moment: _moment,
          depuisRestes: restes && _depuisRestes,
        );
    HapticFeedback.lightImpact();
    montrerToast(
      context,
      tr.ajouteA(tr.auMoment(_moment.name), f.kcalDe(e.nutriments.kcal, tr)),
    );
    retirerEcran(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final r = widget.recette;
    final auj = jourDe(ref.watch(aujourdhuiProvider));
    final jour = jourDe(widget.jour);
    final restes = portionsEnRestes(
      ref.watch(coursesProvider).gardeManger,
      r.id,
    );
    final n = _demis / 2;

    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(
          titre: r.nom,
          surtitre: Text(
            jour == auj ? tr.aujourdhui : f.jourComplet(jour),
            style: RhythmTypo.surtitre,
          ),
        ),
        LigneReglage(
          libelle: tr.nombreDePortions,
          droite: CompteurRhythm(
            valeur: _demis,
            min: 1,
            max: 48,
            largeurValeur: 64,
            affichage: (d) => f.fraction(d / 2),
            onChanged: (d) => setState(() => _demis = d),
          ),
        ),
        ApercuNutriments(nutriments: r.parPortion * n),
        if (restes > 0)
          LigneReglage(
            libelle: tr.prisDansLesRestes,
            detail: tr.restesDisponibles(f.portions(restes, tr)),
            droite: Interrupteur(
              valeur: _depuisRestes,
              onChanged: (v) => setState(() => _depuisRestes = v),
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.moment),
            PucesChoix<MomentRepas>(
              options: [for (final m in MomentRepas.values) (m, m.libelle(tr))],
              valeur: _moment,
              onChanged: (m) => setState(() => _moment = m),
            ),
          ],
        ),
        BoutonPlein(
          libelle: tr.ajouterAu(tr.auMoment(_moment.name)),
          largeurPleine: true,
          hauteur: 52,
          taillePolice: 15,
          onTap: () => _ajouter(restes > 0),
        ),
      ],
    );
  }
}
