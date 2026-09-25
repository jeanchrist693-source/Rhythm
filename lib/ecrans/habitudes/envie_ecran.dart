// lib/ecrans/habitudes/envie_ecran.dart
//
// « J'ai une envie » : le SOUTIEN d'une libération, quand l'envie monte.
// Tout est là, dans l'ordre où on en a besoin :
// - l'envie est une VAGUE (« urge surfing ») : elle monte, culmine et
//   redescend, souvent en moins de quinze minutes ;
// - RESPIRER : un disque qui s'ouvre et se referme, cinq secondes pour
//   inspirer, cinq pour expirer ; « Attendre 10 minutes » en fait le tour
//   d'un anneau ;
// - TES RAISONS (le pourquoi, dans ses propres mots), ce qu'on peut faire À
//   LA PLACE, un verset de force ;
// - APPELER : ses personnes de confiance (Rappels), Info-Social 811, le
//   9-8-8 ; le 911 en cas de danger immédiat ;
// - NOTER l'envie (intensité, déclencheur), puis « J'ai tenu » — une fête
//   sobre, le compte des envies surmontées — ou « J'ai rechuté » : jamais un
//   reproche. Ce qu'on a tenu reste acquis, un verset pour se relever, le
//   déclencheur noté ; le compteur ne repart de zéro qu'en deux temps, et
//   l'écran se termine sur « Recommencer maintenant ».
//
// Discret : ni le titre ni l'écran ne nomment ce dont on se libère.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/traductions.dart';
import '../../modele/calculs_habitudes.dart';
import '../../modele/etat_habitudes.dart';
import '../../modele/etat_sante.dart';
import '../../modele/habitudes.dart';
import '../../modele/modeles.dart';
import '../../modele/versets_encouragement.dart';
import '../../navigation/transitions.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/boutons.dart';
import '../../widgets/filets.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/jauges.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import 'pieces_habitudes.dart';

enum _Phase { soutien, bravo, rechute, recommence }

class EnvieEcran extends ConsumerStatefulWidget {
  const EnvieEcran({super.key, required this.id, this.rechute = false});

  final String id;

  /// Ouvert par « J'ai rechuté » : directement le chemin du retour.
  final bool rechute;

  @override
  ConsumerState<EnvieEcran> createState() => _EnvieEcranState();
}

class _EnvieEcranState extends ConsumerState<EnvieEcran> {
  late _Phase _phase = widget.rechute ? _Phase.rechute : _Phase.soutien;
  int _intensite = 5;
  String? _declencheur;

  /// Fin de l'attente de dix minutes ; `null` = pas lancée.
  DateTime? _finAttente;

  DateTime get _maintenant => ref.read(horlogeProvider)();

  void _noter({required bool tenue}) {
    ref
        .read(habitudesProvider.notifier)
        .noterEnvie(
          widget.id,
          Envie(
            quand: _maintenant,
            intensite: _intensite,
            declencheur: _declencheur,
            tenue: tenue,
          ),
        );
  }

