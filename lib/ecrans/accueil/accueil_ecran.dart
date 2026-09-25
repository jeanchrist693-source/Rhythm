// lib/ecrans/accueil/accueil_ecran.dart
//
// L'accueil (maquette « Accueil »), sans cartes (`filets.dart`) : la date et
// le bonjour ; le verset du jour ; les quatre domaines dans une grille à
// croix de filets (Sports, Alimentation, Habitudes, Lecture) — le CŒUR de
// l'accueil, RESSERRÉ (l'utilisateur, le 24 sept. : « les 4 grosses cartes,
// essaye de réduire ») : le pictogramme DANS son anneau, le libellé à côté,
// le chiffre dessous ; la libération ; la
// prochaine séance (vivante : `sports/etat_sport.dart`). Chaque case, le
// verset et la séance mènent à leur onglet ; la
// cloche, aux Rappels. La case Habitudes est VIVANTE : ce qui est fait
// aujourd'hui, et la série de journées complètes.
//
// LIBÉRATION (demande de l'utilisateur : « une section spéciale, bien
// visible à l'ouverture ») : juste sous la grille (`BlocLiberation`) — les jours en grand (ils comptent à l'entrée), les
// heures qui vivent, la jauge du prochain palier, « Envie ? » qui ouvre le
// soutien sans détour ; la ligne mène à la fiche. Sans libération, une
// ligne discrète en bas de l'accueil propose d'en commencer une.
//
// À l'ouverture de l'app, tout entre selon la partition `EntreeAccueil`
// (animation [entree], pilotée par la coquille) : blocs en cascade, croix
// qui se trace depuis son centre, anneaux, chiffres qui comptent, arcs des
// habitudes faites qui s'allument un à un.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/traductions.dart';
import '../../modele/alimentation/calculs_alimentation.dart';
import '../../modele/alimentation/etat_alimentation.dart';
import '../../modele/calculs_habitudes.dart';
import '../../modele/etat_habitudes.dart';
import '../../modele/etat_sante.dart';
import '../../modele/graine.dart';
import '../../modele/habitudes.dart';
import '../../modele/sports/calculs_sport.dart';
import '../../modele/sports/etat_sport.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/apparition.dart';
import '../../widgets/jauges.dart';
import '../../widgets/filets.dart';
import '../../widgets/page_rhythm.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/surfaces.dart';
import '../coquille/entree_accueil.dart';
import '../coquille/onglets.dart';
import '../habitudes/envie_ecran.dart';
import '../habitudes/habitude_detail_ecran.dart';
import '../habitudes/habitude_formulaire_ecran.dart';
import '../habitudes/pieces_habitudes.dart';
import '../rappels/rappels_ecran.dart';

class AccueilEcran extends ConsumerWidget {
  const AccueilEcran({super.key, required this.entree, required this.onAller});

  /// L'entrée de l'accueil (0 → 1), une fois par lancement.
  final Animation<double> entree;

  /// Bascule vers un onglet (`Onglets`).
  final ValueChanged<int> onAller;

