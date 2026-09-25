// lib/ecrans/habitudes/habitude_formulaire_ecran.dart
//
// Créer ou modifier une habitude (écran secondaire, sans cartes : des champs
// soulignés d'un filet, des capsules, des disques — `formulaire.dart`).
//
// À la création, on choisit d'abord le GENRE : « À construire » (une
// habitude à prendre) ou « Me libérer » (une dépendance à laisser). Puis le
// nom, la précision, la couleur (un domaine) et la lettre ; les jours
// prévus ; le rappel (heure sans clavier) — activer le premier rappel
// demande l'autorisation d'Android ; enfin la MOTIVATION : le pourquoi, le
// plan si-alors, la version minimale des jours difficiles. Pour une
// libération : depuis quand, ce que ça coûtait par jour (les économies),
// les alternatives et les déclencheurs connus (capsules, suggestions
// comprises).
//
// Modifier : mêmes champs (le genre et le point de départ ne changent
// plus) ; supprimer en deux temps, en bas.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/traductions.dart';
import '../../modele/etat_habitudes.dart';
import '../../modele/etat_sante.dart';
import '../../modele/habitudes.dart';
import '../../modele/modeles.dart';
import '../../navigation/transitions.dart';
import '../../systeme/synchro.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/boutons.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/suivi_clavier.dart';
import '../../widgets/toast.dart';

class HabitudeFormulaireEcran extends ConsumerStatefulWidget {
  const HabitudeFormulaireEcran({
    super.key,
    this.id,
    this.genre = GenreHabitude.construire,
  });

  /// L'habitude à modifier ; `null` = une nouvelle.
  final String? id;

  /// Le genre choisi d'avance pour une nouvelle (« Me libérer » depuis
  /// l'accueil).
  final GenreHabitude genre;

  @override
  ConsumerState<HabitudeFormulaireEcran> createState() =>
      _HabitudeFormulaireEcranState();
}

