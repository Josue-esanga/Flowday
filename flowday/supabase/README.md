# Supabase — configuration du projet Flowday

## Photos de profil (Storage)

Les photos de profil sont stockées dans **Supabase Storage** (bucket public
`avatars`), dans un dossier par utilisateur :

```
avatars/<user-id>/avatar.jpg
```

Seule l'**URL publique** est enregistrée dans `user_metadata.avatar` : la photo
est donc retrouvée à chaque connexion, sur n'importe quel appareil (elle ne
dépend plus du stockage local du téléphone).

### Mise en place (une seule fois)

1. Ouvrir le projet Supabase → **SQL Editor** → **New query**.
2. Coller le contenu de [`avatars_bucket.sql`](./avatars_bucket.sql) puis
   **Run**.

Le script crée :

| Élément | Rôle |
| --- | --- |
| bucket `avatars` | stockage public, 5 Mo max, `image/jpeg`, `image/png`, `image/webp` |
| politique `select` | lecture publique des avatars (URL publique) |
| politiques `insert` / `update` / `delete` | chaque utilisateur connecté ne gère que son dossier `avatars/<user-id>/…` |

> Sans ce script, l'enregistrement d'une photo affiche « L'envoi des photos
> n'est pas encore activé » : le reste du profil (nom, téléphone…) fonctionne
> normalement.

### Vérifier

```sql
select id, name, public from storage.buckets where id = 'avatars';
```

Une ligne `avatars | avatars | true` confirme que le bucket est prêt.
