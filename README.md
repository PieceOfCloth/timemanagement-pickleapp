# Pickle App - Time Management App Installation

Pickle App is a Flutter-based time management app that helps you to stay organized in your schedule, prioritize tasks, and stay focused on what's important. This app is designed to make managing your time easier and more efficient. *I use this code for my thesis and there are still some redundant codes*

## Getting Started
To get started with timemanagement-pickleapp, follow these steps (*Don't include the quotation marks*):

1. **Clone the repository:** "git clone https://github.com/PieceOfCloth/timemanagement-pickleapp.git"
2. **Navigate to the project directory:** "cd your-repo-name" (Navigate to your directory)
3. **Install dependencies:** "flutter pub get"
4. **Run the app:** "flutter run"

For **Database setup instructions**, including Firebase configuration, continue to the next section.

## Firebase Setup for Flutter
This guide will help you set up Firebase for Pickle App. Follow these steps to configure Firebase in your project: (*Don't include the quotation marks*)

**Step 1: Create a Firebase Project**
1. Go to the *Firebase Console*.
2. Click on **Add project** and enter a project name.
3. Click **Create Project** and follow the steps to complete.
4. Click **Continue** to go to your Firebase project dashboard.

**Step 2: Add Android App to Firebase**
1. In the Firebase console, click on the **Android icon** to add an Android app.
2. Enter your Android package name (e.g., *com.example.pickleapp*) and SHA-1 key.
3. Click **Register app**.
4. Download the *google-services.json* file and place it in the *android/app* directory of your Flutter project.

**Step 3: Add Firebase SDK to Your Flutter App**
1. Open your Flutter project in your IDE.
2. **Add the *firebase_core* package to your *pubspec.yaml*:** "firebase_core: latest_version" (Look at flutter doc for the latest version)
3. Run *flutter pub get* to install the dependencies.

**Step 4: Configure Firebase for Android**
1. **Open the *android/build.gradle* file and add the following classpath in the *dependencies* section:** "classpath 'com.google.gms:google-services:4.3.10'"
2. **In *android/app/build.gradle*, add the following at the bottom of the file:** "apply plugin: 'com.google.gms.google-services'"
3. **Make sure your *minSdkVersion* is at least 19 in *android/app/build.gradle*:**
defaultConfig {
    ...
    minSdkVersion 19
    ...
}

**Step 7: Initialize Firebase in Your Flutter App**
1. Open the *main.dart* file of your Flutter project.
2. Initialize Firebase in the *main()* function:
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

**Step 8: Testing the Setup**
Run your app on an Android emulator or iOS simulator.
1. Check if there are any issues related to Firebase setup.
2. If everything is set up correctly, your app should be connected to Firebase!
 
**Troubleshooting**
- **Firebase Console:** Ensure the Firebase console has the correct app IDs and SHA-1 key.
- **GoogleServices File:** Verify that the *google-services.json* and *GoogleService-Info.plist* files are correctly placed in their respective directories.
- **FlutterFire Documentation:** Refer to the FlutterFire documentation for more detailed setup instructions. (https://firebase.google.com/docs/flutter/setup?hl=id&authuser=1&platform=android)
