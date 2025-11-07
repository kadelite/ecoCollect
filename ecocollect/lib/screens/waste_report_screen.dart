import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class WasteReportScreen extends StatefulWidget {
  final String userId;

  const WasteReportScreen({super.key, required this.userId});

  @override
  State<WasteReportScreen> createState() => _WasteReportScreenState();
}

class _WasteReportScreenState extends State<WasteReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Plastic';
  dynamic _image; // Can be File or XFile depending on platform
  bool _isUploading = false;
  bool _isGettingLocation = false;
  Position? _currentPosition;

  final _categories = ['Plastic', 'Paper', 'Metal', 'Glass', 'Organic'];

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);

    try {
      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
              ),
            );
          }
          setState(() => _isGettingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied'),
            ),
          );
        }
        setState(() => _isGettingLocation = false);
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isGettingLocation = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGettingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || _image == null || _currentPosition == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all fields, select an image, and get your location'),
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? finalImageUrl;

      // Upload image to Firebase Storage
      try {
        final file = _image as XFile;
        final bytes = await file.readAsBytes();
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('waste_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
        
        // Add proper metadata with content type for web compatibility
        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'max-age=31536000',
        );
        
        // Try to upload with a timeout for web
        if (kIsWeb) {
          // For web, try upload but catch CORS errors immediately
          try {
            await storageRef.putData(bytes, metadata).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('Upload timeout - likely CORS issue');
              },
            );
            finalImageUrl = await storageRef.getDownloadURL();
          } catch (e) {
            // CORS or timeout error - use base64 fallback
            debugPrint('Storage upload failed (CORS/timeout), using base64 fallback: $e');
            final base64String = base64Encode(bytes);
            finalImageUrl = 'data:image/jpeg;base64,$base64String';
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Image stored as base64 (CORS issue). Configure Firebase Storage CORS for direct uploads.',
                  ),
                  duration: Duration(seconds: 4),
                ),
              );
            }
          }
        } else {
          // For mobile, normal upload
          await storageRef.putData(bytes, metadata);
          finalImageUrl = await storageRef.getDownloadURL();
        }
      } catch (storageError) {
        // Fallback for any other storage errors
        debugPrint('Storage upload failed: $storageError');
        if (kIsWeb) {
          final file = _image as XFile;
          final bytes = await file.readAsBytes();
          final base64String = base64Encode(bytes);
          finalImageUrl = 'data:image/jpeg;base64,$base64String';
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Image stored as base64 due to upload error.',
                ),
                duration: Duration(seconds: 3),
              ),
            );
          }
        } else {
          rethrow;
        }
      }

      // Get user's current points
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      
      final currentPoints = userDoc.exists 
          ? (userDoc.data()?['points'] ?? 0) 
          : 0;
      final newPoints = currentPoints + 10; // Award 10 points per report

      // Update user points
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({
        'points': newPoints,
        'email': FirebaseAuth.instance.currentUser?.email,
      }, SetOptions(merge: true));

      // Save report to Firestore
      await FirebaseFirestore.instance.collection('waste_reports').add({
        'userId': widget.userId,
        'category': _selectedCategory,
        'description': _descriptionController.text.trim(),
        'imageUrl': finalImageUrl,
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully! You earned 10 Eco-Points! 🎉'),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(() {
        _image = null;
        _currentPosition = null;
        _descriptionController.clear();
      });
    } catch (e) {
      debugPrint('Error submitting report: $e');
      if (mounted) {
        String errorMessage = 'Error submitting report';
        if (e.toString().contains('CORS') || e.toString().contains('cors')) {
          errorMessage = 'CORS error: Please configure Firebase Storage CORS settings. Check console for details.';
        } else if (e.toString().contains('permission')) {
          errorMessage = 'Permission denied. Please check Firebase Storage rules.';
        } else {
          errorMessage = 'Error: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }


  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Report Waste Hotspot',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Form(
            key: _formKey,
            child: Column(
              children: [
                // Waste category dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  items: _categories
                      .map(
                        (cat) =>
                            DropdownMenuItem(value: cat, child: Text(cat)),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedCategory = val!),
                  decoration: const InputDecoration(
                    labelText: 'Waste Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    hintText: 'Describe the waste hotspot...',
                  ),
                  validator: (value) => value!.isEmpty
                      ? 'Please enter a short description'
                      : null,
                ),
                const SizedBox(height: 16),

                // Location section
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Location',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_currentPosition != null)
                          Text(
                            'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}\n'
                            'Lng: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(fontSize: 12),
                          )
                        else
                          const Text(
                            'Location not captured',
                            style: TextStyle(color: Colors.grey),
                          ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _isGettingLocation ? null : _getCurrentLocation,
                          icon: _isGettingLocation
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.location_on),
                          label: Text(_isGettingLocation 
                              ? 'Getting Location...' 
                              : 'Get Current Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Image picker
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_image != null)
                          FutureBuilder<Uint8List>(
                            future: (_image as XFile).readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Image.memory(
                                  snapshot.data!,
                                  height: 200,
                                  fit: BoxFit.cover,
                                );
                              }
                              return const CircularProgressIndicator();
                            },
                          )
                        else
                          const Text(
                            'No image selected',
                            style: TextStyle(color: Colors.grey),
                          ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image),
                          label: const Text('Pick Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Submit button
                _isUploading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton.icon(
                        onPressed: _submitReport,
                        icon: const Icon(Icons.upload),
                        label: const Text('Submit Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 50),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 10),
          const Text(
            'Your Recent Reports',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          // Display recent reports by user
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('waste_reports')
                .where('userId', isEqualTo: widget.userId)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (snapshot.hasError) {
                debugPrint('Firestore error: ${snapshot.error}');
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error loading reports: ${snapshot.error}'),
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No reports yet. Submit your first report!'),
                  ),
                );
              }

              // Sort by timestamp in memory (since composite index might not exist)
              final reports = snapshot.data!.docs.toList()
                ..sort((a, b) {
                  final aTime = a.data() as Map<String, dynamic>;
                  final bTime = b.data() as Map<String, dynamic>;
                  final aTimestamp = aTime['timestamp'] as Timestamp?;
                  final bTimestamp = bTime['timestamp'] as Timestamp?;
                  if (aTimestamp == null && bTimestamp == null) return 0;
                  if (aTimestamp == null) return 1;
                  if (bTimestamp == null) return -1;
                  return bTimestamp.compareTo(aTimestamp);
                });
              
              // Take only the first 5
              final recentReports = reports.take(5).toList();
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentReports.length,
                itemBuilder: (context, index) {
                  final data = recentReports[index].data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          data['imageUrl'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.image, size: 60),
                        ),
                      ),
                      title: Text(data['category'] ?? 'Unknown'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['description'] ?? ''),
                          if (data['timestamp'] != null)
                            Text(
                              _formatTimestamp(data['timestamp']),
                              style: const TextStyle(fontSize: 10),
                            ),
                        ],
                      ),
                      trailing: const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = timestamp is Timestamp 
        ? timestamp.toDate() 
        : DateTime.now();
    return '${date.day}/${date.month}/${date.year}';
  }
}
