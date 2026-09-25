// lib/ecrans/alimentation/courses/achats_ecran.dart
//
// L'HISTORIQUE DES ÉPICERIES, mois par mois (le total du mois face au
// budget) ; toucher une épicerie la détaille : chaque ligne (prix, taxe,
// consigne) et la caisse (sous-total, TPS, TVQ, consigne, total) — les
// montants payés ce jour-là. « Supprimer cette épicerie » en deux temps.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/libelles_courses.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import 'pieces_courses.dart';

class AchatsEcran extends ConsumerWidget {
  const AchatsEcran({super.key, required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(coursesProvider);
    final budget = etat.reglages.budgetMois;
    final langue = Localizations.localeOf(context).languageCode;
    // Les mois, du plus récent au plus ancien.
    final mois = <DateTime, List<Achat>>{};
    for (final a in etat.achats.reversed) {
      mois.putIfAbsent(DateTime(a.date.year, a.date.month), () => []).add(a);
    }
    final titre = tr.historiqueEpiceries;
    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(titre: titre),
        if (mois.isEmpty) Text(tr.aucuneEpicerieAide, style: RhythmTypo.detail),
        for (final e in mois.entries)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(
                DateFormat(
                  'MMMM y',
                  langue == 'fr' ? 'fr_CA' : 'en_CA',
                ).format(e.key),
                droite: Text(
                  budget == null
                      ? f.prix(_total(e.value))
                      : tr.surBudget(f.prix(_total(e.value)), f.prix(budget)),
                  style: RhythmTypo.texte(
                    13,
                    poids: 600,
                    couleur: budget != null && _total(e.value) > budget
                        ? RhythmCouleurs.corail
                        : RhythmCouleurs.texte64,
                  ),
                ),
              ),
              for (final (i, a) in e.value.indexed)
                LigneCourse(
                  filet: i > 0,
                  nom:
                      '${f.dateCourte(a.date)} · '
                      '${a.magasin ?? tr.magasinInconnu}',
                  detail: tr.epicerieDetail(
                    a.lignes.length,
                    f.prix(a.caisse.taxes),
                  ),
                  valeur: f.prix(a.caisse.total),
                  onTap: () => pousserEcran(
                    context,
                    AchatEcran(id: a.id, retour: titre),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  static double _total(List<Achat> achats) =>
      achats.fold(0.0, (s, a) => s + a.caisse.total);
}

class AchatEcran extends ConsumerWidget {
  const AchatEcran({super.key, required this.id, required this.retour});

  final String id;
  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final f = context.formats;
    final a = ref
        .watch(coursesProvider)
        .achats
        .where((x) => x.id == id)
        .firstOrNull;
    if (a == null) return PageSecondaire(retour: retour, enfants: const []);
    final c = a.caisse;
    Widget montant(String libelle, double v, {bool gras = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              libelle,
              style: RhythmTypo.texte(
                gras ? 16 : 14,
                poids: gras ? 600 : 400,
                couleur: gras ? RhythmCouleurs.texte : RhythmCouleurs.texte72,
              ),
            ),
          ),
          Text(
            f.prix(v),
            style: RhythmTypo.texte(gras ? 16 : 14, poids: gras ? 600 : 400),
          ),
        ],
      ),
    );
    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(
          titre: a.magasin ?? tr.epicerie,
          surtitre: Text(f.dateHeure(a.date), style: RhythmTypo.surtitre),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            montant(tr.sousTotal, c.sousTotal),
            montant('TPS', c.tps),
            montant('TVQ', c.tvq),
            if (c.consigne > 0) montant(tr.consigne, c.consigne),
            const Filet(couleur: RhythmCouleurs.filetGrille),
            montant(tr.total, c.total, gras: true),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.articlesNombre(a.lignes.length)),
            for (final (i, l) in a.lignes.indexed)
              LigneCourse(
                filet: i > 0,
                nom: l.nom,
                detail: [
                  if (l.panier.auPoids)
                    tr.poidsAPrix(
                      '${f.decimal(l.panier.nombre)} '
                          '${l.panier.livres ? 'lb' : 'kg'}',
                      '${f.prix(l.panier.prixUnitaire)} / '
                          '${l.panier.livres ? 'lb' : 'kg'}',
                    )
                  else if (l.panier.nombre != 1)
                    '${f.decimal(l.panier.nombre)} × '
                        '${f.prix(l.panier.prixUnitaire)}',
                  l.panier.statut.libelle(tr),
                  if (l.panier.consigne > 0)
                    tr.consigneValeur(f.prix(l.panier.consigne)),
                ].join(' · '),
                valeur: f.prix(l.panier.prix),
              ),
          ],
        ),
        BoutonSuppression(
          libelle: tr.supprimerEpicerie,
          confirmation: tr.toucherPourSupprimer,
          onConfirme: () {
            ref.read(coursesProvider.notifier).supprimerAchat(a.id);
            retirerEcran(context);
          },
        ),
      ],
    );
  }
}
