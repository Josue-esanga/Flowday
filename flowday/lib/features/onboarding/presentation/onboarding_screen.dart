import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/services/task_reminder_service.dart';
import '../../../shared/widgets/flowday_logo.dart';

/// Accent violet de l'onboarding (maquette) : bouton circulaire et
/// point de progression actif.
const _accent = Color(0xFF6C5CE7);

/// Premier lancement de Flowday : présentation de l'application, puis
/// proposition d'activer les rappels. L'achèvement est mémorisé par
/// [OnboardingProvider] ; l'écran n'est donc affiché qu'une seule fois.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _notificationPage = 3;

  final PageController _pages = PageController();
  int _page = 0;
  bool _finishing = false;

  /// Le spinner n'apparaît que pendant la demande de permission (le choix
  /// « Plus tard » referme l'écran sans faux indicateur d'attente).
  bool _requestingNotifications = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _isNotificationPage => _page == _notificationPage;

  void _goToNotifications() {
    HapticFeedback.selectionClick();
    _pages.animateToPage(
      _notificationPage,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    if (_isNotificationPage) return;
    HapticFeedback.selectionClick();
    _pages.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish({required bool enableNotifications}) async {
    if (_finishing) return;
    setState(() {
      _finishing = true;
      _requestingNotifications = enableNotifications;
    });
    HapticFeedback.lightImpact();

    var notificationsEnabled = false;
    if (enableNotifications) {
      try {
        notificationsEnabled = await TaskReminderService.instance.setEnabled(
          true,
        );
      } catch (_) {
        notificationsEnabled = false;
      }
    }

    if (!mounted) return;
    if (enableNotifications && !notificationsEnabled) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              context.tr(
                'Notifications désactivées. Vous pourrez les activer dans les '
                'paramètres.',
              ),
            ),
          ),
        );
    }

    await context.read<OnboardingProvider>().complete();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final foreground = theme.colorScheme.onSurface;
    final muted = foreground.withValues(alpha: 0.62);

    final pages = <_OnboardingPageData>[
      _OnboardingPageData(
        title: l10n.t('Bienvenue sur Flowday'),
        description: l10n.t('Votre journée, plus claire, une tâche à la fois.'),
        illustration: const _WelcomeIllustration(),
      ),
      _OnboardingPageData(
        title: l10n.t('Planifiez sans effort'),
        description: l10n.t(
          'Regroupez vos tâches par jour et par catégorie. Le calendrier '
          'montre immédiatement les journées déjà chargées.',
        ),
        illustration: const _CalendarIllustration(),
      ),
      _OnboardingPageData(
        title: l10n.t('Gardez le cap'),
        description: l10n.t(
          'Cochez vos tâches, suivez votre progression et avancez chaque '
          'jour avec un tableau de bord qui reste simple.',
        ),
        illustration: const _FocusIllustration(),
      ),
      _OnboardingPageData(
        title: l10n.t('Ne manquez plus rien'),
        description: l10n.t(
          'Autorisez les notifications pour recevoir un rappel au bon '
          'moment. Vous pourrez changer d’avis dans les paramètres.',
        ),
        illustration: const _NotificationIllustration(),
      ),
    ];

    final actionBackground = isDark
        ? theme.colorScheme.primary
        : AppColors.dark;
    final actionForeground = isDark ? Colors.black : Colors.white;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // ----------------------------------------------------------
            // Marque + passage direct aux notifications.
            // ----------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 14, 0),
              child: Row(
                children: [
                  // Retour (inerte sur la première page, comme la maquette).
                  IconButton(
                    onPressed: _page == 0
                        ? null
                        : () {
                            HapticFeedback.selectionClick();
                            _pages.previousPage(
                              duration: const Duration(milliseconds: 360),
                              curve: Curves.easeOutCubic,
                            );
                          },
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 17,
                      color: _page == 0
                          ? muted.withValues(alpha: 0.4)
                          : foreground,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  const FlowdayLogo(size: 30),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Flowday',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'DancingScript',
                        fontVariations: const [FontVariation('wght', 700)],
                        fontWeight: FontWeight.w700,
                        fontSize: 23,
                        color: isDark ? foreground : AppColors.dark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  if (!_isNotificationPage)
                    TextButton(
                      onPressed: _goToNotifications,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l10n.t('Passer'),
                        style: TextStyle(color: muted),
                      ),
                    ),
                ],
              ),
            ),

            // ----------------------------------------------------------
            // Pages illustrées.
            // ----------------------------------------------------------
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: pages.length,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) => _OnboardingPage(
                  data: pages[index],
                  foreground: foreground,
                  muted: muted,
                ),
              ),
            ),

            // ----------------------------------------------------------
            // Progression + action principale.
            // ----------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 22),
              child: Column(
                children: [
                  // Points de progression à gauche, action circulaire à
                  // droite (maquette) ; la dernière page garde les deux
                  // boutons d'action pleine largeur.
                  Row(
                    children: [
                      _ProgressBar(
                        count: pages.length,
                        page: _page,
                        active: _accent,
                        inactive: foreground.withValues(alpha: 0.15),
                      ),
                      const Spacer(),
                      if (!_isNotificationPage)
                        _NextCircleButton(onPressed: _next),
                    ],
                  ),
                  if (_isNotificationPage) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        key: const Key('onboarding-enable-notifications'),
                        onPressed: _finishing
                            ? null
                            : () => _finish(enableNotifications: true),
                        style: FilledButton.styleFrom(
                          backgroundColor: actionBackground,
                          foregroundColor: actionForeground,
                          disabledBackgroundColor: actionBackground.withValues(
                            alpha: 0.6,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _requestingNotifications
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: actionForeground,
                                ),
                              )
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.notifications_active_outlined,
                                    size: 21,
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      l10n.t('Activer les notifications'),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton(
                      key: const Key('onboarding-later'),
                      onPressed: _finishing
                          ? null
                          : () => _finish(enableNotifications: false),
                      child: Text(
                        l10n.t('Plus tard'),
                        style: TextStyle(color: muted),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Points de progression : le point courant s'allonge en pastille violette,
/// les autres restent des cercles gris clair (voir la maquette).
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.count,
    required this.page,
    required this.active,
    required this.inactive,
  });

  final int count;
  final int page;
  final Color active;
  final Color inactive;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < count; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: EdgeInsets.only(right: index == count - 1 ? 0 : 5),
            width: index == page ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == page ? active : inactive,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
      ],
    );
  }
}

