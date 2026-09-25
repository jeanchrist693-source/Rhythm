// lib/ecrans/sports/constructeur_ecran.dart
//
// Le CONSTRUCTEUR de séance, « pas totalement manuel » :
// 1. LES ZONES — on touche les muscles sur la silhouette (face, dos) ; les
//    muscles en récupération sont hachurés et évités ;
// 2. l'OBJECTIF (force, volume, endurance : le dosage) et, en option,
//    l'enchaînement des exercices opposés ;
// 3. LES EXERCICES — ceux qu'on choisit (propositions pour les zones, ou
//    toute la banque), et « Compléter » qui en ajoute d'équilibrés, sans IA ;
// puis l'APERÇU, où Rhythm organise tout (`apercu_ecran.dart`).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_sport.dart';
import '../../l10n/traductions.dart';
import '../../modele/etat_sante.dart';
import '../../modele/sports/calculs_sport.dart';
import '../../modele/sports/catalogue.dart';
import '../../modele/sports/etat_sport.dart';
import '../../modele/sports/muscles.dart';
import '../../modele/sports/sport.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/boutons.dart';
import '../../widgets/corps/silhouette.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/toast.dart';
import 'apercu_ecran.dart';
import 'banque_ecran.dart';
import 'exercice_ecran.dart';
import 'pieces_sports.dart';

class ConstructeurEcran extends ConsumerStatefulWidget {
  const ConstructeurEcran({
    super.key,
    required this.retour,
    this.depart = const [],
  });

  final String retour;

  /// Des exercices déjà choisis (« Ajouter à une séance » depuis une fiche).
  final List<String> depart;

  @override
  ConsumerState<ConstructeurEcran> createState() => _ConstructeurEcranState();
}

class _ConstructeurEcranState extends ConsumerState<ConstructeurEcran> {
  CoteSilhouette _cote = CoteSilhouette.face;
  final Set<Muscle> _zones = {};
  late final List<String> _choisis = [...widget.depart];
  late Objectif _objectif = ref.read(sportProvider).profil.objectif;
  late bool _enchainer = ref.read(sportProvider).profil.enchainements;

  void _basculerZone(Muscle m) {
    HapticFeedback.selectionClick();
    setState(() => _zones.contains(m) ? _zones.remove(m) : _zones.add(m));
  }

  void _basculerExercice(String id) {
    HapticFeedback.selectionClick();
    setState(
      () => _choisis.contains(id) ? _choisis.remove(id) : _choisis.add(id),
    );
  }

  Set<Muscle> get _recuperation => enRecuperation(
    ref.read(sportProvider).journal,
    ref.read(horlogeProvider)(),
  ).keys.toSet();

  void _completer() {
    final etat = ref.read(sportProvider);
    final avant = _choisis.length;
    final r = completer(
      zones: _zones,
      deja: _choisis,
      materiel: etat.profil.materiel,
      niveau: etat.profil.niveau,
      enRecuperation: _recuperation,
      cible: _choisis.length < 6 ? 6 : _choisis.length + 2,
    );
    HapticFeedback.mediumImpact();
    setState(() {
      _choisis
        ..clear()
        ..addAll(r);
    });
    if (r.length == avant) montrerToast(context, context.tr.aucunExercice);
  }

  Future<void> _banque() async {
    final r = await pousserEcran<List<String>>(
      context,
      BanqueEcran(
        retour: context.tr.nouvelleSeance,
        selection: _choisis,
        muscles: _zones,
      ),
    );
    if (r != null && mounted) {
      setState(() {
        _choisis
          ..clear()
          ..addAll(r);
      });
    }
  }

  void _apercu() {
    final tr = context.tr;
    if (_choisis.isEmpty) {
      montrerToast(context, tr.choisirUnExercice);
      return;
    }
    final etat = ref.read(sportProvider);
    final lignes = construireSeance(
      _choisis,
      objectif: _objectif,
      enchainer: _enchainer,
      journal: etat.journal,
    );
    pousserEcran(
      context,
      ApercuEcran(
        lignes: lignes,
        objectif: _objectif,
        retour: tr.nouvelleSeance,
        nomPropose: _nomPropose(tr),
      ),
    );
  }

