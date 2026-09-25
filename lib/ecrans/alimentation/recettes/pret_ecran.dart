// lib/ecrans/alimentation/recettes/pret_ecran.dart
//
// « C'EST PRÊT » : ce qu'on en mange maintenant (au JOURNAL, au bon moment,
// sa valeur par portion) ; les RESTES — au frigo (3 jours) ou au
// congélateur (3 mois), ou pas de restes : ils entrent au garde-manger en
// portions ; le GARDE-MANGER décompté — pour chaque aliment utilisé, ce
// qu'il en restera (coché d'emblée quand on le sait ; sans quantité connue,
// « fini ? » se coche à la main). « Enregistrer » fait tout d'un coup.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_alimentation.dart';
import '../../../l10n/libelles_courses.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_alimentation.dart';
import '../../../modele/alimentation/calculs_recettes.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/etat_recettes.dart';
import '../../../modele/alimentation/recettes.dart';
import '../../../modele/etat_sante.dart';
import '../../../modele/modeles.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/toast.dart';
import '../courses/pieces_courses.dart';

class PretEcran extends ConsumerStatefulWidget {
  const PretEcran({
    super.key,
    required this.recette,
    required this.portions,
    required this.retour,
    this.moment,
  });

  final Recette recette;

  /// Les portions cuisinées.
  final int portions;
  final String retour;
  final MomentRepas? moment;

  @override
  ConsumerState<PretEcran> createState() => _PretEcranState();
}

class _PretEcranState extends ConsumerState<PretEcran> {
  /// Les portions mangées maintenant, en demis.
  int _demis = 2;
  late MomentRepas _moment;

  /// Où vont les restes ; `null` : pas de restes.
  Emplacement? _restesA = Emplacement.frigo;
  late final List<Decompte> _decomptes;
  late final Set<String> _choisis;

  @override
  void initState() {
    super.initState();
    final r = widget.recette;
    final facteur = widget.portions / r.portions;
    _moment = widget.moment ?? momentPourHeure(ref.read(horlogeProvider)());
    _demis = _demis.clamp(0, widget.portions * 2);
    _decomptes = decompteGardeManger([
      for (final i in r.ingredients) i.fois(facteur),
    ], ref.read(coursesProvider).gardeManger);
    _choisis = {
      for (final d in _decomptes)
        if (d.calcule) d.article.id,
    };
    if (r.seCongele && widget.portions >= 4) {
      // Un grand lot qui se congèle : le reste au congélateur.
      _restesA = Emplacement.congelateur;
    }
  }

  double get _mangees => _demis / 2;
  double get _restes => widget.portions - _mangees;

  void _enregistrer() {
    final tr = context.tr;
    final f = context.formats;
    final r = widget.recette;
    ref
        .read(recettesProvider.notifier)
        .cuisiner(
          recette: r,
          portions: widget.portions.toDouble(),
          mangees: _mangees,
          moment: _moment,
          restesA: _restesA,
          nomRestes: tr.nomRestes(r.nom),
          decomptes: [
            for (final d in _decomptes)
              if (_choisis.contains(d.article.id)) d,
          ],
        );
    HapticFeedback.heavyImpact();
    final parties = [
      if (_mangees > 0) tr.noteAuMoment(f.portions(_mangees, tr), _moment.name),
      if (_restesA != null && _restes > 0)
        tr.restesRanges(f.portions(_restes, tr), _restesA!.libelle(tr)),
    ];
    montrerToast(
      context,
      parties.isEmpty ? tr.bonAppetit : parties.join(' · '),
    );
    retirerEcran(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final r = widget.recette;
    final auj = ref.watch(aujourdhuiProvider);
    final jusquau = _restesA == null ? null : restesJusquau(auj, _restesA!);

    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(
          titre: tr.bonAppetit,
          surtitre: Text(
            tr.cuisinePortions(
              r.nom,
              f.portions(widget.portions.toDouble(), tr),
            ),
            style: RhythmTypo.surtitre,
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.jEnMangeMaintenant),
            LigneReglage(
              libelle: tr.portionsMangees,
              detail: _mangees <= 0
                  ? null
                  : tr.kcalEtProteines(
                      f.kcalDe(r.parPortion.kcal * _mangees, tr),
                      f.g(r.parPortion.proteines * _mangees, tr),
                    ),
              droite: CompteurRhythm(
                valeur: _demis,
                min: 0,
                max: widget.portions * 2,
                largeurValeur: 64,
                affichage: (d) => d == 0 ? tr.aucune : f.fraction(d / 2),
                onChanged: (d) => setState(() => _demis = d),
              ),
            ),
            if (_mangees > 0) ...[
              const SizedBox(height: 8),
              PucesChoix<MomentRepas>(
                options: [
                  for (final m in MomentRepas.values) (m, m.libelle(tr)),
                ],
                valeur: _moment,
                onChanged: (m) => setState(() => _moment = m),
              ),
            ],
          ],
        ),
        if (_restes > 0)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.lesRestes(f.portions(_restes, tr))),
              PucesChoix<Emplacement?>(
                options: [
                  (Emplacement.frigo, tr.auFrigo),
                  (Emplacement.congelateur, tr.auCongelateur),
                  (null, tr.pasDeRestes),
                ],
                valeur: _restesA,
                onChanged: (e) => setState(() => _restesA = e),
              ),
              if (jusquau != null) ...[
                const SizedBox(height: 10),
                Text(
                  tr.restesJusquau(f.dateCourte(jusquau)),
                  style: RhythmTypo.texte(13, couleur: RhythmCouleurs.menthe),
                ),
              ],
              const SizedBox(height: 6),
              Text(tr.restesConseil, style: RhythmTypo.petit),
            ],
          ),
        if (_decomptes.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.auGardeManger),
              Text(tr.auGardeMangerAide, style: RhythmTypo.petit),
              const SizedBox(height: 4),
              for (final (i, d) in _decomptes.indexed)
                LigneCourse(
                  filet: i > 0,
                  coche: _choisis.contains(d.article.id),
                  nom: d.article.nom,
                  detail: !d.calcule
                      ? tr.finiQuestion
                      : d.fini
                      ? tr.ilNEnResteraPlus
                      : tr.ilEnRestera(
                          FormatsCourses(f).quantite(d.reste!, tr),
                        ),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(
                      () => _choisis.contains(d.article.id)
                          ? _choisis.remove(d.article.id)
                          : _choisis.add(d.article.id),
                    );
                  },
                ),
            ],
          ),
        BoutonPlein(
          libelle: tr.enregistrer,
          largeurPleine: true,
          hauteur: 52,
          taillePolice: 15,
          onTap: _enregistrer,
        ),
      ],
    );
  }
}
