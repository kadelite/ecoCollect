🌍 EcoCollect: Smart Urban Waste & Recycling Platform

Overview

EcoCollect is a modern mobile application designed to bridge the gap between urban residents and municipal waste management services. By leveraging real-time reporting, gamification, and location-based tracking, the platform drives citizen engagement and optimizes city clean-up efforts. The project is strategically aligned with UN Sustainable Development Goal (SDG) #11 (Sustainable Cities and Communities) and SDG #13 (Climate Action).

💡 Problem & Solution

Area

The Challenge

The EcoCollect Solution

Operational Efficiency

Poor visibility into current waste hotspots (overflow, illegal dumping).

Real-time Reporting: Users submit geotagged and photo-verified reports directly to city services.

Transparency

Lack of public awareness regarding collection routes and progress.

Truck Tracking: Integration with Google Maps to display real-time movement of collection vehicles.

Citizen Engagement

Low participation and sustained interest in recycling and civic cleanliness.

Gamification & Rewards: Point system to incentivize responsible waste sorting and timely hotspot reporting.

✨ Core Features

The application is structured around a multi-tab interface for clear, goal-oriented user flows:

1. User Authentication

Secure Flow: Implements robust Email/Password registration and login using simulated Firebase Authentication.

Stateful Routing: Uses a core listener to dynamically route users to the AuthScreen (logged out) or the main HomeScreenContent (logged in).

Profile: Allows users to register with a username and phone number, which are stored in the mock Firestore user profile.

2. Report Hotspot

Required Inputs: Enforces validation for Description Notes, a Photo URL (Simulated), and GPS Location (Simulated) before submission.

Data Capture: Uses interactive buttons to simulate acquiring photo evidence and real-time geographic coordinates.

Data Persistence: Saves validated reports to a private user collection in Firebase and rewards the user with Eco-Points.

3. Track Trucks (Placeholder)

Designed for integration with the Google Maps SDK.

Will subscribe to a public Firebase collection (/artifacts/{appId}/public/data/truck_locations) to visualize real-time collection vehicle positions.

4. Rewards & Tips

Gamification Dashboard: Displays the user's total Eco-Points earned.

Activity Feed: Shows a list of recent user submissions for transparency and tracking.

Environmental Tips: Provides curated weekly tips to maintain recycling awareness.

🛠️ Tech Stack & Architecture

Component

Technology

Role

Mobile Client

Flutter (Dart)

Cross-platform UI, native feature access (simulated), and local state management.

Backend / DB

Firebase (Mock)

Primary data store (Firestore) for reports, user profiles, and truck locations. Handles all authentication.

Mapping

Google Maps SDK (Planned)

Real-time map rendering and interactive truck markers.

Architecture Highlights

The application follows Flutter best practices:

Modular Separation: Clear separation of concerns between authentication (AuthScreen), data input (WasteReportScreen), and display logic (GamificationScreen).

State Management: Uses StatefulWidget and the setState() method for all necessary localized updates (e.g., displaying the captured photo, updating points, showing status messages).

Simulated Backend: Utilizes local mock classes (MockAuth, MockFirestore) to ensure that the application logic, error handling, and Firebase pathing are correct and ready for production deployment with live Firebase services.

🚀 Setup and Installation

This project is built using the Dart language and the Flutter framework.

Prerequisites

Flutter SDK (Latest Stable Channel)

A Flutter-enabled IDE (VS Code or Android Studio)

Running the App

Save the Code: Save the provided main.dart code into your project's lib/ directory.

Run: Execute the following command in your terminal to run on a web browser (recommended for testing the simulated features):

flutter run -d chrome 


Testing Flow

Authenticate: Register a new user on the Register tab and log in.

Capture Photo: Navigate to Report Hotspot and click "Capture Photo (Set URL)". Paste a public image URL or use the placeholder URL provided in the input field.

Get Location: Click "Get Location" and wait 2 seconds for the simulated coordinates to be acquired.

Submit: Add notes and click "Submit Hotspot Report." The submission data is logged to the console, and your Eco-Points update in the Rewards & Tips tab.

⚙️ Project Status

Status: Core Feature Implementation Complete (Mocked)

The foundational architecture for Authentication, Reporting, and Gamification is robust and validated. The primary next steps involve integrating the live third-party SDKs (Camera/Image Picker, Geolocator, and Google Maps) which require a native mobile environment.