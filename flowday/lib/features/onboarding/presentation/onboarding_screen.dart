import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../shared/widgets/flowday_logo.dart';
import '../../../shared/widgets/wave_painter.dart';

/// Premier lancement de Flowday : présentation de l'application en trois
/// pages illustrées. L'achèvement est mémorisé par [OnboardingProvider] ;
/// l'écran n'est donc affiché qu'une seule fois.
///
/// L'autorisation des notifications n'est **pas** demandée ici : elle est
/// proposée nativement par le système après la connexion à un compte.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pageCount = 3;

  final PageController _pages = PageController();
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  bool get _isLastPage => _page == _pageCount - 1;

  void _next() {
    if (_isLastPage) return;
    HapticFeedback.selectionClick();
    _pages.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    HapticFeedback.lightImpact();
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
            // Marque + passage direct à la fin.
            // ----------------------------------------------------------
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 14, 0),
              child: Row(
                children: [
                  const FlowdayLogo(size: 34),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Flowday',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'DancingScript',
                        fontVariations: const [FontVariation('wght', 700)],
                        fontWeight: FontWeight.w700,
                        fontSize: 25,
                        color: isDark ? foreground : AppColors.dark,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!_isLastPage)
                    TextButton(
                      onPressed: _finishing ? null : _finish,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < pages.length; index++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: index == _page ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: index == _page
                                ? foreground
                                : foreground.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      key: const Key('onboarding-next'),
                      onPressed: _finishing
                          ? null
                          : (_isLastPage ? _finish : _next),
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              l10n.t(_isLastPage ? 'Commencer' : 'Suivant'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            _isLastPage
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 430,
                  maxHeight: 360,
                ),
                child: AspectRatio(aspectRatio: 1.14, child: data.illustration),
              ),
            ),
          ),
          const SizedBox(height: 26),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: foreground,
              fontSize: 28,
              height: 1.15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.7,
            ),
          ),
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Text(
              data.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 14.5, height: 1.5),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Cadre sombre commun aux illustrations (mêmes vagues que l'en-tête).
class _IllustrationFrame extends StatelessWidget {
  const _IllustrationFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.dark,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: CustomPaint(painter: WavePainter())),
          Positioned.fill(child: child),
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
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
              color: Colors.white,
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
                    color: Colors.black.withValues(alpha: 0.22),
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
            color: Colors.black.withValues(alpha: 0.18),
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
