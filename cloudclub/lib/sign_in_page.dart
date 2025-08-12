import 'package:flutter/material.dart';
import 'firebase_auth_service.dart'; // (put your auth functions here)

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  bool showForm = false;
  bool isSignUp = true;
  bool isLoading = false;
  String? errorMessage;

  Future<void> handleAuth() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      if (isSignUp) {
        await signUp(
          emailController.text.trim(),
          passwordController.text.trim(),
          firstNameController.text.trim(),
          lastNameController.text.trim(),
        );
      } else {
        await signIn(
          emailController.text.trim(),
          passwordController.text.trim(),
        );
      }
      // On success, navigate to the home page
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showAuthForm(bool signUp) {
    setState(() {
      showForm = true;
      isSignUp = signUp;
      errorMessage = null;
      emailController.clear();
      passwordController.clear();
      firstNameController.clear();
      lastNameController.clear();
    });
  }

  void hideAuthForm() {
    setState(() {
      showForm = false;
      errorMessage = null;
      emailController.clear();
      passwordController.clear();
      firstNameController.clear();
      lastNameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE3F2FD), Color(0xFFFFFFFF)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/Logo.png',
                  height: 140,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 24),
                const Text(
                  'CloudClub',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF223066),
                  ),
                ),
                if (!showForm) ...[
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome to CloudClub',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF223066),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your space, your pace.',
                    style: TextStyle(fontSize: 18, color: Color(0xFF223066)),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: 320,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => showAuthForm(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF9CA6F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 320,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () => showAuthForm(false),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(
                          color: Color(0xFF223066),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ),
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF223066),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () {
                      // TODO: Implement continue as guest
                    },
                    child: const Text(
                      'Continue as Guest',
                      style: TextStyle(fontSize: 16, color: Color(0xFF223066)),
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 32),
                  if (isSignUp) ...[
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 320,
                      child: TextField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: CircularProgressIndicator(),
                    ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 320,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : handleAuth,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF9CA6F5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isSignUp ? 'Sign Up' : 'Log In',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: isLoading ? null : hideAuthForm,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF223066),
                    ),
                    label: const Text(
                      'Back',
                      style: TextStyle(fontSize: 16, color: Color(0xFF223066)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
