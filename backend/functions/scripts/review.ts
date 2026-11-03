/**
 * Editor review from the command line, until the admin panel is built.
 * Uses your Google credentials (`gcloud auth application-default login`)
 * and the project in GCLOUD_PROJECT (or `firebase use`).
 *
 *   npm run review -- list                       drafts waiting for review
 *   npm run review -- show <id>                  print one draft
 *   npm run review -- publish <id> [edits.json]  approve (optionally with corrections)
 *   npm run review -- reject <id> "<reason>"     drop it
 */
import { readFileSync } from 'node:fs';
import { initializeApp } from 'firebase-admin/app';
import { Store } from '../src/store';

type Bi = { en?: string; hi?: string } | undefined;

async function main() {
  const [cmd, id, arg] = process.argv.slice(2);
  initializeApp();
  const store = new Store();
  const editor = `cli:${process.env.USER ?? 'editor'}`;

  switch (cmd) {
    case 'list': {
      const drafts = await store.listDrafts();
      if (drafts.length === 0) return console.log('No drafts waiting.');
      for (const d of drafts) {
        const cov = d.coverage as { trendingScore?: number; outlets?: string[] } | undefined;
        console.log(`${d.id}  [${String(d.category)}]  score ${cov?.trendingScore?.toFixed(2) ?? '-'}  ${(d.headline as Bi)?.en ?? ''}`);
      }
      return;
    }
    case 'show': {
      need(id, 'show <id>');
      console.log(JSON.stringify(await store.getArticle(id), null, 2));
      return;
    }
    case 'publish': {
      need(id, 'publish <id> [edits.json]');
      const edits = arg ? JSON.parse(readFileSync(arg, 'utf8')) : undefined;
      console.log(await store.publishArticle(id, edits, editor));
      return;
    }
    case 'reject': {
      need(id, 'reject <id> "<reason>"');
      console.log(await store.rejectArticle(id, arg, editor));
      return;
    }
    default:
      console.log('Usage: npm run review -- list | show <id> | publish <id> [edits.json] | reject <id> "<reason>"');
      process.exit(cmd ? 1 : 0);
  }
}

function need(v: string | undefined, usage: string): asserts v is string {
  if (!v) {
    console.error(`Usage: npm run review -- ${usage}`);
    process.exit(1);
  }
}

main().catch((err) => {
  console.error(err.message ?? err);
  process.exit(1);
});
