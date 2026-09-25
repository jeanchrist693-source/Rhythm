// lib/main.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

import 'app/rhythm_app.dart';
import 'modele/depot.dart';
import 'modele/etat_habitudes.dart';
import 'theme/rhythm_theme.dart';
import 'widgets/scene_ouverture.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(RhythmTheme.barresSysteme);
  // La maquette est un téléphone debout.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Noms de jours et de mois (fr_CA, en_CA) pour `Formats`.
  await initializeDateFormatting();
  // La base de l'app (`<documents>/rhythm/rhythm.db`, dossier emporté par
  // la sauvegarde d'Android). Sans dossier accessible, Rhythm démarre quand
  // même, en mémoire.
  Depot? depot;
  try {
    final docs = await getApplicationDocumentsDirectory();
    final sep = Platform.pathSeparator;
    depot = Depot.ouvrir('${docs.path}${sep}rhythm${sep}rhythm.db');
  } catch (_) {}
  // Une fois par lancement : le logo se compose en mesure, puis l'app entre.
  SceneOuverture.activer();
  runApp(
    ProviderScope(
      overrides: [if (depot != null) depotProvider.overrideWithValue(depot)],
      child: const RhythmApp(),
    ),
  );
}
