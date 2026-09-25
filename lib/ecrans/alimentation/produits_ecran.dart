// lib/ecrans/alimentation/produits_ecran.dart
//
// MES PRODUITS : les aliments achetés dont on a recopié le tableau de la
// valeur nutritive (une barre, un yogourt, des céréales). Ils se trouvent
// en premier quand on note un repas. Toucher un produit le modifie.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_alimentation.dart';
import '../../l10n/traductions.dart';
import '../../modele/alimentation/etat_alimentation.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/boutons.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import 'pieces_alimentation.dart';
import 'produit_formulaire_ecran.dart';

class ProduitsEcran extends ConsumerWidget {
  const ProduitsEcran({super.key, required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final produits = [...ref.watch(alimentationProvider).produits]
      ..sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(titre: tr.mesProduits),
        Text(tr.mesProduitsExplication, style: RhythmTypo.detail),
        BoutonCapsule(
          picto: Picto.plus,
          libelle: tr.nouveauProduit,
          plein: true,
          onTap: () => pousserEcran(
            context,
            ProduitFormulaireEcran(retour: tr.mesProduits),
          ),
        ),
        if (produits.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, p) in produits.indexed)
                LigneAliment(
                  filet: i > 0,
                  nom: p.nom,
                  detail: [
                    ?p.marque,
                    portionCourte(p.portion),
                    tr.proteinesCourt(f.g(p.parPortion.proteines, tr)),
                  ].join(' · '),
                  valeur: f.kcalDe(p.parPortion.kcal, tr),
                  onTap: () => pousserEcran(
                    context,
                    ProduitFormulaireEcran(retour: tr.mesProduits, produit: p),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
