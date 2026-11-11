"""Vues API Flowday.

Fonctionnalités MVP couvertes (README §2) :
- F1  GET  /api/tasks/?date=AAAA-MM-JJ   tâches du jour, triées par heure
- F2  GET  /api/tasks/?start=&end=       tâches d'une semaine
- F3  POST /api/tasks/                   création
- F4  PUT/PATCH /api/tasks/<id>/         modification
- F5  DELETE /api/tasks/<id>/            suppression
- F6  POST /api/tasks/<id>/toggle/       terminer / déterminer
- F7  GET  /api/categories/              catégories + couleurs
- F8  (persistance côté serveur SQLite)
"""
from datetime import timedelta

from django.utils import timezone
from drf_spectacular.utils import (
    OpenApiParameter,
    OpenApiTypes,
    extend_schema,
    inline_serializer,
)
from rest_framework import serializers, status, viewsets
from rest_framework.decorators import action, api_view
from rest_framework.response import Response

from .models import Category, Task
from .serializers import CategorySerializer, TaskSerializer


class TaskViewSet(viewsets.ModelViewSet):
    """CRUD complet des tâches + action « toggle » (F1 → F6)."""

    serializer_class = TaskSerializer

    @extend_schema(
        summary="Lister les tâches (toujours triées par heure)",
        description=(
            "F1 : `?date=AAAA-MM-JJ` retourne les tâches d'un jour.\n\n"
            "F2 : `?start=AAAA-MM-JJ&end=AAAA-MM-JJ` retourne les tâches "
            "d'une plage (semaine du sélecteur).\n\n"
            "F7 : `?category=<id>` retourne les tâches d'une catégorie "
            "(ex. `work`), combinable avec `date`.\n\n"
            "Sans paramètre : toutes les tâches."
        ),
        parameters=[
            OpenApiParameter(
                name="date",
                type=OpenApiTypes.DATE,
                description="Jour planifié, ex. 2026-06-28 (F1).",
            ),
            OpenApiParameter(
                name="start",
                type=OpenApiTypes.DATE,
                description="Début de la plage, ex. 2026-06-24 (F2).",
            ),
            OpenApiParameter(
                name="end",
                type=OpenApiTypes.DATE,
                description="Fin de la plage, ex. 2026-06-30 (F2).",
            ),
            OpenApiParameter(
                name="category",
                type=OpenApiTypes.STR,
                description="Id de catégorie, ex. `work` (F7).",
            ),
        ],
        responses=TaskSerializer(many=True),
    )
    def list(self, request, *args, **kwargs):
        return super().list(request, *args, **kwargs)

    @extend_schema(
        summary="Créer une tâche (F3)",
        description=(
            "Titre obligatoire (non vide) et heure au format `HH:MM` "
            "(24 h) — sinon 400. Nouvelle tâche → `completed: false`."
        ),
        responses={201: TaskSerializer},
    )
    def create(self, request, *args, **kwargs):
        return super().create(request, *args, **kwargs)

    def get_queryset(self):
        queryset = Task.objects.select_related("category").all()
        params = self.request.query_params

        date = params.get("date")
        start = params.get("start")
        end = params.get("end")
        category = params.get("category")

        if date:
            # F1 : tâches d'un jour précis.
            queryset = queryset.filter(date=date)
        elif start and end:
            # F2 : tâches d'une plage (semaine du sélecteur).
            queryset = queryset.filter(date__gte=start, date__lte=end)

        if category:
            # F7 : tâches d'une catégorie (page « tâches de la catégorie »),
            # combinable avec un filtre de date.
            queryset = queryset.filter(category_id=category)

        # Toujours triées par heure croissante (README §4).
        return queryset.order_by("time", "created_at")

    def perform_create(self, serializer):
        # Une tâche nouvellement créée est à l'état « à faire » (README §4),
        # sauf si le client fournit explicitement completed=true.
        serializer.save()

    @extend_schema(
        summary="Terminer / déterminer une tâche (F6)",
        description="Inverse l'état `completed` et renvoie la tâche mise à jour.",
        responses={200: TaskSerializer},
    )
    @action(detail=True, methods=["post"])
    def toggle(self, request, pk=None):
        """F6 : inverse l'état terminé / à faire."""
        task = self.get_object()
        task.completed = not task.completed
        task.save(update_fields=["completed"])
        return Response(TaskSerializer(task).data)


class CategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """F7 : catégories (Work, Health, Personal, Education) + couleurs."""

    queryset = Category.objects.all()
    serializer_class = CategorySerializer


@extend_schema(
    summary="Statistiques du profil (§3.5)",
    description=(
        "Nombre total de tâches, nombre de tâches terminées, taux de "
        "réussite (%) et tâches prévues cette semaine."
    ),
    responses={
        200: inline_serializer(
            name="Stats",
            fields={
                "total_tasks": serializers.IntegerField(),
                "completed_tasks": serializers.IntegerField(),
                "success_rate": serializers.FloatField(),
                "tasks_this_week": serializers.IntegerField(),
            },
        )
    },
)
@api_view(["GET"])
def stats(request):
    """Statistiques du profil (README §3.5)."""
    total = Task.objects.count()
    completed = Task.objects.filter(completed=True).count()

    today = timezone.localdate()
    week_start = today - timedelta(days=today.weekday())
    this_week = Task.objects.filter(
        date__gte=week_start, date__lte=today
    ).count()

    success_rate = round(completed * 100 / total, 1) if total else 0.0

    return Response(
        {
            "total_tasks": total,
            "completed_tasks": completed,
            "success_rate": success_rate,
            "tasks_this_week": this_week,
        }
    )
