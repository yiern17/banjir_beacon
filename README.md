# Banjir Beacon

Banjir Beacon is a real-time, crowd-sourced flood mapping and disaster response application. Built specifically to help communities navigate monsoon seasons, this application combines trusted official data with live community reports, all analyzed and structured by artificial intelligence. The goal is to provide rapid, localized safety information to reduce friction during emergency evacuations.

## Features

- Interactive Safety Map: A real-time dashboard displaying official evacuation shelters alongside live, community-reported flood hazards categorized by severity.

- AI-Powered Quick Reporting: Users can capture or upload a photo of rising waters. The integrated Gemini AI automatically analyzes the image to determine flood severity and generates a detailed hazard description, saving users from typing during stressful situations.

- Real-Time Synchronization: Powered by Firebase Firestore, every new report instantly propagates to all users viewing the map without requiring a manual refresh.

- Emergency Information Hub: A dedicated section providing quick access to the nearest safe zones and one-tap emergency dialers.

- Personalized Safety Settings: Users can log specific medical or accessibility needs to help rescue workers prioritize resources during critical operations.

## Local Setup and Installation

To run this project on your local machine, ensure you have the Flutter SDK installed and an Android Emulator configured. An emulator running API Level 34 is highly recommended for optimal Google Maps stability.

1. Clone the repository and install dependencies:  

git clone https://github.com/yiern17/banjir_beacon.git  
cd banjir_beacon  
flutter pub get

2. Configure API Keys and Services:

Google Maps: Obtain a Google Maps SDK for Android API key from the Google Cloud Console. Insert this key into your android/app/src/main/AndroidManifest.xml file within the <meta-data> tag.

Firebase: Set up a Firebase project. Run the FlutterFire CLI (flutterfire configure) to generate your firebase_options.dart file and connect the application to your Firestore database.

Gemini AI: Obtain an API key from Google AI Studio. Add this key to your environment variables or the configuration file where the GenerativeModel is initialized.

3. Run the Application:
For developers using Windows-based Android Emulators, Flutter's new Impeller rendering engine can occasionally conflict with Google Maps OpenGL rendering. To ensure a stable map canvas, run the application using the following command to force the Skia renderer:

flutter run --no-enable-impeller
