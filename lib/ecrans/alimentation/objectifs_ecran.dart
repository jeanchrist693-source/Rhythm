// lib/ecrans/alimentation/objectifs_ecran.dart
//
// MES OBJECTIFS : les besoins du jour en grand (calories, macronutriments,
// eau), puis ce qui les fait —
// - l'objectif (perdre, maintenir, prendre du poids) et son rythme ;
// - moi : sexe, année de naissance, taille ; le poids vient des Mesures
//   (une seule source, partagée avec les Sports) ;
// - l'activité au quotidien, hors sport ;
// - le CALCUL, ligne par ligne (métabolisme, activité, séances, objectif,
//   ajustement) : rien de caché ;
// - l'ajustement automatique (la courbe de poids réelle corrige la
//   formule), les séances comptées, l'eau (et l'habitude qu'elle coche),
//   des objectifs fixés à la main.
// Tout s'applique à l'instant. Pas un avis médical.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_alimentation.dart';
import '../../l10n/libelles_sport.dart';
import '../../l10n/traductions.dart';
import '../../modele/alimentation/alimentation.dart';
import '../../modele/alimentation/calculs_alimentation.dart';
import '../../modele/alimentation/etat_alimentation.dart';
import '../../modele/etat_sante.dart';
import '../../modele/sports/etat_sport.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/filets.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/suivi_clavier.dart';
import '../sports/mesures_ecran.dart';
import 'pieces_alimentation.dart';

class ObjectifsEcran extends ConsumerStatefulWidget {
  const ObjectifsEcran({super.key, required this.retour});

  final String retour;

  @override
  ConsumerState<ObjectifsEcran> createState() => _ObjectifsEcranState();
}

