// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get titreApp => 'Rhythm';

  @override
  String get navAccueil => 'Accueil';

  @override
  String get navSports => 'Sports';

  @override
  String get navAlimentation => 'Alimentation';

  @override
  String get navHabitudes => 'Habitudes';

  @override
  String get navBiblique => 'Biblique';

  @override
  String get navigationPrincipale => 'Navigation principale';

  @override
  String get bientot => 'Bientôt disponible';

  @override
  String get bonjour => 'Bonjour';

  @override
  String get bonsoir => 'Bonsoir';

  @override
  String get notifications => 'Notifications';

  @override
  String get versetDuJour => 'Verset du jour';

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String objectifMinutes(int n) {
    return 'objectif $n min';
  }

  @override
  String kcal(String n) {
    return '$n kcal';
  }

  @override
  String resteKcal(String n) {
    return 'reste $n kcal';
  }

  @override
  String surTotal(int n, int total) {
    return '$n sur $total';
  }

  @override
  String serieDeJours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'série de $n jours',
      one: 'série de 1 jour',
      zero: 'aucune série',
    );
    return '$_temp0';
  }

  @override
  String get lecture => 'Lecture';

  @override
  String chapitreSur(int n, int total) {
    return 'chapitre $n sur $total';
  }

  @override
  String get prochaineSeance => 'Prochaine séance';

  @override
  String seanceEtHeure(String seance, String heure) {
    return '$seance · $heure';
  }

  @override
  String semaineNumero(int n) {
    return 'Semaine $n';
  }

  @override
  String get minCetteSemaine => 'min cette semaine';

  @override
  String objectifSemaine(int n) {
    return 'objectif $n';
  }

  @override
  String get seances => 'Séances';

  @override
  String get calories => 'Calories';

  @override
  String get serie => 'Série';

  @override
  String semainesCourt(int n) {
    return '$n sem.';
  }

  @override
  String seanceDuJour(String heure) {
    return 'Séance du jour · $heure';
  }

  @override
  String get commencer => 'Commencer';

  @override
  String get aujourdhui => 'Aujourd\'hui';

  @override
  String get kcalRestantes => 'kcal restantes';

  @override
  String get proteines => 'Protéines';

  @override
  String get glucides => 'Glucides';

  @override
  String get lipides => 'Lipides';

  @override
  String grammes(int n) {
    return '$n g';
  }

  @override
  String surGrammes(int n) {
    return '/ $n g';
  }

  @override
  String get repas => 'Repas';

  @override
  String get ajouterRepas => 'Ajouter un repas';

  @override
  String get dejeuner => 'Déjeuner';

  @override
  String get diner => 'Dîner';

  @override
  String get collation => 'Collation';

  @override
  String get souper => 'Souper';

  @override
  String get aPlanifier => 'À planifier';

  @override
  String get hydratation => 'Hydratation';

  @override
  String litresSur(String bu, String objectif) {
    return '$bu L sur $objectif L';
  }

  @override
  String joursDaffilee(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours d\'affilée',
      one: '1 jour d\'affilée',
      zero: 'Aucun jour d\'affilée',
    );
    return '$_temp0';
  }

  @override
  String recordPersonnel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Record personnel : $n jours',
      one: 'Record personnel : 1 jour',
      zero: 'Record personnel : aucun',
    );
    return '$_temp0';
  }

  @override
  String jours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours',
      one: '1 jour',
      zero: '0 jour',
    );
    return '$_temp0';
  }

  @override
  String get partager => 'Partager';

  @override
  String get planDeLecture => 'Plan de lecture';

  @override
  String continuer(String chapitre) {
    return 'Continuer · $chapitre';
  }

  @override
  String get priere => 'Prière';

  @override
  String journalSujets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Journal · $n sujets',
      one: 'Journal · 1 sujet',
      zero: 'Journal · aucun sujet',
    );
    return '$_temp0';
  }

  @override
  String get meditation => 'Méditation';

  @override
  String notesSur(String chapitre) {
    return 'Notes sur $chapitre';
  }

  @override
  String get aCommencer => 'À commencer';

  @override
  String serieCourte(int n) {
    return '$n j';
  }

  @override
  String get lesAutresJours => 'Les autres jours';

  @override
  String get liberation => 'Libération';

  @override
  String libreDepuisDuree(String duree) {
    return 'libre depuis $duree';
  }

  @override
  String get envieBouton => 'Envie ?';

  @override
  String get nouvelleHabitude => 'Nouvelle habitude';

  @override
  String toastJourneeComplete(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Journée complète · $n jours d\'affilée',
      one: 'Journée complète',
      zero: 'Journée complète',
    );
    return '$_temp0';
  }

  @override
  String toastPalier(int n) {
    return '$n jours d\'affilée — un palier !';
  }

  @override
  String get jourAVenir => 'Ce jour n\'est pas encore là.';

  @override
  String get coachAucune =>
      'Commence petit : une seule habitude, deux minutes par jour. La régularité fait le reste.';

  @override
  String get coachRienPrevu =>
      'Rien de prévu aujourd\'hui. Repos — ou une habitude en bonus ?';

  @override
  String get coachComplete1 => 'Tout est fait. Journée complète — savoure-la.';

  @override
  String get coachComplete2 =>
      'Journée complète. Tu tiens parole envers toi-même.';

  @override
  String get coachComplete3 =>
      'Rien ne manque aujourd\'hui. Demain, même rythme.';

  @override
  String coachCompleteSerie(int n) {
    return 'Journée complète — $n jours d\'affilée. Continue d\'empiler les jours.';
  }

  @override
  String coachPalier3(String nom) {
    return '3 jours d\'affilée pour « $nom ». Le plus dur, c\'était de commencer.';
  }

  @override
  String coachPalier7(String nom) {
    return 'Une semaine entière de « $nom ». Ça commence à tenir.';
  }

  @override
  String coachPalier14(String nom) {
    return 'Deux semaines de « $nom ». Ce n\'est plus un effort, c\'est un rythme.';
  }

  @override
  String coachPalier21(String nom) {
    return 'Trois semaines de « $nom ». Ça devient naturel.';
  }

  @override
  String coachPalier30(String nom) {
    return 'Un mois de « $nom ». Regarde le chemin parcouru.';
  }

  @override
  String coachPalier50(String nom) {
    return '50 jours de « $nom ». Ça fait partie de toi, maintenant.';
  }

  @override
  String coachPalier66(String nom) {
    return '66 jours de « $nom » : en moyenne, le temps qu\'il faut pour qu\'une habitude devienne automatique.';
  }

  @override
  String coachPalier100(String nom) {
    return '100 jours de « $nom ». Trois chiffres. Chapeau.';
  }

  @override
  String coachPalier365(String nom) {
    return 'Un an de « $nom ». Une année entière, un jour à la fois.';
  }

  @override
  String coachPalierAutre(int n, String nom) {
    return '$n jours d\'affilée pour « $nom ». Quelle constance.';
  }

  @override
  String coachJamaisDeuxFois1(String nom) {
    return '« $nom » a sauté la dernière fois. Ce n\'est rien — mais jamais deux fois de suite.';
  }

  @override
  String coachJamaisDeuxFois2(String nom) {
    return 'Un jour manqué ne défait pas une habitude. Deux, ça commence. « $nom » t\'attend.';
  }

  @override
  String get coachMatin1 =>
      'Une première coche, même petite, lance toute la journée.';

  @override
  String get coachMatin2 =>
      'Nouveau jour, page blanche. Par quoi on commence ?';

  @override
  String get coachMatin3 =>
      'Commence par la plus facile. L\'élan fera le reste.';

  @override
  String get coachApresMidi =>
      'La journée est encore longue. Deux minutes suffisent pour commencer.';

  @override
  String get coachSoirRien =>
      'La soirée est là. Choisis une habitude, même en version minimale.';

  @override
  String coachPartiel1(int reste) {
    String _temp0 = intl.Intl.pluralLogic(
      reste,
      locale: localeName,
      other: 'Plus que $reste. Le plus dur, commencer, est déjà fait.',
      one: 'Plus qu\'une. Le plus dur, commencer, est déjà fait.',
      zero: 'Tout est fait.',
    );
    return '$_temp0';
  }

  @override
  String get coachPartiel2 =>
      'Chaque coche compte, même la plus petite. Garde l\'élan.';

  @override
  String coachPartiel3(int reste) {
    String _temp0 = intl.Intl.pluralLogic(
      reste,
      locale: localeName,
      other: 'Tu avances. Encore $reste et la journée est complète.',
      one: 'Tu avances. Encore une et la journée est complète.',
      zero: 'Tout est fait.',
    );
    return '$_temp0';
  }

  @override
  String coachSoir(int reste) {
    String _temp0 = intl.Intl.pluralLogic(
      reste,
      locale: localeName,
      other:
          'La soirée avance. Il en reste $reste — la version minimale compte aussi.',
      one:
          'La soirée avance. Il en reste une — la version minimale compte aussi.',
      zero: 'Tout est fait.',
    );
    return '$_temp0';
  }

  @override
  String get coachNuit =>
      'Il est tard. Fais la version minimale — ou repose-toi : demain est un nouveau jour.';

  @override
  String get modifier => 'Modifier';

  @override
  String get tousLesJours => 'Tous les jours';

  @override
  String rappelA(String heure) {
    return 'rappel à $heure';
  }

  @override
  String get record => 'Record';

  @override
  String get sur30Jours => 'Sur 30 jours';

  @override
  String valeurFois(int n) {
    return '$n fois';
  }

  @override
  String prochainPalier(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Prochain palier : $n jours',
      one: 'Prochain palier : 1 jour',
      zero: 'Prochain palier',
    );
    return '$_temp0';
  }

  @override
  String encoreJours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'encore $n jours',
      one: 'encore 1 jour',
      zero: 'c\'est aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String prochainPalierDuree(String duree) {
    return 'Prochain palier : $duree';
  }

  @override
  String dansDuree(String duree) {
    return 'dans $duree';
  }

  @override
  String get historique => 'Historique';

  @override
  String get historiqueAide =>
      'Touche un jour passé pour le cocher ou le décocher.';

  @override
  String get pourquoi => 'Pourquoi';

  @override
  String get monPlan => 'Mon plan';

  @override
  String get versionMinimale => 'Version minimale';

  @override
  String get versionMinimaleAide =>
      'Les jours difficiles, au moins ceci — la série continue.';

  @override
  String get ajouterMotivation =>
      'Ajoute ton pourquoi et ton plan : ils t\'aideront les jours difficiles.';

  @override
  String joursLibresUnite(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'jours',
      one: 'jour',
      zero: 'jour',
    );
    return '$_temp0';
  }

  @override
  String depuisLe(String date) {
    return 'depuis le $date';
  }

  @override
  String get economise => 'Économisé';

  @override
  String get enviesSurmontees => 'Envies surmontées';

  @override
  String get jaiUneEnvie => 'J\'ai une envie';

  @override
  String get mesAlternatives => 'Mes alternatives';

  @override
  String get mesDeclencheurs => 'Mes déclencheurs';

  @override
  String get journalEnvies => 'Journal des envies';

  @override
  String intensiteSur10(int n) {
    return 'intensité $n/10';
  }

  @override
  String get tenue => 'Tenue';

  @override
  String get rechute => 'Rechute';

  @override
  String enviesSurtout(String tranche) {
    return 'Tes envies arrivent surtout $tranche.';
  }

  @override
  String get trancheNuit => 'la nuit';

  @override
  String get trancheMatin => 'le matin';

  @override
  String get trancheApresMidi => 'l\'après-midi';

  @override
  String get trancheSoir => 'le soir';

  @override
  String declencheurPrincipal(String declencheur) {
    return 'Déclencheur le plus fréquent : $declencheur.';
  }

  @override
  String rechutesCompte(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rechutes',
      one: '1 rechute',
      zero: 'Aucune rechute',
    );
    return '$_temp0';
  }

  @override
  String get aucuneEnvie =>
      'Aucune envie notée pour l\'instant. Quand l\'envie monte, touche « J\'ai une envie ».';

  @override
  String get modifierHabitude => 'Modifier l\'habitude';

  @override
  String get aConstruire => 'À construire';

  @override
  String get aLiberer => 'Me libérer';

  @override
  String get aConstruireAide => 'Une habitude à prendre, jour après jour.';

  @override
  String get aLibererAide =>
      'Une dépendance à laisser : un compteur, et du soutien quand l\'envie monte.';

  @override
  String get champNom => 'Nom';

  @override
  String get indiceNomConstruire => 'Prière du matin';

  @override
  String get indiceNomLiberer => 'Ce dont je me libère';

  @override
  String get champCouleur => 'Couleur';

  @override
  String get champLettre => 'Lettre';

  @override
  String get champDetail => 'Précision';

  @override
  String get indiceDetail => 'Au réveil · 10 min';

  @override
  String get champJours => 'Jours';

  @override
  String get champRappel => 'Rappel';

  @override
  String get rappelDiscret =>
      'Un mot discret chaque jour, sans jamais nommer ce dont tu te libères.';

  @override
  String get heure => 'Heure';

  @override
  String get champPourquoi => 'Pourquoi';

  @override
  String get indicePourquoi => 'Ce qui compte vraiment pour moi';

  @override
  String get indicePlan => 'Quand je me lève, je prie 10 minutes.';

  @override
  String get aidePlan =>
      'Quand [moment], je [action]. Un plan précis aide à s\'y tenir.';

  @override
  String get indiceVersionMinimale => '2 minutes, 1 verset, 1 verre';

  @override
  String get champLibreDepuis => 'Libre depuis';

  @override
  String get hier => 'Hier';

  @override
  String ilYaJours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Il y a $n jours',
      one: 'Hier',
      zero: 'Aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get champCout => 'Coût par jour';

  @override
  String get aideCout => 'Pour voir ce que tu économises.';

  @override
  String get indiceAlternative => 'Ajouter une alternative';

  @override
  String get indiceDeclencheur => 'Ajouter un déclencheur';

  @override
  String get altEau => 'Boire un grand verre d\'eau';

  @override
  String get altMarcher => 'Marcher 5 minutes';

  @override
  String get altAppeler => 'Appeler quelqu\'un';

  @override
  String get altPrier => 'Prier';

  @override
  String get altRespirer => 'Respirer lentement';

  @override
  String get altDouche => 'Prendre une douche';

  @override
  String get declStress => 'Stress';

  @override
  String get declEnnui => 'Ennui';

  @override
  String get declFatigue => 'Fatigue';

  @override
  String get declSolitude => 'Solitude';

  @override
  String get declColere => 'Colère';

  @override
  String get declSoiree => 'Le soir';

  @override
  String get declEcrans => 'Réseaux sociaux';

  @override
  String get enregistrer => 'Enregistrer';

  @override
  String get annuler => 'Annuler';

  @override
  String get ajouter => 'Ajouter';

  @override
  String get supprimerHabitude => 'Supprimer l\'habitude';

  @override
  String get toucherPourSupprimer => 'Toucher encore pour supprimer';

  @override
  String get nomRequis => 'Donne-lui un nom.';

  @override
  String get envieSurtitre => 'L\'envie passe';

  @override
  String get tiensBon => 'Tiens bon';

  @override
  String get vagueTexte =>
      'Une envie monte, culmine, puis redescend — souvent en moins de quinze minutes. Tu n\'as pas à lui obéir : laisse-la passer comme une vague.';

  @override
  String get inspire => 'Inspire';

  @override
  String get expire => 'Expire';

  @override
  String get respirationAide =>
      'Suis le cercle : cinq secondes pour inspirer, cinq pour expirer.';

  @override
  String get attendreDixMinutes => 'Attendre 10 minutes';

  @override
  String minuteurReste(String temps) {
    return 'Encore $temps';
  }

  @override
  String get minuteurFini => 'Dix minutes. Où en est l\'envie ?';

  @override
  String get tesRaisons => 'Tes raisons';

  @override
  String get essaiePlutot => 'Essaie plutôt';

  @override
  String get appelerQuelquun => 'Appeler quelqu\'un';

  @override
  String get infoSocial => 'Info-Social 811';

  @override
  String get infoSocialDetail => 'Écoute et soutien, 24 h sur 24 (Québec)';

  @override
  String get ligne988 => '9-8-8';

  @override
  String get ligne988Detail =>
      'Crise ou idées suicidaires, 24 h sur 24 (Canada)';

  @override
  String get urgence911 => 'En danger immédiat : 911';

  @override
  String get ajouterPersonneConfiance =>
      'Ajoute une personne de confiance dans Rappels.';

  @override
  String get noterEnvie => 'Noter cette envie';

  @override
  String get intensite => 'Intensité';

  @override
  String get declencheur => 'Déclencheur';

  @override
  String get jaiTenu => 'J\'ai tenu';

  @override
  String get jaiRechute => 'J\'ai rechuté';

  @override
  String get bravo => 'Bravo.';

  @override
  String get bravoTexte =>
      'Une envie de moins. Chaque « non » rend le suivant plus facile.';

  @override
  String enviesSurmonteesTotal(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n envies surmontées',
      one: '1 envie surmontée',
      zero: 'Aucune envie surmontée',
    );
    return '$_temp0';
  }

  @override
  String get rechuteTitre => 'Tu n\'as pas tout perdu.';

  @override
  String rechuteTexte(String duree) {
    return 'Une rechute n\'efface pas le chemin. Tu as tenu $duree — c\'est réel, et ça t\'appartient.';
  }

  @override
  String get rechuteQuestion => 'Qu\'est-ce qui l\'a déclenchée ?';

  @override
  String get remettreAZero => 'Remettre le compteur à zéro';

  @override
  String get toucherPourConfirmer => 'Toucher encore pour confirmer';

  @override
  String get recommencer => 'Recommencer maintenant';

  @override
  String get terminer => 'Terminer';

  @override
  String get rappels => 'Rappels';

  @override
  String get autorisationOk => 'Notifications autorisées';

  @override
  String get autorisationRefusee => 'Bloquées par Android';

  @override
  String get autorisationInconnue => 'Pas encore autorisées';

  @override
  String get ouvrirReglages => 'Ouvrir les réglages';

  @override
  String get autoriser => 'Autoriser';

  @override
  String get rappelsHabitudes => 'Rappels des habitudes';

  @override
  String get rappelsHabitudesAide =>
      'À l\'heure choisie pour chacune, les jours prévus — jamais si c\'est déjà fait.';

  @override
  String get aucunRappel => 'Aucun rappel';

  @override
  String get toucherPourRegler => 'Touche une habitude pour choisir son heure.';

  @override
  String get bilanDuSoir => 'Bilan du soir';

  @override
  String get bilanDuSoirAide => 'Ce qui reste à cocher, en fin de journée.';

  @override
  String get personnesConfiance => 'Personnes de confiance';

  @override
  String get personnesConfianceAide =>
      'À appeler d\'un toucher quand l\'envie est forte.';

  @override
  String get ajouterPersonne => 'Ajouter une personne';

  @override
  String get champTelephone => 'Téléphone';

  @override
  String get discretionTexte =>
      'Discrétion : les rappels de libération ne nomment jamais ce dont tu te libères, et rien ne quitte ton téléphone.';

  @override
  String get canalRappelsNom => 'Rappels des habitudes';

  @override
  String get canalRappelsDescription =>
      'À l\'heure choisie pour chaque habitude.';

  @override
  String get canalBilanNom => 'Bilan du soir';

  @override
  String get canalBilanDescription =>
      'Ce qui reste à cocher en fin de journée.';

  @override
  String get canalSoutienNom => 'Soutien discret';

  @override
  String get canalSoutienDescription =>
      'Un mot et les étapes franchies, sans jamais nommer ce dont tu te libères.';

  @override
  String notifSerie(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Série de $n jours — garde le rythme.',
      one: 'Hier, c\'était fait. On continue ?',
      zero: 'C\'est le moment.',
    );
    return '$_temp0';
  }

  @override
  String notifMinimale(String version) {
    return 'Même petit, ça compte : $version.';
  }

  @override
  String notifPourquoi(String pourquoi) {
    return 'Souviens-toi : $pourquoi';
  }

  @override
  String get notifGenerique =>
      'C\'est le moment. Deux minutes suffisent pour commencer.';

  @override
  String notifBilanReste(int n, String noms) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Il te reste $n habitudes : $noms.',
      one: 'Il te reste une habitude : $noms.',
      zero: 'Tout est fait.',
    );
    return '$_temp0';
  }

  @override
  String get notifBilanGenerique =>
      'Un instant pour faire le point sur ta journée.';

  @override
  String get notifSoutien1 =>
      'Un moment pour toi. Comment ça va aujourd\'hui ?';

  @override
  String get notifSoutien2 => 'Tu tiens bon. Rhythm est là si l\'envie monte.';

  @override
  String get notifSoutien3 => 'Respire. Un jour à la fois.';

  @override
  String get notifPalierTitre => 'Une étape franchie';

  @override
  String notifPalierCorps(String duree) {
    return '$duree — bravo. Continue.';
  }

  @override
  String dureeSemaines(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n semaines',
      one: '1 semaine',
      zero: '0 semaine',
    );
    return '$_temp0';
  }

  @override
  String dureeMois(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n mois',
      one: '1 mois',
      zero: '0 mois',
    );
    return '$_temp0';
  }

  @override
  String dureeAns(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n ans',
      one: '1 an',
      zero: '0 an',
    );
    return '$_temp0';
  }

  @override
  String get activer => 'Activer';

  @override
  String get notifsActiverAide => 'Sans elles, aucun rappel ne peut sonner.';

  @override
  String get notifsGererAide =>
      'Sons, canaux et écran verrouillé se règlent dans Android.';

  @override
  String get reglagesAndroid => 'Réglages';

  @override
  String get notifsBloqueesRappel =>
      'Les notifications sont désactivées : ce rappel ne sonnera pas.';

  @override
  String get rappelsEtNotifications => 'Rappels et notifications';

  @override
  String get separateurHeure => 'h';

  @override
  String get meLibererDependance => 'Me libérer d\'une dépendance';

  @override
  String get monOrdre => 'Mon ordre';

  @override
  String get parHeure => 'Par heure';

  @override
  String get deplacerAide => 'Maintiens une habitude pour la déplacer.';

  @override
  String get epingler => 'Épingler en haut';

  @override
  String get desepingler => 'Désépingler';

  @override
  String get toastEpinglee => 'Épinglée en haut';

  @override
  String get toastDesepinglee => 'Désépinglée';

  @override
  String get retirerEntree => 'Retirer de l\'historique ?';

  @override
  String get retirer => 'Retirer';

  @override
  String get garder => 'Garder';

  @override
  String get journalAide =>
      'Maintiens une entrée pour la retirer — une rechute notée par erreur, par exemple.';

  @override
  String get styleMusculation => 'Musculation';

  @override
  String get stylePoidsDuCorps => 'Poids du corps';

  @override
  String get styleGainage => 'Gainage';

  @override
  String get styleHiit => 'HIIT et circuit';

  @override
  String get styleMobilite => 'Mobilité et étirements';

  @override
  String get styleCardio => 'Cardio';

  @override
  String get materielHalteres => 'Haltères';

  @override
  String get materielBarre => 'Barre';

  @override
  String get materielKettlebell => 'Kettlebell';

  @override
  String get materielElastique => 'Élastique';

  @override
  String get materielBarreTraction => 'Barre de traction';

  @override
  String get materielBanc => 'Banc';

  @override
  String get materielChaise => 'Chaise ou marche';

  @override
  String get materielCorde => 'Corde à sauter';

  @override
  String get materielVelo => 'Vélo';

  @override
  String get niveauDebutant => 'Débutant';

  @override
  String get niveauIntermediaire => 'Intermédiaire';

  @override
  String get niveauAvance => 'Avancé';

  @override
  String get musclePectoraux => 'Pectoraux';

  @override
  String get muscleDos => 'Dos';

  @override
  String get muscleTrapezes => 'Trapèzes';

  @override
  String get muscleEpaules => 'Épaules';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleAvantBras => 'Avant-bras';

  @override
  String get muscleAbdos => 'Abdos';

  @override
  String get muscleObliques => 'Obliques';

  @override
  String get muscleLombaires => 'Lombaires';

  @override
  String get muscleFessiers => 'Fessiers';

  @override
  String get muscleQuadriceps => 'Quadriceps';

  @override
  String get muscleIschios => 'Ischios';

  @override
  String get muscleAdducteurs => 'Adducteurs';

  @override
  String get muscleMollets => 'Mollets';

  @override
  String get objectifForce => 'Force';

  @override
  String get objectifVolume => 'Volume musculaire';

  @override
  String get objectifEndurance => 'Endurance';

  @override
  String get objectifForceDetail => '4 à 6 répétitions, repos long';

  @override
  String get objectifVolumeDetail => '8 à 12 répétitions, 60 à 90 s de repos';

  @override
  String get objectifEnduranceDetail => '15 à 20 répétitions, repos court';

  @override
  String get ressentiFacile => 'Facile';

  @override
  String get ressentiCorrect => 'Correct';

  @override
  String get ressentiDifficile => 'Difficile';

  @override
  String get ressentiEchec => 'Échec';

  @override
  String get effort1 => 'Facile';

  @override
  String get effort2 => 'Modéré';

  @override
  String get effort3 => 'Soutenu';

  @override
  String get effort4 => 'Dur';

  @override
  String get effort5 => 'Épuisant';

  @override
  String get phaseEchauffement => 'Échauffement';

  @override
  String get phaseEffort => 'Vite';

  @override
  String get phaseRecuperation => 'Lent';

  @override
  String get phaseRetourCalme => 'Retour au calme';

  @override
  String get roleSeance => 'Séance';

  @override
  String get recordCharge => 'Charge maximale';

  @override
  String get recordReps => 'Répétitions maximales';

  @override
  String get recordForce => 'Force maximale estimée';

  @override
  String get recordDuree => 'Durée maximale';

  @override
  String get progresPremiereFois => 'Première fois : trouve ta charge';

  @override
  String get progresPareil => 'Comme la dernière fois';

  @override
  String get progresRepDePlus => 'Une répétition de plus que la dernière fois';

  @override
  String get progresPlusDeCharge =>
      'Tout réussi la dernière fois : un peu plus lourd';

  @override
  String get progresPlusLong => '5 secondes de plus que la dernière fois';

  @override
  String get seanceDuJourTitre => 'Séance du jour';

  @override
  String get rienDePrevu => 'Rien de prévu aujourd\'hui';

  @override
  String prochaineLe(String seance, String quand) {
    return 'Prochaine : $seance · $quand';
  }

  @override
  String get seanceFaiteAujourdhui => 'Faite aujourd\'hui';

  @override
  String get creerSeance => 'Créer une séance';

  @override
  String get banqueExercices => 'Banque d\'exercices';

  @override
  String get statistiques => 'Statistiques';

  @override
  String get enRecuperation => 'En récupération';

  @override
  String encoreDuree(String duree) {
    return 'encore $duree';
  }

  @override
  String get recuperationAide =>
      'Travaillés lourdement il y a moins de 48 h : le constructeur les évite.';

  @override
  String get coursesTitre => 'Course, marche, vélo';

  @override
  String get activiteCourse => 'Course';

  @override
  String get activiteMarche => 'Marche';

  @override
  String get activiteVelo => 'Vélo';

  @override
  String get activiteFractionne => 'Fractionné';

  @override
  String get programmesProgressifs => 'Programmes progressifs';

  @override
  String get mesSeances => 'Mes séances';

  @override
  String get aucuneSeanceEnregistree =>
      'Aucune séance enregistrée. Crée la tienne : Rhythm l\'organise.';

  @override
  String resumeSeance(int n, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercices',
      one: '1 exercice',
      zero: 'aucun exercice',
    );
    return '$_temp0 · env. $minutes min';
  }

  @override
  String get aLaDemande => 'À la demande';

  @override
  String get defisTitre => 'Défis de 4 semaines';

  @override
  String get voirLesDefis => 'Voir les défis';

  @override
  String get routinesExpress => 'Routines express';

  @override
  String dureeMinutesCourt(int n) {
    return '$n min';
  }

  @override
  String get journalSport => 'Journal';

  @override
  String get toutLeJournal => 'Tout le journal';

  @override
  String get journalVide => 'Ta première séance apparaîtra ici.';

  @override
  String get mesures => 'Mesures';

  @override
  String get materielEtObjectifs => 'Matériel et objectifs';

  @override
  String get monMateriel => 'Mon matériel';

  @override
  String get materielAide =>
      'La banque te montre d\'abord ce que tu peux faire avec.';

  @override
  String get sansMaterielDu => 'Rien d\'autre que le poids du corps';

  @override
  String get objectif => 'Objectif';

  @override
  String get niveau => 'Niveau';

  @override
  String get poidsDuCorps => 'Poids du corps';

  @override
  String get poidsAide => 'Pour estimer les calories.';

  @override
  String get minutesParSemaine => 'Minutes par semaine';

  @override
  String get minutesParJour => 'Minutes par jour';

  @override
  String get enchainerOpposes => 'Enchaîner les exercices opposés';

  @override
  String get enchainerAide =>
      'Deux exercices opposés sans repos entre eux : la séance est plus courte.';

  @override
  String get lienHabitude => 'Cocher l\'habitude « Entraînement »';

  @override
  String get lienHabitudeAide =>
      'Une séance enregistrée la coche pour la journée.';

  @override
  String kgValeur(String n) {
    return '$n kg';
  }

  @override
  String cmValeur(String n) {
    return '$n cm';
  }

  @override
  String get rechercherExercice => 'Rechercher un exercice';

  @override
  String get avecMonMateriel => 'Avec mon matériel';

  @override
  String get sansMateriel => 'Sans matériel';

  @override
  String get tousLesStyles => 'Tous les styles';

  @override
  String get tousLesMuscles => 'Tous';

  @override
  String nExercices(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercices',
      one: '1 exercice',
      zero: 'Aucun exercice',
    );
    return '$_temp0';
  }

  @override
  String get aucunExercice => 'Aucun exercice ne correspond.';

  @override
  String get quelMateriel => 'Quel matériel as-tu ?';

  @override
  String get quelMaterielAide =>
      'Dis-le une fois : la banque te montre d\'abord ce que tu peux faire.';

  @override
  String get confirmer => 'Confirmer';

  @override
  String get musclesPrincipaux => 'Muscles principaux';

  @override
  String get musclesSecondaires => 'Muscles secondaires';

  @override
  String get materiel => 'Matériel';

  @override
  String get aucunMateriel => 'Aucun';

  @override
  String get polyarticulaire => 'Polyarticulaire';

  @override
  String get isolation => 'Isolation';

  @override
  String get deChaqueCote => 'De chaque côté';

  @override
  String get etapes => 'Étapes';

  @override
  String get erreursFrequentes => 'Erreurs fréquentes';

  @override
  String get respiration => 'Respiration';

  @override
  String get variantes => 'Variantes';

  @override
  String get plusFacile => 'Plus facile';

  @override
  String get plusDur => 'Plus dur';

  @override
  String get tuEsIci => 'Tu es ici';

  @override
  String get tesRecords => 'Tes records';

  @override
  String get ajouterASeance => 'Ajouter à une séance';

  @override
  String get nouvelleSeance => 'Nouvelle séance';

  @override
  String toastAjouteA(String seance) {
    return 'Ajouté à « $seance »';
  }

  @override
  String get lesZones => 'Les zones';

  @override
  String get zonesAide =>
      'Touche les muscles à travailler, de face et de dos. Sans zone : tout le corps.';

  @override
  String get vueFace => 'Face';

  @override
  String get vueDos => 'Dos';

  @override
  String get toutLeCorps => 'Tout le corps';

  @override
  String get effacer => 'Effacer';

  @override
  String get lesExercices => 'Les exercices';

  @override
  String get exercicesAide =>
      'Choisis tes exercices, ou laisse Rhythm compléter.';

  @override
  String get completer => 'Compléter';

  @override
  String get completerAide =>
      'Des exercices équilibrés pour tes zones, avec ton matériel.';

  @override
  String nChoisis(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n choisis',
      one: '1 choisi',
      zero: 'aucun choisi',
    );
    return '$_temp0';
  }

  @override
  String get voirApercu => 'Voir l\'aperçu';

  @override
  String evitesRecuperation(String muscles) {
    return 'Évités, en récupération : $muscles';
  }

  @override
  String get choisirUnExercice => 'Choisis au moins un exercice.';

  @override
  String get pourCesZones => 'Pour tes zones';

  @override
  String get apercu => 'Aperçu';

  @override
  String get dureeEstimee => 'Durée estimée';

  @override
  String environMinutes(int n) {
    return 'env. $n min';
  }

  @override
  String get seriesParMuscle => 'Séries par muscle';

  @override
  String get echauffement => 'Échauffement';

  @override
  String get retourAuCalme => 'Retour au calme';

  @override
  String dosageReps(int series, int reps) {
    return '$series × $reps';
  }

  @override
  String dosageSecondes(int series, int secondes) {
    return '$series × $secondes s';
  }

  @override
  String dureeSecondes(int n) {
    return '$n s';
  }

  @override
  String reposDe(String duree) {
    return 'repos $duree';
  }

  @override
  String get enchaine => 'Enchaîné';

  @override
  String get ajouterUnExercice => 'Ajouter un exercice';

  @override
  String get series => 'Séries';

  @override
  String get repetitions => 'Répétitions';

  @override
  String get dureeSerie => 'Durée';

  @override
  String get charge => 'Charge';

  @override
  String get repos => 'Repos';

  @override
  String get sansCharge => 'Poids du corps';

  @override
  String get enregistrerLaSeance => 'Enregistrer la séance';

  @override
  String get indiceNomSeance => 'Haut du corps, jambes, full body…';

  @override
  String get joursPrevus => 'Jours prévus';

  @override
  String get joursPrevusAide =>
      'Prévue ces jours-là, elle devient la « Séance du jour ».';

  @override
  String get meLeRappeler => 'Me le rappeler';

  @override
  String get supprimerSeance => 'Supprimer la séance';

  @override
  String get toastSeanceEnregistreeProgramme => 'Séance enregistrée';

  @override
  String get retouchesAide =>
      'Touche une ligne pour la retoucher, maintiens-la pour la déplacer.';

  @override
  String serieSur(int n, int total) {
    return 'Série $n sur $total';
  }

  @override
  String exerciceSur(int n, int total) {
    return '$n sur $total';
  }

  @override
  String get serieFaite => 'Série faite';

  @override
  String get demarrer => 'Démarrer';

  @override
  String get cestFait => 'C\'est fait';

  @override
  String get plusQuinze => '+15 s';

  @override
  String get passer => 'Passer';

  @override
  String get aSuivre => 'À suivre';

  @override
  String get commentCetait => 'Comment c\'était ?';

  @override
  String laDerniereFois(String detail) {
    return 'La dernière fois : $detail';
  }

  @override
  String get arreterSeance => 'Arrêter la séance ?';

  @override
  String get garderCeQuiEstFait => 'Enregistrer ce qui est fait';

  @override
  String get abandonnerSeance => 'Abandonner sans enregistrer';

  @override
  String get reprendre => 'Reprendre';

  @override
  String get passerExercice => 'Passer l\'exercice';

  @override
  String toastRecord(String detail) {
    return 'Nouveau record : $detail !';
  }

  @override
  String get reposFini => 'Repos fini';

  @override
  String get chaqueCote => 'de chaque côté';

  @override
  String get pret => 'Prépare-toi';

  @override
  String get seanceTerminee => 'Séance terminée';

  @override
  String get duree => 'Durée';

  @override
  String get volume => 'Volume';

  @override
  String get seriesFaites => 'Séries';

  @override
  String get recordsBattus => 'Records battus';

  @override
  String get ressentiGlobal => 'Ressenti';

  @override
  String get note => 'Note';

  @override
  String get indiceNote => 'Ce que tu as remarqué, ce qui a changé…';

  @override
  String get toastSeanceEnregistree => 'Séance enregistrée';

  @override
  String toastSeanceHabitude(String habitude) {
    return 'Séance enregistrée · « $habitude » cochée';
  }

  @override
  String get toastEtapeValidee => 'Séance enregistrée · étape validée';

  @override
  String get enCours => 'En cours';

  @override
  String get enPause => 'En pause';

  @override
  String get pause => 'Pause';

  @override
  String get distance => 'Distance';

  @override
  String get indiceKm => 'en km';

  @override
  String get allure => 'Allure';

  @override
  String get vitesse => 'Vitesse';

  @override
  String allureValeur(String temps) {
    return '$temps /km';
  }

  @override
  String vitesseValeur(String v) {
    return '$v km/h';
  }

  @override
  String kmValeur(String n) {
    return '$n km';
  }

  @override
  String get effortRessenti => 'Effort ressenti';

  @override
  String get demarrerActivite => 'C\'est parti';

  @override
  String get pasDeGps => 'Rhythm chronomètre ; tu notes la distance à la fin.';

  @override
  String get fractionnesPrets => 'Prêts à lancer';

  @override
  String get personnaliser => 'Personnaliser';

  @override
  String get repetitionsIntervalles => 'Répétitions';

  @override
  String get effortIntervalle => 'Effort';

  @override
  String get recuperationIntervalle => 'Récupération';

  @override
  String get lancer => 'Lancer';

  @override
  String intervalleSur(int n, int total) {
    return '$n sur $total';
  }

  @override
  String intervallesResume(int n, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n répétitions',
      one: '1 répétition',
    );
    return '$_temp0 · $minutes min au total';
  }

  @override
  String get monFractionne => 'Mon fractionné';

  @override
  String nSemaines(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n semaines',
      one: '1 semaine',
    );
    return '$_temp0';
  }

  @override
  String get troisParSemaine => '3 séances par semaine';

  @override
  String seanceNumero(int n, int total) {
    return 'Séance $n sur $total';
  }

  @override
  String get commencerProgramme => 'Commencer le programme';

  @override
  String get arreterProgramme => 'Arrêter le programme';

  @override
  String get prochaineEtape => 'Prochaine séance';

  @override
  String get programmeTermine => 'Programme terminé. Bravo !';

  @override
  String enCoursDepuis(String date) {
    return 'En cours depuis le $date';
  }

  @override
  String get releverDefi => 'Relever le défi';

  @override
  String get abandonnerDefi => 'Abandonner le défi';

  @override
  String prevueLe(String date) {
    return 'prévue le $date';
  }

  @override
  String auTotal(int n) {
    return '$n au total';
  }

  @override
  String get defiReleve => 'Défi relevé !';

  @override
  String get defiEnCours => 'En cours';

  @override
  String etapesFaites(int n, int total) {
    return '$n sur $total faites';
  }

  @override
  String get trenteDerniersJours => '30 derniers jours';

  @override
  String parRapportAvant(String variation) {
    return '$variation par rapport aux 30 jours d\'avant';
  }

  @override
  String get minutesTitre => 'Minutes';

  @override
  String get minutesEtSeancesParJour => 'Minutes par jour';

  @override
  String get regularite => 'Régularité';

  @override
  String joursActifs(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n jours actifs',
      one: '1 jour actif',
      zero: 'aucun jour actif',
    );
    return '$_temp0';
  }

  @override
  String get parStyle => 'Par style';

  @override
  String get musclesTravailles => 'Muscles travaillés';

  @override
  String get aNePasOublier => 'À ne pas oublier';

  @override
  String rienDepuis(String muscle, int n) {
    return '$muscle : rien depuis $n jours';
  }

  @override
  String rienEn30Jours(String muscle) {
    return '$muscle : rien depuis au moins 30 jours';
  }

  @override
  String get toutEstTravaille =>
      'Tout a été travaillé cette semaine. Bel équilibre.';

  @override
  String get recordsRecents => 'Records récents';

  @override
  String get aucunRecord => 'Pas encore de record sur la période.';

  @override
  String get moinsDe => 'moins';

  @override
  String get peuPlusBeaucoup => 'Peu · beaucoup';

  @override
  String get ajouterMesure => 'Ajouter une mesure';

  @override
  String get poids => 'Poids';

  @override
  String get tourDeTaille => 'Tour de taille';

  @override
  String depuisLeDebut(String variation) {
    return '$variation depuis le début';
  }

  @override
  String get aucuneMesure =>
      'Aucune mesure pour l\'instant. Facultatif : pour suivre ta progression.';

  @override
  String get indiceKg => 'en kg';

  @override
  String get indiceCm => 'en cm';

  @override
  String get mesureRequise => 'Note au moins le poids ou le tour de taille.';

  @override
  String get retirerDuJournal => 'Retirer du journal';

  @override
  String get toucherPourRetirer => 'Toucher encore pour retirer';

  @override
  String get canalSeancesNom => 'Séances';

  @override
  String get canalSeancesDescription => 'Le rappel de tes séances prévues.';

  @override
  String notifSeanceCorps(int n, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercices · environ $minutes min. On y va ?',
      one: '1 exercice · environ $minutes min. On y va ?',
      zero: 'Ta séance t\'attend.',
    );
    return '$_temp0';
  }

  @override
  String get exercicesCourt => 'Exercices';

  @override
  String get changeDeCote => 'Change de côté';

  @override
  String parCoteDuree(String duree) {
    return '$duree de chaque côté';
  }

  @override
  String get activiteSedentaire => 'Assis';

  @override
  String get activiteSedentaireDetail =>
      'Surtout assis : bureau, études, écrans. Les séances s\'ajoutent à part.';

  @override
  String get activiteDebout => 'Debout';

  @override
  String get activiteDeboutDetail =>
      'Souvent debout ou à marcher : commerce, enseignement, soins.';

  @override
  String get activitePhysique => 'Physique';

  @override
  String get activitePhysiqueDetail =>
      'Un travail physique : chantier, entrepôt, livraison.';

  @override
  String get activiteQuotidienne => 'Activité du quotidien';

  @override
  String auMoment(String moment) {
    String _temp0 = intl.Intl.selectLogic(moment, {
      'dejeuner': 'au déjeuner',
      'diner': 'au dîner',
      'collation': 'à la collation',
      'souper': 'au souper',
      'other': 'au repas',
    });
    return '$_temp0';
  }

  @override
  String ajouteA(String auMoment, String kcal) {
    return 'Ajouté $auMoment · $kcal';
  }

  @override
  String ajouterAu(String auMoment) {
    return 'Ajouter $auMoment';
  }

  @override
  String ajouterPareil(String nom) {
    return 'Ajouter de nouveau : $nom';
  }

  @override
  String get ajouterUnAliment => 'Ajouter un aliment';

  @override
  String ajustementActif(String depense, String rythme, String correction) {
    return 'Sur 3 semaines : ta dépense réelle est d\'environ $depense, ton poids évolue de $rythme kg par semaine. Correction : $correction par jour.';
  }

  @override
  String get ajustementAuto => 'Ajustement automatique';

  @override
  String get ajustementAutoDetail =>
      'Ta courbe de poids réelle corrige la formule.';

  @override
  String get ajustementDesactive =>
      'Désactivé : les besoins suivent la formule.';

  @override
  String ajustementDonnees(String journees, String pesees) {
    return 'Il faut 10 journées notées et 3 pesées sur 10 jours. Pour l\'instant : $journees, $pesees.';
  }

  @override
  String journeesNotees(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n journées notées',
      one: '1 journée notée',
      zero: 'aucune journée notée',
    );
    return '$_temp0';
  }

  @override
  String peseesNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n pesées',
      one: '1 pesée',
      zero: 'aucune pesée',
    );
    return '$_temp0';
  }

  @override
  String get aliments => 'Aliments';

  @override
  String alimentsAjoutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n aliments ajoutés',
      one: '1 aliment ajouté',
      zero: 'Rien à copier',
    );
    return '$_temp0';
  }

  @override
  String get anneeNaissance => 'Année de naissance';

  @override
  String get auQuotidien => 'Au quotidien, hors sport';

  @override
  String aucunAliment(String q) {
    return 'Rien trouvé pour « $q ». Essaie un mot plus simple, ou une entrée rapide.';
  }

  @override
  String get baseIndisponible => 'La base d\'aliments n\'a pas pu être lue.';

  @override
  String get calculIndicatif => 'Selon le calcul';

  @override
  String get chargementBase => 'Chargement de la base d\'aliments…';

  @override
  String get chercherAliment => 'Chercher un aliment (banane, riz, poulet…)';

  @override
  String commeHier(String contenu) {
    return 'Comme hier : $contenu';
  }

  @override
  String get compterSeances => 'Compter mes séances';

  @override
  String get compterSeancesDetail =>
      'La moyenne des calories de tes séances (14 jours) s\'ajoute à tes besoins.';

  @override
  String conseilApresSeance(int n) {
    return 'Séance faite : il te reste $n g de protéines. Une collation (lait, yogourt grec, œufs) aide tes muscles à récupérer.';
  }

  @override
  String get conseilAtteint1 =>
      'Objectifs atteints aujourd\'hui. Beau travail.';

  @override
  String get conseilAtteint2 =>
      'Calories et protéines au rendez-vous : exactement ce qu\'il fallait.';

  @override
  String get conseilAtteint3 =>
      'Tout y est aujourd\'hui. Ton corps te dit merci.';

  @override
  String get conseilDejeuner1 =>
      'Un déjeuner avec des protéines (œufs, yogourt grec, beurre d\'arachide) tient jusqu\'au dîner.';

  @override
  String get conseilDejeuner2 =>
      'Pas encore déjeuné ? Même petit, un déjeuner lance bien la journée.';

  @override
  String get conseilDepasse1 =>
      'Journée copieuse, ça arrive. Demain, on reprend simplement le rythme.';

  @override
  String get conseilDepasse2 =>
      'Un peu au-dessus aujourd\'hui : rien de grave, c\'est la semaine qui compte.';

  @override
  String conseilEau(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n verres d\'eau',
      one: '1 verre d\'eau',
      zero: 'Pas encore d\'eau',
    );
    return '$_temp0 sur $m : un grand verre maintenant ?';
  }

  @override
  String get conseilGuide1 =>
      'La moitié de l\'assiette en légumes et fruits, un quart en protéines, un quart en grains entiers.';

  @override
  String get conseilGuide2 =>
      'L\'eau est la boisson de choix : un verre à chaque repas, c\'est déjà beaucoup.';

  @override
  String get conseilGuide3 =>
      'Cuisiner plus souvent chez soi : on sait ce qu\'il y a dans l\'assiette.';

  @override
  String get conseilGuide4 =>
      'Des protéines à chaque repas aident à tenir jusqu\'au suivant.';

  @override
  String get conseilGuide5 =>
      'Les grains entiers (avoine, riz brun, pain complet) rassasient plus longtemps.';

  @override
  String get conseilGuide6 =>
      'Manger sans écran, lentement, en savourant : on sent mieux quand on a assez mangé.';

  @override
  String get conseilGuide7 =>
      'Les légumineuses (lentilles, pois chiches, haricots) : protéines et fibres, pour peu cher.';

  @override
  String conseilPrendreSoir(String n) {
    return 'Pour prendre du poids, il te manque encore $n kcal : une collation dense (noix, beurre d\'arachide, lait) fait la différence.';
  }

  @override
  String get conseilProfil =>
      'Dis-moi ton sexe, ton âge et ta taille : tes objectifs seront calculés pour toi.';

  @override
  String conseilProteinesSoir(int n) {
    return 'Il te reste $n g de protéines : poulet, poisson, tofu ou légumineuses au souper les couvrent.';
  }

  @override
  String dejaDansRepas(int n, String kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Déjà $n aliments · $kcal',
      one: 'Déjà 1 aliment · $kcal',
      zero: 'Rien encore',
    );
    return '$_temp0';
  }

  @override
  String detailObjectifs(String kcal, String p) {
    return '$kcal · protéines $p';
  }

  @override
  String get dontFibres => 'dont fibres';

  @override
  String get dontSatures => 'dont saturés';

  @override
  String get dontSucres => 'dont sucres';

  @override
  String get eauAtteinte => 'Objectif d\'eau atteint. Bravo !';

  @override
  String eauAtteinteHabitude(String nom) {
    return 'Objectif d\'eau atteint : « $nom » est cochée.';
  }

  @override
  String get eauCalculee => 'Eau calculée pour moi';

  @override
  String get eauCalculeeDetail =>
      'Selon ton poids, et un verre de plus par demi-heure de sport.';

  @override
  String eauObjectif(int n, String l) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n verres d\'eau par jour ($l L)',
      one: '1 verre d\'eau par jour ($l L)',
      zero: 'Pas d\'objectif d\'eau',
    );
    return '$_temp0';
  }

  @override
  String get enGrammes => 'En grammes';

  @override
  String get entreeRapide => 'Entrée rapide';

  @override
  String get entreeRapideAide => 'Des calories sans chercher l\'aliment';

  @override
  String get entreeRapideExplication =>
      'Pour un repas au restaurant ou chez des amis : les calories suffisent ; les macronutriments, si tu les connais.';

  @override
  String entreeRapideNommee(String q) {
    return 'Entrée rapide : « $q »';
  }

  @override
  String get estimationProfil =>
      'Une estimation : complète « Moi » ci-dessous et note ton poids.';

  @override
  String get fixerMesObjectifs => 'Fixer mes objectifs moi-même';

  @override
  String get fixerMesObjectifsDetail =>
      'Tes chiffres remplacent le calcul (le plan d\'une nutritionniste, par exemple).';

  @override
  String gValeur(String n) {
    return '$n g';
  }

  @override
  String get grammesPortion => 'Grammes';

  @override
  String get indiceEntreeRapide => 'Poutine, pizza, souper au resto…';

  @override
  String get indiceNomProduit => 'Barre protéinée, céréales…';

  @override
  String get indicePortion => '1 barre';

  @override
  String get jourDeSeanceGlucides =>
      'Jour de séance : un peu plus de glucides, un peu moins de lipides.';

  @override
  String get kcalEnPlus => 'kcal de plus';

  @override
  String get kcalParJour => 'kcal par jour';

  @override
  String get kcalRequises => 'Note au moins les calories.';

  @override
  String kgParSemaine(String n) {
    return '$n kg par semaine';
  }

  @override
  String get leCalcul => 'Le calcul';

  @override
  String get lienHabitudeEau => 'Cocher l\'habitude de l\'eau';

  @override
  String get lienHabitudeEauDetail =>
      'Atteindre ton objectif d\'eau coche ton habitude de l\'eau.';

  @override
  String litresValeur(String n) {
    return '$n L';
  }

  @override
  String macrosExplication(String pk) {
    return 'Protéines : $pk g par kilo. Lipides : 30 % des calories (25 % un jour de séance). Glucides : le reste.';
  }

  @override
  String get marqueFacultatif => 'Marque (facultatif)';

  @override
  String get mesObjectifs => 'Mes objectifs';

  @override
  String get mesProduits => 'Mes produits';

  @override
  String get mesProduitsAide => 'Les aliments achetés, avec leur étiquette';

  @override
  String get mesProduitsExplication =>
      'Recopie une fois le tableau de la valeur nutritive d\'un produit (barre, yogourt, céréales) : il se note ensuite d\'un toucher.';

  @override
  String get metabolismeBase => 'Métabolisme de base';

  @override
  String get metabolismeBaseDetail =>
      'Ce que ton corps dépense au repos (Mifflin-St Jeor)';

  @override
  String get modifierProduit => 'Modifier le produit';

  @override
  String get moi => 'Moi';

  @override
  String get moment => 'Moment';

  @override
  String get monObjectif => 'Mon objectif';

  @override
  String get monProduit => 'Mon produit';

  @override
  String get nomDansJournal => 'Nom dans mon journal';

  @override
  String get nomFacultatif => 'Nom (facultatif)';

  @override
  String get nomProduit => 'Nom';

  @override
  String nombreDe(String unite) {
    return 'Portions ($unite)';
  }

  @override
  String get nombreDePortions => 'Portions';

  @override
  String get noterUnRepas => 'Noter un repas';

  @override
  String get nouveauProduit => 'Nouveau produit';

  @override
  String get nouveauProduitAide => 'Recopier l\'étiquette d\'un produit acheté';

  @override
  String get objectifPerdre => 'Perdre du poids';

  @override
  String get objectifMaintenir => 'Maintenir';

  @override
  String get objectifPrendre => 'Prendre du poids';

  @override
  String objectifPerdreDetail(String kcal) {
    return 'Un déficit de $kcal par jour : une perte douce, qui garde le muscle (protéines plus hautes).';
  }

  @override
  String get objectifMaintenirDetail =>
      'Autant de calories que tu en dépenses.';

  @override
  String objectifPrendreDetail(String kcal) {
    return 'Un surplus de $kcal par jour : une prise lente, surtout du muscle si tu t\'entraînes.';
  }

  @override
  String get objectifsEstimes => 'Une estimation : à compléter';

  @override
  String get objectifsFixesMain => 'Tes objectifs sont fixés à la main.';

  @override
  String get ouEnGrammes => 'Ou en grammes';

  @override
  String get pasAvisMedical =>
      'Des repères pour bien se nourrir, pas un avis médical. En cas de doute (grossesse, maladie, troubles alimentaires), parles-en à un professionnel de la santé.';

  @override
  String get poidsAucun => 'Aucune pesée : ajoute-la dans les Mesures';

  @override
  String poidsDepuisMesures(String date) {
    return 'Dernière pesée le $date · Mesures';
  }

  @override
  String get portionEtiquette => 'Portion (étiquette)';

  @override
  String pour100g(String kcal, String p) {
    return '$kcal · protéines $p · pour 100 g';
  }

  @override
  String get produitAjoute => 'Produit ajouté';

  @override
  String get produitModifie => 'Produit modifié';

  @override
  String produitsNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n produits',
      one: '1 produit',
      zero: 'Aucun produit',
    );
    return '$_temp0';
  }

  @override
  String proteinesCourt(String g) {
    return 'protéines $g';
  }

  @override
  String get quantite => 'Quantité';

  @override
  String get quantiteRequise => 'Choisis une quantité.';

  @override
  String get recents => 'Récents';

  @override
  String get repasVide => 'Rien de noté pour ce repas.';

  @override
  String get retirerDuRepas => 'Retirer du repas';

  @override
  String get rienDeNote => 'Rien de noté';

  @override
  String get rienEncore => 'Rien de noté pour l\'instant.';

  @override
  String get seancesMoyenne => 'Séances (moyenne de 14 jours)';

  @override
  String get seancesNonComptees => 'Non comptées';

  @override
  String get sexeFemme => 'Femme';

  @override
  String get sexeHomme => 'Homme';

  @override
  String get sodium => 'Sodium';

  @override
  String get sourceFcen =>
      'Valeurs nutritives : Fichier canadien sur les éléments nutritifs 2026, Santé Canada.';

  @override
  String get supprimerProduit => 'Supprimer le produit';

  @override
  String get taille => 'Taille';

  @override
  String get total => 'Total';

  @override
  String get unePortion => '1 portion';

  @override
  String get valeurNutritive => 'Valeur nutritive';

  @override
  String get valeurNutritiveAide => 'Pour UNE portion, comme sur l\'étiquette.';

  @override
  String get verresParJour => 'Verres par jour';

  @override
  String verresSur(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n verres',
      one: '1 verre',
      zero: 'Aucun verre',
    );
    return '$_temp0 sur $m';
  }

  @override
  String kcalDePlus(String n) {
    return '$n kcal de plus';
  }

  @override
  String get aConsommerAvant => 'À consommer avant';

  @override
  String get aConsommerBientot => 'À consommer bientôt';

  @override
  String aConsommerBientotNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n à consommer bientôt',
      one: '1 à consommer bientôt',
      zero: 'rien à consommer bientôt',
    );
    return '$_temp0';
  }

  @override
  String aConsommerDici(String quand) {
    return 'À consommer $quand';
  }

  @override
  String get aTemperatureAmbiante => 'À l\'armoire ou sur le comptoir';

  @override
  String get ajouterAuGardeManger => 'Ajouter au garde-manger';

  @override
  String get ajouterMagasin => 'Ajouter un magasin';

  @override
  String alimentRange(String nom) {
    return 'Rangé : $nom';
  }

  @override
  String alimentsNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n aliments',
      one: '1 aliment',
      zero: 'Aucun aliment',
    );
    return '$_temp0';
  }

  @override
  String alimentsRanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n aliments rangés',
      one: '1 aliment rangé',
      zero: 'Rien de rangé',
    );
    return '$_temp0';
  }

  @override
  String articleAjoute(String texte) {
    return 'Ajouté : $texte';
  }

  @override
  String articleFusionne(String texte) {
    return 'Déjà sur la liste, quantités additionnées : $texte';
  }

  @override
  String articlesEstimation(int n, String prix) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n articles · env. $prix à la caisse',
      one: '1 article · env. $prix à la caisse',
      zero: 'Aucun article',
    );
    return '$_temp0';
  }

  @override
  String articlesNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n articles',
      one: '1 article',
      zero: 'Aucun article',
    );
    return '$_temp0';
  }

  @override
  String get auMagasin => 'Au magasin';

  @override
  String auPanierPrix(String prix) {
    return 'au panier : $prix';
  }

  @override
  String get auPoids => 'Au poids';

  @override
  String get auPoidsDetail => 'Fruits, légumes, viandes pesés à la caisse';

  @override
  String get aucune => 'Aucune';

  @override
  String get aucuneEpicerie => 'Aucune épicerie encore';

  @override
  String get aucuneEpicerieAide =>
      'Tes épiceries apparaîtront ici, avec les prix payés : terminer les courses au magasin les enregistre.';

  @override
  String budgetDepasse(String prix) {
    return 'Budget du mois dépassé de $prix';
  }

  @override
  String budgetDuMois(String depense, String budget) {
    return 'Ce mois-ci : $depense sur $budget';
  }

  @override
  String get budgetEpicerie => 'Budget d\'épicerie';

  @override
  String get budgetEpicerieDetail =>
      'Au magasin, ce qu\'il en reste ce mois-ci.';

  @override
  String budgetRestant(String prix) {
    return 'Reste du budget du mois : $prix';
  }

  @override
  String get canalGardeMangerDescription =>
      'Les aliments à consommer d\'ici le lendemain.';

  @override
  String get canalGardeMangerNom => 'Garde-manger';

  @override
  String get cestFini => 'C\'est fini';

  @override
  String get changement15Juillet => 'Depuis le 15 juillet 2026';

  @override
  String get changement15JuilletTexte =>
      'Plus de TVQ (la TPS reste) sur : les barres et mélanges granola, les noix et graines salées, les pâtisseries à l\'unité (moins de 230 g ou paquet de moins de 6), les desserts glacés de moins de 500 g, les coupes de dessert de moins de 425 g, les plateaux de fruits ou de légumes coupés, le papier hygiénique et les mouchoirs. Au restaurant et dans les machines distributrices, rien ne change.';

  @override
  String get combien => 'Combien';

  @override
  String get commentLeGarder => 'Comment le garder';

  @override
  String conseilPeremption(String noms) {
    return 'À consommer d\'ici demain : $noms. À cuisiner en premier.';
  }

  @override
  String get consigne => 'Consigne';

  @override
  String get consigneAide =>
      'Canettes et bouteilles de boisson : 10 ¢ ; le verre de 500 ml et plus : 25 ¢. Remboursée au retour, jamais taxée.';

  @override
  String get consigneTexte =>
      'Presque tous les contenants de boisson de 100 ml à 2 L sont consignés : 10 ¢ chacun, 25 ¢ pour le verre de 500 ml et plus. Elle s\'ajoute au total, sans taxe, et se récupère en rapportant les contenants.';

  @override
  String consigneValeur(String prix) {
    return 'consigne $prix';
  }

  @override
  String dansLePanier(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Dans le panier · $n',
      one: 'Dans le panier · 1',
      zero: 'Panier vide',
    );
    return '$_temp0';
  }

  @override
  String datePassee(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Date passée depuis $n jours',
      one: 'Date passée d\'un jour',
      zero: 'Date passée',
    );
    return '$_temp0';
  }

  @override
  String dejaAuGardeManger(String texte) {
    return 'Au garde-manger : $texte';
  }

  @override
  String depenseCeMois(String prix) {
    return 'Ce mois-ci : $prix';
  }

  @override
  String deplaceJusquau(String ou, String date) {
    return '$ou : jusqu\'au $date';
  }

  @override
  String dernierPrixVu(String prix, String magasin, String date) {
    return 'Dernier prix : $prix chez $magasin ($date)';
  }

  @override
  String dureeA(String ou, String duree) {
    return '$ou : $duree';
  }

  @override
  String get echeanceAujourdhui => 'aujourd\'hui';

  @override
  String echeanceDans(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'dans $n jours',
      one: 'demain',
      zero: 'aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get echeanceDemain => 'demain';

  @override
  String get echeanceHier => 'hier';

  @override
  String echeancePassee(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'passée de $n jours',
      one: 'hier',
      zero: 'aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String get emplacementArmoire => 'Armoire';

  @override
  String get emplacementComptoir => 'Comptoir';

  @override
  String get emplacementCongelateur => 'Congélateur';

  @override
  String get emplacementFrigo => 'Frigo';

  @override
  String environPrix(String prix) {
    return 'env. $prix';
  }

  @override
  String environPrixKg(String prix) {
    return 'env. $prix / kg';
  }

  @override
  String get epicerie => 'Épicerie';

  @override
  String epicerieDetail(int n, String taxes) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n articles · taxes $taxes',
      one: '1 article · taxes $taxes',
      zero: 'Aucun article',
    );
    return '$_temp0';
  }

  @override
  String get essentiel => 'Essentiel';

  @override
  String get essentielCourt => 'essentiel';

  @override
  String get essentielDetail =>
      'Fini, il revient seul sur la liste de courses.';

  @override
  String get exemplesDetaxe =>
      'Les aliments de base : fruits et légumes, viandes et poissons, lait, yogourt, fromage, œufs, pain, céréales, pâtes, riz, conserves, farine, café, jus 100 %, biscuits en boîte, desserts en grand format.';

  @override
  String get exemplesTps =>
      'Barres et mélanges granola, noix et graines salées, muffins ou beignes à l\'unité, desserts glacés en portion, coupes de pouding, plateaux de fruits ou de légumes coupés, papier hygiénique, mouchoirs.';

  @override
  String get exemplesTpsTvq =>
      'Boissons gazeuses et boissons aux fruits, bonbons, chocolat, croustilles et grignotines, alcool, produits d\'entretien, d\'hygiène et de beauté, la plupart des médicaments sans ordonnance, nourriture pour animaux.';

  @override
  String finiNote(String nom) {
    return 'Fini : $nom.';
  }

  @override
  String finiReassort(String nom) {
    return 'Fini : $nom, remis sur la liste de courses.';
  }

  @override
  String get gardeManger => 'Garde-manger';

  @override
  String get gardeMangerAide =>
      'Touche un aliment : où le garder, combien de temps, ce qu\'il en reste.';

  @override
  String get gardeMangerVide =>
      'Rien au garde-manger. Termine une épicerie pour ranger tes achats, ou ajoute un aliment.';

  @override
  String get gardeMangerVideCourt => 'Tes aliments rangés, et leurs dates';

  @override
  String get historiqueEpiceries => 'Historique des épiceries';

  @override
  String get ilEnReste => 'Il en reste';

  @override
  String get indiceAjoutListe => 'Ajouter : 2 kg poulet, lait x2…';

  @override
  String get indiceAlimentGardeManger => 'Yogourt, restes de chili…';

  @override
  String get indiceImprevu => 'Un imprévu ? Ajoute-le ici';

  @override
  String get indiceNoteArticle => 'La marque, le format…';

  @override
  String intervalle(String a, String b) {
    return '$a à $b';
  }

  @override
  String get jete => 'Jeté';

  @override
  String jeteCeMois(String prix, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Jeté ce mois-ci : $prix ($n aliments)',
      one: 'Jeté ce mois-ci : $prix (1 aliment)',
      zero: 'Rien jeté ce mois-ci',
    );
    return '$_temp0';
  }

  @override
  String get jeteNote => 'Noté au compteur de gaspillage.';

  @override
  String jeteValeur(String prix) {
    return 'Noté : $prix au compteur de gaspillage.';
  }

  @override
  String ligneResume(String prix, String taxes, String consigne) {
    return 'Ligne : $prix + taxes $taxes + consigne $consigne';
  }

  @override
  String get listeDeCourses => 'Liste de courses';

  @override
  String get listeVide => 'Ta liste est vide.';

  @override
  String get listeVideCourt => 'À remplir';

  @override
  String get magasinInconnu => 'un magasin';

  @override
  String meilleurPrix(String prix, String magasin) {
    return 'Meilleur prix vu : $prix chez $magasin';
  }

  @override
  String get mesMagasins => 'Mes magasins';

  @override
  String get mettreAuPanier => 'Au panier';

  @override
  String mettreAuPanierPrix(String prix) {
    return 'Au panier · $prix';
  }

  @override
  String get nePasRanger => 'Ne pas ranger';

  @override
  String notifPeremptionCorps(String noms) {
    return '$noms : à consommer d\'ici demain.';
  }

  @override
  String notifPeremptionCorpsPlus(String noms, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n autres',
      one: '1 autre',
    );
    return '$noms et $_temp0 : à consommer d\'ici demain.';
  }

  @override
  String notifPeremptionTitre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n aliments à consommer',
      one: '1 aliment à consommer',
      zero: 'Garde-manger',
    );
    return '$_temp0';
  }

  @override
  String get nouvelleQuantite => 'Nouvelle quantité';

  @override
  String get ordreDesRayons => 'Ordre des rayons';

  @override
  String get ordreDesRayonsAide =>
      'Celui de ton magasin : maintiens une ligne pour la déplacer. La liste et le magasin suivent cet ordre.';

  @override
  String get ou => 'Où';

  @override
  String get ouvert => 'ouvert';

  @override
  String get ouvertAujourdhui => 'Ouvert aujourd\'hui';

  @override
  String ouvertDetail(String duree) {
    return 'Une fois ouvert : $duree';
  }

  @override
  String ouvertLe(String date) {
    return 'ouvert le $date';
  }

  @override
  String get panierVide => 'Le panier est vide.';

  @override
  String paquets(int n, String v) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$v paquets',
      one: '$v paquet',
      zero: '$v paquet',
    );
    return '$_temp0';
  }

  @override
  String get parDate => 'Par date';

  @override
  String get parKg => 'Au kg';

  @override
  String get parLivre => 'À la livre';

  @override
  String get parMois => 'Par mois';

  @override
  String get parRayon => 'Par rayon';

  @override
  String pasAuGardeManger(String noms) {
    return 'Pas au garde-manger : $noms.';
  }

  @override
  String get pasDeRepere => 'Pas de repère : ajuste la date toi-même.';

  @override
  String poidsAPrix(String poids, String prix) {
    return '$poids à $prix';
  }

  @override
  String pourOrigines(String noms) {
    return 'pour : $noms';
  }

  @override
  String prixAuKg(String prix) {
    return '$prix / kg';
  }

  @override
  String prixConnusPour(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Prix connus pour $n articles',
      one: 'Prix connu pour 1 article',
      zero: 'Aucun prix connu',
    );
    return '$_temp0';
  }

  @override
  String get prixEtPoidsRequis => 'Entre le prix et le poids.';

  @override
  String prixParUnite(String unite) {
    return 'Prix / $unite';
  }

  @override
  String get prixPaye => 'Prix payé';

  @override
  String get prixPayeFacultatif => 'Prix payé (facultatif)';

  @override
  String get prixRequis => 'Entre le prix.';

  @override
  String get prixUnitaire => 'Prix à l\'unité';

  @override
  String get prixVus => 'Prix vus';

  @override
  String get quantiteFacultatif => 'Quantité (facultatif)';

  @override
  String get quantiteMiseAJour => 'Quantité mise à jour.';

  @override
  String quantitesFusionnees(String texte) {
    return 'Fusionnées : $texte. Une nouvelle quantité les remplace.';
  }

  @override
  String get raisonAlUnite =>
      'À l\'unité (moins de 6) : TPS seulement depuis le 15 juillet 2026. Par 6 et plus : détaxé.';

  @override
  String get raisonAlcool => 'Alcool : TPS et TVQ.';

  @override
  String get raisonBase => 'Un aliment de base : détaxé.';

  @override
  String get raisonGrignotines =>
      'Grignotines, bonbons, chocolat, boissons gazeuses : TPS et TVQ.';

  @override
  String get raisonHygieneDetaxee => 'Protections menstruelles : détaxées.';

  @override
  String get raisonNonAlimentaire => 'Pas un aliment : TPS et TVQ.';

  @override
  String get raisonTvqAbolie =>
      'Plus de TVQ depuis le 15 juillet 2026 : TPS seulement.';

  @override
  String get ranger => 'Ranger';

  @override
  String get rangerExplication =>
      'Où ranger chaque aliment, jusqu\'à quand, et comment le garder longtemps (d\'après le Thermoguide du MAPAQ). Ajuste la date selon l\'emballage.';

  @override
  String get rangerPlusTard =>
      'Revenir en arrière laisse tes achats hors du garde-manger.';

  @override
  String get rappelsPeremption => 'Rappels de péremption';

  @override
  String get rappelsPeremptionDetail =>
      'Le matin, ce qui est à consommer d\'ici le lendemain.';

  @override
  String get rayon => 'Rayon';

  @override
  String get rayonAutre => 'Autre';

  @override
  String get rayonBoissons => 'Boissons';

  @override
  String get rayonBoulangerie => 'Boulangerie';

  @override
  String get rayonCereales => 'Céréales, pâtes et riz';

  @override
  String get rayonCollations => 'Collations et sucreries';

  @override
  String get rayonCondiments => 'Condiments, sauces et huiles';

  @override
  String get rayonConserves => 'Conserves et soupes';

  @override
  String get rayonEntretien => 'Entretien';

  @override
  String get rayonEpices => 'Épices et pâtisserie';

  @override
  String get rayonFruits => 'Fruits';

  @override
  String get rayonHygiene => 'Hygiène et pharmacie';

  @override
  String get rayonLaitiers => 'Produits laitiers et œufs';

  @override
  String get rayonLegumes => 'Légumes et fines herbes';

  @override
  String get rayonLegumineuses => 'Légumineuses, tofu et noix';

  @override
  String get rayonPoissons => 'Poissons et fruits de mer';

  @override
  String get rayonSurgeles => 'Surgelés';

  @override
  String get rayonViandes => 'Viandes';

  @override
  String get rayonsMagasinsBudget => 'Rayons, magasins et budget';

  @override
  String resteAPrendre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Encore $n articles',
      one: 'Encore 1 article',
      zero: 'Tout est pris',
    );
    return '$_temp0';
  }

  @override
  String get retirerDeLaListe => 'Retirer de la liste';

  @override
  String get retirerDuPanier => 'Retirer du panier';

  @override
  String get retirerErreur => 'Retirer (une erreur)';

  @override
  String retirerMagasin(String magasin) {
    return 'Retirer $magasin';
  }

  @override
  String get rienIci => 'Rien ici.';

  @override
  String get sansDate => 'Sans date';

  @override
  String seGarde(String duree) {
    return 'Se garde : $duree';
  }

  @override
  String get sourcesTaxes =>
      'Sources : Revenu Québec (produits alimentaires de base), mesure du 15 juillet 2026, RECYC-QUÉBEC (consigne). Une indication : le reçu fait foi.';

  @override
  String get sousTotal => 'Sous-total';

  @override
  String sousTotalValeur(String prix) {
    return 'sous-total $prix';
  }

  @override
  String get supprimerEpicerie => 'Supprimer cette épicerie';

  @override
  String surBudget(String depense, String budget) {
    return '$depense / $budget';
  }

  @override
  String surLaListe(String quantite) {
    return 'Sur la liste : $quantite';
  }

  @override
  String get surLaListeAction => 'Remettre sur la liste';

  @override
  String get surLaListeDetail => 'Pour le racheter';

  @override
  String tauxEnVigueur(String tps, String tvq, String total) {
    return 'TPS $tps + TVQ $tvq = $total';
  }

  @override
  String get tauxExplication =>
      'Chacune se calcule sur le prix avant taxes de ce qui y est soumis, arrondie au cent. Si un taux change, Rhythm l\'applique à sa date.';

  @override
  String get taxe => 'Taxe';

  @override
  String get taxeChoisie => 'Choisi à la main.';

  @override
  String get taxeDetaxe => 'Détaxé';

  @override
  String get taxeTps => 'TPS seulement';

  @override
  String get taxeTpsTvq => 'TPS + TVQ';

  @override
  String get taxesDuQuebec => 'Les taxes du Québec';

  @override
  String get taxesDuQuebecDetail => 'Ce qui est taxé, et depuis quand';

  @override
  String get tesHabituels => 'Tes habituels';

  @override
  String get totalCaisse => 'Total à la caisse';

  @override
  String totalPaye(String prix) {
    return '$prix payés';
  }

  @override
  String get toucherPourJeter => 'Toucher encore : jeté';

  @override
  String get toucherPourTerminer => 'Toucher encore';

  @override
  String get toucherPourVider => 'Toucher encore pour vider';

  @override
  String get tout => 'Tout';

  @override
  String get toutEstPris => 'Tout est pris';

  @override
  String toutRanger(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ranger $n aliments',
      one: 'Ranger 1 aliment',
      zero: 'Rien à ranger',
    );
    return '$_temp0';
  }

  @override
  String tpsValeur(String prix) {
    return 'TPS $prix';
  }

  @override
  String tvqValeur(String prix) {
    return 'TVQ $prix';
  }

  @override
  String get tuDecides => 'Tu décides';

  @override
  String get tuDecidesTexte =>
      'Rhythm propose un statut d\'après le nom et le rayon, et dit pourquoi ; c\'est toi qui l\'appliques, d\'un toucher. En cas de doute, le reçu fait foi.';

  @override
  String get uneFoisOuvert => 'Une fois ouvert';

  @override
  String get unitePaquet => 'paquet';

  @override
  String get uniteUnite => 'unité';

  @override
  String get viderLaListe => 'Vider la liste';

  @override
  String ligneResumeSansConsigne(String prix, String taxes) {
    return 'Ligne : $prix + taxes $taxes';
  }

  @override
  String get revenuSeul => 'revenu seul (essentiel fini)';

  @override
  String get triRecentes => 'Récentes';

  @override
  String get triAlphabetique => 'A à Z';

  @override
  String get triProteines => 'Protéines';

  @override
  String get triCalories => 'Calories';

  @override
  String get triRapides => 'Rapides';

  @override
  String portionUne(String nombre) {
    return '$nombre portion';
  }

  @override
  String portionsPlusieurs(String nombre) {
    return '$nombre portions';
  }

  @override
  String conseilDecongeler(String noms) {
    return 'Ce soir, du congélateur au frigo : $noms (pour demain).';
  }

  @override
  String get canalDecongelationNom => 'Décongélation';

  @override
  String get canalDecongelationDescription =>
      'La veille d\'un repas prévu, ce qu\'il faut sortir du congélateur';

  @override
  String get notifDecongelationTitre => 'À sortir du congélateur';

  @override
  String notifDecongelationCorps(String articles) {
    return 'Au frigo ce soir, pour demain : $articles.';
  }

  @override
  String notifDecongelationPour(String plats) {
    return 'Pour : $plats.';
  }

  @override
  String get canalMinuteursNom => 'Minuteurs de cuisine';

  @override
  String get canalMinuteursDescription =>
      'La fin d\'un minuteur lancé en cuisinant';

  @override
  String get notifMinuteurTitre => 'Minuteur : c\'est l\'heure';

  @override
  String proteinesDe(String g) {
    return '$g de protéines';
  }

  @override
  String get cestLHeure => 'C\'est l\'heure';

  @override
  String get plusUneMinute => '+1 min';

  @override
  String get arreterMinuteur => 'Arrêter le minuteur';

  @override
  String recettesAjoutees(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n recettes ajoutées',
      one: '1 recette ajoutée',
      zero: 'Tes recettes y sont déjà',
    );
    return '$_temp0';
  }

  @override
  String get mesRecettes => 'Mes recettes';

  @override
  String get mesRecettesAide => 'Écris les tiennes, ou pars de huit recettes';

  @override
  String recettesNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n recettes',
      one: '1 recette',
      zero: 'Aucune recette',
    );
    return '$_temp0';
  }

  @override
  String get nouvelleRecette => 'Nouvelle recette';

  @override
  String get maSemaine => 'Ma semaine';

  @override
  String get livreVide =>
      'Ton livre de recettes est vide. Écris une recette — ses macros se calculent seules, d\'après la base — ou pars de huit recettes simples.';

  @override
  String get recettesDeDepart => 'Recettes de départ';

  @override
  String get recettesDeDepartDetail =>
      'Huit plats simples, du déjeuner au souper, d\'ici et d\'ailleurs (valeurs du FCÉN)';

  @override
  String get chercherRecette => 'Chercher une recette, un ingrédient';

  @override
  String get toutesLesRegions => 'Toutes les régions';

  @override
  String aucuneRecette(String requete) {
    return 'Aucune recette pour « $requete ».';
  }

  @override
  String get macrosCalculees =>
      'Macros calculées d\'après le Fichier canadien sur les éléments nutritifs (Santé Canada).';

  @override
  String get modifierRecette => 'Modifier la recette';

  @override
  String get parPortion => 'Par portion';

  @override
  String preparationDe(String duree) {
    return 'préparation $duree';
  }

  @override
  String cuissonDe(String duree) {
    return 'cuisson $duree';
  }

  @override
  String get cuisiner => 'Cuisiner';

  @override
  String get aLaListe => 'À la liste';

  @override
  String pourRecettePortions(String nom, String portions) {
    return '$nom, pour $portions';
  }

  @override
  String get planifier => 'Planifier';

  @override
  String get noterAuJournal => 'Noter au journal';

  @override
  String restesAuGardeManger(String portions, String detail) {
    return 'Restes : $portions ($detail)';
  }

  @override
  String get ingredients => 'Ingrédients';

  @override
  String get aucunIngredient => 'Aucun ingrédient.';

  @override
  String get dejaLa => 'déjà là';

  @override
  String sansValeurNutritive(String noms) {
    return 'Sans valeur nutritive comptée : $noms.';
  }

  @override
  String get jamaisCuisinee => 'Pas encore cuisinée';

  @override
  String cuisineeFois(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Cuisinée $n fois, la dernière le $date',
      one: 'Cuisinée 1 fois, le $date',
      zero: 'Pas encore cuisinée',
    );
    return '$_temp0';
  }

  @override
  String get seCongeleBien => 'Se congèle bien';

  @override
  String get laRecette => 'La recette';

  @override
  String recetteEnregistree(String nom) {
    return '« $nom » enregistrée';
  }

  @override
  String get nomDeLaRecette => 'Nom de la recette';

  @override
  String get indiceNomRecette => 'Chili sin carne, soupe aux pois…';

  @override
  String get moments => 'Moments';

  @override
  String get cequElleDonne => 'Ce qu\'elle donne';

  @override
  String get preparation => 'Préparation';

  @override
  String get cuisson => 'Cuisson';

  @override
  String get ingredientLibreCourt => 'libre';

  @override
  String get ajouterUnIngredient => 'Ajouter un ingrédient';

  @override
  String get etapesUneParLigne => 'Étapes — une par ligne';

  @override
  String get indiceEtapes => 'Hacher l\'oignon.\nLe faire revenir 5 minutes…';

  @override
  String etapesNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n étapes',
      one: '1 étape',
      zero: 'Aucune étape',
    );
    return '$_temp0';
  }

  @override
  String etapesMinuteurs(int n, String minuteurs) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n étapes · minuteurs : $minuteurs',
      one: '1 étape · minuteurs : $minuteurs',
    );
    return '$_temp0';
  }

  @override
  String get regionFacultatif => 'Région (facultatif)';

  @override
  String get indiceRegion => 'Québécoise, haïtienne, italienne…';

  @override
  String get noteFacultatif => 'Note (facultatif)';

  @override
  String get indiceNoteRecette => 'Un truc, une variante, avec quoi la servir';

  @override
  String get seCongeleDetail =>
      'La cuisine en lot la propose, et ses restes vont d\'emblée au congélateur.';

  @override
  String pourToute(String portions, String kcal) {
    return 'Toute la recette ($portions) : $kcal';
  }

  @override
  String get supprimerRecette => 'Supprimer la recette';

  @override
  String get modifierIngredient => 'Modifier l\'ingrédient';

  @override
  String get unIngredient => 'Un ingrédient';

  @override
  String get chercherIngredient => 'Chercher un aliment';

  @override
  String get ingredientAide =>
      'Cherche dans la base (5 894 aliments, hors ligne) ou dans tes produits : les macros suivent.';

  @override
  String get ingredientLibre => 'Ingrédient libre';

  @override
  String get ingredientLibreAide =>
      'Sans valeur nutritive : sel, poivre, épices, eau.';

  @override
  String ingredientLibreNomme(String texte) {
    return 'Ingrédient libre : « $texte »';
  }

  @override
  String get nomSurLaRecette => 'Nom sur la recette';

  @override
  String get indiceIngredientLibre => 'Sel et poivre';

  @override
  String get ingredientDeLaBase => 'Aliment de la base';

  @override
  String get ajouterALaRecette => 'Ajouter à la recette';

  @override
  String get changerDAliment => 'Changer d\'aliment';

  @override
  String get retirerDeLaRecette => 'Retirer de la recette';

  @override
  String minuteurSonne(String libelle) {
    return 'C\'est l\'heure ! $libelle';
  }

  @override
  String minuteurLibelle(String nom, int n, String duree) {
    return '$nom · étape $n · $duree';
  }

  @override
  String minuteurLance(String duree) {
    return 'Minuteur lancé : $duree';
  }

  @override
  String secondes(int n) {
    return '$n s';
  }

  @override
  String get modeCuisine => 'Mode cuisine';

  @override
  String get pourCombien => 'Pour combien';

  @override
  String miseEnPlace(int fait, int total) {
    return 'Mise en place · $fait sur $total';
  }

  @override
  String get sansEtapes => 'Pas d\'étapes écrites : cuisine à ta façon.';

  @override
  String get cestPret => 'C\'est prêt';

  @override
  String etapeSur(int n, int total) {
    return 'Étape $n sur $total';
  }

  @override
  String lancerMinuteur(String duree) {
    return 'Minuteur $duree';
  }

  @override
  String get precedente => 'Précédente';

  @override
  String get suivante => 'Suivante';

  @override
  String get toutesLesEtapes => 'Toutes les étapes';

  @override
  String nomRestes(String nom) {
    return '$nom (restes)';
  }

  @override
  String noteAuMoment(String portions, String moment) {
    String _temp0 = intl.Intl.selectLogic(moment, {
      'dejeuner': '$portions au déjeuner',
      'diner': '$portions au dîner',
      'collation': '$portions à la collation',
      'souper': '$portions au souper',
      'other': '$portions au journal',
    });
    return '$_temp0';
  }

  @override
  String restesRanges(String portions, String ou) {
    return '$portions en restes · $ou';
  }

  @override
  String get bonAppetit => 'Bon appétit !';

  @override
  String cuisinePortions(String nom, String portions) {
    return '$nom · $portions';
  }

  @override
  String get jEnMangeMaintenant => 'J\'en mange maintenant';

  @override
  String get portionsMangees => 'Portions';

  @override
  String kcalEtProteines(String kcal, String g) {
    return '$kcal · $g de protéines';
  }

  @override
  String lesRestes(String portions) {
    return 'Les restes · $portions';
  }

  @override
  String get auFrigo => 'Au frigo';

  @override
  String get auCongelateur => 'Au congélateur';

  @override
  String get pasDeRestes => 'Pas de restes';

  @override
  String restesJusquau(String date) {
    return 'Jusqu\'au $date';
  }

  @override
  String get restesConseil =>
      'Au frigo dans les 2 heures, en contenants peu profonds : 3 à 4 jours. Congelés : 3 mois, avec la date (Thermoguide du MAPAQ).';

  @override
  String get auGardeManger => 'Au garde-manger';

  @override
  String get auGardeMangerAide =>
      'Ce que la recette a pris. Coche ce qu\'il faut mettre à jour.';

  @override
  String get finiQuestion => 'Quantité inconnue : coche s\'il est fini';

  @override
  String get ilNEnResteraPlus => 'Il n\'en restera plus : fini';

  @override
  String ilEnRestera(String quantite) {
    return 'Il en restera $quantite';
  }

  @override
  String get rienACocher => 'Rien de coché.';

  @override
  String articlesAjoutesListe(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n articles sur la liste',
      one: '1 article sur la liste',
      zero: 'Rien d\'ajouté',
    );
    return '$_temp0';
  }

  @override
  String get dejaSurLaListe => 'Déjà sur la liste';

  @override
  String aAcheter(String quantite) {
    return 'À acheter : $quantite';
  }

  @override
  String aAcheterNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n à acheter',
      one: '1 à acheter',
      zero: 'Rien à acheter',
    );
    return '$_temp0';
  }

  @override
  String dejaLaNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n déjà là',
      one: '1 déjà là',
      zero: 'Rien d\'avance',
    );
    return '$_temp0';
  }

  @override
  String ajouterALaListeNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ajouter $n articles à la liste',
      one: 'Ajouter 1 article à la liste',
      zero: 'Rien à ajouter',
    );
    return '$_temp0';
  }

  @override
  String get ajoutListeAide =>
      'Ce qui est au garde-manger ou déjà sur la liste est retiré ; les doublons fusionnent.';

  @override
  String get rienDePrevuSemaine => 'Rien de prévu cette semaine';

  @override
  String repasPrevusNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n repas prévus',
      one: '1 repas prévu',
      zero: 'Aucun repas prévu',
    );
    return '$_temp0';
  }

  @override
  String get cetteSemaine => 'Cette semaine';

  @override
  String get listeDeLaSemaine => 'Liste de la semaine';

  @override
  String get aucuneRecettePrevue => 'Aucune recette prévue';

  @override
  String get toutEstLa => 'Tout est là';

  @override
  String recettesPrevuesNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Pour $n recettes prévues',
      one: 'Pour 1 recette prévue',
      zero: 'Aucune recette prévue',
    );
    return '$_temp0';
  }

  @override
  String get cuisineEnLot => 'Cuisine en lot';

  @override
  String get cuisineEnLotDetail => 'Cuisiner une fois, manger plusieurs fois';

  @override
  String cuisineEnLotResume(String nom, int n) {
    return '$nom : $n repas, une seule fois';
  }

  @override
  String get aDecongelerCeSoir => 'À décongeler ce soir';

  @override
  String get aDecongelerCeSoirCourt => 'à décongeler ce soir';

  @override
  String get reglages => 'Réglages';

  @override
  String get portionsParRepas => 'Portions par repas';

  @override
  String get portionsParRepasDetail => 'Pour combien tu prévois, d\'habitude';

  @override
  String get rappelDecongelation => 'Rappel de décongélation';

  @override
  String rappelDecongelationDetail(String heure) {
    return 'La veille, à $heure : ce qu\'il faut sortir du congélateur';
  }

  @override
  String prevoirAu(String moment) {
    String _temp0 = intl.Intl.selectLogic(moment, {
      'dejeuner': 'Prévoir le déjeuner',
      'diner': 'Prévoir le dîner',
      'collation': 'Prévoir une collation',
      'souper': 'Prévoir le souper',
      'other': 'Prévoir un repas',
    });
    return '$_temp0';
  }

  @override
  String get rienDePrevuMoment => 'Rien de prévu';

  @override
  String get mangeCourt => 'mangé';

  @override
  String prevuAuToast(String nom, String moment) {
    String _temp0 = intl.Intl.selectLogic(moment, {
      'dejeuner': 'Prévu au déjeuner : $nom',
      'diner': 'Prévu au dîner : $nom',
      'collation': 'Prévu en collation : $nom',
      'souper': 'Prévu au souper : $nom',
      'other': 'Prévu : $nom',
    });
    return '$_temp0';
  }

  @override
  String recettesDuMoment(String moment) {
    String _temp0 = intl.Intl.selectLogic(moment, {
      'dejeuner': 'Pour le déjeuner',
      'diner': 'Pour le dîner',
      'collation': 'Pour la collation',
      'souper': 'Pour le souper',
      'other': 'Pour ce repas',
    });
    return '$_temp0';
  }

  @override
  String get autresRecettes => 'Autres recettes';

  @override
  String get autreChose => 'Autre chose';

  @override
  String get indiceAutreChose => 'Restaurant, souper chez des amis…';

  @override
  String get dejaNoteAuJournal => 'Déjà noté au journal.';

  @override
  String get portionsPrevues => 'Portions prévues';

  @override
  String aSortirLaVeille(String noms) {
    return 'À sortir du congélateur la veille : $noms.';
  }

  @override
  String restesDisponibles(String portions) {
    return '$portions en restes au garde-manger';
  }

  @override
  String get noterCommeMange => 'Noter comme mangé';

  @override
  String get voirLaRecette => 'Voir la recette';

  @override
  String get deplacer => 'Déplacer';

  @override
  String get retirerDuPlan => 'Retirer de ma semaine';

  @override
  String get cuisineEnLotVide =>
      'Aucune recette prévue cette semaine. Prévois tes repas dans Ma semaine : ceux qui reviennent se cuisinent en une fois.';

  @override
  String get aCuisinerCetteSemaine => 'À cuisiner cette semaine';

  @override
  String repasNombreJours(int n, String jours) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n repas ($jours)',
      one: '1 repas ($jours)',
      zero: 'Aucun repas',
    );
    return '$_temp0';
  }

  @override
  String unLotDe(String fois, String portions) {
    return '$fois × la recette ($portions)';
  }

  @override
  String get dejaEnRestes => 'déjà en restes';

  @override
  String get aPreparerEnUneFois => 'À préparer en une fois';

  @override
  String dejaPrevu(String noms) {
    return 'Déjà prévu : $noms';
  }

  @override
  String get ajouterAMaSemaine => 'Ajouter à ma semaine';

  @override
  String get prisDansLesRestes => 'Pris dans les restes';

  @override
  String prevuNoms(String noms) {
    return 'Prévu : $noms';
  }

  @override
  String get prevu => 'Prévu';

  @override
  String get prevuToucher => 'prévu · toucher pour cuisiner ou noter';

  @override
  String get maRecette => 'Ma recette';

  @override
  String get lesRestesTitre => 'Les restes';

  @override
  String mangerUnePortion(String nom) {
    return 'Manger une portion de $nom';
  }

  @override
  String get mangerUnePortionCourt => 'Manger une portion';

  @override
  String get mangerUnePortionDetail => 'Au journal, et décomptée des restes';

  @override
  String get aVerifierPlacard => 'À vérifier au placard';

  @override
  String aVerifierNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n à vérifier',
      one: '1 à vérifier',
      zero: 'Rien à vérifier',
    );
    return '$_temp0';
  }

  @override
  String get revoir => 'Revoir';

  @override
  String get iaErrQuota =>
      'Le service d\'IA a atteint sa limite gratuite pour l\'instant. Réessaie dans une minute.';

  @override
  String get iaErrSurcharge =>
      'Le service d\'IA ne répond pas pour l\'instant. Réessaie dans un moment.';

  @override
  String get iaErrNonAutorise =>
      'Le service d\'IA a refusé la demande (clé non valide).';

  @override
  String get iaErrModele => 'Le modèle d\'IA est indisponible pour l\'instant.';

  @override
  String get iaErrIllisible => 'La réponse de l\'IA était illisible. Réessaie.';

  @override
  String get iaErrReseau =>
      'Pas de connexion Internet : l\'assistant a besoin du réseau.';

  @override
  String get iaErrSansCle =>
      'L\'assistant n\'est pas configuré dans cette version (clé d\'IA absente).';

  @override
  String get reessayer => 'Réessayer';

  @override
  String get mentionIa =>
      'Assistant en ligne (Groq). Rien de personnel ne part : ni ton nom, ni ton poids, ni tes habitudes. Les calories et les macros sont calculées sur ton téléphone, avec la base du FCÉN.';

  @override
  String get horsDeLaBase => 'hors de la base';

  @override
  String get iaAssistant => 'Assistant';

  @override
  String get iaAssistantDetail => 'Idées de recettes, semaine, écart, bilan';

  @override
  String get iaAssistantSurtitre => 'Alimentation · IA';

  @override
  String get iaAssistantIntro =>
      'Je propose, tu choisis : les chiffres restent ceux de Rhythm.';

  @override
  String get iaIdees => 'Idées de recettes';

  @override
  String get iaIdeesCourt => 'Idées';

  @override
  String get iaIdeesDetail => 'Selon la cuisine, le moment et ce que tu as';

  @override
  String get iaIdeesSurtitre => 'Proposées par l\'IA';

  @override
  String get iaAvecCeQuiPresse => 'Avec ce qui presse';

  @override
  String get iaRienNePresse => 'Rien ne presse au garde-manger';

  @override
  String get iaIdeesPourLesUtiliser => 'Des idées pour les utiliser';

  @override
  String get iaIdeesPourLesUtiliserDetail =>
      'Des recettes avec ce qui presse, avant que ça se perde';

  @override
  String get iaEcart => 'Combler l\'écart';

  @override
  String iaIlTeReste(String kcal) {
    return 'Il te reste $kcal aujourd\'hui';
  }

  @override
  String get iaObjectifAtteint => 'Objectif du jour atteint';

  @override
  String get iaPlanifier => 'Planifier ma semaine';

  @override
  String get iaPlanifierAvecIa => 'Planifier avec l\'IA';

  @override
  String get iaPlanifierDetail =>
      'Les cases libres, avec les recettes de ton livre';

  @override
  String get iaPlanifierSurtitre => 'Avec mon livre de recettes';

  @override
  String get iaLivreTropPetit =>
      'Ton livre a moins de trois recettes : ajoute-en d\'abord (des idées, les recettes de départ ou les tiennes), puis l\'IA pourra planifier ta semaine.';

  @override
  String get iaLivreTropPetitCourt => 'Ajoute d\'abord quelques recettes';

  @override
  String get iaEstimer => 'Estimer un repas';

  @override
  String iaEstimerNomme(String nom) {
    return 'Estimer « $nom » avec l\'IA';
  }

  @override
  String get iaEstimerDetailCourt =>
      'Au resto, chez des amis : décris-le, l\'IA le décompose';

  @override
  String get iaEstimerSurtitre => 'Sans recette';

  @override
  String get iaImporter => 'Importer une recette';

  @override
  String get iaImporterDetailCourt =>
      'Colle le texte d\'une recette : l\'IA la met en forme';

  @override
  String get iaImporterSurtitre => 'D\'un site, d\'un courriel, d\'un livre';

  @override
  String get iaBilan => 'Bilan de la semaine';

  @override
  String iaBilanDetail(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n journées notées sur 7',
      one: '1 journée notée sur 7',
      zero: 'Aucune journée notée sur 7',
    );
    return '$_temp0';
  }

  @override
  String get iaAilleurs =>
      'Aussi : « Remplacer un ingrédient » dans une recette, et « Comment le garder ? » pour un aliment que le guide de conservation ne connaît pas.';

  @override
  String get iaAUtiliser => 'À utiliser';

  @override
  String get iaCuisine => 'Cuisine';

  @override
  String get iaPeuImporte => 'Peu importe';

  @override
  String get iaMoment => 'Moment';

  @override
  String get iaGenre => 'Genre de plat';

  @override
  String get iaGenrePlat => 'Plat principal';

  @override
  String get iaGenreSoupe => 'Soupe';

  @override
  String get iaGenreSalade => 'Salade-repas';

  @override
  String get iaGenreSandwich => 'Sandwich, wrap';

  @override
  String get iaGenreBol => 'Bol';

  @override
  String get iaGenreDessert => 'Dessert';

  @override
  String get iaGenreBoisson => 'Smoothie, boisson';

  @override
  String get iaPortions => 'Portions';

  @override
  String get iaOptionRapide => 'Rapide (30 min)';

  @override
  String get iaOptionProteinees => 'Riche en protéines';

  @override
  String get iaOptionVegetarien => 'Végétarien';

  @override
  String get iaOptionGardeManger => 'Avec mon garde-manger';

  @override
  String get iaPrecisions => 'Précisions (facultatif)';

  @override
  String get iaIndicePrecisions => 'sans arachides, au four, petit budget…';

  @override
  String get iaProposer => 'Proposer 3 idées';

  @override
  String get iaAutresIdees => 'Autres idées';

  @override
  String get iaAttenteIdees =>
      'L\'IA cherche des idées… une vingtaine de secondes.';

  @override
  String get iaPropositions => 'Propositions';

  @override
  String get iaAuLivre => 'Au livre';

  @override
  String get iaParPortionCalcule =>
      'Calories par portion calculées par Rhythm avec la base du FCÉN.';

  @override
  String get iaAjouterAuLivre => 'Ajouter à mon livre';

  @override
  String get iaVoirDansLeLivre => 'Voir dans mon livre';

  @override
  String iaAjouteeAuLivre(String nom) {
    return '« $nom » ajoutée à ton livre';
  }

  @override
  String iaHorsBaseDetail(String noms) {
    return 'Hors de la base : $noms (sans valeur nutritive — à préciser dans la recette).';
  }

  @override
  String get iaRecetteAVerifier =>
      'Recette proposée par l\'IA : vérifie-la (cuisson, allergènes). Les valeurs nutritives viennent de la base du FCÉN, calculées par Rhythm.';

  @override
  String get iaTexteDeLaRecette => 'Le texte de la recette';

  @override
  String get iaColler => 'Coller';

  @override
  String get iaIndiceImport => 'Ingrédients, étapes… tel quel';

  @override
  String get iaStructurer => 'Mettre en forme';

  @override
  String get iaAttenteImport => 'L\'IA met la recette en forme…';

  @override
  String get iaPasUneRecette => 'Ce texte ne ressemble pas à une recette.';

  @override
  String get iaTexteTropCourt => 'Colle d\'abord le texte d\'une recette.';

  @override
  String get iaPressePapiersVide => 'Le presse-papiers est vide.';

  @override
  String get iaImporterAide =>
      'Rien n\'est inventé : les ingrédients et les étapes restent ceux de la recette, en unités métriques.';

  @override
  String get iaLesChiffres => 'Les chiffres';

  @override
  String get iaJourneesNotees => 'Journées notées';

  @override
  String iaSurSept(int n) {
    return '$n sur 7';
  }

  @override
  String get iaCaloriesParJour => 'Calories par jour';

  @override
  String get iaProteinesParJour => 'Protéines par jour';

  @override
  String get iaFibresParJour => 'Fibres par jour';

  @override
  String get iaSodiumParJour => 'Sodium par jour';

  @override
  String iaSurObjectif(String valeur, String objectif) {
    return '$valeur / $objectif';
  }

  @override
  String iaRepere(String valeur, String repere) {
    return '$valeur · repère $repere';
  }

  @override
  String iaLimite(String valeur, String limite) {
    return '$valeur · limite $limite';
  }

  @override
  String iaMg(String n) {
    return '$n mg';
  }

  @override
  String iaVerresParJour(String n, int vises) {
    return '$n / $vises verres';
  }

  @override
  String get iaSeances => 'Séances';

  @override
  String get iaJetes => 'Jetés';

  @override
  String get iaSouvent => 'Souvent';

  @override
  String get iaAvis => 'L\'avis de l\'assistant';

  @override
  String get iaAttenteBilan => 'L\'IA lit ta semaine…';

  @override
  String get iaRefaireBilan => 'Refaire le bilan';

  @override
  String get iaBilanPasMedical =>
      'Un repère pour avancer, pas un avis médical : pour un suivi, une diététiste-nutritionniste.';

  @override
  String get iaMomentsARemplir => 'Moments à remplir';

  @override
  String iaCasesLibres(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cases libres sur 7 jours',
      one: '1 case libre sur 7 jours',
      zero: 'Aucune case libre sur 7 jours',
    );
    return '$_temp0';
  }

  @override
  String get iaProposerSemaine => 'Proposer ma semaine';

  @override
  String get iaReproposer => 'Proposer autre chose';

  @override
  String get iaAttenteSemaine => 'L\'IA compose ta semaine…';

  @override
  String get iaRienAPlanifier =>
      'Rien à proposer avec ton livre pour ces cases.';

  @override
  String iaAjouterASemaine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Ajouter $n repas à ma semaine',
      one: 'Ajouter 1 repas à ma semaine',
      zero: 'Rien à ajouter',
    );
    return '$_temp0';
  }

  @override
  String iaRepasAjoutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n repas ajoutés à ta semaine',
      one: '1 repas ajouté à ta semaine',
      zero: 'Aucun repas ajouté',
    );
    return '$_temp0';
  }

  @override
  String get iaPlanDetail =>
      'Ce qui est déjà prévu ne bouge pas. Touche un repas pour le retirer de la proposition.';

  @override
  String get iaResteAujourdhui => 'restent pour aujourd\'hui';

  @override
  String get iaPresqueAtteint =>
      'Tu as presque tout ce qu\'il te faut aujourd\'hui : une petite collation suffira.';

  @override
  String get iaPourQuelRepas => 'Pour quel repas';

  @override
  String get iaDesIdees => 'Des idées';

  @override
  String get iaAttenteEcart => 'L\'IA regarde ce qui te reste…';

  @override
  String iaTotalEtReste(
    String total,
    String proteines,
    String ecart,
    String genre,
  ) {
    String _temp0 = intl.Intl.selectLogic(genre, {
      'plus': '$ecart de plus',
      'other': 'il restera $ecart',
    });
    return 'Total : $total · $proteines de protéines · $_temp0';
  }

  @override
  String get iaNote => 'Noté';

  @override
  String iaNoteAuJournal(String titre) {
    return '« $titre » noté au journal';
  }

  @override
  String iaEcartDetail(String kcal) {
    return 'Objectif du jour : $kcal. Les calories de chaque option sont calculées par Rhythm.';
  }

  @override
  String get iaTonRepas => 'Ton repas';

  @override
  String get iaIndiceEstimer =>
      '2 pointes de pizza toute garnie et une salade César';

  @override
  String get iaEstimerBouton => 'Estimer';

  @override
  String get iaReestimer => 'Estimer de nouveau';

  @override
  String get iaAttenteEstimer => 'L\'IA décompose ton repas…';

  @override
  String get iaRienAEstimer => 'Rien à estimer : décris ce que tu as mangé.';

  @override
  String get iaCeQueJeCompte => 'Ce que je compte';

  @override
  String iaNoterNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Noter $n aliments',
      one: 'Noter 1 aliment',
      zero: 'Rien à noter',
    );
    return '$_temp0';
  }

  @override
  String iaAlimentsNotes(int n, String moment) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n aliments notés',
      one: '1 aliment noté',
      zero: 'Rien de noté',
    );
    return '$_temp0 · $moment';
  }

  @override
  String get iaDecrisTonRepas => 'Décris d\'abord ton repas.';

  @override
  String get iaEstimerDetail =>
      'Une estimation : les quantités sont celles d\'une portion habituelle. Touche une ligne pour la retirer ; un aliment hors de la base n\'est pas compté.';

  @override
  String get iaRemplacer => 'Remplacer un ingrédient';

  @override
  String get iaRemplacerCourt =>
      'Je n\'en ai pas, plus léger, végétarien… l\'IA propose';

  @override
  String get iaQuelIngredient => 'Quel ingrédient';

  @override
  String get iaPourquoiRemplacer => 'Pourquoi';

  @override
  String get iaRaisonManque => 'Je n\'en ai pas';

  @override
  String get iaRaisonLeger => 'Plus léger';

  @override
  String get iaRaisonProteine => 'Plus de protéines';

  @override
  String get iaRaisonVegetarien => 'Végétarien';

  @override
  String get iaRaisonAllergie => 'Allergie';

  @override
  String iaProposerRemplacants(String nom) {
    return 'Remplacer « $nom »';
  }

  @override
  String get iaAttenteRemplacants => 'L\'IA cherche des remplaçants…';

  @override
  String iaParPortionDiff(String kcal, String prot) {
    return 'Par portion : $kcal · $prot de protéines';
  }

  @override
  String get iaRemplacerBouton => 'Remplacer';

  @override
  String iaRemplace(String avant, String apres) {
    return '« $avant » remplacé par « $apres »';
  }

  @override
  String get iaRemplacerDetail =>
      'Les valeurs du remplaçant viennent de la base du FCÉN. En cas d\'allergie, vérifie toujours les étiquettes.';

  @override
  String get iaHorsDuGuide =>
      'Cet aliment n\'est pas dans le guide de conservation : ce sont les repères généraux du rayon.';

  @override
  String get iaCommentLeGarder => 'Comment le garder ?';

  @override
  String get iaAttenteConservation => 'L\'IA cherche comment le garder…';

  @override
  String get iaRepereDeLIa => 'Repère de l\'IA : vérifie aussi l\'emballage.';
}
