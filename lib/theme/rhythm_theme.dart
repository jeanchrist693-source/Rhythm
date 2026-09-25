// lib/theme/rhythm_theme.dart
//
// `ThemeData` de Rhythm : sombre uniquement, construit sur les tokens. Les
// widgets Material par défaut sont neutralisés au profit de `lib/widgets/` ;
// le thème fixe surtout le fond, la police et l'absence d'encre (le retour
// tactile est `PressionEchelle`).

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../navigation/transitions.dart';
import 'rhythm_couleurs.dart';
import 'rhythm_typo.dart';

abstract final class RhythmTheme {
  /// Barres système transparentes, icônes claires.
  static const SystemUiOverlayStyle barresSysteme = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
    systemNavigationBarContrastEnforced: false,
  );

  static ThemeData sombre() {
    const schema = ColorScheme(
      brightness: Brightness.dark,
      primary: RhythmCouleurs.blanc,
      onPrimary: RhythmCouleurs.noir,
      secondary: RhythmCouleurs.menthe,
      onSecondary: RhythmCouleurs.noir,
      error: RhythmCouleurs.corail,
      onError: RhythmCouleurs.noir,
      surface: RhythmCouleurs.fond,
      onSurface: RhythmCouleurs.texte,
      onSurfaceVariant: RhythmCouleurs.texte64,
      outline: RhythmCouleurs.bordVerre,
      outlineVariant: RhythmCouleurs.filet,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: schema,
      scaffoldBackgroundColor: RhythmCouleurs.fond,
      canvasColor: RhythmCouleurs.fond,
      fontFamily: RhythmTypo.familleTexte,
      textTheme: TextTheme(
        bodyLarge: RhythmTypo.texte(15),
        bodyMedium: RhythmTypo.texte(14),
        bodySmall: RhythmTypo.petit,
        labelLarge: RhythmTypo.texte(15, poids: 600),
      ),
      iconTheme: const IconThemeData(color: RhythmCouleurs.texte, size: 22),
      dividerColor: RhythmCouleurs.filet,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashFactory: NoSplash.splashFactory,
      // Les écrans secondaires : le fondu-glissement ralenti de Net Worth et
      // Studio (même sensation dans les trois apps).
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FonduAvantLent(),
          TargetPlatform.iOS: FonduAvantLent(),
        },
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: RhythmCouleurs.blanc,
        selectionColor: Color(0x55A6EFCB),
        selectionHandleColor: RhythmCouleurs.menthe,
      ),
    );
  }
}
