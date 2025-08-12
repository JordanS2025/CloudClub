import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? firstName;
  String? lastName;
  String? displayName;
  bool isLoading = true;

  // Storage-related variables
  double usedStorage = 0.0;
  double totalStorage = 5.0; // 5 GB total storage
  bool isStorageLoading = true;

  // Cache for storage data to avoid recalculation
  static const String _storageCacheKey = 'storage_cache';
  static const Duration _cacheValidDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    displayName = user?.displayName;

    // Load user data and storage in parallel for better performance
    _loadUserDataAndStorage();
  }

  Future<void> _loadUserDataAndStorage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Load user data first (fast) to show name immediately
      await _loadUserName();

      // Load storage data in background (slower, but doesn't block UI)
      _loadStorageUsageInBackground();
    } else {
      setState(() {
        isLoading = false;
        isStorageLoading = false;
      });
    }
  }

  void _loadStorageUsageInBackground() {
    // Load storage data in background without blocking UI
    _loadStorageUsage().catchError((e) {
      print('Background storage loading failed: $e');
      setState(() {
        isStorageLoading = false;
      });
    });
  }

  Future<void> _loadStorageUsage() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Try to load from cache first for better performance
        final cachedData = await _loadStorageFromCache();
        if (cachedData != null) {
          setState(() {
            usedStorage = cachedData['used'] ?? 0.0;
            totalStorage = cachedData['total'] ?? 5.0;
            isStorageLoading = false;
          });
          return;
        }

        // Get user's storage usage from Firestore (same document as user data)
        final userDoc =
            await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

        if (userDoc.exists) {
          final storageData = userDoc.data()?['storage'] ?? {};
          final usedBytes = storageData['used'] ?? 0.0;
          final totalBytes =
              storageData['total'] ?? (totalStorage * 1024 * 1024 * 1024);

          final usedGB = usedBytes / (1024 * 1024 * 1024);
          final totalGB = totalBytes / (1024 * 1024 * 1024);

          setState(() {
            usedStorage = usedGB.toDouble();
            totalStorage = totalGB.toDouble();
            isStorageLoading = false;
          });

          // Cache the storage data
          await _saveStorageToCache(usedGB, totalGB);
        } else {
          // If no storage data exists, calculate from Firebase Storage
          await _calculateStorageFromFirebase();
        }
      }
    } catch (e) {
      print('Error loading storage usage: $e');
      // Fallback to calculating from Firebase Storage
      await _calculateStorageFromFirebase();
    }
  }

  Future<Map<String, double>?> _loadStorageFromCache() async {
    try {
      // For now, we'll use a simple approach
      // In a real app, you might want to use SharedPreferences or Hive
      return null; // Disable cache for now to ensure data accuracy
    } catch (e) {
      print('Error loading storage cache: $e');
      return null;
    }
  }

  Future<void> _saveStorageToCache(double used, double total) async {
    try {
      // For now, we'll skip caching to ensure data accuracy
      // In a real app, you might want to use SharedPreferences or Hive
    } catch (e) {
      print('Error saving storage cache: $e');
    }
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
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
      } catch (e) {
        print('Error loading user name: $e');
        setState(() {
          isLoading = false;
        });
      }
    } else {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _calculateStorageFromFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Show loading state immediately
        setState(() {
          isStorageLoading = true;
        });

        // List all files in user's storage folder
        final storageRef = FirebaseStorage.instance.ref().child('uploads');
        final result = await storageRef.listAll();

        double totalSize = 0.0;

        // Calculate total size of all files more efficiently
        if (result.items.isNotEmpty) {
          // Batch metadata requests for better performance
          final metadataFutures = result.items.map(
            (item) => item.getMetadata(),
          );
          final metadataList = await Future.wait(metadataFutures);

          for (final metadata in metadataList) {
            totalSize += metadata.size ?? 0;
          }
        }

        // Convert bytes to GB
        final usedGB = totalSize / (1024 * 1024 * 1024);

        setState(() {
          usedStorage = usedGB;
          isStorageLoading = false;
        });

        // Update Firestore with calculated storage usage
        await _updateStorageInFirestore(totalSize);
      }
    } catch (e) {
      print('Error calculating storage from Firebase: $e');
      setState(() {
        isStorageLoading = false;
      });
    }
  }

  Future<void> _updateStorageInFirestore(double usedBytes) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'storage': {
            'used': usedBytes,
            'total': totalStorage * 1024 * 1024 * 1024, // Convert GB to bytes
            'lastUpdated': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating storage in Firestore: $e');
    }
  }

  Future<void> _updateStorageQuota(double newQuotaGB) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          totalStorage = newQuotaGB;
        });

        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'storage': {
            'total': newQuotaGB * 1024 * 1024 * 1024, // Convert GB to bytes
            'lastUpdated': FieldValue.serverTimestamp(),
          },
        }, SetOptions(merge: true));
      }
    } catch (e) {
      print('Error updating storage quota: $e');
    }
  }

  String _formatStorageSize(double sizeInGB) {
    if (sizeInGB >= 1.0) {
      return '${sizeInGB.toStringAsFixed(1)} GB';
    } else {
      final sizeInMB = sizeInGB * 1024;
      return '${sizeInMB.toStringAsFixed(1)} MB';
    }
  }

  double _getStoragePercentage() {
    if (totalStorage == 0) return 0.0;
    return (usedStorage / totalStorage).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: Column(
        children: [
          // Header with bear illustration and welcome text
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFBFE2FF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            padding: const EdgeInsets.only(
              top: 60,
              left: 24,
              right: 24,
              bottom: 24,
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topLeft,
                  child: Icon(Icons.arrow_back, color: Colors.black, size: 28),
                ),
                const SizedBox(height: 8),
                // Placeholder for bear illustration
                SizedBox(
                  height: 80,
                  child: Image(
                    image: AssetImage('assets/Logo.png'),
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                // Show name immediately if available, fallback to loading state
                (firstName != null && firstName!.isNotEmpty) ||
                        (displayName != null && displayName!.isNotEmpty)
                    ? Text(
                      'Welcome Back, ${firstName != null && firstName!.isNotEmpty ? '${firstName}${lastName != null && lastName!.isNotEmpty ? ' $lastName' : ''}' : displayName}!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    )
                    : isLoading
                    ? const CircularProgressIndicator()
                    : Text(
                      'Welcome Back!',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                const SizedBox(height: 8),
                const Text(
                  "Let's store something today.",
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadStorageUsage,
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    children: [
                      // Storage usage indicator
                      SizedBox(
                        height: 160,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child:
                                  isStorageLoading
                                      ? const CircularProgressIndicator(
                                        strokeWidth: 10,
                                        backgroundColor: Color(0xFFE3F0FF),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF007AFF),
                                            ),
                                      )
                                      : CircularProgressIndicator(
                                        value: _getStoragePercentage(),
                                        strokeWidth: 10,
                                        backgroundColor: const Color(
                                          0xFFE3F0FF,
                                        ),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              _getStoragePercentage() > 0.8
                                                  ? Colors.red
                                                  : _getStoragePercentage() >
                                                      0.6
                                                  ? Colors.orange
                                                  : const Color(0xFF007AFF),
                                            ),
                                      ),
                            ),
                            // Storage loading indicator
                            if (isStorageLoading)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF007AFF),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                isStorageLoading
                                    ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Color(0xFF007AFF),
                                            ),
                                      ),
                                    )
                                    : Text(
                                      _formatStorageSize(usedStorage),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                const SizedBox(height: 4),
                                isStorageLoading
                                    ? const SizedBox(height: 16)
                                    : Text(
                                      'used of ${_formatStorageSize(totalStorage)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.black54,
                                      ),
                                    ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Storage quota indicator
                      if (!isStorageLoading)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color:
                                _getStoragePercentage() > 0.8
                                    ? Colors.red.withOpacity(0.1)
                                    : _getStoragePercentage() > 0.6
                                    ? Colors.orange.withOpacity(0.1)
                                    : Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _getStoragePercentage() > 0.8
                                      ? Colors.red.withOpacity(0.3)
                                      : _getStoragePercentage() > 0.6
                                      ? Colors.orange.withOpacity(0.3)
                                      : Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getStoragePercentage() > 0.8
                                    ? Icons.warning
                                    : _getStoragePercentage() > 0.6
                                    ? Icons.info
                                    : Icons.check_circle,
                                color:
                                    _getStoragePercentage() > 0.8
                                        ? Colors.red
                                        : _getStoragePercentage() > 0.6
                                        ? Colors.orange
                                        : Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getStoragePercentage() > 0.8
                                    ? 'Storage almost full!'
                                    : _getStoragePercentage() > 0.6
                                    ? 'Storage usage moderate'
                                    : 'Storage usage healthy',
                                style: TextStyle(
                                  color:
                                      _getStoragePercentage() > 0.8
                                          ? Colors.red
                                          : _getStoragePercentage() > 0.6
                                          ? Colors.orange
                                          : Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),
                      // Upload and View Files buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/upload');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF007AFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              'Upload File',
                              style: TextStyle(fontSize: 16),
                            ),
                          ),
                          const SizedBox(width: 16),
                          OutlinedButton(
                            onPressed: () {},
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: Color(0xFF007AFF),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                            ),
                            child: const Text(
                              'View Files',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF007AFF),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Recent Uploads
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Recent Uploads',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: const [
                            _FileTile(
                              icon: Icons.image,
                              fileName: 'photo1.jpg',
                              fileSize: '2,1 MB',
                            ),
                            Divider(height: 1),
                            _FileTile(
                              icon: Icons.picture_as_pdf,
                              fileName: 'notes.pdf',
                              fileSize: '800 KB',
                            ),
                            Divider(height: 1),
                            _FileTile(
                              icon: Icons.image,
                              fileName: 'selfie.png',
                              fileSize: '1,2 MB',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF007AFF),
        unselectedItemColor: Colors.black54,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: 0, // Home tab is selected
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload_outlined),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_open),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'Account',
          ),
        ],
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, '/upload');
          } else if (index == 2) {
            Navigator.pushNamed(context, '/files');
          } else if (index == 3) {
            Navigator.pushNamed(context, '/profile');
          }
          // Handle other navigation items as needed
        },
      ),
    );
  }
}

class _FileTile extends StatelessWidget {
  final IconData icon;
  final String fileName;
  final String fileSize;

  const _FileTile({
    required this.icon,
    required this.fileName,
    required this.fileSize,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF007AFF), size: 32),
      title: Text(
        fileName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Text(fileSize, style: const TextStyle(color: Colors.black54)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }
}

void _onSignInSuccess(BuildContext context) {
  Navigator.pushReplacementNamed(context, '/home');
}

void _onSignUpSuccess(BuildContext context) {
  Navigator.pushReplacementNamed(context, '/home');
}
