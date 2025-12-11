import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class FilesPage extends StatefulWidget {
  const FilesPage({super.key});

  @override
  State<FilesPage> createState() => _FilesPageState();
}

class _FilesPageState extends State<FilesPage> {
  String searchQuery = '';
  List<FileItem> files = [];
  List<FolderItem> folders = [];
  bool isLoading = true;
  bool isLoadingFolders = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFiles();
    _loadFolders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    try {
      setState(() {
        isLoading = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          files = [];
          isLoading = false;
        });
        return;
      }

      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('files')
          .orderBy('uploadedAt', descending: true)
          .get();

      final loadedFiles = query.docs.map((doc) {
        final data = doc.data();
        final name = data['name'] as String? ?? 'Unknown file';
        final size = (data['size'] as num?)?.toInt() ?? 0;
        final type = _detectFileType(name);
        final uploadedAt = (data['uploadedAt'] as Timestamp?)?.toDate();
        final downloadUrl = data['downloadUrl'] as String?;
        final sharing = data['sharing'] as Map<String, dynamic>?;

        return FileItem(
          id: doc.id,
          name: name,
          sizeBytes: size,
          type: type,
          lastModified: uploadedAt,
          downloadUrl: downloadUrl,
          sharingVisibility: sharing?['visibility'] as String?,
          sharingExpiresAt: (sharing?['expiresAt'] as Timestamp?)?.toDate(),
        );
      }).toList();