  Widget _bloc(int rang, Widget enfant) => Apparition(
    animation: entree,
    intervalle: EntreeAccueil.bloc(rang),
    montee: EntreeAccueil.montee,
    child: enfant,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final aujourdhui = ref.watch(aujourdhuiProvider);
    final semaine = ref.watch(semaineSportProvider);
    final etat = ref.watch(habitudesProvider);
    final construire = etat.aConstruire;
    final liberer = etat.aLiberer;
    // Rangs : en-tête 0, verset 1, cases 2 à 5, libération 6 ; ce qui suit
    // glisse d'un pas quand il y a une libération.
    final d = liberer.isEmpty ? 0 : 1;
    final jour = journee(construire, jourDe(aujourdhui));
    final serie = serieGlobale(construire, aujourdhui);
    final auj = jourDe(aujourdhui);
    final kcal = totalDe(
      ref.watch(alimentationProvider).entreesDu(auj),
    ).kcal.round();
    final objectifKcal = ref.watch(besoinsProvider(auj)).kcal;
    const plan = Graine.plan;
    final sport = ref.watch(sportProvider);
    final prochaine = prochaineSeance(
      sport.programmes,
      sport.journal,
      aujourdhui,
    );

    // Construites une fois par build : le tracé de la croix ne les
    // reconstruit pas à chaque image.
    final cases = <Widget>[
      _bloc(
        2,
        _Mesure(
          entree: entree,
          constructeur: (p) => _CaseDomaine(
            anneau: _anneau(
              semaine.minutesAujourdhui / semaine.objectifJour * p,
              RhythmCouleurs.corail,
              Picto.haltere,
            ),
            libelle: tr.navSports,
            valeur: tr.minutes((semaine.minutesAujourdhui * p).round()),
            detail: tr.objectifMinutes(semaine.objectifJour),
            onTap: () => onAller(Onglets.sports),
          ),
        ),
      ),
      _bloc(
        3,
        _Mesure(
          entree: entree,
          constructeur: (p) => _CaseDomaine(
            anneau: _anneau(
              kcal / objectifKcal * p,
              RhythmCouleurs.peche,
              Picto.couverts,
            ),
            libelle: tr.navAlimentation,
            valeur: tr.kcal(f.entier((kcal * p).round())),
            detail: kcal <= objectifKcal
                ? tr.resteKcal(f.entier(objectifKcal - kcal))
                : tr.kcalDePlus(f.entier(kcal - objectifKcal)),
            onTap: () => onAller(Onglets.alimentation),
          ),
        ),
      ),
      _bloc(
        4,
        _Mesure(
          entree: entree,
          constructeur: (p) => _CaseDomaine(
            anneau: _ArcsHabitudes(
              total: jour.prevues,
              faites: jour.faites,
              entree: entree,
            ),
            libelle: tr.navHabitudes,
            valeur: tr.surTotal((jour.faites * p).round(), jour.prevues),
            detail: tr.serieDeJours(serie),
            onTap: () => onAller(Onglets.habitudes),
          ),
        ),
      ),
      _bloc(
        5,
        _Mesure(
          entree: entree,
          constructeur: (p) => _CaseDomaine(
            anneau: _anneau(
              plan.chapitre / plan.total * p,
              RhythmCouleurs.lavande,
              Picto.livre,
            ),
            libelle: tr.lecture,
            valeur: plan.chapitreEnCours,
            detail: tr.chapitreSur(plan.chapitre, plan.total),
            onTap: () => onAller(Onglets.biblique),
          ),
        ),
      ),
    ];

    return PageRhythm(
      blocs: [
        _bloc(
          0,
          EnTete(
            surtitre: Surtitre(f.jourComplet(aujourdhui)),
            titre: aujourdhui.hour < 18 ? tr.bonjour : tr.bonsoir,
            action: _BoutonCloche(
              libelle: tr.notifications,
              onTap: () => pousserEcran(context, const RappelsEcran()),
            ),
          ),
        ),
        _bloc(1, _Verset(onTap: () => onAller(Onglets.biblique))),
        AnimatedBuilder(
          animation: entree,
          builder: (context, _) => GrilleFilets(
            ecart: 14,
            trace: EntreeAccueil.filets.transform(entree.value),
            cases: cases,
          ),
        ),
        if (liberer.isNotEmpty)
          _bloc(
            6,
            BlocLiberation(
              habitudes: ordonner(liberer, etat.reglages),
              comptage: CurvedAnimation(
                parent: entree,
                curve: EntreeAccueil.compteurs,
              ),
              onOuvrir: (h) =>
                  pousserEcran(context, HabitudeDetailEcran(id: h.id)),
              onEnvie: (h) => pousserEcran(context, EnvieEcran(id: h.id)),
            ),
          ),
        if (prochaine case (final p, final quand))
          _bloc(
            6 + d,
            _ProchaineSeance(
              titre: tr.seanceEtHeure(
                p.nom,
                jourDe(quand) == jourDe(aujourdhui)
                    ? f.heure(quand.hour, quand.minute)
                    : '${f.jourCourt(quand.weekday)} '
                          '${f.heure(quand.hour, quand.minute)}',
              ),
              onTap: () => onAller(Onglets.sports),
            ),
          ),
        if (liberer.isEmpty)
          _bloc(
            7,
            _InvitationLiberation(
              onTap: () => pousserEcran(
                context,
                const HabitudeFormulaireEcran(genre: GenreHabitude.liberer),
              ),
            ),
          ),
      ],
    );
  }

  /// L'anneau d'une case, son pictogramme au centre.
  static Widget _anneau(double progression, Color couleur, Picto picto) =>
      Stack(
        alignment: Alignment.center,
        children: [
          Anneau(
            taille: _CaseDomaine.anneauTaille,
            rayon: 17,
            epaisseur: 3.5,
            progression: progression,
            couleur: couleur,
          ),
          PictoRhythm(picto, taille: 17, couleur: couleur, epaisseur: 2),
        ],
      );
}

/// Reconstruit [constructeur] avec l'avancement des compteurs (0 → 1).
class _Mesure extends StatelessWidget {
  const _Mesure({required this.entree, required this.constructeur});

  final Animation<double> entree;
  final Widget Function(double progression) constructeur;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: entree,
    builder: (_, _) =>
        constructeur(EntreeAccueil.compteurs.transform(entree.value)),
  );
}

