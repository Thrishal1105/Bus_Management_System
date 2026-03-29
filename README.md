# 🚌 Bus Pass & Live Tracking Ecosystem (Flutter + Firebase)

A professional, role-based mobile and web application designed for real-time bus tracking and digital QR-based pass validation. Built for high reliability and low-latency interaction using the Firebase real-time engine.

---

## 🌟 Key Features

### 👤 For Passengers
- **Live Tracking**: Watch your bus move on the map in real-time (3-5s updates).
- **Digital Pass**: Display a unique, secure QR code for boarding validation.
- **Route Visibility**: See active trips and estimated locations.

### 🚍 For Drivers
- **Trip Management**: Start/Stop trip broadcasts with a single tap.
- **Background GPS**: Shares high-accuracy location while the app is minimized.
- **Smart QR Scanner**: Resilient "Hybrid" scanner that validates passes even with blurry camera input.

### 🛡️ For Admins
- **Global Overview**: Monitor all active trips on a live dashboard.
- **User Management**: Oversee drivers, buses, and passenger registers.
- **Validation Logs**: Review real-time scan history for auditing and security.

---

## 🛠️ Tech Stack
- **Frontend**: Flutter (Mobile / Web)
- **Backend**: Firebase (Authentication, Cloud Firestore)
- **Maps**: Google Maps SDK for Flutter
- **Security**: Custom Firestore Security Rules + Role-Based Access Control

---

## 🚀 Step-by-Step Installation & Setup

Follow these steps to get a local development environment running:

### 1. Clone the Repository
```bash
git clone https://github.com/yourusername/bus-app.git
cd bus-app
```

### 2. Install Dependencies
Ensure you have the Flutter SDK installed on your machine.
```bash
flutter pub get
```

### 3. Firebase Configuration
Since these files contain private credentials, they are excluded from the repository. You must add your own:
- **Android**: Create a Firebase project and place `google-services.json` in `android/app/`.
- **iOS**: Place `GoogleService-Info.plist` in `ios/Runner/`.
- **Web**: Configure the Firebase options in `lib/firebase_options.dart`.

### 4. Environment Variables (`.env`)
Create a file named `.env` in the root directory and add your Firebase API keys and Google Maps keys:
```env
FIREBASE_API_KEY="your_api_key"
FIREBASE_APP_ID="your_app_id"
FIREBASE_MESSAGING_SENDER_ID="your_sender_id"
FIREBASE_PROJECT_ID="your_project_id"
```

### 5. Final Build & Run
Connect your device (or start an emulator) and run:
```bash
flutter run
```

---

## 🧪 Testing
We have included a dedicated validation test for the QR logic. To run the logic stress test:
```bash
flutter test test/qr_logic_test.dart
```

---

## 📄 License
This project is for educational/MVP demonstration purposes. Refer to your organization's licensing for production usage.
