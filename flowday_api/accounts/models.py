"""Modèles de la couche comptes.

L'utilisateur lui-même est le modèle ``auth.User`` de Django
(l'e-mail est l'identifiant de connexion). Ce module ajoute le
complément de profil : la **photo de profil**.
"""
from django.conf import settings
from django.db import models


class Profile(models.Model):
    """Informations complémentaires du compte (photo de profil)."""

    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='profile',
    )
    photo = models.ImageField(
        upload_to='profile_photos/%Y/%m/',
        blank=True,
        null=True,
        verbose_name='photo de profil',
    )
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self) -> str:
        return f'Profil de {self.user.username}'
