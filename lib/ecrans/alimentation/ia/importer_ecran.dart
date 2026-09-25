// lib/ecrans/alimentation/ia/importer_ecran.dart
//
// IMPORTER UNE RECETTE (palier 4) : le texte d'une recette collé (un site,
// un courriel, une photo transcrite) — « Coller » le prend du presse-
// papiers. L'IA le STRUCTURE sans rien inventer (ingrédients, quantités en
// métrique, étapes, temps, portions, région) ; la recette s'ouvre ensuite
// comme une idée (`RecetteProposeeEcran`) : ce qu'une portion apporte,
// calculé par la base, puis « Ajouter à mon livre ».

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ia/ia_alimentation.dart';
import '../../../l10n/traductions.dart';
import '../../../navigation/transitions.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/formulaire.dart';
import '../../../widgets/page_secondaire.dart';
import '../../../widgets/pictos.dart';
import '../../../widgets/suivi_clavier.dart';
import '../../../widgets/toast.dart';
import 'pieces_ia.dart';
import 'recette_proposee_ecran.dart';

class ImporterEcran extends ConsumerStatefulWidget {
  const ImporterEcran({super.key, required this.retour});

  final String retour;

  @override
  ConsumerState<ImporterEcran> createState() => _ImporterEcranState();
}

class _ImporterEcranState extends ConsumerState<ImporterEcran>
    with
        WidgetsBindingObserver,
        SuiviClavierMixin<ImporterEcran>,
        AppelIa<ImporterEcran> {
  final _texte = TextEditingController();
  final _focus = FocusNode();

  /// Le texte n'était pas une recette.
  bool _pasUneRecette = false;

  @override
  void initState() {
    super.initState();
    surveillerClavier(_focus);
  }

  @override
  void dispose() {
    libererClavier();
    _texte.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _coller() async {
    final d = await Clipboard.getData(Clipboard.kTextPlain);
    final t = d?.text?.trim() ?? '';
    if (!mounted) return;
    if (t.isEmpty) {
      montrerToast(context, context.tr.iaPressePapiersVide);
      return;
    }
    setState(() {
      _texte.text = t;
      _pasUneRecette = false;
    });
  }

  Future<void> _importer() async {
    final tr = context.tr;
    final texte = _texte.text.trim();
    if (texte.length < 40) {
      montrerToast(context, tr.iaTexteTropCourt);
      return;
    }
    setState(() => _pasUneRecette = false);
    final francais = Localizations.localeOf(context).languageCode == 'fr';
    // Le texte est borné (une page de recette) : le quota reste raisonnable.
    final borne = texte.length > 12000 ? texte.substring(0, 12000) : texte;
    final r = await appeler(
      () async => (await importer(borne, francais: francais),),
    );
    if (r == null || !mounted) return;
    final recette = r.$1;
    if (recette == null) {
      setState(() => _pasUneRecette = true);
      return;
    }
    HapticFeedback.lightImpact();
    pousserEcran(
      context,
      RecetteProposeeEcran(proposition: recette, retour: tr.iaImporter),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: tr.iaImporter,
          surtitre: Text(tr.iaImporterSurtitre, style: RhythmTypo.surtitre),
        ),
        Column(
          key: const ValueKey('texte'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            EtiquetteChamp(
              tr.iaTexteDeLaRecette,
              droite: BoutonCapsule(
                picto: Picto.liste,
                libelle: tr.iaColler,
                hauteur: 36,
                onTap: _coller,
              ),
            ),
            ChampRhythm(
              controleur: _texte,
              focus: _focus,
              indice: tr.iaIndiceImport,
              lignes: 12,
              onChanged: (_) {
                if (_pasUneRecette) setState(() => _pasUneRecette = false);
              },
            ),
          ],
        ),
        BoutonPlein(
          libelle: tr.iaStructurer,
          largeurPleine: true,
          hauteur: 52,
          taillePolice: 15,
          onTap: _importer,
        ),
        if (enCours)
          AttenteIa(message: tr.iaAttenteImport)
        else if (erreur != null)
          ErreurIaBloc(erreur: erreur, onReessayer: _importer)
        else if (_pasUneRecette)
          Text(
            tr.iaPasUneRecette,
            style: RhythmTypo.texte(14, couleur: RhythmCouleurs.corail),
          ),
        Text(tr.iaImporterAide, style: RhythmTypo.petit),
        const MentionIa(),
      ],
    );
  }
}
