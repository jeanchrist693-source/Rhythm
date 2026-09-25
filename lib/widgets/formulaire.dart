// lib/widgets/formulaire.dart
//
// Les pièces des formulaires de Rhythm, dans son langage (PAS DE CARTES,
// PAS DE LUEURS — `filets.dart`) :
// - [EtiquetteChamp] : petit libellé en capitales au-dessus d'un champ ;
// - [ChampRhythm] : pas de boîte — le texte posé sur le noir, souligné d'un
//   FILET (8 %, 45 % pendant la saisie). Toute sa hauteur (filet compris)
//   donne le focus ; le clavier ne se ferme PAS au premier toucher ailleurs
//   (défiler le garde ouvert) — seulement en touchant un vide de la page
//   (`PageSecondaire`) ou par le clavier lui-même ;
// - [CompteurRhythm] : une valeur réglée par − / + (appui long = défile),
//   deux disques ; [RouletteHeure] : l'heure sur deux roulettes (heures,
//   minutes de 5 en 5) ;
// - [PucesChoix], [PucesMultiples], [SelecteurJours] : des CAPSULES (blanc
//   plein = choisi) ;
// - [Interrupteur] ; [LigneReglage] (libellé à gauche, commande à droite) ;
// - [BoutonSuppression] : deux temps, sans dialogue (repris de Net Worth /
//   Studio) — le premier toucher arme, le second supprime.
// Jamais d'autofocus : le clavier ne monte qu'au toucher d'un champ.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/rhythm_couleurs.dart';
import '../theme/rhythm_typo.dart';
import 'filets.dart';
import 'pictos.dart';
import 'pression_echelle.dart';

class EtiquetteChamp extends StatelessWidget {
  const EtiquetteChamp(this.texte, {super.key, this.droite});

  final String texte;
  final Widget? droite;

  @override
  Widget build(BuildContext context) {
    final etiquette = Text(
      texte.toUpperCase(),
      style: RhythmTypo.texte(
        12,
        poids: 600,
        couleur: RhythmCouleurs.texte64,
        espacement: 0.06,
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: droite == null
          ? etiquette
          : Row(
              children: [
                Expanded(child: etiquette),
                droite!,
              ],
            ),
    );
  }
}

/// Un champ sans boîte : le texte, puis un filet dessous.
class ChampRhythm extends StatefulWidget {
  const ChampRhythm({
    super.key,
    this.controleur,
    this.focus,
    this.indice,
    this.clavier,
    this.majuscules = TextCapitalization.sentences,
    this.lignes = 1,
    this.formateurs,
    this.suffixe,
    this.onChanged,
    this.actionClavier,
    this.onValider,
    this.style,
  });

  final TextEditingController? controleur;
  final FocusNode? focus;
  final String? indice;
  final TextInputType? clavier;
  final TextCapitalization majuscules;

  /// Plus d'une ligne : le champ grandit jusqu'à [lignes] puis défile.
  final int lignes;
  final List<TextInputFormatter>? formateurs;

  /// Unité à droite (« $ »).
  final String? suffixe;
  final ValueChanged<String>? onChanged;
  final TextInputAction? actionClavier;
  final ValueChanged<String>? onValider;
  final TextStyle? style;

  @override
  State<ChampRhythm> createState() => _ChampRhythmState();
}

class _ChampRhythmState extends State<ChampRhythm> {
  FocusNode? _interne;

  /// Le focus du widget ACTUEL : un `late final` gardait celui du premier
  /// widget — quand le formulaire changeait de forme (construire ↔
  /// libérer), deux champs partageaient un même focus (double sélection,
  /// clavier qui se refermait aussitôt).
  FocusNode get _focus => widget.focus ?? (_interne ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_redessiner);
  }

