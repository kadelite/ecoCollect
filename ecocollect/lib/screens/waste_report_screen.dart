import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WasteReportScreen extends StatefulWidget {
  final String userId;

  const WasteReportScreen({super.key, required this.userId});

  @override
  _WasteReportScreenState createState() => _WasteReportScreenState();
}

class _WasteReportScreenState extends State<WasteReportScreen> {
  XFile? _image;
  final picker = ImagePicker();
  bool _isUploading = false;

  // Replace with your app ID if needed
  final String _appId = "eco_collect_app";

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile;
    });
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() => _isUploading = true);

    try {
      final storageRef = FirebaseStorage.instance.ref().child(
        'artifacts/$_appId/users/${widget.userId}/waste_reports/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      UploadTask uploadTask;

      // Use different upload strategy for web and mobile
      if (kIsWeb) {
        // For web, use putData (read file as bytes)
        final bytes = await _image!.readAsBytes();
        uploadTask = storageRef.putData(bytes);
      } else {
        // For mobile/desktop, use File directly
        uploadTask = storageRef.putFile(File(_image!.path));
      }

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save report metadata to Firestore
      await FirebaseFirestore.instance
          .collection('artifacts/$_appId/users/${widget.userId}/waste_reports')
          .add({
            'imageUrl': downloadUrl,
            'createdAt': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waste report uploaded successfully!')),
      );

      setState(() {
        _image = null;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    }
  }

  Widget _buildPickedImage() {
    if (_image == null) {
      return const Text('No image selected.');
    }

    // ✅ Cross-platform rendering
    return kIsWeb
        ? Image.network(_image!.path, height: 200)
        : Image.file(File(_image!.path), height: 200);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Waste")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildPickedImage(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.photo_library),
              label: const Text('Pick Image'),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadImage,
              icon: const Icon(Icons.upload),
              label: Text(
                _isUploading ? 'Uploading...' : 'Upload Waste Report',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
