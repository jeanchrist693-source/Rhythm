// lib/ecrans/alimentation/recettes/recette_formulaire_ecran.dart
//
// ÉCRIRE UNE RECETTE (ou la modifier) : son nom, ses moments (plusieurs à la
// fois), ce qu'elle donne, ses temps ; les INGRÉDIENTS — chacun cherché dans
// la base du FCÉN ou dans mes produits (ses macros suivent), ou libre (sel,
// épices) ; les ÉTAPES, une par ligne (les minuteurs y sont repérés : « 10
// minutes » deviendra un minuteur du mode cuisine) ; la région, les
// ÉTIQUETTES (des capsules : les siennes, celles du livre, quelques
// propositions ; un champ pour en écrire une), une note, « se congèle
// bien » ; ce qu'une portion apporte, en direct. Supprimer en deux temps.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/nutriments.dart';
import '../../../modele/alimentation/recettes.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/modeles.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../../../widgets/suivi_clavier.dart';
import '../../../widgets/toast.dart';
import '../pieces_alimentation.dart';
import 'ingredient_ecran.dart';
import 'pieces_recettes.dart';
import 'recette_ecran.dart';

class RecetteFormulaireEcran extends ConsumerStatefulWidget {
  const RecetteFormulaireEcran({super.key, required this.retour, this.recette});

  final String retour;

  /// La recette à modifier ; `null` : une nouvelle.
  final Recette? recette;

  @override
  ConsumerState<RecetteFormulaireEcran> createState() =>
      _RecetteFormulaireEcranState();
}

class _RecetteFormulaireEcranState extends ConsumerState<RecetteFormulaireEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<RecetteFormulaireEcran> {
  late final _nom = TextEditingController(text: widget.recette?.nom);
  late final _etapes = TextEditingController(
    text: widget.recette?.etapes.join('\n'),
  );
  late final _region = TextEditingController(text: widget.recette?.region);
  late final _note = TextEditingController(text: widget.recette?.note);
  final _nouvelleEtiquette = TextEditingController();
  final _focus = List.generate(5, (_) => FocusNode());

  late Set<MomentRepas> _moments = {...?widget.recette?.moments};
  late int _portions = widget.recette?.portions ?? 4;
  late int _preparation = widget.recette?.preparation ?? 0;
  late int _cuisson = widget.recette?.cuisson ?? 0;
  late List<Ingredient> _ingredients = [...?widget.recette?.ingredients];
  late bool _congele = widget.recette?.seCongele ?? false;
  late List<String> _etiquettes = [...?widget.recette?.etiquettes];

  bool get _edition => widget.recette != null;

  @override
  void initState() {
    super.initState();
    for (final f in _focus) {
      surveillerClavier(f);
    }
  }

