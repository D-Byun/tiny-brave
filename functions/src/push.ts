import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions/v2";
import { db, dayKey, isQuietHour, paths, PUSHES_PER_DAY } from "./shared.js";

export interface Push {
  title: string;
  body: string;
  /** Lets the app route a tap; values must be strings. */
  data: Record<string, string>;
  /** When set, a recipient who muted this friend gets nothing. */
  fromUid?: string;
}

/** Takes one push from the recipient's daily allowance. False once it's used up. */
async function takeAllowance(uid: string): Promise<boolean> {
  return db.runTransaction(async (tx) => {
    const ref = paths.private(uid);
    const pushes = (await tx.get(ref)).get("pushes") as { day?: string; n?: number } | undefined;
    const today = dayKey();
    const used = pushes?.day === today ? (pushes.n ?? 0) : 0;
    if (used >= PUSHES_PER_DAY) return false;
    tx.set(ref, { pushes: { day: today, n: used + 1 } }, { merge: true });
    return true;
  });
}

/**
 * Sends a notification to every device the recipient registered, unless they muted the sender,
 * it's their quiet hours, or they hit today's cap. The feed still shows everything; pushes are a nudge.
 */
export async function sendPush(toUid: string, push: Push): Promise<void> {
  const [user, mute, devices] = await Promise.all([
    paths.user(toUid).get(),
    push.fromUid ? paths.friend(toUid, push.fromUid).get() : Promise.resolve(undefined),
    paths.devices(toUid).get(),
  ]);
  if (devices.empty) return;
  if (mute?.get("muted") === true) return;
  if (user.get("pushes") === false) return;
  if (isQuietHour(user.get("tz"))) return;
  if (!(await takeAllowance(toUid))) return;

  const tokens = devices.docs.map((d) => d.id);
  const result = await getMessaging().sendEachForMulticast({
    tokens,
    notification: { title: push.title, body: push.body },
    data: push.data,
    apns: { payload: { aps: { sound: "default", threadId: "circle" } } },
  });

  const stale = result.responses.flatMap((response, i) => {
    const code = response.error?.code;
    return code === "messaging/registration-token-not-registered" || code === "messaging/invalid-registration-token" ? [tokens[i]] : [];
  });
  await Promise.all(stale.map((token) => paths.devices(toUid).doc(token).delete()));
  if (result.failureCount > stale.length) logger.warn("Some pushes failed", { toUid, failures: result.failureCount });
}

/** Push failures must never fail the write that caused them. */
export async function trySendPush(toUid: string, push: Push): Promise<void> {
  try {
    await sendPush(toUid, push);
  } catch (error) {
    logger.warn("Push skipped", { toUid, error: String(error) });
  }
}
