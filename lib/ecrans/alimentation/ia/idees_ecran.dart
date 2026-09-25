// lib/ecrans/alimentation/ia/idees_ecran.dart
//
// DES IDÉES DE RECETTES (palier 4) : on choisit AVANT de générer — la
// RÉGION (les grandes régions, puis leurs cuisines : `ChoixRegion`), le
// MOMENT (déjeuner, dîner, collation, souper), le GENRE de plat (plat,
// soupe, salade…), les portions, « rapide », « riche en protéines »,
// « végétarien », « avec mon garde-manger », des précisions. Trois idées
// reviennent, chacune avec ce qu'une portion apporte — CALCULÉ par la base
// du FCÉN ; toucher une idée l'ouvre (`RecetteProposeeEcran`) : au livre,
// puis à la semaine ou à la liste. « Autres idées » n'en repropose aucune.
//
// En mode ANTI-GASPILLAGE, les aliments qui pressent au garde-manger sont
// en tête (tous choisis d'emblée) : chaque idée en utilise au moins un.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ia/ia_alimentation.dart';
import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/base_aliments.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/correspondance.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/nutriments.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/modeles.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/suivi_clavier.dart';
import '../pieces_alimentation.dart';
import '../recettes/pieces_recettes.dart';
import 'pieces_ia.dart';
import 'recette_proposee_ecran.dart';

/// Les options d'une demande d'idées.
enum OptionIdees { rapide, proteinees, vegetarien, gardeManger }

class IdeesEcran extends ConsumerStatefulWidget {
  const IdeesEcran({
    super.key,
    required this.retour,
    this.antiGaspillage = false,
  });

  final String retour;

  /// Avec ce qui presse au garde-manger.
  final bool antiGaspillage;

  @override
  ConsumerState<IdeesEcran> createState() => _IdeesEcranState();
}

