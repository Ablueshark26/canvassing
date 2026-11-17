import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'firestore_service.dart';
import 'map_widgets.dart';
import 'models.dart';
import 'stops_sheet.dart';
import 'survey_form.dart';
import 'widgets.dart';

/// A canvasser works through an assigned route: tap a stop, then fill out
/// the survey or mark the door as "not home" or "declined".
class CanvasserRouteScreen extends StatefulWidget {
  final String routeId;
  const CanvasserRouteScreen({super.key, required this.routeId});

  @override
  State<CanvasserRouteScreen> createState() => _CanvasserRouteScreenState();
}

class _CanvasserRouteScreenState extends State<CanvasserRouteScreen> {
  late final Stream<CanvassRoute?> _routeStream =
      Db.routeStream(widget.routeId);
  late final Stream<Map<int, StopResult>> _resultsStream =
      Db.results(widget.routeId, onlyMine: true);

  Future<void> _openStop(
    CanvassRoute route,
    Map<int, StopResult> results,
    int index,
  ) async {
    final existing = results[index];

    final action = await showModalBottomSheet<StopOutcome>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      constraints: const BoxConstraints(maxWidth: 560),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Stop ${index + 1}',
                style: Theme.of(sheetContext).textTheme.headlineSmall,
              ),
              if (existing != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Already recorded: ${outcomeLabel(existing.outcome)}. '
                    'Saving again replaces it.',
                  ),
                ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.pop(sheetContext, StopOutcome.completed),
                icon: const Icon(Icons.assignment),
                label: const Text('Start survey'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () =>
                    Navigator.pop(sheetContext, StopOutcome.notHome),
                icon: const Icon(Icons.door_front_door_outlined),
                label: const Text('Not home'),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () =>
                    Navigator.pop(sheetContext, StopOutcome.declined),
                icon: const Icon(Icons.block),
                label: const Text('Declined'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;

    if (action == StopOutcome.completed) {
      final answers = await showModalBottomSheet<SurveyAnswers>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        constraints: const BoxConstraints(maxWidth: 560),
        builder: (_) => SurveyForm(stopNumber: index + 1),
      );
      if (!mounted || answers == null) return;
      await _save(route, index, StopOutcome.completed, answers);
    } else {
      await _save(route, index, action, null);
    }
  }

  Future<void> _save(
    CanvassRoute route,
    int index,
    StopOutcome outcome,
    SurveyAnswers? answers,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Db.saveResult(
        route: route,
        stopIndex: index,
        outcome: outcome,
        answers: answers,
      );
      messenger.showSnackBar(
        SnackBar(content: Text('Stop ${index + 1} saved')),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Could not save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<CanvassRoute?>(
      stream: _routeStream,
      builder: (context, routeSnap) {
        if (routeSnap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: MessageView(
              icon: Icons.lock_outline,
              title: 'Route unavailable',
              message:
                  'You may no longer be assigned to this route.\n\n${routeSnap.error}',
            ),
          );
        }
        if (routeSnap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final route = routeSnap.data;
        if (route == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const MessageView(
              icon: Icons.search_off,
              title: 'Route not found',
              message: 'This route may have been deleted.',
            ),
          );
        }

        return StreamBuilder<Map<int, StopResult>>(
          stream: _resultsStream,
          builder: (context, resSnap) {
            final results = resSnap.data ?? const <int, StopResult>{};

            return Scaffold(
              appBar: AppBar(title: Text(route.name)),
              body: Stack(
                children: [
                  FlutterMap(
                    options: routeMapOptions(route.stops),
                    children: [
                      buildTileLayer(),
                      if (route.stops.length > 1)
                        routeLine(route.stops, scheme.primary),
                      MarkerLayer(
                        markers: [
                          for (var i = 0; i < route.stops.length; i++)
                            Marker(
                              point: route.stops[i],
                              width: 44,
                              height: 44,
                              child: GestureDetector(
                                onTap: () => _openStop(route, results, i),
                                child: NumberedPin(
                                  number: i + 1,
                                  color: statusColor(context, results[i]?.outcome),
                                  size: 44,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const MapCredit(),
                  StopsSheet(
                    route: route,
                    results: results,
                    onStopTap: (i) => _openStop(route, results, i),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
