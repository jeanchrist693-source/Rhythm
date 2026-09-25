// lib/ecrans/alimentation/ia/ecart_ecran.dart
//
// COMBLER L'ÉCART (palier 4) : ce qui reste de la journée — calories,
// protéines, glucides, lipides, CALCULÉS sur le téléphone — et le repas qui
// reste à prendre (le souper, une collation). L'IA propose trois options,
// les restes et le garde-manger d'abord : une recette du livre (tant de
// portions) ou quelques aliments simples. Chaque option est CHIFFRÉE par la
// base (ou par la recette) : son total et ce qui restera après ; « Noter au
// journal » l'y met d'un toucher (une recette prise dans les restes s'il y
// en a).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ia/ia_alimentation.dart';
import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/base_aliments.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/correspondance.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/nutriments.dart';
import '../../../modele/alimentation/recettes.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/modeles.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../../../widgets/toast.dart';
import '../pieces_alimentation.dart';
import '../recettes/pieces_recettes.dart';
import 'pieces_ia.dart';

/// Ce qui reste de [visees] une fois [mange] : jamais négatif.
Nutriments resteDuJour(Nutriments visees, Nutriments mange) => Nutriments(
  kcal: (visees.kcal - mange.kcal).clamp(0, double.infinity).toDouble(),
  proteines: (visees.proteines - mange.proteines)
      .clamp(0, double.infinity)
      .toDouble(),
  glucides: (visees.glucides - mange.glucides)
      .clamp(0, double.infinity)
      .toDouble(),
  lipides: (visees.lipides - mange.lipides)
      .clamp(0, double.infinity)
      .toDouble(),
);

class EcartEcran extends ConsumerStatefulWidget {
  const EcartEcran({super.key, required this.retour});

  final String retour;

  @override
  ConsumerState<EcartEcran> createState() => _EcartEcranState();
}

