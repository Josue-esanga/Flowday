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
from rest_framework import status, viewsets
from rest_framework.decorators import action, api_view
from rest_framework.response import Response

from .models import Category, Task
from .serializers import CategorySerializer, TaskSerializer


class TaskViewSet(viewsets.ModelViewSet):
    """CRUD complet des tâches + action « toggle » (F1 → F6)."""

    serializer_class = TaskSerializer

    def get_queryset(self):
        queryset = Task.objects.select_related("category").all()
        params = self.request.query_params

        date = params.get("date")
        start = params.get("start")
        end = params.get("end")

        if date:
            # F1 : tâches d'un jour précis.
            queryset = queryset.filter(date=date)
        elif start and end:
            # F2 : tâches d'une plage (semaine du sélecteur).
            queryset = queryset.filter(date__gte=start, date__lte=end)

        # Toujours triées par heure croissante (README §4).
        return queryset.order_by("time", "created_at")

    def perform_create(self, serializer):
        # Une tâche nouvellement créée est à l'état « à faire » (README §4),
        # sauf si le client fournit explicitement completed=true.
        serializer.save()

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
