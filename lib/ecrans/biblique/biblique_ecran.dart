// lib/ecrans/biblique/biblique_ecran.dart
//
// Biblique (maquette « Biblique »), sans cartes (`filets.dart`) : la série
// de lecture en surtitre, le verset du jour (et « Partager »), le plan de
// lecture — un segment par chapitre,
// « Continuer » —, puis Prière | Méditation, séparées par un filet. Le
// lecteur lit, les yeux clos, en haut à droite.

import 'package:flutter/material.dart';

import '../../l10n/traductions.dart';
import '../../modele/graine.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/boutons.dart';
import '../../widgets/jauges.dart';
import '../../widgets/filets.dart';
import '../../widgets/mascottes.dart';
import '../../widgets/page_rhythm.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/toast.dart';

class BibliqueEcran extends StatelessWidget {
  const BibliqueEcran({super.key});

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    void bientot() => montrerToast(context, tr.bientot);
    const plan = Graine.plan;
    const verset = Graine.verset;

    return PageRhythm(
      blocs: [
        EnTete(
          surtitre: Row(
            children: [
              const PictoRhythm(
                Picto.flamme,
                taille: 16,
                couleur: RhythmCouleurs.corail,
                epaisseur: 2,
              ),
              const SizedBox(width: 6),
              Text(
                tr.jours(Graine.serieLecture),
                style: RhythmTypo.texte(
                  14,
                  poids: 600,
                  couleur: RhythmCouleurs.corail,
                ),
              ),
            ],
          ),
          titre: tr.navBiblique,
          mascotte: Mascotte.biblique,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tr.versetDuJour.toUpperCase(),
              style: RhythmTypo.texte(
                12,
                poids: 600,
                couleur: RhythmCouleurs.lavande,
                espacement: 0.08,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              '« ${verset.texte} »',
              style: RhythmTypo.titre(
                26,
                poids: 500,
                espacement: -0.015,
                hauteur: 1.28,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${verset.reference} · ${verset.traduction}',
                    style: RhythmTypo.detail,
                  ),
                ),
                const SizedBox(width: 12),
                BoutonContour(libelle: tr.partager, onTap: bientot),
              ],
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(tr.planDeLecture, style: RhythmTypo.petit),
                      const SizedBox(height: 2),
                      Text(plan.livre, style: RhythmTypo.texte(18, poids: 600)),
                    ],
                  ),
                ),
                Text(
                  '${plan.chapitre} / ${plan.total}',
                  style: RhythmTypo.texte(14, couleur: RhythmCouleurs.lavande),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Segments(
              total: plan.total,
              pleins: plan.chapitre,
              couleur: RhythmCouleurs.lavande,
              hauteur: 6,
              rayon: 3,
              ecart: 3,
            ),
            const SizedBox(height: 14),
            BoutonPlein(
              libelle: tr.continuer(plan.chapitreEnCours),
              onTap: bientot,
              hauteur: 50,
              taillePolice: 15,
              largeurPleine: true,
              fleche: true,
            ),
          ],
        ),
        RangeeFilets(
          cases: [
            _Outil(
              picto: Picto.cocheCercle,
              couleur: RhythmCouleurs.menthe,
              titre: tr.priere,
              detail: tr.journalSujets(Graine.sujetsPriere),
              onTap: bientot,
            ),
            _Outil(
              picto: Picto.livre,
              couleur: RhythmCouleurs.peche,
              titre: tr.meditation,
              detail: tr.notesSur(plan.chapitrePrecedent),
              onTap: bientot,
            ),
          ],
        ),
      ],
    );
  }
}

class _Outil extends StatelessWidget {
  const _Outil({
    required this.picto,
    required this.couleur,
    required this.titre,
    required this.detail,
    required this.onTap,
  });

  final Picto picto;
  final Color couleur;
  final String titre;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: PressionEchelle(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Pastille(picto: picto, couleur: couleur),
          const SizedBox(height: 18),
          Text(titre, style: RhythmTypo.texte(15, poids: 600)),
          const SizedBox(height: 2),
          Text(detail, style: RhythmTypo.petit),
        ],
      ),
    ),
  );
}
