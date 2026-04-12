# Simplify

Simplify is an offline-first Flutter task manager designed to keep personal planning fast, calm, and fully local. It helps users manage standard one-time tasks as well as recurring focus sessions called **Yudh**, with on-device reminders, optional follow-up alarms, progress tracking, and downloadable reports.

## Overview

The project is built around a local-first productivity workflow:

- **One-time tasks** handle normal to-dos with optional due dates and reminder scheduling.
- **Yudh blocks** are recurring daily or weekly focus sessions that track streaks, score, completion rate, and missed sessions.
- **Everything stays on-device**, including tasks, reports, theme preferences, and ringtone choices.

Simplify uses a polished Flutter UI with responsive layouts, custom theming, and a task dashboard that separates work into **Today**, **Upcoming**, and **Completed** views.

## Key Features

- Offline-first task storage using SQLite
- One-time tasks with due dates and reminder scheduling
- Yudh mode for recurring daily or weekly discipline blocks
- Optional follow-up alarm after the main reminder
- Subtasks/checklist support inside tasks
- Today, Upcoming, and Completed filters
- Auto-tracked Yudh streaks, score, and completion stats
- Exportable HTML Yudh report saved locally
- Light and dark theme support
- Reminder and alarm sound customization
- Responsive UI for multiple Flutter platforms

## Yudh System

Yudh is the app's recurring productivity mode for habit-like focus sessions.

- A Yudh task can repeat daily or weekly
- Each session has a scheduled slot and duration
- Completed and missed sessions are stored as progress logs
- The app calculates streaks, score, completion rate, and report summaries
- Reports can be exported as HTML files for local review

## Tech Stack

- **Flutter** for the cross-platform application
- **Provider** for state management
- **sqflite** for local database persistence
- **shared_preferences** for theme and notification preferences
- **flutter_local_notifications** and **timezone** for scheduled reminders
- **file_picker** and **path_provider** for custom audio selection and local report export

## Project Structure

```text
lib/
  app.dart
  main.dart
  core/
    constants/
    theme/
    utils/
  data/
    database/
    models/
    repositories/
  features/
    tasks/
      providers/
      screens/
      widgets/
  services/
```

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK compatible with the project's Flutter version
- Android Studio, VS Code, or another Flutter-supported IDE

### Installation

```bash
git clone https://github.com/mr0-0kushal/Simplify.git
cd Simplify
flutter pub get
flutter run
```

## Useful Commands

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

## Why This Project

Simplify was built to offer a cleaner and more focused alternative to cloud-heavy task apps. Instead of requiring accounts or internet connectivity, it keeps the full planning experience local while still providing useful productivity features like reminders, recurring focus routines, sound customization, and progress reporting.

## Repository

GitHub: https://github.com/mr0-0kushal/Simplify
