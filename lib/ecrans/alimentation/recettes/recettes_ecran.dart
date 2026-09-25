// lib/ecrans/alimentation/recettes/recettes_ecran.dart
//
// MES RECETTES — le livre : « Nouvelle recette » et « Ma semaine » à portée
// de pouce ; la recherche (nom, région, ingrédients), le moment (déjeuner,
// dîner, collation, souper), le TRI (récentes, A à Z, protéines, calories,
// rapides — retenu), la région s'il y en a (la grande région — « Afrique
// de l'Ouest » —, puis ses cuisines) ; une capsule choisie, touchée de
// nouveau, se retire ; chaque recette avec ses
// portions, son temps, ses protéines et ses calories par portion. Livre
// vide : les huit recettes de départ, d'un toucher. L'IA (palier 4) :
// « Idées » (des recettes générées, région et moment choisis) et
// « Importer une recette » (un texte collé, structuré).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/recettes.dart';
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
import '../ia/idees_ecran.dart';
import '../ia/importer_ecran.dart';
import '../pieces_alimentation.dart';
import 'pieces_recettes.dart';
import 'plan_ecran.dart';
import 'recette_ecran.dart';
import 'recette_formulaire_ecran.dart';

class RecettesEcran extends ConsumerStatefulWidget {
  const RecettesEcran({super.key, required this.retour});

  final String retour;

  @override
  ConsumerState<RecettesEcran> createState() => _RecettesEcranState();
}

class _RecettesEcranState extends ConsumerState<RecettesEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<RecettesEcran> {
  final _recherche = TextEditingController();
  final _focus = FocusNode();
  MomentRepas? _moment;
  String? _region;

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

