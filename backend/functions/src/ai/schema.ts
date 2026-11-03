import { z } from 'zod';

const Bi = z.object({ en: z.string().min(1), hi: z.string().min(1) });
const BiList = z.object({ en: z.array(z.string().min(1)).min(1), hi: z.array(z.string().min(1)).min(1) });

export const CATEGORIES = [
  'national', 'international', 'economy', 'scitech', 'environment',
  'awards', 'sports', 'schemes', 'defence', 'books', 'days',
] as const;
export const EXAMS = ['upsc', 'ssc', 'banking', 'railway', 'defence', 'statepsc'] as const;

export const Mcq = z
  .object({
    question: Bi,
    options: z.object({ en: z.array(z.string().min(1)).length(4), hi: z.array(z.string().min(1)).length(4) }),
    answerIndex: z.number().int().min(0).max(3),
    explanation: Bi,
    difficulty: z.number().int().min(1).max(5),
  })
  .refine((q) => new Set(q.options.en.map((o) => o.trim().toLowerCase())).size === 4, {
    message: 'MCQ options must be distinct',
  });

export const Draft = z.object({
  insufficient: z.literal(false).optional(),
  headline: Bi,
  summary: Bi,
  keyPoints: BiList,
  body: Bi,
  whyImportant: Bi,
  category: z.enum(CATEGORIES),
  examTags: z.array(z.enum(EXAMS)).min(1),
  relevance: z.enum(['prelims', 'mains', 'both']),
  syllabus: z.string().min(2),
  facts: z.array(Bi).max(6),
  mcqs: z.array(Mcq).min(1).max(5),
});
export type Draft = z.infer<typeof Draft>;

export const Insufficient = z.object({ insufficient: z.literal(true), reason: z.string() });

export const DraftOrInsufficient = z.union([Insufficient, Draft]);