class _IdeesEcranState extends ConsumerState<IdeesEcran>
    with
        WidgetsBindingObserver,
        SuiviClavierMixin<IdeesEcran>,
        AppelIa<IdeesEcran> {
  final _precisions = TextEditingController();
  final _focus = FocusNode();
  final _cleResultats = GlobalKey();

  String? _region;
  MomentRepas? _moment;
  GenrePlat? _genre;
  int _portions = 4;
  Set<OptionIdees> _options = {};

  /// Anti-gaspillage : les aliments qui pressent, choisis.
  late Set<String> _aUtiliser = {..._pressants()};

  List<RecetteProposee> _idees = const [];
  final List<String> _dejaProposees = [];
  final Map<RecetteProposee, List<Correspondance>> _calculs = {};

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focus);
  }

  @override
  void dispose() {
    libererClavier();
    _precisions.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Ce qui presse au garde-manger (4 jours), sans les restes.
  List<String> _pressants() {
    final noms = <String>[];
    for (final a in aConsommerBientot(
      ref.read(coursesProvider).gardeManger,
      ref.read(aujourdhuiProvider),
      jours: 4,
    )) {
      if (!a.restes && !noms.contains(a.nom)) noms.add(a.nom);
    }
    return noms;
  }

  Future<void> _proposer() async {
    final courses = ref.read(coursesProvider);
    final livre = ref.read(recettesProvider).recettes;
    final aUtiliser = widget.antiGaspillage
        ? [
            for (final n in _pressants())
              if (_aUtiliser.contains(n)) n,
          ]
        : const <String>[];
    final avecGardeManger =
        widget.antiGaspillage || _options.contains(OptionIdees.gardeManger);
    final demande = DemandeIdees(
      region: _region,
      moment: _moment,
      genre: _genre,
      portions: _portions,
      rapide: _options.contains(OptionIdees.rapide),
      proteinees: _options.contains(OptionIdees.proteinees),
      vegetarien: _options.contains(OptionIdees.vegetarien),
      precisions: _precisions.text,
      aUtiliser: aUtiliser,
      gardeManger: avecGardeManger
          ? {
              for (final a in courses.gardeManger)
                if (!a.restes && !aUtiliser.contains(a.nom)) a.nom,
            }.take(40).toList()
          : const [],
      aEviter: {
        ..._dejaProposees.reversed,
        for (final r in livre.reversed) r.nom,
      }.take(40).toList(),
    );
    final francais = Localizations.localeOf(context).languageCode == 'fr';
    final r = await appeler(() => idees(demande, francais: francais));
    if (r == null || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _idees = r;
      _dejaProposees.addAll(r.map((x) => x.nom));
    });
    montrer(_cleResultats);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final titre = widget.antiGaspillage ? tr.iaAvecCeQuiPresse : tr.iaIdees;
    final pressants = widget.antiGaspillage ? _pressants() : const <String>[];
    final base = ref.watch(baseAlimentsProvider).value;
    final livre = ref.watch(recettesProvider).recettes;
    // Au livre, par nom (une idée ajoutée le dit).
    final auLivre = {for (final r in livre) r.nom.toLowerCase()};

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: titre,
          surtitre: Text(tr.iaIdeesSurtitre, style: RhythmTypo.surtitre),
        ),
        if (widget.antiGaspillage)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.iaAUtiliser, couleur: RhythmCouleurs.peche),
              if (pressants.isEmpty)
                Text(tr.iaRienNePresse, style: RhythmTypo.detail)
              else
                PucesMultiples<String>(
                  options: [for (final n in pressants) (n, n)],
                  valeurs: _aUtiliser,
                  onChanged: (v) => setState(() => _aUtiliser = v),
                ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.iaCuisine),
            ChoixRegion(
              valeur: _region,
              aucune: tr.iaPeuImporte,
              onChanged: (r) => setState(() => _region = r),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.iaMoment),
            RangeePuces<MomentRepas?>(
              options: [
                (null, tr.iaPeuImporte),
                for (final m in MomentRepas.values) (m, m.libelle(tr)),
              ],
              valeur: _moment,
              onChanged: (m) =>
                  setState(() => _moment = m == _moment ? null : m),
            ),
            const SizedBox(height: 18),
            TitreSection(tr.iaGenre),
            RangeePuces<GenrePlat?>(
              options: [
                (null, tr.iaPeuImporte),
                for (final g in GenrePlat.values) (g, _libelleGenre(g, tr)),
              ],
              valeur: _genre,
              onChanged: (g) => setState(() => _genre = g == _genre ? null : g),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LigneReglage(
              libelle: tr.iaPortions,
              droite: CompteurRhythm(
                valeur: _portions,
                min: 1,
                max: 12,
                largeurValeur: 104,
                affichage: (p) => f.portions(p.toDouble(), tr),
                onChanged: (p) => setState(() => _portions = p),
              ),
            ),
            const SizedBox(height: 10),
            PucesMultiples<OptionIdees>(
              options: [
                (OptionIdees.rapide, tr.iaOptionRapide),
                (OptionIdees.proteinees, tr.iaOptionProteinees),
                (OptionIdees.vegetarien, tr.iaOptionVegetarien),
                if (!widget.antiGaspillage)
                  (OptionIdees.gardeManger, tr.iaOptionGardeManger),
              ],
              valeurs: _options,
              onChanged: (o) => setState(() => _options = o),
            ),
          ],
        ),
        Column(
          key: const ValueKey('precisions'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.iaPrecisions),
            ChampRhythm(
              controleur: _precisions,
              focus: _focus,
              indice: tr.iaIndicePrecisions,
              lignes: 2,
              actionClavier: TextInputAction.done,
            ),
          ],
        ),
        BoutonPlein(
          libelle: _idees.isEmpty ? tr.iaProposer : tr.iaAutresIdees,
          largeurPleine: true,
          hauteur: 52,
          taillePolice: 15,
          onTap: _proposer,
        ),
        if (enCours)
          AttenteIa(message: tr.iaAttenteIdees)
        else if (erreur != null)
          ErreurIaBloc(erreur: erreur, onReessayer: _proposer),
        if (_idees.isNotEmpty)
          Column(
            key: _cleResultats,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.iaPropositions),
              for (final (i, p) in _idees.indexed)
                Builder(
                  builder: (context) {
                    final c = base == null
                        ? null
                        : _calculs[p] ??= correspondancesDe(p, base, ref);
                    final parPortion = c == null
                        ? null
                        : Nutriments.somme(c.map((x) => x.nutriments)) *
                              (1 / p.portions);
                    final duree = (p.preparation ?? 0) + (p.cuisson ?? 0);
                    final deja = auLivre.contains(p.nom.toLowerCase());
                    return LigneAliment(
                      filet: i > 0,
                      nom: p.nom,
                      detail: [
                        if (deja) tr.iaAuLivre,
                        ?p.region,
                        if (duree > 0) f.minutes(duree),
                        if (parPortion != null && parPortion.proteines >= 1)
                          tr.proteinesDe(f.g(parPortion.proteines, tr)),
                        ?p.description,
                      ].join(' · '),
                      valeur: parPortion == null
                          ? null
                          : f.kcalDe(parPortion.kcal, tr),
                      onTap: () => pousserEcran(
                        context,
                        RecetteProposeeEcran(proposition: p, retour: titre),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 6),
              Text(tr.iaParPortionCalcule, style: RhythmTypo.petit),
            ],
          ),
        const MentionIa(),
      ],
    );
  }
}

String _libelleGenre(GenrePlat g, AppLocalizations tr) => switch (g) {
  GenrePlat.plat => tr.iaGenrePlat,
  GenrePlat.soupe => tr.iaGenreSoupe,
  GenrePlat.salade => tr.iaGenreSalade,
  GenrePlat.sandwich => tr.iaGenreSandwich,
  GenrePlat.bol => tr.iaGenreBol,
  GenrePlat.dessert => tr.iaGenreDessert,
  GenrePlat.boisson => tr.iaGenreBoisson,
};