class _HabitudeFormulaireEcranState
    extends ConsumerState<HabitudeFormulaireEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<HabitudeFormulaireEcran> {
  Habitude? _origine;
  GenreHabitude _genre = GenreHabitude.construire;
  Teinte _teinte = Teinte.menthe;
  Set<int> _jours = {1, 2, 3, 4, 5, 6, 7};
  bool _rappelActif = false;
  int _rappel = 8 * 60;
  int _depuisJours = 0;
  List<String> _alternatives = [];
  List<String> _declencheurs = [];

  final _nom = TextEditingController();
  final _lettre = TextEditingController();
  final _detail = TextEditingController();
  final _pourquoi = TextEditingController();
  final _plan = TextEditingController();
  final _minimale = TextEditingController();
  final _cout = TextEditingController();
  final _nouvelleAlternative = TextEditingController();
  final _nouveauDeclencheur = TextEditingController();
  final _focus = List.generate(9, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    for (final f in _focus) {
      surveillerClavier(f);
    }
    final h = widget.id == null
        ? null
        : ref.read(habitudesProvider).parId(widget.id!);
    _origine = h;
    _genre = widget.genre;
    if (h != null) {
      _genre = h.genre;
      _teinte = h.teinte;
      _jours = h.jours.isEmpty ? {1, 2, 3, 4, 5, 6, 7} : {...h.jours};
      _rappelActif = h.rappel != null;
      _rappel = h.rappel ?? _rappel;
      _alternatives = [...h.alternatives];
      _declencheurs = [...h.declencheurs];
      _nom.text = h.nom;
      _lettre.text = h.initiale;
      _detail.text = h.detail;
      _pourquoi.text = h.pourquoi;
      _plan.text = h.plan;
      _minimale.text = h.versionMinimale;
    }
  }

  bool _coutPose = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Le coût s'écrit dans la langue de l'app (« 4,5 ») : les formats ne
    // sont pas lisibles dans `initState`.
    final cout = _origine?.coutParJour;
    if (!_coutPose && cout != null) {
      _cout.text = context.formats.decimal(cout);
    }
    _coutPose = true;
  }

  @override
  void dispose() {
    libererClavier();
    for (final c in [
      _nom,
      _lettre,
      _detail,
      _pourquoi,
      _plan,
      _minimale,
      _cout,
      _nouvelleAlternative,
      _nouveauDeclencheur,
    ]) {
      c.dispose();
    }
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  bool get _liberer => _genre == GenreHabitude.liberer;

  /// Enregistré : un second toucher (pendant la transition) ne crée pas
  /// l'habitude une deuxième fois.
  bool _fini = false;

  void _enregistrer() {
    if (_fini) return;
    final tr = context.tr;
    final nom = _nom.text.trim();
    if (nom.isEmpty) {
      montrerToast(context, tr.nomRequis);
      _focus[0].requestFocus();
      return;
    }
    final notif = ref.read(habitudesProvider.notifier);
    final auj = jourDe(ref.read(aujourdhuiProvider));
    final maintenant = ref.read(horlogeProvider)();
    final cout = double.tryParse(
      _cout.text.replaceAll(',', '.').replaceAll(RegExp(r'[^0-9.]'), ''),
    );
    final origine = _origine;
    final base =
        origine ??
        Habitude(
          id: notif.nouvelId(),
          nom: nom,
          creeLe: auj,
          genre: _genre,
          depuis: _liberer
              ? (_depuisJours == 0
                    ? maintenant
                    : plusJoursInstant(maintenant, -_depuisJours))
              : null,
        );
    final h = base.copierAvec(
      nom: nom,
      teinte: _teinte,
      initiale: _lettre.text.trim(),
      detail: _detail.text.trim(),
      jours: _liberer || _jours.length == 7 ? <int>{} : _jours,
      rappel: () => _rappelActif ? _rappel : null,
      pourquoi: _pourquoi.text.trim(),
      plan: _plan.text.trim(),
      versionMinimale: _liberer ? '' : _minimale.text.trim(),
      coutParJour: () => _liberer && cout != null && cout > 0 ? cout : null,
      alternatives: _liberer ? _alternatives : const [],
      declencheurs: _liberer ? _declencheurs : const [],
    );
    _fini = true;
    origine == null ? notif.ajouter(h) : notif.modifier(h);
    if (_rappelActif && origine?.rappel == null) assurerAutorisation(ref);
    HapticFeedback.lightImpact();
    retirerEcran(context);
  }

  void _supprimer() {
    final origine = _origine;
    if (origine == null || _fini) return;
    _fini = true;
    ref.read(habitudesProvider.notifier).supprimer(origine.id);
    Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  }

  void _ajouterA(List<String> liste, TextEditingController c) {
    final texte = c.text.trim();
    if (texte.isEmpty) return;
    setState(() {
      if (!liste.contains(texte)) liste.add(texte);
      c.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final nouvelle = _origine == null;
    final autorisation = ref.watch(autorisationNotifsProvider);

    final champs = <Widget>[
      TitreSecondaire(
        titre: nouvelle ? tr.nouvelleHabitude : tr.modifierHabitude,
      ),
      if (nouvelle)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PucesChoix<GenreHabitude>(
              options: [
                (GenreHabitude.construire, tr.aConstruire),
                (GenreHabitude.liberer, tr.aLiberer),
              ],
              valeur: _genre,
              onChanged: (g) => setState(() => _genre = g),
            ),
            const SizedBox(height: 10),
            Text(
              _liberer ? tr.aLibererAide : tr.aConstruireAide,
              style: RhythmTypo.detail,
            ),
          ],
        ),
      _Champ(
        etiquette: tr.champNom,
        child: ChampRhythm(
          key: const ValueKey('champ0'),
          controleur: _nom,
          focus: _focus[0],
          indice: _liberer ? tr.indiceNomLiberer : tr.indiceNomConstruire,
          actionClavier: TextInputAction.next,
          onChanged: (_) => setState(() {}),
        ),
      ),
      _Champ(
        etiquette: tr.champDetail,
        child: ChampRhythm(
          key: const ValueKey('champ1'),
          controleur: _detail,
          focus: _focus[1],
          indice: tr.indiceDetail,
          actionClavier: TextInputAction.done,
        ),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _Champ(
              etiquette: tr.champCouleur,
              child: _Teintes(
                valeur: _teinte,
                lettre: _lettre.text.trim().isNotEmpty
                    ? _lettre.text.trim()
                    : (_nom.text.trim().isEmpty
                          ? '?'
                          : String.fromCharCode(
                              _nom.text.trim().runes.first,
                            ).toUpperCase()),
                onChanged: (t) => setState(() => _teinte = t),
              ),
            ),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 64,
            child: _Champ(
              etiquette: tr.champLettre,
              child: ChampRhythm(
                key: const ValueKey('champ2'),
                controleur: _lettre,
                focus: _focus[2],
                majuscules: TextCapitalization.characters,
                formateurs: [LengthLimitingTextInputFormatter(2)],
                onChanged: (_) => setState(() {}),
                actionClavier: TextInputAction.done,
              ),
            ),
          ),
        ],
      ),
      if (!_liberer)
        _Champ(
          etiquette: tr.champJours,
          droite: Text(f.joursPrevus(_jours, tr), style: RhythmTypo.petit),
          child: SelecteurJours(
            libelles: [for (var j = 1; j <= 7; j++) f.jourCourt(j)],
            jours: _jours,
            onChanged: (j) {
              // Au moins un jour : décocher le dernier ne fait rien.
              if (j.isNotEmpty) setState(() => _jours = j);
            },
          ),
        ),
      _Champ(
        etiquette: tr.champRappel,
        droite: Interrupteur(
          valeur: _rappelActif,
          onChanged: (v) {
            setState(() => _rappelActif = v);
            // L'autorisation d'Android au moment où l'on active le rappel
            // (pas à l'enregistrement : on comprend pourquoi on la donne).
            if (v) assurerAutorisation(ref);
          },
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_liberer)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(tr.rappelDiscret, style: RhythmTypo.detail),
              ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _rappelActif
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RouletteHeure(
                          minutes: _rappel,
                          separateur: tr.separateurHeure,
                          onChanged: (m) => setState(() => _rappel = m),
                        ),
                        if (autorisation == false)
                          _AlerteNotifs(
                            onActiver: () => ref
                                .read(autorisationNotifsProvider.notifier)
                                .demander(reglagesSiRefus: true),
                          ),
                      ],
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ),
      ),
      _Champ(
        etiquette: tr.champPourquoi,
        child: ChampRhythm(
          key: const ValueKey('champ3'),
          controleur: _pourquoi,
          focus: _focus[3],
          indice: tr.indicePourquoi,
          lignes: 4,
        ),
      ),
      _Champ(
        etiquette: tr.monPlan,
        aide: tr.aidePlan,
        child: ChampRhythm(
          key: const ValueKey('champ4'),
          controleur: _plan,
          focus: _focus[4],
          indice: tr.indicePlan,
          lignes: 3,
        ),
      ),
      if (!_liberer)
        _Champ(
          etiquette: tr.versionMinimale,
          aide: tr.versionMinimaleAide,
          child: ChampRhythm(
            key: const ValueKey('champ5'),
            controleur: _minimale,
            focus: _focus[5],
            indice: tr.indiceVersionMinimale,
            actionClavier: TextInputAction.done,
          ),
        ),
      if (_liberer && nouvelle)
        _Champ(
          etiquette: tr.champLibreDepuis,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tr.ilYaJours(_depuisJours),
                  style: RhythmTypo.titre(22, poids: 500),
                ),
              ),
              CompteurRhythm(
                valeur: _depuisJours,
                min: 0,
                max: 3650,
                largeurValeur: 8,
                affichage: (_) => '',
                onChanged: (v) => setState(() => _depuisJours = v),
              ),
            ],
          ),
        ),
      if (_liberer)
        _Champ(
          etiquette: tr.champCout,
          aide: tr.aideCout,
          child: ChampRhythm(
            key: const ValueKey('champ6'),
            controleur: _cout,
            focus: _focus[6],
            indice: '0',
            suffixe: r'$',
            clavier: const TextInputType.numberWithOptions(decimal: true),
            formateurs: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
            actionClavier: TextInputAction.done,
          ),
        ),
      if (_liberer)
        _Champ(
          etiquette: tr.mesAlternatives,
          child: _Liste(
            valeurs: _alternatives,
            suggestions: [
              tr.altEau,
              tr.altMarcher,
              tr.altAppeler,
              tr.altPrier,
              tr.altRespirer,
              tr.altDouche,
            ],
            onChanged: (l) => setState(() => _alternatives = l),
            champ: ChampRhythm(
              key: const ValueKey('champ7'),
              controleur: _nouvelleAlternative,
              focus: _focus[7],
              indice: tr.indiceAlternative,
              actionClavier: TextInputAction.done,
              onValider: (_) => _ajouterA(_alternatives, _nouvelleAlternative),
            ),
          ),
        ),
      if (_liberer)
        _Champ(
          etiquette: tr.mesDeclencheurs,
          child: _Liste(
            valeurs: _declencheurs,
            suggestions: [
              tr.declStress,
              tr.declEnnui,
              tr.declFatigue,
              tr.declSolitude,
              tr.declColere,
              tr.declSoiree,
              tr.declEcrans,
            ],
            onChanged: (l) => setState(() => _declencheurs = l),
            champ: ChampRhythm(
              key: const ValueKey('champ8'),
              controleur: _nouveauDeclencheur,
              focus: _focus[8],
              indice: tr.indiceDeclencheur,
              actionClavier: TextInputAction.done,
              onValider: (_) => _ajouterA(_declencheurs, _nouveauDeclencheur),
            ),
          ),
        ),
      BoutonPlein(
        libelle: tr.enregistrer,
        largeurPleine: true,
        hauteur: 52,
        taillePolice: 16,
        onTap: _enregistrer,
      ),
      if (!nouvelle)
        BoutonSuppression(
          libelle: tr.supprimerHabitude,
          confirmation: tr.toucherPourSupprimer,
          onConfirme: _supprimer,
        ),
    ];

    return PageSecondaire(
      retour: nouvelle ? tr.navHabitudes : tr.annuler,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: champs,
    );
  }
}

