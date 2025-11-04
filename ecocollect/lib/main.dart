import 'package:flutter/material.dart';
import 'dart:convert';
// NOTE: In a real project, you would need the following imports:
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:image_picker/image_picker.dart'; // For photo
// import 'package:geolocator/geolocator.dart'; // For GPS

// --- Global Variables and Mock FireStore Setup ---
const String __app_id = 'ecocollect-app-1';
const String __firebase_config =
    '{"apiKey": "MOCK_KEY", "projectId": "MOCK_PROJECT"}';
const String __initial_auth_token = '';

// MOCK User class to simulate a Firebase User object
class MockUser {
  final String uid;
  final String email;
  MockUser(this.uid, this.email);
}

// MOCK Firestore for demonstration
class MockFirestore {
  final Map<String, dynamic> db = {};
  final Map<String, String> _userProfiles =
      {}; // Mock user profile storage (username/phone)

  String getPrivatePath(String userId, String collection) {
    return '/artifacts/$_appId/users/$userId/$collection';
  }

  Future<void> addDoc(String path, Map<String, dynamic> data) async {
    print('Firestore: Successfully SAVED to path: $path');
    print('Data: $data');
    // Mock save logic
  }

  Future<void> saveUserProfile(
    String uid,
    String username,
    String phone,
  ) async {
    _userProfiles[uid] = 'Username: $username, Phone: $phone';
    print('Firestore: User profile saved for $uid: $_userProfiles');
  }
}

// Global instances
final _appId = __app_id;
final _firebaseConfig = jsonDecode(__firebase_config);
final MockFirestore _db = MockFirestore();

// MOCK AUTHENTICATION LOGIC (Simulates Firebase Auth)
class MockAuth {
  MockUser? _currentUser;
  final Map<String, dynamic> _userDatabase = {}; // Mock {email: password} store

  MockUser? get currentUser => _currentUser;

  Future<MockUser?> registerWithEmailAndPassword(
    String email,
    String password,
    String username,
    String phone,
  ) async {
    if (_userDatabase.containsKey(email)) {
      throw Exception('Email already in use.');
    }
    final uid = 'user-${_userDatabase.length + 1}';
    _userDatabase[email] = {
      'password': password,
      'uid': uid,
      'username': username,
      'phone': phone,
    };
    _currentUser = MockUser(uid, email);
    await _db.saveUserProfile(uid, username, phone);
    print('Auth: User REGISTERED: $email');
    return _currentUser;
  }

  Future<MockUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    final userData = _userDatabase[email];
    if (userData != null && userData['password'] == password) {
      _currentUser = MockUser(userData['uid'] as String, email);
      print('Auth: User LOGGED IN: $email');
      return _currentUser;
    }
    throw Exception('Invalid email or password.');
  }

  Future<void> signOut() async {
    _currentUser = null;
    print('Auth: User LOGGED OUT.');
  }
}

final MockAuth _auth = MockAuth();

// ----------------------------------------------------

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoCollect: Waste & Recycling',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade700),
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
        ),
      ),
      home: const EcoCollectApp(),
    );
  }
}

// ----------------------------------------------------
// --- Core Application State (Handles Auth Flow) ---
// ----------------------------------------------------

class EcoCollectApp extends StatefulWidget {
  const EcoCollectApp({super.key});

  @override
  State<EcoCollectApp> createState() => _EcoCollectAppState();
}

class _EcoCollectAppState extends State<EcoCollectApp> {
  MockUser? _currentUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _simulateAuthStateListener();
  }

  void _simulateAuthStateListener() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _currentUser = _auth.currentUser;
      _isLoading = false;
    });
  }

  void _handleLogin(MockUser user) {
    setState(() {
      _currentUser = user;
    });
  }

  void _handleLogout() async {
    setState(() {
      _isLoading = true;
    });
    await _auth.signOut();
    setState(() {
      _currentUser = null;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentUser == null) {
      // Show Authentication Screen if user is logged out
      return AuthScreen(onLogin: _handleLogin);
    } else {
      // Show Main Content Screen if user is logged in
      return HomeScreenContent(
        currentUser: _currentUser!,
        onLogout: _handleLogout,
      );
    }
  }
}

// ----------------------------------------------------
// --- Authentication Screen (Login/Register) ---
// ----------------------------------------------------

class AuthScreen extends StatefulWidget {
  final Function(MockUser) onLogin;
  const AuthScreen({super.key, required this.onLogin});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool _isLogin = true;
  String _message = '';

