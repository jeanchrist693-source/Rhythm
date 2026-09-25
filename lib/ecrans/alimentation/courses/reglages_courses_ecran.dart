// lib/ecrans/alimentation/courses/reglages_courses_ecran.dart
//
// RAYONS, MAGASINS ET BUDGET :
// - le budget d'épicerie du mois (au magasin, ce qui en reste) ;
// - mes magasins (ajouter, retirer) ;
// - l'ORDRE DES RAYONS, celui du magasin : maintenir une ligne la soulève
//   et la déplace (la liste et le magasin suivent cet ordre) ;
// - les rappels de péremption (une notification le matin quand des
//   aliments sont à consommer d'ici le lendemain) et leur heure.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_courses.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../systeme/synchro.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../../../widgets/suivi_clavier.dart';

class ReglagesCoursesEcran extends ConsumerStatefulWidget {
  const ReglagesCoursesEcran({super.key, required this.retour});

  final String retour;

  @override
  ConsumerState<ReglagesCoursesEcran> createState() =>
      _ReglagesCoursesEcranState();
}

class _ReglagesCoursesEcranState extends ConsumerState<ReglagesCoursesEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<ReglagesCoursesEcran> {
  final _magasin = TextEditingController();
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focus);
  }

  @override
  void dispose() {
    libererClavier();
    _magasin.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _modifier(ReglagesCourses r) =>
      ref.read(coursesProvider.notifier).modifierReglages(r);

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final r = ref.watch(coursesProvider).reglages;

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(titre: tr.rayonsMagasinsBudget),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LigneReglage(
              libelle: tr.budgetEpicerie,
              detail: tr.budgetEpicerieDetail,
              droite: Interrupteur(
                valeur: r.budgetMois != null,
                onChanged: (v) =>
                    _modifier(r.copierAvec(budgetMois: () => v ? 500 : null)),
              ),
            ),
            if (r.budgetMois != null)
              LigneReglage(
                libelle: tr.parMois,
                droite: CompteurRhythm(
                  valeur: r.budgetMois!.round(),
                  min: 50,
                  max: 5000,
                  pas: 25,
                  largeurValeur: 92,
                  affichage: (v) => f.argent(v.toDouble()),
                  onChanged: (v) =>
                      _modifier(r.copierAvec(budgetMois: () => v.toDouble())),
                ),
              ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.mesMagasins),
            for (final (i, m) in r.magasins.indexed) ...[
              if (i > 0) const Filet(),
              LigneReglage(
                libelle: m,
                droite: BoutonPicto(
                  picto: Picto.croix,
                  libelle: tr.retirerMagasin(m),
                  couleur: RhythmCouleurs.texte64,
                  onTap: () => _modifier(
                    r.copierAvec(
                      magasins: [
                        for (final x in r.magasins)
                          if (x != m) x,
                      ],
                      magasin: r.magasin == m ? () => null : null,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            ChampRhythm(
              controleur: _magasin,
              focus: _focus,
              indice: tr.ajouterMagasin,
              actionClavier: TextInputAction.done,
              onValider: (t) {
                final m = t.trim();
                if (m.isEmpty || r.magasins.contains(m)) return;
                _modifier(r.copierAvec(magasins: [...r.magasins, m]));
                _magasin.clear();
              },
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.ordreDesRayons),
            Text(tr.ordreDesRayonsAide, style: RhythmTypo.detail),
            const SizedBox(height: 8),
            ReorderableListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              buildDefaultDragHandles: false,
              onReorderStart: (_) => HapticFeedback.mediumImpact(),
              onReorderItem: (ancien, nouveau) {
                if (ancien == nouveau) return;
                final ordre = [...r.ordreRayons];
                ordre.insert(nouveau, ordre.removeAt(ancien));
                _modifier(r.copierAvec(ordreRayons: ordre));
              },
              proxyDecorator: (enfant, _, animation) => AnimatedBuilder(
                animation: animation,
                builder: (_, _) => Transform.scale(
                  scale: 1 + 0.03 * Curves.easeOut.transform(animation.value),
                  child: Material(
                    type: MaterialType.transparency,
                    child: ColoredBox(
                      color: RhythmCouleurs.fond,
                      child: enfant,
                    ),
                  ),
                ),
              ),
              children: [
                for (final (i, rayon) in r.ordreRayons.indexed)
                  ReorderableDelayedDragStartListener(
                    key: ValueKey(rayon),
                    index: i,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (i > 0) const Filet(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 28,
                                child: Text(
                                  '${i + 1}',
                                  style: RhythmTypo.texte(
                                    13,
                                    couleur: RhythmCouleurs.texte40,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  rayon.libelle(tr),
                                  style: RhythmTypo.texte(15),
                                ),
                              ),
                              const PictoRhythm(
                                Picto.liste,
                                taille: 18,
                                couleur: RhythmCouleurs.texte40,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LigneReglage(
              libelle: tr.rappelsPeremption,
              detail: tr.rappelsPeremptionDetail,
              droite: Interrupteur(
                valeur: r.rappelsPeremption,
                onChanged: (v) {
                  _modifier(r.copierAvec(rappelsPeremption: v));
                  if (v) assurerAutorisation(ref);
                },
              ),
            ),
            if (r.rappelsPeremption) ...[
              const SizedBox(height: 8),
              RouletteHeure(
                minutes: r.heureRappel,
                onChanged: (m) => _modifier(r.copierAvec(heureRappel: m)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
