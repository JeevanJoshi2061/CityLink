import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MyOtp extends StatefulWidget {
  const MyOtp({super.key});

  @override
  State<MyOtp> createState() => _MyOtpState();
}

class _MyOtpState extends State<MyOtp> {
  final List<TextEditingController> _otpControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  bool _isVerifying = false;
  bool _isSuccess = false;

  @override
  void dispose() {
    for (var controller in _otpControllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyOtp(String verificationId, String phoneNumber) async {
    String otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length != 6) {
      _showSnackBar('Please enter the complete 6-digit OTP');
      return;
    }
    setState(() => _isVerifying = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: otp);
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        _navigateBasedOnUser(userCredential.user!, phoneNumber);
      }
    } catch (e) {
      setState(() => _isVerifying = false);
      _showSnackBar('Invalid OTP: $e');
    }
  }

  Future<void> _navigateBasedOnUser(User user, String phoneNumber) async {
    if (await _checkUserExists(user.uid)) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    } else {
      setState(() {
        _isVerifying = false;
        _isSuccess = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacementNamed(
        context,
        '/user_detail',
        arguments: {'userId': user.uid, 'phoneNumber': phoneNumber}, // Pass phone number
      );
    }
  }

  Future<bool> _checkUserExists(String userId) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('Users').doc(userId).get();
      return userDoc.exists;
    } catch (e) {
      print('Error checking user data: $e');
      return false;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    FirebaseAuth.instance.setLanguageCode('en'); // Set to desired locale

    final args = ModalRoute.of(context)!.settings.arguments as Map;
    final String verificationId = args['verificationId'];
    final String phoneNumber = args['phoneNumber'];

    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: _isSuccess
          ? Center(child: Lottie.asset('assets/success.json', width: 200, height: 200))
          : _isVerifying
              ? const Center(child: CircularProgressIndicator())
              : _buildOtpForm(verificationId, phoneNumber),
    );
  }

  Widget _buildOtpForm(String verificationId, String phoneNumber) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/img1.png', width: 150, height: 150),
          const SizedBox(height: 25),
          const Text('Enter OTP', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          const Text(
            'Enter the OTP sent to your phone',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(6, (index) => _buildOtpField(index)),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => _verifyOtp(verificationId, phoneNumber),
            child: const Text('Verify OTP', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpField(int index) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(width: 1, color: Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: _otpControllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
        onChanged: (value) {
          if (value.length == 1 && index < 5) {
            _focusNodes[index].unfocus();
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index].unfocus();
            _focusNodes[index - 1].requestFocus();
          }
        },
      ),
    );
  }
}
