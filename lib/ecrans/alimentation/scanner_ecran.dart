// lib/ecrans/alimentation/scanner_ecran.dart
//
// SCANNER UN CODE-BARRES : la caméra lit le code (sur le téléphone, sans
// réseau), sa clé de contrôle est vérifiée, puis :
// - un produit DÉJÀ dans « Mes produits » (même code) s'ouvre aussitôt, hors
//   ligne ;
// - sinon, le code (seulement lui) est cherché dans OPEN FOOD FACTS : le
//   produit s'ouvre dans le formulaire, PRÉ-REMPLI (nom, marque, portion,
//   valeur nutritive), à vérifier avec l'étiquette avant de l'enregistrer ;
// - inconnu d'Open Food Facts : « Le créer à la main », son code gardé.
// Depuis « Noter un repas », le produit enregistré enchaîne sur sa portion
// ([noter]) ; depuis « Mes produits », il y reste.
//
// Sans caméra (refusée, absente) : les chiffres se tapent sous le cadre. La
// caméra s'arrête pendant la recherche et quand l'app passe derrière.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../l10n/traductions.dart';
import '../../modele/alimentation/alimentation.dart';
import '../../modele/alimentation/etat_alimentation.dart';
import '../../modele/alimentation/open_food_facts.dart';
import '../../modele/modeles.dart';
import '../../navigation/transitions.dart';
import '../../systeme/open_food_facts.dart';
import '../../theme/rhythm_couleurs.dart';
import '../../theme/rhythm_typo.dart';
import '../../widgets/boutons.dart';
import '../../widgets/formulaire.dart';
import '../../widgets/page_secondaire.dart';
import '../../widgets/suivi_clavier.dart';
import '../../widgets/toast.dart';
import 'ia/pieces_ia.dart';
import 'portion_ecran.dart';
import 'produit_formulaire_ecran.dart';

enum _Etat { scan, recherche, inconnu, erreur }

class ScannerEcran extends ConsumerStatefulWidget {
  const ScannerEcran({super.key, required this.retour, this.noter});

  final String retour;

  /// Pour noter un repas : le jour et le moment (le produit trouvé s'ouvre
  /// à sa portion) ; `null` : « Mes produits » (sa fiche s'ouvre).
  final (DateTime, MomentRepas)? noter;

  /// Faux dans les tests (pas de caméra) : seule la saisie des chiffres.
  static bool camera = true;

  @override
  ConsumerState<ScannerEcran> createState() => _ScannerEcranState();
}

