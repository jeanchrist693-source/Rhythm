package com.gardien.rhythm

import io.flutter.embedding.android.FlutterActivity

/**
 * Activité unique de Rhythm.
 *
 * L'écran de démarrage système est un simple NOIR, sans icône
 * (values-v31 / values-night-v31) : le zoom de l'icône s'y fond, et c'est
 * Flutter qui compose ensuite le logo (lib/widgets/scene_ouverture.dart).
 *
 * Rien n'est joué ici, dans le splash d'Android — leçon de Studio
 * (23 septembre 2026) : depuis l'icône, Samsung superpose l'icône au splash
 * pendant le zoom, et Android coupe l'animation d'un splash à 1 s.
 */
class MainActivity : FlutterActivity()