  void _aller(_Phase phase) {
    setState(() => _phase = phase);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final h = ref.watch(habitudesProvider.select((e) => e.parId(widget.id)));
    if (h == null) return const SizedBox.shrink();
    final auj = ref.watch(aujourdhuiProvider);
    final enfants = switch (_phase) {
      _Phase.soutien => _soutien(context, h, auj),
      _Phase.bravo => _bravo(context, h, auj),
      _Phase.rechute => _rechute(context, h, auj),
      _Phase.recommence => _recommence(context, h, auj),
    };
    return PageSecondaire(
      retour: tr.navHabitudes,
      enfants: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (enfant, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: enfant,
            ),
          ),
          layoutBuilder: (actuel, precedents) => Stack(
            alignment: Alignment.topCenter,
            children: [...precedents, ?actuel],
          ),
          child: Column(
            key: ValueKey(_phase),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < enfants.length; i++) ...[
                if (i > 0) const SizedBox(height: 28),
                enfants[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Le soutien ────────────────────────────────────────────────────────────

  List<Widget> _soutien(BuildContext context, Habitude h, DateTime auj) {
    final tr = context.tr;
    final alternatives = h.alternatives.isNotEmpty
        ? h.alternatives
        : [
            tr.altEau,
            tr.altMarcher,
            tr.altAppeler,
            tr.altPrier,
            tr.altRespirer,
          ];
    return [
      TitreSecondaire(
        surtitre: Text(
          tr.envieSurtitre,
          style: RhythmTypo.texte(
            14,
            poids: 600,
            couleur: RhythmCouleurs.menthe,
          ),
        ),
        titre: tr.tiensBon,
      ),
      Text(
        tr.vagueTexte,
        style: RhythmTypo.texte(
          17,
          hauteur: 1.45,
          couleur: RhythmCouleurs.texte72,
        ),
      ),
      _Respiration(
        finAttente: _finAttente,
        onAttendre: () {
          HapticFeedback.selectionClick();
          setState(
            () => _finAttente = _maintenant.add(const Duration(minutes: 10)),
          );
        },
      ),
      if (h.pourquoi.isNotEmpty)
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.tesRaisons),
            Text(
              h.pourquoi,
              style: RhythmTypo.titre(
                21,
                poids: 500,
                espacement: -0.01,
                hauteur: 1.3,
              ),
            ),
          ],
        ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitreSection(tr.essaiePlutot),
          for (var i = 0; i < alternatives.length; i++) ...[
            if (i > 0) const Filet(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(alternatives[i], style: RhythmTypo.ligne),
            ),
          ],
        ],
      ),
      _VersetSoutien(verset: VersetsEncouragement.du(Soutien.force, auj)),
      _Appeler(contacts: ref.watch(habitudesProvider).reglages.contacts),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitreSection(tr.noterEnvie),
          EtiquetteChamp(
            tr.intensite,
            droite: Text('$_intensite/10', style: RhythmTypo.petit),
          ),
          _Intensite(
            valeur: _intensite,
            onChanged: (v) => setState(() => _intensite = v),
          ),
          const SizedBox(height: 22),
          EtiquetteChamp(tr.declencheur),
          _Declencheurs(
            habitude: h,
            valeur: _declencheur,
            onChanged: (d) => setState(() => _declencheur = d),
          ),
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          BoutonPlein(
            libelle: tr.jaiTenu,
            largeurPleine: true,
            hauteur: 52,
            taillePolice: 16,
            onTap: () {
              if (_phase != _Phase.soutien) return;
              HapticFeedback.heavyImpact();
              _noter(tenue: true);
              _aller(_Phase.bravo);
            },
          ),
          const SizedBox(height: 12),
          Center(
            child: BoutonContour(
              libelle: tr.jaiRechute,
              onTap: () {
                if (_phase != _Phase.soutien) return;
                HapticFeedback.selectionClick();
                _aller(_Phase.rechute);
              },
            ),
          ),
        ],
      ),
    ];
  }

  // ── Tenu ──────────────────────────────────────────────────────────────────

  List<Widget> _bravo(BuildContext context, Habitude h, DateTime auj) {
    final tr = context.tr;
    final f = context.formats;
    return [
      TitreSecondaire(
        surtitre: Horloge(
          constructeur: (_, maintenant) => Text(
            tr.libreDepuisDuree(f.duree(dureeLiberte(h, maintenant))),
            style: RhythmTypo.texte(
              14,
              poids: 600,
              couleur: RhythmCouleurs.menthe,
            ),
          ),
        ),
        titre: tr.bravo,
      ),
      Text(
        tr.bravoTexte,
        style: RhythmTypo.titre(
          22,
          poids: 500,
          espacement: -0.01,
          hauteur: 1.3,
        ),
      ),
      Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: RhythmCouleurs.menthe,
              shape: BoxShape.circle,
            ),
            child: const PictoRhythm(
              Picto.coche,
              taille: 24,
              couleur: RhythmCouleurs.noir,
              epaisseur: 2.6,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              tr.enviesSurmonteesTotal(enviesSurmontees(h)),
              style: RhythmTypo.texte(17, poids: 600),
            ),
          ),
        ],
      ),
      _VersetSoutien(verset: VersetsEncouragement.du(Soutien.liberte, auj)),
      BoutonPlein(
        libelle: tr.terminer,
        largeurPleine: true,
        hauteur: 52,
        taillePolice: 16,
        onTap: () => retirerEcran(context),
      ),
    ];
  }

  // ── Rechuté ───────────────────────────────────────────────────────────────

  List<Widget> _rechute(BuildContext context, Habitude h, DateTime auj) {
    final tr = context.tr;
    final f = context.formats;
    final tenu = dureeLiberte(h, _maintenant);
    return [
      TitreSecondaire(titre: tr.rechuteTitre),
      Text(
        tr.rechuteTexte(f.dureePhrase(tenu, tr)),
        style: RhythmTypo.titre(
          21,
          poids: 500,
          espacement: -0.01,
          hauteur: 1.3,
        ),
      ),
      _VersetSoutien(verset: VersetsEncouragement.du(Soutien.relever, auj)),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitreSection(tr.rechuteQuestion),
          _Declencheurs(
            habitude: h,
            valeur: _declencheur,
            onChanged: (d) => setState(() => _declencheur = d),
          ),
        ],
      ),
      BoutonSuppression(
        libelle: tr.remettreAZero,
        confirmation: tr.toucherPourConfirmer,
        couleur: RhythmCouleurs.blanc,
        onConfirme: () {
          if (_phase != _Phase.rechute) return;
          _noter(tenue: false);
          _aller(_Phase.recommence);
        },
      ),
    ];
  }

  List<Widget> _recommence(BuildContext context, Habitude h, DateTime auj) {
    final tr = context.tr;
    final f = context.formats;
    return [
      TitreSecondaire(
        surtitre: Horloge(
          periode: const Duration(seconds: 1),
          constructeur: (_, maintenant) => Text(
            tr.libreDepuisDuree(f.duree(dureeLiberte(h, maintenant))),
            style: RhythmTypo.texte(
              14,
              poids: 600,
              couleur: RhythmCouleurs.menthe,
            ),
          ),
        ),
        titre: tr.recommencer,
      ),
      _VersetSoutien(verset: VersetsEncouragement.du(Soutien.relever, auj, 3)),
      BoutonPlein(
        libelle: tr.terminer,
        largeurPleine: true,
        hauteur: 52,
        taillePolice: 16,
        onTap: () => retirerEcran(context),
      ),
    ];
  }
}

