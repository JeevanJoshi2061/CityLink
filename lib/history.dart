import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintHistoryScreen extends StatelessWidget {
  final String userId;

  const ComplaintHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Complaint History"),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Complaints')
            .where('user_id', isEqualTo: userId)
            .orderBy('submitted_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text("No complaints found."));
          }

          final complaints = snapshot.data!.docs;

          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                child: ListTile(
                  leading: Icon(
                    _getIconForComplaintType(complaint['complaint_type']),
                    color: Colors.blue,
                  ),
                  title: Text(complaint['complaint_type']),
                  subtitle: Text(
                    "Status: ${complaint['status']}\nSubmitted on: ${_formatTimestamp(complaint['submitted_at'])}",
                  ),
                  isThreeLine: true,
                  trailing: Icon(Icons.arrow_forward),
                  onTap: () {
                    // Navigate to Complaint Detail Screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ComplaintDetailScreen(
                          complaintId: complaint.id,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }

  IconData _getIconForComplaintType(String type) {
    switch (type) {
      case "Hospital":
        return Icons.local_hospital;
      case "Fire Department":
        return Icons.local_fire_department;
      case "Police":
        return Icons.local_police;
      case "Public Complaint":
        return Icons.people;
      default:
        return Icons.report_problem;
    }
  }
}

class ComplaintDetailScreen extends StatelessWidget {
  final String complaintId;

  const ComplaintDetailScreen({super.key, required this.complaintId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Complaint Details"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Complaints').doc(complaintId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text("Complaint details not found."));
          }

          final complaint = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView(
              children: [
                ListTile(
                  title: Text("Complaint Type"),
                  subtitle: Text(complaint['complaint_type']),
                ),
                ListTile(
                  title: Text("Message"),
                  subtitle: Text(complaint['message']),
                ),
                if (complaint['photo_url'] != null) Image.network(complaint['photo_url']),
                if (complaint['video_url'] != null)
                  TextButton(
                    onPressed: () {
                      // Open video
                    },
                    child: Text("View Video"),
                  ),
                if (complaint['voice_url'] != null)
                  TextButton(
                    onPressed: () {
                      // Play audio
                    },
                    child: Text("Play Audio"),
                  ),
                ListTile(
                  title: Text("Location"),
                  subtitle: Text(
                    "Lat: ${complaint['location'].latitude}, Lng: ${complaint['location'].longitude}",
                  ),
                ),
                ListTile(
                  title: Text("Status"),
                  subtitle: Text(complaint['status']),
                ),
                ListTile(
                  title: Text("Submitted At"),
                  subtitle: Text(_formatTimestamp(complaint['submitted_at'])),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return "${date.day}/${date.month}/${date.year}";
  }
}
