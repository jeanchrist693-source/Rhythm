// lib/ecrans/alimentation/ia/bilan_ecran.dart
//
// LE BILAN DE LA SEMAINE (palier 4) : les CHIFFRES d'abord — calculés sur
// le téléphone (`bilan_semaine.dart`) : journées notées, calories et
// protéines par journée notée face aux objectifs, fibres (repère 25 g),
// sodium (limite 2 300 mg), eau, séances, ce qui a été jeté. Puis l'AVIS de
// l'assistant, qui les commente sans les recalculer : ce qui va bien, ce
// qui peut s'améliorer, trois pistes pour la semaine. Demandé à l'ouverture,
// gardé le temps de la session (rouvrir le bilan ne redemande rien) ;
// « Refaire le bilan » le redemande.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ia/ia_alimentation.dart';
import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/bilan_semaine.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/sports/etat_sport.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../utils/dates.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/jauges.dart';
import '../../../widgets/page_secondaire.dart';
import 'pieces_ia.dart';

/// Les bilans commentés, par semaine ([BilanSemaine.cle]), le temps de la
/// session.
final bilansIaProvider = NotifierProvider<BilansIa, Map<String, BilanIa>>(
  BilansIa.new,
);

class BilansIa extends Notifier<Map<String, BilanIa>> {
  @override
  Map<String, BilanIa> build() => const {};

  void garder(String cle, BilanIa b) => state = {...state, cle: b};
}

/// Le bilan de la semaine, tel qu'il se calcule maintenant.
final bilanSemaineProvider = Provider<BilanSemaine>((ref) {
  final auj = ref.watch(aujourdhuiProvider);
  final etat = ref.watch(alimentationProvider);
  return bilanDeLaSemaine(
    journal: etat.journal,
    eau: etat.eau,
    besoins: ref.watch(besoinsProvider(jourDe(auj))),
    seances: ref.watch(sportProvider).journal,
    sorties: ref.watch(coursesProvider).sorties,
    aujourdhui: auj,
  );
});

class BilanEcran extends ConsumerStatefulWidget {
  const BilanEcran({super.key, required this.retour});

  final String retour;

  @override
  ConsumerState<BilanEcran> createState() => _BilanEcranState();
}

