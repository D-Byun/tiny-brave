import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from "@firebase/rules-unit-testing";
import { doc, getDoc, serverTimestamp, setDoc, Timestamp, updateDoc } from "firebase/firestore";
import { afterAll, beforeAll, describe, it } from "vitest";

let env: RulesTestEnvironment;
let n = 0;
const fresh = (name: string) => `${name}${Date.now()}x${n++}`;
const inDays = (days: number) => Timestamp.fromMillis(Date.now() + days * 86_400_000);

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: "demo-tinybrave",
    firestore: { rules: readFileSync(resolve(import.meta.dirname, "../../firestore.rules"), "utf8") },
  });
});

afterAll(async () => {
  await env.cleanup();
});

const social = (uid: string) => env.authenticatedContext(uid, { social: true }).firestore();
const plain = (uid: string) => env.authenticatedContext(uid).firestore();
const profile = { nickname: "Mia", count: 3, streak: 2 };

async function seed(path: string, data: Record<string, unknown>) {
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), path), data);
  });
}

describe("profiles", () => {
  it("lets a social user write a valid profile", async () => {
    const uid = fresh("u");
    await assertSucceeds(setDoc(doc(social(uid), `users/${uid}`), { ...profile, tz: "America/Chicago", pushes: true, updatedAt: serverTimestamp() }));
    await assertSucceeds(getDoc(doc(social(uid), `users/${uid}`)));
  });

  it("accepts nicknames in any alphabet", async () => {
    const uid = fresh("u");
    await assertSucceeds(setDoc(doc(social(uid), `users/${uid}`), { ...profile, nickname: "지민 Zoë 7" }));
  });

  it("blocks accounts without the social claim", async () => {
    const uid = fresh("u");
    await assertFails(setDoc(doc(plain(uid), `users/${uid}`), profile));
    await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), `users/${uid}`), profile));
  });

  it("rejects bad fields", async () => {
    const uid = fresh("u");
    const ref = doc(social(uid), `users/${uid}`);
    await assertFails(setDoc(ref, { ...profile, nickname: "<script>" }));
    await assertFails(setDoc(ref, { ...profile, nickname: "thirteen char" }));
    await assertFails(setDoc(ref, { ...profile, nickname: "" }));
    await assertFails(setDoc(ref, { ...profile, count: 31 }));
    await assertFails(setDoc(ref, { ...profile, count: 2.5 }));
    await assertFails(setDoc(ref, { ...profile, realName: "Mia Smith" }));
  });

  it("hides other people's profiles", async () => {
    const [a, b] = [fresh("a"), fresh("b")];
    await seed(`users/${b}`, profile);
    await assertFails(getDoc(doc(social(a), `users/${b}`)));
    await assertFails(setDoc(doc(social(a), `users/${b}`), profile));
  });
});

describe("server-only data", () => {
  it("never exposes codes or private docs", async () => {
    const uid = fresh("u");
    await seed("codes/ABCDEF", { uid });
    await seed(`private/${uid}`, { code: "ABCDEF" });
    await assertFails(getDoc(doc(social(uid), "codes/ABCDEF")));
    await assertFails(getDoc(doc(social(uid), `private/${uid}`)));
    await assertFails(setDoc(doc(social(uid), "codes/ZZZZZZ"), { uid }));
  });

  it("only lets you read, not write, friends, requests and feed", async () => {
    const [a, b] = [fresh("a"), fresh("b")];
    await seed(`users/${a}/friends/${b}`, { ...profile, muted: false });
    await seed(`users/${a}/requests/${b}`, { fromUid: b, nickname: "Bo" });
    await seed(`users/${a}/feed/p1`, { ownerUid: b, message: "tinyTask" });
    const db = social(a);
    await assertSucceeds(getDoc(doc(db, `users/${a}/friends/${b}`)));
    await assertSucceeds(getDoc(doc(db, `users/${a}/requests/${b}`)));
    await assertSucceeds(getDoc(doc(db, `users/${a}/feed/p1`)));
    await assertFails(setDoc(doc(db, `users/${a}/friends/${fresh("x")}`), profile));
    await assertFails(setDoc(doc(db, `users/${b}/requests/${a}`), { fromUid: a, nickname: "Al" }));
    await assertFails(setDoc(doc(db, `users/${a}/feed/p2`), { ownerUid: a }));
    await assertFails(getDoc(doc(social(b), `users/${a}/feed/p1`)));
  });

  it("lets you mute a friend but change nothing else", async () => {
    const [a, b] = [fresh("a"), fresh("b")];
    await seed(`users/${a}/friends/${b}`, { ...profile, muted: false });
    const ref = doc(social(a), `users/${a}/friends/${b}`);
    await assertSucceeds(updateDoc(ref, { muted: true }));
    await assertFails(updateDoc(ref, { count: 30 }));
    await assertFails(updateDoc(ref, { muted: "yes" }));
  });
});