/// Bouton rond dégradé de la maquette : flèche blanche sur un violet
/// dégradé, avec une ombre portée teintée.
class _NextCircleButton extends StatelessWidget {
  const _NextCircleButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.t('Suivant'),
      child: GestureDetector(
        key: const Key('onboarding-next'),
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF8B7CF8), Color(0xFF6455E8)],
            ),
            boxShadow: [
              BoxShadow(
                color: _accent.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    required this.illustration,
  });

  final String title;
  final String description;
  final Widget illustration;
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.data,
    required this.foreground,
    required this.muted,
  });

  final _OnboardingPageData data;
  final Color foreground;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: foreground,
              fontSize: 30,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            data.description,
            style: TextStyle(color: muted, fontSize: 14.5, height: 1.5),
          ),
          const SizedBox(height: 22),
          // L'illustration occupe tout l'espace restant (borné), comme le
          // bloc illustré de la maquette : pas de grand blanc inutile.
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 460,
                  maxHeight: 440,
                ),
                child: data.illustration,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cadre commun aux illustrations : dégradé lavande (mode clair) ou violet
/// profond (mode sombre) rehaussé de deux pastilles douces — les cartes
/// blanches ressortent, comme sur la maquette.
class _IllustrationFrame extends StatelessWidget {
  const _IllustrationFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark
        ? const [Color(0xFF2B2742), Color(0xFF1E1B2C)]
        : const [Color(0xFFF8F6FF), Color(0xFFEDE8FE)];
    final blob = isDark ? const Color(0xFF4C4376) : const Color(0xFFDCD2FC);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: const Alignment(-1.3, -1.15),
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blob.withValues(alpha: 0.7),
              ),
            ),
          ),
          Align(
            alignment: const Alignment(1.45, 1.2),
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: blob.withValues(alpha: 0.45),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _WelcomeIllustration extends StatelessWidget {
  const _WelcomeIllustration();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _IllustrationFrame(
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FlowdayLogo(size: 138),
              const SizedBox(height: 22),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniPill(
                    label: l10n.t('Aujourd’hui'),
                    color: AppColors.health,
                  ),
                  const SizedBox(width: 8),
                  _MiniPill(
                    label: l10n.t('Organisé'),
                    color: AppColors.education,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarIllustration extends StatelessWidget {
  const _CalendarIllustration();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final now = DateTime.now();
    final week = l10n.isEnglish
        ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
        : const ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    const taskDays = <int>{3, 7, 12, 17, 21, 26};

    // Taille de design fixe : le calendrier est mis à l'échelle par un
    // `FittedBox` au lieu d'utiliser une grille qui se taille toute seule
    // (trop étroite sur les petits écrans, d'où les débordements).
    return _IllustrationFrame(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 250,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 22,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${l10n.months[now.month - 1][0].toUpperCase()}'
                          '${l10n.months[now.month - 1].substring(1)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.dark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final day in week)
                        Expanded(
                          child: Center(
                            child: Text(
                              day,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // 4 rangées fixes de 7 jours (pas de `GridView`).
                  for (var weekIndex = 0; weekIndex < 4; weekIndex++)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          for (var column = 0; column < 7; column++)
                            Expanded(
                              child: _MiniCalendarDay(
                                day: weekIndex * 7 + column + 1,
                                hasTasks: taskDays.contains(
                                  weekIndex * 7 + column + 1,
                                ),
                                selected: weekIndex * 7 + column + 1 == 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniCalendarDay extends StatelessWidget {
  const _MiniCalendarDay({
    required this.day,
    required this.hasTasks,
    required this.selected,
  });

  final int day;
  final bool hasTasks;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: 26,
        height: 30,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? AppColors.dark : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$day',
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.text,
                  fontSize: 8,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 1),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: hasTasks ? AppColors.work : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusIllustration extends StatelessWidget {
  const _FocusIllustration();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _IllustrationFrame(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 280,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MiniTaskCard(
                    title: l10n.t('Préparer la réunion'),
                    time: '09:00',
                    color: AppColors.work,
                    completed: true,
                  ),
                  const SizedBox(height: 10),
                  _MiniTaskCard(
                    title: l10n.t('Séance de sport'),
                    time: '18:30',
                    color: AppColors.health,
                    completed: false,
                  ),
                  const SizedBox(height: 10),
                  _MiniTaskCard(
                    title: l10n.t('Lire 20 pages'),
                    time: '21:00',
                    color: AppColors.education,
                    completed: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniTaskCard extends StatelessWidget {
  const _MiniTaskCard({
    required this.title,
    required this.time,
    required this.color,
    required this.completed,
  });

  final String title;
  final String time;
  final Color color;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bolt_rounded, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: completed ? AppColors.muted : AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: completed
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: completed ? AppColors.dark : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: completed ? AppColors.dark : AppColors.divider,
                width: 1.3,
              ),
            ),
            child: completed
                ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                : null,
          ),
        ],
      ),
    );
  }
}

class _NotificationIllustration extends StatelessWidget {
  const _NotificationIllustration();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _IllustrationFrame(
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pastille blanche à la cloche.
              Container(
                width: 96,
                height: 96,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_active_rounded,
                  color: _accent,
                  size: 42,
                ),
              ),
              const SizedBox(height: 18),
              // Carte « rappel » : badge, libellés et interrupteur actif.
              Container(
                width: 300,
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.health.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.alarm_rounded,
                        color: AppColors.dark,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.t('Rappel de tâche'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n.t('Meeting with Shakib · 09:00'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Interrupteur actif (violet de la maquette).
                    Container(
                      width: 46,
                      height: 27,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 21,
                          height: 21,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
