import 'package:firebase_database/firebase_database.dart';

/// Singleton service for Firebase Realtime Database operations.
class FirebaseDatabaseService {
  FirebaseDatabaseService._();
  static final FirebaseDatabaseService _instance = FirebaseDatabaseService._();
  static FirebaseDatabaseService get instance => _instance;

  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  /// Write data at [path] with [data].
  Future<void> writeData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    await _db.child(path).set(data);
  }

  /// Read data at [path] once.
  Future<Map<String, dynamic>?> readData({required String path}) async {
    final snapshot = await _db.child(path).get();
    if (snapshot.exists && snapshot.value is Map) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    }
    return null;
  }

  /// Listen to real-time changes at [path].
  Stream<Map<String, dynamic>?> listenToData({required String path}) {
    return _db.child(path).onValue.map((event) {
      if (event.snapshot.exists && event.snapshot.value is Map) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return null;
    });
  }

  /// Update specific fields at [path].
  Future<void> updateData({
    required String path,
    required Map<String, dynamic> updates,
  }) async {
    await _db.child(path).update(updates);
  }

  /// Delete data at [path].
  Future<void> deleteData({required String path}) async {
    await _db.child(path).remove();
  }

  /// Push data with auto-generated key at [path].
  Future<String> pushData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final ref = await _db.child(path).push();
    await ref.set(data);
    return ref.key!;
  }

  /// Check connection status stream.
  Stream<bool> checkConnectionStatus() {
    return _db.child('.info/connected').onValue.map((event) {
      return event.snapshot.value as bool? ?? false;
    });
  }

  /// Batch write multiple paths at once.
  Future<void> batchWrite(Map<String, Map<String, dynamic>> updates) async {
    final batch = <String, Map<String, dynamic>>{};
    for (final entry in updates.entries) {
      batch[entry.key] = entry.value;
    }
    await _db.update(batch);
  }
}

/// Convenience top-level reference.
final FirebaseDatabaseService firebaseDbService =
    FirebaseDatabaseService.instance;