import { randomInt } from "node:crypto";
import { FieldValue, type Transaction } from "firebase-admin/firestore";
import { HttpsError, onCall, type CallableOptions } from "firebase-functions/v2/https";
import { trySendPush } from "./push.js";
import {
  CIRCLE_MAX,
  CODE_LOOKUPS_PER_DAY,
  REQUEST_DAYS,
  dayKey,
  daysFromNow,
  db,
  makeCode,
  paths,
  profileOf,
  requireSocial,
  requireUid,
} from "./shared.js";

/** Set APP_CHECK_ENFORCED=true in functions/.env once App Attest is registered for the app in Firebase App Check. */
export const callable: CallableOptions = { enforceAppCheck: process.env.APP_CHECK_ENFORCED === "true" };

/** Client-facing failure. `reason` is what the app switches on to pick its message. */
function fail(code: "not-found" | "invalid-argument" | "resource-exhausted" | "failed-precondition", reason: string, message: string): never {
  throw new HttpsError(code, message, { reason });
}

async function allocateCode(uid: string, replace: boolean): Promise<string> {
  for (let attempt = 0; attempt < 8; attempt++) {
    const candidate = makeCode(() => randomInt(0, 1_000_000) / 1_000_000);
    const code = await db.runTransaction(async (tx) => {
      const priv = await tx.get(paths.private(uid));
      const current = priv.get("code") as string | undefined;
      if (current && !replace) return current;
      if ((await tx.get(paths.code(candidate))).exists) return null;
      if (current) tx.delete(paths.code(current));
      tx.create(paths.code(candidate), { uid, createdAt: FieldValue.serverTimestamp() });
      tx.set(paths.private(uid), { code: candidate }, { merge: true });
      return candidate;
    });
    if (code) return code;
  }
  throw new HttpsError("unavailable", "Couldn't make a code. Try again.");
}

/** Your personal circle code, created the first time you ask. */
export const myCode = onCall(callable, async (request) => {
  const uid = requireSocial(request);
  return { code: await allocateCode(uid, false) };
});

/** Swaps your code for a new one so an old, overshared code stops working. */
export const resetCode = onCall(callable, async (request) => {
  const uid = requireSocial(request);
  return { code: await allocateCode(uid, true) };
});

async function takeLookup(uid: string): Promise<void> {
  const allowed = await db.runTransaction(async (tx) => {
    const ref = paths.private(uid);
    const lookups = (await tx.get(ref)).get("lookups") as { day?: string; n?: number } | undefined;
    const today = dayKey();
    const used = lookups?.day === today ? (lookups.n ?? 0) : 0;
    if (used >= CODE_LOOKUPS_PER_DAY) return false;
    tx.set(ref, { lookups: { day: today, n: used + 1 } }, { merge: true });
    return true;
  });
  if (!allowed) fail("resource-exhausted", "tooMany", "Too many tries today.");
}

async function circleSize(tx: Transaction, uid: string): Promise<number> {
  return (await tx.get(paths.friends(uid))).size;
}

/**
 * Makes `a` and `b` friends if `b` asked `a` (or they asked each other). Both circles must have room
 * and neither may have blocked the other. Clears the requests either way.
 */
async function acceptFriendship(a: string, b: string): Promise<void> {
  await db.runTransaction(async (tx) => {
    const [incoming, already, blockedByA, blockedByB, userA, userB] = await Promise.all([
      tx.get(paths.request(a, b)),
      tx.get(paths.friend(a, b)),
      tx.get(paths.block(a, b)),
      tx.get(paths.block(b, a)),
      tx.get(paths.user(a)),
      tx.get(paths.user(b)),
    ]);
    if (already.exists) {
      tx.delete(paths.request(a, b));
      tx.delete(paths.request(b, a));
      return;
    }
    if (!incoming.exists) fail("not-found", "noRequest", "That request is gone.");
    if (blockedByA.exists || blockedByB.exists) fail("not-found", "noRequest", "That request is gone.");
    const [sizeA, sizeB] = await Promise.all([circleSize(tx, a), circleSize(tx, b)]);
    if (sizeA >= CIRCLE_MAX) fail("resource-exhausted", "youFull", "Your circle is full.");
    if (sizeB >= CIRCLE_MAX) fail("resource-exhausted", "theyFull", "Their circle is full.");

    const since = FieldValue.serverTimestamp();
    tx.set(paths.friend(a, b), { ...profileOf(userB.data()), since, muted: false });
    tx.set(paths.friend(b, a), { ...profileOf(userA.data()), since, muted: false });
    tx.delete(paths.request(a, b));
    tx.delete(paths.request(b, a));
  });
}

