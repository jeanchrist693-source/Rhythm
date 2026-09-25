// lib/ecrans/alimentation/ia/substitution_ecran.dart
//
// REMPLACER UN INGRÉDIENT d'une recette (palier 4) : on choisit
// l'ingrédient, puis pourquoi (je n'en ai pas, plus léger, plus de
// protéines, végétarien, une allergie) ; l'IA propose trois remplaçants et
// ce qu'ils changent (goût, texture, cuisson). Chacun est CHIFFRÉ par la
// base : ce que la portion y gagne ou y perd (calories, protéines).
// « Remplacer » change la recette (le nom et la quantité du remplaçant, ses
// valeurs de la base) et revient à sa fiche.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ia/ia_alimentation.dart';
import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/base_aliments.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/correspondance.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/recettes.dart';
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
import 'pieces_ia.dart';

class SubstitutionEcran extends ConsumerStatefulWidget {
  const SubstitutionEcran({
    super.key,
    required this.recetteId,
    required this.retour,
  });

  final String recetteId;
  final String retour;

  @override
  ConsumerState<SubstitutionEcran> createState() => _SubstitutionEcranState();
}

class _SubstitutionEcranState extends ConsumerState<SubstitutionEcran>
    with AppelIa<SubstitutionEcran> {
  /// L'ingrédient à remplacer (son rang dans la recette).
  int? _choisi;
  RaisonSubstitution? _raison;
  List<(Substitution, Correspondance)> _options = const [];
  final _cleResultats = GlobalKey();

  Future<void> _proposer(Recette r) async {
    final i = _choisi;
    if (i == null || i >= r.ingredients.length) return;
    final francais = Localizations.localeOf(context).languageCode == 'fr';
    final res = await appeler(() async {
      final s = await substituer(
        r,
        r.ingredients[i],
        raison: _raison,
        francais: francais,
      );
      final base = await ref.read(baseAlimentsProvider.future);
      final frequents = frequentsBase(ref.read(alimentationProvider).journal);
      return [
        for (final x in s)
          (x, correspondre(x.ingredient, base, frequents: frequents)),
      ];
    });
    if (res == null || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() => _options = res);
    montrer(_cleResultats);
  }

  void _remplacer(Recette r, Correspondance c) {
    final i = _choisi;
    if (i == null || i >= r.ingredients.length || transitionEnCours) return;
    final avant = r.ingredients[i];
    ref
        .read(recettesProvider.notifier)
        .enregistrer(
          r.copierAvec(
            ingredients: [
              for (final (k, x) in r.ingredients.indexed)
                k == i ? c.ingredient : x,
            ],
          ),
        );
    HapticFeedback.lightImpact();
    montrerToast(context, context.tr.iaRemplace(avant.nom, c.ingredient.nom));
    retirerEcran(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final r = ref.watch(recettesProvider).recette(widget.recetteId);
    if (r == null) {
      return PageSecondaire(retour: widget.retour, enfants: const []);
    }
    final i = _choisi;
    final avant = i == null || i >= r.ingredients.length
        ? null
        : r.ingredients[i];

    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(
          titre: tr.iaRemplacer,
          surtitre: Text(r.nom, style: RhythmTypo.surtitre),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.iaQuelIngredient),
            for (final (k, x) in r.ingredients.indexed)
              LigneAliment(
                filet: k > 0,
                nom: x.nom,
                detail: f.quantiteIngredient(x, tr),
                droite: k == _choisi
                    ? const PictoRhythm(
                        Picto.coche,
                        taille: 20,
                        couleur: RhythmCouleurs.peche,
                        epaisseur: 2.4,
                      )
                    : null,
                onTap: () => setState(() {
                  HapticFeedback.selectionClick();
                  _choisi = k;
                  _options = const [];
                }),
              ),
          ],
        ),
        if (avant != null) ...[
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.iaPourquoiRemplacer),
              RangeePuces<RaisonSubstitution?>(
                options: [
                  (null, tr.iaPeuImporte),
                  (RaisonSubstitution.manque, tr.iaRaisonManque),
                  (RaisonSubstitution.plusLeger, tr.iaRaisonLeger),
                  (RaisonSubstitution.plusProteine, tr.iaRaisonProteine),
                  (RaisonSubstitution.vegetarien, tr.iaRaisonVegetarien),
                  (RaisonSubstitution.allergie, tr.iaRaisonAllergie),
                ],
                valeur: _raison,
                onChanged: (x) => setState(() {
                  _raison = x == _raison ? null : x;
                  _options = const [];
                }),
              ),
            ],
          ),
          BoutonPlein(
            libelle: tr.iaProposerRemplacants(avant.nom),
            largeurPleine: true,
            hauteur: 52,
            taillePolice: 15,
            onTap: () => _proposer(r),
          ),
        ],
        if (enCours)
          AttenteIa(message: tr.iaAttenteRemplacants)
        else if (erreur != null)
          ErreurIaBloc(erreur: erreur, onReessayer: () => _proposer(r)),
        if (avant != null && !enCours && _options.isNotEmpty)
          Column(
            key: _cleResultats,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (s, c) in _options)
                Builder(
                  builder: (context) {
                    final dKcal =
                        (c.nutriments.kcal - avant.nutriments.kcal) /
                        r.portions;
                    final dProt =
                        (c.nutriments.proteines - avant.nutriments.proteines) /
                        r.portions;
                    String signe(double x, String v) =>
                        '${x >= 0 ? '+' : '−'}$v';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Filet(),
                        LigneCorrespondance(correspondance: c, filet: false),
                        if (s.pourquoi != null)
                          Text(s.pourquoi!, style: RhythmTypo.detail),
                        if (c.aliment != null) ...[
                          const SizedBox(height: 6),
                          Text(
                            tr.iaParPortionDiff(
                              signe(dKcal, f.kcalDe(dKcal.abs(), tr)),
                              signe(dProt, f.g(dProt.abs(), tr)),
                            ),
                            style: RhythmTypo.texte(
                              13,
                              couleur: RhythmCouleurs.peche,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: BoutonCapsule(
                            picto: Picto.repete,
                            libelle: tr.iaRemplacerBouton,
                            onTap: () => _remplacer(r, c),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    );
                  },
                ),
            ],
          ),
        Text(tr.iaRemplacerDetail, style: RhythmTypo.petit),
        const MentionIa(),
      ],
    );
  }
}
