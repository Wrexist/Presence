//  Presence backend
//  matchingService.ts
//  Generates icebreakers via the Anthropic SDK. No PII ever leaves this file —
//  callers anonymize before invoking. Falls back to a hardcoded library if
//  the API is disabled, slow, or returns something malformed.

import Anthropic from "@anthropic-ai/sdk";
import { z } from "zod";
import { config, featureFlags } from "../config.js";

// MARK: - Request shape (mirrors CLAUDE.md § AI Integration)

export const IcebreakerRequestSchema = z.object({
  venue: z.object({
    name: z.string().min(1).max(120),
    type: z.enum(["cafe", "park", "gym", "library", "bar", "coworking", "other"]),
    vibe: z.enum(["quiet", "social", "working", "active"])
  }),
  timeContext: z.object({
    hour: z.number().int().min(0).max(23),
    dayOfWeek: z.enum([
      "monday", "tuesday", "wednesday", "thursday", "friday", "saturday", "sunday"
    ]),
    isWeekend: z.boolean()
  }),
  userA: z.object({
    bio: z.string().min(1).max(60),
    connectionCount: z.number().int().nonnegative()
  }),
  userB: z.object({
    bio: z.string().min(1).max(60),
    connectionCount: z.number().int().nonnegative()
  })
});

export type IcebreakerRequest = z.infer<typeof IcebreakerRequestSchema>;

// MARK: - Anthropic client (lazy so tests can run without a key)

let anthropic: Anthropic | null = null;
function getAnthropic(): Anthropic {
  if (!anthropic) {
    anthropic = new Anthropic({ apiKey: config.ANTHROPIC_API_KEY });
  }
  return anthropic;
}

// MARK: - Prompt

const SYSTEM_PROMPT = `You are the icebreaker engine for Presence, an app that connects strangers in real life.
Generate ONE perfect conversation starter for two people who are about to meet.

Rules:
- Maximum 2 sentences
- Warm, not creepy — like something a mutual friend would say
- Specific to the context provided (venue, time, user bios)
- Never romantic or flirtatious
- Never reference the app or AI
- Should feel like it came from local knowledge, not an algorithm
- End with an open question when possible

Output: Only the icebreaker text. Nothing else.`;

function buildUserPrompt(req: IcebreakerRequest): string {
  const { venue, timeContext, userA, userB } = req;
  return [
    `Venue: ${venue.name} (${venue.type}, ${venue.vibe} vibe)`,
    `Time: ${timeContext.dayOfWeek} ${timeContext.hour}:00${timeContext.isWeekend ? " (weekend)" : ""}`,
    `Person A: "${userA.bio}" (${userA.connectionCount} prior connections)`,
    `Person B: "${userB.bio}" (${userB.connectionCount} prior connections)`
  ].join("\n");
}

// MARK: - Validation and fallbacks

const MIN_LEN = 20;
const MAX_LEN = 200;

function isUsable(text: string): boolean {
  const trimmed = text.trim();
  if (trimmed.length < MIN_LEN || trimmed.length > MAX_LEN) return false;
  // Quick heuristic to catch AI mentions that slipped through the system prompt.
  if (/\b(ai|assistant|language model|presence app)\b/i.test(trimmed)) return false;
  return true;
}

const FALLBACKS: Record<IcebreakerRequest["venue"]["type"], string[]> = {
  cafe: [
    "This place has the best oat milk for miles — have you tried their afternoon special yet?",
    "I always come here to recover from mornings — any idea what they do to their coffee?"
  ],
  park: [
    "Prime golden-hour park light right now — do you run this loop often?",
    "This bench has the best view for sunset. Local favourite?"
  ],
  gym: [
    "That's a solid routine — are you training for something specific?",
    "Tuesday morning might be the best time in here. You always come this early?"
  ],
  library: [
    "This corner has the best quiet. Regular spot?",
    "That book made the rounds in my group last month — is it worth the hype?"
  ],
  bar: [
    "The playlist here always surprises me — do you know what they're playing tonight?",
    "This place has the best small plates in the area. First time?"
  ],
  coworking: [
    "Monday mornings feel different here. You been a member long?",
    "The quiet room here is unreal. What do you usually work on?"
  ],
  other: [
    "I always wonder what brings people here on a day like this. What's your story?",
    "This time of day has such a specific feel. You come here often?"
  ]
};

function pickFallback(req: IcebreakerRequest): string {
  const pool = FALLBACKS[req.venue.type] ?? FALLBACKS.other;
  // Deterministic: hash venue name into the pool so the same pair at the same
  // venue sees the same fallback line. Avoids flicker across retries.
  let h = 0;
  for (const ch of req.venue.name) h = (h * 31 + ch.charCodeAt(0)) | 0;
  return pool[Math.abs(h) % pool.length]!;
}

// MARK: - Public API

export interface IcebreakerResult {
  icebreaker: string;
  source: "claude" | "fallback";
}

export async function generateIcebreaker(req: IcebreakerRequest): Promise<IcebreakerResult> {
  if (!featureFlags.anthropicEnabled) {
    return { icebreaker: pickFallback(req), source: "fallback" };
  }

  try {
    const response = await getAnthropic().messages.create({
      model: "claude-opus-4-7",
      max_tokens: 200,
      // No sampling params — temperature/top_p/top_k are removed on Opus 4.7.
      // No extended thinking — icebreakers are short creative output, not reasoning.
      thinking: { type: "disabled" },
      system: [
        {
          type: "text",
          text: SYSTEM_PROMPT,
          // Marker is harmless at ~300 chars (won't trigger caching below the
          // 4096-token floor on Opus 4.7) but future-proofs this call site —
          // when we add a fallback library or examples to the system prompt
          // and cross the threshold, caching kicks in automatically.
          cache_control: { type: "ephemeral" }
        }
      ],
      messages: [{ role: "user", content: buildUserPrompt(req) }]
    });

    const textBlock = response.content.find((b) => b.type === "text");
    const text = textBlock?.type === "text" ? textBlock.text.trim() : "";

    if (!isUsable(text)) {
      return { icebreaker: pickFallback(req), source: "fallback" };
    }
    return { icebreaker: text, source: "claude" };
  } catch {
    return { icebreaker: pickFallback(req), source: "fallback" };
  }
}
