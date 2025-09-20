import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> signUp(
  String email,
  String password,
  String firstName,
  String lastName,
) async {
  try {
    // Validate input
    if (email.isEmpty ||
        password.isEmpty ||
        firstName.isEmpty ||
        lastName.isEmpty) {
      throw Exception('All fields are required');
    }

    if (password.length < 6) {
      throw Exception('Password must be at least 6 characters long');
    }

    print("Starting sign up process for email: $email");
    print("Platform: ${defaultTargetPlatform}");

    // Check if Firebase is initialized
    try {
      final app = Firebase.app();
      print("Firebase app initialized: ${app.name}");

      // Additional check to ensure Firebase Auth is available
      if (FirebaseAuth.instance.app == null) {
        throw Exception('Firebase Auth is not available');
      }
    } catch (e) {
      print("Firebase app check failed: $e");
      throw Exception(
        'Firebase is not properly initialized. Please restart the app.',
      );
    }

    // Create user with email and password
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    print("User credential created successfully");

    final user = credential.user;
    if (user != null) {
      print("User object retrieved, UID: ${user.uid}");

      // Save user data to Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("User data saved to Firestore successfully");

      // Update display name (re-enabled with newer Firebase versions)
      await user.updateDisplayName('$firstName $lastName');
      print("Display name updated successfully");
    }
    print("User signed up and data saved!");
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    print("FirebaseAuthException caught: ${e.code} - ${e.message}");
    switch (e.code) {
      case 'weak-password':
        errorMessage = 'The password provided is too weak.';
        break;
      case 'email-already-in-use':
        errorMessage = 'An account already exists for that email.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is not valid.';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Email/password accounts are not enabled.';
        break;
      default:
        errorMessage = 'An error occurred during sign up: ${e.message}';
    }
    print("Signup Error: $errorMessage");
    throw Exception(errorMessage);
  } catch (e) {
    print("Unexpected error during signup: $e");
    print("Error type: ${e.runtimeType}");
    print("Error toString: ${e.toString()}");

    // Surface the original error to the UI so we can diagnose precisely
    throw Exception(e.toString());
  }
}

Future<void> signIn(String email, String password) async {
  try {
    if (email.isEmpty || password.isEmpty) {
      throw Exception('Email and password are required');
    }

    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    print("User logged in!");
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = 'No user found for that email.';
        break;
      case 'wrong-password':
        errorMessage = 'Wrong password provided.';
        break;
      case 'invalid-email':
        errorMessage = 'The email address is not valid.';
        break;
      case 'user-disabled':
        errorMessage = 'This user account has been disabled.';
        break;
      default:
        errorMessage = 'An error occurred during sign in: ${e.message}';
    }
    print("Login Error: $errorMessage");
    throw Exception(errorMessage);
  } catch (e) {
    print("Login Error: $e");
    throw Exception('An unexpected error occurred: $e');
  }
}
