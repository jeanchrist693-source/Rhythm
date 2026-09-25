// lib/ecrans/rappels/rappels_ecran.dart
//
// Rappels (la cloche de l'accueil, et « Rappels et notifications » en bas
// des Habitudes) : tout ce que Rhythm peut dire hors de l'app, en un
// endroit.
// - NOTIFICATIONS : leur état dans Android, et « Activer » (la demande
//   d'Android, puis ses réglages si elles ont été refusées) ; activées,
//   « Réglages » mène aux canaux d'Android (sons, écran verrouillé) ;
// - l'interrupteur général des rappels des habitudes ;
// - chaque habitude et son heure — la toucher ouvre son formulaire ;
// - le BILAN DU SOIR : ce qui reste à cocher, à l'heure choisie ;
// - les PERSONNES DE CONFIANCE, qu'« J'ai une envie » appelle d'un toucher ;
// - la promesse de discrétion (jamais le nom de ce dont on se libère, rien
//   ne quitte le téléphone).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/traductions.dart';
import '../../modele/etat_habitudes.dart';
import '../../modele/sports/etat_sport.dart';
import '../../modele/habitudes.dart';
import '../../navigation/transitions.dart';
import '../../systeme/notifications.dart';
import '../../systeme/synchro.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/boutons.dart';
import '../../widgets/filets.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/pictos.dart';
import '../../widgets/pression_echelle.dart';
import '../../widgets/suivi_clavier.dart';
import '../habitudes/habitude_formulaire_ecran.dart';
import '../habitudes/pieces_habitudes.dart';

class RappelsEcran extends ConsumerStatefulWidget {
  const RappelsEcran({super.key, this.retour});

  /// Le nom de l'écran d'où l'on vient (« Accueil » par défaut).
  final String? retour;

  @override
  ConsumerState<RappelsEcran> createState() => _RappelsEcranState();
}

