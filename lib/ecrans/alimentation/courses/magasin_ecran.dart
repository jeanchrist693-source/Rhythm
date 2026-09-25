// lib/ecrans/alimentation/courses/magasin_ecran.dart
//
// AU MAGASIN : l'écran reste ALLUMÉ ; le magasin choisi en capsules ; ce
// qui reste à prendre, par rayon dans l'ordre du magasin — toucher un
// article le met au panier avec son prix (`panier_ecran.dart`) ; un article
// imprévu s'ajoute en passant ; ce qui est DANS LE PANIER, avec son prix,
// sa taxe, sa consigne. En bas, fixe, LE TOTAL À LA CAISSE (sous-total,
// TPS, TVQ, consigne) et ce qui reste du budget du mois : plus de
// surprise. « Terminer » (deux temps) enregistre l'épicerie puis cède la
// place au RANGEMENT.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_courses.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/base_aliments.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/rayons.dart';
import '../../../modele/alimentation/taxes.dart';
import '../../../modele/etat_sante.dart';
import '../../../navigation/transitions.dart';
import '../../../systeme/ecran_allume.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pression_echelle.dart';
import '../../../widgets/suivi_clavier.dart';
import '../../../widgets/toast.dart';
import 'panier_ecran.dart';
import 'pieces_courses.dart';
import 'ranger_ecran.dart';

class MagasinEcran extends ConsumerStatefulWidget {
  const MagasinEcran({super.key, required this.retour});

  final String retour;

  @override
  ConsumerState<MagasinEcran> createState() => _MagasinEcranState();
}

class _MagasinEcranState extends ConsumerState<MagasinEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<MagasinEcran> {
  final _saisie = TextEditingController();
  final _focus = FocusNode();
  bool _arme = false;
  Timer? _desarmement;

  /// La hauteur de la barre de la caisse (le bas de la liste passe dessus).
  static const double _hauteurCaisse = 150;

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focus);
    garderEcranAllume(true);
  }

  @override
  void dispose() {
    garderEcranAllume(false);
    _desarmement?.cancel();
    libererClavier();
    _saisie.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _ajouter() {
    final (nom, q) = lireSaisie(_saisie.text);
    if (nom.isEmpty) return;
    final base = ref.read(baseAlimentsProvider).value;
    final (article, _) = ref
        .read(coursesProvider.notifier)
        .ajouter(nom, rayon: rayonDe(nom, base), quantite: q);
    setState(_saisie.clear);
    HapticFeedback.lightImpact();
    // Pris à l'instant : son prix tout de suite.
    pousserEcran(
      context,
      PanierEcran(id: article.id, retour: context.tr.auMagasin),
    );
  }

  void _terminer(String? magasin) {
    final tr = context.tr;
    if (!_arme) {
      HapticFeedback.selectionClick();
      setState(() => _arme = true);
      _desarmement?.cancel();
      _desarmement = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _arme = false);
      });
      return;
    }
    _desarmement?.cancel();
    final achat = ref.read(coursesProvider.notifier).terminer(magasin: magasin);
    if (achat == null) {
      setState(() => _arme = false);
      montrerToast(context, tr.panierVide);
      return;
    }
    HapticFeedback.heavyImpact();
    remplacerEcran(context, RangerEcran(achat: achat, retour: widget.retour));
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(coursesProvider);
    final maintenant = ref.watch(aujourdhuiProvider);
    final reglages = etat.reglages;
    final magasin = reglages.magasin;
    final aPrendre = [
      for (final a in etat.liste)
        if (!a.auPanier) a,
    ];
    final panier = [
      for (final a in etat.liste)
        if (a.auPanier) a,
    ];
    final caisse = caisseDuPanier(
      panier,
      baremeAu(maintenant, etat.reglages.baremes),
    );
    final budget = reglages.budgetMois;
    final titre = tr.auMagasin;

    String? estimation(ArticleListe a) {
      final h = historiquePrix(etat.achats, a.nom);
      if (h.isEmpty) return null;
      final ici = h.where((p) => p.magasin == magasin).firstOrNull ?? h.first;
      final p = f.prix(ici.prix);
      return ici.auPoids ? tr.environPrixKg(p) : tr.environPrix(p);
    }

    final page = PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier + _hauteurCaisse,
      enfants: [
        TitreSecondaire(
          titre: titre,
          surtitre: Text(
            aPrendre.isEmpty
                ? tr.toutEstPris
                : tr.resteAPrendre(aPrendre.length),
            style: RhythmTypo.texte(
              14,
              poids: 600,
              couleur: RhythmCouleurs.menthe,
            ),
          ),
        ),
        PucesChoix<String?>(
          options: [for (final m in reglages.magasins) (m, m)],
          valeur: magasin,
          onChanged: (m) => ref
              .read(coursesProvider.notifier)
              .choisirMagasin(m == magasin ? null : m),
        ),
        for (final (rayon, articles) in parRayon(
          aPrendre,
          reglages.ordreRayons,
        ))
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(rayon.libelle(tr)),
              for (final (i, a) in articles.indexed)
                LigneCourse(
                  filet: i > 0,
                  coche: false,
                  nom: a.nom,
                  detail: [
                    if (a.quantites.isNotEmpty) f.quantites(a.quantites, tr),
                    if (a.note != null) a.note!,
                  ].join(' · '),
                  valeur: estimation(a),
                  onTap: () => pousserEcran(
                    context,
                    PanierEcran(id: a.id, retour: titre),
                  ),
                ),
            ],
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: ChampRhythm(
                controleur: _saisie,
                focus: _focus,
                indice: tr.indiceImprevu,
                actionClavier: TextInputAction.done,
                onValider: (_) => _ajouter(),
              ),
            ),
          ],
        ),
        if (panier.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(
                tr.dansLePanier(panier.length),
                couleur: RhythmCouleurs.menthe,
              ),
              for (final (i, a) in panier.indexed)
                LigneCourse(
                  filet: i > 0,
                  coche: true,
                  nom: a.nom,
                  detail: _detailPanier(a.panier!, f, tr),
                  valeur: f.prix(a.panier!.prix),
                  onTap: () => pousserEcran(
                    context,
                    PanierEcran(id: a.id, retour: titre),
                  ),
                ),
            ],
          ),
      ],
    );

    return Stack(
      children: [
        page,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: BarreCaisse(
            caisse: caisse,
            budgetRestant: budget == null
                ? null
                : budget -
                      depenseDuMois(etat.achats, maintenant) -
                      caisse.total,
            bouton: Semantics(
              button: true,
              child: PressionEchelle(
                onTap: () => _terminer(magasin),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 48,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _arme ? RhythmCouleurs.menthe : RhythmCouleurs.blanc,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    _arme ? tr.toucherPourTerminer : tr.terminer,
                    style: RhythmTypo.texte(
                      14,
                      poids: 600,
                      couleur: RhythmCouleurs.noir,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// « 6 × 1,29 $ · TPS + TVQ · consigne 0,60 $ », « 1,2 kg à 1,69 $ / kg ».
String _detailPanier(LignePanier p, Formats f, AppLocalizations tr) => [
  if (p.auPoids)
    tr.poidsAPrix(
      '${f.decimal(p.nombre)} ${p.livres ? 'lb' : 'kg'}',
      '${f.prix(p.prixUnitaire)} / ${p.livres ? 'lb' : 'kg'}',
    )
  else if (p.nombre != 1)
    '${f.decimal(p.nombre)} × ${f.prix(p.prixUnitaire)}',
  p.statut.libelle(tr),
  if (p.consigne > 0) tr.consigneValeur(f.prix(p.consigne)),
].join(' · ');
