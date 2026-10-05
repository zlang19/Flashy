# Plan

## Goal
Flashy: a personal flashcard iOS app with spaced repetition. Cards are written as markdown in this project's public repo (https://github.com/zlang19/Flashy) and synced into the app.

## Platform & distribution
* Personal use only, installed from Xcode with a free Apple ID (7-day provisioning; rebuild weekly). Never delete the app — that wipes review history.
* SwiftUI + SwiftData, iOS 17+, iPhone only. All state stored locally.
* App icon is `icon.png`.

## Repo layout
```
Flashy/
├── Plan.md
├── icon.png
├── project.yml            # XcodeGen spec; `xcodegen` generates Flashy.xcodeproj (git-ignored)
├── Flashy/                # iOS app: SwiftUI views, SwiftData models, sync, notifications
├── FlashyCore/            # Swift package, Foundation only, so it builds and tests on Linux too
│   ├── Sources/           # scheduler, card parser, repo layout, sync plan, GitHub client, stats
│   └── Tests/             # unit tests; Fixtures/ holds the sample cards
├── flashcards/            # real cards only; the app syncs this subtree
│   └── README.md          # card format spec (ignored by the parser)
└── templates/
    └── card/
        └── flashcard.md   # copy-paste template for new cards
```

## Card format
* A folder that directly contains `flashcard.md` is a **card**. Everything inside it (images, subfolders) belongs to that card; cards cannot contain cards.
* Any other folder under `flashcards/` is a **category**. Categories nest to any depth. A card directly in `flashcards/` is "Uncategorized".
* **Card identity is its folder path** (e.g. `flashcards/bio/cells/mitosis`). Moving or renaming the folder makes it a new card.
* `flashcard.md` structure:
  ```markdown
  ---
  title: Krebs cycle
  tags: [biology]
  ---
  ## Front
  ![](cycle.png)
  What molecule enters the cycle?
  ## Back
  Acetyl-CoA ...
  ```
* Frontmatter is optional. `title` is display-only and may repeat; it falls back to the prettified folder name (`organic_chemistry` → "Organic Chemistry"). Category names are always prettified folder names.
* Images are referenced relatively from the card folder.
* Supported rendering (v1): text, images, lists, bold/italic, inline code. No math or code highlighting.
* Content is read-only in the app; cards are authored in git by copying `templates/card/`.

## Sync
* Runs on app open, plus a manual "Sync now" in Settings.
* Fetch the latest commit SHA on `main` via the GitHub API using an ETag (unchanged → 304, which doesn't count against the rate limit).
* If the SHA changed: fetch the recursive Git Trees listing, compare blob SHAs to the local cache, download only changed files from `raw.githubusercontent.com`. No third-party dependencies.
* Repo URL and branch are hardcoded constants.
* Cards are cached on device; the app works fully offline. A failed sync shows a "last synced X" indicator and never blocks reviewing.
* **Any change** to a card's `flashcard.md` or its images resets it to a new card. Its past review log entries are kept for stats.
* A deleted card is removed from the queue and from Browse, but its record is kept; if the path reappears, its history resumes.
* Malformed cards (missing Front or Back, bad YAML) are skipped and listed under Settings → Sync issues with the file and reason. Broken images render a placeholder.

## Spaced repetition
* New card: first interval 1 day.
* **Good**: interval × 2.5. **Okay**: interval × 1.2 (minimum +1 day). **Bad**: reset to 1 day.
* Maximum interval: 180 days.
* Every review is logged (card, date, rating, resulting interval).

## Daily review
* Daily set = all due cards (most overdue first) + all new cards, shuffled within each group.
* The day rolls over at 4 AM local time.
* Flow: show the front (images and/or text) → "Reveal" (card-flip animation) → show the back → rate Good / Okay / Bad → next card.
* The Good / Okay / Bad buttons appear below the card once it's revealed. Tapping one records the rating and advances; there is no separate "Next" button.
* Cards rated Bad are re-queued at the end of the session until rated Okay or Good. Only the first rating affects the schedule.
* Each rating is saved immediately; quitting mid-session loses nothing.
* At the end of the session, show a summary: cards reviewed and the good/okay/bad breakdown.

## Badge & notifications
* The app badge shows the number of cards in today's set not yet rated, decremented on each card's first rating.
* When the app goes to the background, it schedules badge-only local notifications for each day's 4 AM rollover over the next ~30 days, using the forecast due counts.
* An optional daily reminder alert ("N cards due") at a chosen time is off by default.

## Screens (tab bar)
* **Today**: due count, Start button, review flow, "done for today" state.
* **Browse**: nested folder tree; selecting a folder includes all cards beneath it. Search by title and text. Cards show a breadcrumb (`Bio › Cells › Mitosis`). Practice-only: no rating, no effect on the schedule.
* **Stats**: scrolling dashboard built with Swift Charts, with a range picker (7d / 30d / 1y / all). Only daily-set reviews count.
  * Streak, current and longest. A day counts when the daily set was cleared; a day with nothing due doesn't break the streak.
  * Card maturity donut: new / learning (<21d) / mature (≥21d)
  * Review heatmap calendar
  * Reviews per day, stacked by rating
  * Retention over time (% rated Okay or Good)
  * 30-day due forecast
  * Per-category accuracy, weakest first
* **Settings**: reminder toggle and time, sync status, Sync now, Sync issues.

## Style
* Retro-futuristic synthwave, following the icon. Dark mode only.
* Navy background (~`#14142a`), magenta/violet/blue gradients for surfaces, orange/pink "sun" glow for accents and the Reveal button, faint horizontal scanlines on cards.
* SF Mono for UI chrome (titles, buttons, counters); system font for card content.
* Rating colors: Bad = orange-red, Okay = violet, Good = blue/cyan.
* Charts styled in the same palette.

## Quality
* `flashcards/README.md` documents the card format.
* Unit tests for the scheduler, the markdown/frontmatter parser, repo layout, sync planning, the GitHub client and stats, using the sample cards in `FlashyCore/Tests/FlashyCoreTests/Fixtures/`.
