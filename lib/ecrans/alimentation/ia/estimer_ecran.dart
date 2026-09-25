// lib/ecrans/alimentation/ia/estimer_ecran.dart
//
// ESTIMER UN REPAS SANS RECETTE (palier 4) : au restaurant, chez des amis —
// on le DÉCRIT (« deux pointes de pizza toute garnie et une salade
// César ») ; l'IA le décompose en aliments et en quantités pour une
// personne ; chaque aliment est cherché dans la base du FCÉN, qui le
// CHIFFRE. Toucher une ligne la retire (ou la remet) ; un aliment que la
// base ne connaît pas n'est pas compté. « Noter au journal » les ajoute au
// repas choisi, comme s'ils avaient été cherchés un à un.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ia/ia_alimentation.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/base_aliments.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/correspondance.dart';
import '../../../modele/alimentation/etat_alimentation.dart';
import '../../../modele/alimentation/nutriments.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/modeles.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/suivi_clavier.dart';
import '../../../widgets/toast.dart';
import '../pieces_alimentation.dart';
import '../recettes/pieces_recettes.dart';
import 'pieces_ia.dart';

class EstimerEcran extends ConsumerStatefulWidget {
  const EstimerEcran({
    super.key,
    required this.jour,
    required this.moment,
    required this.retour,
    this.description,
  });

  final DateTime jour;
  final MomentRepas moment;
  final String retour;

  /// Ce qui avait été tapé dans la recherche.
  final String? description;

  @override
  ConsumerState<EstimerEcran> createState() => _EstimerEcranState();
}

class _EstimerEcranState extends ConsumerState<EstimerEcran>
    with
        WidgetsBindingObserver,
        SuiviClavierMixin<EstimerEcran>,
        AppelIa<EstimerEcran> {
  late final _description = TextEditingController(text: widget.description);
  final _focus = FocusNode();
  late MomentRepas _moment = widget.moment;

  List<Correspondance>? _aliments;
  final _cleResultats = GlobalKey();

  /// Les lignes retirées.
  final Set<int> _retires = {};

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focus);
  }

  @override
  void dispose() {
    libererClavier();
    _description.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _estimer() async {
    final tr = context.tr;
    final texte = _description.text.trim();
    if (texte.length < 3) {
      montrerToast(context, tr.iaDecrisTonRepas);
      return;
    }
    final francais = Localizations.localeOf(context).languageCode == 'fr';
    final r = await appeler(() async {
      final e = await estimerRepas(texte, francais: francais);
      final base = await ref.read(baseAlimentsProvider.future);
      final frequents = frequentsBase(ref.read(alimentationProvider).journal);
      return [
        for (final a in e.aliments) correspondre(a, base, frequents: frequents),
      ];
    });
    if (r == null || !mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _aliments = r;
      _retires.clear();
    });
    montrer(_cleResultats);
  }

  void _noter() {
    final aliments = _aliments;
    if (aliments == null || transitionEnCours) return;
    final tr = context.tr;
    final alimentation = ref.read(alimentationProvider.notifier);
    final maintenant = ref.read(horlogeProvider)();
    var n = 0;
    for (final (i, c) in aliments.indexed) {
      if (_retires.contains(i) || c.aliment == null) continue;
      alimentation.ajouter(
        entreeDeCorrespondance(
          c,
          id: alimentation.nouvelId('ent'),
          jour: jourDe(widget.jour),
          moment: _moment,
          ajoutee: maintenant,
        ),
      );
      n++;
    }
    if (n == 0) return;
    HapticFeedback.lightImpact();
    montrerToast(context, tr.iaAlimentsNotes(n, _moment.libelle(tr)));
    retirerEcran(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final aliments = _aliments;
    final comptes = [
      for (final (i, c) in (aliments ?? const <Correspondance>[]).indexed)
        if (!_retires.contains(i) && c.aliment != null) c,
    ];
    final total = Nutriments.somme(comptes.map((c) => c.nutriments));

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: tr.iaEstimer,
          surtitre: Text(tr.iaEstimerSurtitre, style: RhythmTypo.surtitre),
        ),
        Column(
          key: const ValueKey('description'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.iaTonRepas),
            ChampRhythm(
              controleur: _description,
              focus: _focus,
              indice: tr.iaIndiceEstimer,
              lignes: 3,
              actionClavier: TextInputAction.done,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.iaMoment),
            RangeePuces<MomentRepas>(
              options: [for (final m in MomentRepas.values) (m, m.libelle(tr))],
              valeur: _moment,
              onChanged: (m) => setState(() => _moment = m),
            ),
          ],
        ),
        BoutonPlein(
          libelle: aliments == null ? tr.iaEstimerBouton : tr.iaReestimer,
          largeurPleine: true,
          hauteur: 52,
          taillePolice: 15,
          onTap: _estimer,
        ),
        if (enCours)
          AttenteIa(message: tr.iaAttenteEstimer)
        else if (erreur != null)
          ErreurIaBloc(erreur: erreur, onReessayer: _estimer),
        if (aliments != null && !enCours)
          if (aliments.isEmpty)
            Text(tr.iaRienAEstimer, style: RhythmTypo.detail)
          else ...[
            Column(
              key: _cleResultats,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TitreSection(tr.iaCeQueJeCompte),
                for (final (i, c) in aliments.indexed)
                  LigneCorrespondance(
                    correspondance: c,
                    filet: i > 0,
                    coche: c.aliment == null ? null : !_retires.contains(i),
                    onTap: c.aliment == null
                        ? null
                        : () => setState(() {
                            HapticFeedback.selectionClick();
                            if (!_retires.remove(i)) _retires.add(i);
                          }),
                  ),
                const SizedBox(height: 16),
                ApercuNutriments(nutriments: total),
              ],
            ),
            if (comptes.isNotEmpty)
              BoutonPlein(
                libelle: tr.iaNoterNombre(comptes.length),
                largeurPleine: true,
                hauteur: 52,
                taillePolice: 15,
                onTap: _noter,
              ),
          ],
        Text(tr.iaEstimerDetail, style: RhythmTypo.petit),
        const MentionIa(),
      ],
    );
  }
}
