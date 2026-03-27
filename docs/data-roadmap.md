# Data Roadmap

The app now persists the production-relevant onboarding and profile core:

- `profiles`
- `goalSettings`
- `nutritionPlans`
- `appPreferences`
- `weightEntries`

This is intentionally not the full nutrition-tracking schema yet.

## Add Very Soon

- `diaryDays`
  - one row per calendar day to anchor food, water, and future daily summaries
- `trackedFoods`
  - food log entries tied to a diary day, timestamp, meal category, quantity, and product reference
- `productDetails`
  - cached product metadata and nutriments for scanned or searched foods
- `trackedWater`
  - daily or event-based water intake entries

## Why This Is Deferred

- onboarding, profile, goal, and plan persistence needed to be production-shaped first
- food logging adds a second domain slice with different query and indexing needs
- it is better to add diary and product tables once the logging UX and entry flow are defined

## Constraints For The Next Iteration

- keep using `sqlite-data` and explicit migrations
- store user-entered facts separately from derived plan outputs
- prefer history tables for time-series data such as weight and food logs
- add indexes for diary date lookups and foreign keys when the logging tables are introduced
