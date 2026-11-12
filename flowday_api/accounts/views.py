"""Vues API comptes : inscription, connexion, profil et photo.

- POST /api/auth/register/         inscription (e-mail + mot de passe)
- POST /api/auth/login/            connexion → jeton d'accès
- POST /api/auth/logout/           révocation du jeton
- GET  /api/auth/me/               informations de l'utilisateur
- PATCH /api/auth/me/              modification (nom, e-mail, mot de passe)
- POST /api/auth/me/photo/         envoi de la photo de profil
- DELETE /api/auth/me/photo/       suppression de la photo
"""
from django.contrib.auth import get_user_model
from drf_spectacular.utils import extend_schema, inline_serializer
from rest_framework import serializers, status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from .models import Profile
from .serializers import (
    LoginSerializer,
    PhotoSerializer,
    RegisterSerializer,
    UpdateUserSerializer,
    UserSerializer,
)

User = get_user_model()

# Réponse commune connexion / inscription : jeton + profil.
_auth_response = inline_serializer(
    name='AuthResponse',
    fields={
        'token': serializers.CharField(),
        'user': UserSerializer(),
    },
)


@extend_schema(
    summary="Inscription (e-mail + mot de passe)",
    description=(
        "Crée le compte (identifiant = e-mail, 8 caractères minimum) et "
        "retourne le jeton d'accès ainsi que le profil."
    ),
    request=RegisterSerializer,
    responses={201: _auth_response},
)
@api_view(['POST'])
def register(request):
    """Inscription : crée l'utilisateur + profil puis renvoie le jeton."""
    serializer = RegisterSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    user = serializer.save()
    token, _ = Token.objects.get_or_create(user=user)
    return Response(
        {
            'token': token.key,
            'user': UserSerializer(
                user, context={'request': request}
            ).data,
        },
        status=status.HTTP_201_CREATED,
    )


@extend_schema(
    summary="Connexion (e-mail + mot de passe)",
    description=(
        "Authentifie l'utilisateur et renvoie un jeton d'accès "
        "(`Token`) à joindre en `Authorization: Token <jeton>`."
    ),
    request=LoginSerializer,
    responses={200: _auth_response},
)
@api_view(['POST'])
def login(request):
    """Connexion : vérifie les identifiants puis délivre un jeton."""
    serializer = LoginSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    user = serializer.validated_data['user']
    token, _ = Token.objects.get_or_create(user=user)
    return Response(
        {
            'token': token.key,
            'user': UserSerializer(
                user, context={'request': request}
            ).data,
        }
    )


@extend_schema(
    summary="Déconnexion (révoque le jeton)",
    description="Supprime le jeton de l'utilisateur courant.",
    responses={204: None},
)
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout(request):
    """Déconnexion : invalide le jeton côté serveur."""
    Token.objects.filter(user=request.user).delete()
    return Response(status=status.HTTP_204_NO_CONTENT)


@extend_schema(
    summary="Profil courant",
    description=(
        "`GET` : informations de l'utilisateur connecté.\n\n"
        "`PATCH` : modification du nom, de l'e-mail et/ou du mot de passe "
        "(changement de mot de passe : champs `current_password` + "
        "`new_password`)."
    ),
    request=UpdateUserSerializer,
    responses=UserSerializer,
)
@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def me(request):
    """Profil courant : lecture ou modification des informations."""
    if request.method == 'GET':
        return Response(
            UserSerializer(
                request.user, context={'request': request}
            ).data
        )
    serializer = UpdateUserSerializer(
        request.user, data=request.data, partial=True
    )
    serializer.is_valid(raise_exception=True)
    user = serializer.save()
    return Response(
        UserSerializer(user, context={'request': request}).data
    )


@extend_schema(
    summary="Photo de profil",
    description=(
        "`POST` (multipart `photo`) : envoie la photo (JPEG/PNG, "
        "2 Mo max.) — l'ancienne est remplacée.\n\n"
        "`DELETE` : supprime la photo."
    ),
    request={'multipart/form-data': PhotoSerializer},
    responses={
        200: inline_serializer(
            name='PhotoResponse',
            fields={
                'photo_url': serializers.CharField(
                    allow_null=True, allow_blank=True
                )
            },
        )
    },
)
@api_view(['POST', 'DELETE'])
@permission_classes([IsAuthenticated])
def me_photo(request):
    """Photo de profil : envoi, remplacement ou suppression."""
    profile, _ = Profile.objects.get_or_create(user=request.user)

    if request.method == 'DELETE':
        if profile.photo:
            profile.photo.delete(save=True)
        return Response({'photo_url': None})

    serializer = PhotoSerializer(data=request.data)
    serializer.is_valid(raise_exception=True)
    if profile.photo:
        # Retire l'ancien fichier du disque avant remplacement.
        profile.photo.delete(save=False)
    profile.photo = serializer.validated_data['photo']
    profile.save()

    url = profile.photo.url
    if request:
        url = request.build_absolute_uri(url)
    return Response({'photo_url': url})
