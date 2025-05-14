import 'package:flutter/material.dart';
import 'firebase_auth_service.dart'; // (put your auth functions here)

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue[50],
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isLogin ? "Login to CloudClub" : "Sign Up for CloudClub",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextField(controller: emailController, decoration: InputDecoration(labelText: "Email")),
              TextField(controller: passwordController, obscureText: true, decoration: InputDecoration(labelText: "Password")),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (isLogin) {
                    signIn(emailController.text, passwordController.text);
                  } else {
                    signUp(emailController.text, passwordController.text);
                  }
                },
                child: Text(isLogin ? "Login" : "Sign Up"),
              ),
              TextButton(
                onPressed: () => setState(() => isLogin = !isLogin),
                child: Text(isLogin ? "New? Sign Up" : "Already have an account? Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