  @override
  void dispose() {
    libererClavier();
    _nom.dispose();
    _etapes.dispose();
    _region.dispose();
    _note.dispose();
    _nouvelleEtiquette.dispose();
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _ingredient([int? index]) async {
    final r = await pousserEcran<ResultatIngredient>(
      context,
      IngredientEcran(
        ingredient: index == null ? null : _ingredients[index],
        retour: _nom.text.trim().isEmpty
            ? context.tr.laRecette
            : _nom.text.trim(),
      ),
    );
    if (r == null || !mounted) return;
    setState(() {
      final i = r.ingredient;
      if (index == null) {
        if (i != null) _ingredients = [..._ingredients, i];
      } else if (i == null) {
        _ingredients = [..._ingredients]..removeAt(index);
      } else {
        _ingredients = [
          for (final (k, x) in _ingredients.indexed) k == index ? i : x,
        ];
      }
    });
  }

  /// L'étiquette tapée rejoint les autres (une seule fois).
  void _ajouterEtiquette() {
    final e = _nouvelleEtiquette.text.trim();
    if (e.isEmpty) return;
    setState(() {
      _etiquettes = etiquettesPropres([..._etiquettes, e]);
      _nouvelleEtiquette.clear();
    });
  }

  void _enregistrer() {
    if (transitionEnCours) return;
    final tr = context.tr;
    final nom = _nom.text.trim();
    if (nom.isEmpty) {
      montrerToast(context, tr.nomRequis);
      return;
    }
    final notifier = ref.read(recettesProvider.notifier);
    final avant = widget.recette;
    final region = _region.text.trim();
    final note = _note.text.trim();
    final r = Recette(
      id: avant?.id ?? notifier.nouvelId('rec'),
      nom: nom[0].toUpperCase() + nom.substring(1),
      creee: avant?.creee ?? ref.read(horlogeProvider)(),
      moments: _moments,
      portions: _portions,
      ingredients: _ingredients,
      etapes: lireEtapes(_etapes.text),
      preparation: _preparation > 0 ? _preparation : null,
      cuisson: _cuisson > 0 ? _cuisson : null,
      region: region.isEmpty ? null : region,
      note: note.isEmpty ? null : note,
      seCongele: _congele,
      cuisinee: avant?.cuisinee ?? const [],
      favorite: avant?.favorite ?? false,
      // Celle qu'on vient de taper, sans l'avoir validée, compte aussi.
      etiquettes: etiquettesPropres([..._etiquettes, _nouvelleEtiquette.text]),
    );
    notifier.enregistrer(r);
    HapticFeedback.lightImpact();
    montrerToast(context, tr.recetteEnregistree(r.nom));
    if (_edition) {
      retirerEcran(context);
    } else {
      remplacerEcran(context, RecetteEcran(id: r.id, retour: widget.retour));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final total = Nutriments.somme(_ingredients.map((i) => i.nutriments));
    final parPortion = total * (1 / _portions);
    final etapes = lireEtapes(_etapes.text);
    final minuteurs = [
      for (final e in etapes)
        for (final m in minuteursDans(e)) f.minutes(m.duree.inMinutes),
    ];
    final libres = [
      for (final i in _ingredients)
        if (i.libre) i.nom,
    ];
    // Les régions à soi déjà données à une recette (« Créole »), hors des
    // grandes régions : proposées à leur tour.
    final autres = <String>{
      for (final r in ref.watch(recettesProvider).recettes)
        if (r.region != null && grandeRegionDe(r.region) == null) r.region!,
    }.toList()..sort();
    // Les capsules : les siennes, celles du livre, puis quelques-unes.
    final capsules = etiquettesPropres([
      ..._etiquettes,
      ...etiquettesDuLivre(ref.watch(recettesProvider).recettes),
      ...kEtiquettesProposees,
    ]);
    String minutes(int m) => m == 0 ? '—' : f.minutes(m);

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: _edition ? tr.modifierRecette : tr.nouvelleRecette,
        ),
        Column(
          key: const ValueKey('nom'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.nomDeLaRecette),
            ChampRhythm(
              controleur: _nom,
              focus: _focus[0],
              indice: tr.indiceNomRecette,
              actionClavier: TextInputAction.done,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.moments),
            PucesMultiples<MomentRepas>(
              options: [for (final m in MomentRepas.values) (m, m.libelle(tr))],
              valeurs: _moments,
              onChanged: (m) => setState(() => _moments = m),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LigneReglage(
              libelle: tr.cequElleDonne,
              droite: CompteurRhythm(
                valeur: _portions,
                min: 1,
                max: 24,
                largeurValeur: 104,
                affichage: (p) => f.portions(p.toDouble(), tr),
                onChanged: (p) => setState(() => _portions = p),
              ),
            ),
            const Filet(),
            LigneReglage(
              libelle: tr.preparation,
              droite: CompteurRhythm(
                valeur: _preparation,
                min: 0,
                max: 240,
                pas: 5,
                affichage: minutes,
                onChanged: (m) => setState(() => _preparation = m),
              ),
            ),
            const Filet(),
            LigneReglage(
              libelle: tr.cuisson,
              droite: CompteurRhythm(
                valeur: _cuisson,
                min: 0,
                max: 600,
                pas: 5,
                affichage: minutes,
                onChanged: (m) => setState(() => _cuisson = m),
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.ingredients),
            for (final (i, ing) in _ingredients.indexed)
              LigneAliment(
                filet: i > 0,
                nom: ing.nom,
                detail: ing.libre
                    ? [
                        f.quantiteIngredient(ing, tr),
                        tr.ingredientLibreCourt,
                      ].where((s) => s.isNotEmpty).join(' · ')
                    : f.quantiteIngredient(ing, tr),
                valeur: ing.libre ? null : f.kcalDe(ing.nutriments.kcal, tr),
                onTap: () => _ingredient(i),
              ),
            if (_ingredients.isNotEmpty) const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: BoutonCapsule(
                picto: Picto.plus,
                libelle: tr.ajouterUnIngredient,
                onTap: () => _ingredient(),
              ),
            ),
          ],
        ),
        Column(
          key: const ValueKey('etapes'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.etapesUneParLigne),
            ChampRhythm(
              controleur: _etapes,
              focus: _focus[1],
              indice: tr.indiceEtapes,
              lignes: 14,
              onChanged: (_) => setState(() {}),
            ),
            if (etapes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                minuteurs.isEmpty
                    ? tr.etapesNombre(etapes.length)
                    : tr.etapesMinuteurs(etapes.length, minuteurs.join(', ')),
                style: RhythmTypo.texte(13, couleur: RhythmCouleurs.peche),
              ),
            ],
          ],
        ),
        Column(
          key: const ValueKey('region'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.regionFacultatif),
            ChampRhythm(
              controleur: _region,
              focus: _focus[2],
              indice: tr.indiceRegion,
              actionClavier: TextInputAction.done,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            ChoixRegion(
              valeur: _region.text,
              aucune: tr.aucune,
              autres: autres,
              onChanged: (r) => setState(() => _region.text = r ?? ''),
            ),
          ],
        ),
        Column(
          key: const ValueKey('etiquettes'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.etiquettesFacultatif),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in capsules)
                  Builder(
                    builder: (context) {
                      final choisie = _etiquettes.any(
                        (x) => memeEtiquette(x, e),
                      );
                      return Puce(
                        libelle: e,
                        choisie: choisie,
                        couleur: RhythmCouleurs.peche,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(
                            () => _etiquettes = choisie
                                ? [
                                    for (final x in _etiquettes)
                                      if (!memeEtiquette(x, e)) x,
                                  ]
                                : [..._etiquettes, e],
                          );
                        },
                      );
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            ChampRhythm(
              key: const ValueKey('champEtiquette'),
              controleur: _nouvelleEtiquette,
              focus: _focus[4],
              indice: tr.indiceEtiquette,
              actionClavier: TextInputAction.done,
              onValider: (_) => _ajouterEtiquette(),
            ),
          ],
        ),
        Column(
          key: const ValueKey('note'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.noteFacultatif),
            ChampRhythm(
              controleur: _note,
              focus: _focus[3],
              indice: tr.indiceNoteRecette,
              lignes: 4,
            ),
          ],
        ),
        LigneReglage(
          libelle: tr.seCongeleBien,
          detail: tr.seCongeleDetail,
          droite: Interrupteur(
            valeur: _congele,
            onChanged: (v) => setState(() => _congele = v),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.parPortion),
            ApercuNutriments(nutriments: parPortion),
            const SizedBox(height: 8),
            Text(
              [
                tr.pourToute(
                  f.portions(_portions.toDouble(), tr),
                  f.kcalDe(total.kcal, tr),
                ),
                if (libres.isNotEmpty)
                  tr.sansValeurNutritive(enPhrase(libres, premiere: false)),
              ].join('\n'),
              style: RhythmTypo.petit,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoutonPlein(
              libelle: tr.enregistrer,
              largeurPleine: true,
              hauteur: 52,
              taillePolice: 15,
              onTap: _enregistrer,
            ),
            if (_edition) ...[
              const SizedBox(height: 12),
              BoutonSuppression(
                libelle: tr.supprimerRecette,
                confirmation: tr.toucherPourSupprimer,
                onConfirme: () {
                  ref
                      .read(recettesProvider.notifier)
                      .supprimer(widget.recette!.id);
                  // Le formulaire et la fiche : retour au livre.
                  retirerEcrans(context, 2);
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
