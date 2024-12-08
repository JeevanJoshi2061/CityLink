import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ProfileScreen extends StatefulWidget {
  final String userId; // Pass user ID to fetch data

  const ProfileScreen({super.key, required this.userId});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _name, _surname, _phoneNumber, _profilePictureUrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _fetchUserData() async {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.userId)
        .get();

    setState(() {
      _name = userDoc['name'];
      _surname = userDoc['surname'];
      _phoneNumber = userDoc['phone_number'];
      _profilePictureUrl = userDoc['profile_picture_url'];
    });
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      String? newProfilePictureUrl = _profilePictureUrl;
      if (_selectedImage != null) {
        // Upload image to Firebase Storage and get the URL
        // Add your Firebase Storage upload logic here
      }

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.userId)
          .update({
        'name': _name,
        'surname': _surname,
        'phone_number': _phoneNumber,
        'profile_picture_url': newProfilePictureUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profile updated successfully!")),
      );
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: _name == null
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
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
                                  : AssetImage('assets/default_profile.png'))
                                      as ImageProvider,
                          child: Icon(Icons.camera_alt, size: 30),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      initialValue: _name,
                      decoration: InputDecoration(labelText: 'Name'),
                      onSaved: (value) => _name = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Name is required";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      initialValue: _surname,
                      decoration: InputDecoration(labelText: 'Surname'),
                      onSaved: (value) => _surname = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Surname is required";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      initialValue: _phoneNumber,
                      decoration: InputDecoration(labelText: 'Phone Number'),
                      onSaved: (value) => _phoneNumber = value,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Phone Number is required";
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: Text("Save Changes"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
