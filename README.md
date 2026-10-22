<div align="center">

# ⚡ Offline-First Habit Tracker with Local Behavioral Insights

**A private, zero-telemetry, on-device habit tracker powered by deterministic behavioral psychology algorithms and local SQLite persistence.**

[![Flutter](https://img.shields.io/badge/Flutter-3.12%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![SQLite](https://img.shields.io/badge/SQLite-sqflite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://www.sqlite.org)
[![Android WorkManager](https://img.shields.io/badge/WorkManager-Background%20API-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com/topic/libraries/architecture/workmanager)
[![Architecture](https://img.shields.io/badge/Architecture-Clean%20%2F%20Offline--First-10B981?style=for-the-badge)](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20On--Device-6366F1?style=for-the-badge)](https://en.wikipedia.org/wiki/Local-first_software)
[![License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)

<br/>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#behavioral-psychology-engine">Behavioral Engine</a> •
  <a href="#system-architecture">Architecture</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#getting-started">Getting Started</a> •
  <a href="#team-members">Team Members</a>
</p>

</div>

---

## 📖 Overview

Most modern habit applications suffer from two critical flaws:
1. **Invasive Cloud Tracking:** Intimate daily routines, mental health logs, and behavioral patterns are routinely harvested to remote servers.
2. **Vague LLM Hallucinations:** Generative cloud models offer ungrounded, expensive, and delayed recommendations without understanding deterministic habit formation principles.

**Offline-First Habit Tracker** solves this through a strictly local-first paradigm. All data resides exclusively on your device inside an ACID-compliant **SQLite** database. Behavioral interventions are synthesized instantly on-device using a **rule-based behavioral heuristics engine** grounded in published psychological frameworks by **James Clear** (*Atomic Habits*), **Dr. BJ Fogg** (*Tiny Habits*), **Roy Baumeister** (*Ego Depletion & Willpower*), and **Daniel Kahneman** (*Prospect Theory & Loss Aversion*).

---

## 🌟 Key Features

* 🔒 **100% Offline & Private:** Zero account logins, zero tracking telemetry, and zero network calls. Data never leaves the device.
* 🧠 **Deterministic Behavioral Engine:** Analyzes completion patterns locally to detect:
  * **Habit Stacking Opportunities:** Pairs struggling routines with established 80%+ anchor habits.
  * **Weekend Slump Detection:** Identifies Saturday/Sunday drop-offs and recommends friction reductions.
  * **Circadian Timing & Friction:** Correlates time-of-day completion logs to prevent ego depletion.
  * **Streak Defense Alerts:** Intervenes proactively before the midnight cutoff to protect streaks.
  * **"Never Miss Twice" Rule:** Triggers immediate recovery interventions after a single missed session.
* 📊 **Rich Analytics Dashboard:**
  * **4-Week Consistency Heatmap:** GitHub-style activity matrix with 5 intensity levels and interactive day inspection.
  * **Animated Trend Lines & Curves:** Smooth cubic spline charts powered by `fl_chart` illustrating 7-day and 30-day rolling completion ratios.
  * **Category Allocation:** Visual donut distribution of lifestyle balance across health, focus, and wellness.
* ⏰ **Hardened Android WorkManager Integration:**
  * Background worker runs periodically and survives OS battery optimizations to perform midnight streak audits and deliver timely local notification nudges.
* 🎨 **Deep Obsidian Dark Mode & Glassmorphism:**
  * Modern minimalist dark theme (`#090D16`) with glowing neon emerald and electric indigo accents.
  * Frosted glass cards (`BackdropFilter`) and floating glass bottom navigation.
  * Fluid entrance animations, staggered list loads, and tactile micro-bounce check-ins.
* ⚡ **Instant 21-Day Demo Seeder:**
  * One-click dataset generator that loads 3 weeks of realistic behavioral data (anchors, weekend drops, circadian shifts) for instant testing of all engine heuristics.

---

## 🧠 Behavioral Psychology Engine

The on-device behavioral engine transforms raw SQLite logs into actionable coaching experiments:

| Behavioral Principle | Grounding Scientist / Theory | Trigger Heuristic in Engine | Actionable Intervention |
| :--- | :--- | :--- | :--- |
| **Habit Stacking** | James Clear (*Atomic Habits*) | Candidate habit has consistency `< 60%`, while an Anchor habit has `≥ 75%` with `≥ 5` completions. | *"Anchor your new habit immediately after your established routine (e.g. Meditate right after Morning Coffee)."* |
| **Never Miss Twice** | James Clear (*Atomic Habits*) | Yesterday was scheduled and missed; today is scheduled and pending; prior completions `≥ 3`. | *"One missed day is an accident; two missed days is the start of a new, negative habit. Complete a 2-minute micro-version today."* |
| **Weekend Slump** | Dr. BJ Fogg (*Tiny Habits*) | Weekday completion rate `≥ 65%`, but weekend rate drops by `> 25%` over a 21-day rolling window. | *"Weekend environment lacks weekday environmental cues. Lower the baseline requirement (e.g. read 2 pages instead of 20)."* |
| **Circadian Friction** | Roy Baumeister (*Willpower*) | `≥ 65%` of completions occur in one time window (e.g. Morning), but `< 15%` occur in scheduled evening slots. | *"Ego depletion is sabotaging evening sessions. Shift this high-friction habit to your peak morning energy window."* |
| **Loss Aversion** | Kahneman & Tversky (*Prospect Theory*) | Active streak `≥ 3` days, habit scheduled for today remains uncompleted, and local time `≥ 14:00`. | *"Urgent Streak Defense: You have an active streak at risk. Invest 5 minutes now to protect your neurological momentum."* |
| **Momentum Milestones** | Phillippa Lally (*Automaticity Curve*) | Current streak reaches milestone thresholds (7, 14, 21, 30, 66, 100 days). | *"Celebration of neuroplasticity: Research shows habit automaticity peaks at 66 days. You are solidifying permanent neural wiring."* |

---

## 🏛️ System Architecture

Built adhering to strict **Clean Architecture** and **Layered Separation of Concerns**:

```
lib/
├── data/
│   ├── datasources/
│   │   ├── database_helper.dart      # SQLite schema, indices, queries, and migrations
│   │   └── sample_data_seeder.dart   # 21-day realistic behavioral dataset generator
│   ├── models/
│   │   ├── habit.dart                # Core habit entity with frequency & scheduling
│   │   ├── habit_log.dart            # Execution log with timestamps, mood, & notes
│   │   ├── habit_stats.dart          # Aggregated metrics & rolling ratios
│   │   └── behavioral_insight.dart   # Structured insight model with psychology taxonomy
│   └── repositories/
│       ├── habit_repository.dart     # Single source of truth for habits & stats calculation
│       └── insights_repository.dart  # Persistence & dismissal of behavioral insights
├── domain/
│   └── engine/
│       ├── behavioral_engine.dart    # Pure Dart heuristics analyzing SQLite logs
│       └── local_coach_prompts.dart  # Scientific copy templates for behavioral nudges
├── services/
│   ├── background_worker.dart        # Android WorkManager callback dispatcher & scheduling
│   └── notification_service.dart     # Flutter Local Notifications channel management
└── ui/
    ├── core/
    │   ├── app_constants.dart        # Categories, color palettes, and icon mappings
    │   ├── app_theme.dart            # Deep obsidian dark mode & glassmorphism tokens
    │   └── widgets/
    │       ├── glass_container.dart  # Reusable backdrop blur frosted glass container
    │       ├── habit_card.dart       # Tactile card with micro-bounce checkmarks & gestures
    │       ├── progress_ring.dart    # Circular progress with gradient shader
    │       └── streak_badge.dart     # Glowing streak flame indicator
    ├── viewmodels/
    │   ├── habit_viewmodel.dart      # Habit management with cross-viewmodel reactive updates
    │   ├── insights_viewmodel.dart   # Behavioral insights state & filtering
    │   └── stats_viewmodel.dart      # Chart metrics, rolling trends, & heatmap state
    └── views/
        ├── dashboard_view.dart       # Staggered habit checklist, date strip, streak alerts
        ├── insights_view.dart        # Behavioral feedback feed & Habit Health Index
        ├── analytics_view.dart       # 4-week heatmap, animated trend lines, category donut
        ├── settings_view.dart        # Background worker diagnostics, seeder, database reset
        ├── add_edit_habit_view.dart  # Habit builder with anchor habit stacking selector
        └── main_navigation_view.dart # Floating glassmorphic bottom navigation bar
```

---

## 📸 Screenshots

<div align="center">

| Today's Dashboard & Streak Alert | 4-Week Consistency Heatmap & Trends |
| :---: | :---: |
| <img src="https://via.placeholder.com/400x800/090D16/10B981?text=Dashboard+%26+Streak+Defense" width="360" alt="Dashboard Screenshot Placeholder"/> | <img src="https://via.placeholder.com/400x800/090D16/6366F1?text=4-Week+Heatmap+%26+Trends" width="360" alt="Analytics Screenshot Placeholder"/> |

| Behavioral Insights Feed | Add Habit & Habit Stacking |
| :---: | :---: |
| <img src="https://via.placeholder.com/400x800/090D16/F59E0B?text=Behavioral+Insights+Engine" width="360" alt="Insights Screenshot Placeholder"/> | <img src="https://via.placeholder.com/400x800/090D16/06B6D4?text=Habit+Stacking+Setup" width="360" alt="Habit Form Screenshot Placeholder"/> |

</div>

> *Tip: Replace the placeholder URLs above with your own exported screenshots in `assets/screenshots/` before publishing.*

---

## 🚀 Getting Started

Follow these steps to clone, configure, and run the application locally.

### 1. Prerequisites

Ensure you have installed:
* [Flutter SDK](https://docs.flutter.dev/get-started/install) (`v3.12.0` or higher)
* [Dart SDK](https://dart.dev/get-dart) (`v3.0.0` or higher)
* Android Studio / Xcode (or Google Chrome for Web preview)

Check your environment health:
```bash
flutter doctor
```

### 2. Clone the Repository

```bash
git clone https://github.com/Soham51826/offline-habit-tracker.git
cd offline-habit-tracker
```

### 3. Install Dependencies

Fetch all required Flutter and Dart packages:
```bash
flutter pub get
```

### 4. Run the Application

Launch on your connected Android device, emulator, or desktop/web:

**Android / iOS:**
```bash
flutter run
```

**Web (Chrome):**
```bash
flutter run -d chrome
```

**Windows Desktop:**
```bash
flutter run -d windows
```

### 5. Running Automated Tests

Execute the full suite of unit and widget tests:
```bash
flutter test
```

For static code analysis and lint verification:
```bash
flutter analyze
```

---

## 🧪 Quick Test-Drive with 21-Day Demo Data

To immediately explore the full behavioral intelligence engine without waiting 3 weeks:
1. Open the app and navigate to the **Settings** tab (gear icon).
2. Tap **"Seed 21-Day Realistic Data"**.
3. Return to **Today**: notice the completed/in-progress habits and streak alerts.
4. Open **Insights**: see live triggers for *Habit Stacking* (pairing journaling after coffee), *Weekend Slump*, and *Circadian Timing*.
5. Open **Analytics**: view the populated 28-day contribution heatmap and animated completion curves.

---

## 👥 Team Members

Developed with passion by:

| Name | Roll Number | Role |
| :--- | :---: | :--- |
| **Soham** | **C096** | Lead Mobile Developer & System Architecture |
| **Aman** | **C106** | UI/UX Design & Analytics Visualizations |
| **Arsh** | **C109** | Behavioral Intelligence Engine & Background Worker |

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <sub>Built with 💚 for privacy-conscious habit builders worldwide.</sub>
</div>
