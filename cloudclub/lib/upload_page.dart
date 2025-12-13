import 'dart:io' show File;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  PlatformFile? selectedFile;
  double uploadProgress = 0.0;
  bool isUploading = false;
  bool isFileSelected = false;

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
                      // Upload title with cloud icon
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Icon(
                              Icons.cloud_download,
                              color: Color(0xFF2196F3),
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Upload a File',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // File selection box
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.shade300,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: InkWell(
                          onTap: _selectFile,
                          borderRadius: BorderRadius.circular(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (!isFileSelected) ...[
                                Icon(
                                  Icons.description,
                                  color: const Color(0xFF2196F3),
                                  size: 56,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Select File',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ] else ...[
                                Icon(
                                  Icons.description,
                                  color: const Color(0xFF2196F3),
                                  size: 56,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  selectedFile?.name ?? 'File Selected',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Tap to change file',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Upload button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed:
                              isFileSelected && !isUploading
                                  ? _uploadFile
                                  : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF9C27B0), Color(0xFF2196F3)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: Text(
                                'Upload Now',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Progress indicator
                      if (isUploading || uploadProgress > 0) ...[
                        Row(
                          children: [
                            const Text(
                              'Progress:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: uploadProgress,
                                backgroundColor: Colors.grey.shade300,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Color(0xFF2196F3),
                                ),
                                borderRadius: BorderRadius.circular(8),
                                minHeight: 8,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${(uploadProgress * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ],

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
        currentIndex: 1, // Upload tab is selected
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
          } else if (index == 2) {
            Navigator.pushReplacementNamed(context, '/files');
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
          // Handle other navigation items as needed
        },
      ),
    );
  }

  Future<void> _selectFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          selectedFile = result.files.first;
          isFileSelected = true;
          uploadProgress = 0.0;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadFile() async {
    if (!isFileSelected || selectedFile == null) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to upload files.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isUploading = true;
      uploadProgress = 0.0;
    });

    try {
      final PlatformFile file = selectedFile!;
      final storageRef = FirebaseStorage.instance.ref().child(
        'uploads/${user.uid}/${file.name}',
      );

      UploadTask uploadTask;
      final contentType =
          lookupMimeType(file.path ?? file.name) ?? 'application/octet-stream';
      final metadata = SettableMetadata(contentType: contentType);

      if (kIsWeb) {
        if (file.bytes == null) {
          throw Exception('No file data available for web upload.');
        }
        uploadTask = storageRef.putData(file.bytes!, metadata);
      } else {
        final filePath = file.path;
        if (filePath == null) {
          throw Exception('File path missing for upload.');
        }
        uploadTask = storageRef.putFile(File(filePath), metadata);
      }

      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final totalBytes = snapshot.totalBytes;
        if (totalBytes > 0) {
          setState(() {
            uploadProgress = snapshot.bytesTransferred / totalBytes;
          });
        }
      });

      final TaskSnapshot completedSnapshot = await uploadTask;
      final downloadUrl = await completedSnapshot.ref.getDownloadURL();
      final uploadedBytes = completedSnapshot.totalBytes;

      await _saveFileMetadata(user.uid, file.name, uploadedBytes, downloadUrl);

      if (mounted) {
        setState(() {
          isUploading = false;
          uploadProgress = 1.0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              selectedFile = null;
              isFileSelected = false;
              uploadProgress = 0.0;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isUploading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveFileMetadata(
    String userId,
    String fileName,
    int sizeBytes,
    String downloadUrl,
  ) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('files')
        .add({
          'name': fileName,
          'size': sizeBytes,
          'downloadUrl': downloadUrl,
          'path': 'uploads/$userId/$fileName',
          'uploadedAt': FieldValue.serverTimestamp(),
        });

    await userDoc.set({
      'storage': {
        'used': FieldValue.increment(sizeBytes),
        'lastUpdated': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }
}
