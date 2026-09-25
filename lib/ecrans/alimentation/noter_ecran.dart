// lib/ecrans/alimentation/noter_ecran.dart
//
// NOTER UN REPAS : le moment (déjeuner, dîner, collation, souper — choisi
// d'après l'heure), ce qu'il contient déjà, puis la recherche.
// - Sans recherche : les RESTES du garde-manger (un « + » en note une
//   portion), les RÉCENTS (un « + » les ajoute d'un toucher, à la même
//   quantité), mes recettes de ce moment, « Mes produits », l'entrée rapide.
// - En cherchant : mes recettes et mes produits d'abord, puis la base du
//   FCÉN (5 894 aliments, hors ligne — ce qu'on mange souvent passe
//   devant), et en bas « Entrée rapide » avec le texte tapé.
// Toucher un aliment choisit sa quantité (`portion_ecran.dart`) ; l'écran
// reste ouvert pour ajouter le suivant (on compose un repas).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_alimentation.dart';
import '../../l10n/traductions.dart';
import '../../modele/alimentation/alimentation.dart';
import '../../modele/alimentation/base_aliments.dart';
import '../../l10n/libelles_courses.dart';
import '../../l10n/libelles_recettes.dart';
import '../../modele/alimentation/calculs_alimentation.dart';
import '../../modele/alimentation/calculs_courses.dart';
import '../../modele/alimentation/calculs_recettes.dart';
import '../../modele/alimentation/etat_alimentation.dart';
import '../../modele/alimentation/etat_courses.dart';
import '../../modele/alimentation/etat_recettes.dart';
import '../../modele/alimentation/recettes.dart';
import '../../modele/etat_sante.dart';
import '../../modele/modeles.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/filets.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/suivi_clavier.dart';
import '../../widgets/toast.dart';
import 'entree_rapide_ecran.dart';
import 'pieces_alimentation.dart';
import 'portion_ecran.dart';
import 'produit_formulaire_ecran.dart';
import 'recettes/portion_recette_ecran.dart';

class NoterEcran extends ConsumerStatefulWidget {
  const NoterEcran({
    super.key,
    required this.jour,
    required this.moment,
    required this.retour,
  });

  final DateTime jour;
  final MomentRepas moment;
  final String retour;

  @override
  ConsumerState<NoterEcran> createState() => _NoterEcranState();
}

