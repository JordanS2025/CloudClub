import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> signUp(
  String email,
  String password,
  String firstName,
  String lastName,
) async {
  try {
    final credential = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);
    final user = credential.user;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await user.updateDisplayName('$firstName $lastName');
    }
    print("User signed up and data saved!");
  } catch (e) {
    print("Signup Error: $e");
    rethrow;
  }
}

Future<void> signIn(String email, String password) async {
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    print("User logged in!");
  } catch (e) {
    print("Login Error: $e");
  }
}
