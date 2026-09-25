# CLAUDE.md — Projet Rhythm

> Document de référence pour Claude Code. **Projet créé le 24 septembre 2026**
> (Flutter, Android + iOS). Communication et code **en français**.

---

## 1. Identité

**Rhythm** est l'application **santé** de l'utilisateur : Sports, Alimentation,
Habitudes, Biblique. C'est le **module Santé de Flow**
(`C:\Users\Gardien\Applications\flow`, `lib/features/health/` et
`lib/features/bible/`) **réinventé dans le design de la maquette** — une app à
part, comme Studio l'est pour les études. Flow n'a pas été modifié (retrait
éventuel de sa section Santé = décision de l'utilisateur, à ne pas prendre
seul).

Nom de code = nom affiché : `rhythm`, `applicationId = com.gardien.rhythm`.
Ne pas changer l'`applicationId` (il portera les données une fois la
persistance en place).

**État au 24 septembre 2026 : la MAQUETTE réalisée** (première étape
demandée : « réaliser ce mock et l'installer pour tester »), plus une scène
d'ouverture et une entrée animée de l'accueil ; puis on « fait vivre » l'app
SECTION PAR SECTION (demande de l'utilisateur). **Les HABITUDES sont
fonctionnelles et PERSISTÉES** (§ 3 bis), **les SPORTS aussi — section
CONCLUE** (§ 3 ter, 25 sept. 2026 : reste à les éprouver sur le
téléphone, § 6), **l'ALIMENTATION est en cours, palier par palier**
(§ 3 quater : paliers 1 à 4 livrés — le socle, les achats, les
recettes, l'IA — puis les lots 5 et 6, les finitions du plan, à tester :
le plan de l'Alimentation est COMPLET). Biblique affiche encore les données de la
maquette (`lib/modele/graine.dart`), posées sur les vraies dates.

---

## 2. Design — la maquette

Source de vérité : **`design/Rhythm.html`** (copie du fichier de
l'utilisateur, 5 planches de 390 × 844 : Accueil, Sports, Alimentation,
Habitudes, Biblique). C'est un paquet autonome (gabarits + polices + moteur
embarqués) : l'ouvrir via le serveur de `.claude/launch.json` (« maquette »,
port 8765 — les `file://` sont refusés par le navigateur intégré). Les
valeurs exactes sont dans le gabarit de chaque planche (voir
`tool/extraire_polices.py` pour déballer le paquet).

- **PAS DE CARTES** — la grande divergence avec la maquette, voulue par
  l'utilisateur (24 sept. 2026) : les cartes en aplat « pas apaisantes à
  regarder », et « fatigué des cartes aux bords arrondis, on en a trop dans
  les applications — avec Rhythm, je veux innover » (ses autres apps gardent
  les leurs). Le contenu repose sur le **noir OLED pur** `#000000` ; deux
  outils le structurent (`lib/widgets/filets.dart`) :
  - **les filets** : 1 dp, blanc 8 % (11 % pour une grille), qui
    s'estompent à leurs bouts — entre les lignes d'une liste, entre les
    cases d'une rangée (`RangeeFilets`), en CROIX au cœur de la grille 2 × 2
    de l'accueil (`GrilleFilets` : une fenêtre, pas quatre boîtes) ;
  - **l'air** : 28 entre les sections (la maquette, avec ses boîtes : 16),
    22 sous l'en-tête.
  Plus rien n'est une boîte arrondie : restent des CAPSULES (boutons,
  barre, aujourd'hui dans la semaine des Habitudes — la forme des barres du
  logo) et des DISQUES (pastilles). Au toucher : la pression d'échelle de
  toutes les apps (`PressionEchelle`), rien d'autre. Ne pas réintroduire de
  cartes sans que l'utilisateur le demande. Version à cartes sauvegardée
  hors du projet (APK `rhythm-v1-cartes.apk`, dans le bloc-notes de la
  session du 24 sept.).
- **⛔ PAS DE LUEURS (glow)** — essayées le 24 sept. 2026 (une lueur de
  couleur derrière la section héros de chaque écran, une autre sous le
  doigt), puis retirées à la demande de l'utilisateur, en trois temps :
  « réduis le glow considérablement », « même au toucher, j'aime pas le glow
  du tout », « retire totalement ». Ni halo, ni aura, ni dégradé de couleur
  derrière un contenu, ni au repos ni au toucher.
- **Verre** : il ne reste que sur la **barre** (seul objet flottant) —
  dégradé à 180° calculé comme en CSS (`PeintreVerre`), bord 18 %, reflet
  de 1 px (28 %).
- **Cinq pastels, un par domaine** — un sens, jamais une décoration :
  corail `#FF8A7A` sports, pêche `#FFD3A8` alimentation, menthe `#A6EFCB`
  habitudes (et « fait »), lavande `#D9C8FF` biblique, ciel `#BFDDFF` l'eau.
- **Typo** (extraite des WOFF2 de la maquette, OFL, `assets/polices/`) :
  **Bricolage Grotesque** (titres 34, chiffres, versets) et **DM Sans**
  (tout le reste). Toutes deux VARIABLES (`wght` + `opsz`) : taille optique
  = taille du texte, comme le navigateur. ⚠️ Défauts du fichier de
  Bricolage : wght 800, opsz 96 — toujours `RhythmTypo.titre/texte(…)`,
  jamais un `TextStyle` nu. Hauteur de ligne `null` = celle de la police =
  le `line-height: normal` de la maquette.
