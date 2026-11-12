"""Tests de l'API comptes : inscription, connexion, profil, photo."""
import shutil
import tempfile

from django.contrib.auth import get_user_model
from django.core.files.uploadedfile import SimpleUploadedFile
from django.test import override_settings
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APITestCase

from .models import Profile

User = get_user_model()

# Petit PNG valide (1×1 pixel) pour les tests d'upload.
PNG_1PX = (
    b'\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00'
    b'\x01\x08\x06\x00\x00\x00\x1f\x15\xc4\x89\x00\x00\x00\nIDATx\x9cc'
    b'\x00\x01\x00\x00\x05\x00\x01\r\n-\xb4\x00\x00\x00\x00IEND\xaeB'
    b'\x60\x82'
)

TEMP_MEDIA = tempfile.mkdtemp(prefix='flowday_test_media_')


@override_settings(MEDIA_ROOT=TEMP_MEDIA)
class RegisterTests(APITestCase):
    def test_inscription_valide(self):
        """Inscription → 201 + jeton + profil."""
        response = self.client.post(
            '/api/auth/register/',
            {
                'email': 'Nina@Example.com',
                'password': 'MotDePasse2026!',
                'first_name': 'Nina',
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertIn('token', response.data)
        self.assertEqual(response.data['user']['email'], 'nina@example.com')
        self.assertEqual(response.data['user']['first_name'], 'Nina')
        # Le compte existe avec l'e-mail en minuscules.
        self.assertTrue(User.objects.filter(username='nina@example.com').exists())

    def test_inscription_email_invalide(self):
        response = self.client.post(
            '/api/auth/register/',
            {'email': 'pas-un-email', 'password': 'MotDePasse2026!'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('email', response.data)

    def test_inscription_doublon_refuse(self):
        """Un e-mail déjà utilisé est refusé (400)."""
        self.client.post(
            '/api/auth/register/',
            {'email': 'dup@example.com', 'password': 'MotDePasse2026!'},
            format='json',
        )
        response = self.client.post(
            '/api/auth/register/',
            {'email': 'dup@example.com', 'password': 'AutreMotDePasse2026!'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('email', response.data)

    def test_mdp_faible_refuse(self):
        """Les validateurs Django refusent un mot de passe faible."""
        response = self.client.post(
            '/api/auth/register/',
            {'email': 'weak@example.com', 'password': '12345678'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('password', response.data)


class LoginTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='login@example.com',
            email='login@example.com',
            password='MotDePasse2026!',
        )

    def test_connexion_valide(self):
        """Connexion → 200 + jeton réutilisable."""
        response = self.client.post(
            '/api/auth/login/',
            {'email': 'login@example.com', 'password': 'MotDePasse2026!'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        self.assertEqual(response.data['user']['email'], 'login@example.com')

        # Le jeton ouvre l'accès à /api/auth/me/.
        me = self.client.get(
            '/api/auth/me/',
            HTTP_AUTHORIZATION=f"Token {response.data['token']}",
        )
        self.assertEqual(me.status_code, status.HTTP_200_OK)
        self.assertEqual(me.data['email'], 'login@example.com')

    def test_mdp_incorrect_refuse(self):
        response = self.client.post(
            '/api/auth/login/',
            {'email': 'login@example.com', 'password': 'FauxMotDePasse'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('detail', response.data)

    def test_deconnexion_revoque_le_jeton(self):
        """POST /logout supprime le jeton (401 ensuite)."""
        token = Token.objects.create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {token.key}')
        response = self.client.post('/api/auth/logout/')
        self.assertEqual(response.status_code, status.HTTP_204_NO_CONTENT)
        self.assertFalse(Token.objects.filter(key=token.key).exists())

        me = self.client.get('/api/auth/me/')
        self.assertEqual(me.status_code, status.HTTP_401_UNAUTHORIZED)


@override_settings(MEDIA_ROOT=TEMP_MEDIA)
class ProfileTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='profil@example.com',
            email='profil@example.com',
            password='MotDePasse2026!',
            first_name='Josué',
        )
        self.token = Token.objects.create(user=self.user)
        self.client.credentials(HTTP_AUTHORIZATION=f'Token {self.token.key}')

    def test_me_sans_jetons_refuse(self):
        """Sans jeton → 401 (authentification requise)."""
        self.client.credentials()
        response = self.client.get('/api/auth/me/')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)

    def test_modification_nom_et_email(self):
        """PATCH modifie les informations de l'utilisateur."""
        response = self.client.patch(
            '/api/auth/me/',
            {'first_name': 'Mobina', 'last_name': 'K.',
             'email': 'nouveau@example.com'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['first_name'], 'Mobina')
        self.assertEqual(response.data['email'], 'nouveau@example.com')
        self.user.refresh_from_db()
        # L'identifiant de connexion suit le nouvel e-mail.
        self.assertEqual(self.user.username, 'nouveau@example.com')

    def test_changement_mdp_avec_mdp_actuel(self):
        """PATCH avec current_password + new_password change le mdp."""
        response = self.client.patch(
            '/api/auth/me/',
            {
                'current_password': 'MotDePasse2026!',
                'new_password': 'NouveauMotDePasse2026!',
            },
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)

        # L'ancien mot de passe ne marche plus, le nouveau oui.
        old = self.client.post(
            '/api/auth/login/',
            {'email': 'profil@example.com', 'password': 'MotDePasse2026!'},
            format='json',
        )
        self.assertEqual(old.status_code, status.HTTP_400_BAD_REQUEST)
        new = self.client.post(
            '/api/auth/login/',
            {'email': 'profil@example.com',
             'password': 'NouveauMotDePasse2026!'},
            format='json',
        )
        self.assertEqual(new.status_code, status.HTTP_200_OK)

    def test_changement_mdp_mauvais_mdp_actuel_refuse(self):
        response = self.client.patch(
            '/api/auth/me/',
            {'current_password': 'FauxMotDePasse',
             'new_password': 'NouveauMotDePasse2026!'},
            format='json',
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('current_password', response.data)
        self.user.refresh_from_db()
        self.assertTrue(
            self.user.check_password('MotDePasse2026!')  # inchangé
        )

    def test_upload_photo_de_profil(self):
        """POST multipart enregistre la photo et renvoie son URL."""
        photo = SimpleUploadedFile(
            'avatar.png', PNG_1PX, content_type='image/png'
        )
        response = self.client.post(
            '/api/auth/me/photo/', {'photo': photo}, format='multipart'
        )
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('photo_url', response.data)
        self.assertTrue(response.data['photo_url'].endswith('.png'))

        profile = Profile.objects.get(user=self.user)
        self.assertTrue(profile.photo.name)

        # Le profil GET expose la photo.
        me = self.client.get('/api/auth/me/')
        self.assertEqual(me.data['photo_url'], response.data['photo_url'])

    def test_remplacement_et_suppression_photo(self):
        """Un second envoi remplace l'ancien fichier ; DELETE efface tout."""
        first = SimpleUploadedFile(
            'a.png', PNG_1PX, content_type='image/png'
        )
        self.client.post(
            '/api/auth/me/photo/', {'photo': first}, format='multipart'
        )
        profile = Profile.objects.get(user=self.user)
        first_name = profile.photo.name

        second = SimpleUploadedFile(
            'b.png', PNG_1PX, content_type='image/png'
        )
        self.client.post(
            '/api/auth/me/photo/', {'photo': second}, format='multipart'
        )
        profile.refresh_from_db()
        self.assertNotEqual(profile.photo.name, first_name)

        response = self.client.delete('/api/auth/me/photo/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIsNone(response.data['photo_url'])
        profile.refresh_from_db()
        self.assertFalse(profile.photo)

    def test_photo_invalide_refusee(self):
        """Un fichier qui n'est pas une image est refusé (400)."""
        junk = SimpleUploadedFile(
            'note.txt', b'ce n\'est pas une image',
            content_type='text/plain',
        )
        response = self.client.post(
            '/api/auth/me/photo/', {'photo': junk}, format='multipart'
        )
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('photo', response.data)


def tearDownModule():
    shutil.rmtree(TEMP_MEDIA, ignore_errors=True)
