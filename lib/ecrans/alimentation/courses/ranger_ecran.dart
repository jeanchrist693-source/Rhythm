// lib/ecrans/alimentation/courses/ranger_ecran.dart
//
// RANGER, en rentrant de l'épicerie : chaque aliment du panier arrive avec
// OÙ le mettre (le guide de conservation : frigo, congélateur, armoire,
// comptoir), JUSQU'À QUAND (la durée la plus prudente, à corriger d'après
// l'emballage) et COMMENT le garder (« bananes : sur le comptoir, loin des
// autres fruits… »). Changer l'emplacement recalcule la date. « Ne pas
// ranger » l'écarte ; ce qui n'est pas alimentaire (entretien, hygiène)
// n'y va pas. « Tout ranger » : au garde-manger, puis retour à la liste.
// Un aliment HORS DU GUIDE : « Comment le garder ? » le demande à l'IA
// (palier 4) — où, jusqu'à quand et comment suivent sa réponse.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/conservation.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/taxes.dart';
import '../../../modele/etat_sante.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../utils/dates.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pression_echelle.dart';
import '../../../widgets/toast.dart';
import '../../../l10n/libelles_courses.dart';
import '../ia/conservation_ia.dart';
import 'pieces_courses.dart';

class RangerEcran extends ConsumerStatefulWidget {
  const RangerEcran({super.key, required this.achat, required this.retour});

  final Achat achat;
  final String retour;

  @override
  ConsumerState<RangerEcran> createState() => _RangerEcranState();
}

class _RangerEcranState extends ConsumerState<RangerEcran> {
  late final List<ArticleGardeManger> _propositions;
  final Set<String> _ecartes = {};
  late final List<String> _nonAlimentaires;

  @override
  void initState() {
    super.initState();
    final notifier = ref.read(coursesProvider.notifier);
    final a = widget.achat;
    final bareme = baremeAu(a.date);
    final apprises = ref.read(coursesProvider).conservations;
    _propositions = [
      for (final l in a.lignes)
        ?rangementPropose(
          l,
          id: notifier.nouvelId('gm'),
          date: jourDe(a.date),
          bareme: bareme,
          magasin: a.magasin,
          apprises: apprises,
        ),
    ];
    _nonAlimentaires = [
      for (final l in a.lignes)
        if (!l.rayon.alimentaire) l.nom,
    ];
  }

  void _remplacer(int i, ArticleGardeManger a) =>
      setState(() => _propositions[i] = a);

  void _toutRanger() {
    final tr = context.tr;
    final aRanger = [
      for (final a in _propositions)
        if (!_ecartes.contains(a.id)) a,
    ];
    ref.read(coursesProvider.notifier).ranger(aRanger);
    HapticFeedback.heavyImpact();
    montrerToast(context, tr.alimentsRanges(aRanger.length));
    retirerEcran(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final auj = ref.watch(aujourdhuiProvider);
    final apprises = ref.watch(coursesProvider).conservations;
    final a = widget.achat;
    final nombre = _propositions.length - _ecartes.length;
    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(
          titre: tr.ranger,
          surtitre: Text(
            [?a.magasin, tr.totalPaye(f.prix(a.caisse.total))].join(' · '),
            style: RhythmTypo.texte(
              14,
              poids: 600,
              couleur: RhythmCouleurs.menthe,
            ),
          ),
        ),
        Text(tr.rangerExplication, style: RhythmTypo.detail),
        for (final (i, p) in _propositions.indexed)
          _Proposition(
            article: p,
            ecarte: _ecartes.contains(p.id),
            aujourdhui: auj,
            apprises: apprises,
            onChanged: (x) => _remplacer(i, x),
            onEcarter: () => setState(() {
              _ecartes.contains(p.id)
                  ? _ecartes.remove(p.id)
                  : _ecartes.add(p.id);
            }),
          ),
        if (_nonAlimentaires.isNotEmpty)
          Text(
            tr.pasAuGardeManger(_nonAlimentaires.join(', ')),
            style: RhythmTypo.detail,
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoutonPlein(
              libelle: nombre == 0 ? tr.terminer : tr.toutRanger(nombre),
              largeurPleine: true,
              hauteur: 52,
              taillePolice: 15,
              onTap: _toutRanger,
            ),
            const SizedBox(height: 10),
            Text(
              tr.rangerPlusTard,
              textAlign: TextAlign.center,
              style: RhythmTypo.petit,
            ),
          ],
        ),
      ],
    );
  }
}

class _Proposition extends StatelessWidget {
  const _Proposition({
    required this.article,
    required this.ecarte,
    required this.aujourdhui,
    required this.apprises,
    required this.onChanged,
    required this.onEcarter,
  });

  final ArticleGardeManger article;
  final bool ecarte;
  final DateTime aujourdhui;

  /// Les repères de conservation appris de l'IA.
  final Map<String, Conservation> apprises;
  final ValueChanged<ArticleGardeManger> onChanged;
  final VoidCallback onEcarter;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final a = article;
    final g = conservationDe(a.nom, a.rayon, apprises: apprises);
    final duree = g.dureeA(a.emplacement);
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: ecarte ? 0.4 : 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Filet(),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(a.nom, style: RhythmTypo.texte(17, poids: 600)),
              ),
              Semantics(
                button: true,
                child: PressionEchelle(
                  onTap: onEcarter,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Text(
                      ecarte ? tr.ranger : tr.nePasRanger,
                      style: RhythmTypo.texte(
                        13,
                        poids: 600,
                        couleur: RhythmCouleurs.texte64,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (!ecarte) ...[
            const SizedBox(height: 6),
            Text(
              g.conseil,
              style: RhythmTypo.texte(13, couleur: RhythmCouleurs.peche),
            ),
            if (repereDeLIa(a.nom, apprises)) ...[
              const SizedBox(height: 4),
              Text(tr.iaRepereDeLIa, style: RhythmTypo.petit),
            ] else if (horsDuGuide(a.nom, apprises)) ...[
              const SizedBox(height: 10),
              DemandeConservation(
                nom: a.nom,
                rayon: a.rayon,
                onAppris: (c) => onChanged(
                  a.copierAvec(
                    emplacement: c.ideal,
                    peremption: () =>
                        peremptionProposee(c, c.ideal, jourDe(aujourdhui)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            ChoixEmplacement(
              valeur: a.emplacement,
              onChanged: (e) => onChanged(
                a.copierAvec(
                  emplacement: e,
                  peremption: () =>
                      peremptionProposee(g, e, jourDe(aujourdhui)),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              duree == null
                  ? tr.pasDeRepere
                  : tr.seGarde(f.dureeGuide(duree, tr)),
              style: RhythmTypo.petit,
            ),
            const SizedBox(height: 4),
            ChoixDate(
              aujourdhui: aujourdhui,
              date: a.peremption,
              onChanged: (d) => onChanged(a.copierAvec(peremption: () => d)),
            ),
            LigneReglage(
              libelle: tr.essentiel,
              detail: tr.essentielDetail,
              droite: Interrupteur(
                valeur: a.essentiel,
                onChanged: (v) => onChanged(a.copierAvec(essentiel: v)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