class _EcartEcranState extends ConsumerState<EcartEcran>
    with AppelIa<EcartEcran> {
  late MomentRepas _moment = switch (momentPourHeure(
    ref.read(aujourdhuiProvider),
  )) {
    MomentRepas.dejeuner || MomentRepas.diner => MomentRepas.diner,
    final m => m,
  };
  List<OptionEcart> _options = const [];
  final _cleResultats = GlobalKey();
  final Map<OptionEcart, List<Correspondance>> _calculs = {};

  /// Les options déjà notées.
  final Set<OptionEcart> _notees = {};

  ({Nutriments visees, Nutriments reste}) _chiffres() {
    final auj = jourDe(ref.read(aujourdhuiProvider));
    final besoins = ref.read(besoinsProvider(auj));
    final visees = Nutriments(
      kcal: besoins.kcal.toDouble(),
      proteines: besoins.proteines.toDouble(),
      glucides: besoins.glucides.toDouble(),
      lipides: besoins.lipides.toDouble(),
    );
    final mange = totalDe(ref.read(alimentationProvider).entreesDu(auj));
    return (visees: visees, reste: resteDuJour(visees, mange));
  }

  Future<void> _proposer() async {
    final (:visees, :reste) = _chiffres();
    final recettes = ref.read(recettesProvider).recettes;
    final courses = ref.read(coursesProvider);
    final maintenant = ref.read(aujourdhuiProvider);
    final d = DemandeEcart(
      moment: _moment,
      reste: reste,
      visees: visees,
      recettes: [
        for (final r in recettes)
          if (r.pour(_moment)) r,
      ].take(30).toList(),
      restes: {
        for (final r in recettes)
          if (portionsEnRestes(courses.gardeManger, r.id) > 0)
            r.id: portionsEnRestes(courses.gardeManger, r.id),
      },
      gardeManger: {
        for (final a in courses.gardeManger)
          if (!a.restes) a.nom,
      }.take(40).toList(),
      aConsommer: [
        for (final a in aConsommerBientot(courses.gardeManger, maintenant))
          if (!a.restes) a.nom,
      ],
    );
    final francais = Localizations.localeOf(context).languageCode == 'fr';
    final r = await appeler(() => comblerEcart(d, francais: francais));
    if (r == null || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _options = r;
      _notees.clear();
    });
    montrer(_cleResultats);
  }

  void _noter(OptionEcart o, Recette? recette, List<Correspondance>? c) {
    final tr = context.tr;
    final maintenant = ref.read(horlogeProvider)();
    final auj = jourDe(maintenant);
    if (recette != null) {
      final restes = portionsEnRestes(
        ref.read(coursesProvider).gardeManger,
        recette.id,
      );
      ref
          .read(recettesProvider.notifier)
          .noter(
            recette: recette,
            portions: o.portions,
            jour: auj,
            moment: _moment,
            depuisRestes: restes >= o.portions - 1e-6,
          );
    } else if (c != null) {
      final alimentation = ref.read(alimentationProvider.notifier);
      for (final x in c) {
        if (x.aliment == null) continue;
        alimentation.ajouter(
          entreeDeCorrespondance(
            x,
            id: alimentation.nouvelId('ent'),
            jour: auj,
            moment: _moment,
            ajoutee: maintenant,
          ),
        );
      }
    }
    HapticFeedback.lightImpact();
    setState(() => _notees.add(o));
    montrerToast(context, tr.iaNoteAuJournal(o.titre));
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    ref.watch(alimentationProvider);
    ref.watch(besoinsProvider(jourDe(ref.watch(aujourdhuiProvider))));
    final (:visees, :reste) = _chiffres();
    final base = ref.watch(baseAlimentsProvider).value;
    final etat = ref.watch(recettesProvider);

    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(
          titre: tr.iaEcart,
          surtitre: Text(tr.aujourdhui, style: RhythmTypo.surtitre),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              f.kcalDe(reste.kcal, tr),
              style: RhythmTypo.titre(34, couleur: RhythmCouleurs.peche),
            ),
            Text(tr.iaResteAujourdhui, style: RhythmTypo.detail),
            const SizedBox(height: 12),
            Text(
              [
                '${Macro.proteines.libelle(tr)} ${f.g(reste.proteines, tr)}',
                '${Macro.glucides.libelle(tr)} ${f.g(reste.glucides, tr)}',
                '${Macro.lipides.libelle(tr)} ${f.g(reste.lipides, tr)}',
              ].join(' · '),
              style: RhythmTypo.texte(14, couleur: RhythmCouleurs.texte72),
            ),
            if (reste.kcal < 150) ...[
              const SizedBox(height: 10),
              Text(tr.iaPresqueAtteint, style: RhythmTypo.petit),
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.iaPourQuelRepas),
            RangeePuces<MomentRepas>(
              options: [for (final m in MomentRepas.values) (m, m.libelle(tr))],
              valeur: _moment,
              onChanged: (m) => setState(() => _moment = m),
            ),
          ],
        ),
        BoutonPlein(
          libelle: _options.isEmpty ? tr.iaDesIdees : tr.iaAutresIdees,
          largeurPleine: true,
          hauteur: 52,
          taillePolice: 15,
          onTap: _proposer,
        ),
        if (enCours)
          AttenteIa(message: tr.iaAttenteEcart)
        else if (erreur != null)
          ErreurIaBloc(erreur: erreur, onReessayer: _proposer),
        for (final (k, o) in _options.indexed)
          Builder(
            key: k == 0 ? _cleResultats : null,
            builder: (context) {
              final recette = etat.recette(o.recetteId);
              final c = recette != null || base == null
                  ? null
                  : _calculs[o] ??= [
                      for (final a in o.aliments)
                        correspondre(
                          a,
                          base,
                          frequents: frequentsBase(
                            ref.read(alimentationProvider).journal,
                          ),
                        ),
                    ];
              final total = recette != null
                  ? recette.parPortion * o.portions
                  : Nutriments.somme([
                      for (final x in c ?? const <Correspondance>[])
                        x.nutriments,
                    ]);
              final note = _notees.contains(o);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Filet(),
                  const SizedBox(height: 14),
                  Text(o.titre, style: RhythmTypo.texte(17, poids: 600)),
                  if (o.pourquoi != null) ...[
                    const SizedBox(height: 4),
                    Text(o.pourquoi!, style: RhythmTypo.detail),
                  ],
                  const SizedBox(height: 6),
                  if (recette != null)
                    LigneAliment(
                      filet: false,
                      nom: recette.nom,
                      detail: f.portions(o.portions, tr),
                      valeur: f.kcalDe(total.kcal, tr),
                    )
                  else
                    for (final (i, x)
                        in (c ?? const <Correspondance>[]).indexed)
                      LigneCorrespondance(correspondance: x, filet: i > 0),
                  const SizedBox(height: 8),
                  Text(
                    tr.iaTotalEtReste(
                      f.kcalDe(total.kcal, tr),
                      f.g(total.proteines, tr),
                      f.kcalDe((reste.kcal - total.kcal).abs(), tr),
                      reste.kcal - total.kcal >= 0 ? 'reste' : 'plus',
                    ),
                    style: RhythmTypo.texte(13, couleur: RhythmCouleurs.peche),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: note
                        ? Text(
                            tr.iaNote,
                            style: RhythmTypo.texte(
                              14,
                              poids: 600,
                              couleur: RhythmCouleurs.menthe,
                            ),
                          )
                        : BoutonCapsule(
                            picto: Picto.plus,
                            libelle: tr.noterAuJournal,
                            onTap: () => _noter(o, recette, c),
                          ),
                  ),
                  const SizedBox(height: 4),
                ],
              );
            },
          ),
        Text(
          tr.iaEcartDetail(f.kcalDe(visees.kcal, tr)),
          style: RhythmTypo.texte(13, couleur: RhythmCouleurs.texte64),
        ),
        const MentionIa(),
      ],
    );
  }
}
