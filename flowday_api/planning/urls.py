"""Routes de l'API Flowday : /api/...

- /api/…            : endpoints métier (router DRF)
- /api/schema/      : schéma OpenAPI (YAML/JSON)
- /api/docs/        : Swagger UI (interface interactive)
- /api/redoc/       : Redoc (documentation classique)
"""
from django.urls import include, path
from drf_spectacular.views import (
    SpectacularRedocView,
    SpectacularSwaggerView,
    SpectacularAPIView,
)
from rest_framework.routers import DefaultRouter

from . import views

router = DefaultRouter()
router.register("tasks", views.TaskViewSet, basename="task")
router.register("categories", views.CategoryViewSet, basename="category")

urlpatterns = [
    path("", include(router.urls)),
    path("stats/", views.stats, name="stats"),
    # Documentation OpenAPI / Swagger.
    path("schema/", SpectacularAPIView.as_view(), name="schema"),
    path(
        "docs/",
        SpectacularSwaggerView.as_view(url_name="schema"),
        name="swagger-ui",
    ),
    path(
        "redoc/",
        SpectacularRedocView.as_view(url_name="schema"),
        name="redoc",
    ),
]
