// lib/ecrans/alimentation/recettes/choisir_plat_ecran.dart
//
// PRÉVOIR UN PLAT (le souper de vendredi) : mes recettes — celles de ce
// moment d'abord, cuisinées récemment en tête —, mes produits (une
// collation achetée), ou « autre chose » (« Souper chez des amis »,
// « Restaurant »). Un toucher le prévoit, pour les portions du foyer.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
import '../../../modele/alimentation/base_aliments.dart'
    show motsDe, motsRecherche;
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/recettes.dart';
import '../../../modele/modeles.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../../../widgets/suivi_clavier.dart';
import '../../../widgets/toast.dart';
import '../pieces_alimentation.dart';
import 'pieces_recettes.dart';
import 'recette_formulaire_ecran.dart';

class ChoisirPlatEcran extends ConsumerStatefulWidget {
  const ChoisirPlatEcran({
    super.key,
    required this.jour,
    required this.moment,
    required this.retour,
  });

  final DateTime jour;
  final MomentRepas moment;
  final String retour;

  @override
  ConsumerState<ChoisirPlatEcran> createState() => _ChoisirPlatEcranState();
}

class _ChoisirPlatEcranState extends ConsumerState<ChoisirPlatEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<ChoisirPlatEcran> {
  final _recherche = TextEditingController();
  final _libre = TextEditingController();
  final _focus = List.generate(2, (_) => FocusNode());

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
    _recherche.dispose();
    _libre.dispose();
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _prevoir(String nom, {String? recette, String? produit, String? libre}) {
    if (transitionEnCours) return;
    ref
        .read(recettesProvider.notifier)
        .planifier(
          jour: widget.jour,
          moment: widget.moment,
          recetteId: recette,
          produitId: produit,
          libre: libre,
        );
    HapticFeedback.lightImpact();
    final tr = context.tr;
    montrerToast(context, tr.prevuAuToast(nom, widget.moment.name));
    retirerEcran(context);
  }

  void _prevoirLibre() {
    final t = _libre.text.trim();
    if (t.isEmpty) return;
    _prevoir(t, libre: t[0].toUpperCase() + t.substring(1));
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(recettesProvider);
    final produits = ref.watch(alimentationProvider).produits;
    final requete = _recherche.text.trim();
    final q = motsRecherche(requete);
    final recettes = [
      for (final r in recettesPour(widget.moment, etat.recettes))
        if (recetteRepond(r, requete)) r,
    ];
    final pour = recettes.where((r) => r.moments.contains(widget.moment));
    final autres = recettes.where((r) => !r.moments.contains(widget.moment));
    final mesProduits = [
      for (final p in produits)
        if (q.isEmpty ||
            q.every(
              (m) => motsDe(
                '${p.nom} ${p.marque ?? ''}',
              ).any((w) => w.startsWith(m)),
            ))
          p,
    ];

    Widget ligne(int i, Recette r) => LigneAliment(
      filet: i > 0,
      nom: r.nom,
      detail: detailRecette(r, f, tr),
      valeur: f.kcalDe(r.parPortion.kcal, tr),
      onTap: () => _prevoir(r.nom, recette: r.id),
    );

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: tr.prevoirAu(widget.moment.name),
          surtitre: Text(
            f.jourComplet(widget.jour),
            style: RhythmTypo.surtitre,
          ),
        ),
        if (etat.recettes.isNotEmpty)
          ChampRhythm(
            controleur: _recherche,
            focus: _focus[0],
            indice: tr.chercherRecette,
            actionClavier: TextInputAction.search,
            onChanged: (_) => setState(() {}),
          ),
        if (etat.recettes.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr.livreVide, style: RhythmTypo.detail),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: BoutonCapsule(
                  picto: Picto.plus,
                  libelle: tr.nouvelleRecette,
                  onTap: () => pousserEcran(
                    context,
                    RecetteFormulaireEcran(retour: widget.moment.libelle(tr)),
                  ),
                ),
              ),
            ],
          ),
        if (pour.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.recettesDuMoment(widget.moment.name)),
              for (final (i, r) in pour.indexed) ligne(i, r),
            ],
          ),
        if (autres.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(pour.isEmpty ? tr.mesRecettes : tr.autresRecettes),
              for (final (i, r) in autres.indexed) ligne(i, r),
            ],
          ),
        if (mesProduits.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.mesProduits),
              for (final (i, p) in mesProduits.indexed)
                LigneAliment(
                  filet: i > 0,
                  nom: p.nom,
                  detail: [?p.marque, portionCourte(p.portion)].join(' · '),
                  valeur: f.kcalDe(p.parPortion.kcal, tr),
                  onTap: () => _prevoir(p.nom, produit: p.id),
                ),
            ],
          ),
        Column(
          key: const ValueKey('autre'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.autreChose),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: ChampRhythm(
                    controleur: _libre,
                    focus: _focus[1],
                    indice: tr.indiceAutreChose,
                    actionClavier: TextInputAction.done,
                    onValider: (_) => _prevoirLibre(),
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: BoutonRond(
                    couleur: RhythmCouleurs.peche,
                    libelle: tr.ajouter,
                    onTap: _prevoirLibre,
                    child: const PictoRhythm(
                      Picto.plus,
                      taille: 20,
                      epaisseur: 2.4,
                      couleur: RhythmCouleurs.noir,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
