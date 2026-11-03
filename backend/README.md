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

editor          publishArticle / rejectArticle
  ├─ checks the draft is complete in English and Hindi, has 1–5 valid MCQs and a source link
  ├─ applies any corrections the editor made
  ├─ status "published" + publishDate → the app shows it (USE_FIREBASE=true)
  └─ answers copied to quizKeys/{id} for future server grading
```

Stories found only in newspapers (no official source) are never drafted. They show in the admin "Story radar" so an editor can look for the PIB/ministry release.

## Run it locally

```bash
cd functions
npm install
npm test                       # 46 tests, all offline
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

Editors need the custom claim `role: "editor"` (or `"super"`) to call the admin functions below.

## Admin calls

| Callable | Input | Does |
|---|---|---|
| `ingestNow` | none | Fetch every source now |
| `importPbShabdStories` | `[{headline, body, storyId?, url?, date?, language: "en"\|"hi", category?}]` | Adds PB-SHABD stories as content items |
| `publishArticle` | `{id, edits?}` | Approves a draft. `edits` may correct headline, summary, keyPoints, body, whyImportant, category, examTags, relevance, syllabus, facts or mcqs |
| `rejectArticle` | `{id, reason}` | Drops a draft; it is kept with the reason and not drafted again |

## Reviewing drafts without the admin panel

Until the admin panel exists, editors can review from the command line with their Google credentials:

```bash
gcloud auth application-default login
export GCLOUD_PROJECT=<your-project-id>
npm run review -- list                        # drafts waiting
npm run review -- show <id>                   # full draft as JSON
npm run review -- publish <id> [edits.json]   # approve, optionally with corrections
npm run review -- reject <id> "duplicate"     # drop
```

Status only changes through these functions. Firestore rules let editors fix text in place but not change `status`, so nothing reaches the app without passing the checks.

## Firestore written

| Collection | Contents | Who reads |
|---|---|---|
| `sourceItems/{sha1(url)}` | One fetched item; discovery items have no text | Editors |
| `storyClusters/{id}` | Grouped story, outlets, score, draft link | Editors (Story radar) |
| `articles/{id}` | `status: "draft"`, bilingual fields, `draftMcqs`, `source` credit. On publish: `status: "published"`, `publishDate`, `practice`, `facts`, `review` | Editors while draft; everyone once published |
| `quizKeys/{id}` | Answers for the article's questions | Server only |
| `ingestState/sources` | Last run per source, errors | Editors |

The app grades quizzes on the device in v1, so `practice` keeps `answerIndex`. Once server grading (`/quizzes/submit`) is built, drop it from `practice` and grade against `quizKeys`.

## Before launch

1. Run `npm run ingest:live` and fix any failing url or selector.
2. Fill in `LICENCE_CHECK.md` for every source.
3. Register on PB-SHABD (media organisation; papers within 10 days), then set `enabled: true` for `pb-shabd`.
4. Choose the draft model with the `DRAFT_MODEL` env var (default `claude-haiku-5-5`).
