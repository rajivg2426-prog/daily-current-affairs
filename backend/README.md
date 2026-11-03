# Daily Current Affairs: free-source ingestion

Cloud Functions that pull news from free sources every 30 minutes, group the same story across outlets, rank what's trending, and write bilingual exam-ready **drafts** for an editor to approve.

## How it works

```
every 30 min   ingestSources
  ├─ CONTENT sources (text kept, may be summarised)
  │    PIB (English + Hindi RSS) · RBI press releases + notifications (RSS)
  │    PRS monthly policy reviews + bill tracker (listing pages, CC BY 4.0)
  │    PB-SHABD (admin upload, after media registration)
  ├─ DISCOVERY sources (headline + link only, never stored or shown)
  │    GDELT (India, keyless API) · Google News India RSS
  │    The Hindu · Indian Express · Hindustan Times · TOI · Mint · News On AIR (RSS)
  ├─ normalise → categorise (11 categories) → exam tags
  ├─ cluster the same story across sources (title similarity, 36 h window)
  └─ trending score = outlets covering it + official source + exam weight, 12 h half-life

:15 and :45    draftStories
  ├─ top clusters that have an official (content) source
  ├─ fetch report text for PRS items
  ├─ Claude writes EN + HI: summary, key points, body, why-it-matters, facts, 1–5 MCQs
  ├─ strict validation (4 distinct options, one answer, both languages)
  └─ saved to articles/{id} with status "draft" → editor approves in admin
```

Stories found only in newspapers (no official source) are never drafted. They show in the admin "Story radar" so an editor can look for the PIB/ministry release.

## Run it locally

```bash
cd functions
npm install
npm test                       # 39 tests, all offline
npm run ingest:fixtures        # whole pipeline on sample feeds
npm run ingest:live            # real feeds from your machine (checks every url)
ANTHROPIC_API_KEY=sk-... npm run ingest:live -- --draft   # also drafts the top story
```

Run `ingest:live` first. Any source that prints `FAILED` needs its url or selector fixed in `src/config/sources.ts`.

## Deploy

```bash
npm i -g firebase-tools
firebase login
firebase use <your-project-id>
firebase functions:secrets:set ANTHROPIC_API_KEY
firebase deploy --only functions:ingestion,firestore
```

Functions deploy to `asia-south1` (Mumbai). Cloud Scheduler requires the Blaze (pay-as-you-go) plan; at this volume it stays within the free allowances.

Editors need the custom claim `role: "editor"` (or `"super"`) to call `ingestNow` and `importPbShabdStories`.

## Admin calls

| Callable | Input | Does |
|---|---|---|
| `ingestNow` | none | Fetch every source now |
| `importPbShabdStories` | `[{headline, body, storyId?, url?, date?, language: "en"\|"hi", category?}]` | Adds PB-SHABD stories as content items |

## Firestore written

| Collection | Contents | Who reads |
|---|---|---|
| `sourceItems/{sha1(url)}` | One fetched item; discovery items have no text | Editors |
| `storyClusters/{id}` | Grouped story, outlets, score, draft link | Editors (Story radar) |
| `articles/{id}` | `status: "draft"`, bilingual fields, `draftMcqs`, `source` credit | Editors until published |
| `ingestState/sources` | Last run per source, errors | Editors |

On publish, the admin panel should move `draftMcqs` into `questions` and `quizKeys` (answers stay server-side).

## Before launch

1. Run `npm run ingest:live` and fix any failing url or selector.
2. Fill in `LICENCE_CHECK.md` for every source.
3. Register on PB-SHABD (media organisation; papers within 10 days), then set `enabled: true` for `pb-shabd`.
4. Choose the draft model with the `DRAFT_MODEL` env var (default `claude-haiku-5-5`).
