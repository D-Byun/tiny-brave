import { getAuth } from "firebase-admin/auth";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import { callable, unfriend } from "./circle.js";
import { AGE_BANDS, db, paths, type AgeBand } from "./shared.js";

/** Deletes every trace of `uid` in circles: friendships, requests sent, code, profile, posts and feed. */
export async function wipeSocialData(uid: string, keepPrivate: boolean): Promise<void> {
  const friends = await paths.friends(uid).select().get();
  for (const friend of friends.docs) await unfriend(uid, friend.id);

  const sent = await db.collectionGroup("requests").where("fromUid", "==", uid).select().get();
  const priv = await paths.private(uid).get();
  const code = priv.get("code") as string | undefined;

  const writer = db.bulkWriter();
  for (const doc of sent.docs) void writer.delete(doc.ref);
  if (code) void writer.delete(paths.code(code));
  await writer.close();

  await db.recursiveDelete(paths.user(uid));
  if (keepPrivate) {
    await paths.private(uid).set({ code: null, lookups: null, pushes: null }, { merge: true });
  } else {
    await paths.private(uid).delete();
  }
}

async function setSocialClaim(uid: string, social: boolean): Promise<void> {
  const user = await getAuth().getUser(uid);
  await getAuth().setCustomUserClaims(uid, { ...(user.customClaims ?? {}), social });
}

/**
 * Records the age band the app read from Declared Age Range (or the age question) and turns circles
 * on or off. Under 13 sticks until a parent consents, so a child can't just answer again.
 * The app must refresh its ID token afterwards to pick up the claim.
 */
export const setAgeBand = onCall(callable, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  const uid = request.auth.uid;
  const band = request.data?.band as AgeBand;
  if (!AGE_BANDS.includes(band)) throw new HttpsError("invalid-argument", "Unknown age band.");

  const priv = (await paths.private(uid).get()).data() ?? {};
  const consented = priv.consent === "granted";
  const recorded: AgeBand = priv.ageBand === "under13" && !consented ? "under13" : band;
  const social = recorded !== "under13" || consented;

  await paths.private(uid).set({ ageBand: recorded, consent: priv.consent ?? (recorded === "under13" ? "needed" : null) }, { merge: true });
  if (!social && request.auth.token.social === true) await wipeSocialData(uid, true);
  await setSocialClaim(uid, social);
  return { band: recorded, social, consent: social ? null : "needed" };
});

/** In-app account deletion (App Store requirement and a COPPA parent right). Removes data, then the login. */
export const deleteAccount = onCall(callable, async (request) => {
  if (!request.auth) throw new HttpsError("unauthenticated", "Sign in first.");
  await wipeSocialData(request.auth.uid, false);
  await getAuth().deleteUser(request.auth.uid);
  return { status: "deleted" };
});
