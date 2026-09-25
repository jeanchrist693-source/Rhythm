// lib/ecrans/alimentation/courses/panier_ecran.dart
//
// AU PANIER : le prix d'un article pris au magasin.
// - à l'unité (un compteur) ou AU POIDS (le prix au kg ou à la livre, le
//   poids) ;
// - le prix : le dernier payé ici est proposé ; le meilleur vu aussi ;
// - la TAXE, appliquée d'un toucher (l'utilisateur décide) : détaxé, TPS
//   seulement, TPS + TVQ — la suggestion d'après le nom, et pourquoi ;
// - la CONSIGNE (aucune, 10 ¢, 25 ¢ par contenant) ;
// - la ligne en direct : prix, taxes, consigne.
// « Au panier » ; déjà pris : « Retirer du panier ».

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_courses.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../modele/alimentation/taxes.dart';
import '../../../modele/etat_sante.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/suivi_clavier.dart';
import '../../../widgets/toast.dart';
import '../pieces_alimentation.dart';

class PanierEcran extends ConsumerStatefulWidget {
  const PanierEcran({super.key, required this.id, required this.retour});

  final String id;
  final String retour;

  @override
  ConsumerState<PanierEcran> createState() => _PanierEcranState();
}

class _PanierEcranState extends ConsumerState<PanierEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<PanierEcran> {
  late final ArticleListe? _article = ref
      .read(coursesProvider)
      .article(widget.id);
  final _prix = TextEditingController();
  final _poids = TextEditingController();
  final _focusPrix = FocusNode();
  final _focusPoids = FocusNode();

  late bool _auPoids;
  late bool _livres;
  late int _nombre;
  late StatutTaxe _statut;
  late double _consigne;
  late final Suggestion _suggestion;

  /// Le dernier prix vu ici (ou ailleurs), proposé.
  PrixVu? _dernier;
  PrixVu? _meilleur;

