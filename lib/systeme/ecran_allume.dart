// lib/systeme/ecran_allume.dart
//
// Pendant une séance guidée ou une sortie chronométrée, l'écran reste
// ALLUMÉ (`wakelock_plus`) : le repos se lit d'un coup d'œil, le minuteur ne
// disparaît pas au milieu d'une série. Rendu dès qu'on quitte la séance.
// Hors Android (tests, captures), sans effet ; un échec ne gêne jamais.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

Future<void> garderEcranAllume(bool allume) async {
  if (kIsWeb || !Platform.isAndroid) return;
  try {
    await WakelockPlus.toggle(enable: allume);
  } catch (_) {}
}
