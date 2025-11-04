import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io' if (dart.library.html) 'dart:html';
import 'firebase_options.dart'; // Make sure this file exists after running FlutterFire CLI

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(EcoCollectApp());
}

class EcoCollectApp extends StatelessWidget {
  static const String _appId = "eco_collect";

  const EcoCollectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoCollect',
      theme: ThemeData(primarySwatch: Colors.green),
      home: AuthScreen(appId: _appId),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthScreen extends StatefulWidget {
  final String appId;
  const AuthScreen({super.key, required this.appId});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  Future<void> _signInAnonymously() async {
    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      String uid = userCredential.user!.uid;

      await FirebaseFirestore.instance
          .collection('artifacts/${widget.appId}/users/$uid/profile')
          .doc(uid)
          .set({'createdAt': FieldValue.serverTimestamp()});

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => WasteReportScreen(userId: uid, appId: widget.appId),
        ),
      );
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : ElevatedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Continue as Guest'),
                onPressed: _signInAnonymously,
              ),
      ),
    );
  }
}

class WasteReportScreen extends StatefulWidget {
  final String userId;
  final String appId;
  const WasteReportScreen({
    super.key,
    required this.userId,
    required this.appId,
  });

  @override
  State<WasteReportScreen> createState() => _WasteReportScreenState();
}

class _WasteReportScreenState extends State<WasteReportScreen> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _image = pickedFile);
  }

  Future<void> _uploadReport() async {
    if (_image == null) return;

    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child(
        'artifacts/${widget.appId}/users/${widget.userId}/waste_reports/$fileName.jpg',
      );

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = storageRef.putData(await _image!.readAsBytes());
      } else {
        uploadTask = storageRef.putFile(File(_image!.path));
      }

      await uploadTask;
      String downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance
          .collection(
            'artifacts/${widget.appId}/users/${widget.userId}/waste_reports',
          )
          .doc(fileName)
          .set({
            'imageUrl': downloadUrl,
            'timestamp': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waste report uploaded successfully!')),
      );
    } catch (e) {
      debugPrint("Error uploading report: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Waste'),
        backgroundColor: Colors.green,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _image == null
                  ? const Text('No image selected.')
                  : (kIsWeb
                        ? Image.network(_image!.path, height: 200)
                        : Image.file(File(_image!.path), height: 200)),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.photo),
                label: const Text("Pick Image"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: _uploadReport,
                icon: const Icon(Icons.upload),
                label: const Text("Upload Report"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
