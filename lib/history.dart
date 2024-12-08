import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';

class ComplaintHistoryScreen extends StatefulWidget {
  final String userId;

  const ComplaintHistoryScreen({super.key, required this.userId});

  @override
  _ComplaintHistoryScreenState createState() => _ComplaintHistoryScreenState();
}

class _ComplaintHistoryScreenState extends State<ComplaintHistoryScreen> {
  String filterStatus = "All"; // Default filter
  String searchQuery = ""; // Default search query

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Complaint History"),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Complaints')
                  .where('user_id', isEqualTo: widget.userId)
                  .orderBy('submitted_at', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No complaints found."));
                }

                var complaints = snapshot.data!.docs.where((doc) {
                  final statusMatches =
                      filterStatus == "All" || doc['status'] == filterStatus;
                  final searchMatches = searchQuery.isEmpty ||
                      doc['complaint_type']
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase()) ||
                      doc['message']
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase());
                  return statusMatches && searchMatches;
                }).toList();

                if (complaints.isEmpty) {
                  return const Center(child: Text("No complaints match your filters."));
                }

                return ListView.builder(
                  itemCount: complaints.length,
                  itemBuilder: (context, index) {
                    final complaint = complaints[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                      child: ListTile(
                        leading: Icon(
                          _getIconForComplaintType(complaint['complaint_type']),
                          color: Colors.blue,
                        ),
                        title: Text(complaint['complaint_type']),
                        subtitle: Text(
                          "Status: ${complaint['status']}\nSubmitted: ${_formatRelativeTime(complaint['submitted_at'])}",
                        ),
                        isThreeLine: true,
                        trailing: const Icon(Icons.arrow_forward),
                        onTap: () {
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
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: "Search Complaints",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
          prefixIcon: const Icon(Icons.search),
        ),
        onChanged: (value) {
          setState(() {
            searchQuery = value;
          });
        },
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Filter Complaints"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterOption("All"),
              _buildFilterOption("Pending"),
              _buildFilterOption("Resolved"),
              _buildFilterOption("Rejected"),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String status) {
    return RadioListTile(
      value: status,
      groupValue: filterStatus,
      title: Text(status),
      onChanged: (value) {
        setState(() {
          filterStatus = value!;
        });
        Navigator.pop(context);
      },
    );
  }

  String _formatRelativeTime(Timestamp timestamp) {
    return timeago.format(timestamp.toDate());
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
        title: const Text("Complaint Details"),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('Complaints').doc(complaintId).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Complaint details not found."));
          }

          final complaint = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: ListView(
              children: [
                ListTile(
                  title: const Text("Complaint Type"),
                  subtitle: Text(complaint['complaint_type']),
                ),
                ListTile(
                  title: const Text("Message"),
                  subtitle: Text(complaint['message']),
                ),
                if (complaint['photo_url'] != null)
                  Image.network(complaint['photo_url']),
                if (complaint['video_url'] != null)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerScreen(videoUrl: complaint['video_url']),
                        ),
                      );
                    },
                    child: const Text("View Video"),
                  ),
                if (complaint['voice_url'] != null)
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AudioPlayerScreen(audioUrl: complaint['voice_url']),
                        ),
                      );
                    },
                    child: const Text("Play Audio"),
                  ),
                ListTile(
                  title: const Text("Location"),
                  subtitle: Text(
                    "Lat: ${complaint['location'].latitude}, Lng: ${complaint['location'].longitude}",
                  ),
                ),
                ListTile(
                  title: const Text("Status"),
                  subtitle: Text(complaint['status']),
                ),
                ListTile(
                  title: const Text("Submitted At"),
                  subtitle: Text(_formatRelativeTime(complaint['submitted_at'])),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatRelativeTime(Timestamp timestamp) {
    return timeago.format(timestamp.toDate());
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerScreen({super.key, required this.videoUrl});

  @override
  _VideoPlayerScreenState createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Video Player")),
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _controller.value.isPlaying ? _controller.pause() : _controller.play();
          });
        },
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
        ),
      ),
    );
  }
}

class AudioPlayerScreen extends StatefulWidget {
  final String audioUrl;

  const AudioPlayerScreen({super.key, required this.audioUrl});

  @override
  _AudioPlayerScreenState createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool isPlaying = false;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Audio Player")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPlaying ? Icons.pause_circle : Icons.play_circle,
              size: 100,
              color: Colors.blue,
            ),
            TextButton(
              onPressed: () async {
                if (isPlaying) {
                  await _audioPlayer.pause();
                } else {
                  await _audioPlayer.play(UrlSource(widget.audioUrl));
                }
                setState(() {
                  isPlaying = !isPlaying;
                });
              },
              child: Text(isPlaying ? "Pause Audio" : "Play Audio"),
            ),
          ],
        ),
      ),
    );
  }
}