- **Pictogrammes et mascottes dessinés depuis les tracés SVG de la
  maquette**, recopiés tels quels (`chemin_svg.dart` lit l'attribut `d`).
- **Mascottes** (`mascottes.dart`) : le coureur, le gourmand,
  l'enthousiaste, le lecteur — 112 × 90, débordant de l'en-tête comme dans
  la maquette (marges −16 / −8). Leurs FORMES sont celles de la maquette ;
  leur MOUVEMENT a été refait le 24 sept. 2026 (l'utilisateur : celui de la
  maquette était « niveau débutant, aucune naturalité ») selon les principes
  de l'animation — écrasement / étirement à volume constant, anticipation,
  traîne et chevauchement, arcs et ralentis (poses clés reliées par des
  splines d'Hermite, `_piste`), actions secondaires à des rythmes
  incommensurables (clignements irréguliers et parfois doubles,
  respiration, balancements) : rien ne boucle mécaniquement.
  - **coureur** : vrai cycle de course (0,56 s, appui + suspension), le corps
    descend et s'écrase EN APPUI, monte et s'étire en suspension ; jambes et
    bras à deux segments (cinématique inverse, `_membre2`) ; chaque pied suit
    une boucle fermée et, posé, recule à la vitesse exacte du sol (il ne
    glisse pas) ; bras qui pompent coude plié ; rubans du bandeau (ajoutés)
    qui flottent derrière ; poussière à chaque pas ; ombre.
  - **gourmand** : une vraie bouchée (4,4 s) — la main au bol en arc, la
    cuillère plonge et ramasse, ATTEND devant la bouche qui s'ouvre grand
    (anticipation), entre ; les lèvres avancent et se ferment dessus (le
    creux disparaît : ce qui passe derrière le contour du visage est
    « dans la bouche », découpé), la cuillère ressort vide ; il mâche BOUCHE
    FERMÉE (mâchoire en petit ovale, lèvres qui roulent), les yeux se
    ferment puis se plissent de plaisir, avale, sourit ; pieds qui se
    balancent ; la cuillère disparaît dans la soupe (bol peint par-dessus).
    Visage de TROIS QUARTS (il regarde le bol) : yeux décalés vers la
    droite (58 et 67,5 — ceux de la maquette, 52 et 64, faisaient paraître
    la bouche décalée, retour de l'utilisateur), l'œil du fond plus étroit
    (`largeurs` de `_yeux`), la bouche SOUS eux, à peine vers l'avant ; elle
    est peinte après la cuillère, et ce qui passe dans le visage à gauche de
    la commissure est caché (« dans la bouche »).
    Retouché le 24 sept. (l'utilisateur : « sa bouche fait bizarre,
    constamment ouverte, et il a l'air penché ») : au repos la bouche est un
    SOURIRE FERMÉ (`_bouche` : deux lèvres entre deux commissures — un trait
    fermé, un creux noir ouvert) ; le corps reste DROIT (plus de bascule
    vers la cuillère) ; le bras gauche (invisible, même couleur que le
    corps) retiré — son bout bosselait le bas du corps et le faisait
    paraître de travers.
  - **enthousiaste** : saut de joie (2,8 s) — élan accroupi bras le long du
    corps, jaillissement étiré, jambes repliées, mains qui s'agitent,
    atterrissage écrasé puis amorti ; la coche éclot au sommet et se trace ;
    la plante (qui ne « rapetisse » plus) se balance et frémit au choc.
  - **lecteur** : respiration asymétrique, dérive lente de la tête, une page
    tournée toutes les 7,6 s (pincée, soulevée en s'incurvant, revers
    visible, posée, hochement de tête) ; les couleurs de la page la rendent
    invisible au repos des deux côtés : boucle sans couture.
  Yeux (`_yeux`, les quatre) : ouverts, un point qui s'écrase ; FERMÉS, un
  trait plein (un peu tombant, qui s'arque en « ^ » dans la joie) — jamais
  de fondu entre point et arc (il laissait des taches grises).
  Une horloge par mascotte, mise en sourdine (pas remise à zéro) quand
  l'onglet est caché (`TickerMode`), arrêtée si le système réduit les
  animations. Juger un mouvement = le FILMER : `test/outils/mascottes_test.dart`
  écrit les images (30 i/s), ffmpeg en fait une vidéo.
- **Barre** : capsule de verre flottante (20 des bords, 68, coins 34),
  floutée (28) et saturée (160 %) — le seul verre flouté —, ombre peinte
  AUTOUR seulement (comme en CSS). L'onglet actif est une capsule blanche
  14 % avec libellé ; elle se déplie / se replie d'une destination à l'autre
  (300 ms). À l'étroit, les inactives cèdent la place (`flex-shrink`).
- **Typographie française** : insécable U+00A0 avant « : » et entre un
  nombre et son unité, guillemets « » avec insécables (le verset de la
  planche Biblique laissait un « » » seul sur sa ligne : corrigé).
- **Écrans qui défilent** : la maquette tient en 844, le téléphone pas
  toujours (Alimentation dépasse) — le dernier bloc remonte au-dessus de la
  barre ; voile noir fixe derrière la barre d'état.
- **Icône PROVISOIRE** : le logo (quatre capsules pastel) sur noir —
  `python tool/gen_icone.py` puis `dart run flutter_launcher_icons`. À
  remplacer si l'utilisateur fournit un dessin.

### Scène d'ouverture (`lib/widgets/scene_ouverture.dart`)

Une fois par lancement (activée par `main`), sur le noir OLED, le logo se
compose **en mesure** : les quatre capsules naissent en décompte
(« 1, 2, 3, 4 » : un point qui éclot toutes les 110 ms), chacune s'étire
aussitôt à sa hauteur avec un ressort d'égaliseur, puis un **pouls** — double
battement « boum-boum » — les parcourt de gauche à droite ; « Rhythm » monte
en fondu PENDANT les derniers étirements (recouvrement, leçon MyTV). Un
instant immobile, puis tout s'efface en grandissant (×1,06) pendant que
l'accueil entre (signal `SceneOuverture.ouvert`). ≈ 2,75 s ; toutes les
durées en tête du widget. Le splash SYSTÈME est un simple noir, icône
transparente (`values-v31` ET `values-night-v31`) — rien n'est joué dans le
splash d'Android (leçon de Studio : zoom de l'icône Samsung par-dessus, et
coupure à 1 s).

### Entrée de l'accueil (`lib/ecrans/coquille/entree_accueil.dart`)

La partition, en un seul endroit (méthode Net Worth), sur 1,4 s : chaque
bloc monte de 20 px en fondu, en cascade (en-tête, verset, les quatre
cases une à une, séance ; pas 0,05, durée 0,45 — les fondus se
chevauchent) ; la barre monte du bas SANS fondu (flou) ; la croix de la
grille se trace depuis son centre (0,12 → 0,62) ; les anneaux se tracent et
les chiffres comptent (0,22 → 0,86) ; les pastilles des habitudes faites
s'allument une à une. Jamais rejouée au retour sur l'accueil (bascule
d'onglet = fondu + 12 px, 240 ms, comme MyTV / Net Worth / Studio).

---

## 3 bis. Les Habitudes, vivantes (24 septembre 2026)

Demande : « un système avec rappels activables (notifications), streak, des
outils pour davantage nous motiver, des textes de motivation adaptés, un
système qui permet même d'assister afin de combattre des addictions ».

- **Deux genres** (`modele/habitudes.dart`) : **à construire** (prévue
  certains jours, cochée — série, record, taux, historique) et **à
  libérer** (une dépendance : pas de coche, un COMPTEUR depuis le début
  déclaré ou la dernière rechute ; journal des envies ; rechutes ;
  économies si un coût par jour est donné). Les deux portent la
  motivation : pourquoi, plan si-alors (« Quand …, je … »), version
  minimale (construire), alternatives et déclencheurs (libérer).
- **Règles des séries** (`modele/calculs_habitudes.dart`, celles de Flow) :
  aujourd'hui TOLÉRÉ (pas encore coché ne casse rien) ; un jour non prévu ne
  casse rien (fait quand même : bonus compté) ; rien avant la création
  (cocher un jour antérieur recule la création). **Journée complète** =
  toutes les habitudes à construire prévues ce jour-là faites ; la série de
  l'écran et de l'accueil compte les journées complètes d'affilée. Les
  libérations n'entrent jamais dans les journées (une rechute ne casse pas
  la série des autres). Paliers : 3, 7, 14, 21, 30, 50, 66 (automatisme
  moyen, Lally 2009), 100… ; libération : 1 j, 3 j, 1 à 3 sem., 1, 2, 3,
  6 mois, 1 an.
- **Écran**, de haut en bas : l'en-tête ; « + Nouvelle habitude » (capsule
  blanche) et « Rappels » (cerclée), à portée de pouce ; le mot du jour ;
  la LIBÉRATION en tête (`BlocLiberation`, le même que sur l'accueil) ; la
  semaine ; la série ; la liste du jour et son ORDRE — « Mon ordre »
  (maintenir une ligne la soulève — léger grossissement, ni ombre ni lueur
  — et la déplace ; `ReorderableListView` à `onReorderItem`, sans
  poignée) ou « Par heure » (de rappel, sans rappel à la fin) ; l'ÉPINGLÉE
  (une seule, épingle de la fiche) toujours en tête, une épingle menthe à
  côté du nom. Ordre, tri et épingle persistés (`ReglagesHabitudes`).
- Le « mot du jour » (`l10n/libelles_habitudes.dart` : palier
  atteint > journée complète > « jamais deux fois » > le moment de la
  journée > la progression ; variante stable dans la journée, formes
  neutres) ; la semaine (toucher un jour passé l'affiche, on coche après
  coup) ; la série ; les lignes — le CERCLE coche (retour tactile, toast et
  vibration forte aux paliers et à la journée complète), la LIGNE ouvre la
  fiche ; « Les autres jours » ; « Libération » (compteur vivant,
  « Envie ? ») ; « Nouvelle habitude ».
- **Accueil** : le VERSET du jour en premier (demande de l'utilisateur :
  « au-dessus des 4 sections »), puis la GRILLE des quatre cases, le CŒUR de l'accueil
  — RESSERRÉE le 25 sept. (l'utilisateur : « les 4 grosses cartes, essaye
  de réduire ») : le pictogramme DANS l'anneau (40), le libellé à côté, le
  chiffre (24) et le détail dessous, écart 14 ; ≈ 30 % moins haute. La case
  Habitudes est un ANNEAU SEGMENTÉ (`AnneauSegmente`, un arc par habitude
  du jour, menthe = faite, les arcs se déroulent à l'entrée) ; la case
  Sports vit (journal, objectif du profil). Puis la **LIBÉRATION** (depuis que le verset est
  remonté, seul son titre paraît à l'ouverture sur le S26) — pour
  chaque libération les jours en grand (ils comptent à l'entrée, rang 6 de
  la partition), le nom et les heures qui vivent, la jauge et le prochain
  palier, « Envie ? » qui ouvre le soutien ; la ligne mène à la fiche.
  Puis la séance. Sans libération : une invitation discrète EN
  BAS (« Me libérer d'une dépendance » → formulaire déjà sur « Me
  libérer »).
- **Fiche** : stats, jauge du prochain palier, historique de 13 semaines
  (toucher un jour passé le coche) ; libérer : grand compteur à la seconde,
  record, économies, envies surmontées, journal et ce qu'il apprend (moment
  et déclencheur les plus fréquents) — MAINTENIR une entrée propose de la
  retirer (une rechute notée par erreur : le compteur retrouve sa
  période) —, « J'ai rechuté ». En haut : l'épingle et le crayon.
- **« J'ai une envie »** (`envie_ecran.dart`) : l'envie est une vague
  (< 15 min) ; respiration guidée 5 s / 5 s (animations réduites : disque
  immobile, consigne qui alterne quand même) ; attendre 10 minutes (anneau) ;
  ses raisons ; alternatives ; verset de force (LSG,
  `modele/versets_encouragement.dart`) ; appeler un proche (Rappels),
  Info-Social 811, 9-8-8, 911 ; noter intensité + déclencheur ; « J'ai
  tenu » → fête sobre ; « J'ai rechuté » → JAMAIS de reproche : ce qui a été
  tenu reste acquis, verset pour se relever, remise à zéro en deux temps
  (bouton blanc, pas corail), « Recommencer maintenant ».
- **Formulaire** : genre (création seulement), nom, précision, couleur,
  lettre, jours, rappel (ROULETTES heures / minutes de 5 en 5 —
  `RouletteHeure` ; les compteurs − / + d'avant passaient à la ligne à
  20 h et plus, et les minutes s'emballaient), pourquoi, plan, version
  minimale ; libérer : depuis quand, coût par jour, alternatives et
  déclencheurs (capsules + suggestions). Supprimer en deux temps. Activer
  le rappel demande l'autorisation d'Android tout de suite ; bloquée, une
  alerte corail et « Activer ».
- **Clavier** : il ne se ferme plus au premier toucher ailleurs — seulement
  en touchant un VIDE de la page (`PageSecondaire`), défiler le garde
  ouvert ; toute la hauteur d'un champ (filet compris) donne le focus.
- **Rappels** (la cloche de l'accueil, ou « Rappels et notifications » en
  bas des Habitudes) : NOTIFICATIONS (leur état dans Android ; « Activer »
  = la demande d'Android, puis ses réglages si refusées ; activées,
  « Réglages » mène aux canaux), interrupteur général, heure de chaque
  habitude, bilan du soir, personnes de confiance, promesse de discrétion.
- **Notifications** (`systeme/`, service de Studio repris) : instants
  absolus en UTC, alarmes inexactes, replanifiées EN BLOC à chaque
  changement / au retour / au lancement (10 jours d'avance). Rappel d'une
  habitude = les jours prévus, pas si déjà faite ; son texte = la série
  (aujourd'hui), le plan, la version minimale, sinon le pourquoi. Bilan du
  soir = ce qui reste (rien s'il ne reste rien). Cocher retire le rappel du
  jour déjà affiché (identifiant stable, FNV-1a). Toucher une notification
  ouvre les Habitudes. Autorisation demandée à la PREMIÈRE activation d'un
  rappel, jamais au lancement.
- ⛔ **DISCRÉTION des libérations** : aucune notification ne nomme ce dont
  on se libère (titre « Rhythm », canal « Soutien discret » en visibilité
  PRIVÉE sur l'écran verrouillé) — testé. Tout reste sur le téléphone.
- **Persistance** : `modele/depot.dart` (SQLite, repris de Studio / Net
  Worth), `<documents>/rhythm/rhythm.db`, emporté par la sauvegarde
  d'Android ; une famille absente du document n'est pas touchée (chaque
  module écrira les siennes). Premier lancement : les six habitudes de la
  maquette, SANS historique, une seule fois. Sans dépôt (tests, captures) :
  la DÉMONSTRATION (`GraineHabitudes.demonstration`) — deux mois
  d'historique qui retombent sur la maquette (4 sur 6, 12 d'affilée, record
  21) et une libération (« Boissons énergisantes »).
- « Maintenant » (`aujourdhuiProvider`) est rafraîchi au retour dans l'app
  et à chaque changement de tranche (5, 12, 18, 23 h) ou de jour
  (`systeme/synchro.dart`) ; l'heure exacte des compteurs vient de
  `horlogeProvider` (fixée par les tests et les captures).

---

## 3 ter. Les Sports, vivants (25 septembre 2026 — CONCLUS)

Section CONCLUE le 25 sept. 2026 à la demande de l'utilisateur (« on
conclut sport ») : ce qui reste est à éprouver sur le téléphone (§ 6) ;
on n'y revient que sur ses retours.

Demande : une grande banque d'exercices HORS LIGNE, sans IA, un
constructeur qui organise la séance avec des règles d'entraînement
classiques, la séance guidée, le cardio, les statistiques, et « tes autres
idées » (récupération, lien Habitudes, défis, routines, mesures). « Les
exercices animés doivent être plus représentatifs du corps humain, les
baguettes de bonhommes, ça ne le fait pas. »

- **Le corps humain, en 3D** (refait le 25 sept. 2026 ; l'utilisateur :
  « parfois on ne voit pas les membres, des bugs d'affichage — je veux la
  représentation très fidèle, très naturelle ») :
  - `squelette3.dart` : un squelette 3D (x avant, y bas, z vers nous) posé
    par DIRECTIONS absolues (0 avant, 90 bas, −90 haut, 180 arrière) + un
    ÉCART hors du plan par segment, torsion, inclinaison, ROULIS (le corps
    couché sur le côté : planche latérale), haussement d'épaules, poignets.
    Les mains et les pieds se PLANTENT par des cibles (`Cible`, cinématique
    inverse à deux segments, le coude / genou poussé vers un pôle) : plus
    de pieds qui glissent ni de mains qui traversent le sol.
  - `peintre3.dart` : caméra orthographique de trois quarts (`Camera3` :
    profil 25°, face 68°, dos −35°, et **dessus** — une PLONGÉE de 24° pour
    les corps couchés, le sol devient une nappe) ; le CORPS est une PEAU
    MAILLÉE (`peau3.dart`), peinte triangle par triangle du plus loin au
    plus proche (le membre loin passe DERRIÈRE le corps) ; le matériel se
    glisse à sa profondeur parmi ces triangles. Matériel en 3D (haltères, barres, kettlebells
    — une par main si besoin —, banc, dossier, barre fixe, caisse, mur,
    vélo, corde qui tourne, élastiques : sous les pieds, accrochés de
    chaque côté ou sur le côté (`elastiqueZ`), entre les mains, mini-bande).
  - **La peau** (`peau3.dart` + `peau/`, refaite le 25 sept. 2026 ;
    l'utilisateur : « on dirait un jouet en caoutchouc, monté de toutes
    pièces », puis « comme un vrai humain, muscle, articulation, visage,
    cheveux ») : les FORMES (`tronc` balayé le long du dos, section un peu
    carrée, anatomie du torse, short ; `membres` d'un seul tenant de
    l'épaule / la hanche au poignet / la cheville, qui se PLIENT en arc et
    se TASSENT dans le pli, muscles qui se contractent, la hanche « en
    short » — chaque jambe part de la taille ; `tete` lissée par étages,
    mandibule en U, nez, lèvres, yeux qui clignent, sourcils, oreilles,
    cheveux courts ; `mains` en gant — paume, quatre doigts, pouce — qui
    TIENNENT la poignée, se posent à plat ou restent libres ; `extremites` :
    la chaussure qui se plie à la plante), les GRILLES de sommets
    (`grille`), la SOUDURE des parties sur leur union lisse (épaules,
    hanches, entrejambe, cou : `_souderTout` — ce qui est enfoui dans
    l'autre n'est pas peint), le RENDU (`rendu` : lumière de studio liée à
    la caméra, peau, occlusion par capsules), les muscles travaillés en
    fuseaux corail collés à la peau.
  - **Le PLI DU COU** (`_pliCou`, `outils.dart`, 25 sept. 2026) : le cou
    passe de la ligne du dos à l'axe de la tête en UN virage en C, centré
    sur la base du cou, étalé sur ± 0,026 (son rayon dépasse celui du
    cou) ; les anneaux du cou ont fini de tourner sous le menton (0,018),
    au-dessus seul le centre finit la courbe ; le haut du tronc suit le
    même virage en se CISAILLANT (ses anneaux, bien plus larges, ne
    tournent pas). Avant : un S serré — tête pendante (chat-vache, pont),
    le cou se froissait.
  - **Les volumes lus PAR PLANS** (`_Tube(parPlans: true)`, `grille.dart`) :
    au cou et aux épaules, chaque anneau se lit dans son propre plan (un
    point est situé entre deux plans voisins) et une partie s'arrête NET à
    son dernier anneau. Lu en travers de l'axe, un anneau incliné paraît
    plus étroit : une partie se croyait enfouie dans une autre trop mince
    et se cachait — trous à la nuque et à l'aisselle (bras levé).
  - Juger la peau : `test/outils/portrait_corps_test.dart` (un mouvement en
    grand, `ZOOM=tete|visage|haut|mains|epaule|coude|genou|bassin|pieds`,
    `INSTANT` en pour mille, `LACETS`, `DEBOGAGE=true` — une couleur par
    partie : ce qui manque ou s'entrelace se voit), `inspection_corps_test`
    (`INSPECTER=1` : les 208 mouvements image par image — pointes, plis
    retournés, étirements, les pires cas et l'articulation la plus proche ;
    comparer AVANT / APRÈS une retouche), `perf_corps_test`
    (`PERF=true` : ≈ 8 à 9 ms une grande figure, ≈ 2 ms une miniature, en
    JIT).
  - `figure_exercice.dart` : IMAGES CLÉS (`Cle` : durée, COURBE — on
    descend en contrôlant, on remonte vivement —, tenue) ; `_relier` fait
    GLISSER un membre d'une clé tenue par une cible à une clé libre (sans
    lui, le membre sautait à mi-chemin). `animationDe` adapte la charge au
    matériel de l'exercice ; `cadreDe` cadre sur ce que le corps occupe
    VU PAR SA CAMÉRA (hauteur et largeur).
  - **208 mouvements**, une famille par fichier (`mouvements/` : jambes,
    poussee, tirage, tronc, cardio, mobilite, variantes ; outils communs :
    `_pose`, `_pieds`, `_serie` (le tempo d'une répétition), `_suite`,
    `_gaine` (corps gainé des pointes aux épaules), `_pompe`, `_allure`
    (marche, course, montées de genoux… : de vraies foulées, le sol qui
    défile, bras opposés), `_mainsNuque`, `_mainsTempes`). 67 exercices
    du catalogue ont reçu leur mouvement DÉDIÉ (pompe archer, dips jambes
    tendues, planches latérales, Pallof, squat cosaque…).
  - Juger une pose = la RENDRE : `test/outils/corps_test.dart`
    (`MOUVEMENTS=id,id`, `INSTANTS=8`, `TAILLE=180` ; cadré comme dans
    l'app). Muscle, l'énumération, vit dans le MODÈLE
    (`modele/sports/muscles.dart` : gros / petit, articulations, opposé).
- **La banque** (`modele/sports/catalogue/*.dart`, `catalogue.dart`) :
  **254 exercices** — jambes, poussée, tirage, tronc, cardio / HIIT,
  mobilité, variantes —, chacun : style (6), muscles principaux et
  secondaires (15), matériel (haltères, barre, kettlebell, élastique, barre
  de traction, banc, chaise / marche, corde, vélo), poly / isolation,
  niveau, répétitions ou durée, de chaque côté, étapes, erreurs,
  respiration (par famille), MET, intensité. Les VARIANTES sont des
  CHAÎNES (plus facile → plus dur : pompes contre le mur → inclinées → sur
  les genoux → pompes → déclinées → archer → claquées), un exercice sur une
  seule. Contenu en français (donnée), apostrophes droites, insécables
  avant « : ; ? ! » et entre un nombre et son unité.
- **Les règles** (`calculs_sport.dart`, pures, testées) : DOSAGE (force
  4-6 / repos long ; volume 8-12 / 60-90 s ; endurance 15-20 / court),
  ORDRE (poly et lourds d'abord, gros avant petits, gainage à la fin),
  PAIRES d'opposés sans repos (A1 / A2, 15 s entre, repos après la paire —
  `deroulement.dart` alterne leurs séries), ÉCHAUFFEMENT par articulation
  sollicitée (≈ 5 min), RETOUR AU CALME qui étire les plus travaillés,
  « COMPLÉTER » (une par zone, polyarticulaire et chargé d'abord, gainage
  pour le tronc, hors récupération, au niveau), durée estimée, séries par
  muscle, PROGRESSION (double progression : +1 répétition, en haut de la
  plage +charge — barre 2,5, haltères 2, kettlebell 4 — ; échec : pareil ;
  en durée +5 s), RECORDS (charge, répétitions, force estimée Epley, durée ;
  la première fois n'en est pas un), RÉCUPÉRATION (≥ 3 séries lourdes en
  principal < 48 h), semaine, série de semaines, stats sur 30 jours et
  muscles négligés (≥ 7 jours, secondaires compris), calories (MET × poids
  × durée ; cardio selon la vitesse).
- **Écrans** (`ecrans/sports/`) : l'onglet (le haut de la maquette,
  VIVANT ; séance du jour + Commencer, ou la prochaine ; Créer une séance,
  Exercices, Statistiques ; récupération ; course / marche / vélo /
  fractionné et le programme en cours ; mes séances ; défis ; routines
  express ; journal ; mesures ; matériel et objectifs) — banque (recherche,
  « Avec mon matériel » actif d'emblée, sans matériel, style, muscle ;
  liste PARESSEUSE en slivers ; demande le matériel UNE fois ; mode
  sélection) — fiche — constructeur (SILHOUETTE face / dos touchable,
  `widgets/corps/silhouette.dart`, récupération hachurée) — aperçu
  (retouches : toucher ouvre, maintenir déplace ; enregistrer : nom, jours,
  heure, rappel) — séance guidée (proposition pré-remplie, repos en
  anneau, +15 s, ressenti, 3-2-1 en clics, vibration forte à la fin,
  « Change de côté » à mi-temps, record annoncé, résumé, enregistrement)
  — cardio (chrono, pause ; distance notée à la fin — PAS de GPS ;
  fractionné avec signaux) — plans (fractionnés, programmes progressifs
  « Courir 30 min en 8 semaines », marche, vélo ; défis de 4 semaines : 100
  pompes, 150 squats, gainage 3 min, 5 km, 50 burpees) — stats 30 jours
  (barres, calendrier, styles, silhouette colorée, négligés, records) —
  mesures (poids, tour de taille, courbes) — journal.
- Pas de feuilles modales ni de dialogues dans Rhythm : des pages
  secondaires, et pour « Arrêter la séance ? » un VOILE dans l'écran.
- **Temps** : lu à `horlogeProvider` (jamais en comptant des images) ;
  l'écran reste ALLUMÉ pendant une séance (`systeme/ecran_allume.dart`,
  `wakelock_plus`).
- **Liens** : enregistrer une séance COCHE l'habitude « Entraînement »
  (`hab-entrainement`, ou un nom qui contient « entraîn » / « sport »,
  réglable), valide l'étape d'un défi ou d'un programme de course ; les
  RAPPELS de séance (`systeme/rappels_sport.dart`, canal « Séances »,
  charge « sports » → l'onglet Sports ; coupés par l'interrupteur général ;
  réglables aussi dans Rappels).
- **Persistance** : trois tables (`programmesSport`, `journalSport`,
  `mesuresSport`) + réglages (`profilSport`, `defisSport`, `coursesSport`,
  `versionSport`), lecture TOLÉRANTE (aucun `as` forcé). Premier
  lancement : le profil (haltères, à confirmer une fois dans la banque) et
  « Haut du corps » aux haltères lundi et jeudi 18 h, sans rappel, sans
  historique. Démonstration (tests, captures) : deux mois qui retombent sur
  la maquette (45 / 0 / 60 / 42 min, 3 séances, 1 180 kcal, 5 semaines).

## 3 quater. L'Alimentation, palier par palier (25 septembre 2026)

Plan VALIDÉ par l'utilisateur (« implémente tout le reste bien propre ; je
teste à chaque palier et si tout est bon, on avance ») — il teste chaque
palier sur le téléphone, remonte les réparations, PUIS on passe au
suivant. **Pas d'import depuis À Table** (refusé). L'affichage de la
maquette lui plaît : on le garde, on l'enrichit sans s'en éloigner.

1. **Le socle** (LIVRÉ, validé) : profil et besoins, base d'aliments,
   journal vivant, eau, conseil du jour, mes produits.
2. **Les achats** (LIVRÉ, validé) : liste de courses (fusion des doublons : même aliment →
   les quantités s'additionnent, l'origine reste), MODE MAGASIN (écran
   allumé, rayons, panier avec prix, prix au poids, statut de taxe en un
   toucher, consigne 10 ¢ / 25 ¢ verre ≥ 500 ml, total à la caisse en
   direct, budget), taxes du QUÉBEC (TPS 5 % + TVQ 9,975 %, TROIS statuts :
   détaxé / TPS seulement / TPS + TVQ — depuis le 15 juillet 2026, plus de
   TVQ sur barres et mélanges granola, noix salées, pâtisseries à l'unité
   < 230 g ou paquet < 6, desserts glacés < 500 g, coupes de dessert
   < 425 g, plateaux de fruits / légumes coupés, papier hygiénique,
   mouchoirs — la TPS reste ; barème DATÉ embarqué + petit fichier public
   consulté une fois par mois), RANGEMENT GUIDÉ (où ranger, date proposée,
   comment conserver : guide embarqué ≈ 200 aliments d'après le
   Thermoguide du MAPAQ, l'IA pour le reste), GARDE-MANGER (frigo,
   congélateur, armoire, comptoir ; catégories préintégrées ; péremption,
   date d'ouverture, prix payé ; consommer, jeter — compteur de gaspillage
   —, déplacer au congélateur), rappels de péremption, réassort, historique
   des prix et prix unitaire, budget du mois.
3. **Les recettes** (LIVRÉ, à tester) : création à la main (moments multiples : déjeuner,
   dîner, collation, souper ; une collation peut être un produit acheté),
   macros calculées par la base, tri, MODE CUISINE (écran allumé, mise en
   place, étapes, minuteurs repérés dans le texte, portions ajustables,
   « C'est prêt » → journal, garde-manger décompté, restes), « À la
   liste », PLANIFICATION sur 7 jours (liste de la semaine moins le
   garde-manger, rappel de décongélation la veille), cuisine en lot.
4. **L'IA** (LIVRÉ, à tester — Groq, comme Studio / Net Worth — gratuit,
   en ligne ; la permission INTERNET ajoutée) : bilan de la semaine,
   idées de repas → livre / plan / liste (macros RECALCULÉES par la base),
   planifier la semaine, anti-gaspillage, combler l'écart du soir,
   estimer un repas sans recette, importer une recette collée,
   substitutions, conservation d'un aliment hors guide. Tout ce qui est
   CHIFFRÉ reste calculé sur le téléphone ; jamais de taxe décidée par
   l'IA ; jamais de libération ni de nom envoyés ; pas d'avis médical.
   **Demandé le 25 sept. 2026 (pour ce palier)** : la GÉNÉRATION DE
   RECETTES laisse CHOISIR LA RÉGION (la cuisine : québécoise, haïtienne,
   italienne… — `kRegionsCulinaires`, déjà au formulaire des recettes :
   16 GRANDES RÉGIONS et leurs cuisines, `ChoixRegion`) et
   LE TYPE DE REPAS (le moment : déjeuner, dîner, collation, souper — à
   préciser avec l'utilisateur : aussi la catégorie, soupe / plat /
   dessert ?) avant de générer ; la recette générée entre au livre avec sa
   région et ses moments, ses macros recalculées par la base.
5. **Les finitions du plan** (LIVRÉ le 25 sept. 2026, à tester) : ce que
   le plan validé promettait et que les paliers 1 à 4 n'avaient pas fait
   (l'utilisateur : « passe au lot 5 » — il n'était pas écrit).
6. **Le scan et le barème en ligne** (LIVRÉ le 25 sept. 2026, à tester) :
   ce qui restait du plan (l'utilisateur : « continue sur ce qui manque ;
   et on pourra passer à Biblique »).

### Lot 5 — les finitions du plan (livré le 25 sept. 2026)

- **Mon assiette** (`modele/alimentation/assiette.dart`, pur, testé ;
  `ecrans/alimentation/assiette_ecran.dart`) : l'assiette du GUIDE
  ALIMENTAIRE CANADIEN — ½ légumes et fruits, ¼ protéinés, ¼ grains
  (entiers de préférence). Chaque aliment est rangé d'après son GROUPE du
  FCÉN et son nom (`categorieDe`), ou HORS de l'assiette : à limiter
  (sucreries, grignotines 25, restauration rapide 21, pâtisseries, jus,
  boissons sucrées ou alcoolisées), neutre (gras, sauces, épices, eau,
  café, thé, LAIT À BOIRE), non réparti (entrée rapide, plat composé 22,
  soupe, recette effacée). Une recette se répartit ingrédient par
  ingrédient ; un produit comme l'aliment le plus proche de son nom
  (`procheDe`, en retirant des mots). Mesure = le POIDS ; grains et
  légumineuses secs × 2,5 (cuits). Conseil : la part la plus loin (< 60 %
  de la visée), puis à limiter > 25 %, puis < 80 %, puis grains entiers
  < 50 %, sinon équilibrée ; < 100 g : « trop peu ». Sur l'onglet, une
  ligne sous l'eau (petite assiette dessinée — `AssietteDessin` : moitié
  gauche, protéinés en haut à droite, grains en bas à droite, remplies en
  SURFACE, séparées d'un trait noir). L'écran : grand dessin, la phrase,
  les trois parts (atteint sur visé), grains entiers, à limiter, non
  réparti, le détail par part, les 7 jours, ce que dit le Guide.
- **Ma semaine** : le TOTAL PRÉVU du jour choisi à côté des objectifs
  (`totalPrevuDu` : noté + prévus pas encore notés ; « autre chose » ne se
  chiffre pas) — kcal, jauge, trois macros.
- **Recettes FAVORITES et ÉTIQUETTES** : `Recette.favorite`,
  `Recette.etiquettes` (`etiquettesPropres` : sans doublon à la casse et
  aux accents près) ; le cœur (`Picto.coeur`, `plein`) sur la fiche ; le
  tri « Favorites » ; une rangée d'étiquettes dans le livre (les plus
  portées d'abord) ; la recherche les lit ; au formulaire, des capsules
  (les siennes, celles du livre, `kEtiquettesProposees`) et un champ. Les
  8 recettes de départ ont leurs étiquettes ; démonstration : chili et bol
  au cœur.
- **Mes EMPLACEMENTS** (`Lieu` : nom + genre, dans `ReglagesCourses.lieux` ;
  `ArticleGardeManger.lieuId`) : « Congélateur du sous-sol », « Cave »…
  chacun suit les règles de conservation de son GENRE (l'`emplacement` de
  l'article reste le genre : toute la logique de dates est inchangée).
  `ChoixEmplacement` propose les lieux sous les quatre (`onLieu`) ;
  déplacer d'un lieu à un autre du même genre garde la date ; changer le
  genre d'un lieu déplace ce qui y est ; le retirer rend ses aliments à
  son genre. Filtre du garde-manger par lieu ; « Mes emplacements » en bas
  du garde-manger (`courses/lieux_ecran.dart`) ; `ouEstRange` affiche le
  lieu partout.
- **Mode cuisine** : « Remplacer un ingrédient » sous la mise en place
  (l'IA) ; le mode cuisine lit la recette À JOUR (un ingrédient remplacé
  y paraît aussitôt).
- Démonstration : le gruau du journal vient maintenant de la base (1414,
  250 g) — l'assiette de la maquette dit « Il manque des légumes et des
  fruits » (le bol, entrée rapide, reste non réparti).
- Le scan de code-barres et le barème en ligne : le lot 6.

### Lot 6 — le scan et le barème en ligne (livré le 25 sept. 2026)

- **Le SCAN d'un produit** (`ecrans/alimentation/scanner_ecran.dart`,
  extension `mobile_scanner` 7.4.2 — la première à suivre l'Android
  Gradle Plugin 9 ; caméra + ML Kit, lecture SUR le téléphone ; la
  permission CAMERA vient de l'extension, `NSCameraUsageDescription` pour
  iOS) : EAN-13, EAN-8, UPC-A, UPC-E. Le code est CONTRÔLÉ et ramené à un
  seul format (`normaliserCode`, `modele/alimentation/open_food_facts.dart` :
  clé GS1 ; un UPC-A devient l'EAN-13 du même produit, un UPC-E est déplié
  quand la caméra le dit — il passe parfois aussi la clé d'un EAN-8).
  Puis : un produit DÉJÀ dans « Mes produits » (même code,
  `Produit.codeBarres`, `produitDuCode`) s'ouvre aussitôt, HORS LIGNE ;
  sinon le code — seulement lui — part à OPEN FOOD FACTS
  (`systeme/open_food_facts.dart`, API v2, sans clé, `User-Agent` de
  Rhythm, `ServiceOff.instance` remplaçable) ; la réponse est lue sans
  rien inventer (`brouillonDepuisOff` : nom français d'abord, première
  marque, la PORTION de l'emballage — valeurs « _serving », sinon les 100 g
  à la règle de trois —, sinon 100 g ; kJ → kcal, sel → sodium, sodium en
  mg) et ouvre le FORMULAIRE pré-rempli (« Rempli par Open Food Facts :
  vérifie avec l'étiquette ») ; inconnu : « Le créer à la main », son code
  gardé. Depuis « Noter un repas », le produit enregistré enchaîne sur SA
  PORTION (`ProduitFormulaireEcran.apres`) ; depuis « Mes produits », il
  y reste. Sans caméra (refusée, absente) : les chiffres se tapent sous le
  cadre. La caméra s'arrête pendant la recherche et quand l'app passe
  derrière ; « Lampe ». Le cadre : quatre coins, ni boîte ni lueur.
  Entrées : « Scanner un produit » (capsule, Mes produits), « Scanner un
  code-barres » (Noter un repas).
- **Le BARÈME en ligne** : `donnees/baremes_quebec.json` dans le dépôt
  (PUBLIC), lu à `kUrlBaremes` (raw.githubusercontent, branche `main`) au
  plus une fois par MOIS (`baremesAVerifier`, 30 jours ; horloge reculée →
  relu), au lancement et au retour dans l'app (`synchro.dart`,
  `systeme/baremes_en_ligne.dart`) ; les barèmes reçus et la date sont
  gardés (`ReglagesCourses.baremesEnLigne` / `baremesVerifies`) et
  s'AJOUTENT aux embarqués (`reglages.baremes`, passé à chaque
  `baremeAu`). Seuls les TAUX changent ainsi (taux invraisemblables
  refusés) ; ce qui est détaxé reste dans l'app. Sans réseau ou fichier
  abîmé : rien ne change. L'écran des taxes dit « Taux vérifiés en ligne
  le … ». Un changement de taux = une ligne datée ajoutée au fichier, sur
  `main`.
- Pas éprouvé hors des tests (le réseau du conteneur cloud refusait
  Open Food Facts et le SDK Android) : la caméra, un vrai appel à Open
  Food Facts, la construction de l'APK avec l'extension.

### Palier 1 — le socle (livré le 25 sept. 2026)

- **La base d'aliments** (`modele/alimentation/base_aliments.dart`) : le
  FICHIER CANADIEN SUR LES ÉLÉMENTS NUTRITIFS 2026 (Santé Canada, Licence
  du gouvernement ouvert – Canada), réduit par `tool/extraire_fcen.py` à
  `assets/donnees/fcen.txt` (5 894 aliments, noms FRANÇAIS, 8 nutriments
  pour 100 g, les portions du FCÉN type 6 ; bébés exclus ; 743 Ko). Lue une
  fois dans un isolat (`baseAlimentsProvider` ; les tests la lisent
  directement et la surchargent). RECHERCHE tolérante (accents, « œ »,
  pluriels, mots vides) et CLASSÉE (déjà mangé d'abord, première partie du
  nom = le mot cherché, noms courts, sans marque ; crus pour fruits et
  légumes, cuits pour céréales et légumineuses). Source :
  https://open.canada.ca/data/dataset/1b6139bd-ed7e-4043-bc28-ff00e10f3109
- **Les règles** (`calculs_alimentation.dart`, pures, testées) :
  Mifflin-St Jeor × activité HORS sport (assis 1,2 / debout 1,35 /
  physique 1,55) + séances (MOYENNE des 14 jours, lue dans les Sports) ±
  objectif (7 700 kcal / kg : 0,25 kg / sem = 275 kcal / j) + AJUSTEMENT
  AUTOMATIQUE (21 jours : ≥ 10 journées notées — 2 aliments et 1 000 kcal —
  et 3 pesées sur 10 jours ; dépense réelle = apport moyen − tendance du
  poids × 7 700 ; la MOITIÉ de l'écart, ± 400) ; plancher : métabolisme ×
  1,1, 1 500 (H) / 1 200 (F). Macros : protéines 2,0 / 1,6 / 1,8 g/kg
  (perdre / maintenir / prendre), lipides 30 % (25 % un jour de séance),
  ≥ 0,8 g/kg, glucides le reste. Eau : 35 ml/kg × 80 % en verres de 250 ml
  (6 à 16) + 1 par demi-heure de sport du jour. Profil incomplet :
  ESTIMATION (âge 30, taille moyenne, poids 70). Objectifs fixables à la
  main. Le poids = la dernière pesée des MESURES des Sports (une source).
- **Le journal** : une entrée = un aliment (base / produit / entrée
  rapide), sa quantité (grammes, ou portions + libellé), ses nutriments
  FIGÉS à la saisie ; modifier = règle de trois (sans la base).
- **L'onglet** : conseil du jour (Bricolage 19, comme le mot du jour des
  Habitudes ; « profil » → les objectifs), les 7 DERNIERS jours (aujourd'hui
  à droite ; point pêche = ≥ 90 % des calories ; toucher un jour l'affiche),
  l'anneau (toucher → objectifs ; « kcal de plus » au-delà), les macros,
  les repas (toucher → le repas ; « + » → noter, moment selon l'heure ;
  vide : « À planifier » à venir, « Rien de noté » passé), l'eau
  (TOUCHER un verre remplit jusqu'à lui, le dernier plein se vide ; un
  verre de plus apparaît une fois l'objectif atteint), Mes objectifs, Mes
  produits.
- **Écrans** (`ecrans/alimentation/`) : `noter_ecran` (moment, déjà dans
  le repas, recherche ; sans recherche : RÉCENTS avec « + » qui rajoute à
  l'identique, mes produits, entrée rapide ; l'écran RESTE OUVERT pour
  composer le repas), `portion_ecran` (aliment : portions du FCÉN — unités
  d'abord, « 1 moyen » choisi d'emblée —, 100 g, grammes tapés, nom au
  journal = le mot cherché ; produit : portions ; récent ; édition +
  « Retirer du repas » en deux temps), `entree_rapide_ecran`,
  `moment_ecran` (total, aliments, « Comme hier »), `objectifs_ecran`
  (résumé, objectif et rythme, moi, activité, LE CALCUL ligne par ligne,
  ajustement et son état, séances, eau, lien habitude, chiffres à la main,
  « pas un avis médical »), `produits_ecran`, `produit_formulaire_ecran`
  (l'ordre de l'étiquette canadienne), `pieces_alimentation`.
- **Liens** : l'objectif d'eau atteint COCHE « Boire 2 L d'eau »
  (`hab-eau`, ou un nom contenant « eau » ; réglable) ; l'accueil lit les
  vraies calories et l'objectif du jour.
- **Persistance** : trois tables (`journalAlim`, `produitsAlim`,
  `eauAlim` — id = cleJour) + `profilAlim`, `versionAlim` ; lecture
  TOLÉRANTE. Premier lancement : vide (profil à compléter). Démonstration
  (tests, captures) : la maquette (1 640 / 2 200 kcal ; 112 / 150, 190 /
  260, 48 / 70 g ; 5 verres sur 8 ; objectifs fixés à la main), 3 semaines
  d'historique, 2 produits.
- ⛔ Piège : un Notifier ne lit pas un provider qui dépend de LUI
  (`besoinsProvider` depuis `AlimentationNotifier` → CircularDependency) :
  `fixerEau` refait le calcul des verres avec les fonctions pures.

### Palier 2 — les achats (livré le 25 sept. 2026)

Validé par l'utilisateur après le palier 1 (« c'est bon, on passe au
palier 2 »). Tout HORS LIGNE (pas encore de permission INTERNET).

- **Taxes** (`modele/alimentation/taxes.dart`) : BARÈME DATÉ
  (`kBaremesQuebec`, `baremeAu` : un barème futur s'applique seul à sa
  date) ; trois statuts (`StatutTaxe` détaxé / TPS / TPS + TVQ) ; la
  CAISSE (`Caisse.de`) : TPS sur ce qui y est soumis, TVQ sur ce qui y est
  soumis, chacune arrondie au cent, consigne à part NON taxée ; la
  SUGGESTION (`suggererStatut` : exceptions de base — céréales, yogourt,
  lait au chocolat… —, puis des règles ordonnées — TVQ abolie le 15 juillet
  2026, « à l'unité » des pâtisseries, alcool, grignotines —, puis le
  rayon) et sa RAISON affichée : l'utilisateur APPLIQUE le statut (sa
  demande). Mise à jour en ligne PRÉVUE mais inactive : `kUrlBaremes` vide
  + `baremesDepuis` (taux invraisemblables refusés) — il faudra héberger
  un petit JSON et ajouter la permission INTERNET.
- **Rayons et saisie** (`rayons.dart`) : un dictionnaire d'expressions
  (17 rayons, entretien et hygiène compris), repli sur le groupe du FCÉN ;
  `lireSaisie` (« 2 kg poulet », « poulet 2 kg », « lait x2 », « 500 g de
  bœuf haché » ; « 7up » reste un nom) ; `cleArticle` (même article :
  « Bananes » = « banane »).
- **Expressions** (`expressions.dart`, partagé par le guide, les taxes,
  les rayons) : mots SIMPLIFIÉS et au SINGULIER des deux côtés
  (`singulier` : « noix », « riz », « jus » ne bougent pas ; « gateaux »
  → « gateau ») ; un mot de 3 lettres doit être identique (« ail » ≠
  « aile ») ; plus longue expression, puis la plus à DROITE.
- **Guide de conservation** (`conservation.dart`) : ≈ 120 aliments, les
  durées du THERMOGUIDE du MAPAQ (frigo 4 °C, congélateur −18 °C, ambiant,
  après ouverture), un conseil « où et comment » ; la date proposée prend
  la durée la plus COURTE ; ouvert → ne peut que raccourcir ; déplacé au
  congélateur → s'allonge ; décongelé au frigo → 1 à 2 jours. Repères
  par rayon sinon.
- **La liste** (`calculs_courses.dart`) : FUSION (même clé, pas au
  panier : quantités additionnées par famille — `Quantite.plus`, « 2 +
  150 g » sinon —, origines cumulées) ; « déjà au garde-manger » ;
  estimation d'après les derniers prix ; habituels (achetés ≥ 2 fois) ;
  historique et meilleur prix (au kg si au poids) ; dépensé du mois ;
  gaspillé du mois.
- **Écrans** (`ecrans/alimentation/courses/`) : `courses_ecran` (la liste :
  estimation, budget, « Au magasin », saisie + habituels, par rayon dans
  l'ordre du magasin), `article_liste_ecran`, `magasin_ecran` (écran
  ALLUMÉ, magasin en capsules, à prendre / dans le panier, imprévu, BARRE
  DE CAISSE fixe en bas, « Terminer » en deux temps → `remplacerEcran` vers
  le rangement), `panier_ecran` (unité ou AU POIDS kg / lb, dernier et
  meilleur prix, taxe + raison, consigne 0 / 10 / 25 ¢, la ligne en
  direct), `ranger_ecran` (emplacement en 4 capsules sur une ligne, date,
  conseil, essentiel, « Ne pas ranger »), `garde_manger_ecran` (filtre par
  emplacement, par date / par rayon), `article_garde_manger_ecran` (fiche
  ou ajout : échéance, comment le garder, où, date, ouvert, reste, fini /
  jeté / sur la liste / retirer), `achats_ecran` (mois par mois, détail
  de la caisse), `reglages_courses_ecran` (budget, magasins, ORDRE DES
  RAYONS réordonnable, rappels de péremption et leur heure), `taxes_ecran`.
- **L'onglet** : « À consommer bientôt » (3 jours) sous l'eau, puis Liste
  de courses et Garde-manger ; le CONSEIL DU JOUR passe d'abord par ce qui
  presse (« À consommer d'ici demain : épinards, yogourt grec (+1) »).
- **Réassort** : un ESSENTIEL fini ou jeté, s'il n'en reste plus, revient
  seul sur la liste (origine `kOrigineReassort`, affichée « revenu
  seul »).
- **Rappels de péremption** (`systeme/rappels_garde_manger.dart`, canal
  « Garde-manger », charge « alimentation » → l'onglet) : chaque matin à
  l'heure choisie (9 h), s'il y a des aliments à consommer aujourd'hui ou
  demain ; une date passée ne relance pas.
- **Persistance** : quatre tables (`listeCourses`, `gardeManger`,
  `achatsAlim`, `sortiesAlim`) + `reglagesCourses`, `versionCourses`.
  Premier lancement : vide (magasins du Québec par défaut). Démonstration :
  8 articles, 14 aliments (3 à consommer d'ici demain), 8 épiceries, 2
  aliments jetés, budget de 600 $.

### Palier 3 — les recettes (livré le 25 sept. 2026)

Validé par l'utilisateur après le palier 2 (« on attend le palier 4, go
pour le palier 3 »). Tout HORS LIGNE.

- **Le modèle** (`modele/alimentation/recettes.dart`) : [Ingredient] —
  base du FCÉN (code, grammes, `nombre` × `mesure` du FCÉN : « 2 × 1
  moyen », « 250 ml »), un de mes produits, ou LIBRE (sel, épices : sans
  valeur nutritive, quantité facultative) ; ses nutriments FIGÉS à la
  saisie (la recette se lit sans la base). [Recette] : moments
  (plusieurs), portions, ingrédients, étapes (une par entrée), préparation
  et cuisson, RÉGION (la cuisine d'où elle vient : une GRANDE RÉGION —
  « Afrique de l'Ouest » — ou l'une de ses cuisines — « Sénégalaise » ;
  `kRegionsCulinaires` = 16 `RegionCulinaire` : Amérique du Nord,
  Caraïbes, Amérique latine, les cinq Afriques — Ouest, Nord, centrale,
  Est, australe —, océan Indien, Europe, Moyen-Orient, Asie du Sud, Asie
  centrale et Caucase, Asie de l'Est, Asie du Sud-Est, Océanie ; demande
  de l'utilisateur, 25 sept. — l'ancienne « Ouest-africaine » est relue
  « Afrique de l'Ouest »), note, « se congèle bien », jours cuisinés. [RepasPrevu] : une recette, un
  produit (une collation achetée) ou « autre chose » (« Souper chez des
  amis »), un jour, un moment, des portions. [ReglagesRecettes] : portions
  d'un repas prévu (le foyer), rappel de décongélation et son heure (20 h),
  le tri du livre. Le journal a une source `recette` (`recetteId`,
  portions ; « 2 portions ») ; un article du garde-manger peut être des
  RESTES (`recetteId`, quantité = portions).
- **Les règles** (`calculs_recettes.dart`, pures, testées) : `lireEtapes`
  (une par ligne, sans numéro) ; `minuteursDans` (« 5 minutes », « 25 à 30
  min » → la plus courte, « 1 h 30 », « 1h15 », « 30 secondes », « une
  demi-heure » ; ni « 190 °C » ni « 2 carottes ») ; `quantiteDe` (ml
  restent des ml, « 1 moyen » se compte, une PARTIE — gousse, tranche,
  feuille… — en grammes : on n'achète pas 2 têtes d'ail ; sinon les
  grammes) ; `besoinsDe` (additionnés par aliment, MOINS le garde-manger et
  la liste — même famille d'unités ; un stock sans quantité ou compté
  autrement COUVRE ; l'eau jamais ; le PLACARD — huile, sauces, épices en
  petite quantité, sel et poivre — « à vérifier », pas coché ; arrondi à
  5 g / 5 ml, unités au-dessus) ; la SEMAINE (`recettesDeLaSemaine` : 7
  jours, repas pas encore notés, moins les RESTES, en LOTS d'une
  demi-recette : 3 portions d'une recette de 4 → une recette) ;
  `ingredientsPartages` (cuisine en lot : ce qui se prépare en une fois) ;
  `decompteGardeManger` (ce qu'il en restera ; sans quantité → « fini ? »
  à la main ; les restes n'y comptent pas) ; `restesJusquau` (Thermoguide :
  3 jours au frigo, 3 mois au congélateur) ; `decongelationsDu` (ce qu'un
  repas prévu demande et qui n'est QU'au congélateur — ou ses restes
  congelés) ; RÉGIONS (`grandeRegionDe`, `dansLaRegion` : « Sénégalaise »
  est en « Afrique de l'Ouest », à la casse et aux accents près) ;
  recherche (nom, région ET grande région, ingrédients) et TRI (récentes,
  A à Z, protéines, calories, rapides).
- **« Même aliment »** (`memeAliment`, `calculs_courses.dart`) : la clé
  recouvre l'autre (« lait » ↔ « lait 2 % ») ET le rayon deviné est le
  même — « beurre » ne décompte pas le « beurre d'arachide ».
- **Écrans** (`ecrans/alimentation/recettes/`) : `recettes_ecran` (le
  livre : Nouvelle recette, Ma semaine, recherche, moment / tri / région
  en rangées de capsules qui DÉFILENT de côté — `RangeePuces`, la capsule
  choisie ramenée dans la rangée à l'ouverture ; la région : les grandes
  régions du livre, puis leurs cuisines s'il y a de quoi choisir ; une
  capsule choisie, touchée de nouveau, se retire —, livre vide →
  « Recettes de départ »), `recette_ecran` (la fiche : par portion,
  temps, Cuisiner, À la liste, Planifier, Noter au journal, restes, portions
  ajustables dans le titre des ingrédients, menthe « déjà là », étapes aux
  minuteurs soulignés), `recette_formulaire_ecran` (nom, moments, ce
  qu'elle donne, temps, ingrédients, étapes UNE PAR LIGNE avec les
  minuteurs repérés en direct, région — `ChoixRegion` : « Aucune » puis
  les grandes régions, l'une choisie → ses cuisines ; toucher de nouveau la
  capsule choisie la RETIRE (une cuisine rend sa grande région, la grande
  région rend « aucune ») ; les régions tapées à la main reviennent en
  capsules —, note, se congèle, par
  portion en direct ; nouvelle → la fiche remplace le formulaire ;
  supprimer en deux temps → retour au livre, `retirerEcrans(context, 2)`),
  `ingredient_ecran` (chercher : produits puis FCÉN, « Ingrédient libre » ;
  quantité : portions du FCÉN par QUARTS ¼ ½ ¾, grammes ; modifier garde
  l'aliment, règle de trois ; rend un `ResultatIngredient`),
  `cuisine_ecran` (MODE CUISINE : écran allumé, portions, mise en place
  cochée — toute cochée, elle se replie, « Revoir » —, étapes une à une en
  Bricolage 23, minuteurs d'un toucher, toutes les étapes, « C'est
  prêt » ; « Précédente » / « Suivante » dans une BARRE FIXE en bas —
  `BarreCuisine`, les minuteurs en cours au-dessus — : une étape plus
  longue ou sans minuteur ne les fait plus SAUTER sous le doigt (retour de
  l'utilisateur, 25 sept.) ; « Précédente » toujours là, éteinte à la
  première étape ; l'étape changée hors de l'écran, la page défile jusqu'à
  elle ; l'étape ENTIÈRE — texte ET boutons de minuteur, `_Etape` — change
  en FONDU ENCHAÎNÉ (l'ancienne s'efface, puis la nouvelle paraît :
  jamais deux textes superposés) pendant que la hauteur du bloc GLISSE
  (`AnimatedSize`, 300 ms, les deux ensemble) : la liste des étapes
  descend ou remonte en douceur — retour de l'utilisateur : le minuteur
  disparaissait AVANT le texte, puis tout sautait à la fin du fondu), `pret_ecran` (j'en mange maintenant + moment → JOURNAL ; restes
  au frigo / au congélateur — d'emblée au congélateur pour un lot ≥ 4
  portions qui se congèle — / pas de restes ; garde-manger décompté, coché
  quand on le sait), `ajout_liste_ecran` (« À la liste » d'une recette ou
  de la semaine → `ajouterBesoins`, fusion + origines, puis la liste),
  `plan_ecran` (MA SEMAINE : 7 jours dès aujourd'hui, les 4 moments du
  jour choisi et leurs plats, « + » ; liste de la semaine, cuisine en lot,
  à décongeler ce soir ; portions par repas, rappel de décongélation +
  roulette), `choisir_plat_ecran`, `repas_prevu_ecran` (cuisiner, noter
  comme mangé — pris dans les restes —, voir la recette, DÉPLACER, retirer),
  `cuisine_lot_ecran`, `planifier_ecran`, `portion_recette_ecran`
  (portions par demi, « pris dans les restes »), `pieces_recettes`
  (`detailRecette`, `TexteEtape`, `BarreMinuteurs`, `SeptJours`,
  `RangeePuces`).
- **Minuteurs** (`minuteursProvider`, pas enregistrés) : ils survivent à
  l'écran ; le mode cuisine vérifie l'horloge toutes les 250 ms et
  sonne UNE fois (trois vibrations fortes + un mot) ; `synchro.dart` en
  fait des notifications (canal « Minuteurs de cuisine », jamais coupées)
  si l'app passe derrière — alarmes inexactes : quelques minutes de retard
  possibles hors de l'app.
- **Liens** : l'onglet (« Mes recettes », « Ma semaine · à décongeler ce
  soir » ; un repas vide dit « Prévu : … » ; le CONSEIL DU JOUR, dès 16 h,
  passe d'abord par la décongélation : « Ce soir, du congélateur au
  frigo : bœuf haché maigre (pour demain). ») ; un repas (section PRÉVU) ;
  « Noter un repas » (LES RESTES en tête, « + » = une portion ; mes
  recettes du moment ; recettes dans la recherche) ; la fiche d'un aliment
  du garde-manger (des restes : « Manger une portion ») ; rappels de
  décongélation (`systeme/rappels_recettes.dart`, canal « Décongélation »,
  la veille à 20 h ; coupés par l'interrupteur général ou le leur).
- **Persistance** : deux tables (`recettesAlim`, `planAlim` — le plan ne
  garde que le dernier mois) + `reglagesRecettes`, `versionRecettes` ;
  lecture TOLÉRANTE. Premier lancement : livre VIDE ; « Recettes de
  départ » ajoute d'un toucher 8 recettes (valeurs du FCÉN générées par un
  script depuis `fcen.txt`, insécables comprises) : gruau aux bleuets et à
  l'érable, omelette aux épinards, bol poulet riz légumes, chili sin carne,
  pâté chinois (québécoise), saumon et patates douces, smoothie protéiné,
  riz collé aux pois (haïtienne). Démonstration : ces 8, déjà cuisinées, et
  13 repas prévus de demain à J+6 (le souper d'aujourd'hui reste « À
  planifier », comme la maquette ; le pâté chinois de demain demande le
  bœuf haché congelé → décongélation ce soir).

### Palier 4 — l'IA (livré le 25 sept. 2026)

Lancé par l'utilisateur après le palier 3 (« on attend le palier 4 » puis
« conclus ») : l'ASSISTANT de l'Alimentation, EN LIGNE, seulement quand on
le sollicite — le reste de l'app ne sort jamais du téléphone.

- **Le service** (`lib/ia/service_ia.dart`, repris de Studio) : Groq,
  cascade `openai/gpt-oss-120b` → `gpt-oss-20b` (quotas séparés), deux
  essais par modèle, réponse forcée en JSON, erreurs typées (`ErreurIa` :
  quota, surcharge, réseau, sans clé…). `ServiceIa.instance` se remplace
  dans les tests (`test/outils/faux_ia.dart`, aucun réseau). Éprouvé sur
  le VRAI Groq (25 sept., suite 9) : le palier gratuit limite chaque
  modèle à **8 000 jetons PAR MINUTE** — une demande d'idées en prend
  5 000 à 6 000 (raisonnement compris) : deux de suite passent au modèle
  de secours ; les deux à bout, le service ATTEND le `retry-after` de Groq
  s'il est court (≤ 20 s, une fois), sinon l'erreur « quota » ; une
  réponse ILLISIBLE (rare, vue une fois sur six) est redemandée une fois.
  Délais mesurés : idées 7 à 11 s, semaine 5 à 8 s, écart ≈ 10 s, le
  reste 0,3 à 3 s.
- ⛔ **La CLÉ n'est PAS dans le code** (`lib/ia/cles_api.dart`) : elle
  vient de la construction, `--dart-define-from-file=cles.json`, où
  `cles.json` (à la racine, HORS du dépôt — `.gitignore`) contient
  `{"GROQ_CLE": "gsk_…"}` (la clé de Studio / Net Worth). Sans elle,
  l'assistant le dit (`ErreurIa.sansCle`) ; le reste de l'app marche.
- **Les règles** (`lib/ia/ia_alimentation.dart` — pour chaque demande :
  l'INVITE pure, l'appel, la LECTURE pure et tolérante, toutes testées) :
  rien de CHIFFRÉ ne vient de l'IA — elle nomme des aliments, des
  quantités et des MOTS-CLÉS du FCÉN ; ses « kcal » ne servent qu'à
  départager les candidats de la base ; rien de personnel ne part (ni nom,
  ni poids, âge, sexe, ni habitudes ni libérations — testé : seulement des
  aliments, des recettes, les objectifs du jour et perdre / maintenir /
  prendre) ; jamais de taxe ; pas d'avis médical (renvoi vers une
  diététiste-nutritionniste). Ses textes passent par `texteIa`
  (`lib/ia/texte_ia.dart` : sans Markdown ni emoji, apostrophes droites,
  « ≈ → ≥ ≤ » remplacés — absents des polices —, insécables françaises).
- **La correspondance** (`modele/alimentation/correspondance.dart`) :
  chaque aliment proposé est CHERCHÉ dans la base et chiffré par elle —
  une portion du FCÉN quand elle existe (« 2 × 1 gousse »), sinon les
  grammes estimés ; introuvable → ingrédient LIBRE, dit « hors de la
  base » (pas compté). `RecetteProposee` → une `Recette` du livre, région
  et moments vérifiés. **Refaite le 25 sept. (suite 9)** après les vrais
  appels et deux BALAYAGES (274 ingrédients et plats,
  `test/outils/balayage_correspondance_test.dart`) — le faux service ne
  montrait rien de tout ça. Les règles, dans l'ordre où elles jouent :
  - des MOTS ENTIERS (au pluriel ou au féminin près, `_meme`) : « pois »
    n'est pas « poisson », « vin » pas « vinaigre » (la note du journal,
    qui prend les débuts de mots, reçoit `egal: _meme`) ; « pâtes »
    (alimentaires) ≠ « pâte » (d'arachide, à pizza) ≠ « pâté » (sans
    accents, le même mot : `pateviande`) ; « partiellement écrémé » ≠
    « écrémé » ;
  - la NÉGATION des deux côtés : « sans X » / « non X » ne sont pas X
    (« Poulet, conserve, sans bouillon » ; « cuisse sans peau »), et
    « non salé » = « sans sel » (`_racine`) ; la COMPOSITION entre
    parenthèses ne compte pas (« Sauce, arachides (faite à partir de …
    sauce soya) ») ;
  - des SYNONYMES d'ici et de l'IA (`_synonymes` : cari, pois jaunes →
    cassés, riz basmati → blanc long, pâte d'arachide → beurre, butternut
    → musquée, haricots verts → italiens, chou vert → chou, baguette →
    pain français, lait évaporé → concentré, germes de soya → mungo…) ;
  - le NOM porte l'identité (sans ses mots de préparation — haché, frais,
    moulu, épi… —, qui restent dans les mots-clés) : un candidat en porte
    au moins la moitié ; un nom VAGUE (pâte, sauce, jus, huile, lait,
    feuille…) exige son complément ; un nom de PRODUIT (confiture,
    yogourt, fromage…) exige le produit ; un nom dont la base ne connaît
    aucun mot (« Mascarpone ») → hors de la base, pas « un fromage » ;
  - l'ÉTAT : cru (le FCÉN dit « sec » pour les grains : cru ≈ sec, mais
    l'état exact passe devant — raisins secs ≠ raisins crus ; « à sec »
    n'est pas un état) ; l'état contraire coûte cher (le riz d'une recette
    n'est pas « cuit à la vapeur ») ;
  - seulement si on les DEMANDE : les parties de la plante (feuilles,
    germes, graines, pelure), les versions allégées (sans gras, réduit en
    sodium, léger, écrémé), aromatisées (saveur, mélange, chocolat, miel,
    sucrée…), transformées (broyée, étuvée, marinée, barre), et ce qu'un
    aliment a « avec » / « au » / « aux » lui (un aliment de la base :
    « aux canneberges », pas « au soleil ») ;
  - la TÊTE (ce qu'est l'aliment) décrite par la proposition passe devant,
    sans les parenthèses ni un préfixe vague du FCÉN (« Épices, … »,
    « Boisson alcoolisée, … », « Jus, … », « Confiseries, … ») ; quelques
    ingrédients de base passent devant leurs variantes
    (`_ingredientsCourants` : riz blanc long sec, pâtes enrichies sèches,
    poitrine de poulet sans peau crue) ;
  - puis les CALORIES de l'IA départagent — elles sont souvent FAUSSES
    (2 tasses de pois secs « 170 kcal », 1 500 dans la base) : du simple
    au double (± 50 kcal seulement du tiers au triple), sinon la plus
    proche du tiers au triple ; quand le premier candidat est une
    correspondance FORTE (il porte le nom, sa tête est décrite), seules
    ses variantes (même tête) sont départagées, et à défaut il est pris
    tel quel — la base fait foi ;
  - une quantité en g ou ml bien plus petite que le poids estimé (« 2 » ml
    pour 2 tasses) : le poids estimé ; une taille que la base n'a pas
    (« 1 moyen », elle n'a que « 1 gros ») : le poids estimé, compté ;
    jamais une PARTIE non demandée (« 1 tranche moyenne » pour un oignon)
    ni « 1 portion du guide » ;
  - l'eau, la poudre à pâte, le bicarbonate : libres, même oubliés.
  Balayage final : 274 cas, 11 hors de la base (absents du FCÉN :
  mascarpone, gnocchis, boulghour, citronnelle, guacamole, tzatziki,
  kombucha, pancetta, feuilles de manioc, hamburger, shawarma), 4 écarts
  venus de l'estimation de l'IA.
- **Les invites**, retouchées après les vrais appels : la conservation ne
  donne plus d'exemple chiffré (le modèle recopiait « 3 à 5 jours / 60 à
  90 jours » pour le kimchi comme pour le tofu) ; les mots-clés disent
  « sec » pour les grains ; l'ESTIMATION garde entiers les plats courants
  que le FCÉN connaît (poutine, pizza, pad thaï, sushi, lasagne, chow
  mein…) et décompose le reste (pâté chinois, hamburger, hot-dog,
  sandwich) ; la semaine n'utilise les restes que pour autant de repas
  que leurs portions en donnent. Les ÉTAPES d'une idée (retour de
  l'utilisateur, 25 sept. : « trop courtes, comme si elle rush ») : la
  consigne disait « une action par étape » et « phrases courtes » — six
  lignes bâclées pour un thiéboudienne ; maintenant `_etapesDetaillees`
  (idées seulement) : 6 à 12 étapes d'une à trois phrases, la mise en
  place d'abord, l'ustensile, le feu ou le four, la durée (une par étape
  de préférence : les minuteurs), le signe que c'est prêt, les gestes qui
  font le plat, le service à la fin ; l'IMPORT garde les étapes du texte,
  toutes, sans en ajouter.
- **Le bilan** (`modele/alimentation/bilan_semaine.dart`) : les CHIFFRES
  de la semaine calculés sur le téléphone (journées NOTÉES seulement,
  fibres 25 g, sodium 2 300 mg — Santé Canada) ; l'IA les commente sans
  les recalculer. Trop d'entrées rapides (plus du quart des calories) :
  fibres et sodium INCONNUS — ni montrés (corrigé : l'écran les affichait
  à « 0 g »), ni commentés.
- **Écrans** (`ecrans/alimentation/ia/`) : `assistant_ecran` (la ligne
  « Assistant » de l'onglet ; chaque entrée dit ce qui la rend utile
  maintenant), `idees_ecran` (on choisit AVANT de générer : la RÉGION —
  `ChoixRegion`, grandes régions puis cuisines —, le MOMENT, le GENRE de
  plat — plat, soupe, salade, sandwich, bol, dessert, boisson —, les
  portions, rapide, protéiné, végétarien, avec mon garde-manger,
  précisions ; trois idées chiffrées par la base ; « Autres idées » n'en
  repropose aucune ; mode ANTI-GASPILLAGE depuis « À consommer
  bientôt »), `recette_proposee_ecran` (région, moments, par portion,
  ingrédients, étapes aux minuteurs ; « Ajouter à mon livre » → la fiche),
  `importer_ecran` (texte collé, « Coller » ; structuré SANS RIEN
  INVENTER), `ecart_ecran` (ce qui reste de la journée, trois options —
  une recette du livre ou ses restes, ou des aliments —, « Noter au
  journal »), `plan_ia_ecran` (les cases LIBRES des 7 jours avec MON
  LIVRE, restes d'abord ; cocher / décocher ; « Ajouter à ma semaine »),
  `estimer_ecran` (un repas décrit → aliments de la base, toucher une ligne
  la retire ; depuis « Noter un repas »), `substitution_ecran` (depuis la
  fiche d'une recette : l'ingrédient, pourquoi, trois remplaçants chiffrés
  — ce que la portion gagne ou perd —, « Remplacer »), `conservation_ia`
  (« Comment le garder ? » pour un aliment HORS du guide, au rangement et
  au garde-manger : le repère est APPRIS une fois —
  `CoursesNotifier.apprendreConservation`, table `conservationIa` — et
  dit « repère de l'IA »), `bilan_ecran` (les chiffres, puis l'avis et
  trois pistes ; gardé le temps de la session, « Refaire le bilan »),
  `pieces_ia` (`AppelIa` : un appel à la fois ; `AttenteIa` : les quatre
  capsules du logo battent pendant l'attente ; `ErreurIaBloc` +
  « Réessayer » ; `MentionIa` : ce qui part, ce qui reste).
- **Liens** : l'onglet (« Assistant » ; « Des idées pour les utiliser »
  sous « À consommer bientôt »), le livre (idées, importer), la fiche
  d'une recette (remplacer un ingrédient), Ma semaine (planifier avec
  l'IA), « Noter un repas » (estimer, aussi à partir du mot cherché), le
  rangement et la fiche du garde-manger (conservation).
- **Persistance** : une table, `conservationIa` (les repères de
  conservation appris, lus avec l'état des courses). Les réponses de l'IA
  ne sont pas gardées : une recette l'est une fois AJOUTÉE au livre.

## 3. Architecture

```
lib/
  main.dart               bords à bords, portrait, dates fr_CA / en_CA,
                          active la scène d'ouverture
  app/rhythm_app.dart     MaterialApp sombre, FR (source) / EN, scène
                          d'ouverture par-dessus tout (builder)
  theme/                  rhythm_couleurs|typo|mesures|theme.dart
  widgets/                chemin_svg (tracés SVG → Path), pictos
                          (PictoRhythm), filets (LE langage sans cartes :
                          Filet, RangeeFilets, GrilleFilets), surfaces
                          (PeintreVerre de la barre, Pastille), jauges
                          (Anneau, Jauge, Segments),
                          boutons (BoutonPlein, BoutonContour, BoutonRond),
                          barre_navigation, page_rhythm (PageRhythm,
                          EnTete, Surtitre, VoileBarreEtat), mascottes,
                          logo_rhythm (LogoRhythm, PeintreLogo),
                          scene_ouverture, apparition, toast,
                          pression_echelle (copie de Net Worth / Studio)
  ecrans/                 coquille/ (coquille_ecran, onglets,
                          entree_accueil), accueil/, sports/,
                          alimentation/, habitudes/, biblique/
  modele/                 modeles.dart (Verset, Seance, Exercice, Repas,
                          ApportMacro, PlanLecture, Teinte),
                          graine.dart (données de la maquette, hors
                          habitudes), etat_sante.dart (aujourdhuiProvider,
                          horlogeProvider, semaineSportProvider),
                          habitudes.dart (Habitude, Envie, Contact,
                          ReglagesHabitudes, EtatHabitudes, JSON tolérant),
                          calculs_habitudes.dart (séries, journées,
                          paliers, libération — fonctions pures),
                          etat_habitudes.dart (depotProvider,
                          habitudesProvider, graine et démonstration),
                          depot.dart (SQLite), versets_encouragement.dart
  systeme/                notifications.dart (service Android),
                          rappels_habitudes.dart (QUOI notifier — pur,
                          testé), synchro.dart (replanification,
                          autorisation, « maintenant »)
  navigation/transitions.dart  pousserEcran / retirerEcran (Studio)
  ecrans/habitudes/       habitudes_ecran, habitude_detail_ecran,
                          habitude_formulaire_ecran, envie_ecran,
                          pieces_habitudes
  ecrans/rappels/         rappels_ecran (la cloche de l'accueil)
  widgets/                (en plus) formulaire (ChampRhythm souligné d'un
                          filet, CompteurRhythm, RouletteHeure, Puces,
                          SelecteurJours, Interrupteur, LigneReglage,
                          BoutonSuppression), page_secondaire
                          (PageSecondaire, BarreRetour, TitreSecondaire,
                          TitreSection), suivi_clavier (Studio)
  utils/dates.dart        plusJours, lundiDe, joursEntre, numeroSemaine,
                          cleJour / jourDeCle, plusJoursInstant
  l10n/                   app_fr.arb (source), app_en.arb, traductions.dart
                          (`context.tr`, `context.formats` : dates, heures,
                          nombres sans U+202F)
  modele/sports/          muscles, exercices (types), catalogue.dart +
                          catalogue/ (la banque, par famille), sport.dart
                          (profil, Programme, LigneSeance, SeanceFaite,
                          MesureCorps, Suivi, EtatSport + JSON),
                          calculs_sport.dart (les règles), deroulement.dart
                          (étapes d'une séance), plans.dart (fractionnés,
                          programmes de course, défis, routines),
                          etat_sport.dart (sportProvider, graine,
                          démonstration)
  ecrans/sports/          sports_ecran (l'onglet), banque, exercice
                          (fiche), constructeur, apercu, seance_guidee,
                          cardio, plans (fractionné, programmes, défis),
                          stats, mesures, journal, profil_sport,
                          pieces_sports
  widgets/corps/          geometrie3 (V3, deux segments, enveloppe),
                          squelette3 (Pose3, Cible, Squelette3), peintre3
                          (Camera3, PeintreCorps3), peau3 (Tampon3, Peau3,
                          soudures) + peau/ (outils — pli du cou —,
                          grille — _Tube —, rendu, tronc, membres, tete,
                          extremites, mains), corps_humain (kSol,
                          Ancre, Accessoires), animations_corps
                          (Mouvements.tous) + mouvements/ (les 208, par
                          famille), figure_exercice (Cle, AnimCorps,
                          FigureExercice, animationDe, cadreDe), silhouette
  systeme/                (en plus) rappels_sport, ecran_allume
  l10n/libelles_sport.dart  énumérations → libellés, FormatsSport (kg, km,
                          allure, durées, dosage)
  modele/alimentation/    nutriments, base_aliments (FCÉN, recherche),
                          alimentation (profil, entrée, produit, état +
                          JSON), calculs_alimentation (besoins, ajustement,
                          eau, conseil), etat_alimentation (notifier,
                          besoinsProvider, démonstration)
  ecrans/alimentation/    alimentation_ecran (l'onglet), noter, portion,
                          entree_rapide, moment, objectifs, produits,
                          produit_formulaire, pieces_alimentation
  l10n/libelles_alimentation.dart  énumérations, conseil du jour, grammes
assets/donnees/fcen.txt   la base d'aliments (tool/extraire_fcen.py)
test/alimentation_test.dart  la base (vrai fichier), les règles, le journal,
                          l'état (démonstration = maquette, dépôt, eau →
                          habitude), le conseil
test/alimentation_ecrans_test.dart  au doigt : noter une banane, l'eau,
                          retirer + « Comme hier », objectifs, produit,
                          petit écran
  modele/alimentation/    (palier 2) courses (types, état + JSON), taxes,
                          conservation (Thermoguide), expressions, rayons,
                          calculs_courses, etat_courses (notifier,
                          démonstration)
  ecrans/alimentation/courses/  liste, article, magasin, panier, ranger,
                          garde-manger, fiche, achats, réglages, taxes,
                          pieces_courses (LigneCourse, Echeance, ChoixDate,
                          ChoixEmplacement, BarreCaisse)
  l10n/libelles_courses.dart  rayons, emplacements, taxes, prix au cent,
                          quantités, échéances, durées du guide
  systeme/rappels_garde_manger.dart  les rappels de péremption (pur)
test/courses_test.dart    taxes (barème, caisse, suggestions, consigne),
                          saisie, rayons, fusion, prix, mois, guide,
                          état (magasin → rangement, réassort), JSON,
                          rappels
test/courses_ecrans_test.dart  au doigt : liste (fusion, rayon), magasin,
                          panier, caisse, terminer, ranger ; fiche (fini →
                          liste) ; petit écran
test/sports_test.dart     la banque (cohérence : 250+, mouvements,
                          chaînes, matériel), les règles, l'état (JSON
                          tolérant, dépôt, lien Habitudes, défi, rappels)
test/sports_ecrans_test.dart  au doigt : silhouette → Compléter → aperçu →
                          séance → journal + habitude cochée ; banque ;
                          routine express
test/outils/corps_test.dart  planches des mouvements (16 par PNG) et
                          silhouettes : --dart-define=CAPTURES=<dossier>
                          [MOUVEMENTS=id,id] [INSTANTS=8] [TAILLE=180]
test/outils/portrait_corps_test.dart  un mouvement en grand, gros plans
                          (ZOOM), angles (LACETS), DEBOGAGE par partie
test/outils/inspection_corps_test.dart  les déformations des 208
                          mouvements (INSPECTER=1)
test/outils/perf_corps_test.dart  le temps de peindre (PERF=true)
test/fumee_test.dart      dates, semaine de sport, parcours des cinq
                          onglets à 384 et 360 dp, habitude cochée →
                          accueil, retour d'Android, onglets vivants,
                          fiche + soutien d'une envie, nouvelle habitude +
                          rappels, libération de l'accueil (et invitation
                          au premier lancement)
test/formulaire_test.dart  régressions : un seul champ sélectionné après
                          « Me libérer », roulette de l'heure, − / + en
                          boucle (55 + 5 = 0)
test/habitudes_test.dart  règles des séries, démonstration = maquette,
                          paliers, libération, JSON, dépôt (premier
                          lancement), notifications (discrétion), mot du
                          jour
  modele/alimentation/    (palier 3) recettes (types, état + JSON),
                          calculs_recettes (étapes, minuteurs, besoins,
                          semaine, lots, décompte, restes, décongélation),
                          etat_recettes (notifier, minuteursProvider,
                          recettes de départ, démonstration)
  ecrans/alimentation/recettes/  livre, fiche, formulaire, ingrédient,
                          cuisine, prêt, à la liste, ma semaine, choisir un
                          plat, repas prévu, cuisine en lot, planifier,
                          portion d'une recette, pieces_recettes
  l10n/libelles_recettes.dart  tri, fractions (¼ ½ ¾), durées, portions,
                          quantité d'un ingrédient
  systeme/rappels_recettes.dart  décongélation et minuteurs (pur)
  ia/                     (palier 4) cles_api (la clé, depuis cles.json),
                          service_ia (Groq), texte_ia (nettoyage),
                          ia_alimentation (invites + lectures)
  modele/alimentation/    (palier 4) correspondance (IA → base du FCÉN),
                          bilan_semaine (les chiffres de la semaine)
  ecrans/alimentation/ia/  assistant, idées, recette proposée, importer,
                          écart, planifier, estimer, remplacer,
                          conservation, bilan, pieces_ia
  modele/alimentation/    (lot 6) open_food_facts (codes-barres, réponse
                          d'Open Food Facts → brouillon de produit)
  systeme/                (lot 6) open_food_facts (l'appel, ServiceOff),
                          baremes_en_ligne (le barème relu chaque mois)
  ecrans/alimentation/scanner_ecran.dart  le scan (caméra, saisie, recherche)
donnees/baremes_quebec.json  le barème PUBLIC des taxes (kUrlBaremes)
test/ia_test.dart         textes nettoyés, correspondance (vraie base),
                          lectures tolérantes, invites (rien de
                          personnel), bilan, conservation apprise, service
test/ia_ecrans_test.dart  au doigt, avec le faux service : idées → livre,
                          importer, estimer → journal, écart → journal,
                          semaine, remplacer, conservation, bilan, erreurs,
                          petit écran
test/outils/faux_ia.dart  le faux service d'IA (répond comme Groq)
test/outils/captures_ia_test.dart  captures de l'assistant (i01 à i25)
test/outils/ia_reelle_test.dart  chaque demande de l'assistant au VRAI
                          Groq (délais, recettes, correspondance ligne par
                          ligne ; consomme le quota) :
  flutter test --dart-define=IA_REELLE=true --dart-define-from-file=cles.json test/outils/ia_reelle_test.dart
test/scan_test.dart       codes-barres (clé, UPC-A / UPC-E → EAN-13), la
                          réponse d'Open Food Facts (portion, 100 g, kJ,
                          sel, inconnu, sans valeurs), le code gardé
test/scan_ecrans_test.dart  au doigt, faux Open Food Facts : mes produits
                          → pré-rempli → retrouvé sans réseau ; noter →
                          inconnu → créé à la main → portion ; erreurs
test/outils/balayage_correspondance_test.dart  274 ingrédients et plats →
                          l'aliment du FCÉN choisi (✗ hors base, ⚠ écart) :
  flutter test --dart-define=BALAYAGE=true test/outils/balayage_correspondance_test.dart
test/recettes_test.dart   étapes, minuteurs, quantités, besoins (placard,
                          arrondi), semaine et lots, partagés, décompte,
                          restes, décongélation, livre, état (cuisiner →
                          journal + restes + garde-manger, restes mangés,
                          plan, départ), JSON, rappels, conseil du soir
test/recettes_ecrans_test.dart  au doigt : fiche → cuisine (minuteur,
                          étapes) → prêt ; les boutons du mode cuisine
                          qui ne bougent pas ; la région (choisir,
                          préciser, retirer, filtrer le livre) et
                          « Enregistrer » touché deux fois clavier ouvert ;
                          écrire une recette ; ma semaine (prévoir, liste,
                          lot) ; restes d'un toucher ; petit écran
test/outils/captures_alimentation_test.dart  (en plus) « captures des
                          recettes » (c01 à c28 et c17b — la région —, à
                          17 h 30)
test/outils/transitions_test.dart  les transitions vers les écrans
                          secondaires, aller et retour, image par image
                          (0 à 700 ms, animations réelles) ; le changement
                          d'étape du mode cuisine (images + position de la
                          liste des étapes, image par image)
test/outils/captures_test.dart  captures PNG hors appareil (format maquette
                          390 × 844 et S26 Ultra), scène d'ouverture image
                          par image :
  flutter test --dart-define=CAPTURES=<dossier> test/outils/captures_test.dart
test/outils/polices.dart  les vraies polices pour les tests
test/outils/mascottes_test.dart  les quatre mascottes image par image
                          (30 i/s, 8 s) → PNG ; puis ffmpeg (celui
                          d'imageio-ffmpeg) : -framerate 30 -i m_%03d.png
tool/extraire_polices.py  WOFF2 de la maquette → TTF (Brotli via Node)
tool/gen_icone.py         l'icône (géométrie de logo_rhythm.dart)
design/Rhythm.html        la maquette (source de vérité)
```

---

## 4. Conventions (héritées de Flow / Net Worth / Studio)

- Code, fichiers, commentaires en français. **Diffs chirurgicaux**, pas de
  sur-ingénierie, **une seule question à la fois**.
- Toute chaîne d'interface passe par l'ARB (FR + EN) ; le CONTENU (versets,
  exercices, repas, habitudes) est de la donnée, en français. Clé plurielle
  pouvant recevoir 0 → branche `=0{…}` explicite.
- Typographie française : insécable U+00A0 avant `? : ! ;`, entre un nombre
  et son unité, dans « … ». Jamais U+202F (absente des polices).
- Dates : `plusJours` / `joursEntre` — jamais `Duration(days:)`.
- Après édition : `dart format lib test`, `flutter analyze` (vide),
  `flutter test`, captures regardées à côté de la maquette.

### Build et installation

```bash
flutter build apk --release --dart-define-from-file=cles.json
```
(`cles.json` à la racine, hors du dépôt : `{"GROQ_CLE": "gsk_…"}` — sans
lui, l'APK se construit, mais l'assistant répond « sans clé ».)
```bash
C:\Users\Gardien\AppData\Local\Android\Sdk\platform-tools\adb.exe -s R3GL104SS1V install -r build\app\outputs\flutter-apk\app-release.apk
```

⛔ Règle de Net Worth / Studio, EN VIGUEUR (les habitudes de l'utilisateur
vivent dans l'app depuis le 24 sept. 2026) : **jamais** `adb uninstall`,
`pm clear`, `flutter install` ni `flutter run` sur le téléphone (ils
désinstallent) — seulement `install -r`.
En cas d'`INSTALL_FAILED_*`, s'arrêter et demander. Ne jamais envoyer
d'`input` ni lancer l'app pendant que l'utilisateur se sert du téléphone
(vérifier `dumpsys window | grep mCurrentFocus`).

**Vérifier une animation de démarrage = la FILMER** (méthode de Studio) :
`adb shell screenrecord` pendant un `am start -W` après `am force-stop`,
images extraites par le ffmpeg d'`imageio-ffmpeg` ; dans Git Bash,
`MSYS_NO_PATHCONV=1`. Filmé par adb, il n'y a pas le zoom de l'icône : le
lancer aussi DEPUIS L'ICÔNE.

---

## 5. Pièges rencontrés

- ⛔ **Ne jamais changer la FORME de l'arbre au-dessus des onglets** (ni
  d'un bloc animé) selon l'état d'une animation : rendre l'enfant nu au
  repos et `Opacity(Transform(enfant))` pendant le fondu faisait RECRÉER
  tous les onglets à chaque bascule — les mascottes repartaient de zéro
  (« l'animation reprend au lieu d'être continue »), le défilement était
  perdu. Toujours la même enveloppe, même à opacité 1 (coquille,
  `Apparition`) ; test de régression « changer de section garde chaque
  onglet vivant ».

- flutter_test dessine chaque glyphe d'un cadratin : sans les vraies
  polices (`test/outils/polices.dart`), les textes s'allongent et
  inventent des débordements.
- Les mascottes tournent sans fin : `pumpAndSettle` ne rend jamais la main.
  Tests : `FakeAccessibilityFeatures(disableAnimations: true)` (elles se
  figent) ; captures : `pump(durée)` à la main.
- `IndexedStack` garde les animations des onglets cachés EN MARCHE
  (`Visibility.maintain`) : chaque onglet est enveloppé d'un `TickerMode`.
- `OverflowBox` transmet la largeur MINIMALE reçue : sans `minWidth: 0`, la
  rangée de la capsule active prenait toute la capsule et se calait à
  gauche (pictogramme collé au bord).
- Ce qui est posé dans `MaterialApp.builder` ou l'overlay racine n'est dans
  aucun `Material` : le texte y prend le style d'erreur (souligné double
  jaune) — scène d'ouverture et toast sont enveloppés d'un `Material`
  transparent.
- `IntrinsicHeight` (rangées à filets) demande à chaque enfant une hauteur
  intrinsèque FINIE : un filet vertical ne déclare pas de hauteur (la
  rangée l'étire), et son tracé animé est une échelle de PEINTURE
  (`Transform.scale`) — un `FractionallySizedBox` à facteur 0 (début de
  l'entrée) rendait une hauteur infinie.
- Cases de l'accueil : la rangée du haut a une hauteur fixe (36, l'anneau),
  sinon « Lecture » (anneau) tombait 4 px sous « Habitudes » (pastilles).
- Tests : les animations réduites raccourcissent les transitions de page,
  PAS le verrou de 550 ms contre les doubles appuis
  (`navigation/transitions.dart`) — après une navigation, laisser passer
  600 ms (`_naviguer`), sinon le retour suivant est ignoré.
- Captures : `find.byType(Scrollable).last` peut être le défilement
  HORIZONTAL d'un champ de texte — viser la liste verticale.
- `context.formats` (Localizations) est illisible dans `initState` : le
  lire dans `didChangeDependencies`.
- `TickerMode.of` est déprécié : `TickerMode.valuesOf(context).enabled`,
  lu dans `build` (pas dans un minuteur).
- ⛔ **Un champ de texte ne garde pas son FocusNode en `late final`** :
  quand une liste de champs change de forme (construire ↔ libérer), Flutter
  réutilise l'état d'un champ pour un autre — deux TextField partageaient
  un focus (double sélection, clavier refermé aussitôt par
  `onTapOutside`). `ChampRhythm` lit le focus du widget courant
  (`didUpdateWidget`), le formulaire donne une clé à chaque champ, et plus
  d'`onTapOutside` (un toucher pour défiler fermait le clavier). Testé.
- R8 retire l'icône des notifications (nommée seulement côté Dart) :
  `res/raw/keep.xml` la garde (leçon de Studio — oubliée d'abord ici).
- Compteur en boucle avec un pas : `min + (v − min) % (max − min + pas)`
  (l'ancienne formule faisait 55 + 5 → 4). La répétition d'un appui long
  s'arrête au relâchement du doigt (`Listener`), pas seulement à la fin du
  geste.
- Une liste réordonnable DANS la page : `shrinkWrap` + physique
  `NeverScrollable` — elle ne garde pas le glissement, la page défile même
  doigt posé dessus (testé) ; le décor par défaut de la ligne soulevée
  ajoute une OMBRE (interdit : ni ombre ni lueur) → `proxyDecorator`
  (échelle 1,03 sur fond noir, dans un `Material` transparent — sinon le
  texte, dans l'overlay, prend le souligné jaune).
- Heredoc de Git Bash + apostrophes = script cassé : écrire les scripts
  Python dans un fichier (outil Write), puis les lancer.
- Flutter ne lit pas le WOFF2 et le module Python `brotli` n'est pas
  installé : `tool/extraire_polices.py` décompresse via Node
  (`zlib.brotliDecompressSync`).

---

- Heredoc de Git Bash : une apostrophe dans le texte d'un script Python
  passé par `<<'EOF'` a encore cassé une commande — écrire le script avec
  l'outil Write, puis le lancer (piège déjà noté, retombé dedans).
- ⛔ Le glyphe « ≈ » n'existe pas dans DM Sans / Bricolage : un carré vide
  (« env. » / « about » à la place). Vérifier tout symbole inhabituel en
  capture.
- Captures : un parcours de captures peut se PÉRIMER quand un écran change
  (« Nouvelle habitude » monté sous le titre) — le relancer après chaque
  lot, pas seulement les tests.
- Silhouette : les deux côtés d'un muscle sont LE MÊME muscle — toucher le
  pectoral gauche puis le droit le sélectionne puis le désélectionne.
- ARB : ajouter des libellés LIGNE À LIGNE à la fin (style compact du
  fichier), jamais en réécrivant tout le JSON (diff énorme).
- Corps 3D : `Path.combine` ÉCHOUE parfois (« Path.combine() failed ») sur
  des contours lisses qui se touchent — un membre d'un seul tenant se
  peint en deux passes (contours en double épaisseur, puis les
  remplissages par-dessus : `_peindreEnsemble`), jamais par union.
- Corps 3D : un angle interpolé prend le chemin le plus COURT entre deux
  nombres, pas le bon côté du corps — un tibia de 180 à −86 passait sous
  le sol (écrire 274), un tronc de −133 à 180 faisait le tour (écrire
  −180). Vérifier chaque mouvement image par image (`INSTANTS=8`).
- Corps 3D : une direction « absolue » ne suit pas le tronc — les bras
  d'un relevé de buste se calculent à partir de `p.tronc` (`_brasCroises`),
  et une main tenue sur la tête vient de `_centreTete(p)`.
- `part of` : créer le fichier de la partie AVANT d'ajouter sa ligne
  `part` (sinon la compilation casse pour une autre session qui travaille
  en même temps) ; les noms privés sont partagés par toute la
  bibliothèque (collision `_garde`, `_penche`… avec un autre fichier).

- ⛔ Une barre posée PAR-DESSUS une `PageSecondaire` (la caisse du
  magasin, dans un `Stack` hors du Scaffold) n'est dans aucun `Material` :
  texte souligné jaune — l'envelopper d'un `Material` (vu en capture).
- Singulier : couper le « x » final transformait « noix » en « noi » (les
  noix salées sortaient détaxées) — `singulier` ne coupe que -aux / -eux /
  -oux, et les expressions passent au singulier elles aussi.
- Singulier (bis) : « pois » devenait « poi » (la recherche trouvait
  poivron et poire avant les pois), « maïs » → « mai », « gros » → « gro »
  — une liste d'INVARIABLES en -s (`_invariables`, `base_aliments.dart`).
- ARB : vérifier qu'une clé n'existe PAS déjà avant d'en ajouter une
  (`etapes`, `note`, `aucune`, `minuteurFini` — l'envie —, `rienDePrevu`
  existaient) : le script d'ajout refuse les doublons.
- Tests : un minuteur qui tourne rafraîchit l'écran toutes les 250 ms —
  `pumpAndSettle` ne rend jamais la main tant qu'il tourne : `pump()` puis
  l'arrêter.
- `aConsommerBientot(…, jours: 999)` trie avec `peremption!` : un aliment
  sans date y ferait planter — ne jamais l'appeler avec une limite qui
  laisse passer les sans-date.
- ⛔ Corps 3D, un virage de tube PLUS SERRÉ que son rayon croise ses
  anneaux (le cou tête pendante) : étaler le virage (rayon de courbure >
  rayon du tube), ou cisailler sans tourner les anneaux (le haut du
  tronc). Un cou qui part dans la direction du dos d'un point situé SUR
  l'axe de la tête fait forcément un S : centrer le virage sur ce point.
- ⛔ Corps 3D, un volume `_Tube` lu en travers de l'axe se trompe dès que
  les anneaux sont inclinés (cisaillés, étirés en arc) : `parPlans`. Et
  une marge d'enfouissement NÉGATIVE (cacher ce qui colle « au-dessus »
  de l'autre) ouvre des trous là où le volume de l'autre est approché
  (ses bouts) : la limiter à un petit rayon (`rayonA`). Juger avec
  `DEBOGAGE=true` : un trou montre le fond, un entrelacs des rayures.
- Deux sessions en même temps (l'autre sur le corps 3D) : un
  `flutter test` complet peut échouer « au chargement » pendant qu'un
  fichier de l'autre change — relancer avant de conclure.
- ⛔ Double ENREGISTREMENT : entre un toucher et la prochaine image,
  Flutter absorbe les touchers (le Navigator, pendant un push / pop) ;
  mais CLAVIER OUVERT, `pousserEcran` / `retirerEcran` / `remplacerEcran`
  attendent 280 ms qu'il descende — un second « Enregistrer » passait
  (deux recettes, deux entrées au journal). Tout écran qui ENREGISTRE puis
  se ferme, avec un champ de texte, commence par
  `if (transitionEnCours) return;`. Testé (clavier simulé :
  `tester.view.viewInsets`) — sans clavier, le test ne voit rien.
- Un `TextSpan` à `recognizer` recréé à chaque `build` annule le toucher
  en cours quand l'écran se redessine souvent (le mode cuisine, toutes les
  250 ms dès qu'un minuteur tourne) : `TexteEtape` garde ses gestes tant
  que le texte ne change pas.
- Une rangée qui défile de côté : `Scrollable.ensureVisible` fait défiler
  TOUS les ancêtres (la page aussi) — pour ramener la capsule choisie,
  calculer le décalage et `jumpTo` sur la rangée seule (`RangeePuces`).
- ⛔ `AnimatedSwitcher` à `layoutBuilder` en `Stack` : l'ancien enfant
  RETIENT la hauteur (le max des deux) jusqu'à la fin du fondu, puis tout
  saute ; et ce qui est HORS du switcher (les boutons de minuteur) change
  tout de suite, avant le texte. Tout ce qui change avec l'étape va DANS le
  switcher ; les anciens enfants en `Positioned` (sans taille) ; la
  hauteur dans un `AnimatedSize` de même durée.
- Films de tests : un `pump(durée)` UNIQUE après un toucher ne rend
  qu'UNE image — les animations y démarrent à 0 (écran noir, onglet pas
  changé) ; et un écran poussé naît HORS SCÈNE à sa première image
  (`find` ne le voit pas) : `pump()` puis `pump(durée)`, ou des pas de
  100 ms.
- Tests : `find.text` trouve aussi le texte d'un CHAMP (`EditableText`) —
  une capsule dont le libellé est aussi dans le champ : chercher sous son
  widget (`find.descendant(of: find.byType(ChoixRegion), …)`).
- ⛔ IA : un FAUX service qui répond « bien » ne prouve rien — il cachait
  un JSON illisible de temps en temps, le quota à la MINUTE (8 000 jetons
  par modèle), et une vingtaine de confusions de la correspondance (pois →
  poisson, vin → vinaigre, riz cuit pour du riz cru, « 1 tranche » pour un
  oignon, la conservation qui recopiait l'exemple). Éprouver sur le vrai
  Groq (`test/outils/ia_reelle_test.dart`) et BALAYER la correspondance
  (`balayage_correspondance_test.dart`, comparer avant / après chaque
  retouche : une règle qui répare un cas en casse souvent un autre).
- La base du FCÉN est SANS ACCENTS une fois simplifiée : « pâte » et
  « pâté » deviennent le même mot ; « sec » y dit l'état cru des grains
  (et « rôties à sec », autre chose) ; les parenthèses y mêlent synonymes
  (« Okra (gombo) », à garder) et composition (« (faite à partir de …) »,
  à ignorer).
- ⛔ Le barème en ligne se lit sur le dépôt GitHub PUBLIC
  (`raw.githubusercontent.com/…/main/donnees/baremes_quebec.json`) : si le
  dépôt devient privé, le fichier ne se lit plus (l'app garde le barème
  embarqué) — l'héberger ailleurs et changer `kUrlBaremes`. Tout le dépôt
  est public (CLAUDE.md compris) ; la clé Groq, elle, n'y est pas.
- Un toast dure 1,9 s : `pumpAndSettle` le laisse finir — le chercher
  juste après le toucher (`pump()`), pas après `_toucher`.
- flutter_test remplace le réseau (HTTP 400) une fois le binding lancé :
  un test qui parle à un vrai serveur (Groq, ou le faux Groq local des
  tests du service) passe par `HttpOverrides.runWithHttpOverrides` avec
  un `HttpOverrides` nu, ou met `HttpOverrides.global = null`.

## 6. Prochaines étapes (à valider avec l'utilisateur)

- **Pas encore vérifié sur le téléphone** : la scène d'ouverture filmée,
  et les notifications réelles (autorisation, rappel, bilan du soir,
  soutien discret sur l'écran verrouillé).
- **Alimentation : palier 4 (IA) livré, éprouvé sur le vrai Groq, à
  tester sur le téléphone** — § 3 quater. La clé est configurée
  (`cles.json` à la racine, hors du dépôt, celle de Studio / Net Worth ;
  vérifiée : Groq répond, les deux modèles sont là). L'utilisateur juge
  la qualité des idées et des estimations au quotidien ; ce qui reste
  hors de la base est ce que le FCÉN n'a pas. À vérifier sur le
  téléphone (lot 6) : le SCAN (autoriser la caméra, un vrai produit, un
  produit inconnu, sans réseau), la date « Taux vérifiés en ligne » dans
  les taxes (une fois `main` à jour). À vérifier aussi : un minuteur
  du mode cuisine quand l'app passe derrière (notification inexacte), le
  rappel de décongélation.
- Faire vivre Biblique (lecteur, plan, prière, méditation) ; brancher les
  boutons « Bientôt disponible » (Partager, Continuer, Prière, Méditation).
  Chaque module ajoutera SES tables au dépôt.
- Corps 3D, à juger sur le téléphone : la fluidité des figures animées
  (fiche, séance) et le rendu des 208 mouvements ; l'utilisateur dira
  lesquels restent peu naturels. Connu, en très gros plan seulement : une
  fine limite à la base du cou (le col du tronc, un peu plus large que le
  cou, prend la lumière autrement — retoucher la forme des trapèzes), une
  petite écaille en haut de la nuque tête pendante (chat-vache), une
  encoche sous le bras levé ; le pire étirement restant est l'avant-bras
  de l'étirement d'épaule (bras croisé devant la poitrine).
- Sports (section CONCLUE), à vérifier sur le téléphone : une vraie séance
  guidée (vibrations du repos, écran allumé, arrière-plan), un rappel de
  séance, le fractionné.
  Pistes (non demandées) : reprendre une séance interrompue si Android tue
  l'app, GPS pour la course, plus de mouvements dédiés (fire hydrant,
  clean, get-up…), export du journal.
- Habitudes, pistes (non demandées) : archiver / mettre en pause plutôt
  que supprimer, modifier le « libre depuis » après coup, sauvegarde /
  export, widget d'accueil Android (comme Studio).
- Sommeil et mesures corporelles (présents dans Flow) : absents de la
  maquette — à placer si l'utilisateur les veut.

---

**Dernière mise à jour** : 25 septembre 2026 (suite 11) — **Alimentation,
lot 6 : le scan et le barème en ligne** (§ 3 quater) — le plan de
l'Alimentation est complet : scanner un code-barres (caméra, clé contrôlée,
Open Food Facts → formulaire pré-rempli ; retrouvé sans réseau ; créé à la
main s'il est inconnu ; depuis « Noter un repas », enchaîne sur la
portion), le barème des taxes relu en ligne une fois par mois (fichier
public du dépôt). Le lot 5 vérifié (analyse vide, 205 tests) et poussé.
225 tests ; analyse vide ; captures du scan regardées (s01 à s06). APK
pas construit ici (SDK Android inaccessible depuis le conteneur).
Prochaine section : Biblique.
— 25 septembre 2026 (suite 10) — **Alimentation,
lot 5 : les finitions du plan** (§ 3 quater) : mon assiette (Guide
alimentaire canadien), le total prévu du jour dans Ma semaine, recettes
favorites et étiquettes, emplacements ajoutés au garde-manger, remplacer
un ingrédient en mode cuisine. 205 tests ; analyse vide ; captures
regardées (`captures du lot 5`, l01 à l14) ; release installée
(`install -r`, 19 h 00), non lancée. Non commité.
— 25 septembre 2026 (suite 9) — **Alimentation,
palier 4 éprouvé sur le vrai Groq** (§ 3 quater) : les commits du cloud
vérifiés (analyse vide, tests verts) ; la clé configurée (`cles.json`,
hors du dépôt) ; chaque demande de l'assistant envoyée au vrai Groq
(`ia_reelle_test`) — quota à la minute (attente courte), réponse
illisible redemandée, conservation qui ne recopie plus l'exemple, bilan
aux verdicts calculés (il disait « protéines atteintes » pour 96 g sur
150), estimation qui garde entiers les plats du FCÉN ; la correspondance
refaite après deux balayages (281 cas, `balayage_correspondance_test`) :
une trentaine de confusions corrigées (pois → poisson, vin → vinaigre,
riz cuit pour cru, pâte / pâtes / pâté, feuilles de betterave, sauce aux
arachides pour la sauce soya, anchois pour l'huile d'olive…). 193 tests ;
analyse vide ; release installée (`install -r`, 17 h 46), non lancée.
Puis, sur retour de l'utilisateur (1er test de l'IA : les portions
divisent bien les kcal, mais les étapes « rushent ») : les étapes des
idées détaillées (9 étapes précises au lieu de 6 lignes, éprouvé sur le
vrai Groq) ; chou blanc → chou, poulet ordinaire (pas de chapon). 194
tests ; release installée (`install -r`, 18 h 21), non lancée.
— 25 septembre 2026 (suite 8) — **Sports
conclus** (§ 3 ter) : le corps 3D fini — le cou ne se froisse plus tête
pendante (un seul virage, centré sur la base du cou ; le haut du tronc
cisaillé), les volumes du cou et des épaules lus par plans (plus de trou
à la nuque ni à l'aisselle bras levé), la couture de la nuque (pompe)
effacée ; inspection des 208 mouvements avant / après (pointes 100 → 68,
plis 677 → 640, étirements 194 → 204 — surtout des cases jadis cachées à
tort, maintenant peintes ; chat-vache et les ponts sortis des pires cas),
vitesse inchangée ; le
moteur de peau de la session du corps 3D documenté (§ 3 ter). 186 tests ;
analyse vide.
— 25 septembre 2026 (suite 7) — **Alimentation,
palier 4 : l'IA** (§ 3 quater), conclu : assistant (idées de recettes
avec région, moment et genre choisis avant, anti-gaspillage, écart du
soir, semaine planifiée avec le livre, repas estimé, recette importée,
ingrédient remplacé, conservation hors du guide apprise, bilan de la
semaine) ; tout ce qui est chiffré vient de la base du FCÉN ; clé hors du
dépôt (`cles.json`). Revue : le bilan affichait fibres et sodium à
« 0 g » quand ils sont inconnus — corrigé, testé. 186 tests ; analyse
vide ; captures de l'assistant regardées. Pas encore installé.
— 25 septembre 2026 (suite 6) — le mode
cuisine, retour de l'utilisateur (« le minuteur, sa disparition et son
apparition, n'est pas synchronisé avec le reste, le saut persiste ») :
l'étape entière (texte + minuteurs) en fondu enchaîné, hauteur qui glisse
en même temps ; filmé image par image (étape à minuteur → sans → à
minuteur : la liste glisse de 482 à 422 px en 300 ms, sans à-coup). 153
tests ; release installée (`install -r`, 13 h 08), non lancée.
— 25 septembre 2026 (suite 5) — retours de
l'utilisateur sur le palier 3 : les RÉGIONS en 16 grandes régions (les
cinq Afriques, l'Europe, les Amériques, les Asies…) et leurs cuisines,
choisies en deux rangées, retirées d'un toucher (« Aucune », ou la capsule
choisie touchée de nouveau), filtre du livre par grande région ; le MODE
CUISINE : « Précédente » / « Suivante » dans une barre fixe en bas (plus de
saut quand une étape a un minuteur et la suivante non). Revue : double
enregistrement clavier ouvert (8 écrans de l'Alimentation), minuteur
souligné qui ignorait un toucher sur deux pendant qu'un autre tournait ;
transitions filmées image par image depuis les sections principales :
rien de cassé. 153 tests ; release installée (`install -r`, 12 h 46),
non lancée.
— 25 septembre 2026 (suite 4) — **Alimentation,
palier 3 : les recettes** (§ 3 quater) : livre (recherche, moments, tri,
régions), recette écrite à la main (ingrédients du FCÉN, de mes produits
ou libres ; macros par la base ; étapes aux minuteurs repérés), 8
recettes de départ (valeurs du FCÉN), mode cuisine (écran allumé, mise en
place, étapes, minuteurs, portions), « C'est prêt » (journal, restes au
frigo / congélateur, garde-manger décompté), « À la liste » (moins le
garde-manger et la liste ; placard à vérifier), ma semaine (7 jours,
recettes / produits / autre chose, déplacer), liste de la semaine,
cuisine en lot, rappels de décongélation et conseil du soir, restes à
manger d'un toucher. La demande pour le palier 4 (région et type de
repas à la génération) est notée. 149 tests (30 pour les recettes) ;
captures regardées ; release installée (`install -r`, 11 h 58), non
lancée (téléphone en cours d'utilisation).
— 25 septembre 2026 (suite 3) — **Alimentation,
palier 2 : les achats** (§ 3 quater) : liste de courses (fusion, rayons
devinés, habituels, estimation, budget), mode magasin (écran allumé,
panier au prix, au poids, taxes du Québec en trois statuts avec la mesure
du 15 juillet 2026, consigne, caisse en direct), rangement guidé
(Thermoguide du MAPAQ), garde-manger (échéances, ouvert, congeler,
fini / jeté, réassort, gaspillage), historique des épiceries, rappels de
péremption. 119 tests ; captures regardées ; release installée
(`install -r`, 10 h 40), non lancée.
— 25 septembre 2026 (suite 2) — **les
exercices animés refaits en 3D** (§ 3 ter) : squelette 3D à cibles (mains
et pieds plantés), caméra de trois quarts (et plongée pour les corps
couchés), 208 mouvements réécrits famille par famille et vérifiés image
par image (tempo réel, sauts avec envol, vraies foulées, planches
latérales roulées sur le côté), 67 exercices reliés à un mouvement dédié ;
l'ancien moteur 2D supprimé. 119 tests ; release installée (`install -r`),
non lancée (téléphone en cours d'utilisation).
— 25 septembre 2026 (suite) — **Alimentation,
palier 1** (§ 3 quater) : base d'aliments du FCÉN 2026 hors ligne
(5 894 aliments, recherche classée, aliments courants et « gruau »
québécois), profil et besoins (Mifflin-St Jeor, séances des Sports,
objectif, ajustement automatique), journal vivant (noter, récents, portions
du FCÉN, entrée rapide, « Comme hier »), eau touchable qui coche l'habitude,
conseil du jour, mes produits (étiquette canadienne), l'accueil branché.
95 tests (30 pour l'Alimentation) ; captures regardées
(`test/outils/captures_alimentation_test.dart`) ; release reconstruite et
installée (`install -r`, 9 h 47), non lancée. Une autre session travaillait en même
temps sur `lib/widgets/corps/` (corps 3D des Sports) : fichiers partagés
relus avant chaque édition.
— 25 septembre 2026 — **les Sports vivants**
(§ 3 ter) : corps humain réaliste (143 mouvements, cadrage), banque de 254
exercices hors ligne, constructeur à silhouette et « Compléter », aperçu
retouchable, séance guidée (progression, repos, records), cardio et
fractionné, programmes progressifs, défis, routines express, récupération,
stats sur 30 jours, mesures, journal, rappels de séance, lien avec
l'habitude « Entraînement » ; l'accueil resserré (grille ≈ 30 % moins
haute, anneau segmenté des habitudes). 64 tests ; release installée
(`install -r`), non lancée (téléphone verrouillé).
— 24 septembre 2026 — création : projet Flutter,
cinq écrans de la maquette reproduits (tokens, polices et tracés extraits
du fichier), mascottes animées, barre de verre, habitudes cochables,
vraies dates ; scène d'ouverture (logo en mesure) et entrée animée de
l'accueil ; icône provisoire. 5 tests, captures comparées à la maquette ;
release installée sur le S26 Ultra (`install -r`), non lancée (téléphone
en cours d'utilisation).
— 24 septembre 2026 (suite) : sur retour de l'utilisateur (« les cartes
aplats, pas apaisant ; fatigué des bords arrondis ; avec Rhythm je veux
innover »), **plus de cartes** : lumière (une lueur par écran, la case
touchée qui s'illumine), filets qui s'estompent (croix de la grille tracée
depuis son centre à l'ouverture), air. 5 tests, captures vérifiées ;
release installée (`install -r`).
— 24 septembre 2026 (suite 2) : les lueurs retirées TOTALEMENT à la
demande de l'utilisateur (au repos comme au toucher) : il reste le noir,
les filets et l'air ; toucher = pression d'échelle. 5 tests, captures
vérifiées ; release installée (`install -r`).
— 24 septembre 2026 (suite 7) : la grille de l'accueil remise au cœur
(sous le bonjour, en grand), la libération juste après ; Habitudes :
« Nouvelle habitude » et « Rappels » en capsules sous le titre, la
libération en tête, l'ordre des habitudes (« Mon ordre » au doigt, « Par
heure »), une habitude épinglée ; une entrée du journal des envies se
retire (rechute notée par erreur). 40 tests ; release installée
(`install -r`). Lot Habitudes terminé ; prochaine section : Sports.
— 24 septembre 2026 (suite 6) : l'accueil relié aux Habitudes — section
Libération sous le bonjour (compteur qui compte à l'entrée, palier,
« Envie ? »), invitation en bas sans libération. 35 tests ; release
installée (`install -r`).
— 24 septembre 2026 (suite 5) : retours de l'utilisateur — le visage du
gourmand en vrai trois quarts (yeux décalés, bouche dessous) ; l'heure du
rappel en roulettes ; la double sélection et le clavier qui se fermait
(focus partagé entre deux champs) ; « Rappels et notifications » en bas
des Habitudes et une section Notifications claire (« Activer »). Revue :
icône des notifications gardée en release (`keep.xml`), double
enregistrement et envie notée deux fois empêchés, répétition des − / +
arrêtée au relâchement, série « en fois » pour une habitude non
quotidienne. 33 tests ; release installée (`install -r`).
— 24 septembre 2026 (suite 4) : **les Habitudes vivantes** (§ 3 bis) —
à construire / à libérer, séries et paliers, mot du jour, fiche et
historique, formulaire, « J'ai une envie » (soutien, rechute sans
reproche), rappels et bilan du soir (notifications discrètes), personnes
de confiance ; persistance SQLite (premier lancement : les six de la
maquette, sans historique). Et le gourmand retouché : bouche fermée au
repos, corps droit, mastication bouche fermée. 30 tests ; release
installée (`install -r`).
— 24 septembre 2026 (suite 3) : sur retour de l'utilisateur, (1) la
continuité — les onglets étaient recréés à chaque changement de section
(forme d'arbre variable pendant le fondu) : corrigé, testé ; (2) les
mascottes RÉANIMÉES selon les principes de l'animation (course réelle à
deux segments, bouchée complète, saut de joie amorti, page tournée qui
s'incurve), jugées en vidéo image par image. 6 tests ; release installée
(`install -r`).
