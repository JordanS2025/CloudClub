import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? firstName;
  String? lastName;
  String? email;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          email = user.email;
        });

        // Load user data from Firestore
        final doc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (doc.exists) {
          setState(() {
            firstName = doc['firstName'] ?? '';
            lastName = doc['lastName'] ?? '';
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top status bar area
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    iconSize: 24,
                  ),
                  const Spacer(),
                  // Status icons (simulated)
                  Row(
                    children: [
                      Icon(
                        Icons.signal_cellular_alt,
                        color: Colors.black,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.wifi, color: Colors.black, size: 16),
                      const SizedBox(width: 4),
                      Icon(Icons.battery_full, color: Colors.black, size: 16),
                    ],
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Profile picture with koala design
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3F2FD),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1976D2),
                            width: 3,
                          ),
                        ),
                        child: const Center(child: CustomKoalaIcon()),
                      ),

                      const SizedBox(height: 16),

                      // Profile name
                      Text(
                        isLoading
                            ? 'Loading...'
                            : '${firstName ?? ''}${firstName != null && lastName != null ? "'s" : ""} Profile',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1976D2),
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Email
                      if (email != null)
                        Text(
                          email!,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF1976D2),
                          ),
                          textAlign: TextAlign.center,
                        ),

                      const SizedBox(height: 32),

                      // Divider
                      Container(height: 1, color: Colors.grey.shade300),

                      const SizedBox(height: 24),

                      // Plan details
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Free Plan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12),
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              color: Color(0xFF1976D2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const Text(
                            '5 GB',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Action buttons
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement upgrade plan functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Upgrade plan functionality coming soon!',
                                ),
                                backgroundColor: Colors.blue,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE3F2FD),
                            foregroundColor: const Color(0xFF1976D2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Upgrade Plan',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: OutlinedButton(
                          onPressed: _logout,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFF1976D2),
                              width: 2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            foregroundColor: const Color(0xFF1976D2),
                          ),
                          child: const Text(
                            'Logout',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1976D2),
        unselectedItemColor: Colors.grey.shade600,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        currentIndex: 3, // Account tab is selected
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload),
            label: 'Upload',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacementNamed(context, '/home');
          } else if (index == 1) {
            Navigator.pushReplacementNamed(context, '/upload');
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/files');
          }
          // Handle other navigation items as needed
        },
      ),
    );
  }
}

// Custom koala icon widget
class CustomKoalaIcon extends StatelessWidget {
  const CustomKoalaIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(80, 80), painter: KoalaPainter());
  }
}

// Custom painter for the koala face
class KoalaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = const Color(0xFF1976D2)
          ..style = PaintingStyle.fill;

    final strokePaint =
        Paint()
          ..color = const Color(0xFF1976D2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    // Draw koala ears
    final earPath = Path();
    earPath.addOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.3, size.height * 0.25),
        radius: size.width * 0.15,
      ),
    );
    earPath.addOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.7, size.height * 0.25),
        radius: size.width * 0.15,
      ),
    );
    canvas.drawPath(earPath, paint);

    // Draw koala face
    final facePath = Path();
    facePath.addOval(
      Rect.fromCircle(
        center: Offset(size.width * 0.5, size.height * 0.6),
        radius: size.width * 0.25,
      ),
    );
    canvas.drawPath(facePath, paint);

    // Draw eyes
    canvas.drawCircle(
      Offset(size.width * 0.4, size.height * 0.55),
      size.width * 0.08,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.55),
      size.width * 0.08,
      paint,
    );

    // Draw nose
    final nosePath = Path();
    nosePath.addOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.65),
        width: size.width * 0.12,
        height: size.height * 0.08,
      ),
    );
    canvas.drawPath(nosePath, paint);

    // Draw mouth
    final mouthPath = Path();
    mouthPath.moveTo(size.width * 0.4, size.height * 0.75);
    mouthPath.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.8,
      size.width * 0.6,
      size.height * 0.75,
    );
    canvas.drawPath(mouthPath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
