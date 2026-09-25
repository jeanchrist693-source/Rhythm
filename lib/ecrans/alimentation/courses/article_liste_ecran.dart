// lib/ecrans/alimentation/courses/article_liste_ecran.dart
//
// UN ARTICLE DE LA LISTE : son nom, sa quantité (et son unité), son rayon,
// une note ; d'où il vient ; les PRIX VUS (le dernier, le meilleur, par
// magasin) ; « Retirer de la liste » en deux temps.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/libelles_courses.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/calculs_courses.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/filets.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/suivi_clavier.dart';
import '../pieces_alimentation.dart';

class ArticleListeEcran extends ConsumerStatefulWidget {
  const ArticleListeEcran({super.key, required this.id, required this.retour});

  final String id;
  final String retour;

  @override
  ConsumerState<ArticleListeEcran> createState() => _ArticleListeEcranState();
}

class _ArticleListeEcranState extends ConsumerState<ArticleListeEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<ArticleListeEcran> {
  late final ArticleListe? _depart = ref
      .read(coursesProvider)
      .article(widget.id);
  late final _nom = TextEditingController(text: _depart?.nom ?? '');
  late final _quantite = TextEditingController(
    text: _depart == null || _depart.quantites.length != 1
        ? ''
        : _texte(_depart.quantites.first.valeur),
  );
  late final _note = TextEditingController(text: _depart?.note ?? '');
  final _focus = List.generate(3, (_) => FocusNode());
  late Unite _unite = _depart != null && _depart.quantites.length == 1
      ? _depart.quantites.first.unite
      : Unite.unite;
  late Rayon _rayon = _depart?.rayon ?? Rayon.autre;

  static String _texte(double x) =>
      x == x.roundToDouble() ? '${x.round()}' : '$x'.replaceAll('.', ',');

  @override
  void initState() {
    super.initState();
    for (final f in _focus) {
      surveillerClavier(f);
    }
  }

  @override
  void dispose() {
    libererClavier();
    _nom.dispose();
    _quantite.dispose();
    _note.dispose();
    for (final f in _focus) {
      f.dispose();
    }
    super.dispose();
  }

  void _enregistrer(ArticleListe a) {
    if (transitionEnCours) return;
    final nom = _nom.text.trim();
    final v = ChampNombre.lire(_quantite);
    // Plusieurs quantités fusionnées (« 2 + 150 g ») : gardées tant qu'on
    // n'en tape pas une nouvelle.
    final quantites = v != null && v > 0
        ? [Quantite(v, _unite)]
        : (_quantite.text.trim().isEmpty && a.quantites.length > 1
              ? a.quantites
              : const <Quantite>[]);
    ref
        .read(coursesProvider.notifier)
        .modifierArticle(
          a.copierAvec(
            nom: nom.isEmpty ? a.nom : nom,
            rayon: _rayon,
            quantites: quantites,
            note: () => _note.text.trim().isEmpty ? null : _note.text.trim(),
          ),
        );
    HapticFeedback.selectionClick();
    retirerEcran(context);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final f = context.formats;
    final etat = ref.watch(coursesProvider);
    final a = etat.article(widget.id) ?? _depart;
    if (a == null) {
      return PageSecondaire(retour: widget.retour, enfants: const []);
    }
    final prix = historiquePrix(etat.achats, a.nom);
    final meilleur = meilleurPrix(prix);

    String unite(Unite u) =>
        u.symbole ?? (u == Unite.paquet ? tr.unitePaquet : tr.uniteUnite);

    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: a.nom,
          surtitre: a.origines.isEmpty
              ? null
              : Text(
                  tr.pourOrigines(a.origines.join(', ')),
                  style: RhythmTypo.surtitre,
                ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.nomProduit),
            ChampRhythm(
              controleur: _nom,
              focus: _focus[0],
              actionClavier: TextInputAction.next,
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.quantite),
            if (a.quantites.length > 1) ...[
              Text(
                tr.quantitesFusionnees(f.quantites(a.quantites, tr)),
                style: RhythmTypo.detail,
              ),
              const SizedBox(height: 10),
            ],
            ChampNombre(
              controleur: _quantite,
              focus: _focus[1],
              indice: a.quantites.length > 1 ? tr.nouvelleQuantite : '1',
              decimales: 2,
            ),
            const SizedBox(height: 12),
            PucesChoix<Unite>(
              options: [for (final u in Unite.values) (u, unite(u))],
              valeur: _unite,
              onChanged: (u) => setState(() => _unite = u),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitreSection(tr.rayon),
            PucesChoix<Rayon>(
              options: [for (final r in Rayon.values) (r, r.libelle(tr))],
              valeur: _rayon,
              onChanged: (r) => setState(() => _rayon = r),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(tr.note),
            ChampRhythm(
              controleur: _note,
              focus: _focus[2],
              indice: tr.indiceNoteArticle,
              lignes: 3,
            ),
          ],
        ),
        if (prix.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TitreSection(tr.prixVus),
              if (meilleur != null) ...[
                Text(
                  tr.meilleurPrix(
                    _prix(f, tr, meilleur.prix, meilleur.auPoids),
                    meilleur.magasin ?? tr.magasinInconnu,
                  ),
                  style: RhythmTypo.texte(14, couleur: RhythmCouleurs.menthe),
                ),
                const SizedBox(height: 8),
              ],
              for (final (i, p) in prix.take(6).indexed) ...[
                if (i > 0) const Filet(),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${f.dateCourte(p.date)} · '
                          '${p.magasin ?? tr.magasinInconnu}',
                          style: RhythmTypo.detail,
                        ),
                      ),
                      Text(
                        _prix(f, tr, p.prix, p.auPoids),
                        style: RhythmTypo.texte(14),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            BoutonPlein(
              libelle: tr.enregistrer,
              largeurPleine: true,
              hauteur: 52,
              taillePolice: 15,
              onTap: () => _enregistrer(a),
            ),
            const SizedBox(height: 12),
            BoutonSuppression(
              libelle: tr.retirerDeLaListe,
              confirmation: tr.toucherPourRetirer,
              onConfirme: () {
                ref.read(coursesProvider.notifier).retirerArticle(a.id);
                retirerEcran(context);
              },
            ),
          ],
        ),
      ],
    );
  }
}

/// « 4,99 $ » ou « 13,20 $ / kg ».
String _prix(Formats f, AppLocalizations tr, double prix, bool auPoids) =>
    auPoids ? tr.prixAuKg(f.prix(prix)) : f.prix(prix);