      setState(() {
        files = loadedFiles;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading files: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadFolders() async {
    try {
      setState(() {
        isLoadingFolders = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          folders = [];
          isLoadingFolders = false;
        });
        return;
      }

      final query = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .orderBy('createdAt', descending: true)
          .get();

      final loadedFolders = query.docs.map((doc) {
        final data = doc.data();
        return FolderItem(
          id: doc.id,
          name: data['name'] as String? ?? 'Untitled folder',
          description: data['description'] as String? ?? '',
          fileCount: (data['fileCount'] as num?)?.toInt() ?? 0,
        );
      }).toList();

      setState(() {
        folders = loadedFolders;
        isLoadingFolders = false;
      });
    } catch (e) {
      setState(() {
        isLoadingFolders = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading folders: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showCreateFolderDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New folder/album'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Vacation 2024',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _createFolder(
                  nameController.text.trim(),
                  descriptionController.text.trim(),
                );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _createFolder(String name, String description) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Folder name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to create folders.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('folders')
          .add({
        'name': name,
        'description': description,
        'fileCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _loadFolders();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Folder "$name" created'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create folder: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleShare(
    FileItem file,
    ShareVisibility visibility,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to share files.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final link = _buildShareLink(file, visibility);
    DateTime? expiresAt;
    if (visibility == ShareVisibility.temporary) {
      expiresAt = DateTime.now().add(const Duration(hours: 24));
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('files')
          .doc(file.id)
          .set(
        {
          'sharing': {
            'visibility': visibility.name,
            'link': link,
            'expiresAt': expiresAt != null
                ? Timestamp.fromDate(expiresAt)
                : FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        },
        SetOptions(merge: true),
      );

      await Clipboard.setData(ClipboardData(text: link));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Share link copied (${visibility.name}).${expiresAt != null ? ' Expires in 24h.' : ''}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not create share link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _buildShareLink(FileItem file, ShareVisibility visibility) {
    final baseLink = file.downloadUrl ?? 'https://cloudclub.example/${file.id}';
    switch (visibility) {
      case ShareVisibility.public:
        return '$baseLink?visibility=public';
      case ShareVisibility.private:
        return '$baseLink?visibility=private';
      case ShareVisibility.temporary:
        return '$baseLink?visibility=temporary';
    }
  }

  List<FileItem> get filteredFiles {
    if (searchQuery.isEmpty) {
      return files;
    }
    return files.where((file) {
      return file.name.toLowerCase().contains(searchQuery.toLowerCase());
    }).toList();
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

            // Header with folder icon and title
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE3F2FD),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(
                    Icons.folder,
                    color: Color(0xFF2196F3),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your Files',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: 'Search files...',
                    prefixIcon: Icon(Icons.search, color: Colors.grey),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Folders and albums
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  const Text(
                    'Albums & Folders',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _showCreateFolderDialog,
                    icon: const Icon(Icons.create_new_folder),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: isLoadingFolders
                  ? const Center(child: CircularProgressIndicator())
                  : folders.isEmpty
                      ? Center(
                          child: Text(
                            'Create your first album to stay organized.',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          scrollDirection: Axis.horizontal,
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            return FolderCard(folder: folder);
                          },
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemCount: folders.length,
                        ),
            ),

            const SizedBox(height: 16),

            // Files list
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  await _loadFiles();
                  await _loadFolders();
                },
                child: isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2196F3),
                        ),
                      )
                    : filteredFiles.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.folder_open,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'No files found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24),
                            itemCount: filteredFiles.length,
                            itemBuilder: (context, index) {
                              final file = filteredFiles[index];
                              return FileListItem(
                                file: file,
                                onShareSelected: (visibility) {
                                  _handleShare(file, visibility);
                                },
                              );
                            },
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
        currentIndex: 2, // Files tab is selected
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
          } else if (index == 3) {
            Navigator.pushReplacementNamed(context, '/profile');
          }
          // Handle other navigation items as needed
        },
      ),
    );
  }
}

// File item model
class FileItem {
  final String id;
  final String name;
  final int sizeBytes;
  final FileType type;
  final DateTime? lastModified;
  final String? downloadUrl;
  final String? sharingVisibility;
  final DateTime? sharingExpiresAt;

  FileItem({
    required this.id,
    required this.name,
    required this.sizeBytes,
    required this.type,
    required this.lastModified,
    this.downloadUrl,
    this.sharingVisibility,
    this.sharingExpiresAt,
  });
}

// File types enum
enum FileType { image, pdf, document, other }

// File list item widget
class FileListItem extends StatelessWidget {
  final FileItem file;
  final void Function(ShareVisibility visibility) onShareSelected;

  const FileListItem({
    super.key,
    required this.file,
    required this.onShareSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // File icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE3F2FD),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getFileIcon(file.type),
              color: const Color(0xFF2196F3),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // File details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(file.lastModified),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),

          // File size (right side)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatSize(file.sizeBytes),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                file.type.name,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            ],
          ),

          const SizedBox(width: 16),

          PopupMenuButton<ShareVisibility>(
            icon: const Icon(Icons.share, color: Color(0xFF2196F3)),
            onSelected: onShareSelected,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: ShareVisibility.public,
                child: Text('Create public link'),
              ),
              PopupMenuItem(
                value: ShareVisibility.private,
                child: Text('Private link (signed)'),
              ),
              PopupMenuItem(
                value: ShareVisibility.temporary,
                child: Text('Temporary link (24h)'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(FileType type) {
    switch (type) {
      case FileType.image:
        return Icons.image;
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.document:
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown date';
    return '${date.month}/${date.day}/${date.year}';
  }
}

enum ShareVisibility { public, private, temporary }

class FolderItem {
  final String id;
  final String name;
  final String description;
  final int fileCount;

  FolderItem({
    required this.id,
    required this.name,
    required this.description,
    required this.fileCount,
  });
}

class FolderCard extends StatelessWidget {
  final FolderItem folder;

  const FolderCard({super.key, required this.folder});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.folder, color: Color(0xFF2196F3)),
              ),
              const Spacer(),
              Text(
                '${folder.fileCount} items',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            folder.name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (folder.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              folder.description,
              style: TextStyle(color: Colors.grey.shade700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

FileType _detectFileType(String name) {
  final lower = name.toLowerCase();
  if (lower.endsWith('.png') || lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg')) {
    return FileType.image;
  }
  if (lower.endsWith('.pdf')) {
    return FileType.pdf;
  }
  if (lower.endsWith('.doc') || lower.endsWith('.docx') ||
      lower.endsWith('.txt')) {
    return FileType.document;
  }
  return FileType.other;
}
