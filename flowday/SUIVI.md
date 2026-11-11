# Flowday — Fichier de suivi

Ce document liste tout ce qui est réalisé dans le projet, étape par étape.
**Phase actuelle : DESIGN (UI statique, aucune logique métier).**

---

## ✅ Phase 1 — Design (réalisé)

### Charte graphique appliquée (`lib/app/theme/app_theme.dart`)

**Version actuelle : thème clair** (refonte du design à partir du code de
référence fourni — deux dashboards, style « project/planning »).

| Élément | Valeur |
|---|---|
| Fond général | bleu-gris très clair `#E7E9F4` |
| Écrans / cartes | blanc `#FFFFFF`, cartes de tâches `#FAFAFC` |
| En-têtes, boutons, éléments d'action | gris anthracite `#202020` |
| Cartes claires (variante douce) | `#F0F1FF` |
| Champs (recherche, formulaire) | `#F7F7FA` |
| Texte principal / secondaire | `#151515` / `#9295A3` |
| Barre de navigation | `#FAFAFC` (icônes inactives `#C8CAD3`, cerclage du bouton + `#9CB7C0`) |
| Catégorie **Work** | orange `#F4761F` |
| Catégorie **Health** | jaune `#F5C542` |
| Catégorie **Personal** | rouge `#F05B52` |
| Catégorie **Education** | bleu `#4E8CFF` |
| Typographie | Roboto |
| Formes | très arrondies : cartes 18-38 px, champs 20 px, timeline 35 px |

> Toutes les couleurs sont centralisées dans `AppColors` pour rester cohérentes.
> Les couleurs de catégories restent celles du README §5 (seules couleurs
> « vives » du design, utilisées en pastille).

### Écrans réalisés (structure du README §3, look du nouveau design)

| Écran | Fichier | Contenu |
|---|---|---|
| **Accueil** | `lib/features/dashboard/presentation/dashboard_screen.dart` | En-tête sombre arrondi avec vagues décoratives (« Hey Mobina ! » + avatar + « Let's find your best day! »), barre de recherche + bouton filtre sombre, section **Categories** en cartes horizontales (Personal en carte sombre avec flèche, Work / Health / Education en carte claire), sections « Today's task » et « Yesterday's task » avec lien **See all**, listes de tâches (case sombre cochée, titre barré si terminé, heure à droite) |
| **Timeline** | `lib/features/tasks/presentation/timeline_screen.dart` | Retour + date (« June 28, 2026 ») + grand titre (« Today » ou nom du jour) + avatar, sélecteur de dates en pilules verticales (jour actif en pilule sombre avec pastille), timeline : point relié par un trait sombre, heure à droite, catégorie sous la description, **1re tâche mise en avant** (carte sombre « featured » avec bouton check + statut), message vide « Aucune tâche pour ce jour » |
| **Formulaire tâche** | `lib/features/tasks/presentation/task_form_screen.dart` | Titre*, description, date, heure, catégories en pastilles (sélection sombre), boutons **Enregistrer** (sombre) / **Annuler** (README §3.2) |
| **Calendrier** | `lib/features/calendar/presentation/calendar_screen.dart` | Juin 2026, navigation mois, grille des jours (28 en cercle sombre), résumé du jour sur carte claire |
| **Paramètres** | `lib/features/settings/presentation/settings_screen.dart` | Thème sombre, notifications + rappel par défaut, langue, à propos (README §3.4) |
| **Profil** | `lib/features/account/presentation/profile_screen.dart` | Avatar, nom, e-mail, 3 cartes de statistiques, liens (README §3.5) |

### Widgets réutilisables (`lib/shared/widgets/`)

| Widget | Fichier | Rôle |
|---|---|---|
| Barre de navigation | `bottom_nav_bar.dart` | 4 destinations (Accueil, Calendrier, Paramètres, Profil) + bouton **+** central en cercle sombre cerclé de clair ; onglet actif en sombre avec pastille dessous |
| Carte de tâche | `task_list_item.dart` | `TaskListItem` : case carrée sombre, titre/sous-titre, heure ou pastille à droite |
| Ligne de timeline | `timeline_tile.dart` | `TimelineTask` (point + trait + contenu, variante featured) et `CategoryLabel` |
| Titre de section | `section_title.dart` | `SectionTitle` : titre gras + lien d'action cliquable (« See all ») |
| Avatar | `avatar.dart` | `Avatar` : cercle coloré avec initiales |
| Vagues décoratives | `wave_painter.dart` | `WavePainter` : motif de vagues de l'en-tête sombre |

### Structure du code (architecture feature-first)

```
lib/
├── main.dart                      # point d'entrée (runApp)
├── app/                           # "tout ce qui va avec" l'application
│   ├── app.dart                   # FlowdayApp : MaterialApp + thème
│   ├── home_shell.dart            # coque : barre de nav + onglets + bascule timeline
│   └── theme/app_theme.dart       # AppColors (charte) + AppTheme.light()
├── core/                          # briques transverses (à remplir en phase logique)
│   ├── constants/
│   ├── errors/
│   ├── network/
│   ├── providers/
│   ├── router/
│   ├── security/
│   ├── storage/
│   └── ui/
│       ├── buttons/
│       ├── skeleton/
│       └── states/
├── features/                      # une fonctionnalité = data / domain / presentation
│   ├── account/                   # profil utilisateur
│   │   ├── data/  domain/  presentation/profile_screen.dart
│   ├── auth/                      # (à venir : connexion, inscription)
│   │   ├── data/  domain/  presentation/
│   ├── dashboard/                 # maquette 2 (accueil "Hello Mobina!")
│   │   ├── data/  domain/  presentation/dashboard_screen.dart
│   ├── tasks/                     # maquette 1 (timeline) + formulaire
│   │   ├── data/  domain/  presentation/timeline_screen.dart
│   │   │                        presentation/task_form_screen.dart
│   ├── calendar/
│   │   ├── data/  domain/  presentation/calendar_screen.dart
│   └── settings/
│       ├── data/  domain/  presentation/settings_screen.dart
└── shared/                        # éléments partagés entre features
    ├── data/mock_data.dart        # données de maquette (temporaire)
    ├── models/models.dart         # Category, TaskItem, WeekDay
    └── widgets/                   # bottom_nav_bar, task_card, timeline_tile
```

- `core/` : dossiers prêts (`.gitkeep`) pour les constantes, erreurs, réseau,
  providers, routeur, sécurité, stockage et UI générique (boutons, squelettes
  de chargement, états vide/erreur).
- `features/*/data` : sources de données (repositories, stockage local).
- `features/*/domain` : entités et règles métier.
- `features/*/presentation` : écrans et widgets de l'écran.

### Interactions déjà actives (UI uniquement, pas de logique)

- Bascule entre les 4 onglets de la barre de navigation.
- « See all » → ouvre la timeline « Today's task », flèche ← → retour.
- Sélection d'un jour dans le sélecteur de semaine (change la mise en évidence).
- Bouton **+** → ouvre l'écran de formulaire (boutons qui ferment l'écran).
- Sélection d'une catégorie dans le formulaire.
- Interrupteurs des paramètres (état local uniquement).

