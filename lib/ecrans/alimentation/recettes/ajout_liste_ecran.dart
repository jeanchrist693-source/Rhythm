// lib/ecrans/alimentation/recettes/ajout_liste_ecran.dart
//
// « À LA LISTE » — d'une recette ou de la semaine : chaque ingrédient,
// additionné d'une recette à l'autre, MOINS ce qu'il y a au garde-manger et
// ce qui est déjà sur la liste. Ce qui manque est coché d'emblée (« à
// acheter : 300 g · pour : chili, bol poulet ») ; ce qu'on a déjà, en
// menthe, ne l'est pas (on peut le cocher quand même). « Ajouter » les met
// sur la liste — fusionnés, avec leurs origines — et l'ouvre.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_courses.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/base_aliments.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/rayons.dart';
import '../../../modele/alimentation/recettes.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/toast.dart';
import '../courses/courses_ecran.dart';
import '../courses/pieces_courses.dart';

class AjoutListeEcran extends ConsumerStatefulWidget {
  const AjoutListeEcran({
    super.key,
    required this.titre,
    required this.recettes,
    required this.retour,
    this.sousTitre,
  });

  final String titre;
  final String? sousTitre;

  /// Les recettes et combien de fois les cuisiner.
  final List<(Recette, double)> recettes;
  final String retour;

  @override
  ConsumerState<AjoutListeEcran> createState() => _AjoutListeEcranState();
}

class _AjoutListeEcranState extends ConsumerState<AjoutListeEcran> {
  /// Les choix de la personne (par nom) ; les autres suivent la
  /// proposition.
  final Map<String, bool> _choix = {};

  bool _coche(Besoin b) => _choix[b.nom] ?? b.aProposer;

  void _ajouter(List<Besoin> besoins) {
    final tr = context.tr;
    final base = ref.read(baseAlimentsProvider).value;
    final choisis = [
      for (final b in besoins)
        if (_coche(b)) (b.nom, rayonDe(b.nom, base), b.aAcheter, b.origines),
    ];
    if (choisis.isEmpty) {
      montrerToast(context, tr.rienACocher);
      return;
    }
    final n = ref.read(coursesProvider.notifier).ajouterBesoins(choisis);
    HapticFeedback.lightImpact();
    montrerToast(context, tr.articlesAjoutesListe(n));
    remplacerEcran(context, CoursesEcran(retour: widget.retour));
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final courses = ref.watch(coursesProvider);
    final besoins = besoinsDe(
      widget.recettes,
      gardeManger: courses.gardeManger,
      liste: courses.liste,
    );
    final n = besoins.where(_coche).length;

    String detail(Besoin b) {
      if (b.enStock.isNotEmpty) {
        return tr.dejaAuGardeManger(
          b.enStock
              .map(
                (x) => x.quantite == null
                    ? x.nom
                    : '${x.nom} (${f.quantite(x.quantite!, tr)})',
              )
              .join(', '),
        );
      }
      if (b.surLaListe.isNotEmpty && b.aAcheter.isEmpty) {
        return tr.dejaSurLaListe;
      }
      if (b.aVerifier) {
        return [
          tr.aVerifierPlacard,
          if (b.requis.isNotEmpty)
            f.quantites([for (final q in b.requis) arrondiCourses(q)], tr),
        ].join(' · ');
      }
      return [
        if (b.aAcheter.isNotEmpty)
          tr.aAcheter(f.quantites(b.aAcheter, tr))
        else if (b.requis.isNotEmpty)
          f.quantites([for (final q in b.requis) arrondiCourses(q)], tr),
        if (widget.recettes.length > 1)
          tr.pourOrigines(enPhrase(b.origines, premiere: false)),
      ].join(' · ');
    }

    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(
          titre: widget.titre,
          surtitre: widget.sousTitre == null
              ? null
              : Text(widget.sousTitre!, style: RhythmTypo.surtitre),
        ),
        if (besoins.isEmpty)
          Text(tr.aucunIngredient, style: RhythmTypo.detail)
        else ...[
          Text(
            [
              tr.aAcheterNombre(besoins.where((b) => b.aProposer).length),
              if (besoins.any((b) => !b.aProposer && !b.aVerifier))
                tr.dejaLaNombre(
                  besoins.where((b) => !b.aProposer && !b.aVerifier).length,
                ),
              if (besoins.any((b) => b.aVerifier))
                tr.aVerifierNombre(besoins.where((b) => b.aVerifier).length),
            ].join(' · '),
            style: RhythmTypo.texte(15, poids: 500),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, b) in besoins.indexed)
                LigneCourse(
                  filet: i > 0,
                  coche: _coche(b),
                  nom: b.nom,
                  detail: detail(b),
                  detailCouleur: b.aProposer || b.aVerifier
                      ? null
                      : RhythmCouleurs.menthe,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _choix[b.nom] = !_coche(b));
                  },
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              BoutonPlein(
                libelle: tr.ajouterALaListeNombre(n),
                largeurPleine: true,
                hauteur: 52,
                taillePolice: 15,
                onTap: () => _ajouter(besoins),
              ),
              const SizedBox(height: 10),
              Text(tr.ajoutListeAide, style: RhythmTypo.petit),
            ],
          ),
        ],
      ],
    );
  }
}
