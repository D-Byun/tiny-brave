import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp, type DocumentData } from "firebase-admin/firestore";
import { setGlobalOptions } from "firebase-functions/v2";
import { HttpsError, type CallableRequest } from "firebase-functions/v2/https";

// Firestore lives in us-central1; triggers must run in the same region. Set here because every module imports this first.
setGlobalOptions({ region: "us-central1", memory: "256MiB", maxInstances: 5 });
initializeApp();
export const db = getFirestore();

/** Friends per person, not counting you. */
export const CIRCLE_MAX = 6;
export const CODE_LETTERS = "ABCDEFGHJKLMNPQRSTUVWXYZ";
export const CODE_LOOKUPS_PER_DAY = 20;
export const PUSHES_PER_DAY = 10;
export const FEED_DAYS = 30;
export const REQUEST_DAYS = 14;
export const QUIET_START_HOUR = 21;
export const QUIET_END_HOUR = 7;

/** Mirrors `PingMessage` in the app. Posts only ever carry one of these IDs. */
export const MESSAGES: Record<string, string> = {
  lookAtYou: "look at you.",
  tinyTask: "tiny task. real puff.",
  courageLouder: "courage got louder.",
  balloonSaw: "balloon definitely saw that.",
  fearInconvenienced: "fear found this inconvenient.",
  allThirty: "thirty. whole. braves.",
};

/** Mirrors `Reaction` in the app. */
export const REACTIONS: Record<string, string> = {
  balloon: "🎈",
  clap: "👏",
  strong: "💪",
  fire: "🔥",
  heart: "🫶",
  star: "⭐",
};

export const AGE_BANDS = ["under13", "13to15", "16plus"] as const;
export type AgeBand = (typeof AGE_BANDS)[number];

export const paths = {
  user: (uid: string) => db.doc(`users/${uid}`),
  private: (uid: string) => db.doc(`private/${uid}`),
  code: (code: string) => db.doc(`codes/${code}`),
  friends: (uid: string) => db.collection(`users/${uid}/friends`),
  friend: (uid: string, friendUid: string) => db.doc(`users/${uid}/friends/${friendUid}`),
  request: (to: string, from: string) => db.doc(`users/${to}/requests/${from}`),
  block: (uid: string, other: string) => db.doc(`users/${uid}/blocks/${other}`),
  feed: (uid: string) => db.collection(`users/${uid}/feed`),
  posts: (uid: string) => db.collection(`users/${uid}/posts`),
  devices: (uid: string) => db.collection(`users/${uid}/devices`),
};

export function daysFromNow(days: number, from = Date.now()): Timestamp {
  return Timestamp.fromMillis(from + days * 24 * 60 * 60 * 1000);
}

/** UTC calendar day, used to reset per-day counters. */
export function dayKey(at = new Date()): string {
  return at.toISOString().slice(0, 10);
}

/** Signed-in caller who has passed the age check (and, under 13, parent consent). */
export function requireSocial(request: CallableRequest): string {
  const auth = request.auth;
  if (!auth) throw new HttpsError("unauthenticated", "Sign in first.");
  if (auth.token.social !== true) throw new HttpsError("permission-denied", "Circles aren't turned on for this account.");
  return auth.uid;
}

export function requireUid(value: unknown, field = "uid"): string {
  if (typeof value !== "string" || !/^[A-Za-z0-9]{1,128}$/.test(value)) {
    throw new HttpsError("invalid-argument", `${field} is missing or malformed.`);
  }
  return value;
}

export interface Profile {
  nickname: string;
  count: number;
  streak: number;
}

export function profileOf(data: DocumentData | undefined): Profile {
  return {
    nickname: typeof data?.nickname === "string" ? data.nickname : "friend",
    count: typeof data?.count === "number" ? data.count : 0,
    streak: typeof data?.streak === "number" ? data.streak : 0,
  };
}

export function makeCode(random: () => number = Math.random): string {
  return Array.from({ length: 6 }, () => CODE_LETTERS[Math.floor(random() * CODE_LETTERS.length)]).join("");
}

/** True when `now` falls in the recipient's night-time quiet hours. Unknown time zones are never quiet. */
export function isQuietHour(timeZone: unknown, now = new Date()): boolean {
  if (typeof timeZone !== "string") return false;
  try {
    const hour = Number(new Intl.DateTimeFormat("en-US", { timeZone, hour: "numeric", hourCycle: "h23" }).format(now));
    return hour >= QUIET_START_HOUR || hour < QUIET_END_HOUR;
  } catch {
    return false;
  }
}