describe("posts", () => {
  const post = () => ({ message: "tinyTask", stage: 4, createdAt: serverTimestamp(), expireAt: inDays(30) });

  it("accepts a preset post", async () => {
    const uid = fresh("u");
    await assertSucceeds(setDoc(doc(social(uid), `users/${uid}/posts/${fresh("p")}`), post()));
  });

  it("rejects free text, bad stages, old timestamps and long expiry", async () => {
    const uid = fresh("u");
    const ref = () => doc(social(uid), `users/${uid}/posts/${fresh("p")}`);
    await assertFails(setDoc(ref(), { ...post(), message: "hi everyone" }));
    await assertFails(setDoc(ref(), { ...post(), stage: 0 }));
    await assertFails(setDoc(ref(), { ...post(), createdAt: Timestamp.fromMillis(0) }));
    await assertFails(setDoc(ref(), { ...post(), expireAt: inDays(400) }));
    await assertFails(setDoc(ref(), { ...post(), text: "extra" }));
    await assertFails(setDoc(doc(plain(uid), `users/${uid}/posts/${fresh("p")}`), post()));
  });

  it("won't post as someone else", async () => {
    const [a, b] = [fresh("a"), fresh("b")];
    await assertFails(setDoc(doc(social(a), `users/${b}/posts/${fresh("p")}`), post()));
  });
});

describe("reactions", () => {
  const reaction = (emoji = "balloon") => ({ emoji, expireAt: inDays(30) });

  it("lets friends react once, change it and take it back", async () => {
    const [owner, friend] = [fresh("o"), fresh("f")];
    await seed(`users/${owner}/friends/${friend}`, profile);
    const ref = doc(social(friend), `users/${owner}/posts/p1/reactions/${friend}`);
    await assertSucceeds(setDoc(ref, reaction()));
    await assertSucceeds(setDoc(ref, reaction("heart")));
    await assertSucceeds(getDoc(ref));
  });

  it("rejects strangers, yourself, impostors and unknown emoji", async () => {
    const [owner, friend, stranger] = [fresh("o"), fresh("f"), fresh("s")];
    await seed(`users/${owner}/friends/${friend}`, profile);
    await assertFails(setDoc(doc(social(stranger), `users/${owner}/posts/p1/reactions/${stranger}`), reaction()));
    await assertFails(setDoc(doc(social(owner), `users/${owner}/posts/p1/reactions/${owner}`), reaction()));
    await assertFails(setDoc(doc(social(stranger), `users/${owner}/posts/p1/reactions/${friend}`), reaction()));
    await assertFails(setDoc(doc(social(friend), `users/${owner}/posts/p1/reactions/${friend}`), reaction("thumbsDown")));
    await assertFails(setDoc(doc(plain(friend), `users/${owner}/posts/p1/reactions/${friend}`), reaction()));
  });
});

describe("devices", () => {
  it("registers and removes your own push token only", async () => {
    const [a, b] = [fresh("a"), fresh("b")];
    const token = "fcm:token-123_abc";
    await assertSucceeds(setDoc(doc(social(a), `users/${a}/devices/${token}`), { platform: "ios", updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(social(b), `users/${a}/devices/other`), { platform: "ios", updatedAt: serverTimestamp() }));
    await assertFails(setDoc(doc(social(a), `users/${a}/devices/x`), { platform: "android", updatedAt: serverTimestamp() }));
  });
});