  @override
  void didUpdateWidget(ChampRhythm ancien) {
    super.didUpdateWidget(ancien);
    final avant = ancien.focus ?? _interne;
    if (avant != _focus) {
      avant?.removeListener(_redessiner);
      _focus.addListener(_redessiner);
    }
  }

  void _redessiner() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _focus.removeListener(_redessiner);
    _interne?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actif = _focus.hasFocus;
    final style = widget.style ?? RhythmTypo.texte(17, hauteur: 1.35);
    // Toucher sous le texte (la marge, le filet) donne aussi le focus.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _focus.requestFocus,
      child: _contenu(actif, style),
    );
  }

  Widget _contenu(bool actif, TextStyle style) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: widget.lignes > 1
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controleur,
                  focusNode: _focus,
                  keyboardType: widget.lignes > 1
                      ? TextInputType.multiline
                      : widget.clavier,
                  textCapitalization: widget.majuscules,
                  inputFormatters: widget.formateurs,
                  minLines: 1,
                  maxLines: widget.lignes,
                  style: style,
                  cursorColor: RhythmCouleurs.blanc,
                  onChanged: widget.onChanged,
                  textInputAction:
                      widget.actionClavier ??
                      (widget.lignes > 1 ? TextInputAction.newline : null),
                  onSubmitted: widget.onValider,
                  decoration: InputDecoration.collapsed(
                    hintText: widget.indice,
                    hintStyle: style.copyWith(color: RhythmCouleurs.texte40),
                  ),
                ),
              ),
              if (widget.suffixe != null) ...[
                const SizedBox(width: 8),
                Text(
                  widget.suffixe!,
                  style: RhythmTypo.texte(15, couleur: RhythmCouleurs.texte64),
                ),
              ],
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 1,
          color: actif ? RhythmCouleurs.filetActif : RhythmCouleurs.bordBouton,
        ),
      ],
    );
  }
}

/// Une valeur réglée par − / + : [valeur] entre [min] et [max], par [pas].
class CompteurRhythm extends StatelessWidget {
  const CompteurRhythm({
    super.key,
    required this.valeur,
    required this.onChanged,
    required this.affichage,
    this.min = 0,
    this.max = 100,
    this.pas = 1,
    this.largeurValeur = 72,
    this.boucle = false,
  });

  final int valeur;
  final ValueChanged<int> onChanged;
  final String Function(int) affichage;
  final int min;
  final int max;
  final int pas;
  final double largeurValeur;

  /// Au-delà d'une borne, on repart de l'autre (heures, minutes).
  final bool boucle;

  int _suivante(int v) {
    if (v >= min && v <= max) return v;
    if (!boucle) return v.clamp(min, max);
    // En boucle : 55 + 5 → 0, 0 − 5 → 55 (l'ancienne formule donnait 4).
    final etendue = max - min + pas;
    return min + (v - min) % etendue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BoutonPas(
          picto: Picto.moins,
          actif: boucle || valeur > min,
          onPas: () => onChanged(_suivante(valeur - pas)),
        ),
        SizedBox(
          width: largeurValeur,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              affichage(valeur),
              textAlign: TextAlign.center,
              maxLines: 1,
              style: RhythmTypo.titre(20, poids: 500),
            ),
          ),
        ),
        _BoutonPas(
          picto: Picto.plus,
          actif: boucle || valeur < max,
          onPas: () => onChanged(_suivante(valeur + pas)),
        ),
      ],
    );
  }
}

/// − ou + : un toucher = un pas ; maintenu, il défile (≈ 9 pas / s).
class _BoutonPas extends StatefulWidget {
  const _BoutonPas({
    required this.picto,
    required this.actif,
    required this.onPas,
  });

  final Picto picto;
  final bool actif;
  final VoidCallback onPas;

  @override
  State<_BoutonPas> createState() => _BoutonPasState();
}

class _BoutonPasState extends State<_BoutonPas> {
  Timer? _repetition;
  bool _enfonce = false;

