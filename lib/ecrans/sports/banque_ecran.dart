// lib/ecrans/sports/banque_ecran.dart
//
// La BANQUE d'exercices, hors ligne : une recherche, des filtres (avec mon
// matériel — actif d'emblée —, sans matériel, le style, le muscle) et la
// liste, chaque exercice avec son corps en miniature. La première fois, la
// banque demande le matériel qu'on a (une seule fois).
//
// En mode SÉLECTION (le constructeur de séance), chaque ligne se coche et
// l'écran rend la sélection au retour.
//
// La liste est paresseuse (`SliverList`) : 254 corps ne se peignent pas
// d'un coup.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_sport.dart';
import '../../l10n/traductions.dart';
import '../../modele/sports/catalogue.dart';
import '../../modele/sports/etat_sport.dart';
import '../../modele/sports/exercices.dart';
import '../../modele/sports/muscles.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_mesures.dart';
import '../../theme/rhythm_theme.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/boutons.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_rhythm.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import 'exercice_ecran.dart';
import 'pieces_sports.dart';

/// Minuscules, sans accents (la recherche).
String _simple(String s) {
  const avec = 'àâäéèêëîïôöùûüçœ';
  const sans = 'aaaeeeeiioouuuco';
  var t = s.toLowerCase();
  for (var i = 0; i < avec.length; i++) {
    t = t.replaceAll(avec[i], sans[i]);
  }
  return t;
}

class BanqueEcran extends ConsumerStatefulWidget {
  const BanqueEcran({
    super.key,
    required this.retour,
    this.selection,
    this.muscles = const {},
  });

  final String retour;

  /// Mode sélection : les exercices déjà choisis (l'écran rend la nouvelle
  /// sélection au retour).
  final List<String>? selection;

  /// Filtre de départ (les zones du constructeur).
  final Set<Muscle> muscles;

  @override
  ConsumerState<BanqueEcran> createState() => _BanqueEcranState();
}

class _BanqueEcranState extends ConsumerState<BanqueEcran> {
  final _recherche = TextEditingController();
  bool _avecMonMateriel = true;
  bool _sansMateriel = false;
  StyleSport? _style;
  Muscle? _muscle;
  late final List<String> _choisis = [...?widget.selection];
  Set<Materiel>? _declaration;

  bool get _enSelection => widget.selection != null;

  @override
  void initState() {
    super.initState();
    if (widget.muscles.length == 1) _muscle = widget.muscles.first;
    _recherche.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  List<ExerciceSport> _resultats(Set<Materiel> materiel) {
    final q = _simple(_recherche.text.trim());
    final tr = context.tr;
    return [
      for (final e in Catalogue.tous)
        if ((!_avecMonMateriel || e.faisableAvec(materiel)) &&
            (!_sansMateriel || e.sansMateriel) &&
            (_style == null || e.style == _style) &&
            (_muscle == null
                ? (widget.muscles.length < 2 ||
                      e.principaux.any(widget.muscles.contains))
                : e.principaux.contains(_muscle) ||
                      e.secondaires.contains(_muscle)) &&
            (q.isEmpty ||
                _simple(e.nom).contains(q) ||
                e.muscles.any((m) => _simple(m.libelle(tr)).contains(q))))
          e,
    ];
  }

  void _basculer(String id) {
    HapticFeedback.selectionClick();
    setState(
      () => _choisis.contains(id) ? _choisis.remove(id) : _choisis.add(id),
    );
  }

  void _fermer() {
    if (_enSelection) {
      Navigator.of(context).pop(_choisis);
    } else {
      retirerEcran(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final profil = ref.watch(sportProvider.select((s) => s.profil));
    final resultats = _resultats(profil.materiel);
    final haut = MediaQuery.viewPaddingOf(context).top;
    final bas = MediaQuery.viewPaddingOf(context).bottom;

    Widget centre(Widget enfant) => SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: RhythmEspaces.largeurMaxContenu,
          ),
          child: enfant,
        ),
      ),
    );

