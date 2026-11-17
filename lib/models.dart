import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

enum UserRole { organizer, canvasser }

/// What happened when a canvasser visited a stop.
enum StopOutcome { completed, notHome, declined }

String outcomeLabel(StopOutcome? outcome) {
  if (outcome == null) return 'Not visited yet';
  if (outcome == StopOutcome.completed) return 'Survey completed';
  if (outcome == StopOutcome.notHome) return 'Not home';
  return 'Declined';
}

// ---------------------------------------------------------------------------
// users/{uid}
// ---------------------------------------------------------------------------

class AppUser {
  final String uid;
  final String email;
  final UserRole role;

  const AppUser({required this.uid, required this.email, required this.role});

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      uid: doc.id,
      email: (d['email'] as String?) ?? '',
      role: d['role'] == 'organizer' ? UserRole.organizer : UserRole.canvasser,
    );
  }

  String get roleLabel =>
      role == UserRole.organizer ? 'Organizer' : 'Canvasser';
}

// ---------------------------------------------------------------------------
// routes/{routeId}  (stops are stored inside the route document)
// ---------------------------------------------------------------------------

class CanvassRoute {
  final String id;
  final String name;
  final String? assignedTo; // canvasser uid
  final String? assignedToEmail;
  final List<LatLng> stops;

  const CanvassRoute({
    required this.id,
    required this.name,
    required this.assignedTo,
    required this.assignedToEmail,
    required this.stops,
  });

  factory CanvassRoute.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawStops = (d['stops'] as List<dynamic>?) ?? [];
    return CanvassRoute(
      id: doc.id,
      name: (d['name'] as String?) ?? 'Untitled route',
      assignedTo: d['assignedTo'] as String?,
      assignedToEmail: d['assignedToEmail'] as String?,
      stops: [
        for (final s in rawStops)
          LatLng((s['lat'] as num).toDouble(), (s['lng'] as num).toDouble()),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// responses/{routeId}_{stopIndex}  (one result per stop)
// ---------------------------------------------------------------------------

class StopResult {
  final int stopIndex;
  final StopOutcome outcome;
  final String? name;
  final int? age;
  final String? plansToVote;
  final String? notes;
  final String canvasserEmail;

  const StopResult({
    required this.stopIndex,
    required this.outcome,
    required this.name,
    required this.age,
    required this.plansToVote,
    required this.notes,
    required this.canvasserEmail,
  });

  factory StopResult.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return StopResult(
      stopIndex: (d['stopIndex'] as num).toInt(),
      outcome: StopOutcome.values.firstWhere(
        (o) => o.name == d['outcome'],
        orElse: () => StopOutcome.completed,
      ),
      name: d['name'] as String?,
      age: (d['age'] as num?)?.toInt(),
      plansToVote: d['plansToVote'] as String?,
      notes: d['notes'] as String?,
      canvasserEmail: (d['canvasserEmail'] as String?) ?? '',
    );
  }
}

/// What the canvasser types into the survey form.
class SurveyAnswers {
  final String name;
  final int age;
  final String plansToVote; // Yes / No / Undecided
  final String notes;

  const SurveyAnswers({
    required this.name,
    required this.age,
    required this.plansToVote,
    required this.notes,
  });
}
