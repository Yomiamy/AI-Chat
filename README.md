# AI-Chat (Gemini AI Assistant)

A modern AI chat application built with Flutter and Firebase AI (Gemini). This project demonstrates how to integrate Google's state-of-the-art Gemini models into a mobile application, providing a fluid, responsive, and "Good Taste" user experience.

## 📸 Screenshots

| Empty State | Chat Interface |
| :---: | :---: |
| ![Empty State](assets/images/empty_state.png) | ![Chat Interface](assets/images/chat_interface.png) |

## ✨ Features

-   **Gemini 2.5 Flash Integration**: Leverages the latest Gemini models for high-speed, accurate AI interactions.
-   **Real-time Streaming Responses**: Implements Stream-based API for a smooth "typing" effect in conversations.
-   **Modern Material 3 UI**:
    -   Clean, bubble-style chat interface.
    -   Full Markdown rendering (including code blocks with syntax highlighting and inline images).
    -   Automatic bottom-scrolling with smooth animations.
    -   Responsive input area with physical keyboard support (Enter to send, Shift+Enter for newline).
    -   **AppBar Menu**: Convenient actions for clearing chat, copying messages, and viewing application details.
-   **Session Management**: Implements chat session handling and data persistence across restarts.
-   **Robust Architecture**: Utilizes the BLoC (Business Logic Component) pattern for clean, predictable state management.
-   **Dependency Injection**: Structured DI container for repository and bloc instance management.
-   **Localization (i18n)**: Multi-language support (English and Traditional Chinese) using `.arb` files.
-   **Strongly Typed Assets**: Utilizes `flutter_gen` for type-safe static assets and colors management.
-   **Modular UI Components**: Fully decoupled and reusable widget architecture.

## 🛠 Tech Stack

-   **Core Framework**: [Flutter](https://flutter.dev) (v3.10.8+)
-   **Language**: [Dart](https://dart.dev)
-   **State Management**: [flutter_bloc](https://pub.dev/packages/flutter_bloc) (v9.1.1)
-   **AI Engine**: [firebase_ai](https://pub.dev/packages/firebase_ai) (v3.7.0)
-   **Data Persistence**: `shared_preferences` for session state caching.
-   **UI & Utilities**:
    -   `flutter_markdown`: For rendering AI-generated Markdown content.
    -   `url_launcher`: Handling link interactions within the chat.
    -   `equatable`: Simplified value equality in BLoC states.
    -   `flutter_gen`: For strongly-typed assets.

## 🏗 Project Structure

The project follows a Feature-First, clean architecture approach:

```text
lib/
├── bloc/               # Core Business Logic (BLoC)
│   └── gemini_api/     # Gemini API communication, state, events & models
├── data/               # Data Layer & Repositories (Chat Repository)
├── di/                 # Dependency Injection setup
├── features/           # Reusable utils and foundation
├── generated/          # Auto-generated code (e.g., flutter_gen assets)
├── l10n/               # Localization files (.arb)
├── pages/              # UI Components & Pages
│   ├── ai_chat_page.dart # Primary Chat Interface Entry
│   └── widgets/        # Modular UI components (InputArea, MessageBubble, etc.)
└── main.dart           # Entry point & Firebase Initialization
```

## 🚀 Getting Started

### Prerequisites

1.  Ensure you have the Flutter SDK installed.
2.  Create a project in the [Firebase Console](https://console.firebase.google.com/).
3.  Enable the **Google AI (Gemini)** service.
4.  Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) and place them in:
    -   `android/app/google-services.json`
    -   `ios/Runner/GoogleService-Info.plist`

### Running the Project

```bash
# Fetch dependencies
flutter pub get

# Run the application
flutter run
```

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---
Developed by Yomiry.
