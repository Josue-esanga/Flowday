# Flowday — Fichier de suivi

Ce document liste tout ce qui est réalisé dans le projet, étape par étape.
**Phase actuelle : DESIGN (UI statique, aucune logique métier).**

---

## ✅ Phase 1 — Design (réalisé)

### Charte graphique appliquée (`lib/app/theme/app_theme.dart`)

| Élément | Valeur |
|---|---|
| Fond général | gris très foncé `#0B0B0C` |
| Cartes / surfaces | anthracite `#1B1B1D`, `#232326` |
| Barre de navigation | `#161618` |
| Couleur d'accent | orange vif `#F4761F` (jour actif, FAB, timeline, badges) |
| Texte principal / secondaire | `#F4F4F5` / `#9A9A9E` |
| Catégorie **Work** | orange `#F4761F` |
| Catégorie **Health** | jaune `#F5C542` |
| Catégorie **Personal** | rouge `#F05B52` |
| Catégorie **Education** | bleu `#4E8CFF` (issue de la maquette) |
| Typographie | sans-serif moderne (Inter en recommandation, police système pour l'instant) |
| Formes | coins arrondis partout (cartes 14 px, chips 20 px) |

> Le thème sombre est le thème initial du produit (README §6).
> Toutes les couleurs sont centralisées dans `AppColors` pour rester cohérentes.

### Écrans réalisés (conformes aux 2 images + README §3)

| Écran | Fichier | Contenu |
|---|---|---|
| **Accueil — maquette 2** | `lib/features/dashboard/presentation/dashboard_screen.dart` | Avatar + « Hello Mobina! » + date, champ de recherche + bouton loupe, chips **Categories** (Personal, Work, Health, Education), sections « Today's task » et « Yesterday's task » avec lien **See all**, cartes de tâches (case à cocher, titre barré si terminé, description, badge horaire orange, pastille de catégorie) |
| **Timeline — maquette 1** | `lib/features/tasks/presentation/timeline_screen.dart` | Flèche de retour + titre « Today's task », sélecteur de semaine (Mon 24 → Sun 30, jour sélectionné en orange), timeline verticale : heure à gauche, point (coché = terminé) relié par un trait orange, carte de tâche à droite, message vide « Aucune tâche pour ce jour » |
| **Formulaire tâche** | `lib/features/tasks/presentation/task_form_screen.dart` | Titre*, description, date, heure, catégories sélectionnables, boutons **Enregistrer** / **Annuler** (README §3.2) |
| **Calendrier** | `lib/features/calendar/presentation/calendar_screen.dart` | Mois de juin 2026, navigation mois, grille des jours (28 en orange), résumé du jour |
| **Paramètres** | `lib/features/settings/presentation/settings_screen.dart` | Thème sombre, notifications + rappel par défaut, langue, à propos (README §3.4) |
| **Profil** | `lib/features/account/presentation/profile_screen.dart` | Avatar, nom, e-mail, 3 cartes de statistiques (tâches terminées, taux de réussite, semaine), liens (README §3.5) |

### Widgets réutilisables (`lib/shared/widgets/`)

| Widget | Fichier | Rôle |
|---|---|---|
| Barre de navigation + FAB (+) | `bottom_nav_bar.dart` | 4 destinations (Accueil, Calendrier, Paramètres, Profil) + bouton flottant orange central qui dépasse de la barre |
| Carte de tâche | `task_card.dart` | `TaskCard`, `TaskCheckbox`, `TimeBadge`, `CategoryLabel` |
| Ligne de timeline | `timeline_tile.dart` | heure + point d'état + trait de liaison + carte |

### Structure du code (architecture feature-first)

```
lib/
├── main.dart                      # point d'entrée (runApp)
├── app/                           # "tout ce qui va avec" l'application
│   ├── app.dart                   # FlowdayApp : MaterialApp + thème
│   ├── home_shell.dart            # coque : barre de nav + onglets + bascule timeline
│   └── theme/app_theme.dart       # AppColors (charte) + AppTheme.dark()
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

- La maquette montre une catégorie **Education** en plus des 3 du MVP
  (Work, Health, Personal) : elle est intégrée au design, à confirmer pour le MVP.
- Police **Inter** recommandée par le README : non embarquée pour l'instant
  (pas de fichier de police dans le projet), la police système est utilisée.
- Les données affichées viennent de `mock_data.dart` : elles seront remplacées
  par le stockage local lors de la phase logique.
- Le titre de l'écran formulaire reprend « Today's task » comme sur le README ;
  à ajuster si besoin (« Nouvelle tâche »).
