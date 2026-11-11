# Flowday API — Backend Django (DRF)

Backend REST de l'application mobile **Flowday**, écrit avec **Django +
Django REST Framework**. Il se trouve **à côté** du projet Flutter
(`../flowday`).

> **Depuis la phase 4, l'app Flutter utilise l'accès direct Supabase
> (PostgREST) et n'a plus besoin de ce serveur** (voir §4). Ce backend reste
> utile pour l'**admin**, la documentation **Swagger** et ses **tests**.

- Cahier des charges : `../flowday/README.md`
- Framework : Django 6.1 + DRF 3.18
- Base de données : **Supabase** (Postgres managé en ligne — URL lue dans le
  fichier local `.env` via `DATABASE_URL`, voir §1 ; l'ancien `db.sqlite3`
  local n'est plus utilisé)
- Authentification : aucune pour le MVP (API publique), prévue en phase
  « synchronisation cloud » du README §7

## 1. Démarrage

```bash
cd flowday_api

# Créer et activer l'environnement virtuel (première fois)
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt

# Secrets (première fois) : copier le modèle puis renseigner DATABASE_URL
cp .env.example .env
#   → URL de connexion Supabase (Dashboard → Settings → Database → URI,
#     mot de passe URL-encodé). Le .env est ignoré par git ; sans lui,
#     Django refuse de démarrer (« DATABASE_URL manquant »).

# Migrations + catégories par défaut (Work, Health, Personal, Education)
.venv/bin/python manage.py migrate

# Lancer le serveur
.venv/bin/python manage.py runserver
# → API disponible sur http://127.0.0.1:8000/api/
```

Console d'administration (optionnelle) :

```bash
.venv/bin/python manage.py createsuperuser
# → http://127.0.0.1:8000/admin/
```

## 2. Endpoints

| Méthode | URL | Rôle (README) |
|---|---|---|
| GET | `/api/categories/` | F7 — catégories + couleur |
| GET | `/api/tasks/?date=AAAA-MM-JJ` | F1 — tâches d'un jour, triées par heure |
| GET | `/api/tasks/?start=AAAA-MM-JJ&end=AAAA-MM-JJ` | F2 — tâches d'une semaine |
| GET | `/api/tasks/?category=<id>` | F7 — tâches d'une catégorie (combinable avec `?date=`) |
| GET | `/api/tasks/` | toutes les tâches |
| POST | `/api/tasks/` | F3 — création |
| GET | `/api/tasks/<uuid>/` | détail |
| PUT / PATCH | `/api/tasks/<uuid>/` | F4 — modification |
| DELETE | `/api/tasks/<uuid>/` | F5 — suppression |
| POST | `/api/tasks/<uuid>/toggle/` | F6 — terminer / déterminer |
| GET | `/api/stats/` | §3.5 — statistiques du profil |
| GET | `/api/schema/` | schéma OpenAPI 3 (JSON / YAML) |
| GET | `/api/docs/` | **Swagger UI** (interface interactive) |
| GET | `/api/redoc/` | Redoc (documentation classique) |

## 2.1 Documentation Swagger

Une fois le serveur lancé, ouvre **http://127.0.0.1:8000/api/docs/** dans
le navigateur : tu obtiens l'interface **Swagger UI** avec toutes les
endpoints (filtres, payloads, boutons « Try it out » pour appeler l'API
directement depuis le navigateur).

- `GET /api/schema/` : le schéma OpenAPI 3 brut (JSON par défaut, YAML si
  `Accept: application/yaml`) — utile pour générer un client Flutter.
- `GET /api/redoc/` : la même documentation au style Redoc.
- La doc est générée automatiquement par `drf-spectacular` à partir des
  serializers et des annotations `@extend_schema` (paramètres `date`,
  `start`, `end`, `category`, réponses de `toggle` et `stats`…).

Générer le schéma en fichier (ex. pour un outil de codegen) :

```bash
.venv/bin/python manage.py spectacular --file schema.yaml
```

### Format d'une tâche

```json
{
  "id": "3f1c…-uuid",
  "title": "Meeting with Shakib",
  "description": "At Google meet",
  "date": "2026-06-28",
  "time": "14:00",
  "category": "work",
  "category_name": "Work",
  "category_color": "#F4761F",
  "completed": false,
  "reminder": null,
  "created_at": "2026-06-28T09:00:00Z"
}
```

### Règles validées (README §3.2 / §4)

- `title` obligatoire, non vide (400 sinon) ;
- `time` au format `HH:MM` (24 h), invalide → 400 ;
- `date` obligatoire au format `AAAA-MM-JJ` ;
- `category` = identifiant d'une catégorie existante (`work`, `health`,
  `personal`, `education`) ;
- nouvelle tâche → `completed: false` (« à faire ») ;
- toujours triées par heure croissante.

## 3. Exemples curl

