import 'package:flutter/material.dart';

import 'canvasser_route_screen.dart';
import 'firestore_service.dart';
import 'models.dart';
import 'widgets.dart';

class CanvasserHome extends StatefulWidget {
  final AppUser user;
  const CanvasserHome({super.key, required this.user});

  @override
  State<CanvasserHome> createState() => _CanvasserHomeState();
}

class _CanvasserHomeState extends State<CanvasserHome> {
  late final Stream<List<CanvassRoute>> _stream = Db.canvasserRoutes();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My routes'),
        actions: [
          UserMenuButton(user: widget.user),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<CanvassRoute>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return MessageView(
              icon: Icons.error_outline,
              title: 'Could not load your routes',
              message: '${snap.error}',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final routes = snap.data!;
          if (routes.isEmpty) {
            return const MessageView(
              icon: Icons.assignment_late_outlined,
              title: 'No routes assigned yet',
              message:
                  'Ask an organizer to assign you a route. It will show up here automatically.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: routes.length,
            itemBuilder: (context, i) {
              final r = routes[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.directions_walk)),
                  title: Text(r.name),
                  subtitle: Text('${r.stops.length} stops'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CanvasserRouteScreen(routeId: r.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
