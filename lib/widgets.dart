import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'firestore_service.dart';
import 'models.dart';

/// Centered icon + title + message, used for empty and error states.
class MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const MessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Avatar button in the app bar that shows who is signed in and lets them
/// log out.
class UserMenuButton extends StatelessWidget {
  final AppUser user;
  const UserMenuButton({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      tooltip: 'Account menu',
      icon: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Icon(Icons.person, color: scheme.onPrimaryContainer),
      ),
      onSelected: (value) {
        if (value == 'logout') FirebaseAuth.instance.signOut();
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text('${user.email}\n${user.roleLabel}'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Log out'),
          ),
        ),
      ],
    );
  }
}

/// Dropdown of every canvasser, plus an "Unassigned" choice.
class CanvasserDropdown extends StatefulWidget {
  final String? selectedUid;
  final ValueChanged<AppUser?> onChanged;

  const CanvasserDropdown({
    super.key,
    required this.selectedUid,
    required this.onChanged,
  });

  @override
  State<CanvasserDropdown> createState() => _CanvasserDropdownState();
}

class _CanvasserDropdownState extends State<CanvasserDropdown> {
  late final Stream<List<AppUser>> _stream = Db.canvassers();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppUser>>(
      stream: _stream,
      builder: (context, snap) {
        final canvassers = snap.data ?? const <AppUser>[];
        final value = canvassers.any((u) => u.uid == widget.selectedUid)
            ? widget.selectedUid
            : null;

        return DropdownButtonFormField<String?>(
          value: value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Assign to canvasser',
            prefixIcon: const Icon(Icons.person_outline),
            helperText: snap.hasData && canvassers.isEmpty
                ? 'No canvassers have signed up yet'
                : null,
          ),
          items: [
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Unassigned'),
            ),
            for (final u in canvassers)
              DropdownMenuItem<String?>(
                value: u.uid,
                child: Text(u.email, overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (uid) => widget.onChanged(
            uid == null ? null : canvassers.firstWhere((u) => u.uid == uid),
          ),
        );
      },
    );
  }
}
