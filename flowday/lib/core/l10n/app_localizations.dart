import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Localisation légère de Flowday (français par défaut, anglais optionnel).
///
/// Les textes sources restent écrits dans les écrans : [t] renvoie le texte
/// tel quel en français et sa traduction anglaise en anglais. Une clé
/// manquante est simplement rendue en français (aucun écran vide).
///
/// L'instance courante est aussi accessible hors des widgets
/// ([instance]) pour les providers, les erreurs réseau et les
/// notifications locales.
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations _instance = AppLocalizations(const Locale('fr'));

  /// Instance de la langue courante (utile hors `BuildContext`).
  static AppLocalizations get instance => _instance;

  static const List<Locale> supportedLocales = [Locale('fr'), Locale('en')];

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      _instance;

  bool get isEnglish => locale.languageCode == 'en';

  /// Traduit [french] vers la langue courante.
  String t(String french) => isEnglish ? (_en[french] ?? french) : french;

  // ---------------------------------------------------------------------
  // Textes avec valeurs dynamiques
  // ---------------------------------------------------------------------
  String greeting(String name) => isEnglish ? 'Hey $name!' : 'Hey $name !';

  String searchNoResults(String query) =>
      isEnglish ? 'No results for “$query”' : 'Aucun résultat pour « $query »';

  String nTasks(int count) => isEnglish
      ? '$count task${count == 1 ? '' : 's'}'
      : '$count tâche${count > 1 ? 's' : ''}';

  /// Bandeau hors ligne (F8) : modifications en attente de synchronisation.
  String offlinePending(int count) => isEnglish
      ? 'Offline — $count pending ${count == 1 ? 'change' : 'changes'}.'
      : 'Hors ligne — $count modification${count > 1 ? 's' : ''} en attente.';

  String plannedTasks(int count) {
    if (isEnglish) {
      if (count == 0) return 'No tasks planned';
      return '$count task${count == 1 ? '' : 's'} planned';
    }
    if (count == 0) return 'Aucune tâche prévue';
    return '$count tâche${count > 1 ? 's' : ''} prévue${count > 1 ? 's' : ''}';
  }

  /// Libellé complet du délai de rappel (« 15 minutes avant »).
  String reminderDelay(int minutes) {
    if (minutes == 0) {
      return t('À l’heure de la tâche');
    }
    if (minutes % (24 * 60) == 0) {
      final days = minutes ~/ (24 * 60);
      if (isEnglish) {
        return days == 1 ? '1 day before' : '$days days before';
      }
      return '$days jour${days > 1 ? 's' : ''} avant';
    }
    if (minutes < 60) {
      return isEnglish ? '$minutes minutes before' : '$minutes minutes avant';
    }
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    if (isEnglish) {
      final hourLabel = hours == 1 ? '1 hour' : '$hours hours';
      final label = remaining == 0 ? hourLabel : '$hourLabel $remaining min';
      return '$label before';
    }
    final hourLabel = '$hours heure${hours > 1 ? 's' : ''}';
    final label = remaining == 0 ? hourLabel : '$hourLabel $remaining min';
    return '$label avant';
  }

  /// Libellé court des puces du sélecteur de rappel.
  String reminderChipLabel(int minutes) {
    if (minutes == 0) return t('À l’heure');
    if (minutes == 24 * 60) return t('1 jour');
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    return isEnglish ? '${hours}h' : '$hours h';
  }

  /// Durée compacte utilisée dans le corps de la notification.
  String reminderDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final remaining = minutes % 60;
    final hourLabel = isEnglish ? '${hours}h' : '$hours h';
    return remaining == 0 ? hourLabel : '$hourLabel $remaining min';
  }

  String deleteTaskBody(String title) => isEnglish
      ? '“$title” will be permanently deleted.'
      : '« $title » sera définitivement supprimée.';

  String exportedTasks(int count) => isEnglish
      ? '$count task${count == 1 ? '' : 's'} copied to the clipboard (JSON).'
      : '$count tâche(s) copiée(s) dans le presse-papiers (JSON).';

  String taskCompletedSemantics(String title) =>
      isEnglish ? 'Completed task: $title' : 'Tâche terminée : $title';

  String taskToCompleteSemantics(String title) =>
      isEnglish ? 'Complete: $title' : 'Terminer : $title';

  String taskStartsIn(String title, String delay) =>
      isEnglish ? '$title starts in $delay.' : '$title commence dans $delay.';

  // ---------------------------------------------------------------------
  // Catégories (noms et descriptions connus ; repli sur l'API)
  // ---------------------------------------------------------------------
  String categoryName(String id, String fallback) {
    final names = isEnglish ? _categoryNamesEn : _categoryNamesFr;
    return names[id] ?? fallback;
  }

  String categoryDescription(String id, String fallback) {
    final descriptions = isEnglish
        ? _categoryDescriptionsEn
        : _categoryDescriptionsFr;
    return descriptions[id] ?? fallback;
  }

  // ---------------------------------------------------------------------
  // Dates
  // ---------------------------------------------------------------------
  List<String> get months => isEnglish ? _monthsEn : _monthsFr;

  List<String> get weekdays => isEnglish ? _weekdaysEn : _weekdaysFr;

  List<String> get weekLabels => isEnglish ? _weekLabelsEn : _weekLabelsFr;

  /// « 13 novembre 2026 » / « November 13, 2026 ».
  String displayDate(DateTime date) => isEnglish
      ? '${months[date.month - 1]} ${date.day}, ${date.year}'
      : '${date.day} ${months[date.month - 1]} ${date.year}';

  /// « Vendredi 13 novembre » / « Friday, November 13 ».
  String summaryDate(DateTime date) => isEnglish
      ? '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}'
      : '${weekdays[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';

  // ---------------------------------------------------------------------
  // Données de langue
  // ---------------------------------------------------------------------
  static const List<String> _monthsFr = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  static const List<String> _monthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdaysFr = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  static const List<String> _weekdaysEn = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const List<String> _weekLabelsFr = [
    'Lun',
    'Mar',
    'Mer',
    'Jeu',
    'Ven',
    'Sam',
    'Dim',
  ];

  static const List<String> _weekLabelsEn = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const Map<String, String> _categoryNamesFr = {
    'personal': 'Personnel',
    'work': 'Travail',
    'health': 'Santé',
    'education': 'Éducation',
  };

  static const Map<String, String> _categoryNamesEn = {
    'personal': 'Personal',
    'work': 'Work',
    'health': 'Health',
    'education': 'Education',
  };

  static const Map<String, String> _categoryDescriptionsFr = {
    'personal': 'Maison, famille\net quotidien',
    'work': 'Réunions, échéances\net bureau',
    'health': 'Sport, alimentation\net bien-être',
    'education': 'Cours, lecture\net apprentissage',
  };

  static const Map<String, String> _categoryDescriptionsEn = {
    'personal': 'Home, family\n& daily life',
    'work': 'Meetings, deadlines\n& office tasks',
    'health': 'Sport, food\n& well-being',
    'education': 'Courses, reading\n& learning',
  };

  static const Map<String, String> _en = {
    // Commun
    'Réessayer': 'Try again',
    'Annuler': 'Cancel',
    'Enregistrer': 'Save',
    'Supprimer': 'Delete',
    'Fermer': 'Close',
    'Modifier': 'Edit',
    'Retour': 'Back',
    'Chargement…': 'Loading…',

    // Paramètres
    'Autorisez les notifications dans les réglages du téléphone.':
        'Allow notifications in your phone settings.',
    'Paramètres': 'Settings',
    'Apparence': 'Appearance',
    'Thème sombre': 'Dark theme',
    'Notifications': 'Notifications',
    'Activer les rappels': 'Enable reminders',
    'Rappel par défaut': 'Default reminder',
    'Langue': 'Language',
    'Langue de l’application': 'App language',
    'Compte': 'Account',
    'Connecté en tant que': 'Signed in as',
    'À propos': 'About',
    'Choisir la langue': 'Choose language',
    'La langue s’applique à toute l’application.':
        'The language applies to the whole app.',
    'Français': 'French',
    'English': 'English',

    // Rappel par défaut
    'Quand souhaitez-vous être rappelé ?':
        'When would you like to be reminded?',
    'Personnaliser le délai': 'Custom delay',
    'À l’heure': 'On time',
    '1 jour': '1 day',
    'Délai personnalisé': 'Custom delay',
    'Choisissez combien de temps avant la tâche.':
        'Choose how long before the task.',
    'Heures': 'Hours',
    'Minutes': 'Minutes',
    'Maximum : 7 jours. Vérifiez les valeurs.':
        'Maximum: 7 days. Check the values.',
    'À l’heure de la tâche': 'At task time',
    '1 jour avant': '1 day before',

    // Accueil
    'Rechercher': 'Search',
    'Catégories': 'Categories',
    'Aucune catégorie': 'No categories',
    'Tâche du jour': "Today's task",
    'Tout voir': 'See all',
    'Aucune tâche pour ce jour': 'No tasks for this day',
    'Tâche d’hier': "Yesterday's task",
    'Aucune tâche hier': 'No tasks yesterday',
    'Trouvons\nvotre meilleure journée !': "Let's find your\nbest day!",

    // Calendrier
    'Calendrier': 'Calendar',
    'Voir les tâches du jour': "See today's tasks",
    'Tâches prévues': 'Tasks planned',

    // Onboarding
    'Bienvenue sur Flowday': 'Welcome to Flowday',
    'Votre journée, plus claire, une tâche à la fois.':
        'Your day, clearer, one task at a time.',
    'Planifiez sans effort': 'Plan with ease',
    'Regroupez vos tâches par jour et par catégorie. Le calendrier montre '
            'immédiatement les journées déjà chargées.':
        'Group your tasks by day and category. The calendar instantly shows '
        'days that are already busy.',
    'Gardez le cap': 'Stay on track',
    'Cochez vos tâches, suivez votre progression et avancez chaque jour '
            'avec un tableau de bord qui reste simple.':
        'Check off tasks, track your progress and move forward every day '
        'with a dashboard that stays simple.',
    'Ne manquez plus rien': 'Never miss a thing',
    'Autorisez les notifications pour recevoir un rappel au bon moment. '
            'Vous pourrez changer d’avis dans les paramètres.':
        'Allow notifications to get a reminder at the right time. You can '
        'change your mind in Settings.',
    'Passer': 'Skip',
    'Suivant': 'Next',
    'Commencer': 'Get started',
    'Activer les notifications': 'Enable notifications',
    'Plus tard': 'Later',
    'Aujourd’hui': 'Today',
    'Organisé': 'Organized',
    'Préparer la réunion': 'Prepare the meeting',
    'Séance de sport': 'Workout',
    'Lire 20 pages': 'Read 20 pages',
    'Meeting with Shakib · 09:00': 'Meeting with Shakib · 09:00',
    'Notifications désactivées. Vous pourrez les activer dans les '
            'paramètres.':
        'Notifications are off. You can enable them in Settings.',

    // Timeline / tâches
    'Action impossible (serveur injoignable).':
        'Action unavailable (server unreachable).',
    'Today': 'Today',
    'Modifier la tâche': 'Edit task',
    'Supprimer la tâche ?': 'Delete task?',
    'Suppression impossible.': 'Deletion failed.',
    'Terminée': 'Done',
    'À faire': 'To do',
    'Impossible de contacter le serveur.': 'Unable to reach the server.',
    'Hors ligne — données enregistrées sur cet appareil.':
        'Offline — data saved on this device.',
    'Action impossible pour le moment. Réessayez.':
        'Action unavailable right now. Try again.',
    'Aucune tâche dans cette catégorie': 'No tasks in this category',

    // Formulaire de tâche
    'Le titre est obligatoire.': 'Title is required.',
    'Choisissez une catégorie.': 'Choose a category.',
    'New task': 'New task',
    'Edit task': 'Edit task',
    'Title *': 'Title *',
    'Ex. Meeting with Shakib': 'E.g. Meeting with Shakib',
    'Description': 'Description',
    'Short description': 'Short description',
    'Date': 'Date',
    'Time': 'Time',
    'Category': 'Category',
    'Chargement des catégories…': 'Loading categories…',
    'Créer': 'Create',
    'Supprimer la tâche': 'Delete task',

    // Profil
    'Votre profil': 'Your profile',
    'Profil mis à jour.': 'Profile updated.',
    'Aucune tâche à exporter.': 'No tasks to export.',
    'Vous êtes déconnecté.': 'You are signed out.',
    'Profil': 'Profile',
    'Statistiques indisponibles.': 'Statistics unavailable.',
    'Terminées': 'Completed',
    'Réussite': 'Success',
    'Cette semaine': 'This week',
    'Informations personnelles': 'Personal information',
    'Nom complet': 'Full name',
    'Adresse e-mail': 'Email address',
    'Exporter mes tâches': 'Export my tasks',
    'Copier une sauvegarde au format JSON': 'Copy a JSON backup',
    'Se déconnecter': 'Sign out',
    'Notifications, apparence et langue':
        'Notifications, appearance and language',

    // Modification du profil
    'Le prénom et le nom sont obligatoires.':
        'First and last name are required.',
    'Modifier le profil': 'Edit profile',
    'Mettez à jour vos coordonnées personnelles':
        'Update your personal details',
    'Photo de profil': 'Profile photo',
    'Ajouter une photo': 'Add a photo',
    'Changer la photo': 'Change photo',
    'Retirer la photo': 'Remove photo',
    'Prénom': 'First name',
    'Nom': 'Last name',
    'Enregistrer les modifications': 'Save changes',

    // Authentification
    'Prêt pour une journée productive ?': 'Ready for a productive day?',
    'Se connecter': 'Sign in',
    'Retrouvez vos listes et atteignez vos objectifs du jour.':
        'Find your lists and reach your goals for the day.',
    'L’adresse e-mail est obligatoire.': 'Email address is required.',
    'Adresse e-mail invalide.': 'Invalid email address.',
    'Le mot de passe est obligatoire.': 'Password is required.',
    'Mot de passe oublié ?': 'Forgot password?',
    'Adresse email': 'Email address',
    'Envoyer le lien': 'Send link',
    'Si un compte existe avec cette adresse, un e-mail de réinitialisation '
            'vient de vous être envoyé.':
        'If an account exists with this address, a reset email has been sent.',
    'Connexion Google / Apple non disponible pour le moment.':
        'Google / Apple sign-in is not available yet.',
    'Mot de passe': 'Password',
    'OU CONTINUER AVEC': 'OR CONTINUE WITH',
    'Pas encore de compte ? ': "Don't have an account? ",
    "S'inscrire": 'Sign up',
    'Organisez votre quotidien': 'Organize your day',
    'Créer un compte': 'Create account',
    'Structurez vos tâches et gagnez en clarté dès aujourd\'hui.':
        'Structure your tasks and gain clarity today.',
    'Le nom est obligatoire.': 'Name is required.',
    'Nom trop court.': 'Name too short.',
    '8 caractères minimum.': 'At least 8 characters.',
    'Minimum 8 caractères': 'At least 8 characters',
    'Créer mon compte': 'Create my account',
    "OU S'INSCRIRE AVEC": 'OR SIGN UP WITH',
    'Déjà un compte ? ': 'Already have an account? ',
    'Inscription Google / Apple non disponible pour le moment.':
        'Google / Apple sign-up is not available yet.',
    'Un e-mail de confirmation vient de vous être envoyé. Cliquez sur le '
            'lien, puis connectez-vous.':
        'A confirmation email has just been sent. Click the link, then sign in.',
    'Votre adresse e-mail est confirmée. Bienvenue !':
        'Your email address is confirmed. Welcome!',
    'Le lien de confirmation est invalide ou a expiré. Inscrivez-vous de '
            'nouveau pour recevoir un nouvel e-mail.':
        'The confirmation link is invalid or has expired. Sign up again to '
        'receive a new email.',
    'Le lien de confirmation est invalide ou a expiré. Demandez un nouvel '
            'e-mail puis réessayez.':
        'The confirmation link is invalid or has expired. Request a new email '
        'and try again.',
    'Impossible de joindre le serveur. Vérifiez votre connexion internet, '
            'puis réessayez.':
        'Unable to reach the server. Check your internet connection and try '
        'again.',
    'Votre session a expiré. Veuillez vous reconnecter.':
        'Your session has expired. Please sign in again.',

    // Déconnexion
    'Se déconnecter ?': 'Sign out?',
    'Vos données restent enregistrées sur votre compte : vous pourrez vous '
            'reconnecter à tout moment.':
        'Your data stays saved to your account: you can sign back in at any '
        'time.',

    // Erreurs réseau / API
    'Cet élément est introuvable : il a peut-être été supprimé.':
        'This item cannot be found: it may have been deleted.',
    'Cet enregistrement existe déjà.': 'This record already exists.',
    'Trop de tentatives. Réessayez dans quelques instants.':
        'Too many attempts. Try again in a moment.',
    'Cette opération est impossible : la catégorie liée est introuvable.':
        'This action is unavailable: the related category cannot be found.',
    'Saisie trop longue : réduisez la taille de vos informations, puis '
            'réessayez.':
        'Input too long: shorten your information and try again.',
    'Vérifiez les informations saisies, puis réessayez.':
        'Check the information entered and try again.',
    'Le service rencontre un problème. Réessayez plus tard.':
        'The service is having a problem. Try again later.',
    'Une erreur est survenue. Réessayez plus tard.':
        'An error occurred. Try again later.',
    'Tâche introuvable.': 'Task not found.',
    "La tâche n'a pas pu être créée.": 'The task could not be created.',
    "Le compte n'a pas pu être créé. Réessayez plus tard.":
        'The account could not be created. Try again later.',
    'Application non configurée. Contactez le support.':
        'App not configured. Contact support.',
    'Adresse e-mail ou mot de passe incorrect.':
        'Incorrect email address or password.',
    'Veuillez confirmer votre adresse e-mail avant de vous connecter '
            '(vérifiez votre boîte mail).':
        'Please confirm your email address before signing in (check your inbox).',
    'Un compte existe déjà avec cette adresse e-mail.':
        'An account already exists with this email address.',
    'Mot de passe trop faible : 8 caractères minimum.':
        'Password too weak: at least 8 characters.',
    'Identifiants incorrects ou accès refusé.':
        'Incorrect credentials or access denied.',

    // Notifications locales
    'C’est l’heure de votre tâche': "It's time for your task",
    'Rappel de tâche': 'Task reminder',
    'Rappels de tâches': 'Task reminders',
    'Rappels à l’heure prévue pour vos tâches':
        'Reminders at the scheduled time for your tasks',
  };
}

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  String tr(String french) => AppLocalizations.of(this).t(french);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'fr' || locale.languageCode == 'en';

  @override
  Future<AppLocalizations> load(Locale locale) {
    final localizations = AppLocalizations(
      Locale(isSupported(locale) ? locale.languageCode : 'fr'),
    );
    AppLocalizations._instance = localizations;
    return SynchronousFuture(localizations);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      true;
}
