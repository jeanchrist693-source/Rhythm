// lib/systeme/synchro.dart
//
// Le pont entre Rhythm et Android (repris de Studio) : à chaque changement
// des habitudes, des séances, du garde-manger, des repas prévus ou des
// minuteurs de cuisine, au retour dans l'app et au lancement, les
// notifications sont recalculées (`rappels_habitudes.dart`,
// `rappels_sport.dart`, `rappels_garde_manger.dart`,
// `rappels_recettes.dart`) et replanifiées en bloc.
// Posée au-dessus de tout (`RhythmApp.builder`), sous les traductions : les
// textes partent dans la langue de l'app.
//
// L'autorisation des notifications (Android 13+) n'est PAS demandée au
// lancement : elle l'est au moment où l'on active un rappel
// ([assurerAutorisation]) ; ensuite, Rappels dit si Android les bloque et y
// mène.
//
// « Maintenant » (`aujourdhuiProvider`) est rafraîchi au retour dans l'app
// et quand la tranche de la journée change (matin, après-midi, soir, nuit)
// ou le jour : le mot du jour, « Bonjour / Bonsoir » et les séries suivent.

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/traductions.dart';
import '../modele/alimentation/etat_courses.dart';
import '../modele/alimentation/etat_recettes.dart';
import '../modele/calculs_habitudes.dart';
import '../modele/etat_habitudes.dart';
import '../modele/etat_sante.dart';
import '../modele/sports/etat_sport.dart';
import '../utils/dates.dart';
import 'notifications.dart';
import 'rappels_garde_manger.dart';
import 'rappels_habitudes.dart';
import 'rappels_recettes.dart';
import 'rappels_sport.dart';

/// Android autorise-t-il les notifications de Rhythm ? `null` : inconnu
/// (hors Android, ou pas encore vérifié).
final autorisationNotifsProvider = NotifierProvider<AutorisationNotifs, bool?>(
  AutorisationNotifs.new,
);

class AutorisationNotifs extends Notifier<bool?> {
  @override
  bool? build() => null;

  Future<void> verifier() async {
    final r = await NotificationsSysteme.instance.autorisees();
    if (ref.mounted) state = r;
  }

  /// Demande l'autorisation ; refusée pour de bon, ouvre les réglages
  /// d'Android.
  Future<void> demander({bool reglagesSiRefus = false}) async {
    final r = await NotificationsSysteme.instance.demander();
    if (!ref.mounted) return;
    state = r;
    if (r == false && reglagesSiRefus) {
      await NotificationsSysteme.instance.ouvrirReglages();
    }
  }
}

/// À l'activation d'un rappel : l'autorisation d'Android, demandée UNE fois
/// dans la vie de l'app (ensuite, seulement vérifiée).
Future<void> assurerAutorisation(WidgetRef ref) async {
  final reglages = ref.read(habitudesProvider).reglages;
  final autorisation = ref.read(autorisationNotifsProvider.notifier);
  if (reglages.autorisationDemandee) {
    await autorisation.verifier();
    return;
  }
  ref
      .read(habitudesProvider.notifier)
      .modifierReglages(reglages.copierAvec(autorisationDemandee: true));
  await autorisation.demander();
}

class SynchroSysteme extends ConsumerStatefulWidget {
  const SynchroSysteme({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<SynchroSysteme> createState() => _SynchroSystemeState();
}

class _SynchroSystemeState extends ConsumerState<SynchroSysteme>
    with WidgetsBindingObserver {
  Timer? _attente;
  Timer? _horloge;

  static bool get _actif => NotificationsSysteme.disponible;

  @override
  void initState() {
    super.initState();
    if (!_actif) return;
    WidgetsBinding.instance.addObserver(this);
    NotificationsSysteme.instance.preparer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(autorisationNotifsProvider.notifier).verifier();
    });
    _horloge = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _suivreHeure(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // La langue de l'app a pu changer : les textes aussi.
    if (_actif) _programmer();
  }

  @override
  void dispose() {
    _attente?.cancel();
    _horloge?.cancel();
    if (_actif) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState etat) {
    if (etat != AppLifecycleState.resumed) return;
    ref.invalidate(aujourdhuiProvider);
    ref.read(autorisationNotifsProvider.notifier).verifier();
    _programmer(const Duration(milliseconds: 300));
  }

  /// Un nouveau jour, ou une nouvelle tranche de la journée : « maintenant »
  /// avance.
  void _suivreHeure() {
    if (!mounted) return;
    final vu = ref.read(aujourdhuiProvider);
    final maintenant = DateTime.now();
    // Les tranches changent à 5, 12, 18 et 23 h (18 h : « Bonsoir »).
    if (jourDe(vu) != jourDe(maintenant) ||
        trancheDe(vu) != trancheDe(maintenant)) {
      ref.invalidate(aujourdhuiProvider);
    }
  }

  /// Pousse après [delai] sans nouveau changement (une saisie en rafale ne
  /// replanifie qu'une fois).
  void _programmer([Duration delai = const Duration(milliseconds: 1500)]) {
    _attente?.cancel();
    _attente = Timer(delai, _pousser);
  }

  Future<void> _pousser() async {
    if (!mounted) return;
    final habitudes = ref.read(habitudesProvider);
    final maintenant = DateTime.now();
    final notifs = [
      ...notificationsHabitudes(
        etat: habitudes,
        maintenant: maintenant,
        tr: context.tr,
        formats: context.formats,
      ),
      ...notificationsSport(
        etat: ref.read(sportProvider),
        maintenant: maintenant,
        tr: context.tr,
        actifs: habitudes.reglages.rappels,
      ),
      ...notificationsGardeManger(
        etat: ref.read(coursesProvider),
        maintenant: maintenant,
        tr: context.tr,
        actifs: habitudes.reglages.rappels,
      ),
      ...notificationsDecongelation(
        recettes: ref.read(recettesProvider),
        gardeManger: ref.read(coursesProvider).gardeManger,
        maintenant: maintenant,
        tr: context.tr,
        actifs: habitudes.reglages.rappels,
      ),
      ...notificationsMinuteurs(
        minuteurs: ref.read(minuteursProvider),
        maintenant: maintenant,
        tr: context.tr,
      ),
    ];
    // Un échec du système ne doit jamais gêner l'app.
    try {
      await NotificationsSysteme.instance.planifier(notifs);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_actif) {
      ref.listen(habitudesProvider, (_, _) => _programmer());
      ref.listen(sportProvider, (_, _) => _programmer());
      ref.listen(coursesProvider, (_, _) => _programmer());
      ref.listen(recettesProvider, (_, _) => _programmer());
      // Un minuteur lancé doit être planifié tout de suite (il peut ne
      // durer qu'une minute).
      ref.listen(
        minuteursProvider,
        (_, _) => _programmer(const Duration(milliseconds: 200)),
      );
      ref.listen(aujourdhuiProvider, (_, _) => _programmer());
    }
    return widget.child;
  }
}
