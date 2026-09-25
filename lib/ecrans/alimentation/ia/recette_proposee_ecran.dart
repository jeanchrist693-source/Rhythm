// lib/ecrans/alimentation/ia/recette_proposee_ecran.dart
//
// UNE RECETTE PROPOSÉE par l'IA (une idée, ou une recette importée) avant
// d'entrer au livre : sa région et ses moments, ce qu'une portion apporte —
// CALCULÉ par la base du FCÉN, ingrédient par ingrédient (un aliment
// introuvable est dit « hors de la base » : sans valeur nutritive, à
// préciser ensuite dans la recette) —, ses temps, ses ingrédients, ses
// étapes (les minuteurs y sont déjà repérés), sa note.
// « Ajouter à mon livre » l'enregistre et ouvre sa fiche (Cuisiner, À la
// liste, Planifier). Déjà au livre (même nom) : « Voir dans mon livre ».

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/base_aliments.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/correspondance.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/nutriments.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/modeles.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../../../widgets/toast.dart';
import '../pieces_alimentation.dart';
import '../recettes/pieces_recettes.dart';
import '../recettes/recette_ecran.dart';
import 'pieces_ia.dart';

/// Les ingrédients de [p] cherchés dans la base (les aliments déjà
/// mangés passent devant).
List<Correspondance> correspondancesDe(
  RecetteProposee p,
  BaseAliments base,
  WidgetRef ref,
) => p.correspondances(
  base,
  frequents: frequentsBase(ref.read(alimentationProvider).journal),
);

class RecetteProposeeEcran extends ConsumerStatefulWidget {
  const RecetteProposeeEcran({
    super.key,
    required this.proposition,
    required this.retour,
  });

  final RecetteProposee proposition;
  final String retour;

  @override
  ConsumerState<RecetteProposeeEcran> createState() =>
      _RecetteProposeeEcranState();
}

class _RecetteProposeeEcranState extends ConsumerState<RecetteProposeeEcran> {
  List<Correspondance>? _ingredients;

  void _ajouter() {
    final ingredients = _ingredients;
    if (ingredients == null || transitionEnCours) return;
    final notifier = ref.read(recettesProvider.notifier);
    final r = widget.proposition.versRecette(
      ingredients,
      id: notifier.nouvelId('rec'),
      creee: ref.read(horlogeProvider)(),
    );
    notifier.enregistrer(r);
    HapticFeedback.lightImpact();
    montrerToast(context, context.tr.iaAjouteeAuLivre(r.nom));
    remplacerEcran(context, RecetteEcran(id: r.id, retour: widget.retour));
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final p = widget.proposition;
    final base = ref.watch(baseAlimentsProvider).value;
    final ingredients = _ingredients ??= base == null
        ? null
        : correspondancesDe(p, base, ref);
    final deja = ref
        .watch(recettesProvider)
        .recettes
        .where((r) => r.nom.toLowerCase() == p.nom.toLowerCase())
        .firstOrNull;
    final total = Nutriments.somme([
      for (final c in ingredients ?? const <Correspondance>[]) c.nutriments,
    ]);
    final horsBase = [
      for (final c in ingredients ?? const <Correspondance>[])
        if (c.horsBase) c.ingredient.nom,
    ];
    final libres = [
      for (final c in ingredients ?? const <Correspondance>[])
        if (c.propose.libre) c.ingredient.nom,
    ];

    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(
          titre: p.nom,
          surtitre: p.moments.isEmpty && p.region == null
              ? null
              : Text(
                  [
                    for (final m in MomentRepas.values)
                      if (p.moments.contains(m)) m.libelle(tr),
                    ?p.region,
                  ].join(' · '),
                  style: RhythmTypo.surtitre,
                ),
        ),
        if (p.description != null)
          Text(
            p.description!,
            style: RhythmTypo.titre(19, poids: 500, hauteur: 1.3),
          ),
        if (ingredients == null)
          AttenteIa(message: tr.chargementBase)
        else ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ApercuNutriments(nutriments: total * (1 / p.portions)),
              const SizedBox(height: 10),
              Text(
                [
                  tr.parPortion,
                  f.portions(p.portions.toDouble(), tr),
                  if (p.preparation != null)
                    tr.preparationDe(f.minutes(p.preparation!)),
                  if (p.cuisson != null) tr.cuissonDe(f.minutes(p.cuisson!)),
                ].join(' · '),
                style: RhythmTypo.petit,
              ),
            ],
          ),
          if (deja == null)
            BoutonCapsule(
              picto: Picto.plus,
              libelle: tr.iaAjouterAuLivre,
              plein: true,
              hauteur: 50,
              onTap: _ajouter,
            )
          else
            BoutonCapsule(
              picto: Picto.livre,
              libelle: tr.iaVoirDansLeLivre,
              hauteur: 50,
              onTap: () => remplacerEcran(
                context,
                RecetteEcran(id: deja.id, retour: widget.retour),
              ),
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.ingredients),
              for (final (i, c) in ingredients.indexed)
                LigneCorrespondance(correspondance: c, filet: i > 0),
              if (horsBase.isNotEmpty || libres.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  [
                    if (horsBase.isNotEmpty)
                      tr.iaHorsBaseDetail(enPhrase(horsBase, premiere: false)),
                    if (libres.isNotEmpty)
                      tr.sansValeurNutritive(enPhrase(libres, premiere: false)),
                  ].join('\n'),
                  style: RhythmTypo.petit,
                ),
              ],
            ],
          ),
        ],
        if (p.etapes.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.etapes),
              for (final (i, e) in p.etapes.indexed) ...[
                if (i > 0) const Filet(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 30,
                        child: Text(
                          '${i + 1}',
                          style: RhythmTypo.titre(
                            17,
                            couleur: RhythmCouleurs.peche,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TexteEtape(
                          texte: e,
                          style: RhythmTypo.texte(15, hauteur: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        if (p.note != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.note),
              Text(p.note!, style: RhythmTypo.texte(15, hauteur: 1.4)),
            ],
          ),
        Text(
          tr.iaRecetteAVerifier,
          style: RhythmTypo.texte(11, couleur: RhythmCouleurs.texte40),
        ),
      ],
    );
  }
}
