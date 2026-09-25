// lib/ecrans/habitudes/habitudes_ecran.dart
//
// Habitudes, VIVANTES (maquette « Habitudes », sans cartes — `filets.dart`) :
// - l'en-tête : « 4 sur 6 » du jour affiché, l'enthousiaste qui saute ;
// - deux capsules à portée de pouce : « Nouvelle habitude », « Rappels » ;
// - LIBÉRATION en tête (`BlocLiberation`, le même que sur l'accueil) ;
// - le MOT DU JOUR (`libelles_habitudes.dart`) : une phrase sur la journée
//   — palier, journée complète, « jamais deux fois », le moment ;
// - la SEMAINE : le jour affiché dans une capsule blanche (aujourd'hui,
//   d'abord) ; un point menthe par journée complète, pâle si elle est
//   seulement entamée ; toucher un jour passé l'affiche — on coche après
//   coup ;
// - la SÉRIE (journées complètes d'affilée) et le record ;
// - les habitudes prévues ce jour-là : toucher le CERCLE coche (retour
//   tactile, et une petite fête aux paliers et à la journée complète),
//   toucher la LIGNE ouvre la fiche ; la série de chacune en corail. Leur
//   ORDRE : « Mon ordre » (maintenir une ligne pour la déplacer) ou « Par
//   heure » (de rappel) ; l'épinglée (fiche › épingle) toujours en tête ;
// - « Les autres jours » : celles qui ne sont pas prévues ce jour-là.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/libelles_habitudes.dart';
import '../../l10n/traductions.dart';
import '../../modele/calculs_habitudes.dart';
import '../../modele/etat_habitudes.dart';
import '../../modele/etat_sante.dart';
import '../../modele/habitudes.dart';

import '../../navigation/transitions.dart';
import '../../systeme/notifications.dart';
import '../../systeme/rappels_habitudes.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../utils/dates.dart';
import '../../widgets/boutons.dart';
import '../../widgets/filets.dart';
import '../../widgets/mascottes.dart';
import '../../widgets/page_rhythm.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/surfaces.dart';
import '../../widgets/toast.dart';
import '../rappels/rappels_ecran.dart';
import 'envie_ecran.dart';
import 'habitude_detail_ecran.dart';
import 'habitude_formulaire_ecran.dart';
import 'pieces_habitudes.dart';

class HabitudesEcran extends ConsumerStatefulWidget {
  const HabitudesEcran({super.key});

  @override
  ConsumerState<HabitudesEcran> createState() => _HabitudesEcranState();
}

class _HabitudesEcranState extends ConsumerState<HabitudesEcran> {
  /// Le jour affiché ; `null` = aujourd'hui.
  DateTime? _choisi;

