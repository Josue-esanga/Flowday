"""Serializers DRF : inscription, connexion et informations de compte.

Règles :
- l'e-mail est l'identifiant (unique, en minuscules) ;
- le mot de passe suit les validateurs Django (8 car. min., similarité…) ;
- le changement de mot de passe exige le mot de passe actuel.
"""
from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth import password_validation
from rest_framework import serializers

from .models import Profile

User = get_user_model()


class UserSerializer(serializers.ModelSerializer):
    """Profil de l'utilisateur (photo de profil incluse)."""

    photo_url = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'email', 'first_name', 'last_name', 'photo_url']
        read_only_fields = ['id', 'email']

    def get_photo_url(self, obj: User) -> str | None:
        profile = getattr(obj, 'profile', None)
        if profile is None or not profile.photo:
            return None
        url = profile.photo.url
        request = self.context.get('request')
        return request.build_absolute_uri(url) if request else url


class RegisterSerializer(serializers.Serializer):
    """Inscription : e-mail (identifiant) + mot de passe (8 car. min.)."""

    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)
    first_name = serializers.CharField(
        required=False, allow_blank=True, max_length=150
    )
    last_name = serializers.CharField(
        required=False, allow_blank=True, max_length=150
    )

    def validate_email(self, value: str) -> str:
        value = value.strip().lower()
        if User.objects.filter(username=value).exists():
            raise serializers.ValidationError(
                'Un compte existe déjà avec cette adresse.'
            )
        return value

    def validate_password(self, value: str) -> str:
        # Validateurs Django (longueur, mots communs, similarité…).
        email = str(self.initial_data.get('email', '')).strip().lower()
        password_validation.validate_password(
            value, user=User(username=email, email=email)
        )
        return value

    def create(self, validated_data: dict) -> User:
        email = validated_data['email']
        user = User.objects.create_user(
            username=email,
            email=email,
            password=validated_data['password'],
            first_name=validated_data.get('first_name', '').strip(),
            last_name=validated_data.get('last_name', '').strip(),
        )
        Profile.objects.get_or_create(user=user)
        return user


class LoginSerializer(serializers.Serializer):
    """Connexion : e-mail + mot de passe → compte authentifié."""

    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, attrs: dict) -> dict:
        user = authenticate(
            username=str(attrs['email']).strip().lower(),
            password=attrs['password'],
        )
        if user is None:
            raise serializers.ValidationError(
                {'detail': 'Adresse e-mail ou mot de passe incorrect.'}
            )
        attrs['user'] = user
        return attrs


class UpdateUserSerializer(serializers.ModelSerializer):
    """Modification des informations : nom, e-mail, mot de passe.

    Le changement de mot de passe exige `current_password` (sécurité).
    """

    current_password = serializers.CharField(
        write_only=True, required=False, allow_blank=True
    )
    new_password = serializers.CharField(
        write_only=True, required=False, allow_blank=True
    )

    class Meta:
        model = User
        fields = [
            'first_name',
            'last_name',
            'email',
            'current_password',
            'new_password',
        ]

    def validate_email(self, value: str) -> str:
        value = value.strip().lower()
        taken = User.objects.filter(username=value).exclude(
            pk=self.instance.pk if self.instance else None
        )
        if taken.exists():
            raise serializers.ValidationError(
                'Un compte existe déjà avec cette adresse.'
            )
        return value

    def validate(self, attrs: dict) -> dict:
        new_password = attrs.get('new_password') or ''
        if new_password:
            current = attrs.get('current_password') or ''
            if not current:
                raise serializers.ValidationError(
                    {'current_password': 'Le mot de passe actuel est requis.'}
                )
            user = self.instance
            if user is None or not authenticate(
                username=user.username, password=current
            ):
                raise serializers.ValidationError(
                    {'current_password': 'Mot de passe actuel incorrect.'}
                )
            password_validation.validate_password(new_password, user=user)
        return attrs

    def update(self, instance: User, validated_data: dict) -> User:
        validated_data.pop('current_password', None)
        new_password = validated_data.pop('new_password', '') or None
        new_email = validated_data.get('email')
        if new_email and new_email != instance.email:
            # L'e-mail est l'identifiant de connexion : on suit le username.
            instance.username = new_email
        instance.first_name = validated_data.get(
            'first_name', instance.first_name
        )
        instance.last_name = validated_data.get('last_name', instance.last_name)
        if new_email:
            instance.email = new_email
        if new_password:
            instance.set_password(new_password)
        instance.save()
        return instance


class PhotoSerializer(serializers.Serializer):
    """Upload de la photo de profil (JPEG/PNG, 2 Mo max.)."""

    photo = serializers.ImageField()

    def validate_photo(self, value):
        if value.size > 2 * 1024 * 1024:
            raise serializers.ValidationError(
                'Image trop lourde : 2 Mo maximum.'
            )
        return value