  void _arreter() {
    _repetition?.cancel();
    _repetition = null;
  }

  @override
  void dispose() {
    _arreter();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Doigt levé : la répétition s'arrête TOUJOURS (même si le geste d'appui
    // long n'a pas reçu sa fin) — sinon la valeur défilait sans fin.
    return Listener(
      onPointerDown: (_) => setState(() => _enfonce = true),
      onPointerUp: (_) {
        _arreter();
        setState(() => _enfonce = false);
      },
      onPointerCancel: (_) {
        _arreter();
        setState(() => _enfonce = false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.actif
            ? () {
                HapticFeedback.selectionClick();
                widget.onPas();
              }
            : null,
        onLongPressStart: widget.actif
            ? (_) {
                HapticFeedback.selectionClick();
                _arreter();
                _repetition = Timer.periodic(
                  const Duration(milliseconds: 110),
                  (_) => widget.actif ? widget.onPas() : _arreter(),
                );
              }
            : null,
        onLongPressEnd: (_) => _arreter(),
        onLongPressCancel: _arreter,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: AnimatedScale(
              scale: _enfonce && widget.actif ? 0.88 : 1,
              duration: const Duration(milliseconds: 90),
              child: Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: RhythmCouleurs.capsule,
                  shape: BoxShape.circle,
                ),
                child: PictoRhythm(
                  widget.picto,
                  taille: 16,
                  epaisseur: 2.2,
                  couleur: widget.actif
                      ? RhythmCouleurs.blanc
                      : RhythmCouleurs.texte40,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Une heure (minutes depuis minuit) sur deux ROULETTES : les heures, puis
/// les minutes de 5 en 5, qui tournent en boucle. La ligne choisie est
/// entre deux filets (pas de boîte). Remplace les compteurs − / + : l'heure
/// en grand passait à la ligne (« 22 h » / « 00 ») et les minutes
/// s'emballaient.
class RouletteHeure extends StatefulWidget {
  const RouletteHeure({
    super.key,
    required this.minutes,
    required this.onChanged,
    this.separateur = 'h',
  });

  final int minutes;
  final ValueChanged<int> onChanged;

  /// Entre les heures et les minutes (« h », « : »).
  final String separateur;

  @override
  State<RouletteHeure> createState() => _RouletteHeureState();
}

class _RouletteHeureState extends State<RouletteHeure> {
  static const double _ligne = 44;

  late int _h = widget.minutes ~/ 60 % 24;
  late int _m = ((widget.minutes % 60) / 5).round() % 12 * 5;
  late final FixedExtentScrollController _heures = FixedExtentScrollController(
    initialItem: _h,
  );
  late final FixedExtentScrollController _minutes = FixedExtentScrollController(
    initialItem: _m ~/ 5,
  );

  @override
  void dispose() {
    _heures.dispose();
    _minutes.dispose();
    super.dispose();
  }

  void _choisi({int? heure, int? minute}) {
    final h = heure ?? _h, m = minute ?? _m;
    if (h == _h && m == _m) return;
    HapticFeedback.selectionClick();
    _h = h;
    _m = m;
    widget.onChanged(_h * 60 + _m);
  }

  Widget _roue(
    FixedExtentScrollController controleur,
    int n,
    String Function(int) libelle,
    ValueChanged<int> onChoisi,
  ) => ListWheelScrollView.useDelegate(
    controller: controleur,
    itemExtent: _ligne,
    diameterRatio: 1.5,
    overAndUnderCenterOpacity: 0.32,
    physics: const FixedExtentScrollPhysics(),
    onSelectedItemChanged: (i) => onChoisi(i % n),
    childDelegate: ListWheelChildLoopingListDelegate(
      children: [
        for (var i = 0; i < n; i++)
          Center(
            child: Text(libelle(i), style: RhythmTypo.titre(26, poids: 500)),
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _ligne * 3.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // La ligne choisie : deux filets, rien d'autre.
          IgnorePointer(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Filet(couleur: RhythmCouleurs.filetGrille),
                SizedBox(height: _ligne - 2),
                Filet(couleur: RhythmCouleurs.filetGrille),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 76,
                child: _roue(
                  _heures,
                  24,
                  (i) => i.toString().padLeft(2, '0'),
                  (h) => _choisi(heure: h),
                ),
              ),
              SizedBox(
                width: 28,
                child: Center(
                  child: Text(
                    widget.separateur,
                    style: RhythmTypo.titre(
                      22,
                      poids: 500,
                      couleur: RhythmCouleurs.texte64,
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: 76,
                child: _roue(
                  _minutes,
                  12,
                  (i) => (i * 5).toString().padLeft(2, '0'),
                  (i) => _choisi(minute: i * 5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Un choix parmi quelques options, en capsules : le choisi est blanc
/// plein, texte noir ; les autres, blanc 8 %.
class PucesChoix<T> extends StatelessWidget {
  const PucesChoix({
    super.key,
    required this.options,
    required this.valeur,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final T? valeur;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (v, libelle) in options)
        Puce(
          libelle: libelle,
          choisie: v == valeur,
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged(v);
          },
        ),
    ],
  );
}

/// Plusieurs choix à la fois.
class PucesMultiples<T> extends StatelessWidget {
  const PucesMultiples({
    super.key,
    required this.options,
    required this.valeurs,
    required this.onChanged,
  });

  final List<(T, String)> options;
  final Set<T> valeurs;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final (v, libelle) in options)
        Puce(
          libelle: libelle,
          choisie: valeurs.contains(v),
          onTap: () {
            HapticFeedback.selectionClick();
            final nouvelles = {...valeurs};
            nouvelles.contains(v) ? nouvelles.remove(v) : nouvelles.add(v);
            onChanged(nouvelles);
          },
        ),
    ],
  );
}

/// Les jours prévus : sept capsules de même largeur (lundi d'abord),
/// plusieurs à la fois.
class SelecteurJours extends StatelessWidget {
  const SelecteurJours({
    super.key,
    required this.libelles,
    required this.jours,
    required this.onChanged,
  });

  /// Sept libellés, lundi d'abord.
  final List<String> libelles;

  /// Jours ISO choisis (1 = lundi).
  final Set<int> jours;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var j = 1; j <= 7; j++) ...[
          if (j > 1) const SizedBox(width: 4),
          Expanded(
            child: PressionEchelle(
              echelle: 0.92,
              onTap: () {
                HapticFeedback.selectionClick();
                final nouveaux = {...jours};
                nouveaux.contains(j) ? nouveaux.remove(j) : nouveaux.add(j);
                onChanged(nouveaux);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: jours.contains(j)
                      ? RhythmCouleurs.blanc
                      : RhythmCouleurs.capsule,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Text(
                      libelles[j - 1],
                      maxLines: 1,
                      style: RhythmTypo.texte(
                        13,
                        poids: 600,
                        couleur: jours.contains(j)
                            ? RhythmCouleurs.noir
                            : RhythmCouleurs.texte72,
                      ),
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

/// Une capsule de choix.
class Puce extends StatelessWidget {
  const Puce({
    super.key,
    required this.libelle,
    required this.choisie,
    required this.onTap,
    this.couleur = RhythmCouleurs.blanc,
  });

  final String libelle;
  final bool choisie;
  final VoidCallback onTap;

  /// Le fond d'une capsule choisie (blanc, ou la teinte d'un domaine).
  final Color couleur;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: choisie,
      child: PressionEchelle(
        onTap: onTap,
        echelle: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: choisie ? couleur : RhythmCouleurs.capsule,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            libelle,
            maxLines: 1,
            style: RhythmTypo.texte(
              14,
              poids: 500,
              couleur: choisie ? RhythmCouleurs.noir : RhythmCouleurs.texte72,
            ),
          ),
        ),
      ),
    );
  }
}

class Interrupteur extends StatelessWidget {
  const Interrupteur({
    super.key,
    required this.valeur,
    required this.onChanged,
  });

  final bool valeur;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: valeur,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(!valeur);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            width: 46,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: valeur ? RhythmCouleurs.menthe : RhythmCouleurs.piste,
              borderRadius: BorderRadius.circular(999),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              alignment: valeur ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: valeur ? RhythmCouleurs.noir : RhythmCouleurs.texte64,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Une ligne de réglage : libellé (et détail) à gauche, valeur ou commande
/// à droite ; touchable si [onTap] (chevron ajouté). Pas de boîte : les
/// lignes se séparent par des filets.
class LigneReglage extends StatelessWidget {
  const LigneReglage({
    super.key,
    required this.libelle,
    this.detail,
    this.valeur,
    this.droite,
    this.onTap,
    this.gauche,
  });

  final String libelle;
  final String? detail;

  /// Texte à droite (« 21 h 00 »).
  final String? valeur;

  /// Commande à droite (interrupteur) — remplace [valeur].
  final Widget? droite;

  /// Pastille à gauche.
  final Widget? gauche;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ligne = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (gauche != null) ...[gauche!, const SizedBox(width: 14)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(libelle, style: RhythmTypo.texte(15, poids: 500)),
                  if (detail != null) ...[
                    const SizedBox(height: 2),
                    Text(detail!, style: RhythmTypo.petit),
                  ],
                ],
              ),
            ),
            if (droite != null) ...[const SizedBox(width: 12), droite!],
            if (droite == null && valeur != null) ...[
              const SizedBox(width: 12),
              Text(
                valeur!,
                style: RhythmTypo.texte(15, couleur: RhythmCouleurs.texte64),
              ),
            ],
            if (onTap != null && droite == null) ...[
              const SizedBox(width: 6),
              const PictoRhythm(
                Picto.chevron,
                taille: 18,
                couleur: RhythmCouleurs.texte40,
              ),
            ],
          ],
        ),
      ),
    );
    if (onTap == null) return ligne;
    return PressionEchelle(onTap: onTap, echelle: 0.98, child: ligne);
  }
}

/// Deux temps, sans dialogue : le premier toucher ARME (le libellé devient
/// [confirmation], sur la [couleur]), le second agit. Désarmé seul après
/// 3 s. Corail pour supprimer ; blanc quand il ne s'agit pas d'une perte
/// (remettre un compteur à zéro : pas de rouge, pas de reproche).
class BoutonSuppression extends StatefulWidget {
  const BoutonSuppression({
    super.key,
    required this.libelle,
    required this.confirmation,
    required this.onConfirme,
    this.couleur = RhythmCouleurs.corail,
  });

  final String libelle;
  final String confirmation;
  final VoidCallback onConfirme;
  final Color couleur;

  @override
  State<BoutonSuppression> createState() => _BoutonSuppressionState();
}

class _BoutonSuppressionState extends State<BoutonSuppression> {
  bool _arme = false;
  Timer? _desarmement;

  @override
  void dispose() {
    _desarmement?.cancel();
    super.dispose();
  }

  void _toucher() {
    if (_arme) {
      _desarmement?.cancel();
      HapticFeedback.mediumImpact();
      widget.onConfirme();
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _arme = true);
    _desarmement = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _arme = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: PressionEchelle(
        onTap: _toucher,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _arme ? widget.couleur : null,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _arme ? widget.couleur : RhythmCouleurs.bordBouton,
            ),
          ),
          child: Text(
            _arme ? widget.confirmation : widget.libelle,
            style: RhythmTypo.texte(
              15,
              poids: 600,
              couleur: _arme ? RhythmCouleurs.noir : widget.couleur,
            ),
          ),
        ),
      ),
    );
  }
}
