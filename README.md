# Daily Current Affairs

Daily current affairs, quizzes and revision for UPSC, SSC, Banking, Railway, Defence and State PSC aspirants, in English and Hindi.

| Folder | What it is | Start here |
|---|---|---|
| [`app/`](app/) | Flutter mobile app (Android, iOS, web) | `cd app && flutter create . --platforms android,ios,web && flutter run` |
| [`backend/`](backend/) | Firebase Cloud Functions: free-source news ingestion and AI drafting | `cd backend/functions && npm install && npm test` |

## How the pieces fit

```
Free sources ──▶ backend (every 30 min) ──▶ Firestore "articles" (draft) ──▶ editor approves ──▶ published
  PIB, RBI, PRS, PB-SHABD   (content)                                                              │
  GDELT, Google News, newspaper RSS (trending only)                                                ▼
                                                                                   app (USE_FIREBASE=true)
```

Without Firebase, the app runs on built-in sample content, so you can try every screen straight away.

## Design and spec

- Design canvas: https://claude.ai/artifact/H6pt3ie3DQ4epbhaGWQ2HW
- Product and technical spec: https://claude.ai/artifact/2qBMLgUewysjxNadDvLACe

## Working on it with Claude Code

Open the repo folder in Claude Code and ask, for example:
- "Run the app tests and fix anything that fails"
- "Add Firebase phone OTP sign-in to onboarding"
- "Run `npm run ingest:live` in backend/functions and fix the failing feeds"
