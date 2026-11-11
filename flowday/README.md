# Flowday

## Cahier des charges fonctionnel

**Projet :** application mobile de gestion de tâches quotidiennes  
**Version :** 1.0  
**Date :** novembre 2026  
**Plateformes :** Android et iOS  
**Technologie recommandée :** Flutter

## 1. Présentation

Flowday est une application mobile de planification quotidienne. Elle permet
d'organiser les tâches d'une journée dans une timeline verticale, chaque tâche
étant associée à une date, une heure, une description et une catégorie.

L'application vise les étudiants, professionnels, indépendants et toute
personne souhaitant organiser sa journée simplement. Elle doit être sobre,
moderne, utilisable à une main et fonctionner hors ligne pour toutes les
fonctionnalités du MVP.

### Objectifs

- Planifier les tâches jour par jour.
- Lire rapidement le déroulement d'une journée grâce à une timeline.
- Suivre les tâches à faire et celles déjà terminées.
- Fournir une interface sombre, claire et agréable.
- Conserver les données localement sur l'appareil.

## 2. Périmètre fonctionnel

### MVP

| Référence | Fonctionnalité | Description | Priorité |
|---|---|---|---|
| F1 | Affichage des tâches du jour | Afficher les tâches dans une timeline triée par heure. | Haute |
| F2 | Sélecteur de semaine | Naviguer entre les sept jours de la semaine. | Haute |
| F3 | Création de tâche | Saisir un titre, une description, une date, une heure et une catégorie. | Haute |
| F4 | Modification de tâche | Modifier tous les champs d'une tâche existante. | Haute |
| F5 | Suppression de tâche | Supprimer une tâche après confirmation ou par glissement. | Haute |
| F6 | Terminaison de tâche | Appuyer sur le point de la timeline pour changer son état. | Haute |
| F7 | Catégories | Fournir Work, Health et Personal avec une couleur associée. | Moyenne |
| F8 | Stockage local | Persister les données et permettre l'utilisation hors ligne. | Haute |

### Évolutions prévues

- Notifications et rappels avant l'heure d'une tâche.
- Vue calendrier mensuelle avec indicateurs de jours chargés.
- Catégories personnalisées et choix de couleurs.
- Profil utilisateur avec nom, photo et statistiques.
- Paramètres du thème, de la langue et des notifications.
- Tâches récurrentes quotidiennes, hebdomadaires ou mensuelles.
- Synchronisation cloud avec compte utilisateur.
- Recherche et filtres par mot-clé, catégorie ou statut.

## 3. Navigation et écrans

La navigation principale comporte cinq destinations :

1. **Accueil** : timeline des tâches du jour.
2. **Calendrier** : vue mensuelle et sélection d'un jour.
3. **Ajout (+)** : création rapide d'une tâche.
4. **Paramètres** : thème, notifications, langue et informations.
5. **Profil** : informations de l'utilisateur et statistiques.

### 3.1 Accueil — « Today's task »

- Afficher une flèche de retour et le titre **Today's task**.
- Afficher horizontalement les sept jours de la semaine, avec le numéro de
  chaque jour.
- Sélectionner par défaut le jour courant.
- Mettre le jour sélectionné en évidence avec la couleur d'accent orange.
- Afficher les tâches du jour dans une timeline verticale.
- Placer l'heure à gauche et la carte de tâche à droite.
- Trier les tâches par heure croissante.
- Afficher un point par tâche ; un point coché indique une tâche terminée.
- Afficher un message vide : **« Aucune tâche pour ce jour »**.
- Afficher un bouton flottant orange **(+)** pour ajouter une tâche.

Chaque carte affiche l'heure, le titre, une description courte et l'étiquette
de catégorie avec sa pastille colorée. Une tâche terminée présente son titre et
sa description barrés ainsi qu'un point coché.

### 3.2 Ajout et modification d'une tâche

Le formulaire contient :

- un titre obligatoire ;
- une description facultative ;
- une date ;
- une heure ;
- une catégorie ;
- les boutons **Enregistrer** et **Annuler**.

Règles de validation :

- le titre ne peut pas être vide ;
- l'heure doit être valide ;
- l'enregistrement est refusé si une donnée obligatoire est invalide ;
- **Annuler** abandonne les changements sans modifier la tâche existante ;
- après enregistrement, la tâche est visible au jour sélectionné et à sa position
  chronologique.

### 3.3 Calendrier

La vue calendrier affiche un mois et permet de sélectionner un jour. La
sélection d'un jour affiche ses tâches dans la vue de tâches correspondante.
Les évolutions pourront ajouter des indicateurs visuels pour les jours
contenant des tâches.

### 3.4 Paramètres

L'écran regroupe :

- le choix du thème sombre ou clair ;
- l'activation et la gestion des notifications ;
- le choix de la langue ;
- les informations « À propos ».

Le thème sombre est le thème initial du produit.

### 3.5 Profil

L'écran affiche les informations de l'utilisateur et les statistiques de
productivité, notamment le nombre de tâches terminées et le taux de réussite.
Cet écran appartient aux évolutions et peut rester minimal dans le MVP.

## 4. Règles métier

- Chaque tâche possède un identifiant unique.
- Une tâche appartient à une date et à une heure précises.
- Les tâches d'un même jour sont toujours triées par heure croissante.
- Une tâche nouvellement créée est à l'état « à faire ».
- Appuyer sur le point de la timeline inverse l'état terminé / à faire.
- Une tâche terminée reste visible dans la timeline, mais son contenu est barré.
- La suppression doit demander une confirmation lorsqu'elle n'est pas réalisée
  par un geste explicitement confirmé.
