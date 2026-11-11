from django.contrib import admin

from .models import Category, Task


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ("id", "name", "color")
    search_fields = ("name",)


@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ("title", "date", "time", "category", "completed", "created_at")
    list_filter = ("completed", "category", "date")
    search_fields = ("title", "description")
    date_hierarchy = "date"