  /// « Pectoraux, dos » ou « Tout le corps ».
  String _nomPropose(AppLocalizations tr) {
    if (_zones.isEmpty || _zones.length > 3) return tr.toutLeCorps;
    final z = _zones.toList()..sort((a, b) => a.index.compareTo(b.index));
    return z.map((m) => m.libelle(tr)).join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final etat = ref.watch(sportProvider);
    final recuperation = enRecuperation(
      etat.journal,
      ref.read(horlogeProvider)(),
    ).keys.toSet();
    final propositions = suggestions(
      zones: _zones,
      materiel: etat.profil.materiel,
      niveau: etat.profil.niveau,
      enRecuperation: recuperation,
      exclus: _choisis,
      n: 8,
    );
    final evites = recuperation.where(
      (m) => _zones.isEmpty || _zones.contains(m),
    );

    return PageSecondaire(
      retour: widget.retour,
      enfants: [
        TitreSecondaire(titre: tr.nouvelleSeance),
        // ── 1. Les zones ──────────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(
              tr.lesZones,
              droite: Segments2<CoteSilhouette>(
                options: [
                  (CoteSilhouette.face, tr.vueFace),
                  (CoteSilhouette.dos, tr.vueDos),
                ],
                valeur: _cote,
                onChanged: (c) => setState(() => _cote = c),
              ),
            ),
            Text(tr.zonesAide, style: RhythmTypo.detail),
            const SizedBox(height: 14),
            Center(
              child: SizedBox(
                height: 330,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: SilhouetteMuscles(
                    key: ValueKey(_cote),
                    cote: _cote,
                    couleurs: {
                      for (final m in _zones) m: RhythmCouleurs.corail,
                    },
                    hachures: recuperation,
                    onTap: _basculerZone,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (_zones.isEmpty)
                  Text(tr.toutLeCorps, style: RhythmTypo.texte(15, poids: 600))
                else ...[
                  for (final m in _zones)
                    Puce(
                      libelle: m.libelle(tr),
                      choisie: true,
                      couleur: RhythmCouleurs.corail,
                      onTap: () => _basculerZone(m),
                    ),
                  PressionEchelle(
                    onTap: () => setState(_zones.clear),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        tr.effacer,
                        style: RhythmTypo.texte(
                          14,
                          poids: 500,
                          couleur: RhythmCouleurs.texte64,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (evites.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                tr.evitesRecuperation(
                  evites.map((m) => m.libelle(tr).toLowerCase()).join(', '),
                ),
                style: RhythmTypo.petit,
              ),
            ],
          ],
        ),
        // ── 2. L'objectif ─────────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.objectif),
            PucesChoix<Objectif>(
              options: [for (final o in Objectif.values) (o, o.libelle(tr))],
              valeur: _objectif,
              onChanged: (o) => setState(() => _objectif = o),
            ),
            const SizedBox(height: 8),
            Text(_objectif.detail(tr), style: RhythmTypo.detail),
            const SizedBox(height: 10),
            LigneReglage(
              libelle: tr.enchainerOpposes,
              detail: tr.enchainerAide,
              droite: Interrupteur(
                valeur: _enchainer,
                onChanged: (v) => setState(() => _enchainer = v),
              ),
            ),
          ],
        ),
        // ── 3. Les exercices ──────────────────────────────────────────────
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(
              tr.lesExercices,
              droite: Text(
                tr.nChoisis(_choisis.length),
                style: RhythmTypo.texte(13, couleur: RhythmCouleurs.corail),
              ),
            ),
            Text(tr.exercicesAide, style: RhythmTypo.detail),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: BoutonCapsule(
                    picto: Picto.eclair,
                    libelle: tr.completer,
                    plein: true,
                    onTap: _completer,
                  ),
                ),
                const SizedBox(width: 10),
                BoutonCapsule(
                  picto: Picto.recherche,
                  libelle: tr.banqueExercices,
                  onTap: _banque,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(tr.completerAide, style: RhythmTypo.petit),
            const SizedBox(height: 8),
            for (final (i, id) in _choisis.indexed)
              if (Catalogue.de(id) case final e?)
                LigneExercice(
                  exercice: e,
                  filet: i > 0,
                  detail: detailExercice(e, tr),
                  onTap: () => pousserEcran(
                    context,
                    ExerciceEcran(id: e.id, retour: tr.nouvelleSeance),
                  ),
                  droite: _BoutonRetirer(onTap: () => _basculerExercice(id)),
                ),
          ],
        ),
        if (propositions.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(_zones.isEmpty ? tr.toutLeCorps : tr.pourCesZones),
              for (final (i, e) in propositions.indexed)
                LigneExercice(
                  exercice: e,
                  filet: i > 0,
                  detail: detailExercice(e, tr),
                  onTap: () => pousserEcran(
                    context,
                    ExerciceEcran(id: e.id, retour: tr.nouvelleSeance),
                  ),
                  droite: _BoutonAjouter(onTap: () => _basculerExercice(e.id)),
                ),
            ],
          ),
        BoutonPlein(
          libelle: tr.voirApercu,
          largeurPleine: true,
          hauteur: 52,
          taillePolice: 15,
          fleche: true,
          onTap: _apercu,
        ),
      ],
    );
  }
}

class _BoutonAjouter extends StatelessWidget {
  const _BoutonAjouter({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => BoutonRond(
    couleur: RhythmCouleurs.corail,
    libelle: context.tr.ajouter,
    onTap: onTap,
    child: const PictoRhythm(
      Picto.plus,
      taille: 20,
      epaisseur: 2.4,
      couleur: RhythmCouleurs.noir,
    ),
  );
}

class _BoutonRetirer extends StatelessWidget {
  const _BoutonRetirer({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: context.tr.retirer,
    child: PressionEchelle(
      onTap: onTap,
      echelle: 0.9,
      child: const SizedBox.square(
        dimension: 44,
        child: Center(
          child: PictoRhythm(
            Picto.croix,
            taille: 20,
            couleur: RhythmCouleurs.texte64,
          ),
        ),
      ),
    ),
  );
}
