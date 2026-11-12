import 'package:flutter/material.dart';
import 'firebase_database_service.dart';

/// Example widgets demonstrating Firebase Realtime Database usage.
/// Copy/paste the relevant snippet into your own pages.

// ── Example 1: Write user data ──
Future<void> exampleWriteUser() async {
  await firebaseDbService.writeData(
    path: 'users/user_123',
    data: {
      'name': 'John Doe',
      'email': 'john@example.com',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    },
  );
}

// ── Example 2: Read user data once ──
Future<Map<String, dynamic>?> exampleReadUser() {
  return firebaseDbService.readData(path: 'users/user_123');
}

// ── Example 3: Real-time stream ──
Stream<Map<String, dynamic>?> exampleListenUser() {
  return firebaseDbService.listenToData(path: 'users/user_123');
}

// ── Example 4: Update fields ──
Future<void> exampleUpdateUser() async {
  await firebaseDbService.updateData(
    path: 'users/user_123',
    updates: {'status': 'online', 'lastSeen': DateTime.now().millisecondsSinceEpoch},
  );
}

// ── Example 5: Delete data ──
Future<void> exampleDeleteUser() async {
  await firebaseDbService.deleteData(path: 'users/user_123');
}

// ── Example 6: Push with auto-ID ──
Future<void> exampleCreatePost() async {
  await firebaseDbService.pushData(
    path: 'posts',
    data: {
      'title': 'My Post',
      'content': 'Hello!',
      'author': 'user_123',
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    },
  );
}

// ── Example 7: Batch write ──
Future<void> exampleBatchWrite() async {
  await firebaseDbService.batchWrite({
    'users/user_1': {'status': 'online'},
    'users/user_2': {'status': 'offline'},
  });
}

// ── Example 8: Connection status widget ──
class ConnectionStatusWidget extends StatelessWidget {
  const ConnectionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: firebaseDbService.checkConnectionStatus(),
      builder: (context, snapshot) {
        final connected = snapshot.data ?? false;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              connected ? Icons.cloud_done : Icons.cloud_off,
              color: connected ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              connected ? 'Connected' : 'Offline',
              style: TextStyle(
                color: connected ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}