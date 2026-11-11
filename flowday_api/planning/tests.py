"""Tests de l'API Flowday (critères d'acceptation du README §10)."""
from datetime import date, time

from django.urls import reverse
from rest_framework import status
from rest_framework.test import APITestCase

from .models import Category, Task


class CategoryTests(APITestCase):
    def test_categories_seedees(self):
        """F7 : les catégories par défaut existent avec leur couleur."""
        response = self.client.get("/api/categories/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        names = {c["name"] for c in response.data}
        self.assertTrue({"Work", "Health", "Personal"}.issubset(names))

    def test_couleur_work_est_orange(self):
        work = Category.objects.get(id="work")
        self.assertEqual(work.color, "#F4761F")


class TaskCrudTests(APITestCase):
    def setUp(self):
        self.work = Category.objects.get(id="work")

    def _payload(self, **overrides):
        payload = {
            "title": "Meeting with Shakib",
            "description": "At Google meet",
            "date": "2026-06-28",
            "time": "14:00",
            "category": "work",
        }
        payload.update(overrides)
        return payload

    def test_creation_tache_valide(self):
        """F3 : création d'une tâche valide sans erreur."""
        response = self.client.post(
            "/api/tasks/", self._payload(), format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data["title"], "Meeting with Shakib")
        self.assertEqual(response.data["category_name"], "Work")
        self.assertFalse(response.data["completed"])  # état « à faire »

    def test_titre_obligatoire(self):
        """Le titre vide est refusé (README §3.2)."""
        response = self.client.post(
            "/api/tasks/", self._payload(title="   "), format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("title", response.data)

    def test_heure_invalide_refusee(self):
        response = self.client.post(
            "/api/tasks/", self._payload(time="25:99"), format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn("time", response.data)

    def test_tri_par_heure(self):
        """F1 : les tâches du jour sont triées par heure croissante."""
        for title, t in [("Z", "17:00"), ("A", "09:00"), ("M", "12:30")]:
            Task.objects.create(
                title=title,
                date=date(2026, 6, 28),
                time=time.fromisoformat(t),
                category=self.work,
            )
        response = self.client.get("/api/tasks/?date=2026-06-28")
        times = [task["time"] for task in response.data]
        self.assertEqual(times, sorted(times))

    def test_filtre_par_date(self):
        """Le changement de jour actualise la liste affichée."""
        Task.objects.create(
            title="Jour A",
            date=date(2026, 6, 28),
            time=time(9, 0),
            category=self.work,
        )
        Task.objects.create(
            title="Jour B",
            date=date(2026, 6, 29),
            time=time(9, 0),
            category=self.work,
        )
        response = self.client.get("/api/tasks/?date=2026-06-28")
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["title"], "Jour A")

    def test_filtre_par_semaine(self):
        """F2 : plage start/end du sélecteur de semaine."""
        for day in (26, 27, 28, 30):
            Task.objects.create(
                title=f"T{day}",
                date=date(2026, 6, day),
                time=time(9, 0),
                category=self.work,
            )
        response = self.client.get(
            "/api/tasks/?start=2026-06-24&end=2026-06-28"
        )
        self.assertEqual(len(response.data), 3)

    def test_filtre_par_categorie(self):
        """F7 : ?category= ne retourne que la catégorie demandée."""
        Task.objects.create(
            title="Work task",
            date=date(2026, 6, 28),
            time=time(9, 0),
            category=self.work,
        )
        health = Category.objects.get(id="health")
        Task.objects.create(
            title="Health task",
            date=date(2026, 6, 28),
            time=time(10, 0),
            category=health,
        )
        response = self.client.get("/api/tasks/?category=work")
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]["title"], "Work task")

    def test_filtre_date_et_categorie(self):
        """Le filtre catégorie se combine avec le filtre de date."""
        health = Category.objects.get(id="health")
        Task.objects.create(
            title="Work A",
            date=date(2026, 6, 28),
            time=time(9, 0),
            category=self.work,
        )
        Task.objects.create(
            title="Work B",
            date=date(2026, 6, 29),
            time=time(9, 0),
            category=self.work,
        )
        Task.objects.create(
            title="Health A",
            date=date(2026, 6, 28),
            time=time(10, 0),
            category=health,
        )
        response = self.client.get(
            "/api/tasks/?date=2026-06-28&category=work"
        )
        self.assertEqual([t["title"] for t in response.data], ["Work A"])

    def test_modification_tache(self):
        """F4 : modifier tous les champs d'une tâche existante."""
        task = Task.objects.create(
            title="Avant",
            date=date(2026, 6, 28),
            time=time(9, 0),
            category=self.work,
        )
        url = reverse("task-detail", args=[task.id])
        response = self.client.patch(
            url, {"title": "Après", "time": "15:30"}, format="json"
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        task.refresh_from_db()
        self.assertEqual(task.title, "Après")
        self.assertEqual(task.time, time(15, 30))

    def test_suppression_tache(self):
        """F5 : suppression d'une tâche."""
        task = Task.objects.create(
            title="À supprimer",
            date=date(2026, 6, 28),
            time=time(9, 0),
            category=self.work,
        )
        url = reverse("task-detail", args=[task.id])
        response = self.client.delete(url)
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Task.objects.filter(id=task.id).exists())

    def test_toggle_terminer(self):
        """F6 : appuyer sur le point inverse l'état terminé / à faire."""
        task = Task.objects.create(
            title="Toggle",
            date=date(2026, 6, 28),
            time=time(9, 0),
            category=self.work,
        )
        url = reverse("task-toggle", args=[task.id])

        response = self.client.post(url)
        self.assertTrue(response.data["completed"])

        response = self.client.post(url)
        self.assertFalse(response.data["completed"])


class StatsTests(APITestCase):
    def test_stats_profil(self):
        work = Category.objects.get(id="work")
        Task.objects.create(
            title="Terminée",
            date=date(2026, 6, 28),
            time=time(9, 0),
            category=work,
            completed=True,
        )
        Task.objects.create(
            title="À faire",
            date=date(2026, 6, 28),
            time=time(10, 0),
            category=work,
        )
        response = self.client.get("/api/stats/")
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data["total_tasks"], 2)
        self.assertEqual(response.data["completed_tasks"], 1)
        self.assertEqual(response.data["success_rate"], 50.0)
