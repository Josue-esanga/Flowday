"""Modèles de données de Flowday (README §5).

Deux entités :
- Category : Work, Health, Personal (…), avec couleur hexadécimale.
- Task      : id UUID, titre obligatoire, description, date, heure,
              catégorie, état terminé, rappel optionnel, date de création.
"""
import uuid

from django.db import models


class Category(models.Model):
    """Catégorie d'une tâche (README §5)."""

    id = models.SlugField(max_length=50, primary_key=True)
    name = models.CharField(max_length=50, unique=True)
    color = models.CharField(
        max_length=7,
        help_text="Couleur hexadécimale, ex. #F4761F",
    )

    class Meta:
        verbose_name_plural = "categories"
        ordering = ["name"]

    def __str__(self) -> str:
        return self.name


class Task(models.Model):
    """Tâche planifiée à une date et une heure précises (README §5)."""

    id = models.UUIDField(
        primary_key=True,
        default=uuid.uuid4,
        editable=False,
    )
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    date = models.DateField(help_text="Jour planifié (AAAA-MM-JJ).")
    time = models.TimeField(help_text="Heure prévue (HH:MM, 24 h).")
    category = models.ForeignKey(
        Category,
        on_delete=models.PROTECT,
        related_name="tasks",
    )
    completed = models.BooleanField(default=False)
    reminder = models.DurationField(
        null=True,
        blank=True,
        help_text="Rappel optionnel (évolutions : notifications).",
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        # Les tâches d'un même jour sont toujours triées par heure
        # croissante (README §4).
        ordering = ["time"]
        indexes = [
            models.Index(fields=["date"], name="planning_task_date_idx"),
        ]

    def __str__(self) -> str:
        return f"{self.title} ({self.date} {self.time})"
