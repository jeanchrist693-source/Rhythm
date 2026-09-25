// lib/ecrans/alimentation/recettes/ingredient_ecran.dart
//
// UN INGRÉDIENT d'une recette, en deux temps :
// 1. le CHERCHER — mes produits, puis la base du FCÉN (hors ligne) ; en bas,
//    « Ingrédient libre » avec le texte tapé (« sel et poivre », « 1 boîte
//    de tomates » : sans valeur nutritive) ;
// 2. sa QUANTITÉ — pour un aliment de la base : ses portions du FCÉN
//    (« 1 moyen », « 250 ml », « 15 ml »), par quarts (¼, ½, ¾ : la
//    cuisine), ou en grammes ; pour un produit : ses portions ; libre : un
//    nombre et une unité. Le nom sur la recette se modifie (proposé : le mot
//    cherché). Ce qu'il apporte, en direct.
// Modifier un ingrédient garde son aliment (la quantité suit par règle de
// trois, sans la base) ; « Changer d'aliment » revient à la recherche.
// L'écran rend un [ResultatIngredient] (l'ingrédient, ou `null` : retiré).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/alimentation.dart';
import '../../../modele/alimentation/base_aliments.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
import '../../../modele/alimentation/nutriments.dart';
import '../../../modele/alimentation/rayons.dart';
import '../../../modele/alimentation/recettes.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/suivi_clavier.dart';
import '../../../widgets/toast.dart';
import '../pieces_alimentation.dart';

/// Ce que rend [IngredientEcran] : l'ingrédient, ou `null` s'il est retiré.
class ResultatIngredient {
  const ResultatIngredient(this.ingredient);

  final Ingredient? ingredient;
}

class IngredientEcran extends ConsumerStatefulWidget {
  const IngredientEcran({super.key, required this.retour, this.ingredient});

  final String retour;

  /// L'ingrédient à modifier ; `null` : en ajouter un.
  final Ingredient? ingredient;

  @override
  ConsumerState<IngredientEcran> createState() => _IngredientEcranState();
}

class _IngredientEcranState extends ConsumerState<IngredientEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<IngredientEcran> {
  final _recherche = TextEditingController();
  final _nom = TextEditingController();
  final _grammes = TextEditingController();
  final _quantite = TextEditingController();
  final _focus = List.generate(4, (_) => FocusNode());

  /// Un aliment de la base, choisi à l'instant.
  AlimentBase? _aliment;

  /// Un de mes produits, choisi à l'instant.
  Produit? _produit;

  /// L'ingrédient modifié (base ou produit), gardé tel quel.
  Ingredient? _modele;

  /// Un ingrédient libre (sans valeur nutritive).
  bool _libre = false;

  /// Les portions proposées (base) et la choisie.
  List<Portion> _portions = const [];
  int _choisie = 0;

  /// Le nombre de portions, en quarts (4 = une).
  int _quarts = 4;
  Unite _unite = Unite.unite;

  bool get _choix => _aliment != null || _produit != null || _modele != null;
  bool get _edition => widget.ingredient != null;

  @override
  void initState() {
    super.initState();
    for (final f in _focus) {
      surveillerClavier(f);
    }
    final i = widget.ingredient;
    if (i == null) return;
    _nom.text = i.nom;
    if (i.libre) {
      _libre = true;
      final q = i.quantite;
      if (q != null) {
        _quantite.text = _texte(q.valeur);
        _unite = q.unite;
      }
    } else {
      _modele = i;
      if (i.nombre != null && i.mesure != null) {
        _quarts = (i.nombre! * 4).round().clamp(1, 400);
      } else if (i.grammes != null) {
        _grammes.text = _texte(i.grammes!);
      }
    }
  }