class _ObjectifsEcranState extends ConsumerState<ObjectifsEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<ObjectifsEcran> {
  late final ProfilNutrition _depart = ref.read(alimentationProvider).profil;
  late final _annee = TextEditingController(
    text: _depart.anneeNaissance?.toString() ?? '',
  );
  late final _taille = TextEditingController(
    text: _depart.taille == null ? '' : '${_depart.taille!.round()}',
  );
  final _focusAnnee = FocusNode();
  final _focusTaille = FocusNode();

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focusAnnee);
    surveillerClavier(_focusTaille);
  }

  @override
  void dispose() {
    libererClavier();
    _annee.dispose();
    _taille.dispose();
    _focusAnnee.dispose();
    _focusTaille.dispose();
    super.dispose();
  }

  void _modifier(ProfilNutrition p) =>
      ref.read(alimentationProvider.notifier).modifierProfil(p);

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final auj = jourDe(ref.watch(aujourdhuiProvider));
    final p = ref.watch(alimentationProvider).profil;
    final b = ref.watch(besoinsProvider(auj));
    final mesures = ref.watch(sportProvider.select((s) => s.mesures));
    final pesee = mesures.where((m) => m.poids != null).lastOrNull;
    String kcal(double x, {bool signe = false}) {
      final v = (x / 10).round() * 10;
      final t = f.kcalDe(v.abs().toDouble(), tr);
      if (!signe) return t;
      return v > 0 ? '+ $t' : (v < 0 ? '− $t' : t);
    }

    Widget ligneCalcul(String libelle, String valeur, {String? detail}) =>
        LigneReglage(libelle: libelle, detail: detail, valeur: valeur);

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(titre: tr.mesObjectifs),
        _Resume(besoins: b),

        // L'objectif et son rythme.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.monObjectif),
            PucesChoix<ObjectifPoids>(
              options: [
                for (final o in ObjectifPoids.values) (o, o.libelle(tr)),
              ],
              valeur: p.objectif,
              onChanged: (o) => _modifier(p.copierAvec(objectif: o)),
            ),
            if (p.objectif != ObjectifPoids.maintenir) ...[
              const SizedBox(height: 10),
              PucesChoix<double>(
                options: [
                  for (final r in const [0.25, 0.5])
                    (r, tr.kgParSemaine(f.decimal(r))),
                ],
                valeur: p.rythme,
                onChanged: (r) => _modifier(p.copierAvec(rythme: r)),
              ),
            ],
            const SizedBox(height: 10),
            Text(switch (p.objectif) {
              ObjectifPoids.perdre => tr.objectifPerdreDetail(
                kcal(p.rythme * kKcalParKilo / 7),
              ),
              ObjectifPoids.maintenir => tr.objectifMaintenirDetail,
              ObjectifPoids.prendre => tr.objectifPrendreDetail(
                kcal(p.rythme * kKcalParKilo / 7),
              ),
            }, style: RhythmTypo.detail),
          ],
        ),

        // Moi.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.moi),
            PucesChoix<Sexe>(
              options: [for (final s in Sexe.values) (s, s.libelle(tr))],
              valeur: p.sexe,
              onChanged: (s) => _modifier(p.copierAvec(sexe: () => s)),
            ),
            const SizedBox(height: 18),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EtiquetteChamp(tr.anneeNaissance),
                      ChampNombre(
                        controleur: _annee,
                        focus: _focusAnnee,
                        indice: '1995',
                        decimales: 0,
                        onChanged: (t) {
                          final a = int.tryParse(t);
                          final ok =
                              a != null && a >= 1920 && a <= auj.year - 10;
                          if (ok || t.isEmpty) {
                            _modifier(
                              p.copierAvec(anneeNaissance: () => ok ? a : null),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EtiquetteChamp(tr.taille),
                      ChampNombre(
                        controleur: _taille,
                        focus: _focusTaille,
                        indice: '175',
                        suffixe: 'cm',
                        decimales: 0,
                        actionClavier: TextInputAction.done,
                        onChanged: (t) {
                          final v = double.tryParse(t);
                          final ok = v != null && v >= 120 && v <= 230;
                          if (ok || t.isEmpty) {
                            _modifier(
                              p.copierAvec(taille: () => ok ? v : null),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LigneReglage(
              libelle: tr.poids,
              detail: pesee == null
                  ? tr.poidsAucun
                  : tr.poidsDepuisMesures(f.dateCourte(pesee.date)),
              valeur: pesee == null ? null : f.kg(pesee.poids!, tr),
              onTap: () =>
                  pousserEcran(context, MesuresEcran(retour: tr.mesObjectifs)),
            ),
          ],
        ),

        // L'activité hors sport.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.auQuotidien),
            PucesChoix<ActiviteQuotidienne>(
              options: [
                for (final a in ActiviteQuotidienne.values) (a, a.libelle(tr)),
              ],
              valeur: p.activite,
              onChanged: (a) => _modifier(p.copierAvec(activite: a)),
            ),
            const SizedBox(height: 8),
            Text(p.activite.detail(tr), style: RhythmTypo.detail),
          ],
        ),

        // Le calcul, ligne par ligne.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.leCalcul),
            ligneCalcul(
              tr.metabolismeBase,
              kcal(b.metabolisme),
              detail: tr.metabolismeBaseDetail,
            ),
            const Filet(),
            ligneCalcul(tr.activiteQuotidienne, kcal(b.activite, signe: true)),
            const Filet(),
            ligneCalcul(
              tr.seancesMoyenne,
              kcal(b.sport, signe: true),
              detail: p.compterSeances ? null : tr.seancesNonComptees,
            ),
            const Filet(),
            ligneCalcul(tr.objectif, kcal(b.objectif, signe: true)),
            const Filet(),
            ligneCalcul(
              tr.ajustementAuto,
              kcal(b.ajustement.kcal.toDouble(), signe: true),
            ),
            const Filet(couleur: RhythmCouleurs.filetGrille),
            LigneReglage(
              libelle: b.manuel ? tr.calculIndicatif : tr.total,
              detail: b.manuel ? tr.objectifsFixesMain : null,
              // Calculé : le vrai objectif (plancher compris) ; fixé à la
              // main : ce que le calcul aurait donné.
              droite: Text(
                b.manuel
                    ? kcal(b.depenseFormule + b.objectif + b.ajustement.kcal)
                    : f.kcalDe(b.kcal.toDouble(), tr),
                style: RhythmTypo.texte(15, poids: 600),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tr.macrosExplication(f.decimal(proteinesParKilo(p.objectif))),
              style: RhythmTypo.detail,
            ),
          ],
        ),

        // L'ajustement automatique.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LigneReglage(
              libelle: tr.ajustementAuto,
              detail: tr.ajustementAutoDetail,
              droite: Interrupteur(
                valeur: p.ajustementAuto,
                onChanged: (v) => _modifier(p.copierAvec(ajustementAuto: v)),
              ),
            ),
            Text(
              _etatAjustement(b.ajustement),
              style: RhythmTypo.texte(13, couleur: RhythmCouleurs.peche),
            ),
          ],
        ),

        // Séances, eau.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LigneReglage(
              libelle: tr.compterSeances,
              detail: tr.compterSeancesDetail,
              droite: Interrupteur(
                valeur: p.compterSeances,
                onChanged: (v) => _modifier(p.copierAvec(compterSeances: v)),
              ),
            ),
            const Filet(),
            LigneReglage(
              libelle: tr.eauCalculee,
              detail: tr.eauCalculeeDetail,
              droite: Interrupteur(
                valeur: p.verresEau == null,
                onChanged: (v) => _modifier(
                  p.copierAvec(verresEau: () => v ? null : b.verres),
                ),
              ),
            ),
            if (p.verresEau != null) ...[
              const Filet(),
              LigneReglage(
                libelle: tr.verresParJour,
                detail: tr.litresValeur(
                  f.decimal(p.verresEau! * kLitresParVerre),
                ),
                droite: CompteurRhythm(
                  valeur: p.verresEau!,
                  min: 4,
                  max: 20,
                  affichage: (v) => '$v',
                  largeurValeur: 44,
                  onChanged: (v) => _modifier(p.copierAvec(verresEau: () => v)),
                ),
              ),
            ],
            const Filet(),
            LigneReglage(
              libelle: tr.lienHabitudeEau,
              detail: tr.lienHabitudeEauDetail,
              droite: Interrupteur(
                valeur: p.lienHabitudeEau,
                onChanged: (v) => _modifier(p.copierAvec(lienHabitudeEau: v)),
              ),
            ),
          ],
        ),

        // Des chiffres fixés à la main.
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LigneReglage(
              libelle: tr.fixerMesObjectifs,
              detail: tr.fixerMesObjectifsDetail,
              droite: Interrupteur(
                valeur: p.manuels != null,
                onChanged: (v) => _modifier(
                  p.copierAvec(
                    manuels: () => v
                        ? ObjectifsManuels(
                            kcal: b.kcal,
                            proteines: b.proteines,
                            glucides: b.glucides,
                            lipides: b.lipides,
                          )
                        : null,
                  ),
                ),
              ),
            ),
            if (p.manuels case final m?) ...[
              for (final (libelle, valeur, min, max, pas, copie)
                  in <
                    (String, int, int, int, int, ObjectifsManuels Function(int))
                  >[
                    (
                      tr.calories,
                      m.kcal,
                      1200,
                      5000,
                      50,
                      (v) => ObjectifsManuels(
                        kcal: v,
                        proteines: m.proteines,
                        glucides: m.glucides,
                        lipides: m.lipides,
                      ),
                    ),
                    (
                      tr.proteines,
                      m.proteines,
                      20,
                      350,
                      5,
                      (v) => ObjectifsManuels(
                        kcal: m.kcal,
                        proteines: v,
                        glucides: m.glucides,
                        lipides: m.lipides,
                      ),
                    ),
                    (
                      tr.glucides,
                      m.glucides,
                      20,
                      700,
                      5,
                      (v) => ObjectifsManuels(
                        kcal: m.kcal,
                        proteines: m.proteines,
                        glucides: v,
                        lipides: m.lipides,
                      ),
                    ),
                    (
                      tr.lipides,
                      m.lipides,
                      20,
                      300,
                      5,
                      (v) => ObjectifsManuels(
                        kcal: m.kcal,
                        proteines: m.proteines,
                        glucides: m.glucides,
                        lipides: v,
                      ),
                    ),
                  ]) ...[
                const Filet(),
                LigneReglage(
                  libelle: libelle,
                  droite: CompteurRhythm(
                    valeur: valeur,
                    min: min,
                    max: max,
                    pas: pas,
                    largeurValeur: 64,
                    affichage: (v) => pas == 50 ? f.entier(v) : '$v g',
                    onChanged: (v) =>
                        _modifier(p.copierAvec(manuels: () => copie(v))),
                  ),
                ),
              ],
            ],
          ],
        ),
        Text(
          tr.pasAvisMedical,
          style: RhythmTypo.texte(12, couleur: RhythmCouleurs.texte40),
        ),
      ],
    );
  }

  String _etatAjustement(Ajustement a) {
    final tr = context.tr;
    final f = context.formats;
    return switch (a.etat) {
      EtatAjustement.desactive => tr.ajustementDesactive,
      EtatAjustement.donneesInsuffisantes => tr.ajustementDonnees(
        tr.journeesNotees(a.joursNotes),
        tr.peseesNombre(a.pesees),
      ),
      EtatAjustement.actif => tr.ajustementActif(
        f.kcalDe(((a.depenseReelle ?? 0) / 10).round() * 10.0, tr),
        '${(a.rythmeReel ?? 0) >= 0 ? '+' : '−'}'
            '${f.decimal(((a.rythmeReel ?? 0).abs() * 100).round() / 100)}',
        '${a.kcal >= 0 ? '+' : '−'}${f.kcalDe(a.kcal.abs().toDouble(), tr)}',
      ),
    };
  }
}

