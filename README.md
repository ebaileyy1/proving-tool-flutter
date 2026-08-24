# Prove It

Aviation Business Continuity Ltd's internal app for logging, tracking, and
reporting on operational trials — built with Flutter, currently backed by
Supabase.

## Features

- Create, edit, and duplicate trials (type, terminal, status, dates, attendees)
- Attach drawings and evidence — camera capture or existing files
- Observations and replies on each trial
- Dashboard with filters, charts, and a "Today / This Week" view of upcoming
  trials with a quick outcome-entry prompt
- PDF export per trial, CSV export of the filtered trial list
- Works fully offline — trials created or edited with no connection sync
  automatically once back online
- Admin screen for managing user accounts

## Getting started

```bash
flutter pub get
flutter run -d windows   # or -d chrome, an Android device, etc.
```

Offline support uses [drift](https://drift.simonbinder.eu/) for local
storage, so the first run also needs code generation:

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Project layout

- `lib/screens/` — one folder per feature area (auth, trials, dashboard, admin, ...)
- `lib/services/` — Supabase access, the offline outbox/sync engine, connectivity
- `lib/widgets/` — shared UI (trial form, section headers, sync status banner, ...)
- `lib/theme/app_colors.dart` — the app's single color palette
- `store-listing/` — drafts for the Play Store listing and privacy policy
