# Flowday API — Backend Django (DRF)

Backend REST de l'application mobile **Flowday**, écrit avec **Django +
Django REST Framework**. Il se trouve **à côté** du projet Flutter
(`../flowday`) et expose les endpoints que l'app Flutter consommera.

- Cahier des charges : `../flowday/README.md`
- Framework : Django 6.1 + DRF 3.18
- Base de données : SQLite (locale, `db.sqlite3`)
- Authentification : aucune pour le MVP (API publique), prévue en phase
  « synchronisation cloud » du README §7

## 1. Démarrage

```bash
cd flowday_api

# Créer et activer l'environnement virtuel (première fois)
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt

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
| GET | `/api/tasks/` | toutes les tâches |
| POST | `/api/tasks/` | F3 — création |
| GET | `/api/tasks/<uuid>/` | détail |
| PUT / PATCH | `/api/tasks/<uuid>/` | F4 — modification |
| DELETE | `/api/tasks/<uuid>/` | F5 — suppression |
| POST | `/api/tasks/<uuid>/toggle/` | F6 — terminer / déterminer |
| GET | `/api/stats/` | §3.5 — statistiques du profil |

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

### URL de base selon la plateforme

| Cible | URL |
|---|---|
| Émulateur Android | `http://10.0.2.2:8000/api/` |
| Émulateur iOS / simulateur | `http://127.0.0.1:8000/api/` |
| Appareil physique | `http://<IP-PC>:8000/api/` (même Wi-Fi) |
| Flutter Web | `http://127.0.0.1:8000/api/` |

Android 8+ exige le trafic HTTP en clair en dev : ajouter dans
`android/app/src/main/AndroidManifest.xml` (dans `<application>`):

```xml
android:usesCleartextTraffic="true"
```

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
│   ├── settings.py          # DRF + CORS activés
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