class _RappelsEcranState extends ConsumerState<RappelsEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<RappelsEcran> {
  final _nom = TextEditingController();
  final _telephone = TextEditingController();
  final _focusNom = FocusNode();
  final _focusTelephone = FocusNode();

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focusNom);
    surveillerClavier(_focusTelephone);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(autorisationNotifsProvider.notifier).verifier();
    });
  }

  @override
  void dispose() {
    libererClavier();
    _nom.dispose();
    _telephone.dispose();
    _focusNom.dispose();
    _focusTelephone.dispose();
    super.dispose();
  }

  void _reglages(ReglagesHabitudes r) =>
      ref.read(habitudesProvider.notifier).modifierReglages(r);

  void _ajouterContact(ReglagesHabitudes r) {
    final nom = _nom.text.trim();
    final tel = _telephone.text.trim();
    if (nom.isEmpty || tel.isEmpty) return;
    HapticFeedback.lightImpact();
    _reglages(
      r.copierAvec(
        contacts: [
          ...r.contacts,
          Contact(nom: nom, telephone: tel),
        ],
      ),
    );
    _nom.clear();
    _telephone.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(habitudesProvider);
    final r = etat.reglages;
    final autorisation = ref.watch(autorisationNotifsProvider);
    final disponible = NotificationsSysteme.disponible;

    final actives = autorisation == true;
    final seances = [
      for (final p in ref.watch(sportProvider).programmes)
        if (p.jours.isNotEmpty) p,
    ];
    return PageSecondaire(
      retour: widget.retour ?? tr.navAccueil,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(titre: tr.rappels),
        if (disponible)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.notifications),
              LigneReglage(
                gauche: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: actives
                        ? RhythmCouleurs.menthe
                        : RhythmCouleurs.corail,
                    shape: BoxShape.circle,
                  ),
                  child: const PictoRhythm(
                    Picto.cloche,
                    taille: 16,
                    couleur: RhythmCouleurs.noir,
                    epaisseur: 2,
                  ),
                ),
                libelle: actives
                    ? tr.autorisationOk
                    : autorisation == false && r.autorisationDemandee
                    ? tr.autorisationRefusee
                    : tr.autorisationInconnue,
                detail: actives ? tr.notifsGererAide : tr.notifsActiverAide,
                droite: actives
                    ? BoutonContour(
                        libelle: tr.reglagesAndroid,
                        onTap: NotificationsSysteme.instance.ouvrirReglages,
                      )
                    : BoutonPlein(
                        libelle: tr.activer,
                        hauteur: 38,
                        taillePolice: 14,
                        onTap: () {
                          _reglages(r.copierAvec(autorisationDemandee: true));
                          ref
                              .read(autorisationNotifsProvider.notifier)
                              .demander(reglagesSiRefus: true);
                        },
                      ),
              ),
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LigneReglage(
              libelle: tr.rappelsHabitudes,
              detail: tr.rappelsHabitudesAide,
              droite: Interrupteur(
                valeur: r.rappels,
                onChanged: (v) {
                  _reglages(r.copierAvec(rappels: v));
                  if (v) assurerAutorisation(ref);
                },
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: r.rappels ? 1 : 0.4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final h in etat.habitudes) ...[
                    const Filet(),
                    LigneReglage(
                      gauche: PastilleHabitude(habitude: h, taille: 30),
                      libelle: h.nom,
                      valeur: h.rappel == null
                          ? tr.aucunRappel
                          : f.heureMinutes(h.rappel!),
                      onTap: () => pousserEcran(
                        context,
                        HabitudeFormulaireEcran(id: h.id),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(tr.toucherPourRegler, style: RhythmTypo.petit),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LigneReglage(
              libelle: tr.bilanDuSoir,
              detail: tr.bilanDuSoirAide,
              droite: Interrupteur(
                valeur: r.bilanSoir != null,
                onChanged: (v) {
                  _reglages(r.copierAvec(bilanSoir: () => v ? 21 * 60 : null));
                  if (v) assurerAutorisation(ref);
                },
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: r.bilanSoir == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: RouletteHeure(
                        minutes: r.bilanSoir!,
                        separateur: tr.separateurHeure,
                        onChanged: (m) =>
                            _reglages(r.copierAvec(bilanSoir: () => m)),
                      ),
                    ),
            ),
          ],
        ),
        if (seances.isNotEmpty)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: r.rappels ? 1 : 0.4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TitreSection(tr.canalSeancesNom),
                for (final (i, p) in seances.indexed) ...[
                  if (i > 0) const Filet(),
                  LigneReglage(
                    libelle: p.nom,
                    detail:
                        '${f.joursPrevus(p.jours, tr)} · '
                        '${f.heureMinutes(p.heure ?? 18 * 60)}',
                    droite: Interrupteur(
                      valeur: p.rappel,
                      onChanged: (v) {
                        ref
                            .read(sportProvider.notifier)
                            .enregistrerProgramme(p.copierAvec(rappel: v));
                        if (v) assurerAutorisation(ref);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.personnesConfiance),
            Text(tr.personnesConfianceAide, style: RhythmTypo.detail),
            const SizedBox(height: 8),
            for (var i = 0; i < r.contacts.length; i++) ...[
              if (i > 0) const Filet(),
              _LigneContact(
                contact: r.contacts[i],
                onRetirer: () {
                  HapticFeedback.selectionClick();
                  _reglages(
                    r.copierAvec(contacts: [...r.contacts]..removeAt(i)),
                  );
                },
              ),
            ],
            const SizedBox(height: 16),
            EtiquetteChamp(tr.champNom),
            ChampRhythm(
              controleur: _nom,
              focus: _focusNom,
              majuscules: TextCapitalization.words,
              actionClavier: TextInputAction.next,
            ),
            const SizedBox(height: 18),
            EtiquetteChamp(tr.champTelephone),
            ChampRhythm(
              controleur: _telephone,
              focus: _focusTelephone,
              clavier: TextInputType.phone,
              actionClavier: TextInputAction.done,
              onValider: (_) => _ajouterContact(r),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: BoutonContour(
                libelle: tr.ajouterPersonne,
                onTap: () => _ajouterContact(r),
              ),
            ),
          ],
        ),
        Text(tr.discretionTexte, style: RhythmTypo.petit),
      ],
    );
  }
}

class _LigneContact extends StatelessWidget {
  const _LigneContact({required this.contact, required this.onRetirer});

  final Contact contact;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          width: 30,
          height: 30,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: RhythmCouleurs.menthe,
            shape: BoxShape.circle,
          ),
          child: const PictoRhythm(
            Picto.telephone,
            taille: 15,
            couleur: RhythmCouleurs.noir,
            epaisseur: 2,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(contact.nom, style: RhythmTypo.texte(15, poids: 500)),
              Text(contact.telephone, style: RhythmTypo.petit),
            ],
          ),
        ),
        Semantics(
          button: true,
          child: PressionEchelle(
            onTap: onRetirer,
            echelle: 0.9,
            child: const SizedBox.square(
              dimension: 44,
              child: Center(
                child: PictoRhythm(
                  Picto.moins,
                  taille: 18,
                  couleur: RhythmCouleurs.texte64,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
