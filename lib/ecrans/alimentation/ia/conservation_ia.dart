// lib/ecrans/alimentation/ia/conservation_ia.dart
//
// La CONSERVATION d'un aliment HORS DU GUIDE (palier 4) : le guide
// embarqué (Thermoguide du MAPAQ) connaît environ 120 aliments ; pour les
// autres (« kombucha », « kimchi », « tempeh »), « Comment le garder ? »
// demande à l'IA — une fois : le repère est GARDÉ
// (`CoursesNotifier.apprendreConservation`) et sert ensuite partout
// (rangement, fiche, déplacement), dit « repère de l'IA ».

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ia/ia_alimentation.dart';
import '../../../l10n/traductions.dart';
import '../../../modele/alimentation/conservation.dart';
import '../../../modele/alimentation/courses.dart';
import '../../../modele/alimentation/etat_courses.dart';
import '../../../theme/rhythm_couleurs.dart';
import '../../../theme/rhythm_typo.dart';
import '../../../widgets/boutons.dart';
import '../../../widgets/pictos.dart';
import 'pieces_ia.dart';

/// « Comment le garder ? » pour [nom] : l'IA répond, le repère est gardé,
/// [onAppris] le reçoit (pour recalculer la date proposée).
class DemandeConservation extends ConsumerStatefulWidget {
  const DemandeConservation({
    super.key,
    required this.nom,
    required this.rayon,
    this.onAppris,
  });

  final String nom;
  final Rayon rayon;
  final ValueChanged<Conservation>? onAppris;

  @override
  ConsumerState<DemandeConservation> createState() =>
      _DemandeConservationState();
}

class _DemandeConservationState extends ConsumerState<DemandeConservation>
    with AppelIa<DemandeConservation> {
  Future<void> _demander() async {
    final francais = Localizations.localeOf(context).languageCode == 'fr';
    final nom = widget.nom.trim();
    final c = await appeler(
      () => conservationIa(nom, widget.rayon, francais: francais),
    );
    if (c == null || !mounted) return;
    HapticFeedback.lightImpact();
    ref.read(coursesProvider.notifier).apprendreConservation(nom, c);
    widget.onAppris?.call(c);
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    if (enCours) return AttenteIa(message: tr.iaAttenteConservation);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(tr.iaHorsDuGuide, style: RhythmTypo.petit),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: BoutonCapsule(
            picto: Picto.etincelles,
            libelle: tr.iaCommentLeGarder,
            hauteur: 40,
            onTap: _demander,
          ),
        ),
        if (erreur != null) ...[
          const SizedBox(height: 10),
          Text(
            messageErreurIa(tr, erreur),
            style: RhythmTypo.texte(13, couleur: RhythmCouleurs.corail),
          ),
        ],
      ],
    );
  }
}

/// Le repère affiché vient de l'IA (pas du guide) : on le dit.
bool repereDeLIa(String nom, Map<String, Conservation> apprises) =>
    guideDe(nom) == null && apprises.containsKey(cleConservation(nom));