class _BilanEcranState extends ConsumerState<BilanEcran>
    with AppelIa<BilanEcran> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final b = ref.read(bilanSemaineProvider);
      if (ref.read(bilansIaProvider)[b.cle] == null) _demander();
    });
  }

  Future<void> _demander() async {
    final b = ref.read(bilanSemaineProvider);
    final etat = ref.read(alimentationProvider);
    final aConsommer = [
      for (final a in aConsommerBientot(
        ref.read(coursesProvider).gardeManger,
        ref.read(aujourdhuiProvider),
      ))
        a.nom,
    ];
    final francais = Localizations.localeOf(context).languageCode == 'fr';
    final r = await appeler(
      () => commenterBilan(
        b,
        objectif: etat.profil.objectif,
        aConsommer: aConsommer,
        francais: francais,
      ),
    );
    if (r != null) ref.read(bilansIaProvider.notifier).garder(b.cle, r);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final b = ref.watch(bilanSemaineProvider);
    final avis = ref.watch(bilansIaProvider)[b.cle];
    final m = b.moyenne;
    final notes = b.joursNotes > 0;

    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(
          titre: tr.iaBilan,
          surtitre: Text(
            '${f.dateCourte(b.debut)} – ${f.dateCourte(b.fin)}',
            style: RhythmTypo.surtitre,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.iaLesChiffres),
            _Chiffre(
              libelle: tr.iaJourneesNotees,
              valeur: tr.iaSurSept(b.joursNotes),
              progression: b.joursNotes / 7,
              couleur: RhythmCouleurs.peche,
              premier: true,
            ),
            if (notes) ...[
              _Chiffre(
                libelle: tr.iaCaloriesParJour,
                valeur: tr.iaSurObjectif(
                  f.entier(m.kcal.round()),
                  f.kcalDe(b.kcalVisees.toDouble(), tr),
                ),
                progression: m.kcal / b.kcalVisees,
                couleur: RhythmCouleurs.peche,
              ),
              _Chiffre(
                libelle: tr.iaProteinesParJour,
                valeur: tr.iaSurObjectif(
                  f.entier(m.proteines.round()),
                  f.g(b.proteinesVisees.toDouble(), tr),
                ),
                progression: m.proteines / b.proteinesVisees,
                couleur: RhythmCouleurs.corail,
              ),
              _Chiffre(
                libelle: tr.iaFibresParJour,
                valeur: tr.iaRepere(f.g(m.fibres, tr), f.g(kFibresVisees, tr)),
                progression: m.fibres / kFibresVisees,
                couleur: RhythmCouleurs.menthe,
              ),
              _Chiffre(
                libelle: tr.iaSodiumParJour,
                valeur: tr.iaLimite(
                  tr.iaMg(f.entier(m.sodium.round())),
                  tr.iaMg(f.entier(kSodiumLimite.round())),
                ),
                progression: m.sodium / kSodiumLimite,
                couleur: m.sodium > kSodiumLimite
                    ? RhythmCouleurs.corail
                    : RhythmCouleurs.lavande,
              ),
            ],
            _Chiffre(
              libelle: tr.hydratation,
              valeur: tr.iaVerresParJour(
                f.decimal((b.verresMoyens * 10).round() / 10),
                b.verresVises,
              ),
              progression: b.verresMoyens / b.verresVises,
              couleur: RhythmCouleurs.ciel,
            ),
            _Chiffre(libelle: tr.iaSeances, valeur: f.entier(b.seances)),
            if (b.jetes.isNotEmpty)
              _Chiffre(libelle: tr.iaJetes, valeur: enPhrase(b.jetes)),
            if (b.frequents.isNotEmpty)
              _Chiffre(
                libelle: tr.iaSouvent,
                valeur: enPhrase(b.frequents.map((x) => x.$1)),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.iaAvis, couleur: RhythmCouleurs.peche),
            if (enCours)
              AttenteIa(message: tr.iaAttenteBilan)
            else if (avis != null) ...[
              Text(
                avis.resume,
                style: RhythmTypo.titre(19, poids: 500, hauteur: 1.3),
              ),
              if (avis.pistes.isNotEmpty) ...[
                const SizedBox(height: 16),
                for (final (i, p) in avis.pistes.indexed) ...[
                  if (i > 0) const Filet(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${i + 1}',
                            style: RhythmTypo.titre(
                              17,
                              couleur: RhythmCouleurs.peche,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            p,
                            style: RhythmTypo.texte(15, hauteur: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ] else if (erreur != null)
              ErreurIaBloc(erreur: erreur, onReessayer: _demander),
            if (avis != null && !enCours) ...[
              const SizedBox(height: 12),
              BoutonContour(libelle: tr.iaRefaireBilan, onTap: _demander),
            ],
          ],
        ),
        Text(tr.iaBilanPasMedical, style: RhythmTypo.petit),
        const MentionIa(),
      ],
    );
  }
}

/// Une ligne de chiffres : libellé, valeur, et une jauge si [progression].
class _Chiffre extends StatelessWidget {
  const _Chiffre({
    required this.libelle,
    required this.valeur,
    this.progression,
    this.couleur = RhythmCouleurs.peche,
    this.premier = false,
  });

  final String libelle;
  final String valeur;
  final double? progression;
  final Color couleur;
  final bool premier;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (!premier) const Filet(),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(libelle, style: RhythmTypo.texte(15, poids: 500)),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    valeur,
                    textAlign: TextAlign.right,
                    style: RhythmTypo.texte(
                      14,
                      couleur: RhythmCouleurs.texte72,
                    ),
                  ),
                ),
              ],
            ),
            if (progression != null) ...[
              const SizedBox(height: 8),
              Jauge(
                progression: progression!.isFinite
                    ? progression!.clamp(0, 1).toDouble()
                    : 0,
                couleur: couleur,
              ),
            ],
          ],
        ),
      ),
    ],
  );
}
