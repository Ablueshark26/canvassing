import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import 'models.dart';

/// True while the login screen is creating a brand-new account and its
/// profile. The app waits instead of briefly showing the role picker.
final ValueNotifier<bool> signUpInProgress = ValueNotifier<bool>(false);

/// All database reads and writes live here, so screens stay simple.
class Db {
  Db._();

  static FirebaseFirestore get _db => FirebaseFirestore.instance;
  static User get _user => FirebaseAuth.instance.currentUser!;

  // ---- Users --------------------------------------------------------------

  static Stream<DocumentSnapshot<Map<String, dynamic>>> profileStream(
          String uid) =>
      _db.collection('users').doc(uid).snapshots();

  static Future<void> createProfile(UserRole role) {
    return _db.collection('users').doc(_user.uid).set({
      'email': _user.email,
      'role': role.name, // 'organizer' or 'canvasser'
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Stream<List<AppUser>> canvassers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'canvasser')
        .snapshots()
        .map((s) => s.docs.map(AppUser.fromDoc).toList());
  }

  // ---- Routes -------------------------------------------------------------

  static Stream<List<CanvassRoute>> organizerRoutes() {
    return _db
        .collection('routes')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map(CanvassRoute.fromDoc).toList());
  }

  static Stream<List<CanvassRoute>> canvasserRoutes() {
    return _db
        .collection('routes')
        .where('assignedTo', isEqualTo: _user.uid)
        .snapshots()
        .map((s) {
      final list = s.docs.map(CanvassRoute.fromDoc).toList();
      list.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return list;
    });
  }

  static Stream<CanvassRoute?> routeStream(String id) {
    return _db
        .collection('routes')
        .doc(id)
        .snapshots()
        .map((d) => d.exists ? CanvassRoute.fromDoc(d) : null);
  }

  static Future<void> createRoute({
    required String name,
    required List<LatLng> stops,
    AppUser? assignee,
  }) {
    return _db.collection('routes').add({
      'name': name,
      'createdBy': _user.uid,
      'assignedTo': assignee?.uid,
      'assignedToEmail': assignee?.email,
      'stops': [
        for (final s in stops) {'lat': s.latitude, 'lng': s.longitude},
      ],
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> assignRoute(String routeId, AppUser? assignee) {
    return _db.collection('routes').doc(routeId).update({
      'assignedTo': assignee?.uid,
      'assignedToEmail': assignee?.email,
    });
  }

  // ---- Results (survey answers and not-home / declined outcomes) ----------

  /// Results for one route, keyed by stop index. Canvassers pass
  /// onlyMine: true, because the security rules only let them read their own.
  static Stream<Map<int, StopResult>> results(
    String routeId, {
    required bool onlyMine,
  }) {
    Query<Map<String, dynamic>> q =
        _db.collection('responses').where('routeId', isEqualTo: routeId);
    if (onlyMine) {
      q = q.where('canvasserId', isEqualTo: _user.uid);
    }
    return q.snapshots().map((s) {
      final map = <int, StopResult>{};
      for (final d in s.docs) {
        final r = StopResult.fromDoc(d);
        map[r.stopIndex] = r;
      }
      return map;
    });
  }

  /// One document per stop, so saving again simply replaces the old result.
  static Future<void> saveResult({
    required CanvassRoute route,
    required int stopIndex,
    required StopOutcome outcome,
    SurveyAnswers? answers,
  }) {
    final stop = route.stops[stopIndex];
    return _db.collection('responses').doc('${route.id}_$stopIndex').set({
      'routeId': route.id,
      'stopIndex': stopIndex,
      'canvasserId': _user.uid,
      'canvasserEmail': _user.email,
      'outcome': outcome.name,
      'name': answers?.name,
      'age': answers?.age,
      'plansToVote': answers?.plansToVote,
      'notes': answers?.notes,
      'lat': stop.latitude,
      'lng': stop.longitude,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