    return PopScope(
      canPop: !_enSelection,
      onPopInvokedWithResult: (sorti, _) {
        if (!sorti) Navigator.of(context).pop(_choisis);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: RhythmTheme.barresSysteme,
        child: Scaffold(
          backgroundColor: RhythmCouleurs.fond,
          resizeToAvoidBottomInset: false,
          body: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                      parent: AlwaysScrollableScrollPhysics(),
                    ),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          RhythmEspaces.marge,
                          haut + 12,
                          RhythmEspaces.marge,
                          0,
                        ),
                        sliver: centre(
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              BarreRetour(
                                libelle: widget.retour,
                                onRetour: _fermer,
                              ),
                              const SizedBox(height: 14),
                              TitreSecondaire(titre: tr.banqueExercices),
                              if (!profil.materielDeclare && !_enSelection) ...[
                                const SizedBox(height: 22),
                                _Declaration(
                                  valeurs: _declaration ?? profil.materiel,
                                  onChanged: (v) =>
                                      setState(() => _declaration = v),
                                  onConfirmer: () => ref
                                      .read(sportProvider.notifier)
                                      .modifierProfil(
                                        profil.copierAvec(
                                          materiel:
                                              _declaration ?? profil.materiel,
                                          materielDeclare: true,
                                        ),
                                      ),
                                ),
                              ],
                              const SizedBox(height: 18),
                              ChampRhythm(
                                controleur: _recherche,
                                indice: tr.rechercherExercice,
                                actionClavier: TextInputAction.search,
                              ),
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Puce(
                                    libelle: tr.avecMonMateriel,
                                    choisie: _avecMonMateriel,
                                    couleur: RhythmCouleurs.corail,
                                    onTap: () => setState(
                                      () =>
                                          _avecMonMateriel = !_avecMonMateriel,
                                    ),
                                  ),
                                  Puce(
                                    libelle: tr.sansMateriel,
                                    choisie: _sansMateriel,
                                    couleur: RhythmCouleurs.corail,
                                    onTap: () => setState(
                                      () => _sansMateriel = !_sansMateriel,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _Defilant(
                          enfants: [
                            Puce(
                              libelle: tr.tousLesStyles,
                              choisie: _style == null,
                              onTap: () => setState(() => _style = null),
                            ),
                            for (final s in StyleSport.values)
                              Puce(
                                libelle: s.libelle(tr),
                                choisie: _style == s,
                                onTap: () => setState(
                                  () => _style = _style == s ? null : s,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _Defilant(
                          enfants: [
                            Puce(
                              libelle: tr.tousLesMuscles,
                              choisie: _muscle == null,
                              onTap: () => setState(() => _muscle = null),
                            ),
                            for (final m in Muscle.values)
                              Puce(
                                libelle: m.libelle(tr),
                                choisie: _muscle == m,
                                onTap: () => setState(
                                  () => _muscle = _muscle == m ? null : m,
                                ),
                              ),
                          ],
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: RhythmEspaces.marge,
                        ),
                        sliver: centre(
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Text(
                              _enSelection
                                  ? '${tr.nExercices(resultats.length)} · '
                                        '${tr.nChoisis(_choisis.length)}'
                                  : tr.nExercices(resultats.length),
                              style: RhythmTypo.detail,
                            ),
                          ),
                        ),
                      ),
                      if (resultats.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.all(RhythmEspaces.marge),
                          sliver: centre(
                            Text(tr.aucunExercice, style: RhythmTypo.detail),
                          ),
                        ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          RhythmEspaces.marge,
                          0,
                          RhythmEspaces.marge,
                          bas + (_enSelection ? 110 : 40),
                        ),
                        sliver: SliverList.builder(
                          itemCount: resultats.length,
                          itemBuilder: (context, i) {
                            final e = resultats[i];
                            final choisi = _choisis.contains(e.id);
                            return Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: RhythmEspaces.largeurMaxContenu,
                                ),
                                child: LigneExercice(
                                  exercice: e,
                                  filet: i > 0,
                                  detail: detailExercice(e, tr),
                                  droite: _enSelection
                                      ? _Coche(
                                          choisie: choisi,
                                          onTap: () => _basculer(e.id),
                                        )
                                      : PointsNiveau(e.niveau),
                                  onTap: () => _enSelection
                                      ? _basculer(e.id)
                                      : pousserEcran(
                                          context,
                                          ExerciceEcran(
                                            id: e.id,
                                            retour: tr.banqueExercices,
                                          ),
                                        ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: VoileBarreEtat(),
              ),
              if (_enSelection)
                Positioned(
                  left: RhythmEspaces.marge,
                  right: RhythmEspaces.marge,
                  bottom: bas + 20,
                  child: BoutonPlein(
                    libelle:
                        '${tr.confirmer} · ${tr.nChoisis(_choisis.length)}',
                    largeurPleine: true,
                    hauteur: 52,
                    taillePolice: 15,
                    onTap: _fermer,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Une rangée de capsules qui défile de côté, aux marges de l'écran.
class _Defilant extends StatelessWidget {
  const _Defilant({required this.enfants});

  final List<Widget> enfants;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(
        RhythmEspaces.marge,
        8,
        RhythmEspaces.marge,
        6,
      ),
      itemCount: enfants.length,
      separatorBuilder: (_, _) => const SizedBox(width: 8),
      itemBuilder: (_, i) => Center(child: enfants[i]),
    ),
  );
}

/// Le cercle d'une ligne en mode sélection.
class _Coche extends StatelessWidget {
  const _Coche({required this.choisie, required this.onTap});

  final bool choisie;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    checked: choisie,
    child: GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: choisie ? RhythmCouleurs.corail : null,
            border: choisie
                ? null
                : Border.all(color: RhythmCouleurs.cocheVide, width: 1.5),
          ),
          child: choisie
              ? const PictoRhythm(
                  Picto.coche,
                  taille: 16,
                  epaisseur: 2.6,
                  couleur: RhythmCouleurs.noir,
                )
              : null,
        ),
      ),
    ),
  );
}

/// « Quel matériel as-tu ? » — une fois.
class _Declaration extends StatelessWidget {
  const _Declaration({
    required this.valeurs,
    required this.onChanged,
    required this.onConfirmer,
  });

  final Set<Materiel> valeurs;
  final ValueChanged<Set<Materiel>> onChanged;
  final VoidCallback onConfirmer;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tr.quelMateriel, style: RhythmTypo.texte(17, poids: 600)),
        const SizedBox(height: 4),
        Text(tr.quelMaterielAide, style: RhythmTypo.detail),
        const SizedBox(height: 14),
        PucesMultiples<Materiel>(
          options: [for (final m in Materiel.values) (m, m.libelle(tr))],
          valeurs: valeurs,
          onChanged: onChanged,
        ),
        const SizedBox(height: 14),
        BoutonPlein(libelle: tr.confirmer, onTap: onConfirmer),
      ],
    );
  }
}
