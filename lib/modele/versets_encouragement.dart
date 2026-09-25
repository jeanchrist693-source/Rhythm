// lib/modele/versets_encouragement.dart
//
// Les versets qui soutiennent les habitudes (Louis Segond 1910, domaine
// public), rangés par besoin : la FORCE quand l'envie monte (« J'ai une
// envie »), la LIBERTÉ aux paliers d'une libération, SE RELEVER après une
// rechute, PERSÉVÉRER pour les habitudes à construire. Le verset change
// chaque jour, stable dans la journée. Contenu (donnée) : en français,
// typographie française (insécables avant « ; : ! ? »).

import '../utils/dates.dart';
import 'modeles.dart';

enum Soutien { force, liberte, relever, perseverer }

abstract final class VersetsEncouragement {
  static const String _lsg = 'Louis Segond';

  static const Map<Soutien, List<Verset>> parSoutien = {
    Soutien.force: [
      Verset(
        texte:
            "Aucune tentation ne vous est survenue qui n'ait été humaine, et "
            'Dieu, qui est fidèle, ne permettra pas que vous soyez tentés au '
            'delà de vos forces ; mais avec la tentation il préparera '
            "aussi le moyen d'en sortir, afin que vous puissiez la supporter.",
        reference: '1 Corinthiens 10.13',
        traduction: _lsg,
      ),
      Verset(
        texte: 'Je puis tout par celui qui me fortifie.',
        reference: 'Philippiens 4.13',
        traduction: _lsg,
      ),
      Verset(
        texte:
            'Veillez et priez, afin que vous ne tombiez pas dans la '
            "tentation ; l'esprit est bien disposé, mais la chair est "
            'faible.',
        reference: 'Matthieu 26.41',
        traduction: _lsg,
      ),
      Verset(
        texte:
            'Soumettez-vous donc à Dieu ; résistez au diable, et il '
            'fuira loin de vous.',
        reference: 'Jacques 4.7',
        traduction: _lsg,
      ),
      Verset(
        texte:
            'Dieu est pour nous un refuge et un appui, un secours qui ne '
            'manque jamais dans la détresse.',
        reference: 'Psaume 46.2',
        traduction: _lsg,
      ),
      Verset(
        texte:
            'Ne crains rien, car je suis avec toi ; ne promène pas des '
            'regards inquiets, car je suis ton Dieu ; je te fortifie, '
            'je viens à ton secours, je te soutiens de ma droite '
            'triomphante.',
        reference: 'Ésaïe 41.10',
        traduction: _lsg,
      ),
      Verset(
        texte:
            "Car ce n'est pas un esprit de timidité que Dieu nous a donné, "
            "mais un esprit de force, d'amour et de sagesse.",
        reference: '2 Timothée 1.7',
        traduction: _lsg,
      ),
    ],
    Soutien.liberte: [
      Verset(
        texte:
            "C'est pour la liberté que Christ nous a affranchis. Demeurez "
            'donc fermes, et ne vous laissez pas mettre de nouveau sous le '
            'joug de la servitude.',
        reference: 'Galates 5.1',
        traduction: _lsg,
      ),
      Verset(
        texte: 'Si donc le Fils vous affranchit, vous serez réellement libres.',
        reference: 'Jean 8.36',
        traduction: _lsg,
      ),
      Verset(
        texte:
            "Tout m'est permis, mais tout n'est pas utile ; tout m'est "
            'permis, mais je ne me laisserai asservir par quoi que ce soit.',
        reference: '1 Corinthiens 6.12',
        traduction: _lsg,
      ),
    ],
    Soutien.relever: [
      Verset(
        texte: 'Car sept fois le juste tombe, et il se relève.',
        reference: 'Proverbes 24.16',
        traduction: _lsg,
      ),
      Verset(
        texte:
            'Ne te réjouis pas à mon sujet, mon ennemie ! Car si je suis '
            'tombé, je me relève ; si je suis assis dans les ténèbres, '
            "l'Éternel est ma lumière.",
        reference: 'Michée 7.8',
        traduction: _lsg,
      ),
      Verset(
        texte:
            "Il n'y a donc maintenant aucune condamnation pour ceux qui sont "
            'en Jésus Christ.',
        reference: 'Romains 8.1',
        traduction: _lsg,
      ),
      Verset(
        texte:
            "Les bontés de l'Éternel ne sont pas épuisées, ses compassions ne "
            'sont pas à leur terme ; elles se renouvellent chaque '
            'matin. Oh ! que ta fidélité est grande !',
        reference: 'Lamentations 3.22-23',
        traduction: _lsg,
      ),
      Verset(
        texte:
            "Ma grâce te suffit, car ma puissance s'accomplit dans la "
            'faiblesse.',
        reference: '2 Corinthiens 12.9',
        traduction: _lsg,
      ),
    ],
    Soutien.perseverer: [
      Verset(
        texte:
            'Ne nous lassons pas de faire le bien ; car nous '
            'moissonnerons au temps convenable, si nous ne nous relâchons '
            'pas.',
        reference: 'Galates 6.9',
        traduction: _lsg,
      ),
      Verset(
        texte:
            "Mais ceux qui se confient en l'Éternel renouvellent leur force. "
            'Ils prennent le vol comme les aigles ; ils courent, et ne '
            'se lassent point, ils marchent, et ne se fatiguent point.',
        reference: 'Ésaïe 40.31',
        traduction: _lsg,
      ),
      Verset(
        texte:
            "Celui qui est fidèle dans les moindres choses l'est aussi dans "
            'les grandes.',
        reference: 'Luc 16.10',
        traduction: _lsg,
      ),
      Verset(
        texte:
            'Tout ce que vous faites, faites-le de bon cœur, comme pour le '
            'Seigneur et non pour des hommes.',
        reference: 'Colossiens 3.23',
        traduction: _lsg,
      ),
    ],
  };

  /// Le verset du [jour] pour ce [soutien] ([decalage] : un autre du même
  /// jour).
  static Verset du(Soutien soutien, DateTime jour, [int decalage = 0]) {
    final liste = parSoutien[soutien]!;
    return liste[(joursEntre(DateTime(2026), jour) + decalage) % liste.length];
  }
}
