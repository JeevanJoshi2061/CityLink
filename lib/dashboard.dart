import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _userId;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('No user logged in. Redirecting to login screen.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      _userId = user.uid;

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(_userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data() as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        _showSnackBar('User data not found. Redirecting to User Details.');
        Navigator.pushReplacementNamed(context, '/user_detail', arguments: {
          'userId': _userId,
          'phoneNumber': user.phoneNumber,
        });
      }
    } catch (e) {
      _showSnackBar('Error fetching user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.logout),
          //   onPressed: () async {
          //     await FirebaseAuth.instance.signOut();
          //     Navigator.pushReplacementNamed(context, '/login');
          //   },
          // ),
        ],
      ),
      body: _userData == null
          ? Center(
              child: ElevatedButton(
                onPressed: _fetchUserData,
                child: const Text('Retry'),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Welcome to your Dashboard!',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      children: [
                        _buildDashboardItem(
                          title: 'Complaint Box',
                          icon: Icons.report_problem,
                          onTap: () {
                            Navigator.pushNamed(context, '/complaint_box');
                          },
                        ),
_buildDashboardItem(
  title: 'Notifications',
  icon: Icons.notifications,
  onTap: () {
    Navigator.pushNamed(context, '/notifications');
  },
),

                        _buildDashboardItem(
                          title: 'Profile',
                          icon: Icons.person,
                          onTap: () {
                            Navigator.pushNamed(context, '/profile', arguments: _userData);
                          },
                        ),
_buildDashboardItem(
  title: 'News Feed',
  icon: Icons.feed,
  onTap: () {
    // Pass the necessary arguments to the NewsFeedScreen
Navigator.pushNamed(
  context,
  '/news_feed',
  arguments: {
    'municipalityId': _userData?['mun1'] ?? '', // Ensure this is a String
    'languagePreference': _userData?['language_preference'] ?? 'English', // Ensure this is a String
  },
);

  },
),

                        // _buildDashboardItem(
                        //   title: 'Chat',
                        //   icon: Icons.chat,
                        //   onTap: () {
                        //     Navigator.pushNamed(context, '/chat');
                        //   },
                        // ),
                        _buildDashboardItem(
                          title: 'History',
                          icon: Icons.history,
                          onTap: () {
                            Navigator.pushNamed(context, '/history');
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDashboardItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
