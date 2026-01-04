# Flashbook - GDG Hackathon Demo

📚 **Instagram-style scrolling interaction with a calm, book-reading aura.**

## Overview

Flashbook transforms the book reading experience into a modern, mobile-first vertical scrolling feed. Like Instagram, but for knowledge consumption.

## Features

- 📖 **Vertical Page Feed** - Swipe up to navigate through learning blocks
- 🎨 **Visual Reveals** - Tap-and-hold to reveal illustrative images
- 📌 **Bookmarks & Highlights** - Save your favorite quotes and passages
- 📊 **Progress Tracking** - See your reading streak and completion percentage
- ✨ **AI-Powered Structure** - Books are structured using AI for optimal learning (mocked for demo)

## Tech Stack

- **Flutter** - Cross-platform UI framework
- **Provider** - State management
- **Firebase Auth** - User authentication (mocked)
- **Firebase Firestore** - Data persistence (mocked)
- **Gemini API** - AI book processing (mocked)

## Project Structure

```
lib/
├── main.dart           # Entry point
├── app.dart            # App widget with providers
├── theme/              # Theme configuration
│   ├── app_colors.dart
│   └── app_theme.dart
├── models/             # Data models
│   ├── book.dart
│   ├── bookmark.dart
│   ├── reading_progress.dart
│   └── user.dart
├── services/           # Business logic
│   ├── auth_service.dart
│   ├── mock_book_service.dart
│   └── storage_service.dart
├── state/              # State management
│   ├── auth_provider.dart
│   ├── book_provider.dart
│   ├── bookmark_provider.dart
│   └── reading_progress_provider.dart
├── screens/            # App screens
│   ├── entry_screen.dart
│   ├── book_source_screen.dart
│   ├── processing_screen.dart
│   ├── learning_feed_screen.dart
│   ├── bookmark_screen.dart
│   ├── progress_screen.dart
│   └── upgrade_screen.dart
└── widgets/            # Reusable widgets
    ├── learning_card.dart
    ├── visual_reveal_widget.dart
    └── learning_insight_overlay.dart
```

## Screens

1. **Entry Screen** - Calm full-screen layout with "Begin Reading" CTA
2. **Book Source Screen** - Bottom sheet to select public library or upload PDF
3. **Processing Screen** - Animated loading while AI structures the book
4. **Learning Feed Screen** - Core experience with vertical PageView
5. **Bookmark Screen** - Saved highlights and bookmarks
6. **Progress Screen** - Reading stats and continue CTA
7. **Upgrade Screen** - Premium upsell modal

## Running the App

```bash
# Get dependencies
flutter pub get

# Run on device/emulator
flutter run
```

## Design Philosophy

- Paper-like background colors
- Serif fonts for headings (book-like feel)
- Sans-serif for body (readability)
- Generous padding and spacing
- Subtle animations (no flashy effects)
- No social media UI elements

## Built for GDG Hackathon 2025 🚀

