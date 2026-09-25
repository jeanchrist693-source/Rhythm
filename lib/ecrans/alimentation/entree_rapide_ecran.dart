// lib/ecrans/alimentation/entree_rapide_ecran.dart
//
// L'ENTRÉE RAPIDE : des calories (et, si on les connaît, les
// macronutriments) sans chercher l'aliment — un repas au restaurant, une
// assiette chez des amis. Un nom facultatif, le moment. Sert aussi à
// modifier une entrée rapide du journal (« Retirer du repas » en deux
// temps).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_alimentation.dart';
import '../../l10n/traductions.dart';
import '../../modele/alimentation/alimentation.dart';
import '../../modele/alimentation/etat_alimentation.dart';
import '../../modele/alimentation/nutriments.dart';
import '../../modele/etat_sante.dart';
import '../../modele/modeles.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/boutons.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/suivi_clavier.dart';
import '../../widgets/toast.dart';
import 'pieces_alimentation.dart';

class EntreeRapideEcran extends ConsumerStatefulWidget {
  const EntreeRapideEcran({
    super.key,
    required this.jour,
    required this.moment,
    required this.retour,
    this.nom,
    this.modele,
    this.edition,
  });

  final DateTime jour;
  final MomentRepas moment;
  final String retour;

  /// Le nom proposé (le texte cherché).
  final String? nom;

  /// Une entrée rapide récente, à noter de nouveau.
  final EntreeJournal? modele;

  /// L'entrée à modifier.
  final EntreeJournal? edition;

  @override
  ConsumerState<EntreeRapideEcran> createState() => _EntreeRapideEcranState();
}

class _EntreeRapideEcranState extends ConsumerState<EntreeRapideEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<EntreeRapideEcran> {
  late final EntreeJournal? _depart = widget.edition ?? widget.modele;
  late final _nom = TextEditingController(
    text: _depart?.nom ?? widget.nom ?? '',
  );
  late final _kcal = TextEditingController(text: _v(_depart?.nutriments.kcal));
  late final _p = TextEditingController(
    text: _v(_depart?.nutriments.proteines),
  );
  late final _g = TextEditingController(text: _v(_depart?.nutriments.glucides));
  late final _l = TextEditingController(text: _v(_depart?.nutriments.lipides));
  final _focus = List.generate(5, (_) => FocusNode());
  late MomentRepas _moment = widget.edition?.moment ?? widget.moment;

  static String _v(double? x) => x == null || x == 0
      ? ''
      : (x == x.roundToDouble() ? '${x.round()}' : x.toStringAsFixed(1));

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
    for (final c in [_nom, _kcal, _p, _g, _l]) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _enregistrer() {
    if (transitionEnCours) return;
    final tr = context.tr;
    final f = context.formats;
    final kcal = ChampNombre.lire(_kcal);
    if (kcal == null || kcal <= 0) {
      montrerToast(context, tr.kcalRequises);
      return;
    }
    final n = Nutriments(
      kcal: kcal,
      proteines: ChampNombre.lire(_p) ?? 0,
      glucides: ChampNombre.lire(_g) ?? 0,
      lipides: ChampNombre.lire(_l) ?? 0,
    );
    final nom = _nom.text.trim().isEmpty ? tr.entreeRapide : _nom.text.trim();
    final notifier = ref.read(alimentationProvider.notifier);
    final e = widget.edition;
    if (e != null) {
      notifier.modifier(
        EntreeJournal(
          id: e.id,
          jour: e.jour,
          moment: _moment,
          nom: nom,
          source: SourceEntree.rapide,
          nutriments: n,
          ajoutee: e.ajoutee,
        ),
      );
      HapticFeedback.selectionClick();
    } else {
      notifier.ajouter(
        EntreeJournal(
          id: notifier.nouvelId('ent'),
          jour: jourDe(widget.jour),
          moment: _moment,
          nom: nom,
          source: SourceEntree.rapide,
          nutriments: n,
          ajoutee: ref.read(horlogeProvider)(),
        ),
      );
      HapticFeedback.lightImpact();
      montrerToast(
        context,
        tr.ajouteA(tr.auMoment(_moment.name), f.kcalDe(kcal, tr)),
      );
    }
    retirerEcran(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    Widget champ(
      String etiquette,
      TextEditingController c,
      int i,
      String suffixe, {
      int decimales = 1,
    }) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EtiquetteChamp(etiquette),
        ChampNombre(
          controleur: c,
          focus: _focus[i],
          suffixe: suffixe,
          decimales: decimales,
          actionClavier: i == 4 ? TextInputAction.done : TextInputAction.next,
        ),
      ],
    );

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(titre: tr.entreeRapide),
        Text(tr.entreeRapideExplication, style: RhythmTypo.detail),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.nomFacultatif),
            ChampRhythm(
              controleur: _nom,
              focus: _focus[0],
              indice: tr.indiceEntreeRapide,
              actionClavier: TextInputAction.next,
            ),
          ],
        ),
        champ(tr.calories, _kcal, 1, 'kcal', decimales: 0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: champ(tr.proteines, _p, 2, 'g')),
            const SizedBox(width: 14),
            Expanded(child: champ(tr.glucides, _g, 3, 'g')),
            const SizedBox(width: 14),
            Expanded(child: champ(tr.lipides, _l, 4, 'g')),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.moment),
            PucesChoix<MomentRepas>(
              options: [for (final m in MomentRepas.values) (m, m.libelle(tr))],
              valeur: _moment,
              onChanged: (m) => setState(() => _moment = m),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoutonPlein(
              libelle: widget.edition != null
                  ? tr.enregistrer
                  : tr.ajouterAu(tr.auMoment(_moment.name)),
              largeurPleine: true,
              hauteur: 52,
              taillePolice: 15,
              onTap: _enregistrer,
            ),
            if (widget.edition != null) ...[
              const SizedBox(height: 12),
              BoutonSuppression(
                libelle: tr.retirerDuRepas,
                confirmation: tr.toucherPourRetirer,
                onConfirme: () {
                  ref
                      .read(alimentationProvider.notifier)
                      .retirer(widget.edition!.id);
                  retirerEcran(context, true);
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