  void _depart() {
    final n = ref.read(recettesProvider.notifier).ajouterRecettesDeDepart();
    HapticFeedback.lightImpact();
    montrerToast(context, context.tr.recettesAjoutees(n));
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(recettesProvider);
    final notifier = ref.read(recettesProvider.notifier);
    final titre = tr.mesRecettes;
    final requete = _recherche.text.trim();
    // Les grandes régions du livre et, dans chacune, les cuisines qu'il a
    // (une rangée de plus seulement s'il y a de quoi choisir) ; les régions
    // à soi à la fin.
    final utilisees = {for (final r in etat.recettes) ?r.region};
    RegionCulinaire? dansLeLivre(RegionCulinaire g) {
      if (!utilisees.any((u) => dansLaRegion(u, g.nom))) return null;
      final cuisines = [
        for (final c in g.cuisines)
          if (utilisees.any((u) => memeRegion(u, c))) c,
      ];
      final elleMeme = utilisees.any((u) => memeRegion(u, g.nom));
      return RegionCulinaire(
        g.nom,
        cuisines.length + (elleMeme ? 1 : 0) >= 2 ? cuisines : const [],
      );
    }

    final regions = [for (final g in kRegionsCulinaires) ?dansLeLivre(g)];
    final autres = [
      for (final u in utilisees)
        if (grandeRegionDe(u) == null) u,
    ]..sort();
    // Un filtre dont plus aucune recette ne relève (supprimée) s'efface.
    final region =
        _region != null &&
            etat.recettes.any((r) => dansLaRegion(r.region, _region!))
        ? _region
        : null;
    final visibles = trierRecettes([
      for (final r in etat.recettes)
        if ((_moment == null || r.moments.contains(_moment)) &&
            (region == null || dansLaRegion(r.region, region)) &&
            recetteRepond(r, requete))
          r,
    ], etat.reglages.tri);
    final departManquantes = GraineRecettes.depart(DateTime(2026)).any(
      (d) =>
          !etat.recettes.any((r) => r.nom.toLowerCase() == d.nom.toLowerCase()),
    );

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: titre,
          surtitre: etat.recettes.isEmpty
              ? null
              : Text(
                  tr.recettesNombre(etat.recettes.length),
                  style: RhythmTypo.surtitre,
                ),
        ),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            BoutonCapsule(
              picto: Picto.plus,
              libelle: tr.nouvelleRecette,
              plein: true,
              onTap: () =>
                  pousserEcran(context, RecetteFormulaireEcran(retour: titre)),
            ),
            BoutonCapsule(
              picto: Picto.etincelles,
              libelle: tr.iaIdeesCourt,
              onTap: () => pousserEcran(context, IdeesEcran(retour: titre)),
            ),
            BoutonCapsule(
              picto: Picto.calendrier,
              libelle: tr.maSemaine,
              onTap: () => pousserEcran(context, PlanEcran(retour: titre)),
            ),
          ],
        ),
        if (etat.recettes.isEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(tr.livreVide, style: RhythmTypo.texte(15)),
              const SizedBox(height: 16),
              BoutonPlein(
                libelle: tr.recettesDeDepart,
                largeurPleine: true,
                hauteur: 52,
                taillePolice: 15,
                onTap: _depart,
              ),
              const SizedBox(height: 10),
              Text(tr.recettesDeDepartDetail, style: RhythmTypo.petit),
              const SizedBox(height: 16),
              const Filet(),
              LigneReglage(
                libelle: tr.iaImporter,
                detail: tr.iaImporterDetailCourt,
                onTap: () =>
                    pousserEcran(context, ImporterEcran(retour: titre)),
              ),
            ],
          )
        else ...[
          ChampRhythm(
            controleur: _recherche,
            focus: _focus,
            indice: tr.chercherRecette,
            actionClavier: TextInputAction.search,
            onChanged: (_) => setState(() {}),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RangeePuces<MomentRepas?>(
                options: [
                  (null, tr.tout),
                  for (final m in MomentRepas.values) (m, m.libelle(tr)),
                ],
                valeur: _moment,
                // Le moment choisi, touché de nouveau : « Tout ».
                onChanged: (m) =>
                    setState(() => _moment = m == _moment ? null : m),
              ),
              const SizedBox(height: 10),
              RangeePuces<TriRecettes>(
                options: [
                  for (final t in TriRecettes.values) (t, t.libelle(tr)),
                ],
                valeur: etat.reglages.tri,
                onChanged: (t) =>
                    notifier.modifierReglages(etat.reglages.copierAvec(tri: t)),
              ),
              if (regions.isNotEmpty || autres.isNotEmpty) ...[
                const SizedBox(height: 10),
                ChoixRegion(
                  valeur: region,
                  aucune: tr.toutesLesRegions,
                  regions: regions,
                  autres: autres,
                  onChanged: (r) => setState(() => _region = r),
                ),
              ],
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (visibles.isEmpty)
                Text(
                  requete.isEmpty ? tr.rienIci : tr.aucuneRecette(requete),
                  style: RhythmTypo.detail,
                ),
              for (final (i, r) in visibles.indexed)
                LigneAliment(
                  filet: i > 0,
                  nom: r.nom,
                  detail: detailRecette(r, f, tr),
                  valeur: f.kcalDe(r.parPortion.kcal, tr),
                  onTap: () => pousserEcran(
                    context,
                    RecetteEcran(id: r.id, retour: titre),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Filet(),
              LigneReglage(
                libelle: tr.iaImporter,
                detail: tr.iaImporterDetailCourt,
                onTap: () =>
                    pousserEcran(context, ImporterEcran(retour: titre)),
              ),
              if (departManquantes) ...[
                const Filet(),
                LigneReglage(
                  libelle: tr.recettesDeDepart,
                  detail: tr.recettesDeDepartDetail,
                  onTap: _depart,
                ),
              ],
            ],
          ),
          Text(
            tr.macrosCalculees,
            style: RhythmTypo.texte(11, couleur: RhythmCouleurs.texte40),
          ),
        ],
      ],
    );
  }
}
