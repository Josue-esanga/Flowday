# Flowday — Fichier de suivi

Ce document liste tout ce qui est réalisé dans le projet, étape par étape.
**Phase actuelle : design ✅ + backend Django/DRF ✅ + Flutter branché sur
l'API ✅ (MVP F1–F8 fonctionnel de bout en bout).**
Prochaine étapes possibles : mode hors ligne (cache local), authentification,
notifications (post-MVP).

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
| Typographie | **Poppins** embarquée (Regular / Medium / SemiBold / Bold) — choix « Inter ou Poppins » du README §6 |
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
| **Calendrier** | `lib/features/calendar/presentation/calendar_screen.dart` | Juin 2026, navigation mois, grille des jours (28 en cercle sombre), résumé du jour sur carte claire — **responsive** : cellules dimensionnées selon la largeur (téléphone → desktop) et contenu défilant |
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
│   ├── app.dart                   # FlowdayApp : thème + providers + porte d'authentification
│   ├── home_shell.dart            # coque : barre de nav + onglets + bascule timeline
│   └── theme/app_theme.dart       # AppColors (charte) + AppTheme.light()
├── core/                          # briques transverses
│   ├── constants/
│   ├── errors/api_exception.dart  # erreurs REST : message FR générique + détail console
│   ├── network/supabase_config.dart  # URL du projet + clé anon (dart-define)
│   ├── network/supabase_auth_client.dart  # client GoTrue : inscription/connexion/refresh
│   ├── network/supabase_rest_client.dart  # client PostgREST (jeton, retry 401, erreurs)
│   ├── providers/auth_provider.dart  # session : état, persistance, connexion, refresh
│   ├── providers/tasks_provider.dart  # état global : tâches, catégories, stats, CRUD
│   ├── router/
│   ├── security/
│   ├── storage/
│   └── ui/
│       ├── buttons/
│       ├── skeleton/
│       └── states/
├── features/                      # une fonctionnalité = data / domain / presentation
│   ├── account/                   # profil utilisateur + stats API
│   │   ├── data/  domain/  presentation/profile_screen.dart
│   ├── auth/                      # connexion / inscription (Supabase Auth)
│   │   ├── data/  domain/  presentation/auth_screen.dart
│   │   │                        presentation/auth_login_view.dart
│   │   │                        presentation/auth_signup_view.dart
│   │   │                        presentation/auth_widgets.dart
│   ├── dashboard/                 # accueil (« Hey Mobina ! »)
│   │   ├── data/  domain/  presentation/dashboard_screen.dart
│   ├── tasks/                     # timeline + formulaire (création/édition/suppression)
│   │   ├── data/  domain/  presentation/timeline_screen.dart
│   │   │                        presentation/task_form_screen.dart
│   ├── calendar/
│   │   ├── data/  domain/  presentation/calendar_screen.dart
│   └── settings/
│       ├── data/  domain/  presentation/settings_screen.dart
└── shared/                        # éléments partagés entre features
    ├── data/task_repository.dart  # accès Supabase → modèles (F1–F7 + stats)
    ├── models/models.dart         # Category, TaskItem (date/heure API), WeekDay, ProfileStats
    ├── utils/date_utils.dart      # formats AAAA-MM-JJ, HH:MM, semaine, mois (sans intl)
    └── widgets/                   # bottom_nav_bar, task_list_item, timeline_tile…