/// La cloche : un pictogramme seul.
class _BoutonCloche extends StatelessWidget {
  const _BoutonCloche({required this.libelle, required this.onTap});

  final String libelle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: libelle,
    excludeSemantics: true,
    child: PressionEchelle(
      onTap: onTap,
      echelle: 0.92,
      child: const SizedBox.square(
        dimension: 48,
        child: Center(child: PictoRhythm(Picto.cloche)),
      ),
    ),
  );
}

class _Verset extends StatelessWidget {
  const _Verset({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    const verset = Graine.verset;
    return PressionEchelle(
      onTap: onTap,
      echelle: 0.985,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Pastille(
                picto: Picto.livre,
                couleur: RhythmCouleurs.lavande,
                taille: 30,
              ),
              const SizedBox(width: 10),
              Text(
                tr.versetDuJour.toUpperCase(),
                style: RhythmTypo.texte(
                  13,
                  poids: 600,
                  couleur: RhythmCouleurs.lavande,
                  espacement: 0.06,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '« ${verset.texte} »',
            style: RhythmTypo.titre(
              24,
              poids: 500,
              espacement: -0.01,
              hauteur: 1.28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${verset.reference} · ${verset.traduction}',
            style: RhythmTypo.detail,
          ),
        ],
      ),
    );
  }
}

class _CaseDomaine extends StatelessWidget {
  const _CaseDomaine({
    required this.anneau,
    required this.libelle,
    required this.valeur,
    required this.detail,
    required this.onTap,
  });

  static const double anneauTaille = 40;

  final Widget anneau;
  final String libelle;
  final String valeur;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressionEchelle(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            anneau,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                libelle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: RhythmTypo.texte(14, couleur: RhythmCouleurs.texte72),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            valeur,
            maxLines: 1,
            softWrap: false,
            style: RhythmTypo.titre(24),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          detail,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: RhythmTypo.texte(12.5, couleur: RhythmCouleurs.texte64),
        ),
      ],
    ),
  );
}

/// L'anneau des habitudes du jour, un arc par habitude : menthe = faite.
/// À l'ouverture, les arcs des faites se déroulent un à un. Huit au plus
/// (au-delà, à l'échelle).
class _ArcsHabitudes extends StatelessWidget {
  const _ArcsHabitudes({
    required this.total,
    required this.faites,
    required this.entree,
  });

  final int total;
  final int faites;
  final Animation<double> entree;

  @override
  Widget build(BuildContext context) {
    final n = total > 8 ? 8 : total;
    final pleins = total > 8 ? (faites * 8 / total).round() : faites;
    return AnneauSegmente(
      taille: _CaseDomaine.anneauTaille,
      rayon: 17,
      epaisseur: 3.5,
      total: n,
      pleins: pleins,
      couleur: RhythmCouleurs.menthe,
      eclat: (i) => EntreeAccueil.pastille(i).transform(entree.value),
      child: const Center(
        child: PictoRhythm(
          Picto.coche,
          taille: 17,
          couleur: RhythmCouleurs.menthe,
          epaisseur: 2.2,
        ),
      ),
    );
  }
}

/// La prochaine séance : un trait corail, le nom et l'heure, une flèche —
/// rien autour.
class _ProchaineSeance extends StatelessWidget {
  const _ProchaineSeance({required this.titre, required this.onTap});

  final String titre;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PressionEchelle(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: RhythmCouleurs.corail,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr.prochaineSeance, style: RhythmTypo.petit),
                const SizedBox(height: 2),
                Text(titre, style: RhythmTypo.texte(15, poids: 600)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const PictoRhythm(
            Picto.fleche,
            taille: 20,
            couleur: RhythmCouleurs.texte64,
          ),
        ],
      ),
    ),
  );
}

/// Sans libération : une ligne discrète pour en commencer une.
class _InvitationLiberation extends StatelessWidget {
  const _InvitationLiberation({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Semantics(
      button: true,
      child: PressionEchelle(
        onTap: onTap,
        echelle: 0.985,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: RhythmCouleurs.cocheVide,
                    width: 1.5,
                  ),
                ),
                child: const PictoRhythm(
                  Picto.vague,
                  taille: 17,
                  epaisseur: 2,
                  couleur: RhythmCouleurs.menthe,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.meLibererDependance,
                      style: RhythmTypo.texte(15, poids: 600),
                    ),
                    const SizedBox(height: 2),
                    Text(tr.aLibererAide, style: RhythmTypo.petit),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const PictoRhythm(
                Picto.fleche,
                taille: 20,
                couleur: RhythmCouleurs.texte64,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