/** Asks the owner of `code` to join circles. If they already asked you, you're friends straight away. */
export const sendRequest = onCall(callable, async (request) => {
  const uid = requireSocial(request);
  const raw = request.data?.code;
  const code = typeof raw === "string" ? raw.toUpperCase().replace(/[^A-Z]/g, "") : "";
  if (code.length !== 6) fail("invalid-argument", "invalidCode", "A code has six letters.");
  await takeLookup(uid);

  const target = (await paths.code(code).get()).get("uid") as string | undefined;
  if (!target) fail("not-found", "notFound", "No circle has that code.");
  if (target === uid) fail("invalid-argument", "ownCode", "That's your own code.");

  const [blockedByThem, blockedByYou, friends, theyAsked, me] = await Promise.all([
    paths.block(target, uid).get(),
    paths.block(uid, target).get(),
    paths.friend(uid, target).get(),
    paths.request(uid, target).get(),
    paths.user(uid).get(),
  ]);
  // Looks the same as a wrong code, so a block is never revealed.
  if (blockedByThem.exists) fail("not-found", "notFound", "No circle has that code.");
  if (blockedByYou.exists) fail("failed-precondition", "youBlocked", "You blocked this person.");
  if (friends.exists) return { status: "friends" };

  const nickname = profileOf(me.data()).nickname;
  if (theyAsked.exists) {
    await acceptFriendship(uid, target);
    await trySendPush(target, { title: "circle", body: `${nickname} joined your circle.`, data: { type: "friend", uid } });
    return { status: "friends" };
  }

  const [mine, theirs] = await Promise.all([paths.friends(uid).count().get(), paths.friends(target).count().get()]);
  if (mine.data().count >= CIRCLE_MAX) fail("resource-exhausted", "youFull", "Your circle is full.");
  if (theirs.data().count >= CIRCLE_MAX) fail("resource-exhausted", "theyFull", "Their circle is full.");

  const pending = paths.request(target, uid);
  if ((await pending.get()).exists) return { status: "sent" };
  await pending.set({ fromUid: uid, nickname, createdAt: FieldValue.serverTimestamp(), expireAt: daysFromNow(REQUEST_DAYS) });
  await trySendPush(target, { title: "circle", body: `${nickname} wants to join your circle.`, data: { type: "request", uid } });
  return { status: "sent" };
});

/** Accepts or declines a request someone sent you. */
export const respondRequest = onCall(callable, async (request) => {
  const uid = requireSocial(request);
  const from = requireUid(request.data?.from, "from");
  if (request.data?.accept !== true) {
    await paths.request(uid, from).delete();
    return { status: "declined" };
  }
  await acceptFriendship(uid, from);
  const nickname = profileOf((await paths.user(uid).get()).data()).nickname;
  await trySendPush(from, { title: "circle", body: `${nickname} added you to their circle.`, data: { type: "friend", uid } });
  return { status: "friends" };
});

/** Removes everything `a` and `b` shared: both friend rows, each other's feed items and reactions. */
export async function unfriend(a: string, b: string): Promise<void> {
  const batch = db.batch();
  batch.delete(paths.friend(a, b));
  batch.delete(paths.friend(b, a));
  await batch.commit();

  const [feedA, feedB, postsA, postsB] = await Promise.all([
    paths.feed(a).where("ownerUid", "==", b).select().get(),
    paths.feed(b).where("ownerUid", "==", a).select().get(),
    paths.posts(a).select().get(),
    paths.posts(b).select().get(),
  ]);
  const writer = db.bulkWriter();
  for (const doc of [...feedA.docs, ...feedB.docs]) void writer.delete(doc.ref);
  for (const post of postsA.docs) void writer.delete(post.ref.collection("reactions").doc(b));
  for (const post of postsB.docs) void writer.delete(post.ref.collection("reactions").doc(a));
  await writer.close();
}

export const removeFriend = onCall(callable, async (request) => {
  const uid = requireSocial(request);
  const other = requireUid(request.data?.uid);
  await unfriend(uid, other);
  return { status: "removed" };
});

/** Unfriends, drops requests both ways and stops them finding you again. Unblocking is a client-side delete. */
export const blockUser = onCall(callable, async (request) => {
  const uid = requireSocial(request);
  const other = requireUid(request.data?.uid);
  if (other === uid) fail("invalid-argument", "self", "You can't block yourself.");
  await unfriend(uid, other);
  const batch = db.batch();
  batch.delete(paths.request(uid, other));
  batch.delete(paths.request(other, uid));
  batch.set(paths.block(uid, other), { createdAt: FieldValue.serverTimestamp() });
  await batch.commit();
  return { status: "blocked" };
});