/// La respiration : un disque qui s'ouvre (inspirer, 5 s) et se referme
/// (expirer, 5 s) ; autour, l'anneau de l'attente de dix minutes.
class _Respiration extends ConsumerStatefulWidget {
  const _Respiration({required this.finAttente, required this.onAttendre});

  final DateTime? finAttente;
  final VoidCallback onAttendre;

  @override
  ConsumerState<_Respiration> createState() => _RespirationState();
}

class _RespirationState extends ConsumerState<_Respiration>
    with SingleTickerProviderStateMixin {
  static const Duration _cycle = Duration(seconds: 10);

  late final AnimationController _souffle = AnimationController(
    vsync: this,
    duration: _cycle,
  );

  /// Animations réduites : le disque reste immobile, mais la consigne
  /// alterne quand même toutes les cinq secondes (un texte qui change n'est
  /// pas un mouvement).
  Timer? _consigne;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _souffle.stop();
      _souffle.value = 0.25;
      _consigne ??= Timer.periodic(
        const Duration(seconds: 5),
        (_) => _souffle.value = _souffle.value < 0.5 ? 0.75 : 0.25,
      );
    } else if (!_souffle.isAnimating) {
      _consigne?.cancel();
      _consigne = null;
      _souffle.repeat();
    }
  }

  @override
  void dispose() {
    _consigne?.cancel();
    _souffle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    const cote = 220.0;
    return Column(
      children: [
        SizedBox.square(
          dimension: cote,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // L'attente : un anneau qui se remplit en dix minutes.
              Horloge(
                periode: const Duration(seconds: 1),
                constructeur: (_, maintenant) {
                  final reste = widget.finAttente?.difference(maintenant);
                  final p = reste == null
                      ? 0.0
                      : 1 - reste.inMilliseconds / (10 * 60 * 1000);
                  return Anneau(
                    taille: cote,
                    rayon: cote / 2 - 3,
                    epaisseur: 3,
                    progression: p.clamp(0.0, 1.0),
                    couleur: RhythmCouleurs.menthe,
                  );
                },
              ),
              AnimatedBuilder(
                animation: _souffle,
                builder: (_, _) {
                  final t = _souffle.value;
                  // 0 → 0,5 : inspirer (le disque s'ouvre) ; 0,5 → 1 :
                  // expirer. Sinusoïde : ni à-coup ni temps mort. Immobile
                  // (animations réduites) : à mi-ouverture.
                  final ouverture = _consigne != null
                      ? 0.5
                      : 0.5 - 0.5 * math.cos(2 * math.pi * t);
                  final echelle = 0.42 + 0.5 * ouverture;
                  return Container(
                    width: cote * echelle,
                    height: cote * echelle,
                    decoration: const BoxDecoration(
                      color: RhythmCouleurs.ciel,
                      shape: BoxShape.circle,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AnimatedBuilder(
          animation: _souffle,
          builder: (_, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              _souffle.value < 0.5 ? tr.inspire : tr.expire,
              key: ValueKey(_souffle.value < 0.5),
              style: RhythmTypo.titre(26, poids: 500),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          tr.respirationAide,
          textAlign: TextAlign.center,
          style: RhythmTypo.detail,
        ),
        const SizedBox(height: 18),
        Horloge(
          periode: const Duration(seconds: 1),
          constructeur: (_, maintenant) {
            final fin = widget.finAttente;
            if (fin == null) {
              return BoutonContour(
                libelle: tr.attendreDixMinutes,
                onTap: widget.onAttendre,
              );
            }
            final reste = fin.difference(maintenant);
            return Text(
              reste.isNegative
                  ? tr.minuteurFini
                  : tr.minuteurReste(f.minuteur(reste)),
              textAlign: TextAlign.center,
              style: RhythmTypo.texte(
                16,
                poids: 600,
                couleur: RhythmCouleurs.menthe,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Un verset d'encouragement : le texte (Bricolage), la référence.
class _VersetSoutien extends StatelessWidget {
  const _VersetSoutien({required this.verset});

  final Verset verset;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        '« ${verset.texte} »',
        style: RhythmTypo.titre(
          19,
          poids: 500,
          espacement: -0.01,
          hauteur: 1.35,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        '${verset.reference} · ${verset.traduction}',
        style: RhythmTypo.detail,
      ),
    ],
  );
}

/// Appeler : ses personnes de confiance, puis les lignes d'aide.
class _Appeler extends StatelessWidget {
  const _Appeler({required this.contacts});

  final List<Contact> contacts;

  static Future<void> _composer(String numero) async {
    HapticFeedback.selectionClick();
    try {
      await launchUrl(Uri(scheme: 'tel', path: numero));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final lignes = [
      for (final c in contacts)
        _LigneAppel(
          nom: c.nom,
          detail: c.telephone,
          couleur: RhythmCouleurs.menthe,
          onTap: () => _composer(c.telephone),
        ),
      _LigneAppel(
        nom: tr.infoSocial,
        detail: tr.infoSocialDetail,
        couleur: RhythmCouleurs.ciel,
        onTap: () => _composer('811'),
      ),
      _LigneAppel(
        nom: tr.ligne988,
        detail: tr.ligne988Detail,
        couleur: RhythmCouleurs.lavande,
        onTap: () => _composer('988'),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TitreSection(tr.appelerQuelquun),
        for (var i = 0; i < lignes.length; i++) ...[
          if (i > 0) const Filet(),
          lignes[i],
        ],
        const SizedBox(height: 12),
        if (contacts.isEmpty) ...[
          Text(tr.ajouterPersonneConfiance, style: RhythmTypo.petit),
          const SizedBox(height: 6),
        ],
        Text(
          tr.urgence911,
          style: RhythmTypo.texte(
            13,
            poids: 600,
            couleur: RhythmCouleurs.corail,
          ),
        ),
      ],
    );
  }
}

class _LigneAppel extends StatelessWidget {
  const _LigneAppel({
    required this.nom,
    required this.detail,
    required this.couleur,
    required this.onTap,
  });

  final String nom;
  final String detail;
  final Color couleur;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: PressionEchelle(
      onTap: onTap,
      echelle: 0.98,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
              child: const PictoRhythm(
                Picto.telephone,
                taille: 17,
                couleur: RhythmCouleurs.noir,
                epaisseur: 2,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nom, style: RhythmTypo.texte(15, poids: 600)),
                  const SizedBox(height: 2),
                  Text(detail, style: RhythmTypo.petit),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// L'intensité, de 1 à 10 : dix capsules qui se remplissent — menthe
/// (légère), pêche, puis corail (forte).
class _Intensite extends StatelessWidget {
  const _Intensite({required this.valeur, required this.onChanged});

  final int valeur;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final couleur = valeur <= 3
        ? RhythmCouleurs.menthe
        : valeur <= 7
        ? RhythmCouleurs.peche
        : RhythmCouleurs.corail;
    return Row(
      children: [
        for (var i = 1; i <= 10; i++) ...[
          if (i > 1) const SizedBox(width: 4),
          Expanded(
            child: Semantics(
              button: true,
              selected: i == valeur,
              label: '$i',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged(i);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    height: 22,
                    decoration: BoxDecoration(
                      color: i <= valeur ? couleur : RhythmCouleurs.piste,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Le déclencheur : ceux de l'habitude, sinon des suggestions.
class _Declencheurs extends StatelessWidget {
  const _Declencheurs({
    required this.habitude,
    required this.valeur,
    required this.onChanged,
  });

  final Habitude habitude;
  final String? valeur;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final options = habitude.declencheurs.isNotEmpty
        ? habitude.declencheurs
        : [
            tr.declStress,
            tr.declEnnui,
            tr.declFatigue,
            tr.declSolitude,
            tr.declColere,
            tr.declSoiree,
            tr.declEcrans,
          ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final d in options)
          Puce(
            libelle: d,
            choisie: d == valeur,
            couleur: RhythmCouleurs.menthe,
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(d == valeur ? null : d);
            },
          ),
      ],
    );
  }
}
