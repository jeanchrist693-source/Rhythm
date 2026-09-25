// lib/app/rhythm_app.dart
//
// Racine de Rhythm : thème sombre unique, FR (source) / EN, la coquille, et
// par-dessus tout, la scène d'ouverture tant qu'elle joue. La synchro
// (notifications des habitudes, « maintenant ») enveloppe le tout.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../ecrans/coquille/coquille_ecran.dart';
import '../l10n/traductions.dart';
import '../systeme/synchro.dart';
import '../theme/rhythm_theme.dart';
import '../widgets/scene_ouverture.dart';

class RhythmApp extends StatelessWidget {
  const RhythmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.tr.titreApp,
      debugShowCheckedModeBanner: false,
      theme: RhythmTheme.sombre(),
      themeMode: ThemeMode.dark,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      // L'appareil en anglais → anglais ; tout le reste → français.
      localeResolutionCallback: (locale, supportees) =>
          locale?.languageCode == 'en'
          ? const Locale('en')
          : const Locale('fr'),
      home: const CoquilleEcran(),
      // La scène d'ouverture couvre TOUT (barre comprise) jusqu'à sa sortie ;
      // la synchro (notifications, « maintenant ») veille en dessous.
      builder: (context, enfant) => SynchroSysteme(
        child: Stack(
          fit: StackFit.expand,
          children: [
            enfant!,
            if (SceneOuverture.active) const SceneOuverture(),
          ],
        ),
      ),
    );
  }
}