- Les catégories du MVP sont `Work`, `Health` et `Personal`.
- Une tâche peut être créée, modifiée, supprimée ou terminée sans connexion.
- Les données doivent rester disponibles après fermeture et réouverture de
  l'application.

## 5. Modèle de données

### Tâche

| Champ | Type | Règle ou description |
|---|---|---|
| `id` | UUID | Identifiant unique obligatoire. |
| `title` | Texte | Titre obligatoire. |
| `description` | Texte | Description courte facultative. |
| `date` | Date | Jour planifié. |
| `time` | Heure | Heure prévue et valide. |
| `categoryId` | Référence | Catégorie associée. |
| `completed` | Booléen | État terminé ou à faire. |
| `reminder` | Booléen / durée | Rappel optionnel, prévu pour une évolution. |
| `createdAt` | Date/heure | Date de création. |

### Catégorie

| Champ | Type | Description |
|---|---|---|
| `id` | Identifiant | Identifiant unique. |
| `name` | Texte | Exemple : Work, Health ou Personal. |
| `color` | Texte hexadécimal | Couleur de la pastille et de l'étiquette. |

Couleurs par défaut :

- **Work** : orange ;
- **Health** : jaune ;
- **Personal** : rouge.

## 6. Charte graphique et expérience utilisateur

- Thème initial sombre : fond gris très foncé et cartes gris anthracite.
- Couleur d'accent : orange vif pour le jour actif, le bouton d'ajout et la
  timeline.
- Typographie sans-serif moderne et lisible, par exemple Inter ou Poppins.
- Cartes et composants avec coins arrondis.
- Icônes linéaires de style outline et cohérentes entre les écrans.
- Contrastes suffisants et tailles de texte adaptables.
- Zones tactiles d'au moins 44 px.
- Création d'une tâche en trois appuis maximum lorsque le parcours est nominal.
- Interface adaptative pour les différentes tailles d'écran.

## 7. Architecture technique proposée

| Couche | Choix recommandé |
|---|---|
| Application mobile | Flutter et Dart |
| Gestion d'état | Provider, Riverpod ou Bloc |
| Stockage local | SQLite, Hive ou Realm |
| Notifications | `flutter_local_notifications` ou équivalent |
| Backend optionnel | API REST Node.js ou Laravel |
| Base cloud optionnelle | PostgreSQL ou MySQL |
| Design | Figma |
| Versionnage | Git et GitHub |

L'architecture doit séparer au minimum la présentation, la gestion d'état, le
domaine métier et la persistance locale. Le backend et le compte utilisateur
ne sont pas nécessaires au MVP.

## 8. Exigences non fonctionnelles

- Temps d'ouverture cible inférieur à deux secondes.
- Défilement fluide à environ 60 images par seconde.
- Fonctionnement hors ligne de toutes les fonctions du MVP.
- Compatibilité Android 8 ou supérieur et iOS 13 ou supérieur.
- Utilisation correcte sur différentes tailles d'écran.
- Données locales protégées ; chiffrement et authentification requis en cas de
  synchronisation cloud.
- Code structuré, maintenable, documenté lorsque nécessaire et versionné avec
  Git.

## 9. Planning prévisionnel

| Phase | Contenu | Durée estimée |
|---|---|---|
| 1. Analyse et cadrage | Besoins et validation du cahier des charges. | 1 semaine |
| 2. Conception UI/UX | Maquettes Figma et prototype interactif. | 2 semaines |
| 3. Développement MVP | Accueil, CRUD des tâches et stockage local. | 4 semaines |
| 4. Fonctions secondaires | Notifications, calendrier, paramètres et profil. | 3 semaines |
| 5. Tests et corrections | Tests fonctionnels, utilisabilité et corrections. | 2 semaines |
| 6. Publication | APK, IPA, mise en ligne et documentation. | 1 semaine |

**Durée totale estimée : environ 13 semaines.**

## 10. Tests et critères d'acceptation

La version MVP est validée lorsque :

- l'utilisateur peut créer une tâche valide sans erreur ;
- l'utilisateur peut modifier tous les champs d'une tâche ;
- l'utilisateur peut supprimer une tâche avec confirmation ;
- l'utilisateur peut marquer une tâche comme terminée puis revenir à l'état
  « à faire » ;
- les tâches du jour sélectionné sont triées par heure ;
- le changement de jour actualise la liste affichée ;
- le message d'état vide apparaît lorsqu'aucune tâche n'existe ;
- les données persistent après fermeture et réouverture ;
- les couleurs, cartes, timeline et navigation respectent la maquette ;
- aucune erreur bloquante n'est observée sur les appareils Android et iOS de
  test ;
- les actions principales restent utilisables hors connexion.

## 11. Risques et mesures prévues

| Risque | Impact | Mesure |
|---|---|---|
| Dépassement des délais | Moyen | Livrer le MVP avant les évolutions. |
| Restrictions de notifications | Moyen | Tester sur plusieurs appareils et documenter les limites. |
| Perte de données locales | Élevé | Prévoir export ou sauvegarde, puis synchronisation cloud. |
| Tailles d'écran variées | Faible | Utiliser une interface adaptative et tester plusieurs formats. |

## 12. Livrables

- Code source complet de l'application.
- Maquettes et prototype Figma.
- Application installable Android (APK) et iOS (IPA).
- Documentation technique.
- Guide d'utilisation.