  Future<void> _submitAuthForm() async {
    setState(() => _message = 'Processing...');

    try {
      if (_isLogin) {
        // LOGIN
        final user = await _auth.signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        );
        widget.onLogin(user!);
      } else {
        // REGISTER
        final user = await _auth.registerWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
          _usernameController.text,
          _phoneController.text,
        );
        widget.onLogin(user!);
      }
    } catch (e) {
      setState(() => _message = 'Error: ${e.toString().split(':').last}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login to EcoCollect' : 'Register Account'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isLogin ? 'Welcome Back!' : 'Join the Eco Movement!',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
              const SizedBox(height: 30),

              // Email Field
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
              ),
              const SizedBox(height: 15),

              // Password Field
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 15),

              // Registration Fields (Only visible on Register screen)
              if (!_isLogin) ...[
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 25),
              ],

              const SizedBox(height: 20),

              // Submit Button
              ElevatedButton(
                onPressed: _submitAuthForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(
                  _isLogin ? 'Login' : 'Register',
                  style: const TextStyle(fontSize: 18),
                ),
              ),

              const SizedBox(height: 15),

              // Status Message
              Text(
                _message,
                style: TextStyle(
                  color: _message.startsWith('Error')
                      ? Colors.red
                      : Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              // Switch Mode Button
              TextButton(
                onPressed: () {
                  setState(() {
                    _isLogin = !_isLogin;
                    _message = '';
                  });
                },
                child: Text(
                  _isLogin
                      ? 'Don\'t have an account? Register'
                      : 'Already have an account? Login',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// --- Logged-In Main Content ---
// ----------------------------------------------------

class HomeScreenContent extends StatefulWidget {
  final MockUser currentUser;
  final VoidCallback onLogout;

  const HomeScreenContent({
    super.key,
    required this.currentUser,
    required this.onLogout,
  });

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  int _selectedIndex = 0;

  // Mock user profile data for Gamification tab
  int _userPoints = 120; // Default points
  List<String> _recentReports = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _addReport(String report) {
    setState(() {
      _recentReports.insert(0, report);
      _userPoints += 5; // Reward points on report
    });
  }

  // Define the screens
  late final List<Widget> _widgetOptions = <Widget>[
    WasteReportScreen(userId: widget.currentUser.uid, onReport: _addReport),
    const MapTrackingScreen(),
    GamificationScreen(
      userId: widget.currentUser.uid,
      userPoints: _userPoints,
      recentReports: _recentReports,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EcoCollect'),
        actions: [
          // Display user email and Logout Button
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Text(
                'Logged in as: ${widget.currentUser.email}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout, // Logout function
            tooltip: 'Logout',
          ),
        ],
      ),

      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Report Hotspot',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Track Trucks'),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Rewards & Tips',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green.shade800,
        onTap: _onItemTapped,
      ),
    );
  }
}

// ----------------------------------------------------
// --- Tab 1: Waste Reporting Screen (UPDATED) ---
// ----------------------------------------------------

class WasteReportScreen extends StatefulWidget {
  final String? userId;
  final Function(String) onReport;
  const WasteReportScreen({
    super.key,
    required this.userId,
    required this.onReport,
  });

  @override
  State<WasteReportScreen> createState() => _WasteReportScreenState();
}

class _WasteReportScreenState extends State<WasteReportScreen> {
  final TextEditingController _notesController = TextEditingController();

  // State variables for photo and location simulation
  String _status = 'Ready to report';
  String? _imageUrl; // Holds the mock image URL
  double? _latitude;
  double? _longitude;

  // Controller for the image input dialog
  final TextEditingController _imageController = TextEditingController(
    text:
        'https://placehold.co/150x150/008000/FFFFFF?text=Waste+Site', // Default placeholder URL
  );

  // --- Photo Capture Simulation (Mock Image Picker) ---
  void _showImageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Simulate Photo Capture'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Enter a public image URL to simulate a photo upload:',
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _imageController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Capture/Set Image'),
              onPressed: () {
                if (_imageController.text.isNotEmpty) {
                  setState(() {
                    _imageUrl = _imageController.text;
                    _status = 'Photo URL captured successfully!';
                  });
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- GPS Location Simulation (Mock Geolocator) ---
  Future<void> _fetchLocation() async {
    setState(() => _status = 'Fetching GPS location...');

    // Simulate latency and permission check
    await Future.delayed(const Duration(seconds: 2));

    // In a real app: final position = await Geolocator.getCurrentPosition();

    setState(() {
      _latitude = 34.0522; // Mock Lat (Los Angeles)
      _longitude = -118.2437; // Mock Lon
      _status =
          'Location set: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}';
    });
  }

  // --- Report Submission Logic ---
  Future<void> _reportWasteHotspot() async {
    // 1. Validation Checks
    if (widget.userId == null || _notesController.text.isEmpty) {
      setState(() => _status = 'Error: Please add description notes.');
      return;
    }
    if (_imageUrl == null) {
      setState(() => _status = 'Error: Please capture a photo URL.');
      return;
    }
    if (_latitude == null || _longitude == null) {
      setState(() => _status = 'Error: Please acquire GPS location.');
      return;
    }

    setState(() => _status = 'Submitting report...');

    try {
      // 2. Data Preparation
      final reportData = {
        'reporterId': widget.userId,
        'notes': _notesController.text,
        'timestamp': DateTime.now().toIso8601String(),
        'latitude': _latitude,
        'longitude': _longitude,
        'status': 'Pending Review',
        'imageUrl': _imageUrl, // Include the mock image URL
      };

      // 3. Save to Firestore
      final path = _db.getPrivatePath(widget.userId!, 'waste_reports');
      await _db.addDoc(path, reportData);

      // 4. Success and State Reset
      setState(() {
        _status = 'Hotspot reported successfully! +5 Points rewarded.';
        widget.onReport(
          _notesController.text.isNotEmpty
              ? _notesController.text
              : 'No notes.',
        );
        _notesController.clear();
        _imageUrl = null; // Reset photo state
        _latitude = null; // Reset location
        _longitude = null; // Reset location
      });
    } catch (e) {
      setState(() => _status = 'Error submitting report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Text(
            'Report a Waste Hotspot',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // --- Photo Status and Button (UPDATED) ---
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: _imageUrl != null
                  ? Colors.lightGreen.shade100
                  : Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _imageUrl != null
                    ? Colors.lightGreen
                    : Colors.green.shade200,
                width: 2,
              ),
            ),
            child: _imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      _imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 50,
                              color: Colors.red,
                            ),
                          ),
                    ),
                  )
                : Center(
                    child: Icon(
                      Icons.camera_alt,
                      size: 50,
                      color: Colors.green.shade400,
                    ),
                  ),
          ),
          const SizedBox(height: 10),

          // Button to trigger photo simulation dialog
          OutlinedButton.icon(
            onPressed: () => _showImageDialog(context),
            icon: const Icon(Icons.camera_enhance),
            label: Text(
              _imageUrl != null
                  ? 'Change Captured Photo URL'
                  : 'Capture Photo (Set URL)',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade200),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // --- GPS Status and Button ---
          ListTile(
            leading: Icon(
              Icons.gps_fixed,
              color: _latitude != null ? Colors.blue.shade700 : Colors.grey,
            ),
            title: Text(
              _latitude != null ? 'Location Captured' : 'Location Not Set',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              _latitude != null
                  ? 'Lat: ${_latitude!.toStringAsFixed(4)}, Lon: ${_longitude!.toStringAsFixed(4)}'
                  : 'Acquire your current GPS location before reporting.',
            ),
            trailing: ElevatedButton(
              onPressed: _fetchLocation,
              child: const Text('Get Location'),
            ),
            tileColor: Colors.blue.shade50,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // Notes Text Field
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText:
                  'Describe the waste issue (e.g., overflow, illegal dumping)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              prefixIcon: const Icon(Icons.edit_note),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 20),

          // Report Button
          ElevatedButton.icon(
            onPressed: _reportWasteHotspot,
            icon: const Icon(Icons.send),
            label: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Submit Hotspot Report',
                style: TextStyle(fontSize: 18),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700, // Urgent color for action
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 5,
            ),
          ),
          const SizedBox(height: 20),

          // Status Display
          Text(
            _status,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _status.contains('Error')
                  ? Colors.red
                  : Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// --- Tab 2: Map Tracking Screen ---
// ----------------------------------------------------

class MapTrackingScreen extends StatelessWidget {
  const MapTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(15),
        ),
        margin: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.directions_bus,
              size: 60,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 15),
            const Text(
              'Real-Time Truck Tracking (Feature Placeholder)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Integrate Google Maps SDK here to display markers showing the live location of EcoCollect trucks.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// --- Tab 3: Gamification & Tips Screen ---
// ----------------------------------------------------

class GamificationScreen extends StatelessWidget {
  final String userId;
  final int userPoints;
  final List<String> recentReports;

  const GamificationScreen({
    super.key,
    required this.userId,
    required this.userPoints,
    required this.recentReports,
  });

  final List<String> environmentalTips = const [
    'Tip: Aluminum cans can be recycled indefinitely! Rinse them out before tossing.',
    'Tip: Reduce food waste by planning meals and storing leftovers correctly.',
    'Tip: Switch to LED bulbs to reduce energy consumption by up to 80%.',
    'Tip: Try composting kitchen scraps to create nutrient-rich soil for your garden.',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Points Card
          Card(
            color: Colors.green.shade50,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  const Icon(
                    Icons.military_tech,
                    size: 40,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Eco-Points',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        '$userPoints',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Weekly Tips Section
          Text(
            'Weekly Environmental Tips',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const Divider(),
          ...environmentalTips.map((tip) => TipTile(tip: tip)),

          const SizedBox(height: 30),

          // Recent Activity Section
          Text(
            'Recent Reports (Activity Feed)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const Divider(),
          if (recentReports.isEmpty)
            const Text(
              'No reports yet. Earn points by submitting a hotspot!',
              style: TextStyle(color: Colors.grey),
            ),
          ...recentReports.map(
            (report) => ListTile(
              leading: const Icon(
                Icons.check_circle_outline,
                color: Colors.lightGreen,
              ),
              title: const Text('New Hotspot Reported!'),
              subtitle: Text('Notes: $report'),
            ),
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class TipTile extends StatelessWidget {
  final String tip;
  const TipTile({super.key, required this.tip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.amber.shade600),
          const SizedBox(width: 10),
          Expanded(child: Text(tip, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
