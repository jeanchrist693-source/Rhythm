// lib/ecrans/alimentation/recettes/plan_ecran.dart
//
// MA SEMAINE — la planification sur 7 jours à partir d'aujourd'hui : les
// jours en capsules (un point pêche quand un repas est prévu), puis les
// quatre moments du jour choisi — chacun ses plats prévus (une recette, un
// de mes produits, « autre chose »), « + » pour en ajouter ; toucher un plat
// l'ouvre (cuisiner, noter, déplacer, retirer). Puis CETTE SEMAINE : la
// liste de la semaine (moins le garde-manger et les restes), la cuisine en
// lot, ce qui est à décongeler ce soir ; et les réglages : les portions
// d'un repas prévu, le rappel de décongélation (la veille, à l'heure
// choisie).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/recettes.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/modeles.dart';
import '../../../navigation/transitions.dart';
import '../../../systeme/synchro.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../../sports/pieces_sports.dart';
import '../pieces_alimentation.dart';
import 'ajout_liste_ecran.dart';
import 'choisir_plat_ecran.dart';
import 'cuisine_lot_ecran.dart';
import 'pieces_recettes.dart';
import 'repas_prevu_ecran.dart';

class PlanEcran extends ConsumerStatefulWidget {
  const PlanEcran({super.key, required this.retour});

  final String retour;

  @override
  ConsumerState<PlanEcran> createState() => _PlanEcranState();
}

