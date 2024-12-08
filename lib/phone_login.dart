import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class myPhone extends StatefulWidget {
  const myPhone({super.key});

  @override
  State<myPhone> createState() => _myPhoneState();
}

class _myPhoneState extends State<myPhone> {
  final _countryCodeController = TextEditingController(text: '+977'); // Default country code
  final _phoneNumberController = TextEditingController();
  String _verificationId = '';

  Future<void> _sendOtp() async {
    String phoneNumber = _countryCodeController.text + _phoneNumberController.text.trim();

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) {
          FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _showSnackBar('Verification Failed: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _verificationId = verificationId);
Navigator.pushNamed(
  context,
  '/otp',
  arguments: {
    'verificationId': verificationId,
    'phoneNumber': phoneNumber, // Pass the phone number here
  },
);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      _showSnackBar('Error: $e');
    }
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/img1.png', width: 150, height: 150),
            const SizedBox(height: 25),
            const Text('Phone Verification', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text(
              'We need to register your phone before starting',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            _buildPhoneInput(),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: _sendOtp,
              child: const Text('Send OTP', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoneInput() {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: TextField(
              controller: _countryCodeController,
              decoration: const InputDecoration(border: InputBorder.none),
            ),
          ),
          const SizedBox(width: 10),
          const Text("|", style: TextStyle(fontSize: 33, color: Colors.grey)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _phoneNumberController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Phone',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
