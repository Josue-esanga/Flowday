"""Seed des catégories par défaut (README §5).

Work : orange, Health : jaune, Personal : rouge (+ Education de la maquette).
"""
from django.db import migrations

CATEGORIES = [
    {"id": "work", "name": "Work", "color": "#F4761F"},
    {"id": "health", "name": "Health", "color": "#F5C542"},
    {"id": "personal", "name": "Personal", "color": "#F05B52"},
    {"id": "education", "name": "Education", "color": "#4E8CFF"},
]


def seed_categories(apps, schema_editor):
    Category = apps.get_model("planning", "Category")
    for category in CATEGORIES:
        Category.objects.update_or_create(
            id=category["id"],
            defaults={"name": category["name"], "color": category["color"]},
        )


class Migration(migrations.Migration):
    dependencies = [
        ("planning", "0001_initial"),
    ]

    operations = [
        # Pas de reverse : on ne supprime pas les catégories référencées
        # par des tâches (PROTECT).
        migrations.RunPython(seed_categories, migrations.RunPython.noop),
    ]