  @override
  void dispose() {
    libererClavier();
    _recherche.dispose();
    _nom.dispose();
    _grammes.dispose();
    _quantite.dispose();
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  static String _texte(double x) => x == x.roundToDouble()
      ? '${x.round()}'
      : x.toStringAsFixed(1).replaceAll('.', ',');

  static String _premierePartie(String nom) {
    final i = nom.indexOf(',');
    return i < 0 ? nom : nom.substring(0, i);
  }

  String get _requeteMajuscule {
    final r = _recherche.text.trim();
    return r.isEmpty ? r : r[0].toUpperCase() + r.substring(1);
  }

  // ── Choisir ──────────────────────────────────────────────────────────────

  void _choisirAliment(AlimentBase a) {
    // Les unités (« 1 moyen ») d'abord, puis les volumes ; sans les portions
    // en grammes (le champ les remplace) ni les doublons.
    final vues = <String>{};
    final utiles = [
      for (final p in a.portions)
        if (vues.add(portionCourte(p.libelle)) &&
            !RegExp(r'^\d+(\.\d+)? ?g$').hasMatch(portionCourte(p.libelle)))
          p,
    ];
    bool estUnite(Portion p) =>
        p.libelle.startsWith('1 ') && !p.libelle.contains('ml');
    final portions = [
      const Portion('100 g', 100),
      ...utiles.where(estUnite),
      ...utiles.where((p) => !estUnite(p)),
    ].take(10).toList();
    final moyen = portions.indexWhere(
      (p) => estUnite(p) && p.libelle.contains('moyen'),
    );
    final une = portions.indexWhere(estUnite);
    setState(() {
      _aliment = a;
      _produit = null;
      _modele = null;
      _libre = false;
      _portions = portions;
      _choisie = moyen >= 0 ? moyen : (une >= 0 ? une : 0);
      _quarts = 4;
      _grammes.clear();
      _nom.text = _requeteMajuscule.isEmpty
          ? _premierePartie(a.nom)
          : _requeteMajuscule;
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _choisirProduit(Produit p) {
    setState(() {
      _produit = p;
      _aliment = null;
      _modele = null;
      _libre = false;
      _quarts = 4;
      _grammes.clear();
      _nom.text = p.nom;
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _choisirLibre() {
    final (nom, q) = lireSaisie(_recherche.text);
    setState(() {
      _libre = true;
      _aliment = null;
      _produit = null;
      _modele = null;
      _nom.text = nom;
      _quantite.text = q == null ? '' : _texte(q.valeur);
      _unite = q?.unite ?? Unite.unite;
    });
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _changer() => setState(() {
    _aliment = null;
    _produit = null;
    _modele = null;
    _libre = false;
    _grammes.clear();
  });

  // ── La quantité ──────────────────────────────────────────────────────────

  double get _nombre => _quarts / 4;

  /// L'ingrédient tel qu'il est réglé ; `null` sans quantité lisible.
  Ingredient? get _ingredient {
    final nom = _nom.text.trim();
    final saisis = ChampNombre.lire(_grammes);
    final a = _aliment, p = _produit, m = _modele;
    if (_libre) {
      if (nom.isEmpty) return null;
      final v = ChampNombre.lire(_quantite);
      return Ingredient(
        nom: nom,
        quantite: v == null || v <= 0 ? null : Quantite(v, _unite),
      );
    }
    if (a != null) {
      final portion = _portions[_choisie];
      final enMesure = saisis == null && _choisie > 0;
      final g = saisis ?? portion.grammes * _nombre;
      return Ingredient(
        nom: nom.isEmpty ? _premierePartie(a.nom) : nom,
        source: SourceIngredient.base,
        code: a.code,
        grammes: g,
        nombre: enMesure ? _nombre : null,
        mesure: enMesure ? portion.libelle : null,
        nutriments: a.pour(g),
      );
    }
    if (p != null) {
      final n = saisis != null && p.grammesPortion != null
          ? saisis / p.grammesPortion!
          : _nombre;
      return Ingredient(
        nom: nom.isEmpty ? p.nom : nom,
        source: SourceIngredient.produit,
        produitId: p.id,
        grammes: p.grammesPortion == null ? null : p.grammesPortion! * n,
        nombre: n,
        mesure: p.portion,
        nutriments: p.parPortion * n,
      );
    }
    if (m != null) {
      // Par règle de trois : la base n'est pas nécessaire.
      double facteur = 1;
      if (saisis != null && m.grammes != null && m.grammes! > 0) {
        facteur = saisis / m.grammes!;
      } else if (m.nombre != null && m.mesure != null && m.nombre! > 0) {
        facteur = _nombre / m.nombre!;
      }
      final i = m.fois(facteur);
      return Ingredient(
        nom: nom.isEmpty ? m.nom : nom,
        source: i.source,
        code: i.code,
        produitId: i.produitId,
        grammes: i.grammes,
        nombre: i.nombre,
        mesure: i.mesure,
        nutriments: i.nutriments,
      );
    }
    return null;
  }

  void _valider() {
    final i = _ingredient;
    if (i == null) {
      montrerToast(context, context.tr.nomRequis);
      return;
    }
    HapticFeedback.lightImpact();
    retirerEcran(context, ResultatIngredient(i));
  }

  // ── L'écran ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final enfants = !_choix && !_libre
        ? _etapeRecherche(tr)
        : _etapeQuantite(tr);
    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: _edition ? tr.modifierIngredient : tr.unIngredient,
        ),
        ...enfants,
      ],
    );
  }

  List<Widget> _etapeRecherche(AppLocalizations tr) {
    final f = context.formats;
    final requete = _recherche.text.trim();
    final etat = ref.watch(alimentationProvider);
    final base = ref.watch(baseAlimentsProvider);
    final q = motsRecherche(requete);
    final produits = requete.isEmpty
        ? const <Produit>[]
        : [
            for (final p in etat.produits)
              if (q.every(
                (m) => motsDe(
                  '${p.nom} ${p.marque ?? ''}',
                ).any((w) => w.startsWith(m)),
              ))
                p,
          ];
    final aliments = requete.isEmpty
        ? null
        : base.value?.rechercher(
            requete,
            frequents: frequentsBase(etat.journal),
          );
    return [
      ChampRhythm(
        key: const ValueKey('recherche'),
        controleur: _recherche,
        focus: _focus[0],
        indice: tr.chercherIngredient,
        actionClavier: TextInputAction.search,
        onChanged: (_) => setState(() {}),
      ),
      if (requete.isEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(tr.ingredientAide, style: RhythmTypo.detail),
            const SizedBox(height: 8),
            const Filet(),
            LigneReglage(
              libelle: tr.ingredientLibre,
              detail: tr.ingredientLibreAide,
              onTap: _choisirLibre,
            ),
          ],
        )
      else
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (i, p) in produits.indexed)
              LigneAliment(
                filet: i > 0,
                nom: p.nom,
                detail: [
                  tr.monProduit,
                  ?p.marque,
                  portionCourte(p.portion),
                ].join(' · '),
                valeur: f.kcalDe(p.parPortion.kcal, tr),
                onTap: () => _choisirProduit(p),
              ),
            if (base.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(tr.chargementBase, style: RhythmTypo.detail),
              )
            else if (base.hasError)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(tr.baseIndisponible, style: RhythmTypo.detail),
              )
            else if (aliments != null)
              for (final (i, a) in aliments.indexed)
                LigneAliment(
                  filet: i > 0 || produits.isNotEmpty,
                  nom: a.nom,
                  detail: tr.pour100g(
                    f.kcalDe(a.pour100g.kcal, tr),
                    f.g(a.pour100g.proteines, tr),
                  ),
                  onTap: () => _choisirAliment(a),
                ),
            if (aliments != null && aliments.isEmpty && produits.isEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(tr.aucunAliment(requete), style: RhythmTypo.detail),
              ),
            const SizedBox(height: 8),
            const Filet(),
            LigneReglage(
              libelle: tr.ingredientLibreNomme(requete),
              detail: tr.ingredientLibreAide,
              onTap: _choisirLibre,
            ),
          ],
        ),
      Text(
        tr.sourceFcen,
        style: RhythmTypo.texte(11, couleur: RhythmCouleurs.texte40),
      ),
    ];
  }

  List<Widget> _etapeQuantite(AppLocalizations tr) {
    final f = context.formats;
    final a = _aliment, p = _produit, m = _modele;
    final i = _ingredient;
    String unite(Unite u) =>
        u.symbole ?? (u == Unite.paquet ? tr.unitePaquet : tr.uniteUnite);
    // L'unité comptée par le compteur.
    final String? compte = a != null
        ? portionCourte(_portions[_choisie].libelle)
        : p != null
        ? portionCourte(p.portion)
        : (m?.mesure == null ? null : mesureCourte(m!.mesure!));
    final grammesConnus =
        a != null || p?.grammesPortion != null || m?.grammes != null;
    final g = i?.grammes;
    return [
      Column(
        key: const ValueKey('nom'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EtiquetteChamp(_libre ? tr.ingredientLibre : tr.nomSurLaRecette),
          ChampRhythm(
            controleur: _nom,
            focus: _focus[1],
            indice: a == null
                ? tr.indiceIngredientLibre
                : _premierePartie(a.nom),
            actionClavier: TextInputAction.done,
            onChanged: (_) => setState(() {}),
          ),
          if (a != null || m != null || p != null) ...[
            const SizedBox(height: 8),
            Text(
              a?.nom ??
                  (p != null
                      ? (p.marque ?? tr.monProduit)
                      : m!.source == SourceIngredient.produit
                      ? tr.monProduit
                      : tr.ingredientDeLaBase),
              style: RhythmTypo.petit,
            ),
          ],
        ],
      ),
      if (_libre)
        Column(
          key: const ValueKey('libre'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.quantiteFacultatif),
            ChampNombre(
              controleur: _quantite,
              focus: _focus[2],
              decimales: 2,
              actionClavier: TextInputAction.done,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            PucesChoix<Unite>(
              options: [for (final u in Unite.values) (u, unite(u))],
              valeur: _unite,
              onChanged: (u) => setState(() => _unite = u),
            ),
            const SizedBox(height: 10),
            Text(tr.ingredientLibreAide, style: RhythmTypo.petit),
          ],
        )
      else
        Column(
          key: const ValueKey('quantite'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.quantite),
            if (a != null) ...[
              PucesChoix<int>(
                options: [
                  for (final (k, q) in _portions.indexed)
                    (
                      k,
                      k == 0
                          ? q.libelle
                          : '${portionCourte(q.libelle)} · ${f.g(q.grammes, tr)}',
                    ),
                ],
                valeur: ChampNombre.lire(_grammes) != null ? null : _choisie,
                onChanged: (k) => setState(() {
                  _choisie = k;
                  _grammes.clear();
                }),
              ),
              const SizedBox(height: 14),
            ],
            if (compte != null)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      tr.nombreDe(compte),
                      maxLines: 2,
                      style: RhythmTypo.texte(15, poids: 500),
                    ),
                  ),
                  Opacity(
                    opacity: ChampNombre.lire(_grammes) != null ? 0.4 : 1,
                    child: CompteurRhythm(
                      valeur: _quarts,
                      min: 1,
                      max: 400,
                      affichage: (q) => f.fraction(q / 4),
                      onChanged: (q) => setState(() {
                        _quarts = q;
                        _grammes.clear();
                      }),
                    ),
                  ),
                ],
              ),
            if (grammesConnus) ...[
              const SizedBox(height: 14),
              EtiquetteChamp(compte == null ? tr.enGrammes : tr.ouEnGrammes),
              ChampNombre(
                controleur: _grammes,
                focus: _focus[3],
                indice: g == null ? null : _texte(g),
                suffixe: 'g',
                actionClavier: TextInputAction.done,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
        ),
      if (!_libre)
        ApercuNutriments(nutriments: i?.nutriments ?? Nutriments.zero),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BoutonPlein(
            libelle: _edition ? tr.enregistrer : tr.ajouterALaRecette,
            largeurPleine: true,
            hauteur: 52,
            taillePolice: 15,
            onTap: _valider,
          ),
          const SizedBox(height: 4),
          LigneReglage(libelle: tr.changerDAliment, onTap: _changer),
          if (_edition) ...[
            const SizedBox(height: 8),
            BoutonSuppression(
              libelle: tr.retirerDeLaRecette,
              confirmation: tr.toucherPourRetirer,
              onConfirme: () =>
                  retirerEcran(context, const ResultatIngredient(null)),
            ),
          ],
        ],
      ),
    ];
  }
}