  void _basculer(Habitude h, DateTime jour, DateTime auj) {
    final tr = context.tr;
    final r = ref.read(habitudesProvider.notifier).basculer(h.id, jour);
    if (r == null) return;
    if (!r.faite) {
      HapticFeedback.selectionClick();
      return;
    }
    // Faite : son rappel du jour, s'il est affiché, n'a plus lieu d'être.
    if (jour == auj) NotificationsSysteme.instance.annuler(idRappel(h.id, 0));
    if (r.palier != null) {
      HapticFeedback.heavyImpact();
      montrerToast(context, tr.toastPalier(r.palier!));
    } else if (r.journeeComplete) {
      HapticFeedback.heavyImpact();
      final etat = ref.read(habitudesProvider);
      montrerToast(
        context,
        tr.toastJourneeComplete(serieGlobale(etat.habitudes, auj)),
      );
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _ouvrir(Habitude h) =>
      pousserEcran(context, HabitudeDetailEcran(id: h.id));

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final maintenant = ref.watch(aujourdhuiProvider);
    final auj = jourDe(maintenant);
    final etat = ref.watch(habitudesProvider);
    final construire = etat.aConstruire;
    final liberer = etat.aLiberer;
    var jour = _choisi ?? auj;
    if (jour.isAfter(auj)) jour = auj;
    final reglages = etat.reglages;
    final ordonnees = ordonner(construire, reglages);
    final prevues = [
      for (final h in ordonnees)
        if (estPrevue(h, jour)) h,
    ];
    final autres = [
      for (final h in ordonnees)
        if (!estPrevue(h, jour) && !jour.isBefore(h.creeLe)) h,
    ];
    final faites = prevues.where((h) => estFaite(h, jour)).length;
    final mot = jour == auj ? motDuJour(tr, etat, maintenant) : null;
    DateTime? premierJour;
    for (final h in construire) {
      if (premierJour == null || h.creeLe.isBefore(premierJour)) {
        premierJour = h.creeLe;
      }
    }

    return PageRhythm(
      blocs: [
        EnTete(
          surtitre: Text(
            prevues.isEmpty
                ? (etat.habitudes.isEmpty ? tr.aCommencer : f.jourComplet(jour))
                : tr.surTotal(faites, prevues.length),
            style: RhythmTypo.texte(
              14,
              poids: 600,
              couleur: RhythmCouleurs.menthe,
            ),
          ),
          titre: tr.navHabitudes,
          mascotte: Mascotte.habitudes,
        ),
        _Actions(
          onNouvelle: () =>
              pousserEcran(context, const HabitudeFormulaireEcran()),
          onRappels: () =>
              pousserEcran(context, RappelsEcran(retour: tr.navHabitudes)),
        ),
        if (mot != null) _MotDuJour(mot),
        if (liberer.isNotEmpty)
          BlocLiberation(
            habitudes: ordonner(liberer, reglages),
            onOuvrir: _ouvrir,
            onEnvie: (h) => pousserEcran(context, EnvieEcran(id: h.id)),
          ),
        if (construire.isNotEmpty)
          _Semaine(
            aujourdhui: auj,
            choisi: jour,
            habitudes: construire,
            premierJour: premierJour,
            onChoisir: (j) {
              HapticFeedback.selectionClick();
              setState(() => _choisi = j == auj ? null : j);
            },
          ),
        if (construire.isNotEmpty)
          _Serie(
            serie: serieGlobale(construire, auj),
            record: recordGlobal(construire, auj),
          ),
        if (prevues.isNotEmpty || jour != auj)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TeteListe(
                titre: jour == auj ? tr.aujourdhui : f.jourComplet(jour),
                tri: reglages.tri,
                onTri: (t) {
                  HapticFeedback.selectionClick();
                  ref.read(habitudesProvider.notifier).trier(t);
                },
                onAujourdhui: jour == auj
                    ? null
                    : () => setState(() => _choisi = null),
              ),
              _ListeDuJour(
                habitudes: prevues,
                jour: jour,
                aujourdhui: auj,
                epinglee: reglages.epinglee,
                deplacable: reglages.tri == TriHabitudes.manuel,
                onBasculer: (h) => _basculer(h, jour, auj),
                onOuvrir: _ouvrir,
                onReordonner: (ids) {
                  HapticFeedback.selectionClick();
                  ref.read(habitudesProvider.notifier).reordonner(ids);
                },
              ),
              if (reglages.tri == TriHabitudes.manuel &&
                  prevues.length > 1) ...[
                const SizedBox(height: 10),
                Text(
                  tr.deplacerAide,
                  style: RhythmTypo.texte(12, couleur: RhythmCouleurs.texte40),
                ),
              ],
            ],
          ),
        if (autres.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.lesAutresJours),
              for (var i = 0; i < autres.length; i++)
                _LigneAutre(
                  habitude: autres[i],
                  premiere: i == 0,
                  onTap: () => _ouvrir(autres[i]),
                ),
            ],
          ),
      ],
    );
  }
}

/// « + Nouvelle habitude » et « Rappels » : deux capsules, à portée de
/// pouce, sous le titre.
class _Actions extends StatelessWidget {
  const _Actions({required this.onNouvelle, required this.onRappels});

  final VoidCallback onNouvelle;
  final VoidCallback onRappels;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Row(
      children: [
        Expanded(
          child: BoutonCapsule(
            picto: Picto.plus,
            libelle: tr.nouvelleHabitude,
            plein: true,
            onTap: onNouvelle,
          ),
        ),
        const SizedBox(width: 10),
        BoutonCapsule(
          picto: Picto.cloche,
          libelle: tr.rappels,
          onTap: onRappels,
        ),
      ],
    );
  }
}

/// Le titre de la liste du jour, et le choix de l'ordre : « Mon ordre » /
/// « Par heure » (deux segments dans une capsule).
class _TeteListe extends StatelessWidget {
  const _TeteListe({
    required this.titre,
    required this.tri,
    required this.onTri,
    this.onAujourdhui,
  });