class _ScannerEcranState extends ConsumerState<ScannerEcran>
    with WidgetsBindingObserver, SuiviClavierMixin<ScannerEcran> {
  late final MobileScannerController? _camera = ScannerEcran.camera
      ? MobileScannerController(
          formats: const [
            BarcodeFormat.ean13,
            BarcodeFormat.ean8,
            BarcodeFormat.upcA,
            BarcodeFormat.upcE,
          ],
        )
      : null;
  final _saisie = TextEditingController();
  final _focus = FocusNode();

  _Etat _etat = _Etat.scan;
  String? _code;
  ErreurOff? _erreur;

  @override
  void initState() {
    super.initState();
    // Inscrit aussi l'écran aux changements de l'app (la caméra, plus bas).
    surveillerClavier(_focus);
  }

  @override
  void dispose() {
    libererClavier();
    _saisie.dispose();
    _focus.dispose();
    _camera?.dispose();
    super.dispose();
  }

  /// La caméra s'arrête quand l'app passe derrière, reprend au retour.
  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    final camera = _camera;
    if (camera == null || _etat != _Etat.scan) return;
    if (etat == AppLifecycleState.resumed) {
      camera.start();
    } else if (etat == AppLifecycleState.inactive ||
        etat == AppLifecycleState.paused) {
      camera.stop();
    }
  }

  void _detecte(BarcodeCapture capture) {
    if (_etat != _Etat.scan) return;
    for (final b in capture.barcodes) {
      final brut = b.rawValue;
      if (brut == null) continue;
      final code = normaliserCode(brut, upcE: b.format == BarcodeFormat.upcE);
      if (code != null) {
        _trouver(code);
        return;
      }
    }
  }

  void _chercherSaisie() {
    final code = normaliserCode(_saisie.text);
    if (code == null) {
      montrerToast(context, context.tr.scannerCodeInvalide);
      return;
    }
    fermerClavier(context);
    _trouver(code);
  }

  Future<void> _trouver(String code) async {
    HapticFeedback.mediumImpact();
    final local = ref.read(alimentationProvider).produitDuCode(code);
    if (local != null) {
      _ouvrirProduit(local);
      return;
    }
    setState(() {
      _etat = _Etat.recherche;
      _code = code;
      _erreur = null;
    });
    try {
      final brouillon = await ServiceOff.instance.chercher(code);
      if (!mounted) return;
      if (brouillon == null) {
        setState(() => _etat = _Etat.inconnu);
      } else {
        _ouvrirFormulaire(brouillon: brouillon);
      }
    } on ExceptionOff catch (e) {
      if (!mounted) return;
      setState(() {
        _etat = _Etat.erreur;
        _erreur = e.erreur;
      });
    }
  }

  void _relancer() {
    setState(() {
      _etat = _Etat.scan;
      _code = null;
      _erreur = null;
    });
  }

  /// Noter un repas : la portion du produit ; « Mes produits » : sa fiche.
  void _ouvrirProduit(Produit p) {
    final noter = widget.noter;
    remplacerEcran(
      context,
      noter == null
          ? ProduitFormulaireEcran(retour: widget.retour, produit: p)
          : PortionEcran.produit(
              produit: p,
              jour: noter.$1,
              moment: noter.$2,
              retour: widget.retour,
            ),
    );
  }

  void _ouvrirFormulaire({BrouillonOff? brouillon, String? code}) {
    final noter = widget.noter;
    remplacerEcran(
      context,
      ProduitFormulaireEcran(
        retour: widget.retour,
        brouillon: brouillon,
        codeBarres: code,
        apres: noter == null
            ? null
            : (ctx, p) => remplacerEcran(
                ctx,
                PortionEcran.produit(
                  produit: p,
                  jour: noter.$1,
                  moment: noter.$2,
                  retour: widget.retour,
                ),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final code = _code;
    return PageSecondaire(
      retour: widget.retour,
      controleur: defilementClavier,
      basSupplementaire: paddingBasClavier,
      enfants: [
        TitreSecondaire(
          titre: tr.scannerCodeBarres,
          surtitre: Text(tr.scannerSurtitre, style: RhythmTypo.surtitre),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(aspectRatio: 4 / 3, child: _fenetre(tr)),
            const SizedBox(height: 10),
            if (code != null)
              Text(
                tr.codeBarresNumero(codeLisible(code)),
                style: RhythmTypo.detail,
              )
            else
              Row(
                children: [
                  Expanded(
                    child: Text(tr.scannerCadre, style: RhythmTypo.detail),
                  ),
                  if (_camera case final camera?)
                    BoutonContour(
                      libelle: tr.scannerLampe,
                      hauteur: 36,
                      onTap: camera.toggleTorch,
                    ),
                ],
              ),
          ],
        ),
        if (_etat != _Etat.scan) _etatRecherche(tr),
        if (_etat == _Etat.scan)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EtiquetteChamp(tr.scannerTaperCode),
              ChampRhythm(
                controleur: _saisie,
                focus: _focus,
                indice: '0 12345 67890 5',
                clavier: TextInputType.number,
                formateurs: [
                  FilteringTextInputFormatter.allow(RegExp('[0-9 ]')),
                ],
                actionClavier: TextInputAction.search,
                onValider: (_) => _chercherSaisie(),
              ),
              const SizedBox(height: 14),
              BoutonContour(
                libelle: tr.scannerChercher,
                onTap: _chercherSaisie,
              ),
            ],
          ),
        Text(tr.scannerMention, style: RhythmTypo.petit),
      ],
    );
  }

  /// La caméra et son cadre ; pendant la recherche, l'attente.
  Widget _fenetre(AppLocalizations tr) {
    final camera = _camera;
    if (_etat == _Etat.recherche) {
      return Center(child: AttenteIa(message: tr.scannerRecherche));
    }
    if (camera == null || _etat != _Etat.scan) {
      return const ColoredBox(
        color: Colors.black,
        child: CustomPaint(painter: _Cadre()),
      );
    }
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          MobileScanner(
            controller: camera,
            onDetect: _detecte,
            errorBuilder: (context, e) => ColoredBox(
              color: Colors.black,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    e.errorCode == MobileScannerErrorCode.permissionDenied
                        ? tr.scannerCameraRefusee
                        : tr.scannerCameraIndisponible,
                    textAlign: TextAlign.center,
                    style: RhythmTypo.texte(14),
                  ),
                ),
              ),
            ),
          ),
          const IgnorePointer(child: CustomPaint(painter: _Cadre())),
        ],
      ),
    );
  }

  Widget _etatRecherche(AppLocalizations tr) => switch (_etat) {
    _Etat.inconnu => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr.scannerInconnu,
          style: RhythmTypo.titre(19, poids: 500, hauteur: 1.3),
        ),
        const SizedBox(height: 8),
        Text(tr.scannerInconnuDetail, style: RhythmTypo.detail),
        const SizedBox(height: 18),
        BoutonPlein(
          libelle: tr.scannerCreerMain,
          largeurPleine: true,
          hauteur: 52,
          taillePolice: 15,
          onTap: () => _ouvrirFormulaire(code: _code),
        ),
        const SizedBox(height: 12),
        BoutonContour(libelle: tr.scannerAutreCode, onTap: _relancer),
      ],
    ),
    _Etat.erreur => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _erreur == ErreurOff.reseau
              ? tr.scannerHorsLigne
              : tr.scannerErreurService,
          style: RhythmTypo.texte(14, couleur: RhythmCouleurs.corail),
        ),
        const SizedBox(height: 14),
        BoutonPlein(
          libelle: tr.reessayer,
          largeurPleine: true,
          onTap: () {
            final code = _code;
            if (code != null) _trouver(code);
          },
        ),
        const SizedBox(height: 12),
        BoutonContour(libelle: tr.scannerAutreCode, onTap: _relancer),
      ],
    ),
    _ => const SizedBox.shrink(),
  };
}

/// Le CADRE où placer le code : quatre coins, rien d'autre (ni boîte ni
/// lueur).
class _Cadre extends CustomPainter {
  const _Cadre();

  @override
  void paint(Canvas canvas, Size size) {
    final l = size.width * 0.72, h = size.height * 0.46;
    final r = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: l,
      height: h,
    );
    final c = h * 0.22;
    final p = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    for (final (o, dx, dy) in [
      (r.topLeft, 1.0, 1.0),
      (r.topRight, -1.0, 1.0),
      (r.bottomLeft, 1.0, -1.0),
      (r.bottomRight, -1.0, -1.0),
    ]) {
      canvas
        ..drawLine(o, o + Offset(c * dx, 0), p)
        ..drawLine(o, o + Offset(0, c * dy), p);
    }
  }

  @override
  bool shouldRepaint(_Cadre ancien) => false;
}
