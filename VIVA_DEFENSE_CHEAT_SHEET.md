# HabitForge: Monday Viva Defense & Presentation Master Cheat Sheet
**Date of Evaluation:** Monday, 27/10/2026 (10:00 AM – 12:00 PM)  
**Evaluator / Faculty:** Prof. Aishwarinandini Bishnu Rout  
**Division / Batch:** C1 — BTI Division  
**Deliverables Checklist:** 
- [x] **Report:** Fully compiled in `MINI_PROJECT_REPORT.md`
- [x] **Working App Model:** Clean build, 0 bugs, 1-tap "Quick Demo Login (Soham)", offline fallback
- [x] **Code & Tests:** 0 lint issues (`flutter analyze`), 12/12 passing tests (`flutter test`)

---

## 1. 10-Minute Presentation Split & Speaking Timetable

| Speaker | Roll No. | Topic / Domain | Target Time | Slide Breakdown |
| :--- | :--- | :--- | :---: | :--- |
| **Soham** | C096 | Problem Statement, Motivation, Core Vision & Offline Sovereignty | 0:00 – 3:20 | Slides 1–3 (Intro, Problems, Solution) |
| **Aman** | C106 | MVVM Architecture, SQLite Schema, Constraints & WorkManager | 3:20 – 6:40 | Slides 4–6 (Architecture, Database, Background) |
| **Arsh** | C109 | Rule-Based Heuristics, UI/UX, Automated Tests & Future Scope | 6:40 – 10:00 | Slides 7–9 (Behavioral Engine, UI/Charts, Verification) |

---

## 2. 3-Minute Live App Demonstration Flow (Step-by-Step)

When the faculty says *"Show us the running app on your phone"*:

1. **Launch Screen (Title Page):**
   - Show the glowing emerald leaf logo and value proposition cards.
   - Point out: *"We designed this for universal accessibility (ages 20 to 80+) with clear contrast and high touch targets."*
   - Tap **"I Already Have an Account"** $\rightarrow$ Show the Login screen.
2. **One-Tap Demo Login:**
   - Tap **"Quick Demo Login (Soham)"**.
   - Point out: *"Session state is safely persisted locally via SharedPreferences with zero cloud tracking."*
3. **Home Dashboard:**
   - Notice the personalized greeting: `"Hello, Soham 👋"`.
   - Show the circular progress ring and date strip.
   - Tap a habit checkbox: watch the progress ring animate and streak badge increment in real time.
4. **Google Maps Geofencing (Add Habit):**
   - Tap **+** to add a habit.
   - Enter *"Campus Gym"*, toggle **"Attach Location (Geofence)"**.
   - Show the embedded Google Map, set the radius slider (150m).
   - Explain: *"When the user physically enters this venue, Android GPS triggers a proximity notification using Haversine calculation."*
5. **Insights & Gemini AI Coach:**
   - Switch to the **Insights** tab.
   - Point out the **Habit Health Index (0-100)** and the 4 behavioral nudges (Habit Stacking, Weekend Slump, etc.).
   - Tap **"Consult Gemini AI Coach"** to show personalized coaching.
   - Explain: *"If internet drops, it seamlessly falls back to on-device heuristics with zero crashes."*
6. **Analytics & Heatmap:**
   - Switch to **Analytics**: show the 7-day completion bar chart, donut chart, and the 28-day GitHub-style consistency heatmap matrix.
7. **Settings & Logout:**
   - Switch to **Settings**: show Soham's profile avatar, toggle dark/light theme, and demonstrate the secure Logout confirmation dialog returning to the Title screen.

---

## 3. Top 10 Anticipated Viva Questions & Model Answers

### Q1: Why did you use MVVM architecture instead of simple StatefulWidget?
> **Answer:** *"MVVM achieves strict separation of concerns. Our UI views are dumb reactive widgets that only listen to ViewModels via Provider. Business logic, SQLite queries, and Gemini API calls are completely isolated in domain services and repositories. This makes our business logic 100% unit-testable without needing to mount Flutter widgets."*

### Q2: How does your app ensure offline-first data integrity?
> **Answer:** *"SQLite is our single source of truth. We enforce a `UNIQUE(habit_id, date)` constraint on `habit_logs` to ensure idempotency so repeated toggles cannot duplicate history. We also implemented compound B-tree indexes on `(habit_id, date)` so that 30-day analytics and heatmaps query with sub-millisecond latency on-device."*

### Q3: How do background reminders work when the app is killed or device is in Doze mode?
> **Answer:** *"We use Android WorkManager with Flutter's `@pragma('vm:entry-point')` callback dispatcher. Every 3 hours, WorkManager spawns an isolated Dart background runtime that independently opens the SQLite database. If a user has a streak $\ge 3$ days and it is past 6 PM with habits remaining, it fires a high-priority local streak defense notification."*

### Q4: How is sensitive API key security handled?
> **Answer:** *"Zero API keys are hardcoded in git. We use `flutter_dotenv` with an unversioned `.env` file. For Android native Google Maps tiles, a custom Kotlin routine in `build.gradle.kts` injects the key into `manifestPlaceholders` at compilation time, ensuring cryptographic isolation."*

### Q5: What behavioral psychology principles did you codify into code?
> **Answer:** *"We codified 4 major principles:
> 1. **Habit Stacking (James Clear):** Pairs a struggling habit (<40% consistency) immediately after an established anchor habit (>75%).
> 2. **Weekend Slump Detector (BJ Fogg):** If Saturday/Sunday completion drops >25%, it prescribes a 75% reduced 'Minimum Viable Habit' to preserve momentum.
> 3. **Circadian Friction Analysis:** Identifies time-of-day willpower depletion.
> 4. **Never Miss Twice Rule:** Elevates yesterday's missed habit to top priority before noon today."*

### Q6: How does the Geofencing proximity calculation work?
> **Answer:** *"We calculate the great-circle distance between the user's live GPS coordinates (`geolocator`) and the habit's pinned venue coordinates using the Haversine trigonometric formula. A 15-minute hysteresis cooldown dictionary prevents notification storms when lingering on the perimeter."*

### Q7: What automated testing did you perform?
> **Answer:** *"We have 12 automated unit and widget test cases executing in `flutter test`. They validate all algorithmic behavioral heuristics, SQLite JSON serialization roundtrips, and widget tree layouts for our Title, Login, Sign Up, and Main Navigation tabs. `flutter analyze` runs with 0 warnings and 0 lints."*

### Q8: What happens if Gemini API quota is exceeded or the user is in airplane mode?
> **Answer:** *"The `GeminiAiService` contains a resilient error-handling block. If the HTTP request fails, times out, or has no network connection, it immediately catches the exception and falls back to our deterministic on-device Behavioral Heuristics Engine. The user receives immediate guidance without seeing a spinning loader or crash."*

### Q9: Why use `SharedPreferences` if you already have SQLite?
> **Answer:** *"SQLite is ideal for relational, multi-record data like habits, daily logs, and timestamps. `SharedPreferences` is a lightweight key-value store optimized for synchronous session bootstrapping (e.g. `is_logged_in`, `user_name`, `is_guest`), enabling the app to display the correct home screen on frame 1 without executing database queries."*

### Q10: How is the app accessible for senior citizens (ages 60 to 80)?
> **Answer:** *"We followed WCAG guidelines: high contrast text ratios, minimum touch targets of $48 \times 48\text{ dp}$, password show/hide eye toggles to prevent typing frustration, scrollable forms that never overflow regardless of system font scaling, and a single-tap 'Continue as Guest' button for zero-barrier access."*

---
*Ready for Monday 27/10/26 Presentation & Viva!*
