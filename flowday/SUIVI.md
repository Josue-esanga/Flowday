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
│   ├── app.dart                   # FlowdayApp : thème + provider + injection repository
│   ├── home_shell.dart            # coque : barre de nav + onglets + bascule timeline
│   └── theme/app_theme.dart       # AppColors (charte) + AppTheme.light()
├── core/                          # briques transverses
│   ├── constants/
│   ├── errors/api_exception.dart  # erreurs REST (PostgREST + DRF : message/champs)
│   ├── network/supabase_config.dart  # URL du projet + clé anon (dart-define)
│   ├── network/supabase_rest_client.dart  # client PostgREST (timeout, JSON, erreurs)
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
│   ├── auth/                      # (à venir : connexion, inscription)
│   │   ├── data/  domain/  presentation/
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
  `--dart-define=FLOWDAY_SUPABASE_URL` / `_ANON_KEY`) et `SupabaseRestClient`
  (PostgREST, timeout 10 s, erreurs → `ApiException`).
- `core/providers` : `TasksProvider` (ChangeNotifier) — état partagé entre
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

- La clé anon est **publique** (embarquée dans l'application) : avec les
  politiques actuelles (`USING (true)`), **qui possède la clé peut tout
  lire / écrire / supprimer** sur les deux tables. Acceptable pour une démo
  MVP ; en production : Supabase Auth + politiques par utilisateur
  (`auth.uid()`).
- Le mot de passe de la base reste dans `flowday_api/.env` (local, hors
  git) ; s'il a été partagé, le faire tourner dans le dashboard Supabase
  puis mettre `.env` à jour.

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
