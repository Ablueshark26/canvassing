import 'package:flutter/material.dart';

import 'firestore_service.dart';
import 'models.dart';
import 'route_builder_screen.dart';
import 'route_detail_screen.dart';
import 'widgets.dart';

class OrganizerHome extends StatelessWidget {
  final AppUser user;
  const OrganizerHome({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Routes'),
        actions: [
          UserMenuButton(user: user),
          const SizedBox(width: 8),
        ],
      ),
      body: StreamBuilder<List<CanvassRoute>>(
        stream: Db.organizerRoutes(),
        builder: (context, snap) {
          if (snap.hasError) {
            return MessageView(
              icon: Icons.error_outline,
              title: 'Could not load routes',
              message: '${snap.error}',
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final routes = snap.data!;
          if (routes.isEmpty) {
            return const MessageView(
              icon: Icons.route,
              title: 'No routes yet',
              message:
                  'Tap "New route" to pick stops on the map and create your first route.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            itemCount: routes.length,
            itemBuilder: (context, i) {
              final r = routes[i];
              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.route)),
                  title: Text(r.name),
                  subtitle: Text(
                    '${r.stops.length} stops · ${r.assignedToEmail ?? 'Unassigned'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RouteDetailScreen(routeId: r.id),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RouteBuilderScreen()),
        ),
        icon: const Icon(Icons.add_location_alt),
        label: const Text('New route'),
      ),
    );
  }
}