### Vérifications

- `flutter analyze` : **0 problème**
- `flutter test` : **1 test passé** (accueil conforme à la maquette, ouverture de la timeline, retour, section « Yesterday's task »)

---

## ⏭ Phase 2 — Logique (à venir, pas encore implémentée)

D'après le README (MVP, §2) :

1. **F1** Affichage des tâches du jour dans la timeline triée par heure.
2. **F2** Sélecteur de semaine réel (charger les tâches du jour sélectionné).
3. **F3** Création de tâche : validation du titre obligatoire, heure valide.
4. **F4** Modification d'une tâche existante.
5. **F5** Suppression avec confirmation (ou glissement).
6. **F6** Terminaison : appui sur le point de la timeline pour inverser l'état.
7. **F7** Catégories Work / Health / Personal avec couleurs.
8. **F8** Stockage local (SQLite, Hive ou Realm) + persistance après redémarrage.
9. Gestion d'état : Provider, Riverpod ou Bloc (choix à trancher).
10. Architecture : séparer présentation / état / domaine / persistance (README §7).

### Évolutions prévues (post-MVP)

Notifications et rappels, vue calendrier mensuelle avec indicateurs de jours
chargés, catégories personnalisées, profil avec statistiques réelles,
paramètres (thème clair, langue), tâches récurrentes, synchronisation cloud,
recherche et filtres.

---

## 📝 Notes / décisions de design

- **Refonte du design** : le design initial (sombre + orange) a été remplacé
  par le code de référence fourni (thème clair + en-tête sombre avec vagues,
  cartes très arrondies, timeline « featured », barre de nav avec bouton **+**
  central). Le contenu fonctionnel Flowday (tâches, catégories, sections du
  README) est conservé, seul le look a changé.
- La palette et les composants du code de référence sont centralisés dans
  `AppColors` / `AppTheme.light()` et réutilisés partout (`Avatar`,
  `WavePainter`, `SectionTitle`, `TaskListItem`, `TimelineTask`).
- Police **Roboto** (choix du nouveau design) ; le README recommandait Inter.
- La maquette montre une catégorie **Education** en plus des 3 du MVP
  (Work, Health, Personal) : elle est intégrée au design, à confirmer pour le MVP.
- Les cartes de catégories de l'accueil sont des cartes de démonstration
  (libellés + descriptions fixes) : elles seront liées aux vraies catégories
  en phase logique.
- L'écran formulaire porte le titre « New task » ; « See all » ouvre la
  timeline, dont la 1re tâche est mise en avant (carte sombre).
- Les données affichées viennent de `mock_data.dart` : elles seront remplacées
  par le stockage local lors de la phase logique.