/// Les notifications sont coupées : ce rappel ne sonnera pas — et le
/// chemin pour les activer.
class _AlerteNotifs extends StatelessWidget {
  const _AlerteNotifs({required this.onActiver});

  final VoidCallback onActiver;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              tr.notifsBloqueesRappel,
              style: RhythmTypo.texte(13, couleur: RhythmCouleurs.corail),
            ),
          ),
          const SizedBox(width: 12),
          BoutonPlein(
            libelle: tr.activer,
            hauteur: 36,
            taillePolice: 13,
            onTap: onActiver,
          ),
        ],
      ),
    );
  }
}

/// Un champ : son étiquette (et ce qu'on met à sa droite), le champ, une
/// aide.
class _Champ extends StatelessWidget {
  const _Champ({
    required this.etiquette,
    required this.child,
    this.aide,
    this.droite,
  });

  final String etiquette;
  final Widget child;
  final String? aide;
  final Widget? droite;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      EtiquetteChamp(etiquette, droite: droite),
      child,
      if (aide != null) ...[
        const SizedBox(height: 8),
        Text(aide!, style: RhythmTypo.petit),
      ],
    ],
  );
}

/// Les cinq teintes de Rhythm, en disques ; la choisie porte la lettre.
class _Teintes extends StatelessWidget {
  const _Teintes({
    required this.valeur,
    required this.lettre,
    required this.onChanged,
  });

