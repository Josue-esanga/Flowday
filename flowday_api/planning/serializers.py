"""Serializers DRF : validation des règles métier du README §3.2 / §4."""
from rest_framework import serializers

from .models import Category, Task


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ["id", "name", "color"]


class TaskSerializer(serializers.ModelSerializer):
    # Infos de catégorie dénormalisées pour le client Flutter.
    category_name = serializers.CharField(source="category.name", read_only=True)
    category_color = serializers.CharField(source="category.color", read_only=True)

    class Meta:
        model = Task
        fields = [
            "id",
            "title",
            "description",
            "date",
            "time",
            "category",
            "category_name",
            "category_color",
            "completed",
            "reminder",
            "created_at",
        ]
        read_only_fields = ["created_at"]

    def validate_title(self, value: str) -> str:
        """Le titre est obligatoire et ne peut pas être vide (README §3.2)."""
        value = value.strip()
        if not value:
            raise serializers.ValidationError("Le titre est obligatoire.")
        return value
