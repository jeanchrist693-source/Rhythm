import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @titreApp.
  ///
  /// In fr, this message translates to:
  /// **'Rhythm'**
  String get titreApp;

  /// No description provided for @navAccueil.
  ///
  /// In fr, this message translates to:
  /// **'Accueil'**
  String get navAccueil;

  /// No description provided for @navSports.
  ///
  /// In fr, this message translates to:
  /// **'Sports'**
  String get navSports;

  /// No description provided for @navAlimentation.
  ///
  /// In fr, this message translates to:
  /// **'Alimentation'**
  String get navAlimentation;

  /// No description provided for @navHabitudes.
  ///
  /// In fr, this message translates to:
  /// **'Habitudes'**
  String get navHabitudes;

  /// No description provided for @navBiblique.
  ///
  /// In fr, this message translates to:
  /// **'Biblique'**
  String get navBiblique;

  /// No description provided for @navigationPrincipale.
  ///
  /// In fr, this message translates to:
  /// **'Navigation principale'**
  String get navigationPrincipale;

  /// No description provided for @bientot.
  ///
  /// In fr, this message translates to:
  /// **'Bientôt disponible'**
  String get bientot;

  /// No description provided for @bonjour.
  ///
  /// In fr, this message translates to:
  /// **'Bonjour'**
  String get bonjour;

  /// No description provided for @bonsoir.
  ///
  /// In fr, this message translates to:
  /// **'Bonsoir'**
  String get bonsoir;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @versetDuJour.
  ///
  /// In fr, this message translates to:
  /// **'Verset du jour'**
  String get versetDuJour;

  /// No description provided for @minutes.
  ///
  /// In fr, this message translates to:
  /// **'{n} min'**
  String minutes(int n);

  /// No description provided for @objectifMinutes.
  ///
  /// In fr, this message translates to:
  /// **'objectif {n} min'**
  String objectifMinutes(int n);

  /// No description provided for @kcal.
  ///
  /// In fr, this message translates to:
  /// **'{n} kcal'**
  String kcal(String n);

  /// No description provided for @resteKcal.
  ///
  /// In fr, this message translates to:
  /// **'reste {n} kcal'**
  String resteKcal(String n);

  /// No description provided for @surTotal.
  ///
  /// In fr, this message translates to:
  /// **'{n} sur {total}'**
  String surTotal(int n, int total);

  /// No description provided for @serieDeJours.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{aucune série} =1{série de 1 jour} other{série de {n} jours}}'**
  String serieDeJours(int n);

  /// No description provided for @lecture.
  ///
  /// In fr, this message translates to:
  /// **'Lecture'**
  String get lecture;

  /// No description provided for @chapitreSur.
  ///
  /// In fr, this message translates to:
  /// **'chapitre {n} sur {total}'**
  String chapitreSur(int n, int total);

  /// No description provided for @prochaineSeance.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine séance'**
  String get prochaineSeance;

  /// No description provided for @seanceEtHeure.
  ///
  /// In fr, this message translates to:
  /// **'{seance} · {heure}'**
  String seanceEtHeure(String seance, String heure);

  /// No description provided for @semaineNumero.
  ///
  /// In fr, this message translates to:
  /// **'Semaine {n}'**
  String semaineNumero(int n);

  /// No description provided for @minCetteSemaine.
  ///
  /// In fr, this message translates to:
  /// **'min cette semaine'**
  String get minCetteSemaine;

  /// No description provided for @objectifSemaine.
  ///
  /// In fr, this message translates to:
  /// **'objectif {n}'**
  String objectifSemaine(int n);

  /// No description provided for @seances.
  ///
  /// In fr, this message translates to:
  /// **'Séances'**
  String get seances;

  /// No description provided for @calories.
  ///
  /// In fr, this message translates to:
  /// **'Calories'**
  String get calories;

  /// No description provided for @serie.
  ///
  /// In fr, this message translates to:
  /// **'Série'**
  String get serie;

  /// No description provided for @semainesCourt.
  ///
  /// In fr, this message translates to:
  /// **'{n} sem.'**
  String semainesCourt(int n);

  /// No description provided for @seanceDuJour.
  ///
  /// In fr, this message translates to:
  /// **'Séance du jour · {heure}'**
  String seanceDuJour(String heure);

  /// No description provided for @commencer.
  ///
  /// In fr, this message translates to:
  /// **'Commencer'**
  String get commencer;

  /// No description provided for @aujourdhui.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get aujourdhui;

  /// No description provided for @kcalRestantes.
  ///
  /// In fr, this message translates to:
  /// **'kcal restantes'**
  String get kcalRestantes;

  /// No description provided for @proteines.
  ///
  /// In fr, this message translates to:
  /// **'Protéines'**
  String get proteines;

  /// No description provided for @glucides.
  ///
  /// In fr, this message translates to:
  /// **'Glucides'**
  String get glucides;

  /// No description provided for @lipides.
  ///
  /// In fr, this message translates to:
  /// **'Lipides'**
  String get lipides;

  /// No description provided for @grammes.
  ///
  /// In fr, this message translates to:
  /// **'{n} g'**
  String grammes(int n);

  /// No description provided for @surGrammes.
  ///
  /// In fr, this message translates to:
  /// **'/ {n} g'**
  String surGrammes(int n);

  /// No description provided for @repas.
  ///
  /// In fr, this message translates to:
  /// **'Repas'**
  String get repas;

  /// No description provided for @ajouterRepas.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un repas'**
  String get ajouterRepas;

  /// No description provided for @dejeuner.
  ///
  /// In fr, this message translates to:
  /// **'Déjeuner'**
  String get dejeuner;

  /// No description provided for @diner.
  ///
  /// In fr, this message translates to:
  /// **'Dîner'**
  String get diner;

  /// No description provided for @collation.
  ///
  /// In fr, this message translates to:
  /// **'Collation'**
  String get collation;

  /// No description provided for @souper.
  ///
  /// In fr, this message translates to:
  /// **'Souper'**
  String get souper;

  /// No description provided for @aPlanifier.
  ///
  /// In fr, this message translates to:
  /// **'À planifier'**
  String get aPlanifier;

  /// No description provided for @hydratation.
  ///
  /// In fr, this message translates to:
  /// **'Hydratation'**
  String get hydratation;

  /// No description provided for @litresSur.
  ///
  /// In fr, this message translates to:
  /// **'{bu} L sur {objectif} L'**
  String litresSur(String bu, String objectif);

  /// No description provided for @joursDaffilee.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun jour d\'affilée} =1{1 jour d\'affilée} other{{n} jours d\'affilée}}'**
  String joursDaffilee(int n);

  /// No description provided for @recordPersonnel.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Record personnel : aucun} =1{Record personnel : 1 jour} other{Record personnel : {n} jours}}'**
  String recordPersonnel(int n);

  /// No description provided for @jours.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{0 jour} =1{1 jour} other{{n} jours}}'**
  String jours(int n);

  /// No description provided for @partager.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get partager;

  /// No description provided for @planDeLecture.
  ///
  /// In fr, this message translates to:
  /// **'Plan de lecture'**
  String get planDeLecture;

  /// No description provided for @continuer.
  ///
  /// In fr, this message translates to:
  /// **'Continuer · {chapitre}'**
  String continuer(String chapitre);

  /// No description provided for @priere.
  ///
  /// In fr, this message translates to:
  /// **'Prière'**
  String get priere;

  /// No description provided for @journalSujets.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Journal · aucun sujet} =1{Journal · 1 sujet} other{Journal · {n} sujets}}'**
  String journalSujets(int n);

  /// No description provided for @meditation.
  ///
  /// In fr, this message translates to:
  /// **'Méditation'**
  String get meditation;

  /// No description provided for @notesSur.
  ///
  /// In fr, this message translates to:
  /// **'Notes sur {chapitre}'**
  String notesSur(String chapitre);

  /// No description provided for @aCommencer.
  ///
  /// In fr, this message translates to:
  /// **'À commencer'**
  String get aCommencer;

  /// No description provided for @serieCourte.
  ///
  /// In fr, this message translates to:
  /// **'{n} j'**
  String serieCourte(int n);

  /// No description provided for @lesAutresJours.
  ///
  /// In fr, this message translates to:
  /// **'Les autres jours'**
  String get lesAutresJours;

  /// No description provided for @liberation.
  ///
  /// In fr, this message translates to:
  /// **'Libération'**
  String get liberation;

  /// No description provided for @libreDepuisDuree.
  ///
  /// In fr, this message translates to:
  /// **'libre depuis {duree}'**
  String libreDepuisDuree(String duree);

  /// No description provided for @envieBouton.
  ///
  /// In fr, this message translates to:
  /// **'Envie ?'**
  String get envieBouton;

  /// No description provided for @nouvelleHabitude.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle habitude'**
  String get nouvelleHabitude;

  /// No description provided for @toastJourneeComplete.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Journée complète} =1{Journée complète} other{Journée complète · {n} jours d\'affilée}}'**
  String toastJourneeComplete(int n);

  /// No description provided for @toastPalier.
  ///
  /// In fr, this message translates to:
  /// **'{n} jours d\'affilée — un palier !'**
  String toastPalier(int n);

  /// No description provided for @jourAVenir.
  ///
  /// In fr, this message translates to:
  /// **'Ce jour n\'est pas encore là.'**
  String get jourAVenir;

  /// No description provided for @coachAucune.
  ///
  /// In fr, this message translates to:
  /// **'Commence petit : une seule habitude, deux minutes par jour. La régularité fait le reste.'**
  String get coachAucune;

  /// No description provided for @coachRienPrevu.
  ///
  /// In fr, this message translates to:
  /// **'Rien de prévu aujourd\'hui. Repos — ou une habitude en bonus ?'**
  String get coachRienPrevu;

  /// No description provided for @coachComplete1.
  ///
  /// In fr, this message translates to:
  /// **'Tout est fait. Journée complète — savoure-la.'**
  String get coachComplete1;

  /// No description provided for @coachComplete2.
  ///
  /// In fr, this message translates to:
  /// **'Journée complète. Tu tiens parole envers toi-même.'**
  String get coachComplete2;

  /// No description provided for @coachComplete3.
  ///
  /// In fr, this message translates to:
  /// **'Rien ne manque aujourd\'hui. Demain, même rythme.'**
  String get coachComplete3;

  /// No description provided for @coachCompleteSerie.
  ///
  /// In fr, this message translates to:
  /// **'Journée complète — {n} jours d\'affilée. Continue d\'empiler les jours.'**
  String coachCompleteSerie(int n);

  /// No description provided for @coachPalier3.
  ///
  /// In fr, this message translates to:
  /// **'3 jours d\'affilée pour « {nom} ». Le plus dur, c\'était de commencer.'**
  String coachPalier3(String nom);

  /// No description provided for @coachPalier7.
  ///
  /// In fr, this message translates to:
  /// **'Une semaine entière de « {nom} ». Ça commence à tenir.'**
  String coachPalier7(String nom);

  /// No description provided for @coachPalier14.
  ///
  /// In fr, this message translates to:
  /// **'Deux semaines de « {nom} ». Ce n\'est plus un effort, c\'est un rythme.'**
  String coachPalier14(String nom);

  /// No description provided for @coachPalier21.
  ///
  /// In fr, this message translates to:
  /// **'Trois semaines de « {nom} ». Ça devient naturel.'**
  String coachPalier21(String nom);

  /// No description provided for @coachPalier30.
  ///
  /// In fr, this message translates to:
  /// **'Un mois de « {nom} ». Regarde le chemin parcouru.'**
  String coachPalier30(String nom);

  /// No description provided for @coachPalier50.
  ///
  /// In fr, this message translates to:
  /// **'50 jours de « {nom} ». Ça fait partie de toi, maintenant.'**
  String coachPalier50(String nom);

  /// No description provided for @coachPalier66.
  ///
  /// In fr, this message translates to:
  /// **'66 jours de « {nom} » : en moyenne, le temps qu\'il faut pour qu\'une habitude devienne automatique.'**
  String coachPalier66(String nom);

  /// No description provided for @coachPalier100.
  ///
  /// In fr, this message translates to:
  /// **'100 jours de « {nom} ». Trois chiffres. Chapeau.'**
  String coachPalier100(String nom);

  /// No description provided for @coachPalier365.
  ///
  /// In fr, this message translates to:
  /// **'Un an de « {nom} ». Une année entière, un jour à la fois.'**
  String coachPalier365(String nom);

  /// No description provided for @coachPalierAutre.
  ///
  /// In fr, this message translates to:
  /// **'{n} jours d\'affilée pour « {nom} ». Quelle constance.'**
  String coachPalierAutre(int n, String nom);

  /// No description provided for @coachJamaisDeuxFois1.
  ///
  /// In fr, this message translates to:
  /// **'« {nom} » a sauté la dernière fois. Ce n\'est rien — mais jamais deux fois de suite.'**
  String coachJamaisDeuxFois1(String nom);

  /// No description provided for @coachJamaisDeuxFois2.
  ///
  /// In fr, this message translates to:
  /// **'Un jour manqué ne défait pas une habitude. Deux, ça commence. « {nom} » t\'attend.'**
  String coachJamaisDeuxFois2(String nom);

  /// No description provided for @coachMatin1.
  ///
  /// In fr, this message translates to:
  /// **'Une première coche, même petite, lance toute la journée.'**
  String get coachMatin1;

  /// No description provided for @coachMatin2.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau jour, page blanche. Par quoi on commence ?'**
  String get coachMatin2;

  /// No description provided for @coachMatin3.
  ///
  /// In fr, this message translates to:
  /// **'Commence par la plus facile. L\'élan fera le reste.'**
  String get coachMatin3;

  /// No description provided for @coachApresMidi.
  ///
  /// In fr, this message translates to:
  /// **'La journée est encore longue. Deux minutes suffisent pour commencer.'**
  String get coachApresMidi;

  /// No description provided for @coachSoirRien.
  ///
  /// In fr, this message translates to:
  /// **'La soirée est là. Choisis une habitude, même en version minimale.'**
  String get coachSoirRien;

  /// No description provided for @coachPartiel1.
  ///
  /// In fr, this message translates to:
  /// **'{reste, plural, =0{Tout est fait.} =1{Plus qu\'une. Le plus dur, commencer, est déjà fait.} other{Plus que {reste}. Le plus dur, commencer, est déjà fait.}}'**
  String coachPartiel1(int reste);

  /// No description provided for @coachPartiel2.
  ///
  /// In fr, this message translates to:
  /// **'Chaque coche compte, même la plus petite. Garde l\'élan.'**
  String get coachPartiel2;

  /// No description provided for @coachPartiel3.
  ///
  /// In fr, this message translates to:
  /// **'{reste, plural, =0{Tout est fait.} =1{Tu avances. Encore une et la journée est complète.} other{Tu avances. Encore {reste} et la journée est complète.}}'**
  String coachPartiel3(int reste);

  /// No description provided for @coachSoir.
  ///
  /// In fr, this message translates to:
  /// **'{reste, plural, =0{Tout est fait.} =1{La soirée avance. Il en reste une — la version minimale compte aussi.} other{La soirée avance. Il en reste {reste} — la version minimale compte aussi.}}'**
  String coachSoir(int reste);

  /// No description provided for @coachNuit.
  ///
  /// In fr, this message translates to:
  /// **'Il est tard. Fais la version minimale — ou repose-toi : demain est un nouveau jour.'**
  String get coachNuit;

  /// No description provided for @modifier.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modifier;

  /// No description provided for @tousLesJours.
  ///
  /// In fr, this message translates to:
  /// **'Tous les jours'**
  String get tousLesJours;

  /// No description provided for @rappelA.
  ///
  /// In fr, this message translates to:
  /// **'rappel à {heure}'**
  String rappelA(String heure);

  /// No description provided for @record.
  ///
  /// In fr, this message translates to:
  /// **'Record'**
  String get record;

  /// No description provided for @sur30Jours.
  ///
  /// In fr, this message translates to:
  /// **'Sur 30 jours'**
  String get sur30Jours;

  /// No description provided for @valeurFois.
  ///
  /// In fr, this message translates to:
  /// **'{n} fois'**
  String valeurFois(int n);

  /// No description provided for @prochainPalier.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Prochain palier} =1{Prochain palier : 1 jour} other{Prochain palier : {n} jours}}'**
  String prochainPalier(int n);

  /// No description provided for @encoreJours.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{c\'est aujourd\'hui} =1{encore 1 jour} other{encore {n} jours}}'**
  String encoreJours(int n);

  /// No description provided for @prochainPalierDuree.
  ///
  /// In fr, this message translates to:
  /// **'Prochain palier : {duree}'**
  String prochainPalierDuree(String duree);

  /// No description provided for @dansDuree.
  ///
  /// In fr, this message translates to:
  /// **'dans {duree}'**
  String dansDuree(String duree);

  /// No description provided for @historique.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get historique;

  /// No description provided for @historiqueAide.
  ///
  /// In fr, this message translates to:
  /// **'Touche un jour passé pour le cocher ou le décocher.'**
  String get historiqueAide;

  /// No description provided for @pourquoi.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi'**
  String get pourquoi;

  /// No description provided for @monPlan.
  ///
  /// In fr, this message translates to:
  /// **'Mon plan'**
  String get monPlan;

  /// No description provided for @versionMinimale.
  ///
  /// In fr, this message translates to:
  /// **'Version minimale'**
  String get versionMinimale;

  /// No description provided for @versionMinimaleAide.
  ///
  /// In fr, this message translates to:
  /// **'Les jours difficiles, au moins ceci — la série continue.'**
  String get versionMinimaleAide;

  /// No description provided for @ajouterMotivation.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute ton pourquoi et ton plan : ils t\'aideront les jours difficiles.'**
  String get ajouterMotivation;

  /// No description provided for @joursLibresUnite.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{jour} =1{jour} other{jours}}'**
  String joursLibresUnite(int n);

  /// No description provided for @depuisLe.
  ///
  /// In fr, this message translates to:
  /// **'depuis le {date}'**
  String depuisLe(String date);

  /// No description provided for @economise.
  ///
  /// In fr, this message translates to:
  /// **'Économisé'**
  String get economise;

  /// No description provided for @enviesSurmontees.
  ///
  /// In fr, this message translates to:
  /// **'Envies surmontées'**
  String get enviesSurmontees;

  /// No description provided for @jaiUneEnvie.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai une envie'**
  String get jaiUneEnvie;

  /// No description provided for @mesAlternatives.
  ///
  /// In fr, this message translates to:
  /// **'Mes alternatives'**
  String get mesAlternatives;

  /// No description provided for @mesDeclencheurs.
  ///
  /// In fr, this message translates to:
  /// **'Mes déclencheurs'**
  String get mesDeclencheurs;

  /// No description provided for @journalEnvies.
  ///
  /// In fr, this message translates to:
  /// **'Journal des envies'**
  String get journalEnvies;

  /// No description provided for @intensiteSur10.
  ///
  /// In fr, this message translates to:
  /// **'intensité {n}/10'**
  String intensiteSur10(int n);

  /// No description provided for @tenue.
  ///
  /// In fr, this message translates to:
  /// **'Tenue'**
  String get tenue;

  /// No description provided for @rechute.
  ///
  /// In fr, this message translates to:
  /// **'Rechute'**
  String get rechute;

  /// No description provided for @enviesSurtout.
  ///
  /// In fr, this message translates to:
  /// **'Tes envies arrivent surtout {tranche}.'**
  String enviesSurtout(String tranche);

  /// No description provided for @trancheNuit.
  ///
  /// In fr, this message translates to:
  /// **'la nuit'**
  String get trancheNuit;

  /// No description provided for @trancheMatin.
  ///
  /// In fr, this message translates to:
  /// **'le matin'**
  String get trancheMatin;

  /// No description provided for @trancheApresMidi.
  ///
  /// In fr, this message translates to:
  /// **'l\'après-midi'**
  String get trancheApresMidi;

  /// No description provided for @trancheSoir.
  ///
  /// In fr, this message translates to:
  /// **'le soir'**
  String get trancheSoir;

  /// No description provided for @declencheurPrincipal.
  ///
  /// In fr, this message translates to:
  /// **'Déclencheur le plus fréquent : {declencheur}.'**
  String declencheurPrincipal(String declencheur);

  /// No description provided for @rechutesCompte.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucune rechute} =1{1 rechute} other{{n} rechutes}}'**
  String rechutesCompte(int n);

  /// No description provided for @aucuneEnvie.
  ///
  /// In fr, this message translates to:
  /// **'Aucune envie notée pour l\'instant. Quand l\'envie monte, touche « J\'ai une envie ».'**
  String get aucuneEnvie;

  /// No description provided for @modifierHabitude.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'habitude'**
  String get modifierHabitude;

  /// No description provided for @aConstruire.
  ///
  /// In fr, this message translates to:
  /// **'À construire'**
  String get aConstruire;

  /// No description provided for @aLiberer.
  ///
  /// In fr, this message translates to:
  /// **'Me libérer'**
  String get aLiberer;

  /// No description provided for @aConstruireAide.
  ///
  /// In fr, this message translates to:
  /// **'Une habitude à prendre, jour après jour.'**
  String get aConstruireAide;

  /// No description provided for @aLibererAide.
  ///
  /// In fr, this message translates to:
  /// **'Une dépendance à laisser : un compteur, et du soutien quand l\'envie monte.'**
  String get aLibererAide;

  /// No description provided for @champNom.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get champNom;

  /// No description provided for @indiceNomConstruire.
  ///
  /// In fr, this message translates to:
  /// **'Prière du matin'**
  String get indiceNomConstruire;

  /// No description provided for @indiceNomLiberer.
  ///
  /// In fr, this message translates to:
  /// **'Ce dont je me libère'**
  String get indiceNomLiberer;

  /// No description provided for @champCouleur.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get champCouleur;

  /// No description provided for @champLettre.
  ///
  /// In fr, this message translates to:
  /// **'Lettre'**
  String get champLettre;

  /// No description provided for @champDetail.
  ///
  /// In fr, this message translates to:
  /// **'Précision'**
  String get champDetail;

  /// No description provided for @indiceDetail.
  ///
  /// In fr, this message translates to:
  /// **'Au réveil · 10 min'**
  String get indiceDetail;

  /// No description provided for @champJours.
  ///
  /// In fr, this message translates to:
  /// **'Jours'**
  String get champJours;

  /// No description provided for @champRappel.
  ///
  /// In fr, this message translates to:
  /// **'Rappel'**
  String get champRappel;

  /// No description provided for @rappelDiscret.
  ///
  /// In fr, this message translates to:
  /// **'Un mot discret chaque jour, sans jamais nommer ce dont tu te libères.'**
  String get rappelDiscret;

  /// No description provided for @heure.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get heure;

  /// No description provided for @champPourquoi.
  ///
  /// In fr, this message translates to:
  /// **'Pourquoi'**
  String get champPourquoi;

  /// No description provided for @indicePourquoi.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui compte vraiment pour moi'**
  String get indicePourquoi;

  /// No description provided for @indicePlan.
  ///
  /// In fr, this message translates to:
  /// **'Quand je me lève, je prie 10 minutes.'**
  String get indicePlan;

  /// No description provided for @aidePlan.
  ///
  /// In fr, this message translates to:
  /// **'Quand [moment], je [action]. Un plan précis aide à s\'y tenir.'**
  String get aidePlan;

  /// No description provided for @indiceVersionMinimale.
  ///
  /// In fr, this message translates to:
  /// **'2 minutes, 1 verset, 1 verre'**
  String get indiceVersionMinimale;

  /// No description provided for @champLibreDepuis.
  ///
  /// In fr, this message translates to:
  /// **'Libre depuis'**
  String get champLibreDepuis;

  /// No description provided for @hier.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get hier;

  /// No description provided for @ilYaJours.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aujourd\'hui} =1{Hier} other{Il y a {n} jours}}'**
  String ilYaJours(int n);

  /// No description provided for @champCout.
  ///
  /// In fr, this message translates to:
  /// **'Coût par jour'**
  String get champCout;

  /// No description provided for @aideCout.
  ///
  /// In fr, this message translates to:
  /// **'Pour voir ce que tu économises.'**
  String get aideCout;

  /// No description provided for @indiceAlternative.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une alternative'**
  String get indiceAlternative;

  /// No description provided for @indiceDeclencheur.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un déclencheur'**
  String get indiceDeclencheur;

  /// No description provided for @altEau.
  ///
  /// In fr, this message translates to:
  /// **'Boire un grand verre d\'eau'**
  String get altEau;

  /// No description provided for @altMarcher.
  ///
  /// In fr, this message translates to:
  /// **'Marcher 5 minutes'**
  String get altMarcher;

  /// No description provided for @altAppeler.
  ///
  /// In fr, this message translates to:
  /// **'Appeler quelqu\'un'**
  String get altAppeler;

  /// No description provided for @altPrier.
  ///
  /// In fr, this message translates to:
  /// **'Prier'**
  String get altPrier;

  /// No description provided for @altRespirer.
  ///
  /// In fr, this message translates to:
  /// **'Respirer lentement'**
  String get altRespirer;

  /// No description provided for @altDouche.
  ///
  /// In fr, this message translates to:
  /// **'Prendre une douche'**
  String get altDouche;

  /// No description provided for @declStress.
  ///
  /// In fr, this message translates to:
  /// **'Stress'**
  String get declStress;

  /// No description provided for @declEnnui.
  ///
  /// In fr, this message translates to:
  /// **'Ennui'**
  String get declEnnui;

  /// No description provided for @declFatigue.
  ///
  /// In fr, this message translates to:
  /// **'Fatigue'**
  String get declFatigue;

  /// No description provided for @declSolitude.
  ///
  /// In fr, this message translates to:
  /// **'Solitude'**
  String get declSolitude;

  /// No description provided for @declColere.
  ///
  /// In fr, this message translates to:
  /// **'Colère'**
  String get declColere;

  /// No description provided for @declSoiree.
  ///
  /// In fr, this message translates to:
  /// **'Le soir'**
  String get declSoiree;

  /// No description provided for @declEcrans.
  ///
  /// In fr, this message translates to:
  /// **'Réseaux sociaux'**
  String get declEcrans;

  /// No description provided for @enregistrer.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get enregistrer;

  /// No description provided for @annuler.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get annuler;

  /// No description provided for @ajouter.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get ajouter;

  /// No description provided for @supprimerHabitude.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'habitude'**
  String get supprimerHabitude;

  /// No description provided for @toucherPourSupprimer.
  ///
  /// In fr, this message translates to:
  /// **'Toucher encore pour supprimer'**
  String get toucherPourSupprimer;

  /// No description provided for @nomRequis.
  ///
  /// In fr, this message translates to:
  /// **'Donne-lui un nom.'**
  String get nomRequis;

  /// No description provided for @envieSurtitre.
  ///
  /// In fr, this message translates to:
  /// **'L\'envie passe'**
  String get envieSurtitre;

  /// No description provided for @tiensBon.
  ///
  /// In fr, this message translates to:
  /// **'Tiens bon'**
  String get tiensBon;

  /// No description provided for @vagueTexte.
  ///
  /// In fr, this message translates to:
  /// **'Une envie monte, culmine, puis redescend — souvent en moins de quinze minutes. Tu n\'as pas à lui obéir : laisse-la passer comme une vague.'**
  String get vagueTexte;

  /// No description provided for @inspire.
  ///
  /// In fr, this message translates to:
  /// **'Inspire'**
  String get inspire;

  /// No description provided for @expire.
  ///
  /// In fr, this message translates to:
  /// **'Expire'**
  String get expire;

  /// No description provided for @respirationAide.
  ///
  /// In fr, this message translates to:
  /// **'Suis le cercle : cinq secondes pour inspirer, cinq pour expirer.'**
  String get respirationAide;

  /// No description provided for @attendreDixMinutes.
  ///
  /// In fr, this message translates to:
  /// **'Attendre 10 minutes'**
  String get attendreDixMinutes;

  /// No description provided for @minuteurReste.
  ///
  /// In fr, this message translates to:
  /// **'Encore {temps}'**
  String minuteurReste(String temps);

  /// No description provided for @minuteurFini.
  ///
  /// In fr, this message translates to:
  /// **'Dix minutes. Où en est l\'envie ?'**
  String get minuteurFini;

  /// No description provided for @tesRaisons.
  ///
  /// In fr, this message translates to:
  /// **'Tes raisons'**
  String get tesRaisons;

  /// No description provided for @essaiePlutot.
  ///
  /// In fr, this message translates to:
  /// **'Essaie plutôt'**
  String get essaiePlutot;

  /// No description provided for @appelerQuelquun.
  ///
  /// In fr, this message translates to:
  /// **'Appeler quelqu\'un'**
  String get appelerQuelquun;

  /// No description provided for @infoSocial.
  ///
  /// In fr, this message translates to:
  /// **'Info-Social 811'**
  String get infoSocial;

  /// No description provided for @infoSocialDetail.
  ///
  /// In fr, this message translates to:
  /// **'Écoute et soutien, 24 h sur 24 (Québec)'**
  String get infoSocialDetail;

  /// No description provided for @ligne988.
  ///
  /// In fr, this message translates to:
  /// **'9-8-8'**
  String get ligne988;

  /// No description provided for @ligne988Detail.
  ///
  /// In fr, this message translates to:
  /// **'Crise ou idées suicidaires, 24 h sur 24 (Canada)'**
  String get ligne988Detail;

  /// No description provided for @urgence911.
  ///
  /// In fr, this message translates to:
  /// **'En danger immédiat : 911'**
  String get urgence911;

  /// No description provided for @ajouterPersonneConfiance.
  ///
  /// In fr, this message translates to:
  /// **'Ajoute une personne de confiance dans Rappels.'**
  String get ajouterPersonneConfiance;

  /// No description provided for @noterEnvie.
  ///
  /// In fr, this message translates to:
  /// **'Noter cette envie'**
  String get noterEnvie;

  /// No description provided for @intensite.
  ///
  /// In fr, this message translates to:
  /// **'Intensité'**
  String get intensite;

  /// No description provided for @declencheur.
  ///
  /// In fr, this message translates to:
  /// **'Déclencheur'**
  String get declencheur;

  /// No description provided for @jaiTenu.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai tenu'**
  String get jaiTenu;

  /// No description provided for @jaiRechute.
  ///
  /// In fr, this message translates to:
  /// **'J\'ai rechuté'**
  String get jaiRechute;

  /// No description provided for @bravo.
  ///
  /// In fr, this message translates to:
  /// **'Bravo.'**
  String get bravo;

  /// No description provided for @bravoTexte.
  ///
  /// In fr, this message translates to:
  /// **'Une envie de moins. Chaque « non » rend le suivant plus facile.'**
  String get bravoTexte;

  /// No description provided for @enviesSurmonteesTotal.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucune envie surmontée} =1{1 envie surmontée} other{{n} envies surmontées}}'**
  String enviesSurmonteesTotal(int n);

  /// No description provided for @rechuteTitre.
  ///
  /// In fr, this message translates to:
  /// **'Tu n\'as pas tout perdu.'**
  String get rechuteTitre;

  /// No description provided for @rechuteTexte.
  ///
  /// In fr, this message translates to:
  /// **'Une rechute n\'efface pas le chemin. Tu as tenu {duree} — c\'est réel, et ça t\'appartient.'**
  String rechuteTexte(String duree);

  /// No description provided for @rechuteQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Qu\'est-ce qui l\'a déclenchée ?'**
  String get rechuteQuestion;

  /// No description provided for @remettreAZero.
  ///
  /// In fr, this message translates to:
  /// **'Remettre le compteur à zéro'**
  String get remettreAZero;

  /// No description provided for @toucherPourConfirmer.
  ///
  /// In fr, this message translates to:
  /// **'Toucher encore pour confirmer'**
  String get toucherPourConfirmer;

  /// No description provided for @recommencer.
  ///
  /// In fr, this message translates to:
  /// **'Recommencer maintenant'**
  String get recommencer;

  /// No description provided for @terminer.
  ///
  /// In fr, this message translates to:
  /// **'Terminer'**
  String get terminer;

  /// No description provided for @rappels.
  ///
  /// In fr, this message translates to:
  /// **'Rappels'**
  String get rappels;

  /// No description provided for @autorisationOk.
  ///
  /// In fr, this message translates to:
  /// **'Notifications autorisées'**
  String get autorisationOk;

  /// No description provided for @autorisationRefusee.
  ///
  /// In fr, this message translates to:
  /// **'Bloquées par Android'**
  String get autorisationRefusee;

  /// No description provided for @autorisationInconnue.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore autorisées'**
  String get autorisationInconnue;

  /// No description provided for @ouvrirReglages.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir les réglages'**
  String get ouvrirReglages;

  /// No description provided for @autoriser.
  ///
  /// In fr, this message translates to:
  /// **'Autoriser'**
  String get autoriser;

  /// No description provided for @rappelsHabitudes.
  ///
  /// In fr, this message translates to:
  /// **'Rappels des habitudes'**
  String get rappelsHabitudes;

  /// No description provided for @rappelsHabitudesAide.
  ///
  /// In fr, this message translates to:
  /// **'À l\'heure choisie pour chacune, les jours prévus — jamais si c\'est déjà fait.'**
  String get rappelsHabitudesAide;

  /// No description provided for @aucunRappel.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rappel'**
  String get aucunRappel;

  /// No description provided for @toucherPourRegler.
  ///
  /// In fr, this message translates to:
  /// **'Touche une habitude pour choisir son heure.'**
  String get toucherPourRegler;

  /// No description provided for @bilanDuSoir.
  ///
  /// In fr, this message translates to:
  /// **'Bilan du soir'**
  String get bilanDuSoir;

  /// No description provided for @bilanDuSoirAide.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui reste à cocher, en fin de journée.'**
  String get bilanDuSoirAide;

  /// No description provided for @personnesConfiance.
  ///
  /// In fr, this message translates to:
  /// **'Personnes de confiance'**
  String get personnesConfiance;

  /// No description provided for @personnesConfianceAide.
  ///
  /// In fr, this message translates to:
  /// **'À appeler d\'un toucher quand l\'envie est forte.'**
  String get personnesConfianceAide;

  /// No description provided for @ajouterPersonne.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une personne'**
  String get ajouterPersonne;

  /// No description provided for @champTelephone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get champTelephone;

  /// No description provided for @discretionTexte.
  ///
  /// In fr, this message translates to:
  /// **'Discrétion : les rappels de libération ne nomment jamais ce dont tu te libères, et rien ne quitte ton téléphone.'**
  String get discretionTexte;

  /// No description provided for @canalRappelsNom.
  ///
  /// In fr, this message translates to:
  /// **'Rappels des habitudes'**
  String get canalRappelsNom;

  /// No description provided for @canalRappelsDescription.
  ///
  /// In fr, this message translates to:
  /// **'À l\'heure choisie pour chaque habitude.'**
  String get canalRappelsDescription;

  /// No description provided for @canalBilanNom.
  ///
  /// In fr, this message translates to:
  /// **'Bilan du soir'**
  String get canalBilanNom;

  /// No description provided for @canalBilanDescription.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui reste à cocher en fin de journée.'**
  String get canalBilanDescription;

  /// No description provided for @canalSoutienNom.
  ///
  /// In fr, this message translates to:
  /// **'Soutien discret'**
  String get canalSoutienNom;

  /// No description provided for @canalSoutienDescription.
  ///
  /// In fr, this message translates to:
  /// **'Un mot et les étapes franchies, sans jamais nommer ce dont tu te libères.'**
  String get canalSoutienDescription;

  /// No description provided for @notifSerie.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{C\'est le moment.} =1{Hier, c\'était fait. On continue ?} other{Série de {n} jours — garde le rythme.}}'**
  String notifSerie(int n);

  /// No description provided for @notifMinimale.
  ///
  /// In fr, this message translates to:
  /// **'Même petit, ça compte : {version}.'**
  String notifMinimale(String version);

  /// No description provided for @notifPourquoi.
  ///
  /// In fr, this message translates to:
  /// **'Souviens-toi : {pourquoi}'**
  String notifPourquoi(String pourquoi);

  /// No description provided for @notifGenerique.
  ///
  /// In fr, this message translates to:
  /// **'C\'est le moment. Deux minutes suffisent pour commencer.'**
  String get notifGenerique;

  /// No description provided for @notifBilanReste.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Tout est fait.} =1{Il te reste une habitude : {noms}.} other{Il te reste {n} habitudes : {noms}.}}'**
  String notifBilanReste(int n, String noms);

  /// No description provided for @notifBilanGenerique.
  ///
  /// In fr, this message translates to:
  /// **'Un instant pour faire le point sur ta journée.'**
  String get notifBilanGenerique;

  /// No description provided for @notifSoutien1.
  ///
  /// In fr, this message translates to:
  /// **'Un moment pour toi. Comment ça va aujourd\'hui ?'**
  String get notifSoutien1;

  /// No description provided for @notifSoutien2.
  ///
  /// In fr, this message translates to:
  /// **'Tu tiens bon. Rhythm est là si l\'envie monte.'**
  String get notifSoutien2;

  /// No description provided for @notifSoutien3.
  ///
  /// In fr, this message translates to:
  /// **'Respire. Un jour à la fois.'**
  String get notifSoutien3;

  /// No description provided for @notifPalierTitre.
  ///
  /// In fr, this message translates to:
  /// **'Une étape franchie'**
  String get notifPalierTitre;

  /// No description provided for @notifPalierCorps.
  ///
  /// In fr, this message translates to:
  /// **'{duree} — bravo. Continue.'**
  String notifPalierCorps(String duree);

  /// No description provided for @dureeSemaines.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{0 semaine} =1{1 semaine} other{{n} semaines}}'**
  String dureeSemaines(int n);

  /// No description provided for @dureeMois.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{0 mois} =1{1 mois} other{{n} mois}}'**
  String dureeMois(int n);

  /// No description provided for @dureeAns.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{0 an} =1{1 an} other{{n} ans}}'**
  String dureeAns(int n);

  /// No description provided for @activer.
  ///
  /// In fr, this message translates to:
  /// **'Activer'**
  String get activer;

  /// No description provided for @notifsActiverAide.
  ///
  /// In fr, this message translates to:
  /// **'Sans elles, aucun rappel ne peut sonner.'**
  String get notifsActiverAide;

  /// No description provided for @notifsGererAide.
  ///
  /// In fr, this message translates to:
  /// **'Sons, canaux et écran verrouillé se règlent dans Android.'**
  String get notifsGererAide;

  /// No description provided for @reglagesAndroid.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get reglagesAndroid;

  /// No description provided for @notifsBloqueesRappel.
  ///
  /// In fr, this message translates to:
  /// **'Les notifications sont désactivées : ce rappel ne sonnera pas.'**
  String get notifsBloqueesRappel;

  /// No description provided for @rappelsEtNotifications.
  ///
  /// In fr, this message translates to:
  /// **'Rappels et notifications'**
  String get rappelsEtNotifications;

  /// No description provided for @separateurHeure.
  ///
  /// In fr, this message translates to:
  /// **'h'**
  String get separateurHeure;

  /// No description provided for @meLibererDependance.
  ///
  /// In fr, this message translates to:
  /// **'Me libérer d\'une dépendance'**
  String get meLibererDependance;

  /// No description provided for @monOrdre.
  ///
  /// In fr, this message translates to:
  /// **'Mon ordre'**
  String get monOrdre;

  /// No description provided for @parHeure.
  ///
  /// In fr, this message translates to:
  /// **'Par heure'**
  String get parHeure;

  /// No description provided for @deplacerAide.
  ///
  /// In fr, this message translates to:
  /// **'Maintiens une habitude pour la déplacer.'**
  String get deplacerAide;

  /// No description provided for @epingler.
  ///
  /// In fr, this message translates to:
  /// **'Épingler en haut'**
  String get epingler;

  /// No description provided for @desepingler.
  ///
  /// In fr, this message translates to:
  /// **'Désépingler'**
  String get desepingler;

  /// No description provided for @toastEpinglee.
  ///
  /// In fr, this message translates to:
  /// **'Épinglée en haut'**
  String get toastEpinglee;

  /// No description provided for @toastDesepinglee.
  ///
  /// In fr, this message translates to:
  /// **'Désépinglée'**
  String get toastDesepinglee;

  /// No description provided for @retirerEntree.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de l\'historique ?'**
  String get retirerEntree;

  /// No description provided for @retirer.
  ///
  /// In fr, this message translates to:
  /// **'Retirer'**
  String get retirer;

  /// No description provided for @garder.
  ///
  /// In fr, this message translates to:
  /// **'Garder'**
  String get garder;

  /// No description provided for @journalAide.
  ///
  /// In fr, this message translates to:
  /// **'Maintiens une entrée pour la retirer — une rechute notée par erreur, par exemple.'**
  String get journalAide;

  /// No description provided for @styleMusculation.
  ///
  /// In fr, this message translates to:
  /// **'Musculation'**
  String get styleMusculation;

  /// No description provided for @stylePoidsDuCorps.
  ///
  /// In fr, this message translates to:
  /// **'Poids du corps'**
  String get stylePoidsDuCorps;

  /// No description provided for @styleGainage.
  ///
  /// In fr, this message translates to:
  /// **'Gainage'**
  String get styleGainage;

  /// No description provided for @styleHiit.
  ///
  /// In fr, this message translates to:
  /// **'HIIT et circuit'**
  String get styleHiit;

  /// No description provided for @styleMobilite.
  ///
  /// In fr, this message translates to:
  /// **'Mobilité et étirements'**
  String get styleMobilite;

  /// No description provided for @styleCardio.
  ///
  /// In fr, this message translates to:
  /// **'Cardio'**
  String get styleCardio;

  /// No description provided for @materielHalteres.
  ///
  /// In fr, this message translates to:
  /// **'Haltères'**
  String get materielHalteres;

  /// No description provided for @materielBarre.
  ///
  /// In fr, this message translates to:
  /// **'Barre'**
  String get materielBarre;

  /// No description provided for @materielKettlebell.
  ///
  /// In fr, this message translates to:
  /// **'Kettlebell'**
  String get materielKettlebell;

  /// No description provided for @materielElastique.
  ///
  /// In fr, this message translates to:
  /// **'Élastique'**
  String get materielElastique;

  /// No description provided for @materielBarreTraction.
  ///
  /// In fr, this message translates to:
  /// **'Barre de traction'**
  String get materielBarreTraction;

  /// No description provided for @materielBanc.
  ///
  /// In fr, this message translates to:
  /// **'Banc'**
  String get materielBanc;

  /// No description provided for @materielChaise.
  ///
  /// In fr, this message translates to:
  /// **'Chaise ou marche'**
  String get materielChaise;

  /// No description provided for @materielCorde.
  ///
  /// In fr, this message translates to:
  /// **'Corde à sauter'**
  String get materielCorde;

  /// No description provided for @materielVelo.
  ///
  /// In fr, this message translates to:
  /// **'Vélo'**
  String get materielVelo;

  /// No description provided for @niveauDebutant.
  ///
  /// In fr, this message translates to:
  /// **'Débutant'**
  String get niveauDebutant;

  /// No description provided for @niveauIntermediaire.
  ///
  /// In fr, this message translates to:
  /// **'Intermédiaire'**
  String get niveauIntermediaire;

  /// No description provided for @niveauAvance.
  ///
  /// In fr, this message translates to:
  /// **'Avancé'**
  String get niveauAvance;

  /// No description provided for @musclePectoraux.
  ///
  /// In fr, this message translates to:
  /// **'Pectoraux'**
  String get musclePectoraux;

  /// No description provided for @muscleDos.
  ///
  /// In fr, this message translates to:
  /// **'Dos'**
  String get muscleDos;

  /// No description provided for @muscleTrapezes.
  ///
  /// In fr, this message translates to:
  /// **'Trapèzes'**
  String get muscleTrapezes;

  /// No description provided for @muscleEpaules.
  ///
  /// In fr, this message translates to:
  /// **'Épaules'**
  String get muscleEpaules;

  /// No description provided for @muscleBiceps.
  ///
  /// In fr, this message translates to:
  /// **'Biceps'**
  String get muscleBiceps;

  /// No description provided for @muscleTriceps.
  ///
  /// In fr, this message translates to:
  /// **'Triceps'**
  String get muscleTriceps;

  /// No description provided for @muscleAvantBras.
  ///
  /// In fr, this message translates to:
  /// **'Avant-bras'**
  String get muscleAvantBras;

  /// No description provided for @muscleAbdos.
  ///
  /// In fr, this message translates to:
  /// **'Abdos'**
  String get muscleAbdos;

  /// No description provided for @muscleObliques.
  ///
  /// In fr, this message translates to:
  /// **'Obliques'**
  String get muscleObliques;

  /// No description provided for @muscleLombaires.
  ///
  /// In fr, this message translates to:
  /// **'Lombaires'**
  String get muscleLombaires;

  /// No description provided for @muscleFessiers.
  ///
  /// In fr, this message translates to:
  /// **'Fessiers'**
  String get muscleFessiers;

  /// No description provided for @muscleQuadriceps.
  ///
  /// In fr, this message translates to:
  /// **'Quadriceps'**
  String get muscleQuadriceps;

  /// No description provided for @muscleIschios.
  ///
  /// In fr, this message translates to:
  /// **'Ischios'**
  String get muscleIschios;

  /// No description provided for @muscleAdducteurs.
  ///
  /// In fr, this message translates to:
  /// **'Adducteurs'**
  String get muscleAdducteurs;

  /// No description provided for @muscleMollets.
  ///
  /// In fr, this message translates to:
  /// **'Mollets'**
  String get muscleMollets;

  /// No description provided for @objectifForce.
  ///
  /// In fr, this message translates to:
  /// **'Force'**
  String get objectifForce;

  /// No description provided for @objectifVolume.
  ///
  /// In fr, this message translates to:
  /// **'Volume musculaire'**
  String get objectifVolume;

  /// No description provided for @objectifEndurance.
  ///
  /// In fr, this message translates to:
  /// **'Endurance'**
  String get objectifEndurance;

  /// No description provided for @objectifForceDetail.
  ///
  /// In fr, this message translates to:
  /// **'4 à 6 répétitions, repos long'**
  String get objectifForceDetail;

  /// No description provided for @objectifVolumeDetail.
  ///
  /// In fr, this message translates to:
  /// **'8 à 12 répétitions, 60 à 90 s de repos'**
  String get objectifVolumeDetail;

  /// No description provided for @objectifEnduranceDetail.
  ///
  /// In fr, this message translates to:
  /// **'15 à 20 répétitions, repos court'**
  String get objectifEnduranceDetail;

  /// No description provided for @ressentiFacile.
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get ressentiFacile;

  /// No description provided for @ressentiCorrect.
  ///
  /// In fr, this message translates to:
  /// **'Correct'**
  String get ressentiCorrect;

  /// No description provided for @ressentiDifficile.
  ///
  /// In fr, this message translates to:
  /// **'Difficile'**
  String get ressentiDifficile;

  /// No description provided for @ressentiEchec.
  ///
  /// In fr, this message translates to:
  /// **'Échec'**
  String get ressentiEchec;

  /// No description provided for @effort1.
  ///
  /// In fr, this message translates to:
  /// **'Facile'**
  String get effort1;

  /// No description provided for @effort2.
  ///
  /// In fr, this message translates to:
  /// **'Modéré'**
  String get effort2;

  /// No description provided for @effort3.
  ///
  /// In fr, this message translates to:
  /// **'Soutenu'**
  String get effort3;

  /// No description provided for @effort4.
  ///
  /// In fr, this message translates to:
  /// **'Dur'**
  String get effort4;

  /// No description provided for @effort5.
  ///
  /// In fr, this message translates to:
  /// **'Épuisant'**
  String get effort5;

  /// No description provided for @phaseEchauffement.
  ///
  /// In fr, this message translates to:
  /// **'Échauffement'**
  String get phaseEchauffement;

  /// No description provided for @phaseEffort.
  ///
  /// In fr, this message translates to:
  /// **'Vite'**
  String get phaseEffort;

  /// No description provided for @phaseRecuperation.
  ///
  /// In fr, this message translates to:
  /// **'Lent'**
  String get phaseRecuperation;

  /// No description provided for @phaseRetourCalme.
  ///
  /// In fr, this message translates to:
  /// **'Retour au calme'**
  String get phaseRetourCalme;

  /// No description provided for @roleSeance.
  ///
  /// In fr, this message translates to:
  /// **'Séance'**
  String get roleSeance;

  /// No description provided for @recordCharge.
  ///
  /// In fr, this message translates to:
  /// **'Charge maximale'**
  String get recordCharge;

  /// No description provided for @recordReps.
  ///
  /// In fr, this message translates to:
  /// **'Répétitions maximales'**
  String get recordReps;

  /// No description provided for @recordForce.
  ///
  /// In fr, this message translates to:
  /// **'Force maximale estimée'**
  String get recordForce;

  /// No description provided for @recordDuree.
  ///
  /// In fr, this message translates to:
  /// **'Durée maximale'**
  String get recordDuree;

  /// No description provided for @progresPremiereFois.
  ///
  /// In fr, this message translates to:
  /// **'Première fois : trouve ta charge'**
  String get progresPremiereFois;

  /// No description provided for @progresPareil.
  ///
  /// In fr, this message translates to:
  /// **'Comme la dernière fois'**
  String get progresPareil;

  /// No description provided for @progresRepDePlus.
  ///
  /// In fr, this message translates to:
  /// **'Une répétition de plus que la dernière fois'**
  String get progresRepDePlus;

  /// No description provided for @progresPlusDeCharge.
  ///
  /// In fr, this message translates to:
  /// **'Tout réussi la dernière fois : un peu plus lourd'**
  String get progresPlusDeCharge;

  /// No description provided for @progresPlusLong.
  ///
  /// In fr, this message translates to:
  /// **'5 secondes de plus que la dernière fois'**
  String get progresPlusLong;

  /// No description provided for @seanceDuJourTitre.
  ///
  /// In fr, this message translates to:
  /// **'Séance du jour'**
  String get seanceDuJourTitre;

  /// No description provided for @rienDePrevu.
  ///
  /// In fr, this message translates to:
  /// **'Rien de prévu aujourd\'hui'**
  String get rienDePrevu;

  /// No description provided for @prochaineLe.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine : {seance} · {quand}'**
  String prochaineLe(String seance, String quand);

  /// No description provided for @seanceFaiteAujourdhui.
  ///
  /// In fr, this message translates to:
  /// **'Faite aujourd\'hui'**
  String get seanceFaiteAujourdhui;

  /// No description provided for @creerSeance.
  ///
  /// In fr, this message translates to:
  /// **'Créer une séance'**
  String get creerSeance;

  /// No description provided for @banqueExercices.
  ///
  /// In fr, this message translates to:
  /// **'Banque d\'exercices'**
  String get banqueExercices;

  /// No description provided for @statistiques.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistiques;

  /// No description provided for @enRecuperation.
  ///
  /// In fr, this message translates to:
  /// **'En récupération'**
  String get enRecuperation;

  /// No description provided for @encoreDuree.
  ///
  /// In fr, this message translates to:
  /// **'encore {duree}'**
  String encoreDuree(String duree);

  /// No description provided for @recuperationAide.
  ///
  /// In fr, this message translates to:
  /// **'Travaillés lourdement il y a moins de 48 h : le constructeur les évite.'**
  String get recuperationAide;

  /// No description provided for @coursesTitre.
  ///
  /// In fr, this message translates to:
  /// **'Course, marche, vélo'**
  String get coursesTitre;

  /// No description provided for @activiteCourse.
  ///
  /// In fr, this message translates to:
  /// **'Course'**
  String get activiteCourse;

  /// No description provided for @activiteMarche.
  ///
  /// In fr, this message translates to:
  /// **'Marche'**
  String get activiteMarche;

  /// No description provided for @activiteVelo.
  ///
  /// In fr, this message translates to:
  /// **'Vélo'**
  String get activiteVelo;

  /// No description provided for @activiteFractionne.
  ///
  /// In fr, this message translates to:
  /// **'Fractionné'**
  String get activiteFractionne;

  /// No description provided for @programmesProgressifs.
  ///
  /// In fr, this message translates to:
  /// **'Programmes progressifs'**
  String get programmesProgressifs;

  /// No description provided for @mesSeances.
  ///
  /// In fr, this message translates to:
  /// **'Mes séances'**
  String get mesSeances;

  /// No description provided for @aucuneSeanceEnregistree.
  ///
  /// In fr, this message translates to:
  /// **'Aucune séance enregistrée. Crée la tienne : Rhythm l\'organise.'**
  String get aucuneSeanceEnregistree;

  /// No description provided for @resumeSeance.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{aucun exercice} =1{1 exercice} other{{n} exercices}} · env. {minutes} min'**
  String resumeSeance(int n, int minutes);

  /// No description provided for @aLaDemande.
  ///
  /// In fr, this message translates to:
  /// **'À la demande'**
  String get aLaDemande;

  /// No description provided for @defisTitre.
  ///
  /// In fr, this message translates to:
  /// **'Défis de 4 semaines'**
  String get defisTitre;

  /// No description provided for @voirLesDefis.
  ///
  /// In fr, this message translates to:
  /// **'Voir les défis'**
  String get voirLesDefis;

  /// No description provided for @routinesExpress.
  ///
  /// In fr, this message translates to:
  /// **'Routines express'**
  String get routinesExpress;

  /// No description provided for @dureeMinutesCourt.
  ///
  /// In fr, this message translates to:
  /// **'{n} min'**
  String dureeMinutesCourt(int n);

  /// No description provided for @journalSport.
  ///
  /// In fr, this message translates to:
  /// **'Journal'**
  String get journalSport;

  /// No description provided for @toutLeJournal.
  ///
  /// In fr, this message translates to:
  /// **'Tout le journal'**
  String get toutLeJournal;

  /// No description provided for @journalVide.
  ///
  /// In fr, this message translates to:
  /// **'Ta première séance apparaîtra ici.'**
  String get journalVide;

  /// No description provided for @mesures.
  ///
  /// In fr, this message translates to:
  /// **'Mesures'**
  String get mesures;

  /// No description provided for @materielEtObjectifs.
  ///
  /// In fr, this message translates to:
  /// **'Matériel et objectifs'**
  String get materielEtObjectifs;

  /// No description provided for @monMateriel.
  ///
  /// In fr, this message translates to:
  /// **'Mon matériel'**
  String get monMateriel;

  /// No description provided for @materielAide.
  ///
  /// In fr, this message translates to:
  /// **'La banque te montre d\'abord ce que tu peux faire avec.'**
  String get materielAide;

  /// No description provided for @sansMaterielDu.
  ///
  /// In fr, this message translates to:
  /// **'Rien d\'autre que le poids du corps'**
  String get sansMaterielDu;

  /// No description provided for @objectif.
  ///
  /// In fr, this message translates to:
  /// **'Objectif'**
  String get objectif;

  /// No description provided for @niveau.
  ///
  /// In fr, this message translates to:
  /// **'Niveau'**
  String get niveau;

  /// No description provided for @poidsDuCorps.
  ///
  /// In fr, this message translates to:
  /// **'Poids du corps'**
  String get poidsDuCorps;

  /// No description provided for @poidsAide.
  ///
  /// In fr, this message translates to:
  /// **'Pour estimer les calories.'**
  String get poidsAide;

  /// No description provided for @minutesParSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Minutes par semaine'**
  String get minutesParSemaine;

  /// No description provided for @minutesParJour.
  ///
  /// In fr, this message translates to:
  /// **'Minutes par jour'**
  String get minutesParJour;

  /// No description provided for @enchainerOpposes.
  ///
  /// In fr, this message translates to:
  /// **'Enchaîner les exercices opposés'**
  String get enchainerOpposes;

  /// No description provided for @enchainerAide.
  ///
  /// In fr, this message translates to:
  /// **'Deux exercices opposés sans repos entre eux : la séance est plus courte.'**
  String get enchainerAide;

  /// No description provided for @lienHabitude.
  ///
  /// In fr, this message translates to:
  /// **'Cocher l\'habitude « Entraînement »'**
  String get lienHabitude;

  /// No description provided for @lienHabitudeAide.
  ///
  /// In fr, this message translates to:
  /// **'Une séance enregistrée la coche pour la journée.'**
  String get lienHabitudeAide;

  /// No description provided for @kgValeur.
  ///
  /// In fr, this message translates to:
  /// **'{n} kg'**
  String kgValeur(String n);

  /// No description provided for @cmValeur.
  ///
  /// In fr, this message translates to:
  /// **'{n} cm'**
  String cmValeur(String n);

  /// No description provided for @rechercherExercice.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher un exercice'**
  String get rechercherExercice;

  /// No description provided for @avecMonMateriel.
  ///
  /// In fr, this message translates to:
  /// **'Avec mon matériel'**
  String get avecMonMateriel;

  /// No description provided for @sansMateriel.
  ///
  /// In fr, this message translates to:
  /// **'Sans matériel'**
  String get sansMateriel;

  /// No description provided for @tousLesStyles.
  ///
  /// In fr, this message translates to:
  /// **'Tous les styles'**
  String get tousLesStyles;

  /// No description provided for @tousLesMuscles.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get tousLesMuscles;

  /// No description provided for @nExercices.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun exercice} =1{1 exercice} other{{n} exercices}}'**
  String nExercices(int n);

  /// No description provided for @aucunExercice.
  ///
  /// In fr, this message translates to:
  /// **'Aucun exercice ne correspond.'**
  String get aucunExercice;

  /// No description provided for @quelMateriel.
  ///
  /// In fr, this message translates to:
  /// **'Quel matériel as-tu ?'**
  String get quelMateriel;

  /// No description provided for @quelMaterielAide.
  ///
  /// In fr, this message translates to:
  /// **'Dis-le une fois : la banque te montre d\'abord ce que tu peux faire.'**
  String get quelMaterielAide;

  /// No description provided for @confirmer.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirmer;

  /// No description provided for @musclesPrincipaux.
  ///
  /// In fr, this message translates to:
  /// **'Muscles principaux'**
  String get musclesPrincipaux;

  /// No description provided for @musclesSecondaires.
  ///
  /// In fr, this message translates to:
  /// **'Muscles secondaires'**
  String get musclesSecondaires;

  /// No description provided for @materiel.
  ///
  /// In fr, this message translates to:
  /// **'Matériel'**
  String get materiel;

  /// No description provided for @aucunMateriel.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get aucunMateriel;

  /// No description provided for @polyarticulaire.
  ///
  /// In fr, this message translates to:
  /// **'Polyarticulaire'**
  String get polyarticulaire;

  /// No description provided for @isolation.
  ///
  /// In fr, this message translates to:
  /// **'Isolation'**
  String get isolation;

  /// No description provided for @deChaqueCote.
  ///
  /// In fr, this message translates to:
  /// **'De chaque côté'**
  String get deChaqueCote;

  /// No description provided for @etapes.
  ///
  /// In fr, this message translates to:
  /// **'Étapes'**
  String get etapes;

  /// No description provided for @erreursFrequentes.
  ///
  /// In fr, this message translates to:
  /// **'Erreurs fréquentes'**
  String get erreursFrequentes;

  /// No description provided for @respiration.
  ///
  /// In fr, this message translates to:
  /// **'Respiration'**
  String get respiration;

  /// No description provided for @variantes.
  ///
  /// In fr, this message translates to:
  /// **'Variantes'**
  String get variantes;

  /// No description provided for @plusFacile.
  ///
  /// In fr, this message translates to:
  /// **'Plus facile'**
  String get plusFacile;

  /// No description provided for @plusDur.
  ///
  /// In fr, this message translates to:
  /// **'Plus dur'**
  String get plusDur;

  /// No description provided for @tuEsIci.
  ///
  /// In fr, this message translates to:
  /// **'Tu es ici'**
  String get tuEsIci;

  /// No description provided for @tesRecords.
  ///
  /// In fr, this message translates to:
  /// **'Tes records'**
  String get tesRecords;

  /// No description provided for @ajouterASeance.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à une séance'**
  String get ajouterASeance;

  /// No description provided for @nouvelleSeance.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle séance'**
  String get nouvelleSeance;

  /// No description provided for @toastAjouteA.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté à « {seance} »'**
  String toastAjouteA(String seance);

  /// No description provided for @lesZones.
  ///
  /// In fr, this message translates to:
  /// **'Les zones'**
  String get lesZones;

  /// No description provided for @zonesAide.
  ///
  /// In fr, this message translates to:
  /// **'Touche les muscles à travailler, de face et de dos. Sans zone : tout le corps.'**
  String get zonesAide;

  /// No description provided for @vueFace.
  ///
  /// In fr, this message translates to:
  /// **'Face'**
  String get vueFace;

  /// No description provided for @vueDos.
  ///
  /// In fr, this message translates to:
  /// **'Dos'**
  String get vueDos;

  /// No description provided for @toutLeCorps.
  ///
  /// In fr, this message translates to:
  /// **'Tout le corps'**
  String get toutLeCorps;

  /// No description provided for @effacer.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get effacer;

  /// No description provided for @lesExercices.
  ///
  /// In fr, this message translates to:
  /// **'Les exercices'**
  String get lesExercices;

  /// No description provided for @exercicesAide.
  ///
  /// In fr, this message translates to:
  /// **'Choisis tes exercices, ou laisse Rhythm compléter.'**
  String get exercicesAide;

  /// No description provided for @completer.
  ///
  /// In fr, this message translates to:
  /// **'Compléter'**
  String get completer;

  /// No description provided for @completerAide.
  ///
  /// In fr, this message translates to:
  /// **'Des exercices équilibrés pour tes zones, avec ton matériel.'**
  String get completerAide;

  /// No description provided for @nChoisis.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{aucun choisi} =1{1 choisi} other{{n} choisis}}'**
  String nChoisis(int n);

  /// No description provided for @voirApercu.
  ///
  /// In fr, this message translates to:
  /// **'Voir l\'aperçu'**
  String get voirApercu;

  /// No description provided for @evitesRecuperation.
  ///
  /// In fr, this message translates to:
  /// **'Évités, en récupération : {muscles}'**
  String evitesRecuperation(String muscles);

  /// No description provided for @choisirUnExercice.
  ///
  /// In fr, this message translates to:
  /// **'Choisis au moins un exercice.'**
  String get choisirUnExercice;

  /// No description provided for @pourCesZones.
  ///
  /// In fr, this message translates to:
  /// **'Pour tes zones'**
  String get pourCesZones;

  /// No description provided for @apercu.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get apercu;

  /// No description provided for @dureeEstimee.
  ///
  /// In fr, this message translates to:
  /// **'Durée estimée'**
  String get dureeEstimee;

  /// No description provided for @environMinutes.
  ///
  /// In fr, this message translates to:
  /// **'env. {n} min'**
  String environMinutes(int n);

  /// No description provided for @seriesParMuscle.
  ///
  /// In fr, this message translates to:
  /// **'Séries par muscle'**
  String get seriesParMuscle;

  /// No description provided for @echauffement.
  ///
  /// In fr, this message translates to:
  /// **'Échauffement'**
  String get echauffement;

  /// No description provided for @retourAuCalme.
  ///
  /// In fr, this message translates to:
  /// **'Retour au calme'**
  String get retourAuCalme;

  /// No description provided for @dosageReps.
  ///
  /// In fr, this message translates to:
  /// **'{series} × {reps}'**
  String dosageReps(int series, int reps);

  /// No description provided for @dosageSecondes.
  ///
  /// In fr, this message translates to:
  /// **'{series} × {secondes} s'**
  String dosageSecondes(int series, int secondes);

  /// No description provided for @dureeSecondes.
  ///
  /// In fr, this message translates to:
  /// **'{n} s'**
  String dureeSecondes(int n);

  /// No description provided for @reposDe.
  ///
  /// In fr, this message translates to:
  /// **'repos {duree}'**
  String reposDe(String duree);

  /// No description provided for @enchaine.
  ///
  /// In fr, this message translates to:
  /// **'Enchaîné'**
  String get enchaine;

  /// No description provided for @ajouterUnExercice.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un exercice'**
  String get ajouterUnExercice;

  /// No description provided for @series.
  ///
  /// In fr, this message translates to:
  /// **'Séries'**
  String get series;

  /// No description provided for @repetitions.
  ///
  /// In fr, this message translates to:
  /// **'Répétitions'**
  String get repetitions;

  /// No description provided for @dureeSerie.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get dureeSerie;

  /// No description provided for @charge.
  ///
  /// In fr, this message translates to:
  /// **'Charge'**
  String get charge;

  /// No description provided for @repos.
  ///
  /// In fr, this message translates to:
  /// **'Repos'**
  String get repos;

  /// No description provided for @sansCharge.
  ///
  /// In fr, this message translates to:
  /// **'Poids du corps'**
  String get sansCharge;

  /// No description provided for @enregistrerLaSeance.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer la séance'**
  String get enregistrerLaSeance;

  /// No description provided for @indiceNomSeance.
  ///
  /// In fr, this message translates to:
  /// **'Haut du corps, jambes, full body…'**
  String get indiceNomSeance;

  /// No description provided for @joursPrevus.
  ///
  /// In fr, this message translates to:
  /// **'Jours prévus'**
  String get joursPrevus;

  /// No description provided for @joursPrevusAide.
  ///
  /// In fr, this message translates to:
  /// **'Prévue ces jours-là, elle devient la « Séance du jour ».'**
  String get joursPrevusAide;

  /// No description provided for @meLeRappeler.
  ///
  /// In fr, this message translates to:
  /// **'Me le rappeler'**
  String get meLeRappeler;

  /// No description provided for @supprimerSeance.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la séance'**
  String get supprimerSeance;

  /// No description provided for @toastSeanceEnregistreeProgramme.
  ///
  /// In fr, this message translates to:
  /// **'Séance enregistrée'**
  String get toastSeanceEnregistreeProgramme;

  /// No description provided for @retouchesAide.
  ///
  /// In fr, this message translates to:
  /// **'Touche une ligne pour la retoucher, maintiens-la pour la déplacer.'**
  String get retouchesAide;

  /// No description provided for @serieSur.
  ///
  /// In fr, this message translates to:
  /// **'Série {n} sur {total}'**
  String serieSur(int n, int total);

  /// No description provided for @exerciceSur.
  ///
  /// In fr, this message translates to:
  /// **'{n} sur {total}'**
  String exerciceSur(int n, int total);

  /// No description provided for @serieFaite.
  ///
  /// In fr, this message translates to:
  /// **'Série faite'**
  String get serieFaite;

  /// No description provided for @demarrer.
  ///
  /// In fr, this message translates to:
  /// **'Démarrer'**
  String get demarrer;

  /// No description provided for @cestFait.
  ///
  /// In fr, this message translates to:
  /// **'C\'est fait'**
  String get cestFait;

  /// No description provided for @plusQuinze.
  ///
  /// In fr, this message translates to:
  /// **'+15 s'**
  String get plusQuinze;

  /// No description provided for @passer.
  ///
  /// In fr, this message translates to:
  /// **'Passer'**
  String get passer;

  /// No description provided for @aSuivre.
  ///
  /// In fr, this message translates to:
  /// **'À suivre'**
  String get aSuivre;

  /// No description provided for @commentCetait.
  ///
  /// In fr, this message translates to:
  /// **'Comment c\'était ?'**
  String get commentCetait;

  /// No description provided for @laDerniereFois.
  ///
  /// In fr, this message translates to:
  /// **'La dernière fois : {detail}'**
  String laDerniereFois(String detail);

  /// No description provided for @arreterSeance.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter la séance ?'**
  String get arreterSeance;

  /// No description provided for @garderCeQuiEstFait.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer ce qui est fait'**
  String get garderCeQuiEstFait;

  /// No description provided for @abandonnerSeance.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner sans enregistrer'**
  String get abandonnerSeance;

  /// No description provided for @reprendre.
  ///
  /// In fr, this message translates to:
  /// **'Reprendre'**
  String get reprendre;

  /// No description provided for @passerExercice.
  ///
  /// In fr, this message translates to:
  /// **'Passer l\'exercice'**
  String get passerExercice;

  /// No description provided for @toastRecord.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau record : {detail} !'**
  String toastRecord(String detail);

  /// No description provided for @reposFini.
  ///
  /// In fr, this message translates to:
  /// **'Repos fini'**
  String get reposFini;

  /// No description provided for @chaqueCote.
  ///
  /// In fr, this message translates to:
  /// **'de chaque côté'**
  String get chaqueCote;

  /// No description provided for @pret.
  ///
  /// In fr, this message translates to:
  /// **'Prépare-toi'**
  String get pret;

  /// No description provided for @seanceTerminee.
  ///
  /// In fr, this message translates to:
  /// **'Séance terminée'**
  String get seanceTerminee;

  /// No description provided for @duree.
  ///
  /// In fr, this message translates to:
  /// **'Durée'**
  String get duree;

  /// No description provided for @volume.
  ///
  /// In fr, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @seriesFaites.
  ///
  /// In fr, this message translates to:
  /// **'Séries'**
  String get seriesFaites;

  /// No description provided for @recordsBattus.
  ///
  /// In fr, this message translates to:
  /// **'Records battus'**
  String get recordsBattus;

  /// No description provided for @ressentiGlobal.
  ///
  /// In fr, this message translates to:
  /// **'Ressenti'**
  String get ressentiGlobal;

  /// No description provided for @note.
  ///
  /// In fr, this message translates to:
  /// **'Note'**
  String get note;

  /// No description provided for @indiceNote.
  ///
  /// In fr, this message translates to:
  /// **'Ce que tu as remarqué, ce qui a changé…'**
  String get indiceNote;

  /// No description provided for @toastSeanceEnregistree.
  ///
  /// In fr, this message translates to:
  /// **'Séance enregistrée'**
  String get toastSeanceEnregistree;

  /// No description provided for @toastSeanceHabitude.
  ///
  /// In fr, this message translates to:
  /// **'Séance enregistrée · « {habitude} » cochée'**
  String toastSeanceHabitude(String habitude);

  /// No description provided for @toastEtapeValidee.
  ///
  /// In fr, this message translates to:
  /// **'Séance enregistrée · étape validée'**
  String get toastEtapeValidee;

  /// No description provided for @enCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get enCours;

  /// No description provided for @enPause.
  ///
  /// In fr, this message translates to:
  /// **'En pause'**
  String get enPause;

  /// No description provided for @pause.
  ///
  /// In fr, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @distance.
  ///
  /// In fr, this message translates to:
  /// **'Distance'**
  String get distance;

  /// No description provided for @indiceKm.
  ///
  /// In fr, this message translates to:
  /// **'en km'**
  String get indiceKm;

  /// No description provided for @allure.
  ///
  /// In fr, this message translates to:
  /// **'Allure'**
  String get allure;

  /// No description provided for @vitesse.
  ///
  /// In fr, this message translates to:
  /// **'Vitesse'**
  String get vitesse;

  /// No description provided for @allureValeur.
  ///
  /// In fr, this message translates to:
  /// **'{temps} /km'**
  String allureValeur(String temps);

  /// No description provided for @vitesseValeur.
  ///
  /// In fr, this message translates to:
  /// **'{v} km/h'**
  String vitesseValeur(String v);

  /// No description provided for @kmValeur.
  ///
  /// In fr, this message translates to:
  /// **'{n} km'**
  String kmValeur(String n);

  /// No description provided for @effortRessenti.
  ///
  /// In fr, this message translates to:
  /// **'Effort ressenti'**
  String get effortRessenti;

  /// No description provided for @demarrerActivite.
  ///
  /// In fr, this message translates to:
  /// **'C\'est parti'**
  String get demarrerActivite;

  /// No description provided for @pasDeGps.
  ///
  /// In fr, this message translates to:
  /// **'Rhythm chronomètre ; tu notes la distance à la fin.'**
  String get pasDeGps;

  /// No description provided for @fractionnesPrets.
  ///
  /// In fr, this message translates to:
  /// **'Prêts à lancer'**
  String get fractionnesPrets;

  /// No description provided for @personnaliser.
  ///
  /// In fr, this message translates to:
  /// **'Personnaliser'**
  String get personnaliser;

  /// No description provided for @repetitionsIntervalles.
  ///
  /// In fr, this message translates to:
  /// **'Répétitions'**
  String get repetitionsIntervalles;

  /// No description provided for @effortIntervalle.
  ///
  /// In fr, this message translates to:
  /// **'Effort'**
  String get effortIntervalle;

  /// No description provided for @recuperationIntervalle.
  ///
  /// In fr, this message translates to:
  /// **'Récupération'**
  String get recuperationIntervalle;

  /// No description provided for @lancer.
  ///
  /// In fr, this message translates to:
  /// **'Lancer'**
  String get lancer;

  /// No description provided for @intervalleSur.
  ///
  /// In fr, this message translates to:
  /// **'{n} sur {total}'**
  String intervalleSur(int n, int total);

  /// No description provided for @intervallesResume.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 répétition} other{{n} répétitions}} · {minutes} min au total'**
  String intervallesResume(int n, int minutes);

  /// No description provided for @monFractionne.
  ///
  /// In fr, this message translates to:
  /// **'Mon fractionné'**
  String get monFractionne;

  /// No description provided for @nSemaines.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 semaine} other{{n} semaines}}'**
  String nSemaines(int n);

  /// No description provided for @troisParSemaine.
  ///
  /// In fr, this message translates to:
  /// **'3 séances par semaine'**
  String get troisParSemaine;

  /// No description provided for @seanceNumero.
  ///
  /// In fr, this message translates to:
  /// **'Séance {n} sur {total}'**
  String seanceNumero(int n, int total);

  /// No description provided for @commencerProgramme.
  ///
  /// In fr, this message translates to:
  /// **'Commencer le programme'**
  String get commencerProgramme;

  /// No description provided for @arreterProgramme.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter le programme'**
  String get arreterProgramme;

  /// No description provided for @prochaineEtape.
  ///
  /// In fr, this message translates to:
  /// **'Prochaine séance'**
  String get prochaineEtape;

  /// No description provided for @programmeTermine.
  ///
  /// In fr, this message translates to:
  /// **'Programme terminé. Bravo !'**
  String get programmeTermine;

  /// No description provided for @enCoursDepuis.
  ///
  /// In fr, this message translates to:
  /// **'En cours depuis le {date}'**
  String enCoursDepuis(String date);

  /// No description provided for @releverDefi.
  ///
  /// In fr, this message translates to:
  /// **'Relever le défi'**
  String get releverDefi;

  /// No description provided for @abandonnerDefi.
  ///
  /// In fr, this message translates to:
  /// **'Abandonner le défi'**
  String get abandonnerDefi;

  /// No description provided for @prevueLe.
  ///
  /// In fr, this message translates to:
  /// **'prévue le {date}'**
  String prevueLe(String date);

  /// No description provided for @auTotal.
  ///
  /// In fr, this message translates to:
  /// **'{n} au total'**
  String auTotal(int n);

  /// No description provided for @defiReleve.
  ///
  /// In fr, this message translates to:
  /// **'Défi relevé !'**
  String get defiReleve;

  /// No description provided for @defiEnCours.
  ///
  /// In fr, this message translates to:
  /// **'En cours'**
  String get defiEnCours;

  /// No description provided for @etapesFaites.
  ///
  /// In fr, this message translates to:
  /// **'{n} sur {total} faites'**
  String etapesFaites(int n, int total);

  /// No description provided for @trenteDerniersJours.
  ///
  /// In fr, this message translates to:
  /// **'30 derniers jours'**
  String get trenteDerniersJours;

  /// No description provided for @parRapportAvant.
  ///
  /// In fr, this message translates to:
  /// **'{variation} par rapport aux 30 jours d\'avant'**
  String parRapportAvant(String variation);

  /// No description provided for @minutesTitre.
  ///
  /// In fr, this message translates to:
  /// **'Minutes'**
  String get minutesTitre;

  /// No description provided for @minutesEtSeancesParJour.
  ///
  /// In fr, this message translates to:
  /// **'Minutes par jour'**
  String get minutesEtSeancesParJour;

  /// No description provided for @regularite.
  ///
  /// In fr, this message translates to:
  /// **'Régularité'**
  String get regularite;

  /// No description provided for @joursActifs.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{aucun jour actif} =1{1 jour actif} other{{n} jours actifs}}'**
  String joursActifs(int n);

  /// No description provided for @parStyle.
  ///
  /// In fr, this message translates to:
  /// **'Par style'**
  String get parStyle;

  /// No description provided for @musclesTravailles.
  ///
  /// In fr, this message translates to:
  /// **'Muscles travaillés'**
  String get musclesTravailles;

  /// No description provided for @aNePasOublier.
  ///
  /// In fr, this message translates to:
  /// **'À ne pas oublier'**
  String get aNePasOublier;

  /// No description provided for @rienDepuis.
  ///
  /// In fr, this message translates to:
  /// **'{muscle} : rien depuis {n} jours'**
  String rienDepuis(String muscle, int n);

  /// No description provided for @rienEn30Jours.
  ///
  /// In fr, this message translates to:
  /// **'{muscle} : rien depuis au moins 30 jours'**
  String rienEn30Jours(String muscle);

  /// No description provided for @toutEstTravaille.
  ///
  /// In fr, this message translates to:
  /// **'Tout a été travaillé cette semaine. Bel équilibre.'**
  String get toutEstTravaille;

  /// No description provided for @recordsRecents.
  ///
  /// In fr, this message translates to:
  /// **'Records récents'**
  String get recordsRecents;

  /// No description provided for @aucunRecord.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de record sur la période.'**
  String get aucunRecord;

  /// No description provided for @moinsDe.
  ///
  /// In fr, this message translates to:
  /// **'moins'**
  String get moinsDe;

  /// No description provided for @peuPlusBeaucoup.
  ///
  /// In fr, this message translates to:
  /// **'Peu · beaucoup'**
  String get peuPlusBeaucoup;

  /// No description provided for @ajouterMesure.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une mesure'**
  String get ajouterMesure;

  /// No description provided for @poids.
  ///
  /// In fr, this message translates to:
  /// **'Poids'**
  String get poids;

  /// No description provided for @tourDeTaille.
  ///
  /// In fr, this message translates to:
  /// **'Tour de taille'**
  String get tourDeTaille;

  /// No description provided for @depuisLeDebut.
  ///
  /// In fr, this message translates to:
  /// **'{variation} depuis le début'**
  String depuisLeDebut(String variation);

  /// No description provided for @aucuneMesure.
  ///
  /// In fr, this message translates to:
  /// **'Aucune mesure pour l\'instant. Facultatif : pour suivre ta progression.'**
  String get aucuneMesure;

  /// No description provided for @indiceKg.
  ///
  /// In fr, this message translates to:
  /// **'en kg'**
  String get indiceKg;

  /// No description provided for @indiceCm.
  ///
  /// In fr, this message translates to:
  /// **'en cm'**
  String get indiceCm;

  /// No description provided for @mesureRequise.
  ///
  /// In fr, this message translates to:
  /// **'Note au moins le poids ou le tour de taille.'**
  String get mesureRequise;

  /// No description provided for @retirerDuJournal.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du journal'**
  String get retirerDuJournal;

  /// No description provided for @toucherPourRetirer.
  ///
  /// In fr, this message translates to:
  /// **'Toucher encore pour retirer'**
  String get toucherPourRetirer;

  /// No description provided for @canalSeancesNom.
  ///
  /// In fr, this message translates to:
  /// **'Séances'**
  String get canalSeancesNom;

  /// No description provided for @canalSeancesDescription.
  ///
  /// In fr, this message translates to:
  /// **'Le rappel de tes séances prévues.'**
  String get canalSeancesDescription;

  /// No description provided for @notifSeanceCorps.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Ta séance t\'attend.} =1{1 exercice · environ {minutes} min. On y va ?} other{{n} exercices · environ {minutes} min. On y va ?}}'**
  String notifSeanceCorps(int n, int minutes);

  /// No description provided for @exercicesCourt.
  ///
  /// In fr, this message translates to:
  /// **'Exercices'**
  String get exercicesCourt;

  /// No description provided for @changeDeCote.
  ///
  /// In fr, this message translates to:
  /// **'Change de côté'**
  String get changeDeCote;

  /// No description provided for @parCoteDuree.
  ///
  /// In fr, this message translates to:
  /// **'{duree} de chaque côté'**
  String parCoteDuree(String duree);

  /// No description provided for @activiteSedentaire.
  ///
  /// In fr, this message translates to:
  /// **'Assis'**
  String get activiteSedentaire;

  /// No description provided for @activiteSedentaireDetail.
  ///
  /// In fr, this message translates to:
  /// **'Surtout assis : bureau, études, écrans. Les séances s\'ajoutent à part.'**
  String get activiteSedentaireDetail;

  /// No description provided for @activiteDebout.
  ///
  /// In fr, this message translates to:
  /// **'Debout'**
  String get activiteDebout;

  /// No description provided for @activiteDeboutDetail.
  ///
  /// In fr, this message translates to:
  /// **'Souvent debout ou à marcher : commerce, enseignement, soins.'**
  String get activiteDeboutDetail;

  /// No description provided for @activitePhysique.
  ///
  /// In fr, this message translates to:
  /// **'Physique'**
  String get activitePhysique;

  /// No description provided for @activitePhysiqueDetail.
  ///
  /// In fr, this message translates to:
  /// **'Un travail physique : chantier, entrepôt, livraison.'**
  String get activitePhysiqueDetail;

  /// No description provided for @activiteQuotidienne.
  ///
  /// In fr, this message translates to:
  /// **'Activité du quotidien'**
  String get activiteQuotidienne;

  /// No description provided for @auMoment.
  ///
  /// In fr, this message translates to:
  /// **'{moment, select, dejeuner{au déjeuner} diner{au dîner} collation{à la collation} souper{au souper} other{au repas}}'**
  String auMoment(String moment);

  /// No description provided for @ajouteA.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté {auMoment} · {kcal}'**
  String ajouteA(String auMoment, String kcal);

  /// No description provided for @ajouterAu.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter {auMoment}'**
  String ajouterAu(String auMoment);

  /// No description provided for @ajouterPareil.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter de nouveau : {nom}'**
  String ajouterPareil(String nom);

  /// No description provided for @ajouterUnAliment.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un aliment'**
  String get ajouterUnAliment;

  /// No description provided for @ajustementActif.
  ///
  /// In fr, this message translates to:
  /// **'Sur 3 semaines : ta dépense réelle est d\'environ {depense}, ton poids évolue de {rythme} kg par semaine. Correction : {correction} par jour.'**
  String ajustementActif(String depense, String rythme, String correction);

  /// No description provided for @ajustementAuto.
  ///
  /// In fr, this message translates to:
  /// **'Ajustement automatique'**
  String get ajustementAuto;

  /// No description provided for @ajustementAutoDetail.
  ///
  /// In fr, this message translates to:
  /// **'Ta courbe de poids réelle corrige la formule.'**
  String get ajustementAutoDetail;

  /// No description provided for @ajustementDesactive.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé : les besoins suivent la formule.'**
  String get ajustementDesactive;

  /// No description provided for @ajustementDonnees.
  ///
  /// In fr, this message translates to:
  /// **'Il faut 10 journées notées et 3 pesées sur 10 jours. Pour l\'instant : {journees}, {pesees}.'**
  String ajustementDonnees(String journees, String pesees);

  /// No description provided for @journeesNotees.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{aucune journée notée} =1{1 journée notée} other{{n} journées notées}}'**
  String journeesNotees(int n);

  /// No description provided for @peseesNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{aucune pesée} =1{1 pesée} other{{n} pesées}}'**
  String peseesNombre(int n);

  /// No description provided for @aliments.
  ///
  /// In fr, this message translates to:
  /// **'Aliments'**
  String get aliments;

  /// No description provided for @alimentsAjoutes.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Rien à copier} =1{1 aliment ajouté} other{{n} aliments ajoutés}}'**
  String alimentsAjoutes(int n);

  /// No description provided for @anneeNaissance.
  ///
  /// In fr, this message translates to:
  /// **'Année de naissance'**
  String get anneeNaissance;

  /// No description provided for @auQuotidien.
  ///
  /// In fr, this message translates to:
  /// **'Au quotidien, hors sport'**
  String get auQuotidien;

  /// No description provided for @aucunAliment.
  ///
  /// In fr, this message translates to:
  /// **'Rien trouvé pour « {q} ». Essaie un mot plus simple, ou une entrée rapide.'**
  String aucunAliment(String q);

  /// No description provided for @baseIndisponible.
  ///
  /// In fr, this message translates to:
  /// **'La base d\'aliments n\'a pas pu être lue.'**
  String get baseIndisponible;

  /// No description provided for @calculIndicatif.
  ///
  /// In fr, this message translates to:
  /// **'Selon le calcul'**
  String get calculIndicatif;

  /// No description provided for @chargementBase.
  ///
  /// In fr, this message translates to:
  /// **'Chargement de la base d\'aliments…'**
  String get chargementBase;

  /// No description provided for @chercherAliment.
  ///
  /// In fr, this message translates to:
  /// **'Chercher un aliment (banane, riz, poulet…)'**
  String get chercherAliment;

  /// No description provided for @commeHier.
  ///
  /// In fr, this message translates to:
  /// **'Comme hier : {contenu}'**
  String commeHier(String contenu);

  /// No description provided for @compterSeances.
  ///
  /// In fr, this message translates to:
  /// **'Compter mes séances'**
  String get compterSeances;

  /// No description provided for @compterSeancesDetail.
  ///
  /// In fr, this message translates to:
  /// **'La moyenne des calories de tes séances (14 jours) s\'ajoute à tes besoins.'**
  String get compterSeancesDetail;

  /// No description provided for @conseilApresSeance.
  ///
  /// In fr, this message translates to:
  /// **'Séance faite : il te reste {n} g de protéines. Une collation (lait, yogourt grec, œufs) aide tes muscles à récupérer.'**
  String conseilApresSeance(int n);

  /// No description provided for @conseilAtteint1.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs atteints aujourd\'hui. Beau travail.'**
  String get conseilAtteint1;

  /// No description provided for @conseilAtteint2.
  ///
  /// In fr, this message translates to:
  /// **'Calories et protéines au rendez-vous : exactement ce qu\'il fallait.'**
  String get conseilAtteint2;

  /// No description provided for @conseilAtteint3.
  ///
  /// In fr, this message translates to:
  /// **'Tout y est aujourd\'hui. Ton corps te dit merci.'**
  String get conseilAtteint3;

  /// No description provided for @conseilDejeuner1.
  ///
  /// In fr, this message translates to:
  /// **'Un déjeuner avec des protéines (œufs, yogourt grec, beurre d\'arachide) tient jusqu\'au dîner.'**
  String get conseilDejeuner1;

  /// No description provided for @conseilDejeuner2.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore déjeuné ? Même petit, un déjeuner lance bien la journée.'**
  String get conseilDejeuner2;

  /// No description provided for @conseilDepasse1.
  ///
  /// In fr, this message translates to:
  /// **'Journée copieuse, ça arrive. Demain, on reprend simplement le rythme.'**
  String get conseilDepasse1;

  /// No description provided for @conseilDepasse2.
  ///
  /// In fr, this message translates to:
  /// **'Un peu au-dessus aujourd\'hui : rien de grave, c\'est la semaine qui compte.'**
  String get conseilDepasse2;

  /// No description provided for @conseilEau.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Pas encore d\'eau} =1{1 verre d\'eau} other{{n} verres d\'eau}} sur {m} : un grand verre maintenant ?'**
  String conseilEau(int n, int m);

  /// No description provided for @conseilGuide1.
  ///
  /// In fr, this message translates to:
  /// **'La moitié de l\'assiette en légumes et fruits, un quart en protéines, un quart en grains entiers.'**
  String get conseilGuide1;

  /// No description provided for @conseilGuide2.
  ///
  /// In fr, this message translates to:
  /// **'L\'eau est la boisson de choix : un verre à chaque repas, c\'est déjà beaucoup.'**
  String get conseilGuide2;

  /// No description provided for @conseilGuide3.
  ///
  /// In fr, this message translates to:
  /// **'Cuisiner plus souvent chez soi : on sait ce qu\'il y a dans l\'assiette.'**
  String get conseilGuide3;

  /// No description provided for @conseilGuide4.
  ///
  /// In fr, this message translates to:
  /// **'Des protéines à chaque repas aident à tenir jusqu\'au suivant.'**
  String get conseilGuide4;

  /// No description provided for @conseilGuide5.
  ///
  /// In fr, this message translates to:
  /// **'Les grains entiers (avoine, riz brun, pain complet) rassasient plus longtemps.'**
  String get conseilGuide5;

  /// No description provided for @conseilGuide6.
  ///
  /// In fr, this message translates to:
  /// **'Manger sans écran, lentement, en savourant : on sent mieux quand on a assez mangé.'**
  String get conseilGuide6;

  /// No description provided for @conseilGuide7.
  ///
  /// In fr, this message translates to:
  /// **'Les légumineuses (lentilles, pois chiches, haricots) : protéines et fibres, pour peu cher.'**
  String get conseilGuide7;

  /// No description provided for @conseilPrendreSoir.
  ///
  /// In fr, this message translates to:
  /// **'Pour prendre du poids, il te manque encore {n} kcal : une collation dense (noix, beurre d\'arachide, lait) fait la différence.'**
  String conseilPrendreSoir(String n);

  /// No description provided for @conseilProfil.
  ///
  /// In fr, this message translates to:
  /// **'Dis-moi ton sexe, ton âge et ta taille : tes objectifs seront calculés pour toi.'**
  String get conseilProfil;

  /// No description provided for @conseilProteinesSoir.
  ///
  /// In fr, this message translates to:
  /// **'Il te reste {n} g de protéines : poulet, poisson, tofu ou légumineuses au souper les couvrent.'**
  String conseilProteinesSoir(int n);

  /// No description provided for @dejaDansRepas.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Rien encore} =1{Déjà 1 aliment · {kcal}} other{Déjà {n} aliments · {kcal}}}'**
  String dejaDansRepas(int n, String kcal);

  /// No description provided for @detailObjectifs.
  ///
  /// In fr, this message translates to:
  /// **'{kcal} · protéines {p}'**
  String detailObjectifs(String kcal, String p);

  /// No description provided for @dontFibres.
  ///
  /// In fr, this message translates to:
  /// **'dont fibres'**
  String get dontFibres;

  /// No description provided for @dontSatures.
  ///
  /// In fr, this message translates to:
  /// **'dont saturés'**
  String get dontSatures;

  /// No description provided for @dontSucres.
  ///
  /// In fr, this message translates to:
  /// **'dont sucres'**
  String get dontSucres;

  /// No description provided for @eauAtteinte.
  ///
  /// In fr, this message translates to:
  /// **'Objectif d\'eau atteint. Bravo !'**
  String get eauAtteinte;

  /// No description provided for @eauAtteinteHabitude.
  ///
  /// In fr, this message translates to:
  /// **'Objectif d\'eau atteint : « {nom} » est cochée.'**
  String eauAtteinteHabitude(String nom);

  /// No description provided for @eauCalculee.
  ///
  /// In fr, this message translates to:
  /// **'Eau calculée pour moi'**
  String get eauCalculee;

  /// No description provided for @eauCalculeeDetail.
  ///
  /// In fr, this message translates to:
  /// **'Selon ton poids, et un verre de plus par demi-heure de sport.'**
  String get eauCalculeeDetail;

  /// No description provided for @eauObjectif.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Pas d\'objectif d\'eau} =1{1 verre d\'eau par jour ({l} L)} other{{n} verres d\'eau par jour ({l} L)}}'**
  String eauObjectif(int n, String l);

  /// No description provided for @enGrammes.
  ///
  /// In fr, this message translates to:
  /// **'En grammes'**
  String get enGrammes;

  /// No description provided for @entreeRapide.
  ///
  /// In fr, this message translates to:
  /// **'Entrée rapide'**
  String get entreeRapide;

  /// No description provided for @entreeRapideAide.
  ///
  /// In fr, this message translates to:
  /// **'Des calories sans chercher l\'aliment'**
  String get entreeRapideAide;

  /// No description provided for @entreeRapideExplication.
  ///
  /// In fr, this message translates to:
  /// **'Pour un repas au restaurant ou chez des amis : les calories suffisent ; les macronutriments, si tu les connais.'**
  String get entreeRapideExplication;

  /// No description provided for @entreeRapideNommee.
  ///
  /// In fr, this message translates to:
  /// **'Entrée rapide : « {q} »'**
  String entreeRapideNommee(String q);

  /// No description provided for @estimationProfil.
  ///
  /// In fr, this message translates to:
  /// **'Une estimation : complète « Moi » ci-dessous et note ton poids.'**
  String get estimationProfil;

  /// No description provided for @fixerMesObjectifs.
  ///
  /// In fr, this message translates to:
  /// **'Fixer mes objectifs moi-même'**
  String get fixerMesObjectifs;

  /// No description provided for @fixerMesObjectifsDetail.
  ///
  /// In fr, this message translates to:
  /// **'Tes chiffres remplacent le calcul (le plan d\'une nutritionniste, par exemple).'**
  String get fixerMesObjectifsDetail;

  /// No description provided for @gValeur.
  ///
  /// In fr, this message translates to:
  /// **'{n} g'**
  String gValeur(String n);

  /// No description provided for @grammesPortion.
  ///
  /// In fr, this message translates to:
  /// **'Grammes'**
  String get grammesPortion;

  /// No description provided for @indiceEntreeRapide.
  ///
  /// In fr, this message translates to:
  /// **'Poutine, pizza, souper au resto…'**
  String get indiceEntreeRapide;

  /// No description provided for @indiceNomProduit.
  ///
  /// In fr, this message translates to:
  /// **'Barre protéinée, céréales…'**
  String get indiceNomProduit;

  /// No description provided for @indicePortion.
  ///
  /// In fr, this message translates to:
  /// **'1 barre'**
  String get indicePortion;

  /// No description provided for @jourDeSeanceGlucides.
  ///
  /// In fr, this message translates to:
  /// **'Jour de séance : un peu plus de glucides, un peu moins de lipides.'**
  String get jourDeSeanceGlucides;

  /// No description provided for @kcalEnPlus.
  ///
  /// In fr, this message translates to:
  /// **'kcal de plus'**
  String get kcalEnPlus;

  /// No description provided for @kcalParJour.
  ///
  /// In fr, this message translates to:
  /// **'kcal par jour'**
  String get kcalParJour;

  /// No description provided for @kcalRequises.
  ///
  /// In fr, this message translates to:
  /// **'Note au moins les calories.'**
  String get kcalRequises;

  /// No description provided for @kgParSemaine.
  ///
  /// In fr, this message translates to:
  /// **'{n} kg par semaine'**
  String kgParSemaine(String n);

  /// No description provided for @leCalcul.
  ///
  /// In fr, this message translates to:
  /// **'Le calcul'**
  String get leCalcul;

  /// No description provided for @lienHabitudeEau.
  ///
  /// In fr, this message translates to:
  /// **'Cocher l\'habitude de l\'eau'**
  String get lienHabitudeEau;

  /// No description provided for @lienHabitudeEauDetail.
  ///
  /// In fr, this message translates to:
  /// **'Atteindre ton objectif d\'eau coche ton habitude de l\'eau.'**
  String get lienHabitudeEauDetail;

  /// No description provided for @litresValeur.
  ///
  /// In fr, this message translates to:
  /// **'{n} L'**
  String litresValeur(String n);

  /// No description provided for @macrosExplication.
  ///
  /// In fr, this message translates to:
  /// **'Protéines : {pk} g par kilo. Lipides : 30 % des calories (25 % un jour de séance). Glucides : le reste.'**
  String macrosExplication(String pk);

  /// No description provided for @marqueFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Marque (facultatif)'**
  String get marqueFacultatif;

  /// No description provided for @mesObjectifs.
  ///
  /// In fr, this message translates to:
  /// **'Mes objectifs'**
  String get mesObjectifs;

  /// No description provided for @mesProduits.
  ///
  /// In fr, this message translates to:
  /// **'Mes produits'**
  String get mesProduits;

  /// No description provided for @mesProduitsAide.
  ///
  /// In fr, this message translates to:
  /// **'Les aliments achetés, avec leur étiquette'**
  String get mesProduitsAide;

  /// No description provided for @mesProduitsExplication.
  ///
  /// In fr, this message translates to:
  /// **'Recopie une fois le tableau de la valeur nutritive d\'un produit (barre, yogourt, céréales) : il se note ensuite d\'un toucher.'**
  String get mesProduitsExplication;

  /// No description provided for @metabolismeBase.
  ///
  /// In fr, this message translates to:
  /// **'Métabolisme de base'**
  String get metabolismeBase;

  /// No description provided for @metabolismeBaseDetail.
  ///
  /// In fr, this message translates to:
  /// **'Ce que ton corps dépense au repos (Mifflin-St Jeor)'**
  String get metabolismeBaseDetail;

  /// No description provided for @modifierProduit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le produit'**
  String get modifierProduit;

  /// No description provided for @moi.
  ///
  /// In fr, this message translates to:
  /// **'Moi'**
  String get moi;

  /// No description provided for @moment.
  ///
  /// In fr, this message translates to:
  /// **'Moment'**
  String get moment;

  /// No description provided for @monObjectif.
  ///
  /// In fr, this message translates to:
  /// **'Mon objectif'**
  String get monObjectif;

  /// No description provided for @monProduit.
  ///
  /// In fr, this message translates to:
  /// **'Mon produit'**
  String get monProduit;

  /// No description provided for @nomDansJournal.
  ///
  /// In fr, this message translates to:
  /// **'Nom dans mon journal'**
  String get nomDansJournal;

  /// No description provided for @nomFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Nom (facultatif)'**
  String get nomFacultatif;

  /// No description provided for @nomProduit.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get nomProduit;

  /// No description provided for @nombreDe.
  ///
  /// In fr, this message translates to:
  /// **'Portions ({unite})'**
  String nombreDe(String unite);

  /// No description provided for @nombreDePortions.
  ///
  /// In fr, this message translates to:
  /// **'Portions'**
  String get nombreDePortions;

  /// No description provided for @noterUnRepas.
  ///
  /// In fr, this message translates to:
  /// **'Noter un repas'**
  String get noterUnRepas;

  /// No description provided for @nouveauProduit.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau produit'**
  String get nouveauProduit;

  /// No description provided for @nouveauProduitAide.
  ///
  /// In fr, this message translates to:
  /// **'Recopier l\'étiquette d\'un produit acheté'**
  String get nouveauProduitAide;

  /// No description provided for @objectifPerdre.
  ///
  /// In fr, this message translates to:
  /// **'Perdre du poids'**
  String get objectifPerdre;

  /// No description provided for @objectifMaintenir.
  ///
  /// In fr, this message translates to:
  /// **'Maintenir'**
  String get objectifMaintenir;

  /// No description provided for @objectifPrendre.
  ///
  /// In fr, this message translates to:
  /// **'Prendre du poids'**
  String get objectifPrendre;

  /// No description provided for @objectifPerdreDetail.
  ///
  /// In fr, this message translates to:
  /// **'Un déficit de {kcal} par jour : une perte douce, qui garde le muscle (protéines plus hautes).'**
  String objectifPerdreDetail(String kcal);

  /// No description provided for @objectifMaintenirDetail.
  ///
  /// In fr, this message translates to:
  /// **'Autant de calories que tu en dépenses.'**
  String get objectifMaintenirDetail;

  /// No description provided for @objectifPrendreDetail.
  ///
  /// In fr, this message translates to:
  /// **'Un surplus de {kcal} par jour : une prise lente, surtout du muscle si tu t\'entraînes.'**
  String objectifPrendreDetail(String kcal);

  /// No description provided for @objectifsEstimes.
  ///
  /// In fr, this message translates to:
  /// **'Une estimation : à compléter'**
  String get objectifsEstimes;

  /// No description provided for @objectifsFixesMain.
  ///
  /// In fr, this message translates to:
  /// **'Tes objectifs sont fixés à la main.'**
  String get objectifsFixesMain;

  /// No description provided for @ouEnGrammes.
  ///
  /// In fr, this message translates to:
  /// **'Ou en grammes'**
  String get ouEnGrammes;

  /// No description provided for @pasAvisMedical.
  ///
  /// In fr, this message translates to:
  /// **'Des repères pour bien se nourrir, pas un avis médical. En cas de doute (grossesse, maladie, troubles alimentaires), parles-en à un professionnel de la santé.'**
  String get pasAvisMedical;

  /// No description provided for @poidsAucun.
  ///
  /// In fr, this message translates to:
  /// **'Aucune pesée : ajoute-la dans les Mesures'**
  String get poidsAucun;

  /// No description provided for @poidsDepuisMesures.
  ///
  /// In fr, this message translates to:
  /// **'Dernière pesée le {date} · Mesures'**
  String poidsDepuisMesures(String date);

  /// No description provided for @portionEtiquette.
  ///
  /// In fr, this message translates to:
  /// **'Portion (étiquette)'**
  String get portionEtiquette;

  /// No description provided for @pour100g.
  ///
  /// In fr, this message translates to:
  /// **'{kcal} · protéines {p} · pour 100 g'**
  String pour100g(String kcal, String p);

  /// No description provided for @produitAjoute.
  ///
  /// In fr, this message translates to:
  /// **'Produit ajouté'**
  String get produitAjoute;

  /// No description provided for @produitModifie.
  ///
  /// In fr, this message translates to:
  /// **'Produit modifié'**
  String get produitModifie;

  /// No description provided for @produitsNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun produit} =1{1 produit} other{{n} produits}}'**
  String produitsNombre(int n);

  /// No description provided for @proteinesCourt.
  ///
  /// In fr, this message translates to:
  /// **'protéines {g}'**
  String proteinesCourt(String g);

  /// No description provided for @quantite.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get quantite;

  /// No description provided for @quantiteRequise.
  ///
  /// In fr, this message translates to:
  /// **'Choisis une quantité.'**
  String get quantiteRequise;

  /// No description provided for @recents.
  ///
  /// In fr, this message translates to:
  /// **'Récents'**
  String get recents;

  /// No description provided for @repasVide.
  ///
  /// In fr, this message translates to:
  /// **'Rien de noté pour ce repas.'**
  String get repasVide;

  /// No description provided for @retirerDuRepas.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du repas'**
  String get retirerDuRepas;

  /// No description provided for @rienDeNote.
  ///
  /// In fr, this message translates to:
  /// **'Rien de noté'**
  String get rienDeNote;

  /// No description provided for @rienEncore.
  ///
  /// In fr, this message translates to:
  /// **'Rien de noté pour l\'instant.'**
  String get rienEncore;

  /// No description provided for @seancesMoyenne.
  ///
  /// In fr, this message translates to:
  /// **'Séances (moyenne de 14 jours)'**
  String get seancesMoyenne;

  /// No description provided for @seancesNonComptees.
  ///
  /// In fr, this message translates to:
  /// **'Non comptées'**
  String get seancesNonComptees;

  /// No description provided for @sexeFemme.
  ///
  /// In fr, this message translates to:
  /// **'Femme'**
  String get sexeFemme;

  /// No description provided for @sexeHomme.
  ///
  /// In fr, this message translates to:
  /// **'Homme'**
  String get sexeHomme;

  /// No description provided for @sodium.
  ///
  /// In fr, this message translates to:
  /// **'Sodium'**
  String get sodium;

  /// No description provided for @sourceFcen.
  ///
  /// In fr, this message translates to:
  /// **'Valeurs nutritives : Fichier canadien sur les éléments nutritifs 2026, Santé Canada.'**
  String get sourceFcen;

  /// No description provided for @supprimerProduit.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le produit'**
  String get supprimerProduit;

  /// No description provided for @taille.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get taille;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @unePortion.
  ///
  /// In fr, this message translates to:
  /// **'1 portion'**
  String get unePortion;

  /// No description provided for @valeurNutritive.
  ///
  /// In fr, this message translates to:
  /// **'Valeur nutritive'**
  String get valeurNutritive;

  /// No description provided for @valeurNutritiveAide.
  ///
  /// In fr, this message translates to:
  /// **'Pour UNE portion, comme sur l\'étiquette.'**
  String get valeurNutritiveAide;

  /// No description provided for @verresParJour.
  ///
  /// In fr, this message translates to:
  /// **'Verres par jour'**
  String get verresParJour;

  /// No description provided for @verresSur.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun verre} =1{1 verre} other{{n} verres}} sur {m}'**
  String verresSur(int n, int m);

  /// No description provided for @kcalDePlus.
  ///
  /// In fr, this message translates to:
  /// **'{n} kcal de plus'**
  String kcalDePlus(String n);

  /// No description provided for @aConsommerAvant.
  ///
  /// In fr, this message translates to:
  /// **'À consommer avant'**
  String get aConsommerAvant;

  /// No description provided for @aConsommerBientot.
  ///
  /// In fr, this message translates to:
  /// **'À consommer bientôt'**
  String get aConsommerBientot;

  /// No description provided for @aConsommerBientotNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{rien à consommer bientôt} =1{1 à consommer bientôt} other{{n} à consommer bientôt}}'**
  String aConsommerBientotNombre(int n);

  /// No description provided for @aConsommerDici.
  ///
  /// In fr, this message translates to:
  /// **'À consommer {quand}'**
  String aConsommerDici(String quand);

  /// No description provided for @aTemperatureAmbiante.
  ///
  /// In fr, this message translates to:
  /// **'À l\'armoire ou sur le comptoir'**
  String get aTemperatureAmbiante;

  /// No description provided for @ajouterAuGardeManger.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter au garde-manger'**
  String get ajouterAuGardeManger;

  /// No description provided for @ajouterMagasin.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un magasin'**
  String get ajouterMagasin;

  /// No description provided for @alimentRange.
  ///
  /// In fr, this message translates to:
  /// **'Rangé : {nom}'**
  String alimentRange(String nom);

  /// No description provided for @alimentsNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun aliment} =1{1 aliment} other{{n} aliments}}'**
  String alimentsNombre(int n);

  /// No description provided for @alimentsRanges.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Rien de rangé} =1{1 aliment rangé} other{{n} aliments rangés}}'**
  String alimentsRanges(int n);

  /// No description provided for @articleAjoute.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté : {texte}'**
  String articleAjoute(String texte);

  /// No description provided for @articleFusionne.
  ///
  /// In fr, this message translates to:
  /// **'Déjà sur la liste, quantités additionnées : {texte}'**
  String articleFusionne(String texte);

  /// No description provided for @articlesEstimation.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun article} =1{1 article · env. {prix} à la caisse} other{{n} articles · env. {prix} à la caisse}}'**
  String articlesEstimation(int n, String prix);

  /// No description provided for @articlesNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun article} =1{1 article} other{{n} articles}}'**
  String articlesNombre(int n);

  /// No description provided for @auMagasin.
  ///
  /// In fr, this message translates to:
  /// **'Au magasin'**
  String get auMagasin;

  /// No description provided for @auPanierPrix.
  ///
  /// In fr, this message translates to:
  /// **'au panier : {prix}'**
  String auPanierPrix(String prix);

  /// No description provided for @auPoids.
  ///
  /// In fr, this message translates to:
  /// **'Au poids'**
  String get auPoids;

  /// No description provided for @auPoidsDetail.
  ///
  /// In fr, this message translates to:
  /// **'Fruits, légumes, viandes pesés à la caisse'**
  String get auPoidsDetail;

  /// No description provided for @aucune.
  ///
  /// In fr, this message translates to:
  /// **'Aucune'**
  String get aucune;

  /// No description provided for @aucuneEpicerie.
  ///
  /// In fr, this message translates to:
  /// **'Aucune épicerie encore'**
  String get aucuneEpicerie;

  /// No description provided for @aucuneEpicerieAide.
  ///
  /// In fr, this message translates to:
  /// **'Tes épiceries apparaîtront ici, avec les prix payés : terminer les courses au magasin les enregistre.'**
  String get aucuneEpicerieAide;

  /// No description provided for @budgetDepasse.
  ///
  /// In fr, this message translates to:
  /// **'Budget du mois dépassé de {prix}'**
  String budgetDepasse(String prix);

  /// No description provided for @budgetDuMois.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois-ci : {depense} sur {budget}'**
  String budgetDuMois(String depense, String budget);

  /// No description provided for @budgetEpicerie.
  ///
  /// In fr, this message translates to:
  /// **'Budget d\'épicerie'**
  String get budgetEpicerie;

  /// No description provided for @budgetEpicerieDetail.
  ///
  /// In fr, this message translates to:
  /// **'Au magasin, ce qu\'il en reste ce mois-ci.'**
  String get budgetEpicerieDetail;

  /// No description provided for @budgetRestant.
  ///
  /// In fr, this message translates to:
  /// **'Reste du budget du mois : {prix}'**
  String budgetRestant(String prix);

  /// No description provided for @canalGardeMangerDescription.
  ///
  /// In fr, this message translates to:
  /// **'Les aliments à consommer d\'ici le lendemain.'**
  String get canalGardeMangerDescription;

  /// No description provided for @canalGardeMangerNom.
  ///
  /// In fr, this message translates to:
  /// **'Garde-manger'**
  String get canalGardeMangerNom;

  /// No description provided for @cestFini.
  ///
  /// In fr, this message translates to:
  /// **'C\'est fini'**
  String get cestFini;

  /// No description provided for @changement15Juillet.
  ///
  /// In fr, this message translates to:
  /// **'Depuis le 15 juillet 2026'**
  String get changement15Juillet;

  /// No description provided for @changement15JuilletTexte.
  ///
  /// In fr, this message translates to:
  /// **'Plus de TVQ (la TPS reste) sur : les barres et mélanges granola, les noix et graines salées, les pâtisseries à l\'unité (moins de 230 g ou paquet de moins de 6), les desserts glacés de moins de 500 g, les coupes de dessert de moins de 425 g, les plateaux de fruits ou de légumes coupés, le papier hygiénique et les mouchoirs. Au restaurant et dans les machines distributrices, rien ne change.'**
  String get changement15JuilletTexte;

  /// No description provided for @combien.
  ///
  /// In fr, this message translates to:
  /// **'Combien'**
  String get combien;

  /// No description provided for @commentLeGarder.
  ///
  /// In fr, this message translates to:
  /// **'Comment le garder'**
  String get commentLeGarder;

  /// No description provided for @conseilPeremption.
  ///
  /// In fr, this message translates to:
  /// **'À consommer d\'ici demain : {noms}. À cuisiner en premier.'**
  String conseilPeremption(String noms);

  /// No description provided for @consigne.
  ///
  /// In fr, this message translates to:
  /// **'Consigne'**
  String get consigne;

  /// No description provided for @consigneAide.
  ///
  /// In fr, this message translates to:
  /// **'Canettes et bouteilles de boisson : 10 ¢ ; le verre de 500 ml et plus : 25 ¢. Remboursée au retour, jamais taxée.'**
  String get consigneAide;

  /// No description provided for @consigneTexte.
  ///
  /// In fr, this message translates to:
  /// **'Presque tous les contenants de boisson de 100 ml à 2 L sont consignés : 10 ¢ chacun, 25 ¢ pour le verre de 500 ml et plus. Elle s\'ajoute au total, sans taxe, et se récupère en rapportant les contenants.'**
  String get consigneTexte;

  /// No description provided for @consigneValeur.
  ///
  /// In fr, this message translates to:
  /// **'consigne {prix}'**
  String consigneValeur(String prix);

  /// No description provided for @dansLePanier.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Panier vide} =1{Dans le panier · 1} other{Dans le panier · {n}}}'**
  String dansLePanier(int n);

  /// No description provided for @datePassee.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Date passée} =1{Date passée d\'un jour} other{Date passée depuis {n} jours}}'**
  String datePassee(int n);

  /// No description provided for @dejaAuGardeManger.
  ///
  /// In fr, this message translates to:
  /// **'Au garde-manger : {texte}'**
  String dejaAuGardeManger(String texte);

  /// No description provided for @depenseCeMois.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois-ci : {prix}'**
  String depenseCeMois(String prix);

  /// No description provided for @deplaceJusquau.
  ///
  /// In fr, this message translates to:
  /// **'{ou} : jusqu\'au {date}'**
  String deplaceJusquau(String ou, String date);

  /// No description provided for @dernierPrixVu.
  ///
  /// In fr, this message translates to:
  /// **'Dernier prix : {prix} chez {magasin} ({date})'**
  String dernierPrixVu(String prix, String magasin, String date);

  /// No description provided for @dureeA.
  ///
  /// In fr, this message translates to:
  /// **'{ou} : {duree}'**
  String dureeA(String ou, String duree);

  /// No description provided for @echeanceAujourdhui.
  ///
  /// In fr, this message translates to:
  /// **'aujourd\'hui'**
  String get echeanceAujourdhui;

  /// No description provided for @echeanceDans.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{aujourd\'hui} =1{demain} other{dans {n} jours}}'**
  String echeanceDans(int n);

  /// No description provided for @echeanceDemain.
  ///
  /// In fr, this message translates to:
  /// **'demain'**
  String get echeanceDemain;

  /// No description provided for @echeanceHier.
  ///
  /// In fr, this message translates to:
  /// **'hier'**
  String get echeanceHier;

  /// No description provided for @echeancePassee.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{aujourd\'hui} =1{hier} other{passée de {n} jours}}'**
  String echeancePassee(int n);

  /// No description provided for @emplacementArmoire.
  ///
  /// In fr, this message translates to:
  /// **'Armoire'**
  String get emplacementArmoire;

  /// No description provided for @emplacementComptoir.
  ///
  /// In fr, this message translates to:
  /// **'Comptoir'**
  String get emplacementComptoir;

  /// No description provided for @emplacementCongelateur.
  ///
  /// In fr, this message translates to:
  /// **'Congélateur'**
  String get emplacementCongelateur;

  /// No description provided for @emplacementFrigo.
  ///
  /// In fr, this message translates to:
  /// **'Frigo'**
  String get emplacementFrigo;

  /// No description provided for @environPrix.
  ///
  /// In fr, this message translates to:
  /// **'env. {prix}'**
  String environPrix(String prix);

  /// No description provided for @environPrixKg.
  ///
  /// In fr, this message translates to:
  /// **'env. {prix} / kg'**
  String environPrixKg(String prix);

  /// No description provided for @epicerie.
  ///
  /// In fr, this message translates to:
  /// **'Épicerie'**
  String get epicerie;

  /// No description provided for @epicerieDetail.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun article} =1{1 article · taxes {taxes}} other{{n} articles · taxes {taxes}}}'**
  String epicerieDetail(int n, String taxes);

  /// No description provided for @essentiel.
  ///
  /// In fr, this message translates to:
  /// **'Essentiel'**
  String get essentiel;

  /// No description provided for @essentielCourt.
  ///
  /// In fr, this message translates to:
  /// **'essentiel'**
  String get essentielCourt;

  /// No description provided for @essentielDetail.
  ///
  /// In fr, this message translates to:
  /// **'Fini, il revient seul sur la liste de courses.'**
  String get essentielDetail;

  /// No description provided for @exemplesDetaxe.
  ///
  /// In fr, this message translates to:
  /// **'Les aliments de base : fruits et légumes, viandes et poissons, lait, yogourt, fromage, œufs, pain, céréales, pâtes, riz, conserves, farine, café, jus 100 %, biscuits en boîte, desserts en grand format.'**
  String get exemplesDetaxe;

  /// No description provided for @exemplesTps.
  ///
  /// In fr, this message translates to:
  /// **'Barres et mélanges granola, noix et graines salées, muffins ou beignes à l\'unité, desserts glacés en portion, coupes de pouding, plateaux de fruits ou de légumes coupés, papier hygiénique, mouchoirs.'**
  String get exemplesTps;

  /// No description provided for @exemplesTpsTvq.
  ///
  /// In fr, this message translates to:
  /// **'Boissons gazeuses et boissons aux fruits, bonbons, chocolat, croustilles et grignotines, alcool, produits d\'entretien, d\'hygiène et de beauté, la plupart des médicaments sans ordonnance, nourriture pour animaux.'**
  String get exemplesTpsTvq;

  /// No description provided for @finiNote.
  ///
  /// In fr, this message translates to:
  /// **'Fini : {nom}.'**
  String finiNote(String nom);

  /// No description provided for @finiReassort.
  ///
  /// In fr, this message translates to:
  /// **'Fini : {nom}, remis sur la liste de courses.'**
  String finiReassort(String nom);

  /// No description provided for @gardeManger.
  ///
  /// In fr, this message translates to:
  /// **'Garde-manger'**
  String get gardeManger;

  /// No description provided for @gardeMangerAide.
  ///
  /// In fr, this message translates to:
  /// **'Touche un aliment : où le garder, combien de temps, ce qu\'il en reste.'**
  String get gardeMangerAide;

  /// No description provided for @gardeMangerVide.
  ///
  /// In fr, this message translates to:
  /// **'Rien au garde-manger. Termine une épicerie pour ranger tes achats, ou ajoute un aliment.'**
  String get gardeMangerVide;

  /// No description provided for @gardeMangerVideCourt.
  ///
  /// In fr, this message translates to:
  /// **'Tes aliments rangés, et leurs dates'**
  String get gardeMangerVideCourt;

  /// No description provided for @historiqueEpiceries.
  ///
  /// In fr, this message translates to:
  /// **'Historique des épiceries'**
  String get historiqueEpiceries;

  /// No description provided for @ilEnReste.
  ///
  /// In fr, this message translates to:
  /// **'Il en reste'**
  String get ilEnReste;

  /// No description provided for @indiceAjoutListe.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter : 2 kg poulet, lait x2…'**
  String get indiceAjoutListe;

  /// No description provided for @indiceAlimentGardeManger.
  ///
  /// In fr, this message translates to:
  /// **'Yogourt, restes de chili…'**
  String get indiceAlimentGardeManger;

  /// No description provided for @indiceImprevu.
  ///
  /// In fr, this message translates to:
  /// **'Un imprévu ? Ajoute-le ici'**
  String get indiceImprevu;

  /// No description provided for @indiceNoteArticle.
  ///
  /// In fr, this message translates to:
  /// **'La marque, le format…'**
  String get indiceNoteArticle;

  /// No description provided for @intervalle.
  ///
  /// In fr, this message translates to:
  /// **'{a} à {b}'**
  String intervalle(String a, String b);

  /// No description provided for @jete.
  ///
  /// In fr, this message translates to:
  /// **'Jeté'**
  String get jete;

  /// No description provided for @jeteCeMois.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Rien jeté ce mois-ci} =1{Jeté ce mois-ci : {prix} (1 aliment)} other{Jeté ce mois-ci : {prix} ({n} aliments)}}'**
  String jeteCeMois(String prix, int n);

  /// No description provided for @jeteNote.
  ///
  /// In fr, this message translates to:
  /// **'Noté au compteur de gaspillage.'**
  String get jeteNote;

  /// No description provided for @jeteValeur.
  ///
  /// In fr, this message translates to:
  /// **'Noté : {prix} au compteur de gaspillage.'**
  String jeteValeur(String prix);

  /// No description provided for @ligneResume.
  ///
  /// In fr, this message translates to:
  /// **'Ligne : {prix} + taxes {taxes} + consigne {consigne}'**
  String ligneResume(String prix, String taxes, String consigne);

  /// No description provided for @listeDeCourses.
  ///
  /// In fr, this message translates to:
  /// **'Liste de courses'**
  String get listeDeCourses;

  /// No description provided for @listeVide.
  ///
  /// In fr, this message translates to:
  /// **'Ta liste est vide.'**
  String get listeVide;

  /// No description provided for @listeVideCourt.
  ///
  /// In fr, this message translates to:
  /// **'À remplir'**
  String get listeVideCourt;

  /// No description provided for @magasinInconnu.
  ///
  /// In fr, this message translates to:
  /// **'un magasin'**
  String get magasinInconnu;

  /// No description provided for @meilleurPrix.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur prix vu : {prix} chez {magasin}'**
  String meilleurPrix(String prix, String magasin);

  /// No description provided for @mesMagasins.
  ///
  /// In fr, this message translates to:
  /// **'Mes magasins'**
  String get mesMagasins;

  /// No description provided for @mettreAuPanier.
  ///
  /// In fr, this message translates to:
  /// **'Au panier'**
  String get mettreAuPanier;

  /// No description provided for @mettreAuPanierPrix.
  ///
  /// In fr, this message translates to:
  /// **'Au panier · {prix}'**
  String mettreAuPanierPrix(String prix);

  /// No description provided for @nePasRanger.
  ///
  /// In fr, this message translates to:
  /// **'Ne pas ranger'**
  String get nePasRanger;

  /// No description provided for @notifPeremptionCorps.
  ///
  /// In fr, this message translates to:
  /// **'{noms} : à consommer d\'ici demain.'**
  String notifPeremptionCorps(String noms);

  /// No description provided for @notifPeremptionCorpsPlus.
  ///
  /// In fr, this message translates to:
  /// **'{noms} et {n, plural, =1{1 autre} other{{n} autres}} : à consommer d\'ici demain.'**
  String notifPeremptionCorpsPlus(String noms, int n);

  /// No description provided for @notifPeremptionTitre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Garde-manger} =1{1 aliment à consommer} other{{n} aliments à consommer}}'**
  String notifPeremptionTitre(int n);

  /// No description provided for @nouvelleQuantite.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle quantité'**
  String get nouvelleQuantite;

  /// No description provided for @ordreDesRayons.
  ///
  /// In fr, this message translates to:
  /// **'Ordre des rayons'**
  String get ordreDesRayons;

  /// No description provided for @ordreDesRayonsAide.
  ///
  /// In fr, this message translates to:
  /// **'Celui de ton magasin : maintiens une ligne pour la déplacer. La liste et le magasin suivent cet ordre.'**
  String get ordreDesRayonsAide;

  /// No description provided for @ou.
  ///
  /// In fr, this message translates to:
  /// **'Où'**
  String get ou;

  /// No description provided for @ouvert.
  ///
  /// In fr, this message translates to:
  /// **'ouvert'**
  String get ouvert;

  /// No description provided for @ouvertAujourdhui.
  ///
  /// In fr, this message translates to:
  /// **'Ouvert aujourd\'hui'**
  String get ouvertAujourdhui;

  /// No description provided for @ouvertDetail.
  ///
  /// In fr, this message translates to:
  /// **'Une fois ouvert : {duree}'**
  String ouvertDetail(String duree);

  /// No description provided for @ouvertLe.
  ///
  /// In fr, this message translates to:
  /// **'ouvert le {date}'**
  String ouvertLe(String date);

  /// No description provided for @panierVide.
  ///
  /// In fr, this message translates to:
  /// **'Le panier est vide.'**
  String get panierVide;

  /// No description provided for @paquets.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{{v} paquet} =1{{v} paquet} other{{v} paquets}}'**
  String paquets(int n, String v);

  /// No description provided for @parDate.
  ///
  /// In fr, this message translates to:
  /// **'Par date'**
  String get parDate;

  /// No description provided for @parKg.
  ///
  /// In fr, this message translates to:
  /// **'Au kg'**
  String get parKg;

  /// No description provided for @parLivre.
  ///
  /// In fr, this message translates to:
  /// **'À la livre'**
  String get parLivre;

  /// No description provided for @parMois.
  ///
  /// In fr, this message translates to:
  /// **'Par mois'**
  String get parMois;

  /// No description provided for @parRayon.
  ///
  /// In fr, this message translates to:
  /// **'Par rayon'**
  String get parRayon;

  /// No description provided for @pasAuGardeManger.
  ///
  /// In fr, this message translates to:
  /// **'Pas au garde-manger : {noms}.'**
  String pasAuGardeManger(String noms);

  /// No description provided for @pasDeRepere.
  ///
  /// In fr, this message translates to:
  /// **'Pas de repère : ajuste la date toi-même.'**
  String get pasDeRepere;

  /// No description provided for @poidsAPrix.
  ///
  /// In fr, this message translates to:
  /// **'{poids} à {prix}'**
  String poidsAPrix(String poids, String prix);

  /// No description provided for @pourOrigines.
  ///
  /// In fr, this message translates to:
  /// **'pour : {noms}'**
  String pourOrigines(String noms);

  /// No description provided for @prixAuKg.
  ///
  /// In fr, this message translates to:
  /// **'{prix} / kg'**
  String prixAuKg(String prix);

  /// No description provided for @prixConnusPour.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun prix connu} =1{Prix connu pour 1 article} other{Prix connus pour {n} articles}}'**
  String prixConnusPour(int n);

  /// No description provided for @prixEtPoidsRequis.
  ///
  /// In fr, this message translates to:
  /// **'Entre le prix et le poids.'**
  String get prixEtPoidsRequis;

  /// No description provided for @prixParUnite.
  ///
  /// In fr, this message translates to:
  /// **'Prix / {unite}'**
  String prixParUnite(String unite);

  /// No description provided for @prixPaye.
  ///
  /// In fr, this message translates to:
  /// **'Prix payé'**
  String get prixPaye;

  /// No description provided for @prixPayeFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Prix payé (facultatif)'**
  String get prixPayeFacultatif;

  /// No description provided for @prixRequis.
  ///
  /// In fr, this message translates to:
  /// **'Entre le prix.'**
  String get prixRequis;

  /// No description provided for @prixUnitaire.
  ///
  /// In fr, this message translates to:
  /// **'Prix à l\'unité'**
  String get prixUnitaire;

  /// No description provided for @prixVus.
  ///
  /// In fr, this message translates to:
  /// **'Prix vus'**
  String get prixVus;

  /// No description provided for @quantiteFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Quantité (facultatif)'**
  String get quantiteFacultatif;

  /// No description provided for @quantiteMiseAJour.
  ///
  /// In fr, this message translates to:
  /// **'Quantité mise à jour.'**
  String get quantiteMiseAJour;

  /// No description provided for @quantitesFusionnees.
  ///
  /// In fr, this message translates to:
  /// **'Fusionnées : {texte}. Une nouvelle quantité les remplace.'**
  String quantitesFusionnees(String texte);

  /// No description provided for @raisonAlUnite.
  ///
  /// In fr, this message translates to:
  /// **'À l\'unité (moins de 6) : TPS seulement depuis le 15 juillet 2026. Par 6 et plus : détaxé.'**
  String get raisonAlUnite;

  /// No description provided for @raisonAlcool.
  ///
  /// In fr, this message translates to:
  /// **'Alcool : TPS et TVQ.'**
  String get raisonAlcool;

  /// No description provided for @raisonBase.
  ///
  /// In fr, this message translates to:
  /// **'Un aliment de base : détaxé.'**
  String get raisonBase;

  /// No description provided for @raisonGrignotines.
  ///
  /// In fr, this message translates to:
  /// **'Grignotines, bonbons, chocolat, boissons gazeuses : TPS et TVQ.'**
  String get raisonGrignotines;

  /// No description provided for @raisonHygieneDetaxee.
  ///
  /// In fr, this message translates to:
  /// **'Protections menstruelles : détaxées.'**
  String get raisonHygieneDetaxee;

  /// No description provided for @raisonNonAlimentaire.
  ///
  /// In fr, this message translates to:
  /// **'Pas un aliment : TPS et TVQ.'**
  String get raisonNonAlimentaire;

  /// No description provided for @raisonTvqAbolie.
  ///
  /// In fr, this message translates to:
  /// **'Plus de TVQ depuis le 15 juillet 2026 : TPS seulement.'**
  String get raisonTvqAbolie;

  /// No description provided for @ranger.
  ///
  /// In fr, this message translates to:
  /// **'Ranger'**
  String get ranger;

  /// No description provided for @rangerExplication.
  ///
  /// In fr, this message translates to:
  /// **'Où ranger chaque aliment, jusqu\'à quand, et comment le garder longtemps (d\'après le Thermoguide du MAPAQ). Ajuste la date selon l\'emballage.'**
  String get rangerExplication;

  /// No description provided for @rangerPlusTard.
  ///
  /// In fr, this message translates to:
  /// **'Revenir en arrière laisse tes achats hors du garde-manger.'**
  String get rangerPlusTard;

  /// No description provided for @rappelsPeremption.
  ///
  /// In fr, this message translates to:
  /// **'Rappels de péremption'**
  String get rappelsPeremption;

  /// No description provided for @rappelsPeremptionDetail.
  ///
  /// In fr, this message translates to:
  /// **'Le matin, ce qui est à consommer d\'ici le lendemain.'**
  String get rappelsPeremptionDetail;

  /// No description provided for @rayon.
  ///
  /// In fr, this message translates to:
  /// **'Rayon'**
  String get rayon;

  /// No description provided for @rayonAutre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get rayonAutre;

  /// No description provided for @rayonBoissons.
  ///
  /// In fr, this message translates to:
  /// **'Boissons'**
  String get rayonBoissons;

  /// No description provided for @rayonBoulangerie.
  ///
  /// In fr, this message translates to:
  /// **'Boulangerie'**
  String get rayonBoulangerie;

  /// No description provided for @rayonCereales.
  ///
  /// In fr, this message translates to:
  /// **'Céréales, pâtes et riz'**
  String get rayonCereales;

  /// No description provided for @rayonCollations.
  ///
  /// In fr, this message translates to:
  /// **'Collations et sucreries'**
  String get rayonCollations;

  /// No description provided for @rayonCondiments.
  ///
  /// In fr, this message translates to:
  /// **'Condiments, sauces et huiles'**
  String get rayonCondiments;

  /// No description provided for @rayonConserves.
  ///
  /// In fr, this message translates to:
  /// **'Conserves et soupes'**
  String get rayonConserves;

  /// No description provided for @rayonEntretien.
  ///
  /// In fr, this message translates to:
  /// **'Entretien'**
  String get rayonEntretien;

  /// No description provided for @rayonEpices.
  ///
  /// In fr, this message translates to:
  /// **'Épices et pâtisserie'**
  String get rayonEpices;

  /// No description provided for @rayonFruits.
  ///
  /// In fr, this message translates to:
  /// **'Fruits'**
  String get rayonFruits;

  /// No description provided for @rayonHygiene.
  ///
  /// In fr, this message translates to:
  /// **'Hygiène et pharmacie'**
  String get rayonHygiene;

  /// No description provided for @rayonLaitiers.
  ///
  /// In fr, this message translates to:
  /// **'Produits laitiers et œufs'**
  String get rayonLaitiers;

  /// No description provided for @rayonLegumes.
  ///
  /// In fr, this message translates to:
  /// **'Légumes et fines herbes'**
  String get rayonLegumes;

  /// No description provided for @rayonLegumineuses.
  ///
  /// In fr, this message translates to:
  /// **'Légumineuses, tofu et noix'**
  String get rayonLegumineuses;

  /// No description provided for @rayonPoissons.
  ///
  /// In fr, this message translates to:
  /// **'Poissons et fruits de mer'**
  String get rayonPoissons;

  /// No description provided for @rayonSurgeles.
  ///
  /// In fr, this message translates to:
  /// **'Surgelés'**
  String get rayonSurgeles;

  /// No description provided for @rayonViandes.
  ///
  /// In fr, this message translates to:
  /// **'Viandes'**
  String get rayonViandes;

  /// No description provided for @rayonsMagasinsBudget.
  ///
  /// In fr, this message translates to:
  /// **'Rayons, magasins et budget'**
  String get rayonsMagasinsBudget;

  /// No description provided for @resteAPrendre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Tout est pris} =1{Encore 1 article} other{Encore {n} articles}}'**
  String resteAPrendre(int n);

  /// No description provided for @retirerDeLaListe.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la liste'**
  String get retirerDeLaListe;

  /// No description provided for @retirerDuPanier.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du panier'**
  String get retirerDuPanier;

  /// No description provided for @retirerErreur.
  ///
  /// In fr, this message translates to:
  /// **'Retirer (une erreur)'**
  String get retirerErreur;

  /// No description provided for @retirerMagasin.
  ///
  /// In fr, this message translates to:
  /// **'Retirer {magasin}'**
  String retirerMagasin(String magasin);

  /// No description provided for @rienIci.
  ///
  /// In fr, this message translates to:
  /// **'Rien ici.'**
  String get rienIci;

  /// No description provided for @sansDate.
  ///
  /// In fr, this message translates to:
  /// **'Sans date'**
  String get sansDate;

  /// No description provided for @seGarde.
  ///
  /// In fr, this message translates to:
  /// **'Se garde : {duree}'**
  String seGarde(String duree);

  /// No description provided for @sourcesTaxes.
  ///
  /// In fr, this message translates to:
  /// **'Sources : Revenu Québec (produits alimentaires de base), mesure du 15 juillet 2026, RECYC-QUÉBEC (consigne). Une indication : le reçu fait foi.'**
  String get sourcesTaxes;

  /// No description provided for @sousTotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get sousTotal;

  /// No description provided for @sousTotalValeur.
  ///
  /// In fr, this message translates to:
  /// **'sous-total {prix}'**
  String sousTotalValeur(String prix);

  /// No description provided for @supprimerEpicerie.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette épicerie'**
  String get supprimerEpicerie;

  /// No description provided for @surBudget.
  ///
  /// In fr, this message translates to:
  /// **'{depense} / {budget}'**
  String surBudget(String depense, String budget);

  /// No description provided for @surLaListe.
  ///
  /// In fr, this message translates to:
  /// **'Sur la liste : {quantite}'**
  String surLaListe(String quantite);

  /// No description provided for @surLaListeAction.
  ///
  /// In fr, this message translates to:
  /// **'Remettre sur la liste'**
  String get surLaListeAction;

  /// No description provided for @surLaListeDetail.
  ///
  /// In fr, this message translates to:
  /// **'Pour le racheter'**
  String get surLaListeDetail;

  /// No description provided for @tauxEnVigueur.
  ///
  /// In fr, this message translates to:
  /// **'TPS {tps} + TVQ {tvq} = {total}'**
  String tauxEnVigueur(String tps, String tvq, String total);

  /// No description provided for @tauxExplication.
  ///
  /// In fr, this message translates to:
  /// **'Chacune se calcule sur le prix avant taxes de ce qui y est soumis, arrondie au cent. Si un taux change, Rhythm l\'applique à sa date.'**
  String get tauxExplication;

  /// No description provided for @taxe.
  ///
  /// In fr, this message translates to:
  /// **'Taxe'**
  String get taxe;

  /// No description provided for @taxeChoisie.
  ///
  /// In fr, this message translates to:
  /// **'Choisi à la main.'**
  String get taxeChoisie;

  /// No description provided for @taxeDetaxe.
  ///
  /// In fr, this message translates to:
  /// **'Détaxé'**
  String get taxeDetaxe;

  /// No description provided for @taxeTps.
  ///
  /// In fr, this message translates to:
  /// **'TPS seulement'**
  String get taxeTps;

  /// No description provided for @taxeTpsTvq.
  ///
  /// In fr, this message translates to:
  /// **'TPS + TVQ'**
  String get taxeTpsTvq;

  /// No description provided for @taxesDuQuebec.
  ///
  /// In fr, this message translates to:
  /// **'Les taxes du Québec'**
  String get taxesDuQuebec;

  /// No description provided for @taxesDuQuebecDetail.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui est taxé, et depuis quand'**
  String get taxesDuQuebecDetail;

  /// No description provided for @tesHabituels.
  ///
  /// In fr, this message translates to:
  /// **'Tes habituels'**
  String get tesHabituels;

  /// No description provided for @totalCaisse.
  ///
  /// In fr, this message translates to:
  /// **'Total à la caisse'**
  String get totalCaisse;

  /// No description provided for @totalPaye.
  ///
  /// In fr, this message translates to:
  /// **'{prix} payés'**
  String totalPaye(String prix);

  /// No description provided for @toucherPourJeter.
  ///
  /// In fr, this message translates to:
  /// **'Toucher encore : jeté'**
  String get toucherPourJeter;

  /// No description provided for @toucherPourTerminer.
  ///
  /// In fr, this message translates to:
  /// **'Toucher encore'**
  String get toucherPourTerminer;

  /// No description provided for @toucherPourVider.
  ///
  /// In fr, this message translates to:
  /// **'Toucher encore pour vider'**
  String get toucherPourVider;

  /// No description provided for @tout.
  ///
  /// In fr, this message translates to:
  /// **'Tout'**
  String get tout;

  /// No description provided for @toutEstPris.
  ///
  /// In fr, this message translates to:
  /// **'Tout est pris'**
  String get toutEstPris;

  /// No description provided for @toutRanger.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Rien à ranger} =1{Ranger 1 aliment} other{Ranger {n} aliments}}'**
  String toutRanger(int n);

  /// No description provided for @tpsValeur.
  ///
  /// In fr, this message translates to:
  /// **'TPS {prix}'**
  String tpsValeur(String prix);

  /// No description provided for @tvqValeur.
  ///
  /// In fr, this message translates to:
  /// **'TVQ {prix}'**
  String tvqValeur(String prix);

  /// No description provided for @tuDecides.
  ///
  /// In fr, this message translates to:
  /// **'Tu décides'**
  String get tuDecides;

  /// No description provided for @tuDecidesTexte.
  ///
  /// In fr, this message translates to:
  /// **'Rhythm propose un statut d\'après le nom et le rayon, et dit pourquoi ; c\'est toi qui l\'appliques, d\'un toucher. En cas de doute, le reçu fait foi.'**
  String get tuDecidesTexte;

  /// No description provided for @uneFoisOuvert.
  ///
  /// In fr, this message translates to:
  /// **'Une fois ouvert'**
  String get uneFoisOuvert;

  /// No description provided for @unitePaquet.
  ///
  /// In fr, this message translates to:
  /// **'paquet'**
  String get unitePaquet;

  /// No description provided for @uniteUnite.
  ///
  /// In fr, this message translates to:
  /// **'unité'**
  String get uniteUnite;

  /// No description provided for @viderLaListe.
  ///
  /// In fr, this message translates to:
  /// **'Vider la liste'**
  String get viderLaListe;

  /// No description provided for @ligneResumeSansConsigne.
  ///
  /// In fr, this message translates to:
  /// **'Ligne : {prix} + taxes {taxes}'**
  String ligneResumeSansConsigne(String prix, String taxes);

  /// No description provided for @revenuSeul.
  ///
  /// In fr, this message translates to:
  /// **'revenu seul (essentiel fini)'**
  String get revenuSeul;

  /// No description provided for @triRecentes.
  ///
  /// In fr, this message translates to:
  /// **'Récentes'**
  String get triRecentes;

  /// No description provided for @triAlphabetique.
  ///
  /// In fr, this message translates to:
  /// **'A à Z'**
  String get triAlphabetique;

  /// No description provided for @triProteines.
  ///
  /// In fr, this message translates to:
  /// **'Protéines'**
  String get triProteines;

  /// No description provided for @triCalories.
  ///
  /// In fr, this message translates to:
  /// **'Calories'**
  String get triCalories;

  /// No description provided for @triRapides.
  ///
  /// In fr, this message translates to:
  /// **'Rapides'**
  String get triRapides;

  /// No description provided for @portionUne.
  ///
  /// In fr, this message translates to:
  /// **'{nombre} portion'**
  String portionUne(String nombre);

  /// No description provided for @portionsPlusieurs.
  ///
  /// In fr, this message translates to:
  /// **'{nombre} portions'**
  String portionsPlusieurs(String nombre);

  /// No description provided for @conseilDecongeler.
  ///
  /// In fr, this message translates to:
  /// **'Ce soir, du congélateur au frigo : {noms} (pour demain).'**
  String conseilDecongeler(String noms);

  /// No description provided for @canalDecongelationNom.
  ///
  /// In fr, this message translates to:
  /// **'Décongélation'**
  String get canalDecongelationNom;

  /// No description provided for @canalDecongelationDescription.
  ///
  /// In fr, this message translates to:
  /// **'La veille d\'un repas prévu, ce qu\'il faut sortir du congélateur'**
  String get canalDecongelationDescription;

  /// No description provided for @notifDecongelationTitre.
  ///
  /// In fr, this message translates to:
  /// **'À sortir du congélateur'**
  String get notifDecongelationTitre;

  /// No description provided for @notifDecongelationCorps.
  ///
  /// In fr, this message translates to:
  /// **'Au frigo ce soir, pour demain : {articles}.'**
  String notifDecongelationCorps(String articles);

  /// No description provided for @notifDecongelationPour.
  ///
  /// In fr, this message translates to:
  /// **'Pour : {plats}.'**
  String notifDecongelationPour(String plats);

  /// No description provided for @canalMinuteursNom.
  ///
  /// In fr, this message translates to:
  /// **'Minuteurs de cuisine'**
  String get canalMinuteursNom;

  /// No description provided for @canalMinuteursDescription.
  ///
  /// In fr, this message translates to:
  /// **'La fin d\'un minuteur lancé en cuisinant'**
  String get canalMinuteursDescription;

  /// No description provided for @notifMinuteurTitre.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur : c\'est l\'heure'**
  String get notifMinuteurTitre;

  /// No description provided for @proteinesDe.
  ///
  /// In fr, this message translates to:
  /// **'{g} de protéines'**
  String proteinesDe(String g);

  /// No description provided for @cestLHeure.
  ///
  /// In fr, this message translates to:
  /// **'C\'est l\'heure'**
  String get cestLHeure;

  /// No description provided for @plusUneMinute.
  ///
  /// In fr, this message translates to:
  /// **'+1 min'**
  String get plusUneMinute;

  /// No description provided for @arreterMinuteur.
  ///
  /// In fr, this message translates to:
  /// **'Arrêter le minuteur'**
  String get arreterMinuteur;

  /// No description provided for @recettesAjoutees.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Tes recettes y sont déjà} =1{1 recette ajoutée} other{{n} recettes ajoutées}}'**
  String recettesAjoutees(int n);

  /// No description provided for @mesRecettes.
  ///
  /// In fr, this message translates to:
  /// **'Mes recettes'**
  String get mesRecettes;

  /// No description provided for @mesRecettesAide.
  ///
  /// In fr, this message translates to:
  /// **'Écris les tiennes, ou pars de huit recettes'**
  String get mesRecettesAide;

  /// No description provided for @recettesNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucune recette} =1{1 recette} other{{n} recettes}}'**
  String recettesNombre(int n);

  /// No description provided for @nouvelleRecette.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle recette'**
  String get nouvelleRecette;

  /// No description provided for @maSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Ma semaine'**
  String get maSemaine;

  /// No description provided for @livreVide.
  ///
  /// In fr, this message translates to:
  /// **'Ton livre de recettes est vide. Écris une recette — ses macros se calculent seules, d\'après la base — ou pars de huit recettes simples.'**
  String get livreVide;

  /// No description provided for @recettesDeDepart.
  ///
  /// In fr, this message translates to:
  /// **'Recettes de départ'**
  String get recettesDeDepart;

  /// No description provided for @recettesDeDepartDetail.
  ///
  /// In fr, this message translates to:
  /// **'Huit plats simples, du déjeuner au souper, d\'ici et d\'ailleurs (valeurs du FCÉN)'**
  String get recettesDeDepartDetail;

  /// No description provided for @chercherRecette.
  ///
  /// In fr, this message translates to:
  /// **'Chercher une recette, un ingrédient'**
  String get chercherRecette;

  /// No description provided for @toutesLesRegions.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les régions'**
  String get toutesLesRegions;

  /// No description provided for @aucuneRecette.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette pour « {requete} ».'**
  String aucuneRecette(String requete);

  /// No description provided for @macrosCalculees.
  ///
  /// In fr, this message translates to:
  /// **'Macros calculées d\'après le Fichier canadien sur les éléments nutritifs (Santé Canada).'**
  String get macrosCalculees;

  /// No description provided for @modifierRecette.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la recette'**
  String get modifierRecette;

  /// No description provided for @parPortion.
  ///
  /// In fr, this message translates to:
  /// **'Par portion'**
  String get parPortion;

  /// No description provided for @preparationDe.
  ///
  /// In fr, this message translates to:
  /// **'préparation {duree}'**
  String preparationDe(String duree);

  /// No description provided for @cuissonDe.
  ///
  /// In fr, this message translates to:
  /// **'cuisson {duree}'**
  String cuissonDe(String duree);

  /// No description provided for @cuisiner.
  ///
  /// In fr, this message translates to:
  /// **'Cuisiner'**
  String get cuisiner;

  /// No description provided for @aLaListe.
  ///
  /// In fr, this message translates to:
  /// **'À la liste'**
  String get aLaListe;

  /// No description provided for @pourRecettePortions.
  ///
  /// In fr, this message translates to:
  /// **'{nom}, pour {portions}'**
  String pourRecettePortions(String nom, String portions);

  /// No description provided for @planifier.
  ///
  /// In fr, this message translates to:
  /// **'Planifier'**
  String get planifier;

  /// No description provided for @noterAuJournal.
  ///
  /// In fr, this message translates to:
  /// **'Noter au journal'**
  String get noterAuJournal;

  /// No description provided for @restesAuGardeManger.
  ///
  /// In fr, this message translates to:
  /// **'Restes : {portions} ({detail})'**
  String restesAuGardeManger(String portions, String detail);

  /// No description provided for @ingredients.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédients'**
  String get ingredients;

  /// No description provided for @aucunIngredient.
  ///
  /// In fr, this message translates to:
  /// **'Aucun ingrédient.'**
  String get aucunIngredient;

  /// No description provided for @dejaLa.
  ///
  /// In fr, this message translates to:
  /// **'déjà là'**
  String get dejaLa;

  /// No description provided for @sansValeurNutritive.
  ///
  /// In fr, this message translates to:
  /// **'Sans valeur nutritive comptée : {noms}.'**
  String sansValeurNutritive(String noms);

  /// No description provided for @jamaisCuisinee.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore cuisinée'**
  String get jamaisCuisinee;

  /// No description provided for @cuisineeFois.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Pas encore cuisinée} =1{Cuisinée 1 fois, le {date}} other{Cuisinée {n} fois, la dernière le {date}}}'**
  String cuisineeFois(int n, String date);

  /// No description provided for @seCongeleBien.
  ///
  /// In fr, this message translates to:
  /// **'Se congèle bien'**
  String get seCongeleBien;

  /// No description provided for @laRecette.
  ///
  /// In fr, this message translates to:
  /// **'La recette'**
  String get laRecette;

  /// No description provided for @recetteEnregistree.
  ///
  /// In fr, this message translates to:
  /// **'« {nom} » enregistrée'**
  String recetteEnregistree(String nom);

  /// No description provided for @nomDeLaRecette.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la recette'**
  String get nomDeLaRecette;

  /// No description provided for @indiceNomRecette.
  ///
  /// In fr, this message translates to:
  /// **'Chili sin carne, soupe aux pois…'**
  String get indiceNomRecette;

  /// No description provided for @moments.
  ///
  /// In fr, this message translates to:
  /// **'Moments'**
  String get moments;

  /// No description provided for @cequElleDonne.
  ///
  /// In fr, this message translates to:
  /// **'Ce qu\'elle donne'**
  String get cequElleDonne;

  /// No description provided for @preparation.
  ///
  /// In fr, this message translates to:
  /// **'Préparation'**
  String get preparation;

  /// No description provided for @cuisson.
  ///
  /// In fr, this message translates to:
  /// **'Cuisson'**
  String get cuisson;

  /// No description provided for @ingredientLibreCourt.
  ///
  /// In fr, this message translates to:
  /// **'libre'**
  String get ingredientLibreCourt;

  /// No description provided for @ajouterUnIngredient.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un ingrédient'**
  String get ajouterUnIngredient;

  /// No description provided for @etapesUneParLigne.
  ///
  /// In fr, this message translates to:
  /// **'Étapes — une par ligne'**
  String get etapesUneParLigne;

  /// No description provided for @indiceEtapes.
  ///
  /// In fr, this message translates to:
  /// **'Hacher l\'oignon.\nLe faire revenir 5 minutes…'**
  String get indiceEtapes;

  /// No description provided for @etapesNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucune étape} =1{1 étape} other{{n} étapes}}'**
  String etapesNombre(int n);

  /// No description provided for @etapesMinuteurs.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =1{1 étape · minuteurs : {minuteurs}} other{{n} étapes · minuteurs : {minuteurs}}}'**
  String etapesMinuteurs(int n, String minuteurs);

  /// No description provided for @regionFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Région (facultatif)'**
  String get regionFacultatif;

  /// No description provided for @indiceRegion.
  ///
  /// In fr, this message translates to:
  /// **'Québécoise, haïtienne, italienne…'**
  String get indiceRegion;

  /// No description provided for @noteFacultatif.
  ///
  /// In fr, this message translates to:
  /// **'Note (facultatif)'**
  String get noteFacultatif;

  /// No description provided for @indiceNoteRecette.
  ///
  /// In fr, this message translates to:
  /// **'Un truc, une variante, avec quoi la servir'**
  String get indiceNoteRecette;

  /// No description provided for @seCongeleDetail.
  ///
  /// In fr, this message translates to:
  /// **'La cuisine en lot la propose, et ses restes vont d\'emblée au congélateur.'**
  String get seCongeleDetail;

  /// No description provided for @pourToute.
  ///
  /// In fr, this message translates to:
  /// **'Toute la recette ({portions}) : {kcal}'**
  String pourToute(String portions, String kcal);

  /// No description provided for @supprimerRecette.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la recette'**
  String get supprimerRecette;

  /// No description provided for @modifierIngredient.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'ingrédient'**
  String get modifierIngredient;

  /// No description provided for @unIngredient.
  ///
  /// In fr, this message translates to:
  /// **'Un ingrédient'**
  String get unIngredient;

  /// No description provided for @chercherIngredient.
  ///
  /// In fr, this message translates to:
  /// **'Chercher un aliment'**
  String get chercherIngredient;

  /// No description provided for @ingredientAide.
  ///
  /// In fr, this message translates to:
  /// **'Cherche dans la base (5 894 aliments, hors ligne) ou dans tes produits : les macros suivent.'**
  String get ingredientAide;

  /// No description provided for @ingredientLibre.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédient libre'**
  String get ingredientLibre;

  /// No description provided for @ingredientLibreAide.
  ///
  /// In fr, this message translates to:
  /// **'Sans valeur nutritive : sel, poivre, épices, eau.'**
  String get ingredientLibreAide;

  /// No description provided for @ingredientLibreNomme.
  ///
  /// In fr, this message translates to:
  /// **'Ingrédient libre : « {texte} »'**
  String ingredientLibreNomme(String texte);

  /// No description provided for @nomSurLaRecette.
  ///
  /// In fr, this message translates to:
  /// **'Nom sur la recette'**
  String get nomSurLaRecette;

  /// No description provided for @indiceIngredientLibre.
  ///
  /// In fr, this message translates to:
  /// **'Sel et poivre'**
  String get indiceIngredientLibre;

  /// No description provided for @ingredientDeLaBase.
  ///
  /// In fr, this message translates to:
  /// **'Aliment de la base'**
  String get ingredientDeLaBase;

  /// No description provided for @ajouterALaRecette.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à la recette'**
  String get ajouterALaRecette;

  /// No description provided for @changerDAliment.
  ///
  /// In fr, this message translates to:
  /// **'Changer d\'aliment'**
  String get changerDAliment;

  /// No description provided for @retirerDeLaRecette.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de la recette'**
  String get retirerDeLaRecette;

  /// No description provided for @minuteurSonne.
  ///
  /// In fr, this message translates to:
  /// **'C\'est l\'heure ! {libelle}'**
  String minuteurSonne(String libelle);

  /// No description provided for @minuteurLibelle.
  ///
  /// In fr, this message translates to:
  /// **'{nom} · étape {n} · {duree}'**
  String minuteurLibelle(String nom, int n, String duree);

  /// No description provided for @minuteurLance.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur lancé : {duree}'**
  String minuteurLance(String duree);

  /// No description provided for @secondes.
  ///
  /// In fr, this message translates to:
  /// **'{n} s'**
  String secondes(int n);

  /// No description provided for @modeCuisine.
  ///
  /// In fr, this message translates to:
  /// **'Mode cuisine'**
  String get modeCuisine;

  /// No description provided for @pourCombien.
  ///
  /// In fr, this message translates to:
  /// **'Pour combien'**
  String get pourCombien;

  /// No description provided for @miseEnPlace.
  ///
  /// In fr, this message translates to:
  /// **'Mise en place · {fait} sur {total}'**
  String miseEnPlace(int fait, int total);

  /// No description provided for @sansEtapes.
  ///
  /// In fr, this message translates to:
  /// **'Pas d\'étapes écrites : cuisine à ta façon.'**
  String get sansEtapes;

  /// No description provided for @cestPret.
  ///
  /// In fr, this message translates to:
  /// **'C\'est prêt'**
  String get cestPret;

  /// No description provided for @etapeSur.
  ///
  /// In fr, this message translates to:
  /// **'Étape {n} sur {total}'**
  String etapeSur(int n, int total);

  /// No description provided for @lancerMinuteur.
  ///
  /// In fr, this message translates to:
  /// **'Minuteur {duree}'**
  String lancerMinuteur(String duree);

  /// No description provided for @precedente.
  ///
  /// In fr, this message translates to:
  /// **'Précédente'**
  String get precedente;

  /// No description provided for @suivante.
  ///
  /// In fr, this message translates to:
  /// **'Suivante'**
  String get suivante;

  /// No description provided for @toutesLesEtapes.
  ///
  /// In fr, this message translates to:
  /// **'Toutes les étapes'**
  String get toutesLesEtapes;

  /// No description provided for @nomRestes.
  ///
  /// In fr, this message translates to:
  /// **'{nom} (restes)'**
  String nomRestes(String nom);

  /// No description provided for @noteAuMoment.
  ///
  /// In fr, this message translates to:
  /// **'{moment, select, dejeuner{{portions} au déjeuner} diner{{portions} au dîner} collation{{portions} à la collation} souper{{portions} au souper} other{{portions} au journal}}'**
  String noteAuMoment(String portions, String moment);

  /// No description provided for @restesRanges.
  ///
  /// In fr, this message translates to:
  /// **'{portions} en restes · {ou}'**
  String restesRanges(String portions, String ou);

  /// No description provided for @bonAppetit.
  ///
  /// In fr, this message translates to:
  /// **'Bon appétit !'**
  String get bonAppetit;

  /// No description provided for @cuisinePortions.
  ///
  /// In fr, this message translates to:
  /// **'{nom} · {portions}'**
  String cuisinePortions(String nom, String portions);

  /// No description provided for @jEnMangeMaintenant.
  ///
  /// In fr, this message translates to:
  /// **'J\'en mange maintenant'**
  String get jEnMangeMaintenant;

  /// No description provided for @portionsMangees.
  ///
  /// In fr, this message translates to:
  /// **'Portions'**
  String get portionsMangees;

  /// No description provided for @kcalEtProteines.
  ///
  /// In fr, this message translates to:
  /// **'{kcal} · {g} de protéines'**
  String kcalEtProteines(String kcal, String g);

  /// No description provided for @lesRestes.
  ///
  /// In fr, this message translates to:
  /// **'Les restes · {portions}'**
  String lesRestes(String portions);

  /// No description provided for @auFrigo.
  ///
  /// In fr, this message translates to:
  /// **'Au frigo'**
  String get auFrigo;

  /// No description provided for @auCongelateur.
  ///
  /// In fr, this message translates to:
  /// **'Au congélateur'**
  String get auCongelateur;

  /// No description provided for @pasDeRestes.
  ///
  /// In fr, this message translates to:
  /// **'Pas de restes'**
  String get pasDeRestes;

  /// No description provided for @restesJusquau.
  ///
  /// In fr, this message translates to:
  /// **'Jusqu\'au {date}'**
  String restesJusquau(String date);

  /// No description provided for @restesConseil.
  ///
  /// In fr, this message translates to:
  /// **'Au frigo dans les 2 heures, en contenants peu profonds : 3 à 4 jours. Congelés : 3 mois, avec la date (Thermoguide du MAPAQ).'**
  String get restesConseil;

  /// No description provided for @auGardeManger.
  ///
  /// In fr, this message translates to:
  /// **'Au garde-manger'**
  String get auGardeManger;

  /// No description provided for @auGardeMangerAide.
  ///
  /// In fr, this message translates to:
  /// **'Ce que la recette a pris. Coche ce qu\'il faut mettre à jour.'**
  String get auGardeMangerAide;

  /// No description provided for @finiQuestion.
  ///
  /// In fr, this message translates to:
  /// **'Quantité inconnue : coche s\'il est fini'**
  String get finiQuestion;

  /// No description provided for @ilNEnResteraPlus.
  ///
  /// In fr, this message translates to:
  /// **'Il n\'en restera plus : fini'**
  String get ilNEnResteraPlus;

  /// No description provided for @ilEnRestera.
  ///
  /// In fr, this message translates to:
  /// **'Il en restera {quantite}'**
  String ilEnRestera(String quantite);

  /// No description provided for @rienACocher.
  ///
  /// In fr, this message translates to:
  /// **'Rien de coché.'**
  String get rienACocher;

  /// No description provided for @articlesAjoutesListe.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Rien d\'ajouté} =1{1 article sur la liste} other{{n} articles sur la liste}}'**
  String articlesAjoutesListe(int n);

  /// No description provided for @dejaSurLaListe.
  ///
  /// In fr, this message translates to:
  /// **'Déjà sur la liste'**
  String get dejaSurLaListe;

  /// No description provided for @aAcheter.
  ///
  /// In fr, this message translates to:
  /// **'À acheter : {quantite}'**
  String aAcheter(String quantite);

  /// No description provided for @aAcheterNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Rien à acheter} =1{1 à acheter} other{{n} à acheter}}'**
  String aAcheterNombre(int n);

  /// No description provided for @dejaLaNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Rien d\'avance} =1{1 déjà là} other{{n} déjà là}}'**
  String dejaLaNombre(int n);

  /// No description provided for @ajouterALaListeNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Rien à ajouter} =1{Ajouter 1 article à la liste} other{Ajouter {n} articles à la liste}}'**
  String ajouterALaListeNombre(int n);

  /// No description provided for @ajoutListeAide.
  ///
  /// In fr, this message translates to:
  /// **'Ce qui est au garde-manger ou déjà sur la liste est retiré ; les doublons fusionnent.'**
  String get ajoutListeAide;

  /// No description provided for @rienDePrevuSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Rien de prévu cette semaine'**
  String get rienDePrevuSemaine;

  /// No description provided for @repasPrevusNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun repas prévu} =1{1 repas prévu} other{{n} repas prévus}}'**
  String repasPrevusNombre(int n);

  /// No description provided for @cetteSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get cetteSemaine;

  /// No description provided for @listeDeLaSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Liste de la semaine'**
  String get listeDeLaSemaine;

  /// No description provided for @aucuneRecettePrevue.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette prévue'**
  String get aucuneRecettePrevue;

  /// No description provided for @toutEstLa.
  ///
  /// In fr, this message translates to:
  /// **'Tout est là'**
  String get toutEstLa;

  /// No description provided for @recettesPrevuesNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucune recette prévue} =1{Pour 1 recette prévue} other{Pour {n} recettes prévues}}'**
  String recettesPrevuesNombre(int n);

  /// No description provided for @cuisineEnLot.
  ///
  /// In fr, this message translates to:
  /// **'Cuisine en lot'**
  String get cuisineEnLot;

  /// No description provided for @cuisineEnLotDetail.
  ///
  /// In fr, this message translates to:
  /// **'Cuisiner une fois, manger plusieurs fois'**
  String get cuisineEnLotDetail;

  /// No description provided for @cuisineEnLotResume.
  ///
  /// In fr, this message translates to:
  /// **'{nom} : {n} repas, une seule fois'**
  String cuisineEnLotResume(String nom, int n);

  /// No description provided for @aDecongelerCeSoir.
  ///
  /// In fr, this message translates to:
  /// **'À décongeler ce soir'**
  String get aDecongelerCeSoir;

  /// No description provided for @aDecongelerCeSoirCourt.
  ///
  /// In fr, this message translates to:
  /// **'à décongeler ce soir'**
  String get aDecongelerCeSoirCourt;

  /// No description provided for @reglages.
  ///
  /// In fr, this message translates to:
  /// **'Réglages'**
  String get reglages;

  /// No description provided for @portionsParRepas.
  ///
  /// In fr, this message translates to:
  /// **'Portions par repas'**
  String get portionsParRepas;

  /// No description provided for @portionsParRepasDetail.
  ///
  /// In fr, this message translates to:
  /// **'Pour combien tu prévois, d\'habitude'**
  String get portionsParRepasDetail;

  /// No description provided for @rappelDecongelation.
  ///
  /// In fr, this message translates to:
  /// **'Rappel de décongélation'**
  String get rappelDecongelation;

  /// No description provided for @rappelDecongelationDetail.
  ///
  /// In fr, this message translates to:
  /// **'La veille, à {heure} : ce qu\'il faut sortir du congélateur'**
  String rappelDecongelationDetail(String heure);

  /// No description provided for @prevoirAu.
  ///
  /// In fr, this message translates to:
  /// **'{moment, select, dejeuner{Prévoir le déjeuner} diner{Prévoir le dîner} collation{Prévoir une collation} souper{Prévoir le souper} other{Prévoir un repas}}'**
  String prevoirAu(String moment);

  /// No description provided for @rienDePrevuMoment.
  ///
  /// In fr, this message translates to:
  /// **'Rien de prévu'**
  String get rienDePrevuMoment;

  /// No description provided for @mangeCourt.
  ///
  /// In fr, this message translates to:
  /// **'mangé'**
  String get mangeCourt;

  /// No description provided for @prevuAuToast.
  ///
  /// In fr, this message translates to:
  /// **'{moment, select, dejeuner{Prévu au déjeuner : {nom}} diner{Prévu au dîner : {nom}} collation{Prévu en collation : {nom}} souper{Prévu au souper : {nom}} other{Prévu : {nom}}}'**
  String prevuAuToast(String nom, String moment);

  /// No description provided for @recettesDuMoment.
  ///
  /// In fr, this message translates to:
  /// **'{moment, select, dejeuner{Pour le déjeuner} diner{Pour le dîner} collation{Pour la collation} souper{Pour le souper} other{Pour ce repas}}'**
  String recettesDuMoment(String moment);

  /// No description provided for @autresRecettes.
  ///
  /// In fr, this message translates to:
  /// **'Autres recettes'**
  String get autresRecettes;

  /// No description provided for @autreChose.
  ///
  /// In fr, this message translates to:
  /// **'Autre chose'**
  String get autreChose;

  /// No description provided for @indiceAutreChose.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant, souper chez des amis…'**
  String get indiceAutreChose;

  /// No description provided for @dejaNoteAuJournal.
  ///
  /// In fr, this message translates to:
  /// **'Déjà noté au journal.'**
  String get dejaNoteAuJournal;

  /// No description provided for @portionsPrevues.
  ///
  /// In fr, this message translates to:
  /// **'Portions prévues'**
  String get portionsPrevues;

  /// No description provided for @aSortirLaVeille.
  ///
  /// In fr, this message translates to:
  /// **'À sortir du congélateur la veille : {noms}.'**
  String aSortirLaVeille(String noms);

  /// No description provided for @restesDisponibles.
  ///
  /// In fr, this message translates to:
  /// **'{portions} en restes au garde-manger'**
  String restesDisponibles(String portions);

  /// No description provided for @noterCommeMange.
  ///
  /// In fr, this message translates to:
  /// **'Noter comme mangé'**
  String get noterCommeMange;

  /// No description provided for @voirLaRecette.
  ///
  /// In fr, this message translates to:
  /// **'Voir la recette'**
  String get voirLaRecette;

  /// No description provided for @deplacer.
  ///
  /// In fr, this message translates to:
  /// **'Déplacer'**
  String get deplacer;

  /// No description provided for @retirerDuPlan.
  ///
  /// In fr, this message translates to:
  /// **'Retirer de ma semaine'**
  String get retirerDuPlan;

  /// No description provided for @cuisineEnLotVide.
  ///
  /// In fr, this message translates to:
  /// **'Aucune recette prévue cette semaine. Prévois tes repas dans Ma semaine : ceux qui reviennent se cuisinent en une fois.'**
  String get cuisineEnLotVide;

  /// No description provided for @aCuisinerCetteSemaine.
  ///
  /// In fr, this message translates to:
  /// **'À cuisiner cette semaine'**
  String get aCuisinerCetteSemaine;

  /// No description provided for @repasNombreJours.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Aucun repas} =1{1 repas ({jours})} other{{n} repas ({jours})}}'**
  String repasNombreJours(int n, String jours);

  /// No description provided for @unLotDe.
  ///
  /// In fr, this message translates to:
  /// **'{fois} × la recette ({portions})'**
  String unLotDe(String fois, String portions);

  /// No description provided for @dejaEnRestes.
  ///
  /// In fr, this message translates to:
  /// **'déjà en restes'**
  String get dejaEnRestes;

  /// No description provided for @aPreparerEnUneFois.
  ///
  /// In fr, this message translates to:
  /// **'À préparer en une fois'**
  String get aPreparerEnUneFois;

  /// No description provided for @dejaPrevu.
  ///
  /// In fr, this message translates to:
  /// **'Déjà prévu : {noms}'**
  String dejaPrevu(String noms);

  /// No description provided for @ajouterAMaSemaine.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter à ma semaine'**
  String get ajouterAMaSemaine;

  /// No description provided for @prisDansLesRestes.
  ///
  /// In fr, this message translates to:
  /// **'Pris dans les restes'**
  String get prisDansLesRestes;

  /// No description provided for @prevuNoms.
  ///
  /// In fr, this message translates to:
  /// **'Prévu : {noms}'**
  String prevuNoms(String noms);

  /// No description provided for @prevu.
  ///
  /// In fr, this message translates to:
  /// **'Prévu'**
  String get prevu;

  /// No description provided for @prevuToucher.
  ///
  /// In fr, this message translates to:
  /// **'prévu · toucher pour cuisiner ou noter'**
  String get prevuToucher;

  /// No description provided for @maRecette.
  ///
  /// In fr, this message translates to:
  /// **'Ma recette'**
  String get maRecette;

  /// No description provided for @lesRestesTitre.
  ///
  /// In fr, this message translates to:
  /// **'Les restes'**
  String get lesRestesTitre;

  /// No description provided for @mangerUnePortion.
  ///
  /// In fr, this message translates to:
  /// **'Manger une portion de {nom}'**
  String mangerUnePortion(String nom);

  /// No description provided for @mangerUnePortionCourt.
  ///
  /// In fr, this message translates to:
  /// **'Manger une portion'**
  String get mangerUnePortionCourt;

  /// No description provided for @mangerUnePortionDetail.
  ///
  /// In fr, this message translates to:
  /// **'Au journal, et décomptée des restes'**
  String get mangerUnePortionDetail;

  /// No description provided for @aVerifierPlacard.
  ///
  /// In fr, this message translates to:
  /// **'À vérifier au placard'**
  String get aVerifierPlacard;

  /// No description provided for @aVerifierNombre.
  ///
  /// In fr, this message translates to:
  /// **'{n, plural, =0{Rien à vérifier} =1{1 à vérifier} other{{n} à vérifier}}'**
  String aVerifierNombre(int n);

  /// No description provided for @revoir.
  ///
  /// In fr, this message translates to:
  /// **'Revoir'**
  String get revoir;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
