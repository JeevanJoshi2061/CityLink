import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'package:cloudinary/cloudinary.dart';

// Initialize Cloudinary
const String cloudName = "dtlmvwa2q";
const String uploadPreset = "unsigned-preset";
final cloudinary = Cloudinary.unsignedConfig(cloudName: cloudName);

// Helper function to map resource types
CloudinaryResourceType? getResourceType(String resourceType) {
  switch (resourceType) {
    case "image":
      return CloudinaryResourceType.image;
    case "video":
      return CloudinaryResourceType.video;
    case "raw":
      return CloudinaryResourceType.raw; // For audio or other files
    default:
      return null; // Invalid type
  }
}

class ComplaintBoxScreen extends StatefulWidget {
  const ComplaintBoxScreen({super.key});

  @override
  _ComplaintBoxScreenState createState() => _ComplaintBoxScreenState();
}

class _ComplaintBoxScreenState extends State<ComplaintBoxScreen> {
  String selectedType = "Hospital"; // Default complaint type
  TextEditingController messageController = TextEditingController();
  File? selectedImage;
  File? selectedVideo;
  File? selectedVoice;
  GeoPoint? userLocation;
  bool isRecording = false;
  bool isSubmitting = false; // Track submission status
  late FlutterSoundRecorder _recorder;

  @override
  void initState() {
    super.initState();
    _fetchLocation();
    _initializeRecorder();
  }

  Future<void> _fetchLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception("Location permission denied");
      }
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        userLocation = GeoPoint(position.latitude, position.longitude);
      });
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  Future<void> _initializeRecorder() async {
    _recorder = FlutterSoundRecorder();
    await _recorder.openRecorder();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedImage = await ImagePicker().pickImage(source: source);
    if (pickedImage != null) {
      setState(() {
        selectedImage = File(pickedImage.path);
      });
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    final pickedVideo = await ImagePicker().pickVideo(source: source);
    if (pickedVideo != null) {
      setState(() {
        selectedVideo = File(pickedVideo.path);
      });
    }
  }

  Future<void> _startRecording() async {
    Directory tempDir = await getTemporaryDirectory();
    String path = "${tempDir.path}/voice_note.aac";
    var status = await Permission.microphone.request();
    if (status.isGranted) {
      try {
        setState(() {
          isRecording = true;
        });
        await _recorder.startRecorder(toFile: path);
      } catch (e) {
        print("Error starting recorder: $e");
      }
    } else {
      print("Microphone permission denied");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Microphone permission is required to record audio")),
      );
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? path = await _recorder.stopRecorder();
      setState(() {
        isRecording = false;
        if (path != null) {
          selectedVoice = File(path);
        }
      });
    } catch (e) {
      print("Error stopping recorder: $e");
    }
  }

  Future<String?> _uploadToCloudinary(File file, String resourceType) async {
    try {
      final cloudinaryType = getResourceType(resourceType);
      if (cloudinaryType == null) {
        throw Exception("Invalid resource type: $resourceType");
      }

      final response = await cloudinary.unsignedUpload(
        file: file.path,
        uploadPreset: uploadPreset,
        resourceType: cloudinaryType,
      );

      if (response.isSuccessful && response.secureUrl != null) {
        return response.secureUrl;
      } else {
        print("Error uploading to Cloudinary: ${response.error}");
        return null;
      }
    } catch (e) {
      print("Error uploading file: $e");
      return null;
    }
  }

  void submitComplaint() async {
    if (messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Message field cannot be empty")));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not logged in")));
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    List<Future<String?>> uploadFutures = [];

    if (selectedImage != null) {
      uploadFutures.add(_uploadToCloudinary(selectedImage!, "image"));
    }
    if (selectedVideo != null) {
      uploadFutures.add(_uploadToCloudinary(selectedVideo!, "video"));
    }
    if (selectedVoice != null) {
      uploadFutures.add(_uploadToCloudinary(selectedVoice!, "raw"));
    }

    try {
      final results = await Future.wait(uploadFutures);
      final photoUrl = results.isNotEmpty ? results[0] : null;
      final videoUrl = results.length > 1 ? results[1] : null;
      final voiceUrl = results.length > 2 ? results[2] : null;

      final complaint = {
        "user_id": user.uid,
        "municipality_id": "mun123",
        "complaint_type": selectedType,
        "message": messageController.text.trim(),
        "photo_url": photoUrl,
        "video_url": videoUrl,
        "voice_url": voiceUrl,
        "location": userLocation ?? GeoPoint(0, 0),
        "status": "Pending",
        "priority": 1,
        "submitted_at": Timestamp.now(),
        "updated_at": Timestamp.now(),
      };

      await FirebaseFirestore.instance.collection('Complaints').add(complaint);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Complaint Submitted Successfully')));
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Complaint Box')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: selectedType,
                items: ["Hospital", "Fire Department", "Police", "Public Complaint"]
                    .map((type) =>
                    DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => setState(() => selectedType = value!),
                decoration: InputDecoration(labelText: "Complaint Type"),
              ),
              TextField(
                controller: messageController,
                decoration: InputDecoration(labelText: "Message"),
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera),
                    label: Text("Camera"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library),
                    label: Text("Gallery"),
                  ),
                ],
              ),
              if (selectedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Image.file(
                    selectedImage!,
                    height: 150,
                    width: 150,
                    fit: BoxFit.cover,
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickVideo(ImageSource.camera),
                    icon: Icon(Icons.videocam),
                    label: Text("Camera"),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _pickVideo(ImageSource.gallery),
                    icon: Icon(Icons.video_library),
                    label: Text("Gallery"),
                  ),
                ],
              ),
              if (selectedVideo != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text("Selected Video: ${selectedVideo!.path.split('/').last}"),
                ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: isRecording ? _stopRecording : _startRecording,
                icon: Icon(isRecording ? Icons.stop : Icons.mic),
                label: Text(isRecording ? "Stop Recording" : "Record Voice"),
              ),
              if (selectedVoice != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Text("Selected Audio: ${selectedVoice!.path.split('/').last}"),
                ),
              const SizedBox(height: 20),
              isSubmitting
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: submitComplaint,
                child: Text("Submit Complaint"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
