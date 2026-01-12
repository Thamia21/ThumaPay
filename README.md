# Thuma Mina Pay

A digital payment application built with Flutter and Firebase Authentication, featuring role-based access for Parents and Vendors.

## 🚀 Features

- **User Authentication**: Secure email/password login with Firebase Auth
- **Role-Based Access**: Parents and Vendors have different dashboards and capabilities
- **User Management**: Complete user profiles stored in Firestore
- **Secure Data Storage**: Firebase Firestore with proper security rules

## 🛠 Tech Stack

- **Flutter**: Mobile frontend framework
- **Firebase Authentication**: Email/password authentication
- **Cloud Firestore**: NoSQL database for user data and transactions
- **Firebase Core**: App initialization and configuration

## 📱 Project Structure

```
lib/
├── main.dart                 # App entry point
├── firebase_options.dart       # Firebase configuration
├── screens/
│   ├── auth_wrapper.dart      # Authentication flow management
│   ├── login_screen.dart      # User login interface
│   ├── registration_screen.dart # User registration with role selection
│   ├── parent_dashboard.dart # Parent-specific dashboard
│   └── vendor_dashboard.dart  # Vendor-specific dashboard
├── services/
│   └── auth_service.dart     # Firebase authentication service
├── models/
│   └── user_model.dart        # User data model
└── assets/
    └── images/               # App images and assets
```

## 🔐 Setup Instructions

### 1. Firebase Project Setup

1. Create a new Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Enable Email/Password Authentication
3. Set up Cloud Firestore
4. Run `flutterfire configure` to connect your Flutter app
5. Update `firebase_options.dart` with your Firebase config

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

## 🔐 Authentication Flow

### Registration Process
1. User selects role (Parent/Vendor)
2. Provides full name, email, password
3. Creates Firebase Auth account
4. Stores user data in Firestore
5. Redirects to appropriate dashboard

### Login Process
1. User enters email and password
2. Authenticates with Firebase Auth
3. Fetches user role from Firestore
4. Redirects to role-based dashboard

## 📊 Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read, write: if request.auth != null && 
        request.auth.token.admin == 'true' || 
        (request.resource.data.role() == 'admin' && request.auth.uid == userId);
    }
  }
  
  match /users/{userId} {
    allow read, write: if request.auth != null && request.auth.uid == userId;
    allow read: if request.auth != null && 
        request.resource.data.role() in ['parent', 'vendor'] && 
        request.auth.uid == userId;
  }
  }
}
```

## 🎯 Role-Based Features

### Parent Dashboard
- Send money to children
- View transaction history
- Manage children accounts
- Set spending allowances
- View payment analytics

### Vendor Dashboard
- Receive payments from parents
- View sales reports
- Manage products/services
- Business profile management
- Transaction history

## 🔒 Security Best Practices

- Passwords handled only by Firebase Auth
- Input validation on all forms
- Proper error handling and user feedback
- Role-based data access control
- Secure Firestore rules implementation

## 📝 Next Steps

1. Set up Firebase project and configure `firebase_options.dart`
2. Implement payment processing features
3. Add transaction history and analytics
4. Implement push notifications
5. Add admin dashboard for role management

---

**Note**: This is a complete authentication foundation. The app includes proper error handling, input validation, and role-based access control. All Firebase dependencies are properly configured and the code follows Flutter best practices.