```

- `core/network` : `SupabaseConfig` (URL du projet + clé anon, surcharge
  `--dart-define=FLOWDAY_SUPABASE_URL` / `_ANON_KEY`), `SupabaseAuthClient`
  (GoTrue : inscription, connexion, rafraîchissement, déconnexion) et
  `SupabaseRestClient` (PostgREST, jeton utilisateur, retry 401, timeout
  10 s, erreurs → `ApiException`).
- `core/providers` : `AuthProvider` (session : restauration locale,
  connexion/inscription/déconnexion, renouvellement des jetons) et
  `TasksProvider` (ChangeNotifier) — état partagé entre
  accueil / timeline / calendrier / profil, chargements et mutations.
- `shared/data` : `TaskRepository` convertit le JSON de Supabase en modèles.
- `features/*/presentation` : écrans branchés sur le provider.
- Les données de maquette sont déplacées dans `test/fixtures/`
  (fixture des tests, plus aucun écran ne les utilise).

### Interactions actives (UI + logique API en phase 3)

- Bascule entre les 4 onglets de la barre de navigation.
- « See all » → ouvre la timeline « Today's task », flèche ← → retour.
- Sélection d'un jour dans le sélecteur de semaine (recharge les tâches
  via `planning_task?date=eq.AAAA-MM-JJ`).
- Bouton **+** → ouvre l'écran de formulaire (création réelle via l'API).
- Sélection d'une catégorie dans le formulaire (catégories de l'API).
- Interrupteurs des paramètres (état local uniquement).

### Vérifications

- `flutter analyze` : **0 problème**
- `flutter test` : **5 tests passés** :
  - accueil conforme au design, ouverture de la timeline via « See all »,
    retour, section « Yesterday's task » ;
  - calendrier responsive sur 4 tailles d'écran (320×568, 390×844,
    768×1024, 1280×800) : aucun débordement, grille et défilement OK.

---

## ✅ Phase 2 — Backend Django / DRF (réalisé)

**Dossier : `../flowday_api/`** (à côté du projet Flutter, hors de `flowday/`)

Backend REST créé avec **Django 6.1 + Django REST Framework 3.18**, base
**Supabase** (Postgres managé en ligne : `DATABASES` → pooler Supabase
`aws-0-eu-central-1.pooler.supabase.com`, toutes les migrations + le seed
des 4 catégories y sont appliqués ; l'ancien `db.sqlite3` local n'est plus
utilisé), API publique (pas d'auth pour le MVP, conforme au README §7).
Documentation complète : `flowday_api/README.md`.

### Ce qui est couvert (MVP du README §2)

| Réf | Fonctionnalité | Endpoint |
|---|---|---|
| F1 | Tâches du jour triées par heure | `GET /api/tasks/?date=AAAA-MM-JJ` |
| F2 | Tâches d'une semaine (sélecteur) | `GET /api/tasks/?start=&end=` |
| F3 | Création (titre obligatoire, heure valide) | `POST /api/tasks/` |
| F4 | Modification de tous les champs | `PUT` / `PATCH /api/tasks/<uuid>/` |
| F5 | Suppression | `DELETE /api/tasks/<uuid>/` |
| F6 | Terminer / déterminer | `POST /api/tasks/<uuid>/toggle/` |
| F7 | Catégories + couleurs | `GET /api/categories/` |
| F8 | Persistance côté serveur | Base **Supabase** en ligne |
| §3.5 | Statistiques du profil | `GET /api/stats/` |

### Détails

- **Modèles** (`planning/models.py`) : `Category` (id slug, name, color) et
  `Task` (UUID, title, description, date, time, category, completed,
  reminder, created_at) — README §5.
- **Seed des catégories** (`0002_seed_categories.py`) : Work `#F4761F`,
  Health `#F5C542`, Personal `#F05B52`, Education `#4E8CFF`.
- **Validation** (`serializers.py`) : titre non vide → 400, heure au format
  `HH:MM` (24 h), date `AAAA-MM-JJ`, catégorie existante ; nouvelle tâche →
  `completed: false`.
- **Tri** : toujours par heure croissante (README §4).
- **CORS** activé (Flutter Web) ; `ALLOWED_HOSTS = ['*']` en dev.
- **Swagger / OpenAPI** : `drf-spectacular` exposant `/api/docs/`
  (Swagger UI), `/api/schema/` (OpenAPI 3) et `/api/redoc/` — la doc est
  générée depuis les serializers + annotations `@extend_schema`.
- **Flutter** : URL candidates selon la plateforme (`127.0.0.1` avec
  `adb reverse` pour téléphone, repli `10.0.2.2` pour l'émulateur, surcharge
  `--dart-define=FLOWDAY_API_URL`) + snippet `package:http` dans le README
  de l'API.

### Vérifications backend

- `manage.py test` : **14 tests OK** (seed F7, création/validations F3,
  tri + filtres jour/semaine/catégorie F1-F2-F7, modification F4,
  suppression F5, toggle F6, stats §3.5)
- `manage.py check` : aucune erreur
- `manage.py spectacular` : schéma OpenAPI 3 généré sans erreur (6 chemins)
- Test curl : catégories, création, titre vide → 400, liste du jour
  triée, stats — tout répond correctement sur `http://127.0.0.1:8000/api/`
- Swagger : `/api/docs/` → 200 (Swagger UI « Flowday API »),
  `/api/schema/` → OpenAPI 3.0.3 en JSON, `/api/redoc/` → 200

### Démarrage rapide

```bash
cd ../flowday_api
.venv/bin/python manage.py runserver   # → http://127.0.0.1:8000/api/
```

---

## ✅ Phase 3 — Logique côté Flutter : Flutter branché sur l'API (réalisé)

### Ajouts de dépendances

- `http` (client HTTP) et `provider` (gestion d'état — choix « Provider »
  du README §7) ajoutés à `pubspec.yaml`.

### Couches créées

| Couche | Fichier | Rôle |
|---|---|---|
| Réseau | `lib/core/network/supabase_config.dart` + `supabase_rest_client.dart` | `SupabaseConfig` (URL du projet + clé anon) et `SupabaseRestClient` : accès direct PostgREST (filtres `eq./gte./lte.`, catégorie embarquée, `Prefer: return=representation`, timeout 10 s, erreurs → `ApiException`) — l'ancien `ApiClient` (URL par plateforme) a été retiré en phase 4 |
| Erreurs | `lib/core/errors/api_exception.dart` | `ApiException` : code HTTP + message (PostgREST ou DRF) + erreurs par champ (`{'title': …}`) |
| Repository | `lib/shared/data/task_repository.dart` | `TaskRepository` : `fetchCategories`, `fetchTasks(date/start/end/category)`, `createTask`, `updateTask`, `deleteTask`, `toggleTask`, `fetchStats` → JSON converti en modèles |
| État | `lib/core/providers/tasks_provider.dart` | `TasksProvider` (ChangeNotifier) : catégories, tâches d'aujourd'hui / d'hier / du jour sélectionné, stats, `selectDate` (partagé timeline ↔ calendrier), mutations F3→F6 avec mise à jour optimiste et rollback, états loading/erreur |
| Modèles | `lib/shared/models/models.dart` | `TaskItem` porte `date` (`AAAA-MM-JJ`) et `time` (`HH:MM`) avec `timeLabel` (`02:00 PM`), `Category.fromJson`, `ProfileStats` (taux recalculé côté client) |
| Dates | `lib/shared/utils/date_utils.dart` | `FlowDates` : formats API/affichage, noms de mois/jours, semaine lundi→dimanche (sans dépendance `intl`) |

### Écrans branchés (F1–F7)

- **Accueil** : catégories réelles (F7, descriptions/icônes par id),
  « Today's task » / « Yesterday's task » chargées et triées par heure (F1),
  états chargement / erreur (« Réessayer ») / vide, tap sur une tâche →
  formulaire en modification (F4).
- **Timeline** : semaine réelle (lundi→dimanche de la semaine courante),
  date et grand titre dynamiques, tâches du jour sélectionné via l'API,
  états chargement / erreur / vide, **F6** : appui sur le point ou sur le
  bouton check → `POST …/toggle/` (optimiste, rollback si échec),
  tap sur la carte → feuille Modifier (F4) / Supprimer avec confirmation (F5).
- **Formulaire** : titre obligatoire (validation client + erreurs DRF
  affichées champ par champ), **sélecteurs natifs de date et d'heure**
  (`showDatePicker` / `showTimePicker` → formats API), catégories issues de
  l'API, création (F3) / enregistrement (F4) / suppression avec confirmation
  (F5), état « Enregistrement… » sur le bouton.
- **Calendrier** : mois réel navigable (← →), jours cliquables → même date
  que la timeline, résumé avec **nombre réel de tâches** du jour (F1) et
  bouton « Voir les tâches du jour » qui ouvre la timeline sur cette date.
- **Profil** : statistiques réelles (`GET /api/stats/` : terminées, taux de
  réussite, cette semaine) avec états chargement / erreur.
- **Coque** : injection du repository (`FlowdayApp(repository: …)`), ouverture
  du formulaire depuis le **+** et depuis les tâches.

### Itération — recherche dynamique + page catégorie (réalisé)

- **Recherche dynamique** (accueil) : champ `TextField` réel qui filtre en
  direct les tâches affichées (titre + description) et les noms de
  catégories ; message « Aucun résultat pour « … » » avec sections
  masquées ; bouton (×) qui remplace l'icône de filtre pendant la saisie
  pour effacer la recherche.
- **Flèche sur toutes les cartes** : chaque carte de catégorie a sa flèche
  (fond blanc sur carte sombre, fond sombre sur carte claire) et la carte
  entière est cliquable → **page « tâches de la catégorie »**
  (`lib/features/tasks/presentation/category_tasks_screen.dart`) :
  en-tête sombre (nom + icône + compteur), toutes les tâches de la
  catégorie groupées par date, tap sur une tâche → modification (F4) avec
  rechargement au retour, états chargement / erreur / vide.
- **Backend** : `GET /api/tasks/?category=<id>` pour lister les tâches
  d'une catégorie sur tous les jours (combinable avec `?date=`).
- **Partagé** : `lib/shared/widgets/category_meta.dart`
  (descriptions / icônes par id, accueil ↔ page catégorie) et
  `lib/core/ui/states/error_state.dart` (`ErrorState` : message +
  « Réessayer »).

### Plateformes

- Android : `android:usesCleartextTraffic="true"` ajouté au manifeste (HTTP
  en dev).
- iOS : `NSAppTransportSecurity → NSAllowsArbitraryLoads` ajouté à
  `Info.plist` (HTTP en dev).

### Tests (phase 3)

- `test/fakes/fake_task_repository.dart` : faux repository qui simule l'API
  (tâches datées de la date demandée, mutations enregistrées).
- `test/fixtures/mock_data.dart` : données de maquette déplacées depuis
  `lib/` (les écrans ne les utilisent plus).
- `test/widget_test.dart` : accueil (design + catégories/tâches du faux),
  ouverture de la timeline (date du jour, `02:00 PM`), retour, onglet Profil
  avec statistiques (12/30 → 40 %).
- `test/logic_test.dart` : **F3** création réelle via le formulaire,
  validation titre obligatoire (aucun appel réseau), **F6** toggle depuis la
  timeline, **F4** modification depuis la timeline, **recherche dynamique**
  (aucun résultat → sections masquées, filtre réel, effacement), **carte de
  catégorie → page des tâches** (flèches, compteur, groupement par date,
  ouverture du formulaire F4, retour).
- `test/calendar_responsive_test.dart` : calendrier responsive sur 4 tailles
  d'écran, mois réel et résumé issu de l'API.
- `test/live_api_test.dart` : **intégration réelle** avec la base Supabase
  (catégories seedées, création aux bons formats `AAAA-MM-JJ` / `HH:MM`,
  listing par date, filtre catégorie, modification, toggle ×2, stats,
  suppression, 404 → `ApiException`) — sans serveur ni tunnel, un seul tour :
  `FLOWDAY_LIVE=1 flutter test test/live_api_test.dart`.

### Vérifications phase 3

- `flutter analyze` : **0 problème**
- `flutter test` : **11 tests OK** + 1 test d'intégration réel OK
- `manage.py test` (backend) : **14 tests OK**
- **Base en ligne (Supabase)** : `FLOWDAY_LIVE=1 flutter test …` OK —
  création / lecture / mise à jour / toggle / suppression vérifiées dans le
  cloud, tâche de démo « Yoga » restaurée en ligne.
- `flutter build web` : compilation OK (pas de `dart:io` dans `lib/`)
- **Test de bout en bout sur téléphone physique** (`R3CT3107NRL`, USB) :
  APK installé et lancé → l'API reçoit bien les 5 appels de démarrage
  (`categories`, `tasks` aujourd'hui/hier/jour, `stats`) en 200 via
  `adb reverse`, capture d'écran : accueil affichant les catégories issues
  de l'API ; relance via `flutter run` : tunnel préservé, données rechargées.

### Démarrage (Flutter — accès direct Supabase)

```bash
# L'application parle directement à Supabase : aucun serveur, aucun tunnel.
cd flowday && flutter run

# Surcharges optionnelles (autre projet / autre clé) :
flutter run \
  --dart-define=FLOWDAY_SUPABASE_URL=https://<projet>.supabase.co \
  --dart-define=FLOWDAY_SUPABASE_ANON_KEY=sb_publishable_…

# Backend Django (optionnel : admin, Swagger, tests — plus requis pour l'app)
cd ../flowday_api && .venv/bin/python manage.py runserver
```

**Premier lancement (phase 5)** : l'écran de connexion s'affiche.

- **Compte de démo** : `flowday.test@gmail.com` / `Flowday!Test2026`
  (les 5 tâches existantes y sont rattachées).
- **Ou inscription** avec votre adresse : un e-mail de confirmation est
  envoyé (validez-le avant de vous connecter) ; les tâches de démo
  restent sur le compte de démo — dites-nous votre adresse pour les
  basculer.
- La session reste ouverte localement ; « Se déconnecter » se trouve
  dans l'onglet Paramètres → section Compte.

### Évolutions prévues (post-MVP)

Notifications et rappels, vue calendrier mensuelle avec indicateurs de jours
chargés, catégories personnalisées, profil avec statistiques réelles,
paramètres (thème clair, langue), tâches récurrentes, synchronisation cloud,
recherche et filtres.

---

## ✅ Phase 4 — Accès direct Supabase (réalisé)

**Objectif** : le data-layer Flutter parle **directement** à la base
Supabase (PostgREST) — l'application fonctionne depuis n'importe quel
appareil connecté à internet, sans serveur Django ni tunnel `adb reverse`.

### Corrections réalisées

- **Identifiants hors du code** (« première erreur ») : `config/settings.py`
  lit `DATABASE_URL` via `python-dotenv` ; le secret vit dans
  `flowday_api/.env` (ignoré par git, modèle `.env.example` fourni).
  Django refuse de démarrer sans cette variable. Ajouts à
  `requirements.txt` : `dj-database-url==3.1.2`, `python-dotenv==1.2.4`.
- **Politiques RLS** : les tables avaient RLS **activé sans aucune
  politique** (le rôle `anon` ne voyait rien). Deux politiques créées :
  `planning_task_anon` et `planning_category_anon`
  (`FOR ALL TO anon USING (true) WITH CHECK (true)`), réversibles par
  `DROP POLICY`.

### Nouveaux fichiers

| Fichier | Rôle |
|---|---|
| `lib/core/network/supabase_config.dart` | URL du projet + clé anon (valeurs par défaut embarquées, surcharge `--dart-define=FLOWDAY_SUPABASE_*`) |
| `lib/core/network/supabase_rest_client.dart` | Client PostgREST : GET/POST/PATCH/DELETE, en-têtes `apikey` + `Authorization`, `Prefer: return=representation` (détecte les mutations sans ligne → 404), timeout 10 s, erreurs → `ApiException` |
| `lib/shared/data/task_repository.dart` (**réécrit**) | Interface inchangée (le provider et les écrans n'ont pas bougé) : filtres `eq.` / plage `gte.+lte.` répétée, catégorie embarquée `planning_category(id,name,color)` en une seule requête, `id` (uuid v4) + `created_at` générés côté client (colonnes NOT NULL **sans défaut** en base), toggle en 2 requêtes, stats recalculées (lundi → aujourd'hui, identique au backend) |
| `lib/core/errors/api_exception.dart` (**adapté**) | Parse aussi les erreurs PostgREST (`message`/`code`) avec traduction des codes fréquents (`23502`, `23503`, `PGRST116`…) |

- `lib/core/network/api_client.dart` (ancien client DRF à URL candidates) :
  **supprimé** — l'unique URL HTTPS Supabase rend la logique de repli
  (`127.0.0.1` → `10.0.2.2`) inutile.

### Vérifications phase 4

- `flutter analyze` : **0 problème**
- `flutter test` : **11 tests OK** + 1 ignoré (live sans flag)
- `FLOWDAY_LIVE=1 flutter test test/live_api_test.dart` : **OK en 8 s**
  contre Supabase en direct (CRUD complet, toggle, stats, 404)
- `manage.py test --keepdb` : **14 tests OK** (le backend conserve admin,
  Swagger et ses tests)
- `flutter build web` : OK (CORS Supabase ouvert par défaut)

### Sécurité (à connaître)

- ⚠️ **Corrigé en Phase 5** : les politiques `USING (true)` du rôle
  `anon` (accès total avec la clé publique) ont été remplacées par des
  politiques **par utilisateur** (`auth.uid()`) + écran de connexion —
  voir « Phase 5 » ci-dessous.
- Le mot de passe de la base reste dans `flowday_api/.env` (local, hors
  git) ; s'il a été partagé, le faire tourner dans le dashboard Supabase
  puis mettre `.env` à jour (étape encore à faire : voir Phase 5).

---

## ✅ Phase 5 — Sécurité, erreurs professionnelles & interactions (réalisé)

**Objectif** : corriger les deux points de sécurité signalés (accès
total avec la clé publique, mot de passe exposé), professionnaliser la
gestion d'erreurs et dynamiser les interactions demandées (calendrier,
dashboard, cartes cliquables).

### 1. Sécurité — authentification réelle (Supabase Auth)

- **Politiques RLS par utilisateur** (remplacement des politiques
  `USING (true)` largement ouvertes) :
  - `planning_task.user_id uuid REFERENCES auth.users(id)` +
    `DEFAULT auth.uid()` (le jeton de l'utilisateur connecté est écrit
    automatiquement à l'insertion) + index sur `user_id` ;
  - `task_select` / `task_insert` / `task_update` / `task_delete` :
    `TO authenticated … user_id = auth.uid()` ;
  - `category_select` : `TO authenticated USING (true)` (catégories
    partagées, non sensibles) ;
  - **plus aucune politique pour `anon`** : sans connexion la base est
    vide (vérifié en curl : lecture → `[]`, écriture → refus `42501`).
  - Les 5 tâches existantes sont rattachées au compte de démo
    (`planning_task.user_id`).
- **Écran d'authentification** (`features/auth/presentation/`) — rendu
  du design fourni, découpé en 4 fichiers :
  - `auth_screen.dart` : coque à **onglets pilule** « Log In / Sign Up »
    (bascule sans navigation) sur fond clair à **lignes ondulées**
    (`WaveBackgroundPainter`) ;
  - `auth_login_view.dart` : carte sombre « Welcome Back! », illustration
    bouclier, **champs à libellé flottant**, bouton fléché, **mot de
    passe oublié** (e-mail GoTrue `/recover`, message générique — aucun
    compte révélé), boutons sociaux (affichent « non disponible » car
    l'OAuth Google/Apple n'est pas configuré) ;
  - `auth_signup_view.dart` : cartes d'étapes « Choose a Name / Set a
    Password », champs Nom complet / E-mail / Mot de passe (nom envoyé
    dans `user_metadata.full_name`), lien de retour à la connexion ;
  - `auth_widgets.dart` : composants partagés (`AuthTextField` à libellé
    flottant, `AuthPrimaryButton`, `AuthDarkHeader`, `AuthErrorBox`,
    `AuthSocialButton`, `AuthDivider`).
  Validation côté client (messages FR), état de chargement,
  messages professionnels ; la confirmation par e-mail (activée sur le
  projet) bascule sur l'onglet Log In avec un message d'information.
- **Session** : jetons conservés **localement** (`shared_preferences`,
  aucun mot de passe stocké), restauration au démarrage,
  **rafraîchissement automatique sur 401** (le client REST renouvelle le
  jeton puis retente la requête une seule fois), déconnexion automatique
  si la session n'est plus valide. Section « Compte » dans Paramètres
  (e-mail + « Se déconnecter ») ; les données sont vidées à la
  déconnexion (`TasksProvider.reset()`).
- **Compte de démo / tests** : `flowday.test@gmail.com`
  (`Flowday!Test2026`) — confirmé en base (les nouveaux inscrits
  reçoivent un e-mail de confirmation à valider).
- **Rotation du mot de passe** (reste à faire, action dashboard) :
  impossible en SQL (le rôle `postgres` Supabase n'est pas superuser) →
  dashboard Supabase → **Project Settings → Database → Reset database
  password**, puis mettre `flowday_api/.env` à jour (README backend §1).

### 2. Gestion des erreurs professionnelle (sans fuite d'information)

- `ApiException.message` est **toujours** un message FR professionnel et
  générique : plus de « Clé API Supabase manquante : renseignez
  FLOWDAY_SUPABASE_ANON_KEY… », de noms de tables/colonnes (`null value
  in column "id" of relation "planning_task"…`) ni de « Serveur Supabase
  injoignable… ».
- Le détail brut du serveur part en **console uniquement**
  (`ApiException.details` + `debugPrint`), pour le diagnostic développeur.
- Mapping appliqué : réseau → « Impossible de joindre le serveur… »,
  401/403 → « Votre session a expirée. Veuillez vous reconnecter. »,
  404 → « Cet élément est introuvable… », 409/`23505` → « existe déjà »,
  5xx → « Le service rencontre un problème… » ; erreurs GoTrue traduites
  (identifiants incorrects, e-mail non confirmé, compte existant, mot de
  passe faible, limite d'envoi).

### 3. Calendrier & dashboard — « voir les tâches du jour » dynamique

- **Correctif** : depuis le Calendrier, « Voir les tâches du jour »
  n'activait que l'état timeline **sans changer d'onglet** (la timeline
  restait invisible derrière le calendrier). Le `HomeShell` bascule
  maintenant sur l'onglet Accueil **et revient à l'onglet d'origine**
  (Calendrier) à la fermeture de la timeline.
- La date est **transmise explicitement** : le calendrier ouvre la
  timeline sur le **jour sélectionné** ; « See all » de *Today's task*
  ouvre sur **aujourd'hui** et celui de *Yesterday's task* sur **hier**
  (fini la date résiduelle d'une sélection précédente).

### 4. Cartes « Today's task » cliquables

- Un clic sur une tâche (sections *aujourd'hui* **et** *hier*) **coche /
  décoche** la tâche (F6) avec retour visuel (SnackBar « … marquée comme
  terminée / réactivée »). L'édition reste accessible depuis la timeline
  et la page « tâches de la catégorie ».

### Nouveaux fichiers (phase 5)

| Fichier | Rôle |
|---|---|
| `lib/core/network/supabase_auth_client.dart` | Client GoTrue : `signUp` (session ou confirmation e-mail, nom dans `user_metadata`), `signIn` (password grant), `recover` (e-mail de réinitialisation), `refresh`, `signOut` ; `TokenSource` (jeton + renouvellement) ; messages d'erreur FR |
| `lib/core/providers/auth_provider.dart` | État de session (`unknown / unauthenticated / authenticated`), restauration et persistance locale, connexion / inscription / réinitialisation de mot de passe / déconnexion, `refreshSession()` appelé par le client REST sur 401 |
| `lib/features/auth/presentation/auth_screen.dart` | Coque à onglets Log In / Sign Up + fond à lignes ondulées (`WaveBackgroundPainter`) + message d'information après inscription |
| `lib/features/auth/presentation/auth_login_view.dart` | Vue connexion (« Welcome Back! », champs flottants, mot de passe oublié via GoTrue, boutons sociaux) |
| `lib/features/auth/presentation/auth_signup_view.dart` | Vue inscription (cartes d'étapes, Nom / E-mail / Mot de passe, lien retour connexion) |
| `lib/features/auth/presentation/auth_widgets.dart` | Composants du design : `AuthTextField` (libellé flottant), `AuthPrimaryButton`, `AuthDarkHeader`, `AuthErrorBox`, `AuthSocialButton`, `AuthDivider` |

Fichiers modifiés : `app.dart` (MultiProvider + `_AuthGate` : chargement
des données après connexion, `reset()` à la déconnexion), `home_shell.dart`
(bascule d'onglet + date + toggle SnackBar), `dashboard_screen.dart`
(See all daté + clic = F6), `calendar_screen.dart` (date transmise au
coque), `settings_screen.dart` (section Compte + déconnexion),
`supabase_rest_client.dart` (jeton utilisateur + retry 401 + messages),
`api_exception.dart` (messages sanitizés + `details` + `logDetails`),
`task_repository.dart` (`auth:`), `tasks_provider.dart` (`reset()`),
tests (session injectée via `AuthProvider.authenticated()`), `pubspec.yaml`
(+ `shared_preferences`).

### Vérifications phase 5

- `flutter analyze` : **0 problème**
- `flutter test` : **13 tests OK** + 1 ignoré (live sans flag)
  (dont `auth_screen_test` : rendu onglets Log In / Sign Up + validation
  avant tout appel réseau ; rendu visuel vérifié par captures golden
  temporaires — supprimées après contrôle)
- `FLOWDAY_LIVE=1 flutter test test/live_api_test.dart` : **OK en 9 s**
  (connexion GoTrue + CRUD complet sur tables RLS)
- `curl` RLS : anon lecture `[]`, insertion refusée `42501`, compte
  connecté → ses 5 tâches
- `manage.py test --keepdb` : **14 tests OK** ; `flutter build web` : OK

---

## ✅ Phase 6 — Déconnexion universelle, profil & auth backend (réalisé)

### 1. Déconnexion qui marche partout (app)

- **Cause racine** : le lien « Déconnexion » du profil (`_ProfileLink`)
  n'avait aucun `onTap` ; le bouton des Paramètres déconnectait sans
  confirmation ni retour visuel.
- `core/ui/confirm_sign_out.dart` : dialogue de confirmation partagé
  (« Se déconnecter ? », Annuler / Se déconnecter) utilisé par le profil
  **et** les Paramètres.
- Après confirmation : `signOut()` puis SnackBar « Vous êtes déconnecté. » —
  le messenger est capturé **avant** l'ouverture du dialogue pour survivre à
  la bascule d'écran ; les Paramètres ignorent l'action si `auth.busy`.

### 2. Photo de profil & informations éditables (app)

- `profile_edit_sheet.dart` : feuille « Modifier le profil » (nom complet,
  photo, nouveau mot de passe + confirmation ≥ 8 caractères) ;
  `image_picker` galerie → 512 px / qualité 80 → **data-URL base64 dans
  `user_metadata.avatar`** ; boutons « Changer » / « Retirer » ; erreurs FR
  locales ; sélecteur injectable (`ProfileImagePicker`) pour les tests.
- `supabase_auth_client.dart` : `updateUser` (GoTrue `PUT /user` —
  **remplace** `user_metadata` → le client envoie toujours le dictionnaire
  complet fusionné), `fetchUser` (`GET /user`), `_send` avec timeout couvrant
  toute la chaîne.
- `auth_provider.dart` : champ `metadata` (+ accesseurs `fullName` / `avatar`),
  `updateProfile({metadata, newPassword})`, métadonnées persistées avec la
  session, ctors `authenticated(...)` / `signedOut(...)` (session de test).
- `profile_screen.dart` : identité réelle (photo ou initiales ;
  `full_name` → sinon partie locale de l'e-mail) et 3 liens fonctionnels :
  « Modifier le profil » (feuille + SnackBar « Profil mis à jour. »),
  « Exporter mes tâches » (JSON dédoublonné par id dans le presse-papiers +
  SnackBar), « Déconnexion » (confirmation).
- `dashboard_screen.dart` : salut dynamique « Hey {prénom} ! » (fallback
  « Mobina » du design) + initiales d'avatar cohérentes.

### 3. Backend Django : app `accounts` (inscription / connexion / profil / photo)

| Endpoint | Rôle |
|---|---|
| `POST /api/auth/register/` | Inscription (e-mail, nom, mot de passe) → `Token` |
| `POST /api/auth/login/` | Connexion → `Token` |
| `POST /api/auth/logout/` | Déconnexion (204, jeton invalidé) |
| `GET` / `PATCH` `/api/auth/me/` | Profil : nom, e-mail, mot de passe (`current_password` requis) |
| `POST /api/auth/me/photo/` | Photo (multipart, 2 Mo max, Pillow ; remplace et supprime l'ancien fichier) |
| `DELETE /api/auth/me/photo/` | Suppression de la photo |

- Modèle `Account` (OneToOne `User` + `avatar ImageField` sous `MEDIA/`),
  `rest_framework.authtoken` en parallèle de la session, `Pillow==12.1.0`,
  `manage.py migrate` appliqué.
- **Architecture à double couche** : l'app Flutter parle à **Supabase
  GoTrue** (indispensable — les policies RLS des tâches lisent `auth.uid()`) ;
  l'API Django gère sa propre auth par **jeton** — deux couches
  complémentaires, sans donnée partagée.

### Nouveaux fichiers (phase 6)

| Fichier | Rôle |
|---|---|
| `flowday/lib/core/ui/confirm_sign_out.dart` | Dialogue de déconnexion partagé |
| `flowday/lib/features/account/presentation/profile_edit_sheet.dart` | Feuille d'édition (nom, photo, mot de passe) |
| `flowday/test/profile_screen_test.dart` | 4 tests : identité + déconnexion, enregistrement du nom, photo injectée, déconnexion Paramètres |
| `flowday_api/accounts/` | App Django : `models`, `serializers`, `views`, `urls`, `tests` (14), migration `0001` |

Fichiers modifiés : `profile_screen.dart` (refonte identité + liens),
`settings_screen.dart` (confirmation + feedback), `dashboard_screen.dart`
(salut dynamique), `supabase_auth_client.dart` (`updateUser` / `fetchUser` /
`_send`), `auth_provider.dart` (métadonnées + `updateProfile`),
`pubspec.yaml` (+ `image_picker`), `test/live_api_test.dart` (aller-retour
`PUT /user`), `flowday_api` : `config/settings.py`, `config/urls.py`,
`requirements.txt`, `README.md`.

### Vérifications phase 6

- `flutter analyze` : **0 problème**
- `flutter test` : **17 tests OK** + 2 ignorés (live sans flag)
- `FLOWDAY_LIVE=1 flutter test test/live_api_test.dart` : **2 tests OK**
  (CRUD complet + aller-retour `PUT /user` : nom → photo data-URL →
  restauration exacte, sur le compte réel)
- `manage.py test --keepdb` : **28 tests OK** (14 planning + 14 accounts)
- Smoke `curl` complet sur `127.0.0.1:8001` : register 201 → login 200 →
  `me` 200 → PATCH 200 → photo `POST` → URL `/media/profile_photos/2026/11/…`
  → `DELETE` → logout 204 → `me` **401** (script `/tmp/opencode/smoke_auth.sh`)
- Pas de `flutter build web` (instruction en vigueur)

### Itération visuelle — maquette auth, logo, skeletons, icônes (réalisé)

- **Auth redessiné conformément à la maquette** : grand en-tête sombre
  (titre / sous-titre / **cloche** à pastille, le titre suit l'écran),
  **feuille blanche** pleine hauteur à coins supérieurs arrondis, champs
  **pilule** à indicatif (libellé flottant abandonné au profit du rendu
  maquette), bouton fléché (texte centré + flèche à droite), « Forgot
  Password? » centré, sociaux en pastilles blanches ; l'inscription garde
  les cartes d'étapes et le lien « Already have an account? Log In ».
  **Les onglets visibles ont disparu** : la bascule se fait par les liens
  du bas (« Don't have an account? Sign Up ») ; le `TabController`
  interne fait foi — `auth_screen_test` mis à jour en conséquence.
  *(Rendu ensuite remplacé par la maquette Stitch — voir « Itération
  visuelle 2 » ci-dessous.)*
- **`FlowdayLogo`** (`shared/widgets/flowday_logo.dart`, `CustomPaint`
  fourni) : affiché au **démarrage** (`_Splash` remplace le simple
  texte + rond), en carte héros de la page de connexion *(celle-ci a été
  remplacée depuis par l'en-tête cursive de la maquette Stitch)*, et utilisé pour
  **régénérer toutes les icônes** (fini le logo Flutter à l'ouverture) :
  Android `mipmap-*` (5 densités, y compris le splash Android 12+),
  iOS `AppIcon` (20 tailles, sans alpha), macOS (7 tailles, coins
  arrondis), web (`favicon` + `Icon-192/512` + versions `maskable`),
  Windows `app_icon.ico` (multi-tailles). Masters rendus via le painter
  (test one-shot supprimé) puis redimensionnés (Pillow).
- **Skeletons partout** : `shared/widgets/skeleton.dart` (bloc shimmer +
  `SkeletonTaskTile` / `SkeletonStatCard` / `SkeletonTaskList`) remplace
  les ronds de chargement **de contenu** — accueil (l'en-tête reste
  visible), statistiques du profil, tâches d'une catégorie, timeline,
  résumé du calendrier ; les ronds restent pour les **actions**
  (soumission de formulaire, enregistrement du profil).
- **Doublons nettoyés** : les 3 copies de « La lettre de stage » (créées
  dans la même minute le 11/11) ont été supprimées via l'API —
  l'originale (15:15, terminée) est conservée.

Vérifications de l'itération : `flutter analyze` **0 problème**,
`flutter test` **17 tests OK**, rendus contrôlés par captures golden
temporaires (login + inscription + icônes, supprimées après contrôle).

### Itération visuelle 2 — maquette Stitch des écrans d'auth (réalisé)

Rendu repris du projet Stitch fourni (`725b78a47155410493afa6ab85bf8875`,
code Dart de référence) — **remplace** la maquette précédente sur
connexion/inscription uniquement ; le reste de l'app est inchangé.

- **Connexion / inscription** : fond `#F8F9FD`, **en-tête noir
  full-bleed** à coins inférieurs arrondis (36) — marque « Flowday » en
  **cursive Dancing Script**, accroche grise (« Prêt pour une journée
  productive ? » / « Organisez votre quotidien »), titre de l'écran et
  bénéfice ; champs **cartouches à libellé flottant**
  (`FloatingInputField` : carte blanche, bord `#E5E7EB`, icône préfixe,
  œil de visibilité du mot de passe), « Mot de passe oublié ? » aligné
  à droite (dialogue GoTrue), **bouton primaire noir fléché**
  (`PrimaryFlowButton`), séparateurs « OU CONTINUER AVEC » /
  « OU S'INSCRIRE AVEC », **boutons sociaux larges** (Google en « G »
  quadricolor vectoriel + Apple) et liens « Pas encore de compte ?
  S'inscrire » / « Déjà un compte ? Se connecter ».
- **Tout en français** : libellés, boutons, liens et dialogues
  (« Se connecter », « Créer un compte », « Annuler » /
  « Envoyer le lien ») ; les validateurs FR sont inchangés.
- **Bascule par `AnimatedSwitcher`** (350 ms) : le `TabController`
  interne et la cloche de l'en-tête ont été supprimés. La logique GoTrue
  est intégralement conservée — validation client (aucun appel réseau
  tant que le formulaire est invalide), `signIn` / `signUp` avec
  état busy, `recover` du mot de passe oublié, e-mail de confirmation →
  retour à la connexion + SnackBar.
- **Typographie** : Poppins reste la police de l'app (choix du projet,
  README §6) ; seul le titre de marque du header utilise **Dancing
  Script** (police variable embarquée dans `fonts/`, appliquée via
  `fontVariations: wght 700` — aucun téléchargement à l'exécution).
- **Composants** : `auth_widgets.dart` entièrement refait
  (`AuthColors`, `FlowdayHeader`, `FloatingInputField`,
  `PrimaryFlowButton`, `DividerWithLabel`, `SocialAuthButton`,
  `AuthErrorBox`) ; les anciens (`AuthTextField`, `AuthPrimaryButton`,
  `AuthHeader`, `AuthDivider`, `AuthSocialButton`,
  `WaveBackgroundPainter`) ont été supprimés.
- **Robustesse** : liens du bas protégés par `FittedBox` (pas de
  débordement en petite largeur ni avec une grande police système) ;
  `FlowdayLogo` n'apparaît plus sur la connexion (la maquette n'affiche
  que le texte cursive) — il reste au démarrage et source de toutes les
  icônes.
- **Tests** : `auth_screen_test` réécrit (assertions FR, bascule par
  liens, validation avant appel réseau) ; `profile_screen_test` cible
  l'accroche du nouvel en-tête après déconnexion.

Vérifications : `flutter analyze` **0 problème**, `flutter test`
**17 tests OK + 2 skip (live)**, rendus contrôlés par captures golden
temporaires (login + inscription, supprimées après contrôle).

### Itération visuelle 3 — nouveau logo & icônes (réalisé)

- **Logo repris de la maquette fournie** (Stitch
  `7a0bd5e42a6444c29e43adfe9bf3dfbc`) : `flowday_logo.dart` entièrement
  refait — carré sombre `#1E1E22`, **vagues texturées**
  (`BackgroundWavesPainter`, trait vectoriel mis à l'échelle), halo
  radial et **symbole « F » sculptural** (`StylizedFLogoPainter` :
  F argenté, coche blanche sur poche sombre, badge calendrier avec
  attaches et pastilles). Props `framed` (carré arrondi + ombre pour le
  splash) et `symbolScale` (0.72 standard / 0.56 zone sûre maskable) ;
  conversion `withValues(alpha:)`.
- **Toutes les icônes régénérées** à partir de masters 1024 px rendus
  par test one-shot (supprimé après usage) puis redimensionnées
  (Pillow) : Android `mipmap-*` (5 tailles), iOS (15 fichiers, RGB
  sans alpha), macOS (7 tailles, coins arrondis 22,5 %), web
  (`favicon` 32 + `Icon-192/512` + `Icon-maskable-192/512` à zone
  sûre), Windows `app_icon.ico` (7 tailles) — 32 PNG + 1 ICO vérifiés
  (dimensions et modes).
- **Backend** : mot de passe Supabase tourné, `DATABASE_URL` de
  `flowday_api/.env` mis à jour — **28 tests Django OK** ; tests live
  Flutter (GoTrue + PostgREST) **2 OK**.

### Itération visuelle 4 — continuité dashboard (réalisé)

- **En-tête d'auth aligné sur l'en-tête du dashboard** : carte
  **anthracite `AppColors.dark` (#202020)** à coins inférieurs arrondis
  (32), mêmes **lignes d'ondes** (`WavePainter`, blanc 5,5 %) et
  **typographie géométrique blanche affirmée** (marque « Flowday » en
  Poppins w800, accroche `white70`, titre 25 bold, bénéfice `white70`)
  — alignement à gauche comme le dashboard. La cursive Dancing Script
  est abandonnée : police supprimée (`fonts/` + `pubspec.yaml`).
- **Formulaires resserrés** : gouttière horizontale 24 → **40** et
  largeur bornée à **420 max centrée** (les champs paraissent moins
  larges sur téléphone, sur tablette/desktop le formulaire reste
  centré). *→ réverti en Itération 7 (gouttière 24, sans borne).*
- **Splash en fond blanc** : `_Splash` sur `Colors.white`, le logo
  (carte anthracite) reste **toujours en noir**.
- **Icônes/logo unifiés sur l'univers dashboard** : fond du logo passé
  de `#1E1E22` à **`AppColors.dark` (#202020)** — même anthracite que
  l'en-tête ; masters régénérés et **toutes les icônes refaites**
  (Android 5, iOS 15, macOS 7, web 5, ICO 7 tailles), contrôle de la
  couleur du master (32,32,32).
  **Annulé sur demande** : retour à la couleur d'origine **`#1E1E22`**
  (design de référence conservé, vagues `BackgroundWavesPainter`
  inchangées) — masters + toutes icônes régénérés à nouveau
  (contrôle du master : 30,30,34). Seul l'en-tête d'auth conserve
  l'anthracite dashboard `#202020` ; le splash reste blanc avec le
  logo toujours en noir.

Vérifications : `flutter analyze` **0 problème**, `flutter test`
**17 tests OK + 2 skip (live)**, rendus contrôlés par captures golden
temporaires (login + inscription, supprimées après contrôle).

### Itération 5 — confirmation d'inscription par lien (deep link) (réalisé)

- **Problème** : le lien de confirmation e-mail redirigeait vers le
  Site URL par défaut (`http://localhost:3000`) — page inutilisable sur
  un téléphone.
- **Solution : flux PKCE + deep link `flowday://login-callback`** (l'app
  reçoit le lien, échange le code, s'ouvre connectée) :
  - `core/network/pkce.dart` : paire PKCE RFC 7636 (vérificateur 43
    caractères + défi `s256`), preuve de référence RFC 7636 testée ;
  - `SupabaseAuthClient.signUp` envoie `code_challenge` /
    `code_challenge_method: s256` **et** `redirect_to=
    flowday://login-callback` (query) ; nouvel
    `exchangeCode(authCode, codeVerifier)` → `POST token?grant_type=pkce` ;
  - `AuthProvider` : vérificateur conservé en mémoire **et** local
    (`fd.auth.pkce`, survit à un redémarrage avant le clic),
    `completeEmailConfirmation(code)` ouvre la session (nettoyage du
    vérificateur, métadonnées, persistance), messages transitoires
    `notice` / `showNotice` / `consumeNotice` ; `restoreSession` ne
    peut plus écraser une session ouverte par un lien (course
    restauration ↔ échange) ;
  - `core/providers/auth_deep_links.dart` (`app_links`) : lien initial
    lu **après** la restauration (`ready`), `uriLinkStream` en cours
    d'exécution, déduplication du code, erreurs silencieuses (plugin
    absent en tests) ; branché dans `_FlowdayAppState` uniquement hors
    tests + `dispose` ;
  - plateformes : intent-filter Android (`scheme flowday`,
    `host login-callback`, BROWSABLE) et `CFBundleURLTypes` iOS
    (schéma `flowday`) ; `AuthScreen` affiche les messages
    transitoires en SnackBar (listener + rattrapage du message reçu
    pendant le splash).
- **Configuration Supabase requise (dashboard, à faire une fois)** :
  Authentication → URL Configuration → **Redirect URLs** : ajouter
  `flowday://login-callback` ; **Site URL** : `flowday://login-callback`
  (les deux rôles de repli sont ainsi sur le deep link).
- **Tests** : `test/auth_pkce_test.dart` (7 tests — formats, vecteur
  RFC, requêtes signup/échange, session ouverte, refus sans inscription,
  refus sur mauvais vérificateur).
- **Limite connue** : la réinitialisation de mot de passe (`recover`)
  n'a pas d'écran in-app — son lien reste non traité (hors périmètre,
  à traiter avec un écran « nouveau mot de passe »).

Vérifications : `flutter analyze` **0 problème**, `flutter test`
**24 tests OK + 2 skip (live)**.

---

## 🎨 Itération 6 — nouveau logo, titres cursive, interactions allégées

Demandes regroupées (12 nov.) :

- **Nouveau logo Flowday** (maquette fournie) : `flowday_logo.dart`
  réécrit — carte noire dégradée arrondie (#292930 → #17171D → #08080D)
  avec ombre portée, 15 vagues #A5A5B9 à 18 %, « F » blanc sculptural,
  coche et badge calendrier. Adapté à nos conventions :
  `withValues(alpha:)`, plus les paramètres `framed` (carte arrondie en
  usage applicatif / plein cadre pour les icônes) et `symbolScale`
  (0.56 = zone sûre des icônes maskables). Le splash utilise ce logo
  sur fond **blanc** (Flutter + lancement natif Android/iOS déjà blancs).
- **Icônes régénérées (33 fichiers)** : masters 1024 px rendus par un
  test one-off (supprimé après exécution), puis Android (5 dpi), iOS
  (15, RGB opaque, tailles base × facteur), macOS (7, coins arrondis
  22,5 %), web (5, dont 2 maskables sur le master à échelle réduite) et
  Windows (ICO 7 tailles). Contrôles : coin du master (41,41,48) =
  dégradé #292930, symbole hors zone sûre confirmé sur le maskable.
- **Titres principaux en Dancing Script** (police re-téléchargée,
  variable, déclarée dans `pubspec.yaml`) via `fontVariations wght 700` :
  titre des écrans d'authentification (31 px), héros du dashboard
  (« Let's find your best day! », 29 px), titre de la timeline
  (« Today »/jour, 42 px), « Profil » et « Paramètres » (38 px). La
  marque « Flowday » (en-tête d'auth + splash) reste en Poppins
  géométrique. Vérifié par captures d'écrans (polices réelles chargées
  dans le test).
- **Case à cocher des tâches** : plus de message « … marquée comme
  terminée » / « … réactivée » à chaque bascule (fluidité perçue) —
  seul un échec serveur affiche encore « Action impossible pour le
  moment. Réessayez. » (`home_shell._toggleTask`).
- **Dialogue « Se déconnecter ? »** simplifié : la **croix** tient lieu
  de bouton « Annuler » (supprimé) et un **seul bouton** rouge
  « Se déconnecter » pleine largeur (flex, avec icône) termine
  l'action (`confirm_sign_out.dart`).
- **En-têtes dynamiques (photo de profil)** : l'avatar du dashboard et
  de la timeline (jusque-là figé sur les initiales / « M ») affiche
  désormais la photo du compte (`auth.avatar`, data-URL base64) avec
  repli automatique sur les initiales — `Avatar` enrichi du paramètre
  `image` et `decodeAvatarImage()` partagé (le profil réutilise cette
  fonction ; double décodage supprimé).

Vérifications : `flutter analyze` **0 problème**, `flutter test`
**24 tests OK + 2 skip (live)** ; captures one-off des 8 écrans
(splash blanc + nouveau logo, titres cursive, dialogue) analysées puis
supprimées avec leur test.

---

## 🎨 Itération 7 — erreur de saisie, champs, polices, avatar

Demandes regroupées (12 nov.) :

- **Erreur « Vérifiez les informations saisies, puis réessayez. »** :
  message **générique** émis uniquement par `ApiException._genericMessage`
  (réponse 400/422 dont aucun code n'est reconnu). Toute la surface
  atteignable a été éprouvée (JWT malformé, uuid/dates invalides,
  colonnes NOT NULL, `auth.uid()`, `maxLength` absent, `reminder` jamais
  envoyé…) : le **seul 400 déclenchable depuis l'app est un `title` de
  plus de 200 caractères** — `planning_task.title` est `varchar(200)` →
  SQLSTATE `22001` → `case default` du `switch` → message générique.
  Corrigé : `22001` mappe désormais « Saisie trop longue : réduisez la
  taille de vos informations, puis réessayez. », et le champ titre impose
  `maxLength: 200` avec `MaxLengthEnforcement.enforced` (le défaut varie
  par plateforme : Android/Windows l'applique, le web tronque après
  composition — d'où l'import `package:flutter/services.dart`).
- **Champs de saisie** : gouttière ramenée à **24** (suppression du
  `Center` + `ConstrainedBox(maxWidth: 420)` — la demande de réduction
  avait été mal formulée) et **hauteur réduite** : conteneur `FlowField`
  `vertical: 6 → 4`, `contentPadding` `vertical: 4 → 2`.
- **Dancing Script cantonné** : uniquement la marque « Flowday »
  (en-tête d'auth 27 px, splash 38 px) et la salutation du dashboard
  (« Hey … ! », 21 px, `white70`). Les 5 titres passés en cursive à
  l'itération 6 reviennent en Poppins **bold** : titre d'auth (25),
  héros du dashboard (25), « Today » (39), « Profil » (32),
  « Paramètres » (32).
- **Avatar du profil** : contrôle à blanc par rendu pixel (test one-off,
  supprimé après exécution) — `CircleAvatar` peint bien un **cercle
  centré** (décor `BoxShape.circle`, photo en `BoxFit.cover`, initiale
  centrée par `Center`), et c'est identique au `git show HEAD:` : la
  photo du compte (JPEG 512 × 512) remplit tout le disque. Aucun défaut
  de rendu reproductible — si l'aspect « carré » persiste après
  reconstruction, c'est la composition de la photo (visage décentré à
  gauche) ou un binaire ancien ; une capture d'écran reste demandée.

Vérifications : `flutter analyze` **0 problème**, `flutter test`
**24 tests OK + 2 skip (live)**.

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
- Police **Poppins** embarquée dans `fonts/` et déclarée dans `pubspec.yaml`
  (README §6 : « Inter ou Poppins »). Poppins a été choisie pour son côté
  arrondi qui colle au design ; Inter reste un simple remplacement possible.
- La maquette montre une catégorie **Education** en plus des 3 du MVP
  (Work, Health, Personal) : elle est intégrée au design, à confirmer pour le MVP.
- Les cartes de catégories de l'accueil affichent les **vraies catégories de
  l'API** (F7) ; les descriptions et icônes sont mappées par id
  (`personal`, `work`, `health`, `education`).
- L'écran formulaire porte le titre « New task » (« Edit task » en
  modification) ; « See all » ouvre la timeline, dont la 1re tâche est mise
  en avant (carte sombre).
- Les données affichées viennent de l'API (`../flowday_api`) via
  `TaskRepository` + `TasksProvider` ; `mock_data.dart` ne sert plus qu'aux
  tests (déplacé dans `test/fixtures/`).
- Hors ligne (F8) : pas encore de cache local — si le serveur est
  indisponible, les écrans affichent un état d'erreur avec « Réessayer ».
  Un cache (Hive/SharedPreferences) reste prévu en post-MVP.
