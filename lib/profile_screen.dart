import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name, _surname, _phoneNumber, _profilePictureUrl;
  File? _selectedImage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showError("User not logged in!");
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          _name = data?['name'] ?? 'N/A';
          _surname = data?['surname'] ?? 'N/A';
          _phoneNumber = data?['phone_number'] ?? 'N/A';
          _profilePictureUrl = data?['profile_picture_url'];
          _isLoading = false;
        });
      } else {
        _showError("User data not found!");
      }
    } catch (e) {
      _showError("Failed to fetch user data: $e");
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    try {
      String? newProfilePictureUrl = _profilePictureUrl;
      if (_selectedImage != null) {
        newProfilePictureUrl = await _uploadImage(_selectedImage!);
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('Users').doc(user.uid).update({
          'name': _name,
          'surname': _surname,
          'phone_number': _phoneNumber,
          'profile_picture_url': newProfilePictureUrl,
        });

        _showMessage("Profile updated successfully!");
      }
    } catch (e) {
      _showError("Failed to update profile: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

Future<String> _uploadImage(File image) async {
  const cloudinaryUrl = "https://api.cloudinary.com/v1_1/dtlmvwa2q/image/upload";
  const uploadPreset = "unsigned-preset";

  try {
    final request = http.MultipartRequest('POST', Uri.parse(cloudinaryUrl));
    request.fields['upload_preset'] = uploadPreset;
    request.files.add(await http.MultipartFile.fromPath('file', image.path));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final jsonResponse = json.decode(responseData);
      return jsonResponse['secure_url']; // The URL of the uploaded image
    } else {
      throw Exception("Failed to upload image");
    }
  } catch (e) {
    throw Exception("Image upload error: $e");
  }
}

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    setState(() => _isLoading = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_profilePictureUrl != null
                                  ? NetworkImage(_profilePictureUrl!)
                                  : const AssetImage('assets/default_profile.jpg')) as ImageProvider,
                          child: const Icon(Icons.camera_alt, size: 30, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(labelText: 'Name'),
                      onSaved: (value) => _name = value,
                      validator: (value) =>
                          value == null || value.isEmpty ? "Name is required" : null,
                    ),
                    TextFormField(
                      initialValue: _surname,
                      decoration: const InputDecoration(labelText: 'Surname'),
                      onSaved: (value) => _surname = value,
                      validator: (value) =>
                          value == null || value.isEmpty ? "Surname is required" : null,
                    ),
                    TextFormField(
                      initialValue: _phoneNumber,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                      onSaved: (value) => _phoneNumber = value,
                      validator: (value) =>
                          value == null || value.isEmpty ? "Phone number is required" : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: const Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
