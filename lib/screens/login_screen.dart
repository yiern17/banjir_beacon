import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/gradient_scaffold.dart';
import 'main_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLogin = true;
  bool _isLoading = false;

  // Added the two new controllers!
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    // Best Practice: Clear memory when the screen is closed
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientScaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              const Icon(Icons.water_drop, size: 80, color: Colors.blue),
              const SizedBox(height: 16),
              Text(
                isLogin ? 'Welcome Back' : 'Create Account',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 40),

              // This widget creates the smooth slide-down animation!
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: Column(
                  children: [
                    if (!isLogin) ...[
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                ),
              ),

              // Email Field (Always visible)
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password Field (Always visible)
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Main Action Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isLoading ? null : () async {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      if (isLogin) {
                        // ---------------------------------------------------------
                        // FIREBASE LOGIN
                        // ---------------------------------------------------------
                        await FirebaseAuth.instance.signInWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );

                        // ONLY go to Main Screen if they successfully log in!
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const MainScreen()),
                          );
                        }

                      } else {
                        // ---------------------------------------------------------
                        // FIREBASE SIGN UP
                        // ---------------------------------------------------------
                        UserCredential userCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: _emailController.text.trim(),
                          password: _passwordController.text.trim(),
                        );
                        
                        // Attach Name to Auth
                        await userCred.user?.updateDisplayName(_nameController.text.trim());

                        // Save Name and Phone to Firestore
                        String newUserId = userCred.user!.uid;
                        await FirebaseFirestore.instance.collection('users').doc(newUserId).set({
                          'name': _nameController.text.trim(),
                          'phone': _phoneController.text.trim(),
                          'email': _emailController.text.trim(),
                          'createdAt': FieldValue.serverTimestamp(), 
                        });

                        // CRITICAL: Firebase auto-logs you in on sign up. We must sign them out!
                        await FirebaseAuth.instance.signOut();

                        if (context.mounted) {
                          // Show a nice green success popup
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Account created successfully! Please log in."), 
                              backgroundColor: Colors.green
                            ),
                          );

                          // Flip the UI back to Login mode and clear the password/name fields
                          setState(() {
                            isLogin = true; 
                            _nameController.clear();
                            _phoneController.clear();
                            _passwordController.clear();
                            // Notice we DO NOT clear the email controller—it's a nice UX touch 
                            // to leave their email filled in so they only have to type their password!
                          });
                        }
                      }
                    } on FirebaseAuthException catch (e) {
                      String message = "An error occurred. Please try again.";
                      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
                        message = "Incorrect email or password.";
                      } else if (e.code == 'email-already-in-use') {
                        message = "An account already exists for that email.";
                      } else if (e.code == 'weak-password') {
                        message = "Password should be at least 6 characters.";
                      }
                      
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(message), backgroundColor: Colors.red),
                        );
                      }
                    } finally {
                      if (context.mounted) {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          isLogin ? 'LOGIN' : 'SIGN UP',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Toggle Button
              TextButton(
                onPressed: () {
                  setState(() {
                    isLogin = !isLogin;
                    
                    // Clear out the text boxes when they flip between Login and Sign Up
                    _nameController.clear();
                    _phoneController.clear();
                    _passwordController.clear();
                  });
                },
                child: Text(
                  isLogin 
                      ? "Don't have an account? Sign up" 
                      : "Already have an account? Login",
                  style: const TextStyle(color: Colors.blueGrey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}