class _PlanEcranState extends ConsumerState<PlanEcran> {
  /// Le jour affiché ; `null` : aujourd'hui.
  DateTime? _jour;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final auj = jourDe(ref.watch(aujourdhuiProvider));
    var jour = _jour ?? auj;
    if (jour.isBefore(auj) || joursEntre(auj, jour) > 6) jour = auj;
    final etat = ref.watch(recettesProvider);
    final alimentation = ref.watch(alimentationProvider);
    final courses = ref.watch(coursesProvider);
    final notifier = ref.read(recettesProvider.notifier);
    final titre = tr.maSemaine;
    final fin = plusJours(auj, 7);
    final semaine = [
      for (final p in etat.plan)
        if (!p.jour.isBefore(auj) && p.jour.isBefore(fin)) p,
    ];
    final aCuisiner = recettesDeLaSemaine(
      etat,
      debut: auj,
      journal: alimentation.journal,
      gardeManger: courses.gardeManger,
    );
    final besoins = besoinsDe(
      [
        for (final s in aCuisiner)
          if (s.lots > 0) (s.recette, s.lots),
      ],
      gardeManger: courses.gardeManger,
      liste: courses.liste,
    );
    final manquent = besoins.where((b) => b.aProposer).length;
    final lot = aCuisiner.where((s) => s.repas.length >= 2).toList()
      ..sort((a, b) => b.repas.length.compareTo(a.repas.length));
    final demain = decongelationsDu(
      plusJours(auj, 1),
      etat,
      courses.gardeManger,
    );
    final r = etat.reglages;

    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(
          titre: titre,
          surtitre: Text(
            semaine.isEmpty
                ? tr.rienDePrevuSemaine
                : tr.repasPrevusNombre(semaine.length),
            style: RhythmTypo.surtitre,
          ),
        ),
        SeptJours(
          aujourdhui: auj,
          choisi: jour,
          aDesRepas: (j) => etat.prevusLe(j).isNotEmpty,
          onChoisir: (j) {
            HapticFeedback.selectionClick();
            setState(() => _jour = j == auj ? null : j);
          },
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(jour == auj ? tr.aujourdhui : f.jourComplet(jour)),
            for (final m in MomentRepas.values)
              _BlocMoment(
                jour: jour,
                moment: m,
                prevus: etat.prevusLe(jour, m),
                retour: titre,
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.cetteSemaine),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.panier,
                couleur: RhythmCouleurs.peche,
              ),
              libelle: tr.listeDeLaSemaine,
              detail: aCuisiner.isEmpty
                  ? tr.aucuneRecettePrevue
                  : manquent == 0
                  ? tr.toutEstLa
                  : tr.aAcheterNombre(manquent),
              onTap: () => pousserEcran(
                context,
                AjoutListeEcran(
                  titre: tr.listeDeLaSemaine,
                  sousTitre: tr.recettesPrevuesNombre(aCuisiner.length),
                  recettes: [
                    for (final s in aCuisiner)
                      if (s.lots > 0) (s.recette, s.lots),
                  ],
                  retour: titre,
                ),
              ),
            ),
            const Filet(),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.couverts,
                couleur: RhythmCouleurs.peche,
              ),
              libelle: tr.cuisineEnLot,
              detail: lot.isEmpty
                  ? tr.cuisineEnLotDetail
                  : tr.cuisineEnLotResume(
                      lot.first.recette.nom,
                      lot.first.repas.length,
                    ),
              onTap: () =>
                  pousserEcran(context, CuisineLotEcran(retour: titre)),
            ),
            if (demain.isNotEmpty) ...[
              const Filet(),
              LigneReglage(
                gauche: const PictoCercle(
                  Picto.frigo,
                  couleur: RhythmCouleurs.peche,
                ),
                libelle: tr.aDecongelerCeSoir,
                detail: enPhrase([
                  for (final d in demain)
                    for (final a in d.articles) a.nom,
                ]),
              ),
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.reglages),
            LigneReglage(
              libelle: tr.portionsParRepas,
              detail: tr.portionsParRepasDetail,
              droite: CompteurRhythm(
                valeur: r.personnes,
                min: 1,
                max: 12,
                largeurValeur: 44,
                affichage: (p) => '$p',
                onChanged: (p) =>
                    notifier.modifierReglages(r.copierAvec(personnes: p)),
              ),
            ),
            const Filet(),
            LigneReglage(
              libelle: tr.rappelDecongelation,
              detail: tr.rappelDecongelationDetail(
                f.heureMinutes(r.heureDecongelation),
              ),
              droite: Interrupteur(
                valeur: r.rappelsDecongelation,
                onChanged: (v) {
                  notifier.modifierReglages(
                    r.copierAvec(rappelsDecongelation: v),
                  );
                  if (v) assurerAutorisation(ref);
                },
              ),
            ),
            if (r.rappelsDecongelation) ...[
              const SizedBox(height: 8),
              RouletteHeure(
                minutes: r.heureDecongelation,
                onChanged: (m) => notifier.modifierReglages(
                  r.copierAvec(heureDecongelation: m),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Un moment du jour : son nom, « + », puis ses plats prévus (noté : un
/// point menthe).
class _BlocMoment extends ConsumerWidget {
  const _BlocMoment({
    required this.jour,
    required this.moment,
    required this.prevus,
    required this.retour,
  });

  final DateTime jour;
  final MomentRepas moment;
  final List<RepasPrevu> prevus;
  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final recettes = ref.watch(recettesProvider);
    final alimentation = ref.watch(alimentationProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Filet(),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  moment.libelle(tr),
                  style: RhythmTypo.texte(15, poids: 600),
                ),
              ),
              BoutonRond(
                couleur: RhythmCouleurs.capsule,
                libelle: tr.prevoirAu(moment.name),
                onTap: () => pousserEcran(
                  context,
                  ChoisirPlatEcran(jour: jour, moment: moment, retour: retour),
                ),
                child: const PictoRhythm(
                  Picto.plus,
                  taille: 18,
                  epaisseur: 2.2,
                  couleur: RhythmCouleurs.texte,
                ),
              ),
            ],
          ),
        ),
        if (prevus.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(tr.rienDePrevuMoment, style: RhythmTypo.detail),
          ),
        for (final p in prevus)
          Builder(
            builder: (context) {
              final r = recettes.recette(p.recetteId);
              final produit = alimentation.produit(p.produitId ?? '');
              final note = prevuNote(p, alimentation.journal);
              final kcal = r != null
                  ? r.parPortion.kcal * p.portions
                  : produit != null
                  ? produit.parPortion.kcal * p.portions
                  : null;
              return LigneAliment(
                filet: false,
                nom: r?.nom ?? produit?.nom ?? p.libre ?? '—',
                detail: [
                  if (note) tr.mangeCourt,
                  if (r != null || produit != null) f.portions(p.portions, tr),
                  if (produit != null) tr.monProduit,
                ].join(' · '),
                valeur: kcal == null ? null : f.kcalDe(kcal, tr),
                droite: note
                    ? const PictoRhythm(
                        Picto.coche,
                        taille: 18,
                        epaisseur: 2.4,
                        couleur: RhythmCouleurs.menthe,
                      )
                    : null,
                onTap: () => pousserEcran(
                  context,
                  RepasPrevuEcran(id: p.id, retour: retour),
                ),
              );
            },
          ),
      ],
    );
  }
}