```bash
# Catégories
curl http://127.0.0.1:8000/api/categories/

# Tâches du 28 juin 2026
curl "http://127.0.0.1:8000/api/tasks/?date=2026-06-28"

# Créer une tâche
curl -X POST http://127.0.0.1:8000/api/tasks/ \
  -H "Content-Type: application/json" \
  -d '{"title":"Yoga","description":"at the village","date":"2026-06-28","time":"16:00","category":"health"}'

# Modifier
curl -X PATCH http://127.0.0.1:8000/api/tasks/<uuid>/ \
  -H "Content-Type: application/json" -d '{"completed":true}'

# Terminer / déterminer (F6)
curl -X POST http://127.0.0.1:8000/api/tasks/<uuid>/toggle/

# Supprimer (F5)
curl -X DELETE http://127.0.0.1:8000/api/tasks/<uuid>/

# Statistiques
curl http://127.0.0.1:8000/api/stats/
```

## 4. Consommation depuis Flutter

### Depuis la phase 4 : accès direct Supabase (sans ce serveur)

L'app Flutter (`../flowday`) interroge directement l'API REST **Supabase**
(PostgREST) : `https://<projet>.supabase.co/rest/v1/…` avec la clé publique
du projet — configurée dans
`flowday/lib/core/network/supabase_config.dart` (surcharge possible :
`--dart-define=FLOWDAY_SUPABASE_URL` / `FLOWDAY_SUPABASE_ANON_KEY`).

| Table | Usage dans l'app |
|---|---|
| `planning_category` | F7 — `GET …/planning_category?select=id,name,color` |
| `planning_task` | F1–F6 + stats — filtres `date=eq.…`, plage `date=gte.…&date=lte.…`, `category_id=eq.…`, catégorie embarquée `select=…,planning_category(id,name,color)` |

Politiques RLS nécessaires (déjà en place sur le projet) :

```sql
CREATE POLICY planning_task_anon ON planning_task FOR ALL TO anon
  USING (true) WITH CHECK (true);
CREATE POLICY planning_category_anon ON planning_category FOR ALL TO anon
  USING (true) WITH CHECK (true);
```

> Le RLS est activé sur les tables : **sans politique, le rôle `anon` ne
> voit aucune ligne** (réponses `[]` ou `42501`).

### API Django optionnelle (admin / Swagger / tests)

Consommer directement cette API reste possible ; il faut alors démarrer le
serveur :

```bash
# Défaut (localhost) — suffit pour web/émulateur/simulateur/USB avec adb reverse
.venv/bin/python manage.py runserver

# Accessible depuis le Wi-Fi (autres appareils)
.venv/bin/python manage.py runserver 0.0.0.0:8000
```

| Cible | URL utilisée | Condition |
|---|---|---|
| **Téléphone physique (USB)** | `http://127.0.0.1:8000/api/` | tunnel USB : `adb reverse tcp:8000 tcp:8000` (une fois par connexion) |
| Émulateur Android | `http://10.0.2.2:8000/api/` (repli après `127.0.0.1`) | aucun réglage |
| Émulateur / simulateur iOS | `http://127.0.0.1:8000/api/` | aucun réglage |
| Appareil sur le même Wi-Fi | `http://<IP-PC>:8000/api/` | serveur en `runserver 0.0.0.0:8000` + `--dart-define=FLOWDAY_API_URL=http://<IP-PC>:8000` |
| Flutter Web (même machine) | `http://127.0.0.1:8000/api/` | CORS déjà activé |

Android 8+ exige le trafic HTTP en clair en dev : c'est déjà fait dans ce
projet (`android:usesCleartextTraffic="true"` dans le manifeste, et
`NSAllowsArbitraryLoads` côté iOS).

### Exemple avec `package:http`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class FlowdayApi {
  static const baseUrl = 'http://10.0.2.2:8000/api'; // émulateur Android

  Future<List<dynamic>> tasksOf(String date) async {
    final res = await http.get(Uri.parse('$baseUrl/tasks/?date=$date'));
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<void> toggle(String id) async {
    await http.post(Uri.parse('$baseUrl/tasks/$id/toggle/'));
  }

  Future<void> createTask(Map<String, dynamic> body) async {
    await http.post(
      Uri.parse('$baseUrl/tasks/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
  }
}
```

## 5. Tests

```bash
.venv/bin/python manage.py test
```

Couvre : seed des catégories (F7), création / titre obligatoire / heure
valide (F3), tri par heure et filtres jour + semaine (F1, F2), modification
(F4), suppression (F5), toggle (F6), statistiques (§3.5).

## 6. Structure

```
flowday_api/
├── manage.py
├── requirements.txt
├── README.md                # ce fichier
├── config/                  # projet Django (settings, urls)
│   ├── settings.py          # DRF + CORS + Swagger (drf-spectacular)
│   └── urls.py              # /api/ → planning.urls
└── planning/                # app métier
    ├── models.py            # Category, Task (README §5)
    ├── serializers.py       # validation des règles métier
    ├── views.py             # TaskViewSet, CategoryViewSet, stats
    ├── urls.py              # routes /api/…
    ├── admin.py
    ├── tests.py
    └── migrations/
        ├── 0001_initial.py
        └── 0002_seed_categories.py   # Work / Health / Personal / Education
```