  final Teinte valeur;
  final String lettre;
  final ValueChanged<Teinte> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 10,
    runSpacing: 10,
    children: [
      for (final t in Teinte.values)
        Semantics(
          button: true,
          selected: t == valeur,
          child: PressionEchelle(
            echelle: 0.9,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(t);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 40,
              height: 40,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: t == valeur
                      ? RhythmCouleurs.blanc
                      : const Color(0x00FFFFFF),
                  width: 2,
                ),
              ),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: t.couleur,
                  shape: BoxShape.circle,
                ),
                child: t == valeur
                    ? Text(
                        lettre,
                        style: RhythmTypo.texte(
                          13,
                          poids: 600,
                          couleur: RhythmCouleurs.noir,
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
    ],
  );
}

/// Une liste de mots (alternatives, déclencheurs) : des capsules à cocher —
/// les siens et des suggestions —, et un champ pour en ajouter.
class _Liste extends StatelessWidget {
  const _Liste({
    required this.valeurs,
    required this.suggestions,
    required this.onChanged,
    required this.champ,
  });

  final List<String> valeurs;
  final List<String> suggestions;
  final ValueChanged<List<String>> onChanged;
  final Widget champ;

  @override
  Widget build(BuildContext context) {
    final toutes = [
      ...valeurs,
      for (final s in suggestions)
        if (!valeurs.contains(s)) s,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final v in toutes)
              Puce(
                libelle: v,
                choisie: valeurs.contains(v),
                couleur: RhythmCouleurs.menthe,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(
                    valeurs.contains(v)
                        ? [
                            for (final x in valeurs)
                              if (x != v) x,
                          ]
                        : [...valeurs, v],
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 14),
        champ,
      ],
    );
  }
}
