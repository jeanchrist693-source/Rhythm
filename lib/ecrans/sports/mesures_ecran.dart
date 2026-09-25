// lib/ecrans/sports/mesures_ecran.dart
//
// Les MESURES, facultatives : le poids et le tour de taille, pour suivre la
// progression — une courbe discrète pour chacun, l'écart depuis le début,
// l'historique (maintenir une ligne propose de la retirer). La dernière
// mesure du poids sert aussi aux calories.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_sport.dart';
import '../../l10n/traductions.dart';
import '../../modele/etat_sante.dart';
import '../../modele/sports/etat_sport.dart';
import '../../modele/sports/sport.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/boutons.dart';
import '../../widgets/filets.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/suivi_clavier.dart';
import '../../widgets/toast.dart';
import 'pieces_sports.dart';

class MesuresEcran extends ConsumerStatefulWidget {
  const MesuresEcran({super.key, required this.retour});

  final String retour;

  @override
  ConsumerState<MesuresEcran> createState() => _MesuresEcranState();
}

class _MesuresEcranState extends ConsumerState<MesuresEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<MesuresEcran> {
  final _poids = TextEditingController();
  final _taille = TextEditingController();
  final _focusPoids = FocusNode();
  final _focusTaille = FocusNode();
  String? _aRetirer;

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focusPoids);
    surveillerClavier(_focusTaille);
  }

  @override
  void dispose() {
    libererClavier();
    _poids.dispose();
    _taille.dispose();
    _focusPoids.dispose();
    _focusTaille.dispose();
    super.dispose();
  }

  double? _lire(TextEditingController c) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
    return v == null || v <= 0 ? null : v;
  }

  void _ajouter() {
    final tr = context.tr;
    final p = _lire(_poids), t = _lire(_taille);
    if (p == null && t == null) {
      montrerToast(context, tr.mesureRequise);
      return;
    }
    final notifier = ref.read(sportProvider.notifier);
    notifier.ajouterMesure(
      MesureCorps(
        id: notifier.nouvelId('mes'),
        date: ref.read(horlogeProvider)(),
        poids: p,
        tourTaille: t,
      ),
    );
    HapticFeedback.mediumImpact();
    _poids.clear();
    _taille.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final mesures = ref.watch(sportProvider.select((s) => s.mesures));
    final poids = [
      for (final m in mesures)
        if (m.poids != null) (m.date, m.poids!),
    ];
    final tailles = [
      for (final m in mesures)
        if (m.tourTaille != null) (m.date, m.tourTaille!),
    ];

    String ecart(List<(DateTime, double)> s, String Function(double) u) {
      final d = s.last.$2 - s.first.$2;
      final signe = d > 0 ? '+' : (d < 0 ? '−' : '');
      return tr.depuisLeDebut('$signe${u(d.abs())}');
    }

    final formats = [
      TextInputFormatter.withFunction(
        (a, b) => RegExp(r'^[0-9]*[.,]?[0-9]{0,1}$').hasMatch(b.text) ? b : a,
      ),
    ];

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(titre: tr.mesures),
        if (poids.isNotEmpty)
          _Courbe(
            titre: tr.poids,
            valeur: f.kg(poids.last.$2, tr),
            ecart: poids.length > 1 ? ecart(poids, (d) => f.kg(d, tr)) : null,
            points: poids,
            couleur: RhythmCouleurs.corail,
          ),
        if (tailles.isNotEmpty)
          _Courbe(
            titre: tr.tourDeTaille,
            valeur: f.cm(tailles.last.$2, tr),
            ecart: tailles.length > 1
                ? ecart(tailles, (d) => f.cm(d, tr))
                : null,
            points: tailles,
            couleur: RhythmCouleurs.peche,
          ),
        if (mesures.isEmpty) Text(tr.aucuneMesure, style: RhythmTypo.detail),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.ajouterMesure),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EtiquetteChamp(tr.poids),
                      ChampRhythm(
                        controleur: _poids,
                        focus: _focusPoids,
                        indice: tr.indiceKg,
                        clavier: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        formateurs: formats,
                        suffixe: 'kg',
                        actionClavier: TextInputAction.next,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      EtiquetteChamp(tr.tourDeTaille),
                      ChampRhythm(
                        controleur: _taille,
                        focus: _focusTaille,
                        indice: tr.indiceCm,
                        clavier: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        formateurs: formats,
                        suffixe: 'cm',
                        actionClavier: TextInputAction.done,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            BoutonCapsule(
              picto: Picto.plus,
              libelle: tr.ajouter,
              plein: true,
              onTap: _ajouter,
            ),
          ],
        ),
        if (mesures.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.historique),
              for (final (i, m) in mesures.reversed.indexed) ...[
                if (i > 0) const Filet(),
                GestureDetector(
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _aRetirer = m.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            f.dateCourte(m.date),
                            style: RhythmTypo.detail,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            [
                              if (m.poids != null) f.kg(m.poids!, tr),
                              if (m.tourTaille != null) f.cm(m.tourTaille!, tr),
                            ].join(' · '),
                            style: RhythmTypo.texte(15),
                          ),
                        ),
                        if (_aRetirer == m.id)
                          PressionEchelle(
                            onTap: () {
                              ref
                                  .read(sportProvider.notifier)
                                  .supprimerMesure(m.id);
                              setState(() => _aRetirer = null);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Text(
                                tr.retirer,
                                style: RhythmTypo.texte(
                                  14,
                                  poids: 600,
                                  couleur: RhythmCouleurs.corail,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }
}

class _Courbe extends StatelessWidget {
  const _Courbe({
    required this.titre,
    required this.valeur,
    required this.ecart,
    required this.points,
    required this.couleur,
  });

  final String titre;
  final String valeur;
  final String? ecart;
  final List<(DateTime, double)> points;
  final Color couleur;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: StatSport(libelle: titre, valeur: valeur, couleur: couleur),
          ),
          if (ecart != null) Text(ecart!, style: RhythmTypo.detail),
        ],
      ),
      if (points.length > 1) ...[
        const SizedBox(height: 12),
        SizedBox(
          height: 70,
          child: CustomPaint(painter: _PeintreCourbe(points, couleur)),
        ),
      ],
    ],
  );
}

class _PeintreCourbe extends CustomPainter {
  _PeintreCourbe(this.points, this.couleur);

  final List<(DateTime, double)> points;
  final Color couleur;

  @override
  void paint(Canvas canvas, Size size) {
    final t0 = points.first.$1.millisecondsSinceEpoch.toDouble();
    final t1 = points.last.$1.millisecondsSinceEpoch.toDouble();
    var mn = points.map((p) => p.$2).reduce(math.min);
    var mx = points.map((p) => p.$2).reduce(math.max);
    if (mx - mn < 1) {
      mn -= 0.5;
      mx += 0.5;
    }
    Offset o((DateTime, double) p) => Offset(
      t1 == t0
          ? size.width / 2
          : (p.$1.millisecondsSinceEpoch - t0) / (t1 - t0) * size.width,
      size.height - 6 - (p.$2 - mn) / (mx - mn) * (size.height - 12),
    );
    final chemin = Path()..moveTo(o(points.first).dx, o(points.first).dy);
    for (final p in points.skip(1)) {
      chemin.lineTo(o(p).dx, o(p).dy);
    }
    canvas.drawPath(
      chemin,
      Paint()
        ..color = couleur
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(o(points.last), 4, Paint()..color = couleur);
  }

  @override
  bool shouldRepaint(_PeintreCourbe a) => a.points != points;
}