class _NoterEcranState extends ConsumerState<NoterEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<NoterEcran> {
  final _recherche = TextEditingController();
  final _focus = FocusNode();
  late MomentRepas _moment = widget.moment;

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focus);
  }

  @override
  void dispose() {
    libererClavier();
    _recherche.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _ouvrir(Widget ecran) async {
    final ajoute = await pousserEcran<bool>(context, ecran);
    if (ajoute == true && mounted && _recherche.text.isNotEmpty) {
      setState(_recherche.clear);
    }
  }

  /// Le même aliment, à la même quantité, d'un toucher.
  void _ajouterPareil(EntreeJournal modele) {
    final tr = context.tr;
    final f = context.formats;
    final notifier = ref.read(alimentationProvider.notifier);
    notifier.ajouter(
      modele.copiee(
        id: notifier.nouvelId('ent'),
        jour: jourDe(widget.jour),
        moment: _moment,
        ajoutee: ref.read(horlogeProvider)(),
      ),
    );
    HapticFeedback.lightImpact();
    montrerToast(
      context,
      tr.ajouteA(
        tr.auMoment(_moment.name),
        f.kcalDe(modele.nutriments.kcal, tr),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(alimentationProvider);
    final auj = jourDe(ref.watch(aujourdhuiProvider));
    final jour = jourDe(widget.jour);
    final deja = etat.entreesDu(jour, _moment);
    final requete = _recherche.text.trim();

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: tr.noterUnRepas,
          surtitre: jour == auj
              ? null
              : Text(f.jourComplet(jour), style: RhythmTypo.surtitre),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PucesChoix<MomentRepas>(
              options: [for (final m in MomentRepas.values) (m, m.libelle(tr))],
              valeur: _moment,
              onChanged: (m) => setState(() => _moment = m),
            ),
            const SizedBox(height: 12),
            Text(
              deja.isEmpty
                  ? tr.rienEncore
                  : tr.dejaDansRepas(
                      deja.length,
                      f.kcalDe(totalDe(deja).kcal, tr),
                    ),
              style: RhythmTypo.detail,
            ),
          ],
        ),
        ChampRhythm(
          controleur: _recherche,
          focus: _focus,
          indice: tr.chercherAliment,
          actionClavier: TextInputAction.search,
          onChanged: (_) => setState(() {}),
        ),
        if (requete.isEmpty)
          ..._sansRecherche(etat)
        else
          _resultats(etat, requete),
        Text(
          tr.sourceFcen,
          style: RhythmTypo.texte(11, couleur: RhythmCouleurs.texte40),
        ),
      ],
    );
  }

  /// Une portion des restes, d'un toucher.
  void _mangerReste(Recette r) {
    final tr = context.tr;
    final f = context.formats;
    final e = ref
        .read(recettesProvider.notifier)
        .noter(
          recette: r,
          portions: 1,
          jour: widget.jour,
          moment: _moment,
          depuisRestes: true,
        );
    HapticFeedback.lightImpact();
    montrerToast(
      context,
      tr.ajouteA(tr.auMoment(_moment.name), f.kcalDe(e.nutriments.kcal, tr)),
    );
  }

  Widget _ligneRecette(Recette r, bool filet) {
    final tr = context.tr;
    final f = context.formats;
    return LigneAliment(
      filet: filet,
      nom: r.nom,
      // Par portion, comme les calories à droite.
      detail: [
        tr.maRecette,
        if (r.parPortion.proteines >= 1)
          tr.proteinesDe(f.g(r.parPortion.proteines, tr)),
      ].join(' · '),
      valeur: f.kcalDe(r.parPortion.kcal, tr),
      onTap: () => _ouvrir(
        PortionRecetteEcran(
          recette: r,
          jour: widget.jour,
          moment: _moment,
          retour: tr.noterUnRepas,
        ),
      ),
    );
  }

  List<Widget> _sansRecherche(EtatAlimentation etat) {
    final tr = context.tr;
    final f = context.formats;
    final liste = recents(etat.journal);
    final recettes = ref.watch(recettesProvider);
    final gardeManger = ref.watch(coursesProvider).gardeManger;
    final auj = jourDe(ref.watch(aujourdhuiProvider));
    // Les restes, une ligne par recette (le plus pressé d'abord).
    DateTime echeance(Recette r) =>
        restesDe(gardeManger, r.id).first.peremption ?? DateTime(9999);
    final restes = <Recette>[
      for (final id in {
        for (final a in gardeManger)
          if (a.recetteId != null) a.recetteId!,
      })
        ?recettes.recette(id),
    ]..sort((a, b) => echeance(a).compareTo(echeance(b)));
    final duMoment = [
      for (final r in recettesPour(_moment, recettes.recettes))
        if (r.moments.contains(_moment)) r,
    ].take(5).toList();
    return [
      if (restes.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.lesRestesTitre),
            for (final (i, r) in restes.indexed)
              Builder(
                builder: (context) {
                  final articles = restesDe(gardeManger, r.id);
                  final jours = joursRestants(articles.first, auj);
                  return LigneAliment(
                    filet: i > 0,
                    nom: r.nom,
                    detail: [
                      f.portions(portionsEnRestes(gardeManger, r.id), tr),
                      articles.first.emplacement.libelle(tr),
                      if (jours != null) f.echeance(jours, tr),
                    ].join(' · '),
                    onTap: () => _ouvrir(
                      PortionRecetteEcran(
                        recette: r,
                        jour: widget.jour,
                        moment: _moment,
                        retour: tr.noterUnRepas,
                      ),
                    ),
                    droite: _BoutonPlus(
                      libelle: tr.mangerUnePortion(r.nom),
                      onTap: () => _mangerReste(r),
                    ),
                  );
                },
              ),
          ],
        ),
      if (liste.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.recents),
            for (final (i, e) in liste.indexed)
              LigneAliment(
                filet: i > 0,
                nom: e.nom,
                detail: [
                  FormatsAlimentation(f).quantite(e, tr),
                  f.kcalDe(e.nutriments.kcal, tr),
                ].where((s) => s.isNotEmpty).join(' · '),
                onTap: () => _ouvrir(
                  e.source == SourceEntree.rapide
                      ? EntreeRapideEcran(
                          jour: widget.jour,
                          moment: _moment,
                          retour: tr.noterUnRepas,
                          modele: e,
                        )
                      : PortionEcran.modele(
                          modele: e,
                          jour: widget.jour,
                          moment: _moment,
                          retour: tr.noterUnRepas,
                        ),
                ),
                droite: _BoutonPlus(
                  libelle: tr.ajouterPareil(e.nom),
                  onTap: () => _ajouterPareil(e),
                ),
              ),
          ],
        ),
      if (duMoment.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.mesRecettes),
            for (final (i, r) in duMoment.indexed) _ligneRecette(r, i > 0),
          ],
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitreSection(tr.mesProduits),
          for (final (i, p) in etat.produits.indexed)
            LigneAliment(
              filet: i > 0,
              nom: p.nom,
              detail: [?p.marque, portionCourte(p.portion)].join(' · '),
              valeur: f.kcalDe(p.parPortion.kcal, tr),
              onTap: () => _ouvrir(
                PortionEcran.produit(
                  produit: p,
                  jour: widget.jour,
                  moment: _moment,
                  retour: tr.noterUnRepas,
                ),
              ),
            ),
          if (etat.produits.isNotEmpty) const SizedBox(height: 4),
          LigneReglage(
            libelle: tr.nouveauProduit,
            detail: tr.nouveauProduitAide,
            onTap: () => pousserEcran(
              context,
              ProduitFormulaireEcran(retour: tr.noterUnRepas),
            ),
          ),
          LigneReglage(
            libelle: tr.entreeRapide,
            detail: tr.entreeRapideAide,
            onTap: () => _ouvrir(
              EntreeRapideEcran(
                jour: widget.jour,
                moment: _moment,
                retour: tr.noterUnRepas,
              ),
            ),
          ),
        ],
      ),
    ];
  }

  Widget _resultats(EtatAlimentation etat, String requete) {
    final tr = context.tr;
    final f = context.formats;
    final base = ref.watch(baseAlimentsProvider);
    final q = motsRecherche(requete);
    final produits = [
      for (final p in etat.produits)
        if (q.every(
          (m) =>
              motsDe('${p.nom} ${p.marque ?? ''}').any((w) => w.startsWith(m)),
        ))
          p,
    ];
    final aliments = base.value?.rechercher(
      requete,
      frequents: frequentsBase(etat.journal),
    );
    final recettes = [
      for (final r in ref.watch(recettesProvider).recettes)
        if (recetteRepond(r, requete)) r,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, r) in recettes.indexed) _ligneRecette(r, i > 0),
        for (final (i, p) in produits.indexed)
          LigneAliment(
            filet: i > 0 || recettes.isNotEmpty,
            nom: p.nom,
            detail: [
              tr.monProduit,
              ?p.marque,
              portionCourte(p.portion),
            ].join(' · '),
            valeur: f.kcalDe(p.parPortion.kcal, tr),
            onTap: () => _ouvrir(
              PortionEcran.produit(
                produit: p,
                jour: widget.jour,
                moment: _moment,
                retour: tr.noterUnRepas,
              ),
            ),
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
              filet: i > 0 || produits.isNotEmpty || recettes.isNotEmpty,
              nom: a.nom,
              detail: tr.pour100g(
                f.kcalDe(a.pour100g.kcal, tr),
                f.g(a.pour100g.proteines, tr),
              ),
              onTap: () => _ouvrir(
                PortionEcran.aliment(
                  aliment: a,
                  jour: widget.jour,
                  moment: _moment,
                  retour: tr.noterUnRepas,
                  nomPropose: requete[0].toUpperCase() + requete.substring(1),
                ),
              ),
            ),
        if (aliments != null &&
            aliments.isEmpty &&
            produits.isEmpty &&
            recettes.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(tr.aucunAliment(requete), style: RhythmTypo.detail),
          ),
        const SizedBox(height: 8),
        const Filet(),
        LigneReglage(
          libelle: tr.entreeRapideNommee(requete),
          detail: tr.entreeRapideAide,
          onTap: () => _ouvrir(
            EntreeRapideEcran(
              jour: widget.jour,
              moment: _moment,
              retour: tr.noterUnRepas,
              nom: requete,
            ),
          ),
        ),
      ],
    );
  }
}

/// Un petit disque « + » (ajouter la même chose).
class _BoutonPlus extends StatelessWidget {
  const _BoutonPlus({required this.libelle, required this.onTap});

  final String libelle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: libelle,
    excludeSemantics: true,
    child: PressionEchelle(
      onTap: onTap,
      echelle: 0.88,
      child: SizedBox.square(
        dimension: 44,
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: RhythmCouleurs.peche,
              shape: BoxShape.circle,
            ),
            child: const PictoRhythm(
              Picto.plus,
              taille: 16,
              epaisseur: 2.4,
              couleur: RhythmCouleurs.noir,
            ),
          ),
        ),
      ),
    ),
  );
}
