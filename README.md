# Pickle App - Time Management App

Pickle App is a Flutter-based time management app that helps you to stay organized in your schedule, prioritize tasks, and stay focused on what's important. This app is designed to make managing your time easier and more efficient.

## Getting Started
To get started with timemanagement-pickleapp, follow these steps (*Don't include the quotation marks*):

1. *Clone the repository:* "git clone [https://github.com/yourusername/your-repo-name.git](https://github.com/PieceOfCloth/timemanagement-pickleapp.git)"
2. *Navigate to the project directory:* "cd your-repo-name" (Navigate to your directory)
3. *Install dependencies:* "flutter pub get"
4. *Run the app:* "flutter run"

For detailed setup instructions, including Firebase configuration, continue to the next section.

## Firebase Setup for Flutter
This guide will help you set up Firebase for your Flutter app. Follow these steps to configure Firebase in your project:

Step 1: Create a Firebase Project
Go to the Firebase Console.
Click on Add project and enter a project name.
(Optional) Configure Google Analytics for your project.
Click Create Project and wait for the process to complete.
Click Continue to go to your Firebase project dashboard.
Step 2: Add Android App to Firebase
In the Firebase console, click on the Android icon to add an Android app.
Enter your Android package name (e.g., com.example.pickleapp) and optionally a nickname and SHA-1 key.
Click Register app.
Download the google-services.json file and place it in the android/app directory of your Flutter project.
Step 3: Add iOS App to Firebase (if applicable)
In the Firebase console, click on the iOS icon to add an iOS app.
Enter your iOS bundle ID (e.g., com.example.pickleapp), App Store ID, and team ID (optional).
Click Register app.
Download the GoogleService-Info.plist file and place it in the ios/Runner directory of your Flutter project.
Step 4: Add Firebase SDK to Your Flutter App
Open your Flutter project in your IDE.
Add the firebase_core package to your pubspec.yaml:
yaml
Copy code
dependencies:
  flutter:
    sdk: flutter
  firebase_core: latest_version
Run flutter pub get to install the dependencies.
Step 5: Configure Firebase for Android
Open the android/build.gradle file and add the following classpath in the dependencies section:
gradle
Copy code
classpath 'com.google.gms:google-services:4.3.10'
In android/app/build.gradle, add the following at the bottom of the file:
gradle
Copy code
apply plugin: 'com.google.gms.google-services'
Make sure your minSdkVersion is at least 19 in android/app/build.gradle:
gradle
Copy code
defaultConfig {
    ...
    minSdkVersion 19
    ...
}
Step 6: Configure Firebase for iOS
Open the ios/Runner/Info.plist file.
Add the following keys:
xml
Copy code
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleTypeRole</key>
    <string>Editor</string>
    <key>CFBundleURLSchemes</key>
    <array>
      <string>YOUR_REVERSED_CLIENT_ID</string>
    </array>
  </dict>
</array>
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
Open the ios/Podfile and make sure the platform is set to at least 10.0:
ruby
Copy code
platform :ios, '10.0'
Step 7: Initialize Firebase in Your Flutter App
Open the main.dart file of your Flutter project.
Initialize Firebase in the main() function:
dart
Copy code
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
Step 8: Testing the Setup
Run your app on an Android emulator or iOS simulator.
Check if there are any issues related to Firebase setup.
If everything is set up correctly, your app should be connected to Firebase!
Troubleshooting
Firebase Console: Ensure the Firebase console has the correct app IDs and SHA-1 key.
GoogleServices File: Verify that the google-services.json and GoogleService-Info.plist files are correctly placed in their respective directories.
FlutterFire Documentation: Refer to the FlutterFire documentation for more detailed setup instructions.
