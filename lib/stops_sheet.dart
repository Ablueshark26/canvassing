import 'package:flutter/material.dart';

import 'map_widgets.dart';
import 'models.dart';

/// Draggable bottom sheet showing progress and every stop on a route.
/// Used by both the organizer's route detail and the canvasser's route screen.
class StopsSheet extends StatelessWidget {
  final CanvassRoute route;
  final Map<int, StopResult> results;
  final void Function(int index) onStopTap;

  /// Extra widgets shown above the stop list (e.g. the assign dropdown).
  final List<Widget> header;

  const StopsSheet({
    super.key,
    required this.route,
    required this.results,
    required this.onStopTap,
    this.header = const [],
  });

  String _subtitle(StopResult? r) {
    if (r == null) return outcomeLabel(null);
    if (r.outcome == StopOutcome.completed && (r.name ?? '').isNotEmpty) {
      return 'Survey completed · ${r.name}';
    }
    return outcomeLabel(r.outcome);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final total = route.stops.length;
    final visited = results.keys.where((i) => i < total).length;

    return DraggableScrollableSheet(
      initialChildSize: 0.34,
      minChildSize: 0.14,
      maxChildSize: 0.9,
      builder: (context, controller) => Material(
        elevation: 8,
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: ListView(
          controller: controller,
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$visited of $total stops visited',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: total == 0 ? 0 : visited / total,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...header,
                ],
              ),
            ),
            for (var i = 0; i < total; i++)
              ListTile(
                leading: NumberedPin(
                  number: i + 1,
                  color: statusColor(context, results[i]?.outcome),
                  size: 34,
                ),
                title: Text('Stop ${i + 1}'),
                subtitle: Text(_subtitle(results[i])),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => onStopTap(i),
              ),
          ],
        ),
      ),
    );
  }
}
