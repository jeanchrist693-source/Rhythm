// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get titreApp => 'Rhythm';

  @override
  String get navAccueil => 'Home';

  @override
  String get navSports => 'Sports';

  @override
  String get navAlimentation => 'Nutrition';

  @override
  String get navHabitudes => 'Habits';

  @override
  String get navBiblique => 'Bible';

  @override
  String get navigationPrincipale => 'Main navigation';

  @override
  String get bientot => 'Coming soon';

  @override
  String get bonjour => 'Good morning';

  @override
  String get bonsoir => 'Good evening';

  @override
  String get notifications => 'Notifications';

  @override
  String get versetDuJour => 'Verse of the day';

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String objectifMinutes(int n) {
    return 'goal $n min';
  }

  @override
  String kcal(String n) {
    return '$n kcal';
  }

  @override
  String resteKcal(String n) {
    return '$n kcal left';
  }

  @override
  String surTotal(int n, int total) {
    return '$n of $total';
  }

  @override
  String serieDeJours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n-day streak',
      one: '1-day streak',
      zero: 'no streak',
    );
    return '$_temp0';
  }

  @override
  String get lecture => 'Reading';

  @override
  String chapitreSur(int n, int total) {
    return 'chapter $n of $total';
  }

  @override
  String get prochaineSeance => 'Next session';

  @override
  String seanceEtHeure(String seance, String heure) {
    return '$seance · $heure';
  }

  @override
  String semaineNumero(int n) {
    return 'Week $n';
  }

  @override
  String get minCetteSemaine => 'min this week';

  @override
  String objectifSemaine(int n) {
    return 'goal $n';
  }

  @override
  String get seances => 'Sessions';

  @override
  String get calories => 'Calories';

  @override
  String get serie => 'Streak';

  @override
  String semainesCourt(int n) {
    return '$n wk';
  }

  @override
  String seanceDuJour(String heure) {
    return 'Today\'s session · $heure';
  }

  @override
  String get commencer => 'Start';

  @override
  String get aujourdhui => 'Today';

  @override
  String get kcalRestantes => 'kcal left';

  @override
  String get proteines => 'Protein';

  @override
  String get glucides => 'Carbs';

  @override
  String get lipides => 'Fat';

  @override
  String grammes(int n) {
    return '$n g';
  }

  @override
  String surGrammes(int n) {
    return '/ $n g';
  }

  @override
  String get repas => 'Meals';

  @override
  String get ajouterRepas => 'Add a meal';

  @override
  String get dejeuner => 'Breakfast';

  @override
  String get diner => 'Lunch';

  @override
  String get collation => 'Snack';

  @override
  String get souper => 'Dinner';

  @override
  String get aPlanifier => 'To plan';

  @override
  String get hydratation => 'Hydration';

  @override
  String litresSur(String bu, String objectif) {
    return '$bu L of $objectif L';
  }

  @override
  String joursDaffilee(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days in a row',
      one: '1 day in a row',
      zero: 'No days in a row',
    );
    return '$_temp0';
  }

  @override
  String recordPersonnel(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Personal best: $n days',
      one: 'Personal best: 1 day',
      zero: 'Personal best: none',
    );
    return '$_temp0';
  }

  @override
  String jours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String get partager => 'Share';

  @override
  String get planDeLecture => 'Reading plan';

  @override
  String continuer(String chapitre) {
    return 'Continue · $chapitre';
  }

  @override
  String get priere => 'Prayer';

  @override
  String journalSujets(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Journal · $n topics',
      one: 'Journal · 1 topic',
      zero: 'Journal · no topics',
    );
    return '$_temp0';
  }

  @override
  String get meditation => 'Meditation';

  @override
  String notesSur(String chapitre) {
    return 'Notes on $chapitre';
  }

  @override
  String get aCommencer => 'To start';

  @override
  String serieCourte(int n) {
    return '$n d';
  }

  @override
  String get lesAutresJours => 'Other days';

  @override
  String get liberation => 'Breaking free';

  @override
  String libreDepuisDuree(String duree) {
    return 'free for $duree';
  }

  @override
  String get envieBouton => 'Craving?';

  @override
  String get nouvelleHabitude => 'New habit';

  @override
  String toastJourneeComplete(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Day complete · $n in a row',
      one: 'Day complete',
      zero: 'Day complete',
    );
    return '$_temp0';
  }

  @override
  String toastPalier(int n) {
    return '$n days in a row — a milestone!';
  }

  @override
  String get jourAVenir => 'That day hasn\'t come yet.';

  @override
  String get coachAucune =>
      'Start small: one habit, two minutes a day. Consistency does the rest.';

  @override
  String get coachRienPrevu =>
      'Nothing planned today. Rest — or a bonus habit?';

  @override
  String get coachComplete1 => 'All done. A complete day — enjoy it.';

  @override
  String get coachComplete2 =>
      'Complete day. You\'re keeping your word to yourself.';

  @override
  String get coachComplete3 => 'Nothing missing today. Tomorrow, same rhythm.';

  @override
  String coachCompleteSerie(int n) {
    return 'Complete day — $n in a row. Keep stacking days.';
  }

  @override
  String coachPalier3(String nom) {
    return '3 days in a row for “$nom”. The hardest part was starting.';
  }

  @override
  String coachPalier7(String nom) {
    return 'A full week of “$nom”. It\'s starting to stick.';
  }

  @override
  String coachPalier14(String nom) {
    return 'Two weeks of “$nom”. It\'s no longer an effort, it\'s a rhythm.';
  }

  @override
  String coachPalier21(String nom) {
    return 'Three weeks of “$nom”. It\'s becoming natural.';
  }

  @override
  String coachPalier30(String nom) {
    return 'A month of “$nom”. Look how far you\'ve come.';
  }

  @override
  String coachPalier50(String nom) {
    return '50 days of “$nom”. It\'s part of you now.';
  }

  @override
  String coachPalier66(String nom) {
    return '66 days of “$nom”: on average, the time it takes for a habit to become automatic.';
  }

  @override
  String coachPalier100(String nom) {
    return '100 days of “$nom”. Three digits. Hats off.';
  }

  @override
  String coachPalier365(String nom) {
    return 'A year of “$nom”. A whole year, one day at a time.';
  }

  @override
  String coachPalierAutre(int n, String nom) {
    return '$n days in a row for “$nom”. What consistency.';
  }

  @override
  String coachJamaisDeuxFois1(String nom) {
    return '“$nom” slipped last time. No big deal — but never twice in a row.';
  }

  @override
  String coachJamaisDeuxFois2(String nom) {
    return 'Missing one day doesn\'t undo a habit. Two starts to. “$nom” is waiting.';
  }

  @override
  String get coachMatin1 =>
      'A first check, however small, gets the whole day going.';

  @override
  String get coachMatin2 => 'New day, blank page. Where do we start?';

  @override
  String get coachMatin3 =>
      'Start with the easiest one. Momentum will do the rest.';

  @override
  String get coachApresMidi =>
      'There\'s plenty of day left. Two minutes is enough to start.';

  @override
  String get coachSoirRien =>
      'Evening\'s here. Pick one habit, even the minimal version.';

  @override
  String coachPartiel1(int reste) {
    String _temp0 = intl.Intl.pluralLogic(
      reste,
      locale: localeName,
      other: 'Just $reste left. The hardest part, starting, is done.',
      one: 'Just one left. The hardest part, starting, is done.',
      zero: 'All done.',
    );
    return '$_temp0';
  }

  @override
  String get coachPartiel2 =>
      'Every check counts, even the smallest. Keep the momentum.';

  @override
  String coachPartiel3(int reste) {
    String _temp0 = intl.Intl.pluralLogic(
      reste,
      locale: localeName,
      other: 'You\'re moving. $reste more and the day is complete.',
      one: 'You\'re moving. One more and the day is complete.',
      zero: 'All done.',
    );
    return '$_temp0';
  }

  @override
  String coachSoir(int reste) {
    String _temp0 = intl.Intl.pluralLogic(
      reste,
      locale: localeName,
      other:
          'The evening\'s moving on. $reste left — the minimal version counts too.',
      one:
          'The evening\'s moving on. One left — the minimal version counts too.',
      zero: 'All done.',
    );
    return '$_temp0';
  }

  @override
  String get coachNuit =>
      'It\'s late. Do the minimal version — or rest: tomorrow is a new day.';

  @override
  String get modifier => 'Edit';

  @override
  String get tousLesJours => 'Every day';

  @override
  String rappelA(String heure) {
    return 'reminder at $heure';
  }

  @override
  String get record => 'Record';

  @override
  String get sur30Jours => 'Last 30 days';

  @override
  String valeurFois(int n) {
    return '$n×';
  }

  @override
  String prochainPalier(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Next milestone: $n days',
      one: 'Next milestone: 1 day',
      zero: 'Next milestone',
    );
    return '$_temp0';
  }

  @override
  String encoreJours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n more days',
      one: '1 more day',
      zero: 'it\'s today',
    );
    return '$_temp0';
  }

  @override
  String prochainPalierDuree(String duree) {
    return 'Next milestone: $duree';
  }

  @override
  String dansDuree(String duree) {
    return 'in $duree';
  }

  @override
  String get historique => 'History';

  @override
  String get historiqueAide => 'Tap a past day to check or uncheck it.';

  @override
  String get pourquoi => 'Why';

  @override
  String get monPlan => 'My plan';

  @override
  String get versionMinimale => 'Minimal version';

  @override
  String get versionMinimaleAide =>
      'On hard days, at least this — the streak goes on.';

  @override
  String get ajouterMotivation =>
      'Add your why and your plan: they\'ll help on hard days.';

  @override
  String joursLibresUnite(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'days',
      one: 'day',
      zero: 'days',
    );
    return '$_temp0';
  }

  @override
  String depuisLe(String date) {
    return 'since $date';
  }

  @override
  String get economise => 'Saved';

  @override
  String get enviesSurmontees => 'Cravings overcome';

  @override
  String get jaiUneEnvie => 'I have a craving';

  @override
  String get mesAlternatives => 'My alternatives';

  @override
  String get mesDeclencheurs => 'My triggers';

  @override
  String get journalEnvies => 'Craving log';

  @override
  String intensiteSur10(int n) {
    return 'intensity $n/10';
  }

  @override
  String get tenue => 'Resisted';

  @override
  String get rechute => 'Relapse';

  @override
  String enviesSurtout(String tranche) {
    return 'Your cravings come mostly $tranche.';
  }

  @override
  String get trancheNuit => 'at night';

  @override
  String get trancheMatin => 'in the morning';

  @override
  String get trancheApresMidi => 'in the afternoon';

  @override
  String get trancheSoir => 'in the evening';

  @override
  String declencheurPrincipal(String declencheur) {
    return 'Most frequent trigger: $declencheur.';
  }

  @override
  String rechutesCompte(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n relapses',
      one: '1 relapse',
      zero: 'No relapses',
    );
    return '$_temp0';
  }

  @override
  String get aucuneEnvie =>
      'No cravings logged yet. When one comes, tap “I have a craving”.';

  @override
  String get modifierHabitude => 'Edit habit';

  @override
  String get aConstruire => 'To build';

  @override
  String get aLiberer => 'Break free';

  @override
  String get aConstruireAide => 'A habit to build, day after day.';

  @override
  String get aLibererAide =>
      'An addiction to leave behind: a counter, and support when a craving comes.';

  @override
  String get champNom => 'Name';

  @override
  String get indiceNomConstruire => 'Morning prayer';

  @override
  String get indiceNomLiberer => 'What I\'m breaking free from';

  @override
  String get champCouleur => 'Color';

  @override
  String get champLettre => 'Letter';

  @override
  String get champDetail => 'Detail';

  @override
  String get indiceDetail => 'On waking · 10 min';

  @override
  String get champJours => 'Days';

  @override
  String get champRappel => 'Reminder';

  @override
  String get rappelDiscret =>
      'A discreet word each day, never naming what you\'re breaking free from.';

  @override
  String get heure => 'Time';

  @override
  String get champPourquoi => 'Why';

  @override
  String get indicePourquoi => 'What really matters to me';

  @override
  String get indicePlan => 'When I get up, I pray for 10 minutes.';

  @override
  String get aidePlan =>
      'When [moment], I [action]. A precise plan helps you stick to it.';

  @override
  String get indiceVersionMinimale => '2 minutes, 1 verse, 1 glass';

  @override
  String get champLibreDepuis => 'Free since';

  @override
  String get hier => 'Yesterday';

  @override
  String ilYaJours(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: 'Yesterday',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get champCout => 'Cost per day';

  @override
  String get aideCout => 'To see what you\'re saving.';

  @override
  String get indiceAlternative => 'Add an alternative';

  @override
  String get indiceDeclencheur => 'Add a trigger';

  @override
  String get altEau => 'Drink a big glass of water';

  @override
  String get altMarcher => 'Walk for 5 minutes';

  @override
  String get altAppeler => 'Call someone';

  @override
  String get altPrier => 'Pray';

  @override
  String get altRespirer => 'Breathe slowly';

  @override
  String get altDouche => 'Take a shower';

  @override
  String get declStress => 'Stress';

  @override
  String get declEnnui => 'Boredom';

  @override
  String get declFatigue => 'Tiredness';

  @override
  String get declSolitude => 'Loneliness';

  @override
  String get declColere => 'Anger';

  @override
  String get declSoiree => 'Evenings';

  @override
  String get declEcrans => 'Social media';

  @override
  String get enregistrer => 'Save';

  @override
  String get annuler => 'Cancel';

  @override
  String get ajouter => 'Add';

  @override
  String get supprimerHabitude => 'Delete habit';

  @override
  String get toucherPourSupprimer => 'Tap again to delete';

  @override
  String get nomRequis => 'Give it a name.';

  @override
  String get envieSurtitre => 'The craving will pass';

  @override
  String get tiensBon => 'Hold on';

  @override
  String get vagueTexte =>
      'A craving rises, peaks, then fades — often in under fifteen minutes. You don\'t have to obey it: let it pass like a wave.';

  @override
  String get inspire => 'Breathe in';

  @override
  String get expire => 'Breathe out';

  @override
  String get respirationAide =>
      'Follow the circle: five seconds in, five seconds out.';

  @override
  String get attendreDixMinutes => 'Wait 10 minutes';

  @override
  String minuteurReste(String temps) {
    return '$temps left';
  }

  @override
  String get minuteurFini => 'Ten minutes. How\'s the craving now?';

  @override
  String get tesRaisons => 'Your reasons';

  @override
  String get essaiePlutot => 'Try instead';

  @override
  String get appelerQuelquun => 'Call someone';

  @override
  String get infoSocial => 'Info-Social 811';

  @override
  String get infoSocialDetail => 'Listening and support, 24/7 (Québec)';

  @override
  String get ligne988 => '9-8-8';

  @override
  String get ligne988Detail => 'Crisis or suicidal thoughts, 24/7 (Canada)';

  @override
  String get urgence911 => 'In immediate danger: 911';

  @override
  String get ajouterPersonneConfiance => 'Add a trusted person in Reminders.';

  @override
  String get noterEnvie => 'Log this craving';

  @override
  String get intensite => 'Intensity';

  @override
  String get declencheur => 'Trigger';

  @override
  String get jaiTenu => 'I held on';

  @override
  String get jaiRechute => 'I relapsed';

  @override
  String get bravo => 'Well done.';

  @override
  String get bravoTexte =>
      'One craving down. Every “no” makes the next one easier.';

  @override
  String enviesSurmonteesTotal(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n cravings overcome',
      one: '1 craving overcome',
      zero: 'No cravings overcome',
    );
    return '$_temp0';
  }

  @override
  String get rechuteTitre => 'You haven\'t lost everything.';

  @override
  String rechuteTexte(String duree) {
    return 'A relapse doesn\'t erase the road. You held on for $duree — that\'s real, and it\'s yours.';
  }

  @override
  String get rechuteQuestion => 'What triggered it?';

  @override
  String get remettreAZero => 'Reset the counter';

  @override
  String get toucherPourConfirmer => 'Tap again to confirm';

  @override
  String get recommencer => 'Start again now';

  @override
  String get terminer => 'Done';

  @override
  String get rappels => 'Reminders';

  @override
  String get autorisationOk => 'Notifications allowed';

  @override
  String get autorisationRefusee => 'Blocked by Android';

  @override
  String get autorisationInconnue => 'Not allowed yet';

  @override
  String get ouvrirReglages => 'Open settings';

  @override
  String get autoriser => 'Allow';

  @override
  String get rappelsHabitudes => 'Habit reminders';

  @override
  String get rappelsHabitudesAide =>
      'At the time set for each, on planned days — never if it\'s already done.';

  @override
  String get aucunRappel => 'No reminder';

  @override
  String get toucherPourRegler => 'Tap a habit to set its time.';

  @override
  String get bilanDuSoir => 'Evening check-in';

  @override
  String get bilanDuSoirAide => 'What\'s left to check, at the end of the day.';

  @override
  String get personnesConfiance => 'Trusted people';

  @override
  String get personnesConfianceAide =>
      'One tap to call them when a craving is strong.';

  @override
  String get ajouterPersonne => 'Add a person';

  @override
  String get champTelephone => 'Phone';

  @override
  String get discretionTexte =>
      'Privacy: freedom reminders never name what you\'re breaking free from, and nothing leaves your phone.';

  @override
  String get canalRappelsNom => 'Habit reminders';

  @override
  String get canalRappelsDescription => 'At the time set for each habit.';

  @override
  String get canalBilanNom => 'Evening check-in';

  @override
  String get canalBilanDescription =>
      'What\'s left to check at the end of the day.';

  @override
  String get canalSoutienNom => 'Discreet support';

  @override
  String get canalSoutienDescription =>
      'A word and milestones reached, never naming what you\'re breaking free from.';

  @override
  String notifSerie(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n-day streak — keep the rhythm.',
      one: 'Done yesterday. Keep going?',
      zero: 'It\'s time.',
    );
    return '$_temp0';
  }

  @override
  String notifMinimale(String version) {
    return 'Small still counts: $version.';
  }

  @override
  String notifPourquoi(String pourquoi) {
    return 'Remember: $pourquoi';
  }

  @override
  String get notifGenerique => 'It\'s time. Two minutes is enough to start.';

  @override
  String notifBilanReste(int n, String noms) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n habits left: $noms.',
      one: 'One habit left: $noms.',
      zero: 'All done.',
    );
    return '$_temp0';
  }

  @override
  String get notifBilanGenerique => 'A moment to look back on your day.';

  @override
  String get notifSoutien1 => 'A moment for you. How are you doing today?';

  @override
  String get notifSoutien2 =>
      'You\'re holding on. Rhythm is here if a craving comes.';

  @override
  String get notifSoutien3 => 'Breathe. One day at a time.';

  @override
  String get notifPalierTitre => 'A milestone reached';

  @override
  String notifPalierCorps(String duree) {
    return '$duree — well done. Keep going.';
  }

  @override
  String dureeSemaines(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weeks',
      one: '1 week',
      zero: '0 weeks',
    );
    return '$_temp0';
  }

  @override
  String dureeMois(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n months',
      one: '1 month',
      zero: '0 months',
    );
    return '$_temp0';
  }

  @override
  String dureeAns(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n years',
      one: '1 year',
      zero: '0 years',
    );
    return '$_temp0';
  }

  @override
  String get activer => 'Turn on';

  @override
  String get notifsActiverAide => 'Without them, no reminder can ring.';

  @override
  String get notifsGererAide =>
      'Sounds, channels and lock screen are managed in Android.';

  @override
  String get reglagesAndroid => 'Settings';

  @override
  String get notifsBloqueesRappel =>
      'Notifications are off: this reminder won\'t ring.';

  @override
  String get rappelsEtNotifications => 'Reminders and notifications';

  @override
  String get separateurHeure => ':';

  @override
  String get meLibererDependance => 'Break free from an addiction';

  @override
  String get monOrdre => 'My order';

  @override
  String get parHeure => 'By time';

  @override
  String get deplacerAide => 'Press and hold a habit to move it.';

  @override
  String get epingler => 'Pin to top';

  @override
  String get desepingler => 'Unpin';

  @override
  String get toastEpinglee => 'Pinned to the top';

  @override
  String get toastDesepinglee => 'Unpinned';

  @override
  String get retirerEntree => 'Remove from history?';

  @override
  String get retirer => 'Remove';

  @override
  String get garder => 'Keep';

  @override
  String get journalAide =>
      'Press and hold an entry to remove it — a relapse logged by mistake, for example.';

  @override
  String get styleMusculation => 'Strength';

  @override
  String get stylePoidsDuCorps => 'Bodyweight';

  @override
  String get styleGainage => 'Core';

  @override
  String get styleHiit => 'HIIT and circuit';

  @override
  String get styleMobilite => 'Mobility and stretching';

  @override
  String get styleCardio => 'Cardio';

  @override
  String get materielHalteres => 'Dumbbells';

  @override
  String get materielBarre => 'Barbell';

  @override
  String get materielKettlebell => 'Kettlebell';

  @override
  String get materielElastique => 'Resistance band';

  @override
  String get materielBarreTraction => 'Pull-up bar';

  @override
  String get materielBanc => 'Bench';

  @override
  String get materielChaise => 'Chair or step';

  @override
  String get materielCorde => 'Jump rope';

  @override
  String get materielVelo => 'Bike';

  @override
  String get niveauDebutant => 'Beginner';

  @override
  String get niveauIntermediaire => 'Intermediate';

  @override
  String get niveauAvance => 'Advanced';

  @override
  String get musclePectoraux => 'Chest';

  @override
  String get muscleDos => 'Back';

  @override
  String get muscleTrapezes => 'Traps';

  @override
  String get muscleEpaules => 'Shoulders';

  @override
  String get muscleBiceps => 'Biceps';

  @override
  String get muscleTriceps => 'Triceps';

  @override
  String get muscleAvantBras => 'Forearms';

  @override
  String get muscleAbdos => 'Abs';

  @override
  String get muscleObliques => 'Obliques';

  @override
  String get muscleLombaires => 'Lower back';

  @override
  String get muscleFessiers => 'Glutes';

  @override
  String get muscleQuadriceps => 'Quads';

  @override
  String get muscleIschios => 'Hamstrings';

  @override
  String get muscleAdducteurs => 'Adductors';

  @override
  String get muscleMollets => 'Calves';

  @override
  String get objectifForce => 'Strength';

  @override
  String get objectifVolume => 'Muscle size';

  @override
  String get objectifEndurance => 'Endurance';

  @override
  String get objectifForceDetail => '4 to 6 reps, long rest';

  @override
  String get objectifVolumeDetail => '8 to 12 reps, 60 to 90 s rest';

  @override
  String get objectifEnduranceDetail => '15 to 20 reps, short rest';

  @override
  String get ressentiFacile => 'Easy';

  @override
  String get ressentiCorrect => 'Good';

  @override
  String get ressentiDifficile => 'Hard';

  @override
  String get ressentiEchec => 'Failed';

  @override
  String get effort1 => 'Easy';

  @override
  String get effort2 => 'Moderate';

  @override
  String get effort3 => 'Steady';

  @override
  String get effort4 => 'Hard';

  @override
  String get effort5 => 'Exhausting';

  @override
  String get phaseEchauffement => 'Warm-up';

  @override
  String get phaseEffort => 'Fast';

  @override
  String get phaseRecuperation => 'Easy';

  @override
  String get phaseRetourCalme => 'Cool-down';

  @override
  String get roleSeance => 'Workout';

  @override
  String get recordCharge => 'Heaviest weight';

  @override
  String get recordReps => 'Most reps';

  @override
  String get recordForce => 'Estimated max strength';

  @override
  String get recordDuree => 'Longest hold';

  @override
  String get progresPremiereFois => 'First time: find your weight';

  @override
  String get progresPareil => 'Same as last time';

  @override
  String get progresRepDePlus => 'One more rep than last time';

  @override
  String get progresPlusDeCharge => 'All done last time: a little heavier';

  @override
  String get progresPlusLong => '5 seconds longer than last time';

  @override
  String get seanceDuJourTitre => 'Today\'s workout';

  @override
  String get rienDePrevu => 'Nothing planned today';

  @override
  String prochaineLe(String seance, String quand) {
    return 'Next: $seance · $quand';
  }

  @override
  String get seanceFaiteAujourdhui => 'Done today';

  @override
  String get creerSeance => 'Build a workout';

  @override
  String get banqueExercices => 'Exercise library';

  @override
  String get statistiques => 'Statistics';

  @override
  String get enRecuperation => 'Recovering';

  @override
  String encoreDuree(String duree) {
    return '$duree left';
  }

  @override
  String get recuperationAide =>
      'Trained hard less than 48 h ago: the builder avoids them.';

  @override
  String get coursesTitre => 'Run, walk, ride';

  @override
  String get activiteCourse => 'Run';

  @override
  String get activiteMarche => 'Walk';

  @override
  String get activiteVelo => 'Ride';

  @override
  String get activiteFractionne => 'Intervals';

  @override
  String get programmesProgressifs => 'Step-by-step plans';

  @override
  String get mesSeances => 'My workouts';

  @override
  String get aucuneSeanceEnregistree =>
      'No saved workout yet. Build yours: Rhythm organizes it.';

  @override
  String resumeSeance(int n, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercises',
      one: '1 exercise',
      zero: 'no exercise',
    );
    return '$_temp0 · about $minutes min';
  }

  @override
  String get aLaDemande => 'On demand';

  @override
  String get defisTitre => '4-week challenges';

  @override
  String get voirLesDefis => 'See challenges';

  @override
  String get routinesExpress => 'Quick routines';

  @override
  String dureeMinutesCourt(int n) {
    return '$n min';
  }

  @override
  String get journalSport => 'Log';

  @override
  String get toutLeJournal => 'Full log';

  @override
  String get journalVide => 'Your first workout will show up here.';

  @override
  String get mesures => 'Measurements';

  @override
  String get materielEtObjectifs => 'Equipment and goals';

  @override
  String get monMateriel => 'My equipment';

  @override
  String get materielAide => 'The library shows what you can do with it first.';

  @override
  String get sansMaterielDu => 'Nothing but bodyweight';

  @override
  String get objectif => 'Goal';

  @override
  String get niveau => 'Level';

  @override
  String get poidsDuCorps => 'Body weight';

  @override
  String get poidsAide => 'To estimate calories.';

  @override
  String get minutesParSemaine => 'Minutes per week';

  @override
  String get minutesParJour => 'Minutes per day';

  @override
  String get enchainerOpposes => 'Pair opposite exercises';

  @override
  String get enchainerAide =>
      'Two opposite exercises back to back: a shorter workout.';

  @override
  String get lienHabitude => 'Tick the “Workout” habit';

  @override
  String get lienHabitudeAide => 'A saved workout ticks it for the day.';

  @override
  String kgValeur(String n) {
    return '$n kg';
  }

  @override
  String cmValeur(String n) {
    return '$n cm';
  }

  @override
  String get rechercherExercice => 'Search exercises';

  @override
  String get avecMonMateriel => 'With my equipment';

  @override
  String get sansMateriel => 'No equipment';

  @override
  String get tousLesStyles => 'All styles';

  @override
  String get tousLesMuscles => 'All';

  @override
  String nExercices(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercises',
      one: '1 exercise',
      zero: 'No exercise',
    );
    return '$_temp0';
  }

  @override
  String get aucunExercice => 'No exercise matches.';

  @override
  String get quelMateriel => 'What equipment do you have?';

  @override
  String get quelMaterielAide =>
      'Tell us once: the library shows what you can do first.';

  @override
  String get confirmer => 'Confirm';

  @override
  String get musclesPrincipaux => 'Main muscles';

  @override
  String get musclesSecondaires => 'Secondary muscles';

  @override
  String get materiel => 'Equipment';

  @override
  String get aucunMateriel => 'None';

  @override
  String get polyarticulaire => 'Compound';

  @override
  String get isolation => 'Isolation';

  @override
  String get deChaqueCote => 'Each side';

  @override
  String get etapes => 'Steps';

  @override
  String get erreursFrequentes => 'Common mistakes';

  @override
  String get respiration => 'Breathing';

  @override
  String get variantes => 'Variations';

  @override
  String get plusFacile => 'Easier';

  @override
  String get plusDur => 'Harder';

  @override
  String get tuEsIci => 'You are here';

  @override
  String get tesRecords => 'Your records';

  @override
  String get ajouterASeance => 'Add to a workout';

  @override
  String get nouvelleSeance => 'New workout';

  @override
  String toastAjouteA(String seance) {
    return 'Added to “$seance”';
  }

  @override
  String get lesZones => 'Target areas';

  @override
  String get zonesAide =>
      'Tap the muscles to train, front and back. No area: full body.';

  @override
  String get vueFace => 'Front';

  @override
  String get vueDos => 'Back';

  @override
  String get toutLeCorps => 'Full body';

  @override
  String get effacer => 'Clear';

  @override
  String get lesExercices => 'Exercises';

  @override
  String get exercicesAide => 'Pick your exercises, or let Rhythm fill in.';

  @override
  String get completer => 'Fill in';

  @override
  String get completerAide =>
      'Balanced exercises for your areas, with your equipment.';

  @override
  String nChoisis(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n picked',
      one: '1 picked',
      zero: 'none picked',
    );
    return '$_temp0';
  }

  @override
  String get voirApercu => 'See preview';

  @override
  String evitesRecuperation(String muscles) {
    return 'Avoided, recovering: $muscles';
  }

  @override
  String get choisirUnExercice => 'Pick at least one exercise.';

  @override
  String get pourCesZones => 'For your areas';

  @override
  String get apercu => 'Preview';

  @override
  String get dureeEstimee => 'Estimated time';

  @override
  String environMinutes(int n) {
    return 'about $n min';
  }

  @override
  String get seriesParMuscle => 'Sets per muscle';

  @override
  String get echauffement => 'Warm-up';

  @override
  String get retourAuCalme => 'Cool-down';

  @override
  String dosageReps(int series, int reps) {
    return '$series × $reps';
  }

  @override
  String dosageSecondes(int series, int secondes) {
    return '$series × $secondes s';
  }

  @override
  String dureeSecondes(int n) {
    return '$n s';
  }

  @override
  String reposDe(String duree) {
    return 'rest $duree';
  }

  @override
  String get enchaine => 'Paired';

  @override
  String get ajouterUnExercice => 'Add an exercise';

  @override
  String get series => 'Sets';

  @override
  String get repetitions => 'Reps';

  @override
  String get dureeSerie => 'Time';

  @override
  String get charge => 'Weight';

  @override
  String get repos => 'Rest';

  @override
  String get sansCharge => 'Bodyweight';

  @override
  String get enregistrerLaSeance => 'Save workout';

  @override
  String get indiceNomSeance => 'Upper body, legs, full body…';

  @override
  String get joursPrevus => 'Planned days';

  @override
  String get joursPrevusAide => 'On those days, it becomes “Today\'s workout”.';

  @override
  String get meLeRappeler => 'Remind me';

  @override
  String get supprimerSeance => 'Delete workout';

  @override
  String get toastSeanceEnregistreeProgramme => 'Workout saved';

  @override
  String get retouchesAide => 'Tap a line to adjust it, hold it to move it.';

  @override
  String serieSur(int n, int total) {
    return 'Set $n of $total';
  }

  @override
  String exerciceSur(int n, int total) {
    return '$n of $total';
  }

  @override
  String get serieFaite => 'Set done';

  @override
  String get demarrer => 'Start';

  @override
  String get cestFait => 'Done';

  @override
  String get plusQuinze => '+15 s';

  @override
  String get passer => 'Skip';

  @override
  String get aSuivre => 'Up next';

  @override
  String get commentCetait => 'How was it?';

  @override
  String laDerniereFois(String detail) {
    return 'Last time: $detail';
  }

  @override
  String get arreterSeance => 'Stop the workout?';

  @override
  String get garderCeQuiEstFait => 'Save what\'s done';

  @override
  String get abandonnerSeance => 'Quit without saving';

  @override
  String get reprendre => 'Resume';

  @override
  String get passerExercice => 'Skip exercise';

  @override
  String toastRecord(String detail) {
    return 'New record: $detail!';
  }

  @override
  String get reposFini => 'Rest\'s over';

  @override
  String get chaqueCote => 'each side';

  @override
  String get pret => 'Get ready';

  @override
  String get seanceTerminee => 'Workout complete';

  @override
  String get duree => 'Time';

  @override
  String get volume => 'Volume';

  @override
  String get seriesFaites => 'Sets';

  @override
  String get recordsBattus => 'Records broken';

  @override
  String get ressentiGlobal => 'How it felt';

  @override
  String get note => 'Note';

  @override
  String get indiceNote => 'What you noticed, what changed…';

  @override
  String get toastSeanceEnregistree => 'Workout saved';

  @override
  String toastSeanceHabitude(String habitude) {
    return 'Workout saved · “$habitude” ticked';
  }

  @override
  String get toastEtapeValidee => 'Workout saved · step completed';

  @override
  String get enCours => 'Running';

  @override
  String get enPause => 'Paused';

  @override
  String get pause => 'Pause';

  @override
  String get distance => 'Distance';

  @override
  String get indiceKm => 'in km';

  @override
  String get allure => 'Pace';

  @override
  String get vitesse => 'Speed';

  @override
  String allureValeur(String temps) {
    return '$temps /km';
  }

  @override
  String vitesseValeur(String v) {
    return '$v km/h';
  }

  @override
  String kmValeur(String n) {
    return '$n km';
  }

  @override
  String get effortRessenti => 'Perceived effort';

  @override
  String get demarrerActivite => 'Let\'s go';

  @override
  String get pasDeGps => 'Rhythm times you; you enter the distance at the end.';

  @override
  String get fractionnesPrets => 'Ready to go';

  @override
  String get personnaliser => 'Custom';

  @override
  String get repetitionsIntervalles => 'Rounds';

  @override
  String get effortIntervalle => 'Work';

  @override
  String get recuperationIntervalle => 'Recovery';

  @override
  String get lancer => 'Start';

  @override
  String intervalleSur(int n, int total) {
    return '$n of $total';
  }

  @override
  String intervallesResume(int n, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n rounds',
      one: '1 round',
    );
    return '$_temp0 · $minutes min total';
  }

  @override
  String get monFractionne => 'My intervals';

  @override
  String nSemaines(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weeks',
      one: '1 week',
    );
    return '$_temp0';
  }

  @override
  String get troisParSemaine => '3 sessions a week';

  @override
  String seanceNumero(int n, int total) {
    return 'Session $n of $total';
  }

  @override
  String get commencerProgramme => 'Start the plan';

  @override
  String get arreterProgramme => 'Stop the plan';

  @override
  String get prochaineEtape => 'Next session';

  @override
  String get programmeTermine => 'Plan complete. Well done!';

  @override
  String enCoursDepuis(String date) {
    return 'Started $date';
  }

  @override
  String get releverDefi => 'Take the challenge';

  @override
  String get abandonnerDefi => 'Give up the challenge';

  @override
  String prevueLe(String date) {
    return 'planned $date';
  }

  @override
  String auTotal(int n) {
    return '$n total';
  }

  @override
  String get defiReleve => 'Challenge complete!';

  @override
  String get defiEnCours => 'In progress';

  @override
  String etapesFaites(int n, int total) {
    return '$n of $total done';
  }

  @override
  String get trenteDerniersJours => 'Last 30 days';

  @override
  String parRapportAvant(String variation) {
    return '$variation vs the previous 30 days';
  }

  @override
  String get minutesTitre => 'Minutes';

  @override
  String get minutesEtSeancesParJour => 'Minutes per day';

  @override
  String get regularite => 'Consistency';

  @override
  String joursActifs(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n active days',
      one: '1 active day',
      zero: 'no active day',
    );
    return '$_temp0';
  }

  @override
  String get parStyle => 'By style';

  @override
  String get musclesTravailles => 'Muscles trained';

  @override
  String get aNePasOublier => 'Don\'t forget';

  @override
  String rienDepuis(String muscle, int n) {
    return '$muscle: nothing for $n days';
  }

  @override
  String rienEn30Jours(String muscle) {
    return '$muscle: nothing for at least 30 days';
  }

  @override
  String get toutEstTravaille =>
      'Everything got trained this week. Nice balance.';

  @override
  String get recordsRecents => 'Recent records';

  @override
  String get aucunRecord => 'No record in this period yet.';

  @override
  String get moinsDe => 'less';

  @override
  String get peuPlusBeaucoup => 'Less · more';

  @override
  String get ajouterMesure => 'Add a measurement';

  @override
  String get poids => 'Weight';

  @override
  String get tourDeTaille => 'Waist';

  @override
  String depuisLeDebut(String variation) {
    return '$variation since the start';
  }

  @override
  String get aucuneMesure =>
      'No measurement yet. Optional: to follow your progress.';

  @override
  String get indiceKg => 'in kg';

  @override
  String get indiceCm => 'in cm';

  @override
  String get mesureRequise => 'Enter at least weight or waist.';

  @override
  String get retirerDuJournal => 'Remove from log';

  @override
  String get toucherPourRetirer => 'Tap again to remove';

  @override
  String get canalSeancesNom => 'Workouts';

  @override
  String get canalSeancesDescription => 'Reminders for your planned workouts.';

  @override
  String notifSeanceCorps(int n, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n exercises · about $minutes min. Let\'s go?',
      one: '1 exercise · about $minutes min. Let\'s go?',
      zero: 'Your workout is waiting.',
    );
    return '$_temp0';
  }

  @override
  String get exercicesCourt => 'Exercises';

  @override
  String get changeDeCote => 'Switch sides';

  @override
  String parCoteDuree(String duree) {
    return '$duree each side';
  }

  @override
  String get activiteSedentaire => 'Seated';

  @override
  String get activiteSedentaireDetail =>
      'Mostly seated: desk, studies, screens. Workouts are added separately.';

  @override
  String get activiteDebout => 'On your feet';

  @override
  String get activiteDeboutDetail =>
      'Often standing or walking: retail, teaching, care.';

  @override
  String get activitePhysique => 'Physical';

  @override
  String get activitePhysiqueDetail =>
      'Physical work: construction, warehouse, delivery.';

  @override
  String get activiteQuotidienne => 'Daily activity';

  @override
  String auMoment(String moment) {
    String _temp0 = intl.Intl.selectLogic(moment, {
      'dejeuner': 'to breakfast',
      'diner': 'to lunch',
      'collation': 'to snacks',
      'souper': 'to dinner',
      'other': 'to the meal',
    });
    return '$_temp0';
  }

  @override
  String ajouteA(String auMoment, String kcal) {
    return 'Added $auMoment · $kcal';
  }

  @override
  String ajouterAu(String auMoment) {
    return 'Add $auMoment';
  }

  @override
  String ajouterPareil(String nom) {
    return 'Add again: $nom';
  }

  @override
  String get ajouterUnAliment => 'Add a food';

  @override
  String ajustementActif(String depense, String rythme, String correction) {
    return 'Over 3 weeks: your real expenditure is about $depense, your weight changes by $rythme kg a week. Correction: $correction a day.';
  }

  @override
  String get ajustementAuto => 'Automatic adjustment';

  @override
  String get ajustementAutoDetail =>
      'Your real weight trend corrects the formula.';

  @override
  String get ajustementDesactive => 'Off: your needs follow the formula.';

  @override
  String ajustementDonnees(String journees, String pesees) {
    return 'It takes 10 logged days and 3 weigh-ins over 10 days. So far: $journees, $pesees.';
  }

  @override
  String journeesNotees(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n logged days',
      one: '1 logged day',
      zero: 'no logged day',
    );
    return '$_temp0';
  }

  @override
  String peseesNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n weigh-ins',
      one: '1 weigh-in',
      zero: 'no weigh-in',
    );
    return '$_temp0';
  }

  @override
  String get aliments => 'Foods';

  @override
  String alimentsAjoutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n foods added',
      one: '1 food added',
      zero: 'Nothing to copy',
    );
    return '$_temp0';
  }

  @override
  String get anneeNaissance => 'Year of birth';

  @override
  String get auQuotidien => 'Day to day, outside workouts';

  @override
  String aucunAliment(String q) {
    return 'Nothing found for “$q”. Try a simpler word, or a quick entry.';
  }

  @override
  String get baseIndisponible => 'The food database could not be read.';

  @override
  String get calculIndicatif => 'By the formula';

  @override
  String get chargementBase => 'Loading the food database…';

  @override
  String get chercherAliment => 'Search a food (banana, rice, chicken…)';

  @override
  String commeHier(String contenu) {
    return 'Same as yesterday: $contenu';
  }

  @override
  String get compterSeances => 'Count my workouts';

  @override
  String get compterSeancesDetail =>
      'The average calories of your workouts (14 days) is added to your needs.';

  @override
  String conseilApresSeance(int n) {
    return 'Workout done: $n g of protein to go. A snack (milk, Greek yogurt, eggs) helps your muscles recover.';
  }

  @override
  String get conseilAtteint1 => 'Goals reached today. Well done.';

  @override
  String get conseilAtteint2 =>
      'Calories and protein on target: exactly what was needed.';

  @override
  String get conseilAtteint3 =>
      'Everything is there today. Your body says thanks.';

  @override
  String get conseilDejeuner1 =>
      'A breakfast with protein (eggs, Greek yogurt, peanut butter) lasts until lunch.';

  @override
  String get conseilDejeuner2 =>
      'No breakfast yet? Even a small one gets the day going.';

  @override
  String get conseilDepasse1 =>
      'A hearty day, it happens. Tomorrow, simply get back into rhythm.';

  @override
  String get conseilDepasse2 =>
      'A little over today: nothing serious, it\'s the week that counts.';

  @override
  String conseilEau(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n glasses of water',
      one: '1 glass of water',
      zero: 'No water yet',
    );
    return '$_temp0 out of $m: a big glass now?';
  }

  @override
  String get conseilGuide1 =>
      'Half the plate vegetables and fruit, a quarter protein, a quarter whole grains.';

  @override
  String get conseilGuide2 =>
      'Water is the drink of choice: a glass with every meal already goes a long way.';

  @override
  String get conseilGuide3 =>
      'Cook at home more often: you know what\'s on the plate.';

  @override
  String get conseilGuide4 =>
      'Protein at every meal helps you last until the next one.';

  @override
  String get conseilGuide5 =>
      'Whole grains (oats, brown rice, whole wheat bread) keep you full longer.';

  @override
  String get conseilGuide6 =>
      'Eat without screens, slowly, savouring: you feel better when you\'ve had enough.';

  @override
  String get conseilGuide7 =>
      'Legumes (lentils, chickpeas, beans): protein and fibre, for little money.';

  @override
  String conseilPrendreSoir(String n) {
    return 'To gain weight, you still need $n kcal: a dense snack (nuts, peanut butter, milk) makes the difference.';
  }

  @override
  String get conseilProfil =>
      'Tell me your sex, age and height: your goals will be calculated for you.';

  @override
  String conseilProteinesSoir(int n) {
    return 'You have $n g of protein to go: chicken, fish, tofu or legumes at dinner cover it.';
  }

  @override
  String dejaDansRepas(int n, String kcal) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Already $n foods · $kcal',
      one: 'Already 1 food · $kcal',
      zero: 'Nothing yet',
    );
    return '$_temp0';
  }

  @override
  String detailObjectifs(String kcal, String p) {
    return '$kcal · protein $p';
  }

  @override
  String get dontFibres => 'of which fibre';

  @override
  String get dontSatures => 'of which saturated';

  @override
  String get dontSucres => 'of which sugars';

  @override
  String get eauAtteinte => 'Water goal reached. Well done!';

  @override
  String eauAtteinteHabitude(String nom) {
    return 'Water goal reached: “$nom” is checked.';
  }

  @override
  String get eauCalculee => 'Water calculated for me';

  @override
  String get eauCalculeeDetail =>
      'Based on your weight, plus a glass per half hour of exercise.';

  @override
  String eauObjectif(int n, String l) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n glasses of water a day ($l L)',
      one: '1 glass of water a day ($l L)',
      zero: 'No water goal',
    );
    return '$_temp0';
  }

  @override
  String get enGrammes => 'In grams';

  @override
  String get entreeRapide => 'Quick entry';

  @override
  String get entreeRapideAide => 'Calories without searching the food';

  @override
  String get entreeRapideExplication =>
      'For a meal out or at friends\': calories are enough; macronutrients if you know them.';

  @override
  String entreeRapideNommee(String q) {
    return 'Quick entry: “$q”';
  }

  @override
  String get estimationProfil =>
      'An estimate: fill in “Me” below and log your weight.';

  @override
  String get fixerMesObjectifs => 'Set my own goals';

  @override
  String get fixerMesObjectifsDetail =>
      'Your numbers replace the formula (a dietitian\'s plan, for example).';

  @override
  String gValeur(String n) {
    return '$n g';
  }

  @override
  String get grammesPortion => 'Grams';

  @override
  String get indiceEntreeRapide => 'Poutine, pizza, dinner out…';

  @override
  String get indiceNomProduit => 'Protein bar, cereal…';

  @override
  String get indicePortion => '1 bar';

  @override
  String get jourDeSeanceGlucides =>
      'Workout day: a little more carbs, a little less fat.';

  @override
  String get kcalEnPlus => 'kcal over';

  @override
  String get kcalParJour => 'kcal a day';

  @override
  String get kcalRequises => 'Enter at least the calories.';

  @override
  String kgParSemaine(String n) {
    return '$n kg a week';
  }

  @override
  String get leCalcul => 'The calculation';

  @override
  String get lienHabitudeEau => 'Check the water habit';

  @override
  String get lienHabitudeEauDetail =>
      'Reaching your water goal checks your water habit.';

  @override
  String litresValeur(String n) {
    return '$n L';
  }

  @override
  String macrosExplication(String pk) {
    return 'Protein: $pk g per kilo. Fat: 30% of calories (25% on a workout day). Carbs: the rest.';
  }

  @override
  String get marqueFacultatif => 'Brand (optional)';

  @override
  String get mesObjectifs => 'My goals';

  @override
  String get mesProduits => 'My products';

  @override
  String get mesProduitsAide => 'Store-bought foods, with their label';

  @override
  String get mesProduitsExplication =>
      'Copy a product’s Nutrition Facts table once (bar, yogurt, cereal): then log it with one tap.';

  @override
  String get metabolismeBase => 'Basal metabolism';

  @override
  String get metabolismeBaseDetail =>
      'What your body burns at rest (Mifflin-St Jeor)';

  @override
  String get modifierProduit => 'Edit product';

  @override
  String get moi => 'Me';

  @override
  String get moment => 'Meal';

  @override
  String get monObjectif => 'My goal';

  @override
  String get monProduit => 'My product';

  @override
  String get nomDansJournal => 'Name in my log';

  @override
  String get nomFacultatif => 'Name (optional)';

  @override
  String get nomProduit => 'Name';

  @override
  String nombreDe(String unite) {
    return 'Servings ($unite)';
  }

  @override
  String get nombreDePortions => 'Servings';

  @override
  String get noterUnRepas => 'Log a meal';

  @override
  String get nouveauProduit => 'New product';

  @override
  String get nouveauProduitAide => 'Copy the label of a store-bought product';

  @override
  String get objectifPerdre => 'Lose weight';

  @override
  String get objectifMaintenir => 'Maintain';

  @override
  String get objectifPrendre => 'Gain weight';

  @override
  String objectifPerdreDetail(String kcal) {
    return 'A deficit of $kcal a day: a gentle loss that keeps muscle (higher protein).';
  }

  @override
  String get objectifMaintenirDetail => 'As many calories as you burn.';

  @override
  String objectifPrendreDetail(String kcal) {
    return 'A surplus of $kcal a day: a slow gain, mostly muscle if you train.';
  }

  @override
  String get objectifsEstimes => 'An estimate: to complete';

  @override
  String get objectifsFixesMain => 'Your goals are set by hand.';

  @override
  String get ouEnGrammes => 'Or in grams';

  @override
  String get pasAvisMedical =>
      'Guidelines for eating well, not medical advice. If in doubt (pregnancy, illness, eating disorders), talk to a health professional.';

  @override
  String get poidsAucun => 'No weigh-in: add it in Measurements';

  @override
  String poidsDepuisMesures(String date) {
    return 'Last weigh-in on $date · Measurements';
  }

  @override
  String get portionEtiquette => 'Serving (label)';

  @override
  String pour100g(String kcal, String p) {
    return '$kcal · protein $p · per 100 g';
  }

  @override
  String get produitAjoute => 'Product added';

  @override
  String get produitModifie => 'Product updated';

  @override
  String produitsNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n products',
      one: '1 product',
      zero: 'No products',
    );
    return '$_temp0';
  }

  @override
  String proteinesCourt(String g) {
    return 'protein $g';
  }

  @override
  String get quantite => 'Quantity';

  @override
  String get quantiteRequise => 'Choose a quantity.';

  @override
  String get recents => 'Recent';

  @override
  String get repasVide => 'Nothing logged for this meal.';

  @override
  String get retirerDuRepas => 'Remove from meal';

  @override
  String get rienDeNote => 'Nothing logged';

  @override
  String get rienEncore => 'Nothing logged yet.';

  @override
  String get seancesMoyenne => 'Workouts (14-day average)';

  @override
  String get seancesNonComptees => 'Not counted';

  @override
  String get sexeFemme => 'Female';

  @override
  String get sexeHomme => 'Male';

  @override
  String get sodium => 'Sodium';

  @override
  String get sourceFcen =>
      'Nutrition values: Canadian Nutrient File 2026, Health Canada.';

  @override
  String get supprimerProduit => 'Delete product';

  @override
  String get taille => 'Height';

  @override
  String get total => 'Total';

  @override
  String get unePortion => '1 serving';

  @override
  String get valeurNutritive => 'Nutrition Facts';

  @override
  String get valeurNutritiveAide => 'For ONE serving, as on the label.';

  @override
  String get verresParJour => 'Glasses a day';

  @override
  String verresSur(int n, int m) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n glasses',
      one: '1 glass',
      zero: 'No glass',
    );
    return '$_temp0 out of $m';
  }

  @override
  String kcalDePlus(String n) {
    return '$n kcal over';
  }

  @override
  String get aConsommerAvant => 'Use by';

  @override
  String get aConsommerBientot => 'Use soon';

  @override
  String aConsommerBientotNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n to use soon',
      one: '1 to use soon',
      zero: 'nothing to use soon',
    );
    return '$_temp0';
  }

  @override
  String aConsommerDici(String quand) {
    return 'Use $quand';
  }

  @override
  String get aTemperatureAmbiante => 'In the cupboard or on the counter';

  @override
  String get ajouterAuGardeManger => 'Add to the pantry';

  @override
  String get ajouterMagasin => 'Add a store';

  @override
  String alimentRange(String nom) {
    return 'Stored: $nom';
  }

  @override
  String alimentsNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n foods',
      one: '1 food',
      zero: 'No food',
    );
    return '$_temp0';
  }

  @override
  String alimentsRanges(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n foods stored',
      one: '1 food stored',
      zero: 'Nothing stored',
    );
    return '$_temp0';
  }

  @override
  String articleAjoute(String texte) {
    return 'Added: $texte';
  }

  @override
  String articleFusionne(String texte) {
    return 'Already on the list, quantities combined: $texte';
  }

  @override
  String articlesEstimation(int n, String prix) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items · about $prix at checkout',
      one: '1 item · about $prix at checkout',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String articlesNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items',
      one: '1 item',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get auMagasin => 'At the store';

  @override
  String auPanierPrix(String prix) {
    return 'in the cart: $prix';
  }

  @override
  String get auPoids => 'By weight';

  @override
  String get auPoidsDetail => 'Produce and meat weighed at checkout';

  @override
  String get aucune => 'None';

  @override
  String get aucuneEpicerie => 'No grocery trip yet';

  @override
  String get aucuneEpicerieAide =>
      'Your grocery trips will appear here, with the prices paid: finishing at the store saves them.';

  @override
  String budgetDepasse(String prix) {
    return 'Monthly budget exceeded by $prix';
  }

  @override
  String budgetDuMois(String depense, String budget) {
    return 'This month: $depense of $budget';
  }

  @override
  String get budgetEpicerie => 'Grocery budget';

  @override
  String get budgetEpicerieDetail => 'At the store, what\'s left this month.';

  @override
  String budgetRestant(String prix) {
    return 'Left in this month\'s budget: $prix';
  }

  @override
  String get canalGardeMangerDescription => 'Food to use by tomorrow.';

  @override
  String get canalGardeMangerNom => 'Pantry';

  @override
  String get cestFini => 'It\'s finished';

  @override
  String get changement15Juillet => 'Since July 15, 2026';

  @override
  String get changement15JuilletTexte =>
      'No more QST (GST still applies) on: granola bars and trail mixes, salted nuts and seeds, single pastries (under 230 g or packs of fewer than 6), frozen desserts under 500 g, dessert cups under 425 g, cut fruit or vegetable platters, toilet paper and tissues. In restaurants and vending machines, nothing changes.';

  @override
  String get combien => 'How many';

  @override
  String get commentLeGarder => 'How to keep it';

  @override
  String conseilPeremption(String noms) {
    return 'Use by tomorrow: $noms. Cook these first.';
  }

  @override
  String get consigne => 'Deposit';

  @override
  String get consigneAide =>
      'Drink cans and bottles: 10¢; glass of 500 ml or more: 25¢. Refunded on return, never taxed.';

  @override
  String get consigneTexte =>
      'Almost all drink containers from 100 ml to 2 L carry a deposit: 10¢ each, 25¢ for glass of 500 ml or more. It is added to the total, untaxed, and refunded when you return the containers.';

  @override
  String consigneValeur(String prix) {
    return 'deposit $prix';
  }

  @override
  String dansLePanier(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'In the cart · $n',
      one: 'In the cart · 1',
      zero: 'Empty cart',
    );
    return '$_temp0';
  }

  @override
  String datePassee(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Date passed $n days ago',
      one: 'Date passed yesterday',
      zero: 'Date passed',
    );
    return '$_temp0';
  }

  @override
  String dejaAuGardeManger(String texte) {
    return 'In the pantry: $texte';
  }

  @override
  String depenseCeMois(String prix) {
    return 'This month: $prix';
  }

  @override
  String deplaceJusquau(String ou, String date) {
    return '$ou: until $date';
  }

  @override
  String dernierPrixVu(String prix, String magasin, String date) {
    return 'Last price: $prix at $magasin ($date)';
  }

  @override
  String dureeA(String ou, String duree) {
    return '$ou: $duree';
  }

  @override
  String get echeanceAujourdhui => 'today';

  @override
  String echeanceDans(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'in $n days',
      one: 'tomorrow',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get echeanceDemain => 'tomorrow';

  @override
  String get echeanceHier => 'yesterday';

  @override
  String echeancePassee(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days ago',
      one: 'yesterday',
      zero: 'today',
    );
    return '$_temp0';
  }

  @override
  String get emplacementArmoire => 'Cupboard';

  @override
  String get emplacementComptoir => 'Counter';

  @override
  String get emplacementCongelateur => 'Freezer';

  @override
  String get emplacementFrigo => 'Fridge';

  @override
  String environPrix(String prix) {
    return 'about $prix';
  }

  @override
  String environPrixKg(String prix) {
    return 'about $prix / kg';
  }

  @override
  String get epicerie => 'Grocery trip';

  @override
  String epicerieDetail(int n, String taxes) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items · taxes $taxes',
      one: '1 item · taxes $taxes',
      zero: 'No items',
    );
    return '$_temp0';
  }

  @override
  String get essentiel => 'Staple';

  @override
  String get essentielCourt => 'staple';

  @override
  String get essentielDetail =>
      'When it runs out, it goes back on the list by itself.';

  @override
  String get exemplesDetaxe =>
      'Basic groceries: fruit and vegetables, meat and fish, milk, yogurt, cheese, eggs, bread, cereal, pasta, rice, canned goods, flour, coffee, 100% juice, boxed cookies, family-size desserts.';

  @override
  String get exemplesTps =>
      'Granola bars and trail mixes, salted nuts and seeds, single muffins or donuts, single-serve frozen desserts, pudding cups, cut fruit or vegetable platters, toilet paper, tissues.';

  @override
  String get exemplesTpsTvq =>
      'Soft drinks and fruit drinks, candy, chocolate, chips and snacks, alcohol, cleaning, hygiene and beauty products, most over-the-counter drugs, pet food.';

  @override
  String finiNote(String nom) {
    return 'Finished: $nom.';
  }

  @override
  String finiReassort(String nom) {
    return 'Finished: $nom, back on the shopping list.';
  }

  @override
  String get gardeManger => 'Pantry';

  @override
  String get gardeMangerAide =>
      'Tap a food: where to keep it, how long, what\'s left.';

  @override
  String get gardeMangerVide =>
      'Nothing in the pantry. Finish a grocery trip to store your food, or add one.';

  @override
  String get gardeMangerVideCourt => 'Your stored food and its dates';

  @override
  String get historiqueEpiceries => 'Grocery history';

  @override
  String get ilEnReste => 'What\'s left';

  @override
  String get indiceAjoutListe => 'Add: 2 kg chicken, milk x2…';

  @override
  String get indiceAlimentGardeManger => 'Yogurt, leftover chili…';

  @override
  String get indiceImprevu => 'Something extra? Add it here';

  @override
  String get indiceNoteArticle => 'Brand, size…';

  @override
  String intervalle(String a, String b) {
    return '$a to $b';
  }

  @override
  String get jete => 'Thrown out';

  @override
  String jeteCeMois(String prix, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Thrown out this month: $prix ($n foods)',
      one: 'Thrown out this month: $prix (1 food)',
      zero: 'Nothing thrown out this month',
    );
    return '$_temp0';
  }

  @override
  String get jeteNote => 'Noted in the waste counter.';

  @override
  String jeteValeur(String prix) {
    return 'Noted: $prix in the waste counter.';
  }

  @override
  String ligneResume(String prix, String taxes, String consigne) {
    return 'Line: $prix + taxes $taxes + deposit $consigne';
  }

  @override
  String get listeDeCourses => 'Shopping list';

  @override
  String get listeVide => 'Your list is empty.';

  @override
  String get listeVideCourt => 'Empty';

  @override
  String get magasinInconnu => 'a store';

  @override
  String meilleurPrix(String prix, String magasin) {
    return 'Best price seen: $prix at $magasin';
  }

  @override
  String get mesMagasins => 'My stores';

  @override
  String get mettreAuPanier => 'Add to cart';

  @override
  String mettreAuPanierPrix(String prix) {
    return 'Add to cart · $prix';
  }

  @override
  String get nePasRanger => 'Don\'t store';

  @override
  String notifPeremptionCorps(String noms) {
    return '$noms: use by tomorrow.';
  }

  @override
  String notifPeremptionCorpsPlus(String noms, int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n more',
      one: '1 more',
    );
    return '$noms and $_temp0: use by tomorrow.';
  }

  @override
  String notifPeremptionTitre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n foods to use',
      one: '1 food to use',
      zero: 'Pantry',
    );
    return '$_temp0';
  }

  @override
  String get nouvelleQuantite => 'New quantity';

  @override
  String get ordreDesRayons => 'Aisle order';

  @override
  String get ordreDesRayonsAide =>
      'Your store\'s: hold a row to move it. The list and the store view follow this order.';

  @override
  String get ou => 'Where';

  @override
  String get ouvert => 'opened';

  @override
  String get ouvertAujourdhui => 'Opened today';

  @override
  String ouvertDetail(String duree) {
    return 'Once opened: $duree';
  }

  @override
  String ouvertLe(String date) {
    return 'opened $date';
  }

  @override
  String get panierVide => 'The cart is empty.';

  @override
  String paquets(int n, String v) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$v packs',
      one: '$v pack',
      zero: '$v pack',
    );
    return '$_temp0';
  }

  @override
  String get parDate => 'By date';

  @override
  String get parKg => 'Per kg';

  @override
  String get parLivre => 'Per lb';

  @override
  String get parMois => 'Per month';

  @override
  String get parRayon => 'By aisle';

  @override
  String pasAuGardeManger(String noms) {
    return 'Not for the pantry: $noms.';
  }

  @override
  String get pasDeRepere => 'No guideline: set the date yourself.';

  @override
  String poidsAPrix(String poids, String prix) {
    return '$poids at $prix';
  }

  @override
  String pourOrigines(String noms) {
    return 'for: $noms';
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
      other: 'Prices known for $n items',
      one: 'Price known for 1 item',
      zero: 'No known price',
    );
    return '$_temp0';
  }

  @override
  String get prixEtPoidsRequis => 'Enter the price and the weight.';

  @override
  String prixParUnite(String unite) {
    return 'Price / $unite';
  }

  @override
  String get prixPaye => 'Price paid';

  @override
  String get prixPayeFacultatif => 'Price paid (optional)';

  @override
  String get prixRequis => 'Enter the price.';

  @override
  String get prixUnitaire => 'Unit price';

  @override
  String get prixVus => 'Prices seen';

  @override
  String get quantiteFacultatif => 'Quantity (optional)';

  @override
  String get quantiteMiseAJour => 'Quantity updated.';

  @override
  String quantitesFusionnees(String texte) {
    return 'Combined: $texte. A new quantity replaces them.';
  }

  @override
  String get raisonAlUnite =>
      'Single (fewer than 6): GST only since July 15, 2026. Six or more: zero-rated.';

  @override
  String get raisonAlcool => 'Alcohol: GST and QST.';

  @override
  String get raisonBase => 'Basic grocery: zero-rated.';

  @override
  String get raisonGrignotines =>
      'Snacks, candy, chocolate, soft drinks: GST and QST.';

  @override
  String get raisonHygieneDetaxee => 'Menstrual products: zero-rated.';

  @override
  String get raisonNonAlimentaire => 'Not a food: GST and QST.';

  @override
  String get raisonTvqAbolie => 'No QST since July 15, 2026: GST only.';

  @override
  String get ranger => 'Store';

  @override
  String get rangerExplication =>
      'Where to store each food, until when, and how to keep it longer (based on the MAPAQ Thermoguide). Adjust the date to the packaging.';

  @override
  String get rangerPlusTard =>
      'Going back leaves your groceries out of the pantry.';

  @override
  String get rappelsPeremption => 'Expiry reminders';

  @override
  String get rappelsPeremptionDetail =>
      'In the morning, what to use by tomorrow.';

  @override
  String get rayon => 'Aisle';

  @override
  String get rayonAutre => 'Other';

  @override
  String get rayonBoissons => 'Drinks';

  @override
  String get rayonBoulangerie => 'Bakery';

  @override
  String get rayonCereales => 'Cereal, pasta and rice';

  @override
  String get rayonCollations => 'Snacks and sweets';

  @override
  String get rayonCondiments => 'Condiments, sauces and oils';

  @override
  String get rayonConserves => 'Canned goods and soups';

  @override
  String get rayonEntretien => 'Household';

  @override
  String get rayonEpices => 'Spices and baking';

  @override
  String get rayonFruits => 'Fruit';

  @override
  String get rayonHygiene => 'Personal care and pharmacy';

  @override
  String get rayonLaitiers => 'Dairy and eggs';

  @override
  String get rayonLegumes => 'Vegetables and herbs';

  @override
  String get rayonLegumineuses => 'Legumes, tofu and nuts';

  @override
  String get rayonPoissons => 'Fish and seafood';

  @override
  String get rayonSurgeles => 'Frozen';

  @override
  String get rayonViandes => 'Meat';

  @override
  String get rayonsMagasinsBudget => 'Aisles, stores and budget';

  @override
  String resteAPrendre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items left',
      one: '1 item left',
      zero: 'Everything is in the cart',
    );
    return '$_temp0';
  }

  @override
  String get retirerDeLaListe => 'Remove from the list';

  @override
  String get retirerDuPanier => 'Remove from the cart';

  @override
  String get retirerErreur => 'Remove (a mistake)';

  @override
  String retirerMagasin(String magasin) {
    return 'Remove $magasin';
  }

  @override
  String get rienIci => 'Nothing here.';

  @override
  String get sansDate => 'No date';

  @override
  String seGarde(String duree) {
    return 'Keeps: $duree';
  }

  @override
  String get sourcesTaxes =>
      'Sources: Revenu Québec (basic groceries), July 15, 2026 measure, RECYC-QUÉBEC (deposit). A guide: the receipt prevails.';

  @override
  String get sousTotal => 'Subtotal';

  @override
  String sousTotalValeur(String prix) {
    return 'subtotal $prix';
  }

  @override
  String get supprimerEpicerie => 'Delete this grocery trip';

  @override
  String surBudget(String depense, String budget) {
    return '$depense / $budget';
  }

  @override
  String surLaListe(String quantite) {
    return 'On the list: $quantite';
  }

  @override
  String get surLaListeAction => 'Put back on the list';

  @override
  String get surLaListeDetail => 'To buy it again';

  @override
  String tauxEnVigueur(String tps, String tvq, String total) {
    return 'GST $tps + QST $tvq = $total';
  }

  @override
  String get tauxExplication =>
      'Each is calculated on the pre-tax price of what it applies to, rounded to the cent. If a rate changes, Rhythm applies it on its date.';

  @override
  String get taxe => 'Tax';

  @override
  String get taxeChoisie => 'Set by hand.';

  @override
  String get taxeDetaxe => 'Zero-rated';

  @override
  String get taxeTps => 'GST only';

  @override
  String get taxeTpsTvq => 'GST + QST';

  @override
  String get taxesDuQuebec => 'Quebec sales taxes';

  @override
  String get taxesDuQuebecDetail => 'What\'s taxed, and since when';

  @override
  String get tesHabituels => 'Your usuals';

  @override
  String get totalCaisse => 'Total at checkout';

  @override
  String totalPaye(String prix) {
    return '$prix paid';
  }

  @override
  String get toucherPourJeter => 'Tap again: thrown out';

  @override
  String get toucherPourTerminer => 'Tap again';

  @override
  String get toucherPourVider => 'Tap again to clear';

  @override
  String get tout => 'All';

  @override
  String get toutEstPris => 'Everything is in the cart';

  @override
  String toutRanger(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Store $n foods',
      one: 'Store 1 food',
      zero: 'Nothing to store',
    );
    return '$_temp0';
  }

  @override
  String tpsValeur(String prix) {
    return 'GST $prix';
  }

  @override
  String tvqValeur(String prix) {
    return 'QST $prix';
  }

  @override
  String get tuDecides => 'You decide';

  @override
  String get tuDecidesTexte =>
      'Rhythm suggests a status from the name and the aisle, and says why; you apply it with one tap. When in doubt, the receipt prevails.';

  @override
  String get uneFoisOuvert => 'Once opened';

  @override
  String get unitePaquet => 'pack';

  @override
  String get uniteUnite => 'unit';

  @override
  String get viderLaListe => 'Clear the list';

  @override
  String ligneResumeSansConsigne(String prix, String taxes) {
    return 'Line: $prix + taxes $taxes';
  }

  @override
  String get revenuSeul => 'back by itself (staple finished)';

  @override
  String get triRecentes => 'Recent';

  @override
  String get triAlphabetique => 'A to Z';

  @override
  String get triProteines => 'Protein';

  @override
  String get triCalories => 'Calories';

  @override
  String get triRapides => 'Quick';

  @override
  String portionUne(String nombre) {
    return '$nombre serving';
  }

  @override
  String portionsPlusieurs(String nombre) {
    return '$nombre servings';
  }

  @override
  String conseilDecongeler(String noms) {
    return 'Tonight, from the freezer to the fridge: $noms (for tomorrow).';
  }

  @override
  String get canalDecongelationNom => 'Thawing';

  @override
  String get canalDecongelationDescription =>
      'The evening before a planned meal, what to take out of the freezer';

  @override
  String get notifDecongelationTitre => 'Out of the freezer';

  @override
  String notifDecongelationCorps(String articles) {
    return 'Into the fridge tonight, for tomorrow: $articles.';
  }

  @override
  String notifDecongelationPour(String plats) {
    return 'For: $plats.';
  }

  @override
  String get canalMinuteursNom => 'Kitchen timers';

  @override
  String get canalMinuteursDescription =>
      'The end of a timer started while cooking';

  @override
  String get notifMinuteurTitre => 'Timer: time\'s up';

  @override
  String proteinesDe(String g) {
    return '$g protein';
  }

  @override
  String get cestLHeure => 'Time\'s up';

  @override
  String get plusUneMinute => '+1 min';

  @override
  String get arreterMinuteur => 'Stop the timer';

  @override
  String recettesAjoutees(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n recipes added',
      one: '1 recipe added',
      zero: 'Your recipes are already there',
    );
    return '$_temp0';
  }

  @override
  String get mesRecettes => 'My recipes';

  @override
  String get mesRecettesAide => 'Write your own, or start with eight recipes';

  @override
  String recettesNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n recipes',
      one: '1 recipe',
      zero: 'No recipes',
    );
    return '$_temp0';
  }

  @override
  String get nouvelleRecette => 'New recipe';

  @override
  String get maSemaine => 'My week';

  @override
  String get livreVide =>
      'Your recipe book is empty. Write a recipe — its macros are calculated from the database — or start with eight simple recipes.';

  @override
  String get recettesDeDepart => 'Starter recipes';

  @override
  String get recettesDeDepartDetail =>
      'Eight simple dishes, breakfast to dinner, from here and elsewhere (CNF values)';

  @override
  String get chercherRecette => 'Search a recipe, an ingredient';

  @override
  String get toutesLesRegions => 'All regions';

  @override
  String aucuneRecette(String requete) {
    return 'No recipe for “$requete”.';
  }

  @override
  String get macrosCalculees =>
      'Macros calculated from the Canadian Nutrient File (Health Canada).';

  @override
  String get modifierRecette => 'Edit recipe';

  @override
  String get parPortion => 'Per serving';

  @override
  String preparationDe(String duree) {
    return 'prep $duree';
  }

  @override
  String cuissonDe(String duree) {
    return 'cook $duree';
  }

  @override
  String get cuisiner => 'Cook';

  @override
  String get aLaListe => 'To the list';

  @override
  String pourRecettePortions(String nom, String portions) {
    return '$nom, for $portions';
  }

  @override
  String get planifier => 'Plan';

  @override
  String get noterAuJournal => 'Log it';

  @override
  String restesAuGardeManger(String portions, String detail) {
    return 'Leftovers: $portions ($detail)';
  }

  @override
  String get ingredients => 'Ingredients';

  @override
  String get aucunIngredient => 'No ingredients.';

  @override
  String get dejaLa => 'on hand';

  @override
  String sansValeurNutritive(String noms) {
    return 'No nutrition counted: $noms.';
  }

  @override
  String get jamaisCuisinee => 'Not cooked yet';

  @override
  String cuisineeFois(int n, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Cooked $n times, last on $date',
      one: 'Cooked once, on $date',
      zero: 'Not cooked yet',
    );
    return '$_temp0';
  }

  @override
  String get seCongeleBien => 'Freezes well';

  @override
  String get laRecette => 'The recipe';

  @override
  String recetteEnregistree(String nom) {
    return '“$nom” saved';
  }

  @override
  String get nomDeLaRecette => 'Recipe name';

  @override
  String get indiceNomRecette => 'Chili, pea soup…';

  @override
  String get moments => 'Meals';

  @override
  String get cequElleDonne => 'Makes';

  @override
  String get preparation => 'Prep time';

  @override
  String get cuisson => 'Cook time';

  @override
  String get ingredientLibreCourt => 'free';

  @override
  String get ajouterUnIngredient => 'Add an ingredient';

  @override
  String get etapesUneParLigne => 'Steps — one per line';

  @override
  String get indiceEtapes => 'Chop the onion.\nSauté it for 5 minutes…';

  @override
  String etapesNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n steps',
      one: '1 step',
      zero: 'No steps',
    );
    return '$_temp0';
  }

  @override
  String etapesMinuteurs(int n, String minuteurs) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n steps · timers: $minuteurs',
      one: '1 step · timers: $minuteurs',
    );
    return '$_temp0';
  }

  @override
  String get regionFacultatif => 'Region (optional)';

  @override
  String get indiceRegion => 'Québécois, Haitian, Italian…';

  @override
  String get noteFacultatif => 'Note (optional)';

  @override
  String get indiceNoteRecette => 'A tip, a variation, what to serve it with';

  @override
  String get seCongeleDetail =>
      'Batch cooking suggests it, and its leftovers go straight to the freezer.';

  @override
  String pourToute(String portions, String kcal) {
    return 'Whole recipe ($portions): $kcal';
  }

  @override
  String get supprimerRecette => 'Delete recipe';

  @override
  String get modifierIngredient => 'Edit ingredient';

  @override
  String get unIngredient => 'An ingredient';

  @override
  String get chercherIngredient => 'Search a food';

  @override
  String get ingredientAide =>
      'Search the database (5,894 foods, offline) or your products: the macros follow.';

  @override
  String get ingredientLibre => 'Free ingredient';

  @override
  String get ingredientLibreAide =>
      'No nutrition: salt, pepper, spices, water.';

  @override
  String ingredientLibreNomme(String texte) {
    return 'Free ingredient: “$texte”';
  }

  @override
  String get nomSurLaRecette => 'Name in the recipe';

  @override
  String get indiceIngredientLibre => 'Salt and pepper';

  @override
  String get ingredientDeLaBase => 'Food from the database';

  @override
  String get ajouterALaRecette => 'Add to the recipe';

  @override
  String get changerDAliment => 'Change food';

  @override
  String get retirerDeLaRecette => 'Remove from the recipe';

  @override
  String minuteurSonne(String libelle) {
    return 'Time\'s up! $libelle';
  }

  @override
  String minuteurLibelle(String nom, int n, String duree) {
    return '$nom · step $n · $duree';
  }

  @override
  String minuteurLance(String duree) {
    return 'Timer started: $duree';
  }

  @override
  String secondes(int n) {
    return '$n s';
  }

  @override
  String get modeCuisine => 'Cooking mode';

  @override
  String get pourCombien => 'Servings';

  @override
  String miseEnPlace(int fait, int total) {
    return 'Mise en place · $fait of $total';
  }

  @override
  String get sansEtapes => 'No steps written: cook your way.';

  @override
  String get cestPret => 'It\'s ready';

  @override
  String etapeSur(int n, int total) {
    return 'Step $n of $total';
  }

  @override
  String lancerMinuteur(String duree) {
    return 'Timer $duree';
  }

  @override
  String get precedente => 'Previous';

  @override
  String get suivante => 'Next';

  @override
  String get toutesLesEtapes => 'All steps';

  @override
  String nomRestes(String nom) {
    return '$nom (leftovers)';
  }

  @override
  String noteAuMoment(String portions, String moment) {
    String _temp0 = intl.Intl.selectLogic(moment, {
      'dejeuner': '$portions at breakfast',
      'diner': '$portions at lunch',
      'collation': '$portions as a snack',
      'souper': '$portions at dinner',
      'other': '$portions logged',
    });
    return '$_temp0';
  }

  @override
  String restesRanges(String portions, String ou) {
    return '$portions left over · $ou';
  }

  @override
  String get bonAppetit => 'Enjoy!';

  @override
  String cuisinePortions(String nom, String portions) {
    return '$nom · $portions';
  }

  @override
  String get jEnMangeMaintenant => 'Eating now';

  @override
  String get portionsMangees => 'Servings';

  @override
  String kcalEtProteines(String kcal, String g) {
    return '$kcal · $g protein';
  }

  @override
  String lesRestes(String portions) {
    return 'Leftovers · $portions';
  }

  @override
  String get auFrigo => 'Fridge';

  @override
  String get auCongelateur => 'Freezer';

  @override
  String get pasDeRestes => 'No leftovers';

  @override
  String restesJusquau(String date) {
    return 'Until $date';
  }

  @override
  String get restesConseil =>
      'In the fridge within 2 hours, in shallow containers: 3 to 4 days. Frozen: 3 months, dated (MAPAQ Thermoguide).';

  @override
  String get auGardeManger => 'In the pantry';

  @override
  String get auGardeMangerAide => 'What the recipe used. Check what to update.';

  @override
  String get finiQuestion => 'Unknown amount: check it if it\'s finished';

  @override
  String get ilNEnResteraPlus => 'None left: finished';

  @override
  String ilEnRestera(String quantite) {
    return '$quantite left';
  }

  @override
  String get rienACocher => 'Nothing checked.';

  @override
  String articlesAjoutesListe(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n items on the list',
      one: '1 item on the list',
      zero: 'Nothing added',
    );
    return '$_temp0';
  }

  @override
  String get dejaSurLaListe => 'Already on the list';

  @override
  String aAcheter(String quantite) {
    return 'To buy: $quantite';
  }

  @override
  String aAcheterNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n to buy',
      one: '1 to buy',
      zero: 'Nothing to buy',
    );
    return '$_temp0';
  }

  @override
  String dejaLaNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n on hand',
      one: '1 on hand',
      zero: 'Nothing on hand',
    );
    return '$_temp0';
  }

  @override
  String ajouterALaListeNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Add $n items to the list',
      one: 'Add 1 item to the list',
      zero: 'Nothing to add',
    );
    return '$_temp0';
  }

  @override
  String get ajoutListeAide =>
      'What\'s in the pantry or already on the list is taken out; duplicates merge.';

  @override
  String get rienDePrevuSemaine => 'Nothing planned this week';

  @override
  String repasPrevusNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n meals planned',
      one: '1 meal planned',
      zero: 'No meals planned',
    );
    return '$_temp0';
  }

  @override
  String get cetteSemaine => 'This week';

  @override
  String get listeDeLaSemaine => 'The week\'s list';

  @override
  String get aucuneRecettePrevue => 'No recipe planned';

  @override
  String get toutEstLa => 'Everything\'s on hand';

  @override
  String recettesPrevuesNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'For $n planned recipes',
      one: 'For 1 planned recipe',
      zero: 'No recipe planned',
    );
    return '$_temp0';
  }

  @override
  String get cuisineEnLot => 'Batch cooking';

  @override
  String get cuisineEnLotDetail => 'Cook once, eat several times';

  @override
  String cuisineEnLotResume(String nom, int n) {
    return '$nom: $n meals, cooked once';
  }

  @override
  String get aDecongelerCeSoir => 'To thaw tonight';

  @override
  String get aDecongelerCeSoirCourt => 'to thaw tonight';

  @override
  String get reglages => 'Settings';

  @override
  String get portionsParRepas => 'Servings per meal';

  @override
  String get portionsParRepasDetail => 'How many you usually plan for';

  @override
  String get rappelDecongelation => 'Thawing reminder';

  @override
  String rappelDecongelationDetail(String heure) {
    return 'The evening before, at $heure: what to take out of the freezer';
  }

  @override
  String prevoirAu(String moment) {
    String _temp0 = intl.Intl.selectLogic(moment, {
      'dejeuner': 'Plan breakfast',
      'diner': 'Plan lunch',
      'collation': 'Plan a snack',
      'souper': 'Plan dinner',
      'other': 'Plan a meal',
    });
    return '$_temp0';
  }

  @override
  String get rienDePrevuMoment => 'Nothing planned';

  @override
  String get mangeCourt => 'eaten';

  @override
  String prevuAuToast(String nom, String moment) {
    String _temp0 = intl.Intl.selectLogic(moment, {
      'dejeuner': 'Planned for breakfast: $nom',
      'diner': 'Planned for lunch: $nom',
      'collation': 'Planned as a snack: $nom',
      'souper': 'Planned for dinner: $nom',
      'other': 'Planned: $nom',
    });
    return '$_temp0';
  }

  @override
  String recettesDuMoment(String moment) {
    String _temp0 = intl.Intl.selectLogic(moment, {
      'dejeuner': 'For breakfast',
      'diner': 'For lunch',
      'collation': 'For a snack',
      'souper': 'For dinner',
      'other': 'For this meal',
    });
    return '$_temp0';
  }

  @override
  String get autresRecettes => 'Other recipes';

  @override
  String get autreChose => 'Something else';

  @override
  String get indiceAutreChose => 'Restaurant, dinner at friends\'…';

  @override
  String get dejaNoteAuJournal => 'Already in the log.';

  @override
  String get portionsPrevues => 'Planned servings';

  @override
  String aSortirLaVeille(String noms) {
    return 'Take out of the freezer the day before: $noms.';
  }

  @override
  String restesDisponibles(String portions) {
    return '$portions of leftovers in the pantry';
  }

  @override
  String get noterCommeMange => 'Log as eaten';

  @override
  String get voirLaRecette => 'See the recipe';

  @override
  String get deplacer => 'Move';

  @override
  String get retirerDuPlan => 'Remove from my week';

  @override
  String get cuisineEnLotVide =>
      'No recipe planned this week. Plan your meals in My week: the ones that come back get cooked in one go.';

  @override
  String get aCuisinerCetteSemaine => 'To cook this week';

  @override
  String repasNombreJours(int n, String jours) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n meals ($jours)',
      one: '1 meal ($jours)',
      zero: 'No meals',
    );
    return '$_temp0';
  }

  @override
  String unLotDe(String fois, String portions) {
    return '$fois × the recipe ($portions)';
  }

  @override
  String get dejaEnRestes => 'covered by leftovers';

  @override
  String get aPreparerEnUneFois => 'Prep in one go';

  @override
  String dejaPrevu(String noms) {
    return 'Already planned: $noms';
  }

  @override
  String get ajouterAMaSemaine => 'Add to my week';

  @override
  String get prisDansLesRestes => 'From the leftovers';

  @override
  String prevuNoms(String noms) {
    return 'Planned: $noms';
  }

  @override
  String get prevu => 'Planned';

  @override
  String get prevuToucher => 'planned · tap to cook or log';

  @override
  String get maRecette => 'My recipe';

  @override
  String get lesRestesTitre => 'Leftovers';

  @override
  String mangerUnePortion(String nom) {
    return 'Eat a serving of $nom';
  }

  @override
  String get mangerUnePortionCourt => 'Eat a serving';

  @override
  String get mangerUnePortionDetail => 'Logged, and taken from the leftovers';

  @override
  String get aVerifierPlacard => 'Check the cupboard';

  @override
  String aVerifierNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n to check',
      one: '1 to check',
      zero: 'Nothing to check',
    );
    return '$_temp0';
  }

  @override
  String get revoir => 'Show';

  @override
  String get iaErrQuota =>
      'The AI service hit its free limit for now. Try again in a minute.';

  @override
  String get iaErrSurcharge =>
      'The AI service isn\'t responding right now. Try again shortly.';

  @override
  String get iaErrNonAutorise =>
      'The AI service refused the request (invalid key).';

  @override
  String get iaErrModele => 'The AI model is unavailable right now.';

  @override
  String get iaErrIllisible => 'The AI\'s answer couldn\'t be read. Try again.';

  @override
  String get iaErrReseau =>
      'No Internet connection: the assistant needs the network.';

  @override
  String get iaErrSansCle =>
      'The assistant isn\'t set up in this build (missing AI key).';

  @override
  String get reessayer => 'Try again';

  @override
  String get mentionIa =>
      'Online assistant (Groq). Nothing personal is sent: not your name, your weight or your habits. Calories and macros are computed on your phone from the Canadian Nutrient File.';

  @override
  String get horsDeLaBase => 'not in the database';

  @override
  String get iaAssistant => 'Assistant';

  @override
  String get iaAssistantDetail => 'Recipe ideas, week, gap, review';

  @override
  String get iaAssistantSurtitre => 'Nutrition · AI';

  @override
  String get iaAssistantIntro =>
      'I suggest, you choose — the numbers stay Rhythm\'s.';

  @override
  String get iaIdees => 'Recipe ideas';

  @override
  String get iaIdeesCourt => 'Ideas';

  @override
  String get iaIdeesDetail => 'By cuisine, meal and what you have';

  @override
  String get iaIdeesSurtitre => 'Suggested by AI';

  @override
  String get iaAvecCeQuiPresse => 'Use what\'s expiring';

  @override
  String get iaRienNePresse => 'Nothing\'s expiring in the pantry';

  @override
  String get iaIdeesPourLesUtiliser => 'Ideas to use them up';

  @override
  String get iaIdeesPourLesUtiliserDetail =>
      'Recipes with what\'s expiring, before it goes to waste';

  @override
  String get iaEcart => 'Close the gap';

  @override
  String iaIlTeReste(String kcal) {
    return '$kcal left today';
  }

  @override
  String get iaObjectifAtteint => 'Today\'s goal reached';

  @override
  String get iaPlanifier => 'Plan my week';

  @override
  String get iaPlanifierAvecIa => 'Plan with AI';

  @override
  String get iaPlanifierDetail => 'The empty slots, with your own recipes';

  @override
  String get iaPlanifierSurtitre => 'From my recipe book';

  @override
  String get iaLivreTropPetit =>
      'Your book has fewer than three recipes: add some first (ideas, starter recipes or your own), then AI can plan your week.';

  @override
  String get iaLivreTropPetitCourt => 'Add a few recipes first';

  @override
  String get iaEstimer => 'Estimate a meal';

  @override
  String iaEstimerNomme(String nom) {
    return 'Estimate “$nom” with AI';
  }

  @override
  String get iaEstimerDetailCourt =>
      'At a restaurant, at friends\': describe it, AI breaks it down';

  @override
  String get iaEstimerSurtitre => 'Without a recipe';

  @override
  String get iaImporter => 'Import a recipe';

  @override
  String get iaImporterDetailCourt =>
      'Paste a recipe\'s text: AI structures it';

  @override
  String get iaImporterSurtitre => 'From a site, an email, a book';

  @override
  String get iaBilan => 'Weekly review';

  @override
  String iaBilanDetail(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n days logged out of 7',
      one: '1 day logged out of 7',
      zero: 'No day logged out of 7',
    );
    return '$_temp0';
  }

  @override
  String get iaAilleurs =>
      'Also: “Replace an ingredient” in a recipe, and “How to store it?” for a food the storage guide doesn\'t know.';

  @override
  String get iaAUtiliser => 'To use up';

  @override
  String get iaCuisine => 'Cuisine';

  @override
  String get iaPeuImporte => 'Any';

  @override
  String get iaMoment => 'Meal';

  @override
  String get iaGenre => 'Kind of dish';

  @override
  String get iaGenrePlat => 'Main dish';

  @override
  String get iaGenreSoupe => 'Soup';

  @override
  String get iaGenreSalade => 'Meal salad';

  @override
  String get iaGenreSandwich => 'Sandwich, wrap';

  @override
  String get iaGenreBol => 'Bowl';

  @override
  String get iaGenreDessert => 'Dessert';

  @override
  String get iaGenreBoisson => 'Smoothie, drink';

  @override
  String get iaPortions => 'Servings';

  @override
  String get iaOptionRapide => 'Quick (30 min)';

  @override
  String get iaOptionProteinees => 'High protein';

  @override
  String get iaOptionVegetarien => 'Vegetarian';

  @override
  String get iaOptionGardeManger => 'From my pantry';

  @override
  String get iaPrecisions => 'Details (optional)';

  @override
  String get iaIndicePrecisions => 'no peanuts, oven-baked, tight budget…';

  @override
  String get iaProposer => 'Suggest 3 ideas';

  @override
  String get iaAutresIdees => 'Other ideas';

  @override
  String get iaAttenteIdees => 'AI is looking for ideas… about twenty seconds.';

  @override
  String get iaPropositions => 'Suggestions';

  @override
  String get iaAuLivre => 'In the book';

  @override
  String get iaParPortionCalcule =>
      'Calories per serving computed by Rhythm from the Canadian Nutrient File.';

  @override
  String get iaAjouterAuLivre => 'Add to my book';

  @override
  String get iaVoirDansLeLivre => 'See in my book';

  @override
  String iaAjouteeAuLivre(String nom) {
    return '“$nom” added to your book';
  }

  @override
  String iaHorsBaseDetail(String noms) {
    return 'Not in the database: $noms (no nutritional value — refine it in the recipe).';
  }

  @override
  String get iaRecetteAVerifier =>
      'Recipe suggested by AI: check it (cooking, allergens). Nutritional values come from the Canadian Nutrient File, computed by Rhythm.';

  @override
  String get iaTexteDeLaRecette => 'The recipe text';

  @override
  String get iaColler => 'Paste';

  @override
  String get iaIndiceImport => 'Ingredients, steps… as is';

  @override
  String get iaStructurer => 'Structure it';

  @override
  String get iaAttenteImport => 'AI is structuring the recipe…';

  @override
  String get iaPasUneRecette => 'This text doesn\'t look like a recipe.';

  @override
  String get iaTexteTropCourt => 'Paste a recipe\'s text first.';

  @override
  String get iaPressePapiersVide => 'The clipboard is empty.';

  @override
  String get iaImporterAide =>
      'Nothing is made up: ingredients and steps stay the recipe\'s own, in metric units.';

  @override
  String get iaLesChiffres => 'The numbers';

  @override
  String get iaJourneesNotees => 'Days logged';

  @override
  String iaSurSept(int n) {
    return '$n of 7';
  }

  @override
  String get iaCaloriesParJour => 'Calories per day';

  @override
  String get iaProteinesParJour => 'Protein per day';

  @override
  String get iaFibresParJour => 'Fiber per day';

  @override
  String get iaSodiumParJour => 'Sodium per day';

  @override
  String iaSurObjectif(String valeur, String objectif) {
    return '$valeur / $objectif';
  }

  @override
  String iaRepere(String valeur, String repere) {
    return '$valeur · target $repere';
  }

  @override
  String iaLimite(String valeur, String limite) {
    return '$valeur · limit $limite';
  }

  @override
  String iaMg(String n) {
    return '$n mg';
  }

  @override
  String iaVerresParJour(String n, int vises) {
    return '$n / $vises glasses';
  }

  @override
  String get iaSeances => 'Workouts';

  @override
  String get iaJetes => 'Thrown out';

  @override
  String get iaSouvent => 'Often';

  @override
  String get iaAvis => 'The assistant\'s take';

  @override
  String get iaAttenteBilan => 'AI is reading your week…';

  @override
  String get iaRefaireBilan => 'Redo the review';

  @override
  String get iaBilanPasMedical =>
      'A guide to move forward, not medical advice: for follow-up, see a registered dietitian.';

  @override
  String get iaMomentsARemplir => 'Meals to fill';

  @override
  String iaCasesLibres(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n empty slots over 7 days',
      one: '1 empty slot over 7 days',
      zero: 'No empty slot over 7 days',
    );
    return '$_temp0';
  }

  @override
  String get iaProposerSemaine => 'Suggest my week';

  @override
  String get iaReproposer => 'Suggest something else';

  @override
  String get iaAttenteSemaine => 'AI is putting your week together…';

  @override
  String get iaRienAPlanifier => 'Nothing from your book fits these slots.';

  @override
  String iaAjouterASemaine(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Add $n meals to my week',
      one: 'Add 1 meal to my week',
      zero: 'Nothing to add',
    );
    return '$_temp0';
  }

  @override
  String iaRepasAjoutes(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n meals added to your week',
      one: '1 meal added to your week',
      zero: 'No meal added',
    );
    return '$_temp0';
  }

  @override
  String get iaPlanDetail =>
      'What\'s already planned stays. Tap a meal to leave it out.';

  @override
  String get iaResteAujourdhui => 'left for today';

  @override
  String get iaPresqueAtteint =>
      'You have almost everything you need today: a small snack will do.';

  @override
  String get iaPourQuelRepas => 'For which meal';

  @override
  String get iaDesIdees => 'Get ideas';

  @override
  String get iaAttenteEcart => 'AI is looking at what\'s left…';

  @override
  String iaTotalEtReste(
    String total,
    String proteines,
    String ecart,
    String genre,
  ) {
    String _temp0 = intl.Intl.selectLogic(genre, {
      'plus': '$ecart over',
      'other': '$ecart left',
    });
    return 'Total: $total · $proteines protein · $_temp0';
  }

  @override
  String get iaNote => 'Logged';

  @override
  String iaNoteAuJournal(String titre) {
    return '“$titre” logged';
  }

  @override
  String iaEcartDetail(String kcal) {
    return 'Today\'s goal: $kcal. Each option\'s calories are computed by Rhythm.';
  }

  @override
  String get iaTonRepas => 'Your meal';

  @override
  String get iaIndiceEstimer =>
      '2 slices of all-dressed pizza and a Caesar salad';

  @override
  String get iaEstimerBouton => 'Estimate';

  @override
  String get iaReestimer => 'Estimate again';

  @override
  String get iaAttenteEstimer => 'AI is breaking down your meal…';

  @override
  String get iaRienAEstimer => 'Nothing to estimate: describe what you ate.';

  @override
  String get iaCeQueJeCompte => 'What I count';

  @override
  String iaNoterNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Log $n foods',
      one: 'Log 1 food',
      zero: 'Nothing to log',
    );
    return '$_temp0';
  }

  @override
  String iaAlimentsNotes(int n, String moment) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n foods logged',
      one: '1 food logged',
      zero: 'Nothing logged',
    );
    return '$_temp0 · $moment';
  }

  @override
  String get iaDecrisTonRepas => 'Describe your meal first.';

  @override
  String get iaEstimerDetail =>
      'An estimate: quantities are a usual serving. Tap a line to leave it out; a food not in the database isn\'t counted.';

  @override
  String get iaRemplacer => 'Replace an ingredient';

  @override
  String get iaRemplacerCourt =>
      'Don\'t have it, lighter, vegetarian… AI suggests';

  @override
  String get iaQuelIngredient => 'Which ingredient';

  @override
  String get iaPourquoiRemplacer => 'Why';

  @override
  String get iaRaisonManque => 'Don\'t have it';

  @override
  String get iaRaisonLeger => 'Lighter';

  @override
  String get iaRaisonProteine => 'More protein';

  @override
  String get iaRaisonVegetarien => 'Vegetarian';

  @override
  String get iaRaisonAllergie => 'Allergy';

  @override
  String iaProposerRemplacants(String nom) {
    return 'Replace “$nom”';
  }

  @override
  String get iaAttenteRemplacants => 'AI is looking for substitutes…';

  @override
  String iaParPortionDiff(String kcal, String prot) {
    return 'Per serving: $kcal · $prot protein';
  }

  @override
  String get iaRemplacerBouton => 'Replace';

  @override
  String iaRemplace(String avant, String apres) {
    return '“$avant” replaced with “$apres”';
  }

  @override
  String get iaRemplacerDetail =>
      'The substitute\'s values come from the Canadian Nutrient File. With an allergy, always check the labels.';

  @override
  String get iaHorsDuGuide =>
      'This food isn\'t in the storage guide: these are the aisle\'s general guidelines.';

  @override
  String get iaCommentLeGarder => 'How to store it?';

  @override
  String get iaAttenteConservation => 'AI is looking up how to store it…';

  @override
  String get iaRepereDeLIa => 'AI guidance: check the packaging too.';

  @override
  String get monAssiette => 'My plate';

  @override
  String get assietteLegumesFruits => 'Vegetables and fruits';

  @override
  String get assietteProteines => 'Protein foods';

  @override
  String get assietteGrains => 'Grains';

  @override
  String get assietteALimiter => 'To limit';

  @override
  String get assietteNeutre => 'Not counted';

  @override
  String get assietteNonReparti => 'Not sorted';

  @override
  String get assietteLegumesFruitsDetail => 'Half the plate.';

  @override
  String get assietteProteinesDetail => 'A quarter of the plate.';

  @override
  String get assietteGrainsDetail =>
      'A quarter of the plate, whole grains preferably.';

  @override
  String get assietteALimiterDetail =>
      'Sweets, snacks, pastries, juice, sugary or alcoholic drinks, fast food.';

  @override
  String get assietteNeutreDetail =>
      'Fats, sauces, spices, water, coffee, tea, milk to drink: off the plate.';

  @override
  String get assietteNonRepartiDetail =>
      'Quick entries and mixed dishes: what they contain is unknown. Logged from the food base or a recipe, a meal gets sorted.';

  @override
  String assietteSur(String vise) {
    return 'of $vise';
  }

  @override
  String get assietteGrainsEntiers => 'Whole grains';

  @override
  String assietteDesGrains(String part) {
    return '$part of grains';
  }

  @override
  String assietteDeCeQuiEstMange(String part) {
    return '$part of what\'s eaten';
  }

  @override
  String assietteNonRepartisNombre(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n foods',
      one: '1 food',
      zero: 'none',
    );
    return '$_temp0';
  }

  @override
  String get assietteGrainEntier => 'whole grain';

  @override
  String get assietteRienDeNote =>
      'Nothing logged that day: the plate is empty.';

  @override
  String get assietteConseilVide => 'Not enough on the plate yet to judge.';

  @override
  String get assietteConseilLegumesFruits =>
      'Vegetables and fruits are missing: they make up half the plate.';

  @override
  String get assietteConseilProteines =>
      'A little more protein foods: legumes, fish, eggs, nuts, yogurt, meat.';

  @override
  String get assietteConseilGrains =>
      'Grains are missing: a quarter of the plate, whole grain.';

  @override
  String get assietteConseilALimiter =>
      'Lots of foods to limit: water, fruit and nuts replace them well.';

  @override
  String get assietteConseilEntiers =>
      'Grains, but few whole ones: brown rice, whole wheat bread, oatmeal, quinoa.';

  @override
  String get assietteConseilEquilibree =>
      'A balanced plate, as the Guide suggests.';

  @override
  String get assietteCourtVide => 'Not enough logged yet to judge';

  @override
  String get assietteCourtLegumesFruits => 'More vegetables and fruits';

  @override
  String get assietteCourtProteines => 'More protein foods';

  @override
  String get assietteCourtGrains => 'More whole grains';

  @override
  String get assietteCourtALimiter => 'Fewer foods to limit';

  @override
  String get assietteCourtEntiers => 'Whole grains more often';

  @override
  String get assietteCourtEquilibree => 'Balanced, per the Guide';

  @override
  String get assietteSeptJours => 'These 7 days';

  @override
  String assietteSeptJoursDetail(String lf, String p, String g) {
    return 'Vegetables and fruits $lf · protein $p · grains $g';
  }

  @override
  String get assietteLeGuide => 'Canada\'s Food Guide';

  @override
  String get assietteGuide1 =>
      'Half the plate: vegetables and fruits, of every colour.';

  @override
  String get assietteGuide2 =>
      'A quarter: protein foods, more often from plants.';

  @override
  String get assietteGuide3 => 'A quarter: whole grain foods.';

  @override
  String get assietteGuide4 =>
      'Water as the drink of choice; few highly processed foods.';

  @override
  String get assietteEstimation =>
      'An estimate based on the weight of logged foods (dry grains and legumes in a recipe count as cooked). Canada\'s Food Guide, Health Canada. Not medical advice.';

  @override
  String get kcalPrevues => 'kcal planned';

  @override
  String prevuSur(String kcal) {
    return 'of $kcal';
  }

  @override
  String dontDejaNotees(String kcal) {
    return 'including $kcal already logged';
  }

  @override
  String repasSansValeur(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '+ $n meals without values (something else)',
      one: '+ 1 meal without values (something else)',
      zero: 'no meal without values',
    );
    return '$_temp0';
  }

  @override
  String get triFavorites => 'Favourites';

  @override
  String get ajouterAuxFavorites => 'Add to favourites';

  @override
  String get retirerDesFavorites => 'Remove from favourites';

  @override
  String get recetteFavorite => 'Added to favourites.';

  @override
  String get recettePlusFavorite => 'Removed from favourites.';

  @override
  String get etiquettesFacultatif => 'Tags (optional)';

  @override
  String get indiceEtiquette => 'Write another tag';

  @override
  String get toutesLesEtiquettes => 'All tags';

  @override
  String get mesEmplacements => 'My storage places';

  @override
  String get mesEmplacementsDetail =>
      'A second freezer, a cellar, the garage fridge…';

  @override
  String get mesEmplacementsAide =>
      'The fridge, freezer, cupboard and counter are already there. Add your own: each one keeps food like one of the four (same storage times).';

  @override
  String get ajouterUnEmplacement => 'Add a storage place';

  @override
  String get nouvelEmplacement => 'New storage place';

  @override
  String get modifierEmplacement => 'Edit storage place';

  @override
  String get indiceEmplacement => 'Basement freezer, cellar…';

  @override
  String get seGardeCommeTitre => 'Keeps food like';

  @override
  String seGardeComme(String genre) {
    return 'like $genre';
  }

  @override
  String seGardeCommeDetail(String genre) {
    return 'Storage times and suggested dates follow the chosen kind ($genre).';
  }

  @override
  String emplacementEnregistre(String nom) {
    return '“$nom” saved.';
  }

  @override
  String get retirerEmplacement => 'Remove this storage place';

  @override
  String get toucherEncorePourRetirer => 'Tap again to remove';

  @override
  String retirerEmplacementDetail(String genre) {
    return 'What\'s stored there stays in the pantry, under “$genre”.';
  }

  @override
  String emplacementRetire(String nom, String genre) {
    return '“$nom” removed: its foods are under “$genre”.';
  }

  @override
  String get iaRemplacerCuisine => 'Missing one? AI suggests substitutes';
}
