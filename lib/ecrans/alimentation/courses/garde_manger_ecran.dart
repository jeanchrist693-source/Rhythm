// lib/ecrans/alimentation/courses/garde_manger_ecran.dart
//
// LE GARDE-MANGER : combien d'aliments, combien à consommer bientôt, ce qui
// a été jeté ce mois-ci ; filtré par emplacement (frigo, congélateur,
// armoire, comptoir, et les lieux ajoutés — « Mes emplacements ») ; trié par DATE (le plus urgent d'abord) ou par
// RAYON. Chaque ligne dit où, combien, ouvert ou non, et son échéance en
// couleur. « + Ajouter » range un aliment à la main.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_courses.dart';
import '../../../l10n/libelles_recettes.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/etat_sante.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../../../widgets/filets.dart';
import '../../sports/pieces_sports.dart';
import 'article_garde_manger_ecran.dart';
import 'lieux_ecran.dart';
import 'pieces_courses.dart';

enum _Tri { date, rayon }

class GardeMangerEcran extends ConsumerStatefulWidget {
  const GardeMangerEcran({super.key, required this.retour});

  final String retour;

  @override
  ConsumerState<GardeMangerEcran> createState() => _GardeMangerEcranState();
}

class _GardeMangerEcranState extends ConsumerState<GardeMangerEcran> {
  /// `null` : tout ; un [Emplacement] ; ou l'id d'un lieu ajouté.
  Object? _ou;
  _Tri _tri = _Tri.date;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(coursesProvider);
    final auj = ref.watch(aujourdhuiProvider);
    final tous = etat.gardeManger;
    final bientot = aConsommerBientot(tous, auj);
    final jete = gaspillageDuMois(etat.sorties, auj);
    final reglages = etat.reglages;
    // Un lieu retiré entre-temps : le filtre s'efface.
    final ou = _ou is String && reglages.lieu(_ou as String) == null
        ? null
        : _ou;
    bool dedans(ArticleGardeManger a) => switch (ou) {
      null => true,
      final Emplacement e =>
        a.emplacement == e && reglages.lieu(a.lieuId) == null,
      _ => a.lieuId == ou,
    };
    final visibles = [
      for (final a in tous)
        if (dedans(a)) a,
    ];
    final titre = tr.gardeManger;

    Widget ligne(ArticleGardeManger a, bool filet) => LigneCourse(
      filet: filet,
      nom: a.nom,
      detail: [
        ouEstRange(a, reglages, tr),
        if (a.quantite != null)
          a.restes
              ? f.portions(a.quantite!.valeur, tr)
              : f.quantite(a.quantite!, tr),
        if (a.ouvertLe != null) tr.ouvert,
        if (a.essentiel) tr.essentielCourt,
      ].join(' · '),
      valeurWidget: Echeance(jours: joursRestants(a, auj)),
      onTap: () => pousserEcran(
        context,
        ArticleGardeMangerEcran(id: a.id, retour: titre),
      ),
    );

    final List<Widget> liste;
    if (_tri == _Tri.date) {
      final tries = [...visibles]
        ..sort((a, b) {
          final pa = a.peremption, pb = b.peremption;
          if (pa == null && pb == null) return a.nom.compareTo(b.nom);
          if (pa == null) return 1;
          if (pb == null) return -1;
          return pa.compareTo(pb);
        });
      liste = [
        if (tries.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final (i, a) in tries.indexed) ligne(a, i > 0)],
          ),
      ];
    } else {
      liste = [
        for (final r in etat.reglages.ordreRayons)
          if (visibles.any((a) => a.rayon == r))
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TitreSection(r.libelle(tr)),
                for (final (i, a) in [
                  for (final x in visibles)
                    if (x.rayon == r) x,
                ].indexed)
                  ligne(a, i > 0),
              ],
            ),
      ];
    }

    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(titre: titre),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tous.isEmpty
                  ? tr.gardeMangerVide
                  : [
                      tr.alimentsNombre(tous.length),
                      if (bientot.isNotEmpty)
                        tr.aConsommerBientotNombre(bientot.length),
                    ].join(' · '),
              style: RhythmTypo.texte(15, poids: 500),
            ),
            if (jete.nombre > 0) ...[
              const SizedBox(height: 4),
              Text(
                tr.jeteCeMois(f.prix(jete.valeur), jete.nombre),
                style: RhythmTypo.detail,
              ),
            ],
          ],
        ),
        BoutonCapsule(
          picto: Picto.plus,
          libelle: tr.ajouterAuGardeManger,
          plein: true,
          onTap: () =>
              pousserEcran(context, ArticleGardeMangerEcran(retour: titre)),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PucesChoix<Object?>(
              options: [
                (null, tr.tout),
                for (final e in Emplacement.values) (e, e.libelle(tr)),
                for (final l in reglages.lieux) (l.id, l.nom),
              ],
              valeur: ou,
              onChanged: (e) => setState(() => _ou = e),
            ),
            const SizedBox(height: 10),
            PucesChoix<_Tri>(
              options: [(_Tri.date, tr.parDate), (_Tri.rayon, tr.parRayon)],
              valeur: _tri,
              onChanged: (t) => setState(() => _tri = t),
            ),
          ],
        ),
        if (visibles.isEmpty && tous.isNotEmpty)
          Text(tr.rienIci, style: RhythmTypo.detail),
        ...liste,
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Filet(),
            LigneReglage(
              gauche: const PictoCercle(
                Picto.frigo,
                couleur: RhythmCouleurs.peche,
              ),
              libelle: tr.mesEmplacements,
              detail: reglages.lieux.isEmpty
                  ? tr.mesEmplacementsDetail
                  : [for (final l in reglages.lieux) l.nom].join(', '),
              onTap: () => pousserEcran(context, LieuxEcran(retour: titre)),
            ),
          ],
        ),
        if (tous.isNotEmpty)
          Text(
            tr.gardeMangerAide,
            style: RhythmTypo.texte(12, couleur: RhythmCouleurs.texte40),
          ),
      ],
    );
  }
}
