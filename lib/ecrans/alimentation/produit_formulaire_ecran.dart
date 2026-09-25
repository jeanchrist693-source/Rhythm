// lib/ecrans/alimentation/produit_formulaire_ecran.dart
//
// UN PRODUIT : son nom, sa marque, la portion telle qu'écrite sur
// l'emballage (« 1 barre », et ses grammes si indiqués), puis le TABLEAU DE
// LA VALEUR NUTRITIVE pour cette portion — calories, lipides (dont
// saturés), glucides (dont fibres et sucres), protéines, sodium, dans
// l'ordre de l'étiquette canadienne. Supprimer en deux temps (le journal
// garde ce qui a déjà été noté).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/traductions.dart';
import '../../modele/alimentation/alimentation.dart';
import '../../modele/alimentation/etat_alimentation.dart';
import '../../modele/alimentation/nutriments.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/boutons.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/suivi_clavier.dart';
import '../../widgets/toast.dart';
import 'pieces_alimentation.dart';

class ProduitFormulaireEcran extends ConsumerStatefulWidget {
  const ProduitFormulaireEcran({super.key, required this.retour, this.produit});

  final String retour;

  /// Le produit à modifier ; `null` : un nouveau.
  final Produit? produit;

  @override
  ConsumerState<ProduitFormulaireEcran> createState() =>
      _ProduitFormulaireEcranState();
}

class _ProduitFormulaireEcranState extends ConsumerState<ProduitFormulaireEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<ProduitFormulaireEcran> {
  late final Produit? _p = widget.produit;
  late final _nom = TextEditingController(text: _p?.nom ?? '');
  late final _marque = TextEditingController(text: _p?.marque ?? '');
  late final _portion = TextEditingController(text: _p?.portion ?? '');
  late final _grammes = TextEditingController(text: _v(_p?.grammesPortion));
  late final _kcal = TextEditingController(text: _v(_p?.parPortion.kcal));
  late final _lipides = TextEditingController(text: _v(_p?.parPortion.lipides));
  late final _satures = TextEditingController(text: _v(_p?.parPortion.satures));
  late final _glucides = TextEditingController(
    text: _v(_p?.parPortion.glucides),
  );
  late final _fibres = TextEditingController(text: _v(_p?.parPortion.fibres));
  late final _sucres = TextEditingController(text: _v(_p?.parPortion.sucres));
  late final _proteines = TextEditingController(
    text: _v(_p?.parPortion.proteines),
  );
  late final _sodium = TextEditingController(text: _v(_p?.parPortion.sodium));
  final _focus = List.generate(12, (_) => FocusNode());

  static String _v(double? x) => x == null || x == 0
      ? ''
      : (x == x.roundToDouble() ? '${x.round()}' : x.toStringAsFixed(1));

  List<TextEditingController> get _tous => [
    _nom,
    _marque,
    _portion,
    _grammes,
    _kcal,
    _lipides,
    _satures,
    _glucides,
    _fibres,
    _sucres,
    _proteines,
    _sodium,
  ];

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
    for (final c in _tous) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _enregistrer() {
    final tr = context.tr;
    final nom = _nom.text.trim();
    final kcal = ChampNombre.lire(_kcal);
    if (nom.isEmpty) {
      montrerToast(context, tr.nomRequis);
      return;
    }
    if (kcal == null) {
      montrerToast(context, tr.kcalRequises);
      return;
    }
    final grammes = ChampNombre.lire(_grammes);
    var portion = _portion.text.trim();
    if (portion.isEmpty) {
      portion = grammes == null ? tr.unePortion : '${_v(grammes)} g';
    }
    final notifier = ref.read(alimentationProvider.notifier);
    notifier.enregistrerProduit(
      Produit(
        id: _p?.id ?? notifier.nouvelId('prod'),
        nom: nom,
        marque: _marque.text.trim().isEmpty ? null : _marque.text.trim(),
        portion: portion,
        grammesPortion: grammes == null || grammes <= 0 ? null : grammes,
        parPortion: Nutriments(
          kcal: kcal,
          lipides: ChampNombre.lire(_lipides) ?? 0,
          satures: ChampNombre.lire(_satures) ?? 0,
          glucides: ChampNombre.lire(_glucides) ?? 0,
          fibres: ChampNombre.lire(_fibres) ?? 0,
          sucres: ChampNombre.lire(_sucres) ?? 0,
          proteines: ChampNombre.lire(_proteines) ?? 0,
          sodium: ChampNombre.lire(_sodium) ?? 0,
        ),
      ),
    );
    HapticFeedback.lightImpact();
    montrerToast(context, _p == null ? tr.produitAjoute : tr.produitModifie);
    retirerEcran(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    Widget texte(String etiquette, int i, {String? indice}) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EtiquetteChamp(etiquette),
        ChampRhythm(
          controleur: _tous[i],
          focus: _focus[i],
          indice: indice,
          actionClavier: TextInputAction.next,
        ),
      ],
    );
    Widget nombre(
      String etiquette,
      int i,
      String suffixe, {
      int decimales = 1,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EtiquetteChamp(etiquette),
        ChampNombre(
          controleur: _tous[i],
          focus: _focus[i],
          suffixe: suffixe,
          decimales: decimales,
          actionClavier: i == 11 ? TextInputAction.done : TextInputAction.next,
        ),
      ],
    );
    Widget paire(Widget a, Widget b) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: 18),
        Expanded(child: b),
      ],
    );

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: _p == null ? tr.nouveauProduit : tr.modifierProduit,
        ),
        texte(tr.nomProduit, 0, indice: tr.indiceNomProduit),
        texte(tr.marqueFacultatif, 1),
        paire(
          texte(tr.portionEtiquette, 2, indice: tr.indicePortion),
          nombre(tr.grammesPortion, 3, 'g'),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.valeurNutritive),
            Text(tr.valeurNutritiveAide, style: RhythmTypo.detail),
          ],
        ),
        nombre(tr.calories, 4, 'kcal', decimales: 0),
        paire(nombre(tr.lipides, 5, 'g'), nombre(tr.dontSatures, 6, 'g')),
        paire(nombre(tr.glucides, 7, 'g'), nombre(tr.dontFibres, 8, 'g')),
        paire(nombre(tr.dontSucres, 9, 'g'), nombre(tr.proteines, 10, 'g')),
        paire(
          nombre(tr.sodium, 11, 'mg', decimales: 0),
          const SizedBox.shrink(),
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
            if (_p != null) ...[
              const SizedBox(height: 12),
              BoutonSuppression(
                libelle: tr.supprimerProduit,
                confirmation: tr.toucherPourSupprimer,
                onConfirme: () {
                  ref
                      .read(alimentationProvider.notifier)
                      .supprimerProduit(_p.id);
                  retirerEcran(context);
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
