import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'firestore_service.dart';
import 'map_widgets.dart';
import 'models.dart';
import 'stops_sheet.dart';
import 'widgets.dart';

/// Organizer's view of one route: stops colored by outcome, progress,
/// reassignment, and the survey answers collected at each stop.
class RouteDetailScreen extends StatefulWidget {
  final String routeId;
  const RouteDetailScreen({super.key, required this.routeId});

  @override
  State<RouteDetailScreen> createState() => _RouteDetailScreenState();
}

class _RouteDetailScreenState extends State<RouteDetailScreen> {
  late final Stream<CanvassRoute?> _routeStream =
      Db.routeStream(widget.routeId);
  late final Stream<Map<int, StopResult>> _resultsStream =
      Db.results(widget.routeId, onlyMine: false);

  void _showResult(int index, Map<int, StopResult> results) {
    final r = results[index];
    if (r == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Stop ${index + 1} has not been visited yet')),
      );
      return;
    }

    final lines = <String>[
      if (r.outcome == StopOutcome.completed) ...[
        'Name: ${r.name ?? '-'}',
        'Age: ${r.age ?? '-'}',
        'Plans to vote: ${r.plansToVote ?? '-'}',
        if ((r.notes ?? '').isNotEmpty) 'Additional information: ${r.notes}',
      ],
      'Collected by: ${r.canvasserEmail}',
    ];

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Stop ${index + 1} · ${outcomeLabel(r.outcome)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(line),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
              icon: Icons.error_outline,
              title: 'Could not load this route',
              message: '${routeSnap.error}',
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
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => _showResult(i, results),
                                child: NumberedPin(
                                  number: i + 1,
                                  color: statusColor(context, results[i]?.outcome),
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
                    onStopTap: (i) => _showResult(i, results),
                    header: [
                      CanvasserDropdown(
                        selectedUid: route.assignedTo,
                        onChanged: (u) => Db.assignRoute(route.id, u),
                      ),
                      const SizedBox(height: 8),
                    ],
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
