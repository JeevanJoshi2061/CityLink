import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // Function to fetch notifications stream
  Stream<QuerySnapshot> _fetchNotifications(String userId) {
    return FirebaseFirestore.instance
        .collection('Notifications')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(20) // Fetch notifications in batches (optional for pagination)
        .snapshots();
  }

  // Function to mark all notifications as read
  Future<void> _markAllAsRead(String userId) async {
    try {
      final notifications = await FirebaseFirestore.instance
          .collection('Notifications')
          .where('user_id', isEqualTo: userId)
          .get();

      for (var notification in notifications.docs) {
        await notification.reference.update({'read_status': true});
      }
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Notifications")),
        body: const Center(
          child: Text("No user logged in."),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          TextButton(
            onPressed: () => _markAllAsRead(userId),
            child: const Text(
              "Mark All Read",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchNotifications(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text("Error fetching notifications."),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No notifications available."),
            );
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return NotificationCard(
                title: notification['title'],
                message: notification['message'],
                isRead: notification['read_status'],
                createdAt: (notification['created_at'] as Timestamp).toDate(),
                onMarkAsRead: () async {
                  await FirebaseFirestore.instance
                      .collection('Notifications')
                      .doc(notification.id)
                      .update({'read_status': true});
                },
              );
            },
          );
        },
      ),
    );
  }
}

class NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final VoidCallback onMarkAsRead;

  const NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(10.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRead ? Colors.grey : Colors.blue,
          child: Icon(
            isRead ? Icons.notifications : Icons.notifications_active,
            color: Colors.white,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            const SizedBox(height: 5),
            Text(
              "${createdAt.day}/${createdAt.month}/${createdAt.year} ${createdAt.hour}:${createdAt.minute}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: isRead
            ? const Icon(Icons.check, color: Colors.green)
            : TextButton(
                onPressed: onMarkAsRead,
                child: const Text(
                  'Mark as Read',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
      ),
    );
  }
}
