import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/daily_course_service.dart';
import '../theme/studio_visuals.dart';

/// Keeps course controls visible while a game opens its own play routes.
/// Only the completed stage result leaves this navigator and reaches the
/// competition coordinator, which saves it before opening the next game.
class CompetitionStagePage extends StatefulWidget {
  const CompetitionStagePage({
    super.key,
    required this.gameId,
    required this.gameName,
    required this.stageNumber,
    required this.stageCount,
    required this.gameBuilder,
  });

  final String gameId;
  final String gameName;
  final int stageNumber;
  final int stageCount;
  final WidgetBuilder gameBuilder;

  @override
  State<CompetitionStagePage> createState() => _CompetitionStagePageState();
}

class _CompetitionStagePageState extends State<CompetitionStagePage> {
  int _attempt = 0;
  bool _resolved = false;
  bool _showingExit = false;
  Future<String?>? _exitDialog;

  void _resolve(Object? result) {
    if (_resolved || !mounted) return;
    if (result == null ||
        (result is DailyStageResult &&
            result.outcome == DailyStageOutcome.exited)) {
      _showExit(restartOnReturn: true);
      return;
    }
    unawaited(_finishStage(result));
  }

  Future<void> _finishStage(Object? result) async {
    if (_resolved || !mounted) return;
    _resolved = true;
    // Timed games may resolve while the exit sheet is open. Close the sheet
    // with its own result type before returning the game result to the race.
    final Future<String?>? exitDialog = _exitDialog;
    if (exitDialog != null) {
      Navigator.of(context).pop<String>('completed');
      await exitDialog;
    }
    if (mounted) Navigator.of(context).pop(result);
  }

  void _skip() => _resolve(DailyStageResult.skipped(gameId: widget.gameId));

  Future<void> _showExit({bool restartOnReturn = false}) async {
    if (_resolved || _showingExit || !mounted) return;
    setState(() => _showingExit = true);
    final bool english = context.l10n.isEnglish;
    final Future<String?> exitDialog = showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: StudioVisuals.surface,
      builder: (BuildContext sheetContext) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Icon(
                Icons.save_alt_rounded,
                color: StudioVisuals.teal,
                size: 36,
              ),
              const SizedBox(height: 12),
              Text(
                english
                    ? 'LEAVE THE GROUP COURSE?'
                    : 'GRUP PARKURUNDAN ÇIKILSIN MI?',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                english
                    ? '${widget.gameName} is not finished. Your course progress will be saved.'
                    : '${widget.gameName} henüz tamamlanmadı. Parkurdaki ilerlemen korunacak.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                key: const ValueKey<String>('competition_return_to_game'),
                onPressed: () => Navigator.pop(sheetContext, 'continue'),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(english ? 'RETURN TO GAME' : 'OYUNA DÖN'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const ValueKey<String>('competition_exit_skip'),
                onPressed: () => Navigator.pop(sheetContext, 'skip'),
                icon: const Icon(Icons.skip_next_rounded),
                label: Text(english ? 'SKIP THIS SECTION' : 'BU BÖLÜMÜ GEÇ'),
              ),
              const SizedBox(height: 4),
              Text(
                english
                    ? 'Skipping records 0 stars and 0 points.'
                    : 'Geçilen bölüm 0 yıldız ve 0 puanla kaydedilir.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: StudioVisuals.muted,
                  fontSize: 11,
                ),
              ),
              TextButton.icon(
                key: const ValueKey<String>('competition_leave_course'),
                onPressed: () => Navigator.pop(sheetContext, 'leave'),
                icon: const Icon(Icons.exit_to_app_rounded),
                label: Text(english ? 'LEAVE THE COURSE' : 'PARKURDAN ÇIK'),
              ),
            ],
          ),
        ),
      ),
    );
    _exitDialog = exitDialog;
    final String? decision = await exitDialog;
    _exitDialog = null;
    _showingExit = false;
    if (!mounted || _resolved) return;
    setState(() {});
    if (decision == 'skip') {
      _skip();
    } else if (decision == 'leave') {
      // Distinguish an explicit leave from a game's back button so the
      // coordinator does not ask the same exit question for a second time.
      unawaited(_finishStage(CompetitionStageAction.leave));
    } else if (restartOnReturn) {
      // A game's own back button may already have closed its inner play
      // route. Reopen the identical level/layout when returning from that.
      setState(() => _attempt++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool english = context.l10n.isEnglish;
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && !_resolved) _showExit();
      },
      child: Scaffold(
        backgroundColor: StudioVisuals.canvas,
        body: TickerMode(
          enabled: !_showingExit,
          child: Navigator(
            key: ValueKey<int>(_attempt),
            onGenerateRoute: (RouteSettings settings) =>
                _CompetitionGameRootRoute(
                  settings: settings,
                  builder: widget.gameBuilder,
                  onResult: _resolve,
                ),
          ),
        ),
        bottomNavigationBar: Material(
          color: StudioVisuals.surface,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '${english ? 'GROUP COURSE' : 'GRUP PARKURU'} · ${widget.stageNumber}/${widget.stageCount}',
                    style: const TextStyle(
                      color: StudioVisuals.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: <Widget>[
                      IconButton(
                        key: const ValueKey<String>(
                          'competition_restart_stage',
                        ),
                        tooltip: english
                            ? 'Restart section'
                            : 'Bölümü baştan oyna',
                        onPressed: () => setState(() => _attempt++),
                        icon: const Icon(Icons.restart_alt_rounded),
                        color: StudioVisuals.teal,
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const ValueKey<String>('competition_skip_stage'),
                          onPressed: _skip,
                          icon: const Icon(Icons.skip_next_rounded),
                          label: Text(
                            english ? 'SKIP SECTION' : 'BÖLÜMÜ GEÇ',
                            textAlign: TextAlign.center,
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: StudioVisuals.teal,
                          ),
                        ),
                      ),
                      IconButton(
                        key: const ValueKey<String>('competition_exit_stage'),
                        tooltip: english ? 'Leave course' : 'Parkurdan çık',
                        onPressed: () => _showExit(),
                        icon: const Icon(Icons.exit_to_app_rounded),
                        color: StudioVisuals.muted,
                      ),
                    ],
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

enum CompetitionStageAction { leave }

// A game's explicit Navigator.pop bypasses PopScope.canPop. Consume that
// result without removing the nested navigator's last route, then forward it
// after Navigator releases its history lock.
class _CompetitionGameRootRoute extends MaterialPageRoute<Object?> {
  _CompetitionGameRootRoute({
    required super.settings,
    required super.builder,
    required this.onResult,
  });

  final ValueChanged<Object?> onResult;

  @override
  bool didPop(Object? result) {
    // Local history consumes the pop through the framework's normal route
    // implementation, keeping this navigator's last route mounted.
    addLocalHistoryEntry(LocalHistoryEntry(onRemove: () {}));
    final bool didRemoveRoute = super.didPop(result);
    scheduleMicrotask(() => onResult(result));
    return didRemoveRoute;
  }
}
