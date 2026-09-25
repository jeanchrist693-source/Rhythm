// lib/systeme/notifications.dart
//
// Les notifications d'Android (`flutter_local_notifications`), le service de
// Studio repris : planifiées à l'avance et REPLANIFIÉES en bloc à chaque
// changement (`synchro.dart`) — celles en attente sont annulées, celles déjà
// affichées restent.
//
// Heures : des INSTANTS absolus (calculés en heure locale par Dart, passage
// à l'heure d'été compris), envoyés en UTC — pas besoin du fuseau du
// téléphone ; un changement de fuseau est rattrapé à la prochaine ouverture.
// Alarmes INEXACTES (`inexactAllowWhileIdle`) : aucune permission d'alarme
// exacte ; un rappel peut arriver quelques minutes après l'heure.
//
// DISCRÉTION : le canal de soutien (libération) est « privé » — sur un écran
// verrouillé sécurisé, Android n'en montre que l'existence. Et ses textes ne
// nomment JAMAIS ce dont on se libère (`rappels_habitudes.dart`).
//
// Toucher une notification ouvre l'app sur les Habitudes (charge utile
// « habitudes », relayée par [NotificationsSysteme.touchee]).
//
// Hors Android (tests, captures), tout est sans effet.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

/// Un canal d'Android : réglable à part dans les paramètres du système.
class CanalNotif {
  const CanalNotif(this.id, this.nom, this.description, {this.prive = false});

  final String id;
  final String nom;
  final String description;

  /// Contenu masqué sur un écran verrouillé sécurisé.
  final bool prive;
}

/// Une notification prête à planifier : son texte est déjà dans la langue
/// de l'app.
class NotifTexte {
  const NotifTexte({
    required this.id,
    required this.quand,
    required this.canal,
    required this.titre,
    required this.corps,
    this.charge,
  });

  final int id;
  final DateTime quand;
  final CanalNotif canal;
  final String titre;

  /// Une ligne par idée ; la première se lit notification repliée.
  final String corps;

  /// Ce que l'app fait quand on la touche (« habitudes »).
  final String? charge;
}

class NotificationsSysteme {
  NotificationsSysteme._();

  static final instance = NotificationsSysteme._();

  /// Seul Android reçoit des notifications (ni les tests ni les captures).
  static bool get disponible => !kIsWeb && Platform.isAndroid;

  /// La charge utile de la notification touchée (au lancement ou app
  /// ouverte) ; la coquille la consomme (remise à `null`).
  static final ValueNotifier<String?> touchee = ValueNotifier(null);

  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void>? _init;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  /// Prépare le service (une fois) et relaie la notification qui a lancé
  /// l'app, s'il y en a une.
  Future<void> preparer() async {
    if (!disponible) return;
    await (_init ??= _initialiser());
  }

  Future<void> _initialiser() async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
      onDidReceiveNotificationResponse: (r) => touchee.value = r.payload,
    );
    final lancement = await _plugin.getNotificationAppLaunchDetails();
    if (lancement?.didNotificationLaunchApp ?? false) {
      touchee.value = lancement!.notificationResponse?.payload;
    }
  }

  /// Le système les autorise-t-il ? `null` hors Android.
  Future<bool?> autorisees() async {
    if (!disponible) return null;
    await preparer();
    return _android?.areNotificationsEnabled();
  }

  /// Demande l'autorisation (Android 13 et plus ; le système ne la
  /// redemande plus après deux refus).
  Future<bool?> demander() async {
    if (!disponible) return null;
    await preparer();
    return _android?.requestNotificationsPermission();
  }

  /// Ouvre les réglages de notification de Rhythm dans Android.
  Future<void> ouvrirReglages() async {
    if (!disponible) return;
    await preparer();
    await _plugin.openAppNotificationSettings();
  }

  /// Retire une notification affichée (le rappel d'une habitude qu'on vient
  /// de cocher).
  Future<void> annuler(int id) async {
    if (!disponible) return;
    await preparer();
    try {
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  /// Remplace toutes les notifications EN ATTENTE par [notifs].
  Future<void> planifier(List<NotifTexte> notifs) async {
    if (!disponible) return;
    await preparer();
    await _plugin.cancelAllPendingNotifications();
    for (final n in notifs) {
      // Le plugin refuse une heure passée : une marge, et chacune à part
      // (un refus ne doit pas priver les suivantes).
      final limite = DateTime.now().add(const Duration(seconds: 10));
      if (!n.quand.isAfter(limite)) continue;
      try {
        await _planifierUne(n);
      } catch (_) {}
    }
  }

  Future<void> _planifierUne(NotifTexte n) => _plugin.zonedSchedule(
    id: n.id,
    scheduledDate: tz.TZDateTime.from(n.quand, tz.UTC),
    title: n.titre,
    body: n.corps.split('\n').first,
    payload: n.charge,
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        n.canal.id,
        n.canal.nom,
        channelDescription: n.canal.description,
        icon: 'ic_notification',
        // La menthe de Rhythm (petite icône et accents du système).
        color: const Color(0xFFA6EFCB),
        visibility: n.canal.prive
            ? NotificationVisibility.private
            : NotificationVisibility.public,
        styleInformation: BigTextStyleInformation(n.corps),
      ),
    ),
    androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
  );
}
