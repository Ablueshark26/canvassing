import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'firestore_service.dart';
import 'map_widgets.dart';
import 'models.dart';
import 'widgets.dart';

/// Organizers tap the map to add numbered stops, then name, assign and save.
class RouteBuilderScreen extends StatefulWidget {
  const RouteBuilderScreen({super.key});

  @override
  State<RouteBuilderScreen> createState() => _RouteBuilderScreenState();
}

class _RouteBuilderScreenState extends State<RouteBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<LatLng> _stops = [];
  AppUser? _assignee;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _move(int index, int delta) {
    setState(() {
      final stop = _stops.removeAt(index);
      _stops.insert(index + delta, stop);
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_stops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap the map to add at least one stop')),
      );
      return;
    }

    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      await Db.createRoute(
        name: _nameController.text.trim(),
        stops: List.of(_stops),
        assignee: _assignee,
      );
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Route saved')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not save route: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New route')),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: kStartCenter,
              initialZoom: kStartZoom,
              onTap: (tapPosition, point) => setState(() => _stops.add(point)),
            ),
            children: [
              buildTileLayer(),
              if (_stops.length > 1) routeLine(_stops, scheme.primary),
              MarkerLayer(
                markers: [
                  for (var i = 0; i < _stops.length; i++)
                    Marker(
                      point: _stops[i],
                      width: 40,
                      height: 40,
                      child: NumberedPin(number: i + 1, color: scheme.primary),
                    ),
                ],
              ),
            ],
          ),
          const MapCredit(),
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.14,
            maxChildSize: 0.92,
            builder: (context, controller) => Material(
              elevation: 8,
              color: scheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
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
                    Text(
                      _stops.isEmpty
                          ? 'Tap the map to add stops'
                          : '${_stops.length} ${_stops.length == 1 ? 'stop' : 'stops'}',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Route name',
                        prefixIcon: Icon(Icons.route),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Please name this route'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    CanvasserDropdown(
                      selectedUid: _assignee?.uid,
                      onChanged: (u) => setState(() => _assignee = u),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _stops.length; i++)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: NumberedPin(
                          number: i + 1,
                          color: scheme.primary,
                          size: 32,
                        ),
                        title: Text('Stop ${i + 1}'),
                        subtitle: Text(
                          '${_stops[i].latitude.toStringAsFixed(5)}, '
                          '${_stops[i].longitude.toStringAsFixed(5)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Move up',
                              icon: const Icon(Icons.arrow_upward),
                              onPressed: i == 0 ? null : () => _move(i, -1),
                            ),
                            IconButton(
                              tooltip: 'Move down',
                              icon: const Icon(Icons.arrow_downward),
                              onPressed: i == _stops.length - 1
                                  ? null
                                  : () => _move(i, 1),
                            ),
                            IconButton(
                              tooltip: 'Remove stop',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () =>
                                  setState(() => _stops.removeAt(i)),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save route'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