  static String _texte(double x) => x == x.roundToDouble()
      ? '${x.round()}'
      : x.toStringAsFixed(2).replaceAll('.', ',');

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focusPrix);
    surveillerClavier(_focusPoids);
    final a = _article;
    final etat = ref.read(coursesProvider);
    _suggestion = suggererStatut(
      a?.nom ?? '',
      a?.rayon.taxe ?? StatutTaxe.detaxe,
      nonAlimentaire: !(a?.rayon.alimentaire ?? true),
    );
    final historique = a == null
        ? const <PrixVu>[]
        : historiquePrix(etat.achats, a.nom);
    final magasin = etat.reglages.magasin;
    _dernier =
        historique.where((p) => p.magasin == magasin).firstOrNull ??
        historique.firstOrNull;
    _meilleur = meilleurPrix(historique);
    final p = a?.panier;
    if (p != null) {
      _auPoids = p.auPoids;
      _livres = p.livres;
      _nombre = p.auPoids ? 1 : p.nombre.round().clamp(1, 99);
      _statut = p.statut;
      _consigne = p.consigneUnitaire;
      _prix.text = _texte(p.prixUnitaire);
      if (p.auPoids) _poids.text = _texte(p.nombre);
    } else {
      final q = a?.quantites.firstOrNull;
      _auPoids =
          _dernier?.auPoids ??
          (q != null &&
              q.unite.famille == FamilleUnite.masse &&
              (a!.rayon == Rayon.fruits ||
                  a.rayon == Rayon.legumes ||
                  a.rayon == Rayon.viandes));
      _livres = false;
      _nombre = q != null && q.unite == Unite.unite
          ? q.valeur.round().clamp(1, 99)
          : 1;
      if (_auPoids && q != null && q.unite.famille == FamilleUnite.masse) {
        _poids.text = _texte(q.base / 1000);
      }
      _statut = _suggestion.statut;
      _consigne = consigneSuggeree(a?.nom ?? '');
    }
  }

  @override
  void dispose() {
    libererClavier();
    _prix.dispose();
    _poids.dispose();
    _focusPrix.dispose();
    _focusPoids.dispose();
    super.dispose();
  }

  /// Le prix unitaire tapé, sinon le dernier vu (converti kg ↔ lb).
  double? get _prixUnitaire {
    final tape = ChampNombre.lire(_prix);
    if (tape != null) return tape;
    final d = _dernier;
    if (d == null || d.auPoids != _auPoids) return null;
    return _auPoids && _livres ? d.prix * 0.453592 : d.prix;
  }

  LignePanier? get _ligne {
    final pu = _prixUnitaire;
    if (pu == null) return null;
    final n = _auPoids ? ChampNombre.lire(_poids) : _nombre.toDouble();
    if (n == null || n <= 0) return null;
    return LignePanier(
      prixUnitaire: pu,
      nombre: n,
      auPoids: _auPoids,
      livres: _livres,
      statut: _statut,
      consigneUnitaire: _consigne,
    );
  }

  void _auPanier() {
    if (transitionEnCours) return;
    final tr = context.tr;
    final l = _ligne;
    if (l == null) {
      montrerToast(context, _auPoids ? tr.prixEtPoidsRequis : tr.prixRequis);
      return;
    }
    ref.read(coursesProvider.notifier).mettreAuPanier(widget.id, l);
    HapticFeedback.lightImpact();
    retirerEcran(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final a = ref.watch(coursesProvider).article(widget.id) ?? _article;
    if (a == null) {
      return PageSecondaire(retour: widget.retour, enfants: const []);
    }
    final bareme = baremeAu(
      ref.watch(aujourdhuiProvider),
      ref.watch(coursesProvider).reglages.baremes,
    );
    final l = _ligne;
    final unite = _livres ? 'lb' : 'kg';
    final d = _dernier;

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: a.nom,
          surtitre: a.quantites.isEmpty
              ? null
              : Text(
                  tr.surLaListe(f.quantites(a.quantites, tr)),
                  style: RhythmTypo.surtitre,
                ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LigneReglage(
              libelle: tr.auPoids,
              detail: tr.auPoidsDetail,
              droite: Interrupteur(
                valeur: _auPoids,
                onChanged: (v) => setState(() {
                  _auPoids = v;
                  _prix.clear();
                }),
              ),
            ),
            if (_auPoids) ...[
              const SizedBox(height: 4),
              PucesChoix<bool>(
                options: [(false, tr.parKg), (true, tr.parLivre)],
                valeur: _livres,
                onChanged: (v) => setState(() => _livres = v),
              ),
            ] else
              LigneReglage(
                libelle: tr.combien,
                droite: CompteurRhythm(
                  valeur: _nombre,
                  min: 1,
                  max: 99,
                  largeurValeur: 44,
                  affichage: (v) => '$v',
                  onChanged: (v) => setState(() => _nombre = v),
                ),
              ),
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EtiquetteChamp(
                    _auPoids ? tr.prixParUnite(unite) : tr.prixUnitaire,
                  ),
                  ChampNombre(
                    controleur: _prix,
                    focus: _focusPrix,
                    decimales: 2,
                    suffixe: r'$',
                    indice: d == null || d.auPoids != _auPoids
                        ? null
                        : _texte(_livres ? d.prix * 0.453592 : d.prix),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ),
            ),
            if (_auPoids) ...[
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    EtiquetteChamp(tr.poids),
                    ChampNombre(
                      controleur: _poids,
                      focus: _focusPoids,
                      decimales: 3,
                      suffixe: unite,
                      actionClavier: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        if (d != null)
          Text(
            [
              tr.dernierPrixVu(
                d.auPoids ? tr.prixAuKg(f.prix(d.prix)) : f.prix(d.prix),
                d.magasin ?? tr.magasinInconnu,
                f.dateCourte(d.date),
              ),
              if (_meilleur != null && _meilleur!.prix < d.prix)
                tr.meilleurPrix(
                  _meilleur!.auPoids
                      ? tr.prixAuKg(f.prix(_meilleur!.prix))
                      : f.prix(_meilleur!.prix),
                  _meilleur!.magasin ?? tr.magasinInconnu,
                ),
            ].join('\n'),
            style: RhythmTypo.detail,
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.taxe),
            PucesChoix<StatutTaxe>(
              options: [for (final s in StatutTaxe.values) (s, s.libelle(tr))],
              valeur: _statut,
              onChanged: (s) => setState(() => _statut = s),
            ),
            const SizedBox(height: 8),
            Text(
              _statut == _suggestion.statut
                  ? _suggestion.raison.texte(tr)
                  : tr.taxeChoisie,
              style: RhythmTypo.detail,
            ),
          ],
        ),
        if (!_auPoids)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.consigne),
              PucesChoix<double>(
                options: [(0, tr.aucune), (0.10, '10 ¢'), (0.25, '25 ¢')],
                valeur: _consigne,
                onChanged: (c) => setState(() => _consigne = c),
              ),
              const SizedBox(height: 8),
              Text(tr.consigneAide, style: RhythmTypo.detail),
            ],
          ),
        if (l != null)
          Text(
            l.consigne > 0
                ? tr.ligneResume(
                    f.prix(l.prix),
                    f.prix(Caisse.avecTaxes(l.prix, l.statut, bareme) - l.prix),
                    f.prix(l.consigne),
                  )
                : tr.ligneResumeSansConsigne(
                    f.prix(l.prix),
                    f.prix(Caisse.avecTaxes(l.prix, l.statut, bareme) - l.prix),
                  ),
            style: RhythmTypo.texte(14, couleur: RhythmCouleurs.menthe),
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoutonPlein(
              libelle: l == null
                  ? tr.mettreAuPanier
                  : tr.mettreAuPanierPrix(
                      f.prix(
                        Caisse.avecTaxes(l.prix, l.statut, bareme) + l.consigne,
                      ),
                    ),
              largeurPleine: true,
              hauteur: 52,
              taillePolice: 15,
              onTap: _auPanier,
            ),
            if (a.auPanier) ...[
              const SizedBox(height: 12),
              BoutonSuppression(
                libelle: tr.retirerDuPanier,
                confirmation: tr.toucherPourRetirer,
                couleur: RhythmCouleurs.blanc,
                onConfirme: () {
                  ref.read(coursesProvider.notifier).retirerDuPanier(a.id);
                  retirerEcran(context);
                },
              ),
            ],
          ],
        ),
      ],
    );
  }
}