  final String titre;
  final TriHabitudes tri;
  final ValueChanged<TriHabitudes> onTri;

  /// Un jour passé est affiché : revenir à aujourd'hui.
  final VoidCallback? onAujourdhui;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    Widget segment(TriHabitudes t, String libelle) {
      final choisi = t == tri;
      return Semantics(
        button: true,
        selected: choisi,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: choisi ? null : () => onTri(t),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 11),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: choisi ? RhythmCouleurs.blanc : null,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              libelle,
              style: RhythmTypo.texte(
                12,
                poids: 600,
                couleur: choisi ? RhythmCouleurs.noir : RhythmCouleurs.texte64,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titre.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: RhythmTypo.texte(
                13,
                poids: 600,
                couleur: RhythmCouleurs.texte64,
                espacement: 0.06,
              ),
            ),
          ),
          if (onAujourdhui != null) ...[
            _Lien(libelle: tr.aujourdhui, onTap: onAujourdhui!),
            const SizedBox(width: 12),
          ],
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RhythmCouleurs.bordBouton),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                segment(TriHabitudes.manuel, tr.monOrdre),
                segment(TriHabitudes.rappel, tr.parHeure),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Les habitudes du jour. En « Mon ordre », on les déplace en maintenant
/// une ligne (elle se soulève à peine — ni ombre ni lueur).
class _ListeDuJour extends StatelessWidget {
  const _ListeDuJour({
    required this.habitudes,
    required this.jour,
    required this.aujourdhui,
    required this.epinglee,
    required this.deplacable,
    required this.onBasculer,
    required this.onOuvrir,
    required this.onReordonner,
  });

  final List<Habitude> habitudes;
  final DateTime jour;
  final DateTime aujourdhui;
  final String? epinglee;
  final bool deplacable;
  final ValueChanged<Habitude> onBasculer;
  final ValueChanged<Habitude> onOuvrir;
  final ValueChanged<List<String>> onReordonner;

  Widget _ligne(int i) => _LigneHabitude(
    key: ValueKey(habitudes[i].id),
    habitude: habitudes[i],
    jour: jour,
    aujourdhui: aujourdhui,
    premiere: i == 0,
    epinglee: habitudes[i].id == epinglee,
    onBasculer: () => onBasculer(habitudes[i]),
    onOuvrir: () => onOuvrir(habitudes[i]),
  );

  @override
  Widget build(BuildContext context) {
    if (!deplacable || habitudes.length < 2) {
      return Column(
        children: [for (var i = 0; i < habitudes.length; i++) _ligne(i)],
      );
    }
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      buildDefaultDragHandles: false,
      onReorderStart: (_) => HapticFeedback.mediumImpact(),
      // L'indice d'arrivée tient déjà compte de la ligne retirée.
      onReorderItem: (ancien, nouveau) {
        if (nouveau == ancien) return;
        final ids = [for (final h in habitudes) h.id];
        ids.insert(nouveau, ids.removeAt(ancien));
        onReordonner(ids);
      },
      // La ligne soulevée : un léger grossissement sur le noir, rien
      // d'autre (le décor par défaut ajoute une ombre).
      proxyDecorator: (enfant, _, animation) => AnimatedBuilder(
        animation: animation,
        builder: (_, _) => Transform.scale(
          scale: 1 + 0.03 * Curves.easeOut.transform(animation.value),
          child: Material(
            type: MaterialType.transparency,
            child: ColoredBox(color: RhythmCouleurs.fond, child: enfant),
          ),
        ),
      ),
      children: [
        for (var i = 0; i < habitudes.length; i++)
          ReorderableDelayedDragStartListener(
            key: ValueKey(habitudes[i].id),
            index: i,
            child: _ligne(i),
          ),
      ],
    );
  }
}

/// Le mot du jour : une phrase, rien autour.
class _MotDuJour extends StatelessWidget {
  const _MotDuJour(this.texte);

  final String texte;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: const Duration(milliseconds: 280),
    layoutBuilder: (actuel, precedents) =>
        Stack(alignment: Alignment.topLeft, children: [...precedents, ?actuel]),
    child: Text(
      texte,
      key: ValueKey(texte),
      style: RhythmTypo.titre(20, poids: 500, espacement: -0.01, hauteur: 1.3),
    ),
  );
}

