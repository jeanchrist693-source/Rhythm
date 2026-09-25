// lib/ecrans/alimentation/recettes/planifier_ecran.dart
//
// PLANIFIER une recette : le jour (les sept à venir), le moment (le sien
// d'abord), les portions ; ce qui est déjà prévu à ce moment-là.
// « Ajouter à ma semaine ».

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
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
import 'pieces_recettes.dart';

class PlanifierEcran extends ConsumerStatefulWidget {
  const PlanifierEcran({
    super.key,
    required this.recette,
    required this.retour,
  });

  final Recette recette;
  final String retour;

  @override
  ConsumerState<PlanifierEcran> createState() => _PlanifierEcranState();
}

class _PlanifierEcranState extends ConsumerState<PlanifierEcran> {
  late DateTime _jour = jourDe(ref.read(aujourdhuiProvider));
  late MomentRepas _moment;

  /// Les portions, en demis.
  late int _demis = ref.read(recettesProvider).reglages.personnes * 2;

  @override
  void initState() {
    super.initState();
    final m = widget.recette.moments;
    final maintenant = momentPourHeure(ref.read(aujourdhuiProvider));
    _moment = m.isEmpty || m.contains(maintenant)
        ? maintenant
        : MomentRepas.values.firstWhere(m.contains);
  }

  void _ajouter() {
    final tr = context.tr;
    ref
        .read(recettesProvider.notifier)
        .planifier(
          jour: _jour,
          moment: _moment,
          recetteId: widget.recette.id,
          portions: _demis / 2,
        );
    HapticFeedback.lightImpact();
    montrerToast(context, tr.prevuAuToast(widget.recette.nom, _moment.name));
    retirerEcran(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(recettesProvider);
    final produits = ref.watch(alimentationProvider);
    final auj = jourDe(ref.watch(aujourdhuiProvider));
    final deja = [
      for (final p in etat.prevusLe(_jour, _moment))
        etat.recette(p.recetteId)?.nom ??
            produits.produit(p.produitId ?? '')?.nom ??
            p.libre ??
            '—',
    ];

    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(
          titre: tr.planifier,
          surtitre: Text(widget.recette.nom, style: RhythmTypo.surtitre),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(_jour == auj ? tr.aujourdhui : f.jourComplet(_jour)),
            SeptJours(
              aujourdhui: auj,
              choisi: _jour,
              aDesRepas: (j) => etat.prevusLe(j).isNotEmpty,
              onChoisir: (j) {
                HapticFeedback.selectionClick();
                setState(() => _jour = j);
              },
            ),
            const SizedBox(height: 14),
            PucesChoix<MomentRepas>(
              options: [for (final m in MomentRepas.values) (m, m.libelle(tr))],
              valeur: _moment,
              onChanged: (m) => setState(() => _moment = m),
            ),
            if (deja.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(tr.dejaPrevu(deja.join(', ')), style: RhythmTypo.detail),
            ],
          ],
        ),
        LigneReglage(
          libelle: tr.portionsPrevues,
          droite: CompteurRhythm(
            valeur: _demis,
            min: 1,
            max: 48,
            largeurValeur: 64,
            affichage: (d) => f.fraction(d / 2),
            onChanged: (d) => setState(() => _demis = d),
          ),
        ),
        BoutonPlein(
          libelle: tr.ajouterAMaSemaine,
          largeurPleine: true,
          hauteur: 52,
          taillePolice: 15,
          onTap: _ajouter,
        ),
      ],
    );
  }
}
