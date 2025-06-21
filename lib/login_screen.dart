import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final storage = FlutterSecureStorage();
  bool _obscurePassword = true;

  Future<void> _signInWithGoogle() async {
    try {
      await _googleSignIn.signOut();
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      final token = await _auth.currentUser?.getIdToken();
      await storage.write(key: 'firebase_token', value: token);

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/auth'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 201) {
        _showMessage('User authenticated successfully');
        Navigator.pushReplacementNamed(context, '/vehicle');
      } else if (response.statusCode == 200) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      _showMessage('Google Sign-in failed');
      print('Sign-in failed: $e');
    }
  }

  Future<void> _signInWithEmailPassword() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final token = await _auth.currentUser?.getIdToken();
      await storage.write(key: 'firebase_token', value: token);

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/auth'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showMessage('User authenticated successfully');
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
      else if( response.statusCode == 201) {
        _showMessage('User authenticated successfully');
        Navigator.pushReplacementNamed(context, '/vehicle');

      } else {
        _showMessage('Failed to authenticate user: ${response.statusCode}');
      }
    } catch (e) {
      _showMessage('Email login failed');
      print('Email/password sign-in error: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Color.fromARGB(255, 70, 118, 91); // SeaGreen

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Fuel Tracker Login', style: TextStyle(fontFamily: 'TimesNewRoman',color: Colors.white,fontWeight:  FontWeight.bold)),
        backgroundColor: themeColor,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          padding: EdgeInsets.all(24),
          margin: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Text(
                  'Welcome Back!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'TimesNewRoman',
                    color: themeColor,
                  ),
                ),
                SizedBox(height: 30),

                // Email
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(fontFamily: 'TimesNewRoman'),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: TextStyle(fontFamily: 'TimesNewRoman'),
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Email Sign-In
                ElevatedButton(
                  onPressed: _signInWithEmailPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Sign in with Email',
                      style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'TimesNewRoman',
                          color: Colors.white)),
                ),
                SizedBox(height: 16),

                // Google Sign-In
                ElevatedButton.icon(
                  icon: FaIcon(FontAwesomeIcons.google, color: Colors.white),
                  label: Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 16,
                      fontFamily: 'TimesNewRoman',
                      color: Colors.white,
                    ),
                  ),
                  onPressed: _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                SizedBox(height: 20),

                // Register
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/register');
                  },
                  child: Text(
                    'Don\'t have an account? Register here',
                    style: TextStyle(
                      fontFamily: 'TimesNewRoman',
                      fontSize: 14,
                      color: themeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
