// lib/ecrans/alimentation/courses/lieux_ecran.dart
//
// MES EMPLACEMENTS (lot 5) : le frigo, le congélateur, l'armoire et le
// comptoir sont déjà là ; on AJOUTE les siens — un deuxième congélateur,
// une cave, le frigo du garage. Chacun suit les règles de conservation de
// son genre (« se garde comme un congélateur »). La liste, puis un
// emplacement : son nom (quelques propositions d'un toucher), son genre ;
// le retirer en deux temps (ce qui y est rangé retourne dans son genre).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_courses.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../../../widgets/suivi_clavier.dart';
import '../../../widgets/toast.dart';
import 'pieces_courses.dart';

class LieuxEcran extends ConsumerWidget {
  const LieuxEcran({super.key, required this.retour});

  final String retour;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = context.tr;
    final etat = ref.watch(coursesProvider);
    final lieux = etat.reglages.lieux;
    final titre = tr.mesEmplacements;
    return PageSecondaire(
      retour: retour,
      enfants: [
        TitreSecondaire(titre: titre),
        Text(tr.mesEmplacementsAide, style: RhythmTypo.texte(15)),
        BoutonCapsule(
          picto: Picto.plus,
          libelle: tr.ajouterUnEmplacement,
          plein: true,
          onTap: () => pousserEcran(context, LieuEcran(retour: titre)),
        ),
        if (lieux.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, l) in lieux.indexed) ...[
                if (i > 0) const Filet(),
                LigneReglage(
                  libelle: l.nom,
                  detail: [
                    tr.seGardeComme(l.genre.libelle(tr).toLowerCase()),
                    tr.alimentsNombre(
                      etat.gardeManger.where((a) => a.lieuId == l.id).length,
                    ),
                  ].join(' · '),
                  onTap: () =>
                      pousserEcran(context, LieuEcran(lieu: l, retour: titre)),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

/// Des noms proposés, avec leur genre.
const List<(String, Emplacement)> kLieuxProposes = [
  ('Congélateur du sous-sol', Emplacement.congelateur),
  ('Deuxième frigo', Emplacement.frigo),
  ('Frigo du garage', Emplacement.frigo),
  ('Cave', Emplacement.armoire),
  ('Garde-manger', Emplacement.armoire),
  ('Panier à fruits', Emplacement.comptoir),
];

class LieuEcran extends ConsumerStatefulWidget {
  const LieuEcran({super.key, required this.retour, this.lieu});

  final String retour;

  /// Le lieu à modifier ; `null` : un nouveau.
  final Lieu? lieu;

  @override
  ConsumerState<LieuEcran> createState() => _LieuEcranState();
}

class _LieuEcranState extends ConsumerState<LieuEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<LieuEcran> {
  late final _nom = TextEditingController(text: widget.lieu?.nom);
  final _focus = FocusNode();
  late Emplacement _genre = widget.lieu?.genre ?? Emplacement.congelateur;

  bool get _edition => widget.lieu != null;

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focus);
  }

  @override
  void dispose() {
    libererClavier();
    _nom.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _enregistrer() {
    if (transitionEnCours) return;
    final tr = context.tr;
    final nom = _nom.text.trim();
    if (nom.isEmpty) {
      montrerToast(context, tr.nomRequis);
      return;
    }
    final notifier = ref.read(coursesProvider.notifier);
    notifier.enregistrerLieu(
      Lieu(
        id: widget.lieu?.id ?? notifier.nouvelId('lieu'),
        nom: nom[0].toUpperCase() + nom.substring(1),
        genre: _genre,
      ),
    );
    HapticFeedback.lightImpact();
    montrerToast(context, tr.emplacementEnregistre(nom));
    retirerEcran(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final existants = {
      for (final l in ref.watch(coursesProvider).reglages.lieux)
        l.nom.toLowerCase(),
    };
    final propositions = [
      for (final p in kLieuxProposes)
        if (!existants.contains(p.$1.toLowerCase())) p,
    ];
    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: _edition ? tr.modifierEmplacement : tr.nouvelEmplacement,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.champNom),
            ChampRhythm(
              controleur: _nom,
              focus: _focus,
              indice: tr.indiceEmplacement,
              actionClavier: TextInputAction.done,
            ),
            if (!_edition && propositions.isNotEmpty) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (nom, genre) in propositions)
                    Puce(
                      libelle: nom,
                      choisie: _nom.text == nom,
                      couleur: RhythmCouleurs.peche,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _nom.text = nom;
                          _genre = genre;
                        });
                      },
                    ),
                ],
              ),
            ],
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.seGardeCommeTitre),
            ChoixEmplacement(
              valeur: _genre,
              onChanged: (e) => setState(() => _genre = e),
            ),
            const SizedBox(height: 10),
            Text(
              tr.seGardeCommeDetail(_genre.libelle(tr).toLowerCase()),
              style: RhythmTypo.petit,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoutonPlein(
              libelle: tr.enregistrer,
              largeurPleine: true,
              hauteur: 52,
              taillePolice: 15,
              onTap: _enregistrer,
            ),
            if (_edition) ...[
              const SizedBox(height: 12),
              BoutonSuppression(
                libelle: tr.retirerEmplacement,
                confirmation: tr.toucherEncorePourRetirer,
                onConfirme: () {
                  final l = widget.lieu!;
                  ref.read(coursesProvider.notifier).supprimerLieu(l.id);
                  montrerToast(
                    context,
                    tr.emplacementRetire(l.nom, l.genre.libelle(tr)),
                  );
                  retirerEcran(context);
                },
              ),
              const SizedBox(height: 10),
              Text(
                tr.retirerEmplacementDetail(widget.lieu!.genre.libelle(tr)),
                style: RhythmTypo.petit,
              ),
            ],
          ],
        ),
      ],
    );
  }
}