/// Un lien discret (« Aujourd'hui »).
class _Lien extends StatelessWidget {
  const _Lien({required this.libelle, required this.onTap});

  final String libelle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    child: PressionEchelle(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          libelle,
          style: RhythmTypo.texte(
            13,
            poids: 600,
            couleur: RhythmCouleurs.menthe,
          ),
        ),
      ),
    ),
  );
}

/// Les sept jours de la semaine : initiale, date, point (menthe = journée
/// complète, pâle = entamée). Le jour affiché est dans une capsule blanche ;
/// aujourd'hui, s'il ne l'est pas, garde un contour.
class _Semaine extends StatelessWidget {
  const _Semaine({
    required this.aujourdhui,
    required this.choisi,
    required this.habitudes,
    required this.premierJour,
    required this.onChoisir,
  });

  final DateTime aujourdhui;
  final DateTime choisi;
  final List<Habitude> habitudes;
  final DateTime? premierJour;
  final ValueChanged<DateTime> onChoisir;

  @override
  Widget build(BuildContext context) {
    final f = context.formats;
    final lundi = lundiDe(aujourdhui);
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          Expanded(
            child: Builder(
              builder: (context) {
                final jour = plusJours(lundi, i);
                final passe = !jour.isAfter(aujourdhui);
                final existe =
                    premierJour != null && !jour.isBefore(premierJour!);
                return _Jour(
                  jour: jour,
                  initiale: f.initialeJour(jour),
                  aujourdhui: jour == aujourdhui,
                  choisi: jour == choisi,
                  actif: passe && existe,
                  bilan: passe && existe ? journee(habitudes, jour) : null,
                  onTap: () => onChoisir(jour),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _Jour extends StatelessWidget {
  const _Jour({
    required this.jour,
    required this.initiale,
    required this.aujourdhui,
    required this.choisi,
    required this.actif,
    required this.bilan,
    required this.onTap,
  });

  final DateTime jour;
  final String initiale;
  final bool aujourdhui;
  final bool choisi;

  /// Passé (ou aujourd'hui) et après la première habitude : on peut
  /// l'afficher.
  final bool actif;
  final Journee? bilan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = bilan;
    final Color? point = b == null || b.vide
        ? null
        : b.complete
        ? (choisi ? RhythmCouleurs.noir : RhythmCouleurs.menthe)
        : b.entamee
        ? (choisi ? const Color(0x59000000) : const Color(0x73A6EFCB))
        : null;
    final texte = choisi
        ? RhythmCouleurs.noir
        : actif || aujourdhui
        ? RhythmCouleurs.texte
        : RhythmCouleurs.texte40;
    return Semantics(
      button: actif,
      selected: choisi,
      child: PressionEchelle(
        onTap: actif ? onTap : null,
        echelle: 0.94,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: choisi ? RhythmCouleurs.blanc : null,
            // Une capsule, pas une carte : la forme des barres du logo.
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: aujourdhui && !choisi
                  ? RhythmCouleurs.bordBouton
                  : const Color(0x00FFFFFF),
            ),
          ),
          child: Column(
            children: [
              Text(
                initiale,
                style: RhythmTypo.texte(
                  11,
                  couleur: choisi
                      ? RhythmCouleurs.noir
                      : RhythmCouleurs.texte64,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${jour.day}',
                style: RhythmTypo.texte(15, poids: 600, couleur: texte),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 5,
                height: 5,
                decoration: BoxDecoration(shape: BoxShape.circle, color: point),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// La série globale et le record.
class _Serie extends StatelessWidget {
  const _Serie({required this.serie, required this.record});

  final int serie;
  final int record;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return Row(
      children: [
        const Pastille(
          picto: Picto.flamme,
          couleur: RhythmCouleurs.corail,
          taille: 40,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.joursDaffilee(serie),
                style: RhythmTypo.texte(16, poids: 600),
              ),
              const SizedBox(height: 2),
              Text(tr.recordPersonnel(record), style: RhythmTypo.detail),
            ],
          ),
        ),
      ],
    );
  }
}

/// Une habitude du jour : la ligne ouvre la fiche, le cercle coche.
class _LigneHabitude extends StatelessWidget {
  const _LigneHabitude({
    super.key,
    required this.habitude,
    required this.jour,
    required this.aujourdhui,
    required this.premiere,
    required this.onBasculer,
    required this.onOuvrir,
    this.epinglee = false,
  });

  final Habitude habitude;
  final DateTime jour;
  final DateTime aujourdhui;

  /// La première ligne n'a pas de filet au-dessus d'elle.
  final bool premiere;

  /// Épinglée en tête : une épingle menthe à côté du nom.
  final bool epinglee;
  final VoidCallback onBasculer;
  final VoidCallback onOuvrir;

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final h = habitude;
    final faite = estFaite(h, jour);
    final n = serie(h, aujourdhui);
    return Column(
      children: [
        if (!premiere) const Filet(),
        Row(
          children: [
            Expanded(
              child: Semantics(
                button: true,
                label: h.nom,
                excludeSemantics: true,
                child: PressionEchelle(
                  onTap: onOuvrir,
                  echelle: 0.98,
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 58),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    child: Row(
                      children: [
                        PastilleHabitude(habitude: h),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      h.nom,
                                      style: RhythmTypo.texte(15, poids: 500),
                                    ),
                                  ),
                                  if (epinglee) ...[
                                    const SizedBox(width: 6),
                                    const PictoRhythm(
                                      Picto.epingle,
                                      taille: 14,
                                      epaisseur: 2.2,
                                      couleur: RhythmCouleurs.menthe,
                                    ),
                                  ],
                                ],
                              ),
                              if (h.detail.isNotEmpty || n >= 2) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    if (h.detail.isNotEmpty)
                                      Flexible(
                                        child: Text(
                                          h.detail,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: RhythmTypo.petit,
                                        ),
                                      ),
                                    if (n >= 2) ...[
                                      if (h.detail.isNotEmpty)
                                        const SizedBox(width: 8),
                                      const PictoRhythm(
                                        Picto.flamme,
                                        taille: 12,
                                        couleur: RhythmCouleurs.corail,
                                        epaisseur: 2.4,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        h.quotidienne
                                            ? tr.serieCourte(n)
                                            : tr.valeurFois(n),
                                        style: RhythmTypo.texte(
                                          12,
                                          poids: 600,
                                          couleur: RhythmCouleurs.corail,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            _Coche(faite: faite, libelle: h.nom, onTap: onBasculer),
          ],
        ),
      ],
    );
  }
}

/// Le cercle d'une habitude : vide, ou menthe coché (un petit rebond quand
/// il change). Cible de 48.
class _Coche extends StatelessWidget {
  const _Coche({
    required this.faite,
    required this.libelle,
    required this.onTap,
  });

  final bool faite;
  final String libelle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    checked: faite,
    label: libelle,
    excludeSemantics: true,
    child: PressionEchelle(
      onTap: onTap,
      echelle: 0.88,
      child: SizedBox.square(
        dimension: 48,
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (enfant, animation) => ScaleTransition(
              scale: animation,
              child: FadeTransition(opacity: animation, child: enfant),
            ),
            child: faite
                ? Container(
                    key: const ValueKey(true),
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: RhythmCouleurs.menthe,
                      shape: BoxShape.circle,
                    ),
                    child: const PictoRhythm(
                      Picto.coche,
                      taille: 16,
                      couleur: RhythmCouleurs.noir,
                      epaisseur: 2.6,
                    ),
                  )
                : Container(
                    key: const ValueKey(false),
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: RhythmCouleurs.cocheVide,
                        width: 2,
                      ),
                    ),
                  ),
          ),
        ),
      ),
    ),
  );
}

/// Une habitude qui n'est pas prévue ce jour-là : estompée, ses jours en
/// détail ; elle ouvre sa fiche.
class _LigneAutre extends StatelessWidget {
  const _LigneAutre({
    required this.habitude,
    required this.premiere,
    required this.onTap,
  });

  final Habitude habitude;
  final bool premiere;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final h = habitude;
    return Column(
      children: [
        if (!premiere) const Filet(),
        Semantics(
          button: true,
          label: h.nom,
          excludeSemantics: true,
          child: PressionEchelle(
            onTap: onTap,
            echelle: 0.98,
            child: Container(
              constraints: const BoxConstraints(minHeight: 56),
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Opacity(
                opacity: 0.6,
                child: Row(
                  children: [
                    PastilleHabitude(habitude: h),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(h.nom, style: RhythmTypo.texte(15, poids: 500)),
                          const SizedBox(height: 2),
                          Text(
                            context.formats.joursPrevus(h.jours, context.tr),
                            style: RhythmTypo.petit,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