/// Les objectifs du jour en grand : calories, macronutriments, eau.
class _Resume extends StatelessWidget {
  const _Resume({required this.besoins});

  final Besoins besoins;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final b = besoins;
    Widget macro(String libelle, int g, Color couleur) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(libelle, style: RhythmTypo.petit),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            f.g(g.toDouble(), tr),
            maxLines: 1,
            style: RhythmTypo.titre(22, couleur: couleur),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(f.entier(b.kcal), style: RhythmTypo.titre(40)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                tr.kcalParJour,
                style: RhythmTypo.texte(14, couleur: RhythmCouleurs.texte64),
              ),
            ),
          ],
        ),
        if (b.estimation) ...[
          const SizedBox(height: 4),
          Text(
            tr.estimationProfil,
            style: RhythmTypo.texte(13, couleur: RhythmCouleurs.peche),
          ),
        ],
        const SizedBox(height: 14),
        RangeeFilets(
          cases: [
            macro(tr.proteines, b.proteines, RhythmCouleurs.corail),
            macro(tr.glucides, b.glucides, RhythmCouleurs.peche),
            macro(tr.lipides, b.lipides, RhythmCouleurs.menthe),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          tr.eauObjectif(b.verres, f.decimal(b.verres * kLitresParVerre)),
          style: RhythmTypo.texte(14, couleur: RhythmCouleurs.ciel),
        ),
        if (b.jourDeSeance) ...[
          const SizedBox(height: 4),
          Text(tr.jourDeSeanceGlucides, style: RhythmTypo.detail),
        ],
      ],
    );
  }
}
