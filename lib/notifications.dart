import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationsScreen extends StatelessWidget {
  final String userId;

  const NotificationsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Notifications"),
        actions: [
          TextButton(
            onPressed: () async {
              // Mark all notifications as read
              final notifications = await FirebaseFirestore.instance
                  .collection('Notifications')
                  .where('user_id', isEqualTo: userId)
                  .get();

              for (var notification in notifications.docs) {
                notification.reference.update({'read_status': true});
              }
            },
            child: Text(
              "Mark All Read",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Notifications')
            .where('user_id', isEqualTo: userId)
            .orderBy('created_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No notifications available."));
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
  final VoidCallback onMarkAsRead;

  const NotificationCard({super.key, 
    required this.title,
    required this.message,
    required this.isRead,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(10.0),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
        ),
        subtitle: Text(message),
        trailing: isRead
            ? Icon(Icons.check, color: Colors.green)
            : TextButton(
                onPressed: onMarkAsRead,
                child: Text('Mark as Read'),
              ),
      ),
    );
  }
}
