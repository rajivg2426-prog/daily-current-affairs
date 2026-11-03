import { getFirestore, FieldValue, Timestamp, type Firestore } from 'firebase-admin/firestore';
import type { SourceItem, StoryCluster } from './core/types';
import type { Draft } from './ai/schema';
import type { SourceRun } from './pipeline';
import { planPublish, planReject } from './review';

/**
 * Firestore layout written by the pipeline (all server-only; clients never
 * read these directly):
 *
 *   ingestState/sources              { lastRun: {sourceId: iso}, lastRuns: SourceRun[] }
 *   sourceItems/{sha1(url)}          SourceItem (+ createdAt)  -- discovery items have no text
 *   storyClusters/{clusterId}        StoryCluster (+ draftedArticleId)
 *   articles/{autoId}                status "draft", aiGenerated true  -> editor reviews in admin
 *                                    -> "published" (app reads) or "rejected"
 *   quizKeys/{articleId}             answers, written on publish (server-only)
 */
export class Store {
  constructor(private db: Firestore = getFirestore()) {}

  async lastRuns(): Promise<Record<string, string>> {
    const snap = await this.db.doc('ingestState/sources').get();
    return (snap.get('lastRun') as Record<string, string>) ?? {};
  }

  async recordRuns(runs: SourceRun[], at: Date): Promise<void> {
    const lastRun: Record<string, string> = {};
    for (const r of runs) if (r.ok) lastRun[r.sourceId] = at.toISOString();
    await this.db.doc('ingestState/sources').set({ lastRun, lastRuns: runs, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  }

  /** Inserts new items; existing ones are left untouched (first-seen time is kept). */
  async saveItems(items: SourceItem[]): Promise<number> {
    let created = 0;
    for (let i = 0; i < items.length; i += 400) {
      const chunk = items.slice(i, i + 400);
      const refs = chunk.map((it) => this.db.collection('sourceItems').doc(it.id));
      const existing = await this.db.getAll(...refs);
      const batch = this.db.batch();
      existing.forEach((snap, j) => {
        if (snap.exists) return;
        batch.set(refs[j], { ...chunk[j], createdAt: FieldValue.serverTimestamp() });
        created++;
      });
      await batch.commit();
    }
    return created;
  }

  async recentItems(hours = 36): Promise<SourceItem[]> {
    const since = new Date(Date.now() - hours * 3_600_000).toISOString();
    const snap = await this.db.collection('sourceItems').where('publishedAt', '>=', since).limit(5000).get();
    return snap.docs.map((d) => d.data() as SourceItem);
  }

  async itemsByIds(ids: string[]): Promise<SourceItem[]> {
    if (ids.length === 0) return [];
    const snaps = await this.db.getAll(...ids.map((id) => this.db.collection('sourceItems').doc(id)));
    return snaps.filter((s) => s.exists).map((s) => s.data() as SourceItem);
  }

  async saveClusters(clusters: StoryCluster[]): Promise<void> {
    for (let i = 0; i < clusters.length; i += 400) {
      const batch = this.db.batch();
      for (const c of clusters.slice(i, i + 400)) {
        batch.set(this.db.collection('storyClusters').doc(c.id), { ...c, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
      }
      await batch.commit();
    }
  }

  /** Top draftable clusters that don't have a draft yet. */
  async clustersToDraft(limit: number, minScore: number): Promise<StoryCluster[]> {
    const snap = await this.db
      .collection('storyClusters')
      .where('draftable', '==', true)
      .orderBy('trendingScore', 'desc')
      .limit(limit * 4)
      .get();
    return snap.docs
      .map((d) => d.data() as StoryCluster & { draftedArticleId?: string; draftFailedReason?: string })
      .filter((c) => !c.draftedArticleId && !c.draftFailedReason && c.trendingScore >= minScore)
      .slice(0, limit);
  }

  async saveDraft(cluster: StoryCluster, draft: Draft, contentItems: SourceItem[]): Promise<string> {
    const lead = contentItems[0];
    const ref = this.db.collection('articles').doc();
    await ref.set({
      status: 'draft',
      aiGenerated: true,
      clusterId: cluster.id,
      headline: draft.headline,
      summary: draft.summary,
      keyPoints: draft.keyPoints,
      body: draft.body,
      whyImportant: draft.whyImportant,
      category: draft.category,
      examTags: draft.examTags,
      relevance: draft.relevance,
      syllabus: draft.syllabus,
      draftFacts: draft.facts,
      draftMcqs: draft.mcqs,              // split into questions + quizKeys on publish
      source: { name: lead.sourceName, url: lead.url, attribution: lead.attribution },
      sources: contentItems.map((i) => ({ name: i.sourceName, url: i.url, attribution: i.attribution })),
      coverage: { outlets: cluster.discoveryOutlets, trendingScore: cluster.trendingScore },
      publishDate: null,
      createdAt: FieldValue.serverTimestamp(),
      reviewBy: Timestamp.fromDate(new Date(Date.now() + 6 * 3_600_000)),
    });
    await this.db.collection('storyClusters').doc(cluster.id).set({ draftedArticleId: ref.id }, { merge: true });
    return ref.id;
  }

  async markDraftFailed(clusterId: string, reason: string): Promise<void> {
    await this.db.collection('storyClusters').doc(clusterId).set({ draftFailedReason: reason }, { merge: true });
  }

  /** Drafts waiting for an editor, oldest first (the review queue). */
  async listDrafts(limit = 50): Promise<Array<{ id: string } & Record<string, unknown>>> {
    const snap = await this.db.collection('articles').where('status', '==', 'draft').orderBy('createdAt', 'desc').limit(limit).get();
    return snap.docs.map((d) => ({ id: d.id, ...d.data() })).reverse();
  }

  async getArticle(id: string): Promise<Record<string, unknown> | undefined> {
    const snap = await this.db.collection('articles').doc(id).get();
    return snap.exists ? snap.data() : undefined;
  }

  /** Editor approves a draft: validated, moved to "published", answers copied to quizKeys. */
  async publishArticle(id: string, edits: unknown, editor: string, now = new Date()): Promise<{ id: string; status: 'published' }> {
    const ref = this.db.collection('articles').doc(id);
    await this.db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const plan = planPublish(id, snap.exists ? snap.data() : undefined, edits, editor, now);
      const update: Record<string, unknown> = { ...plan.article, updatedAt: FieldValue.serverTimestamp() };
      for (const f of plan.remove) update[f] = FieldValue.delete();
      tx.update(ref, update);
      tx.set(this.db.collection('quizKeys').doc(id), plan.quizKey);
    });
    return { id, status: 'published' };
  }

  /** Editor rejects a draft. The story cluster keeps its draft link, so it isn't drafted again. */
  async rejectArticle(id: string, reason: unknown, editor: string, now = new Date()): Promise<{ id: string; status: 'rejected' }> {
    const ref = this.db.collection('articles').doc(id);
    await this.db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const update = planReject(id, snap.exists ? snap.data() : undefined, reason, editor, now);
      tx.update(ref, { ...update, updatedAt: FieldValue.serverTimestamp() });
    });
    return { id, status: 'rejected' };
  }
}
