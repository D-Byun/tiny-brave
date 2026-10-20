import { FieldValue } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";
import { onDocumentCreated, onDocumentWritten } from "firebase-functions/v2/firestore";
import { trySendPush } from "./push.js";
import { FEED_DAYS, MESSAGES, REACTIONS, dayKey, daysFromNow, db, paths, profileOf } from "./shared.js";

const POSTS_PER_DAY = 40;

async function takePostAllowance(uid: string): Promise<boolean> {
  return db.runTransaction(async (tx) => {
    const ref = paths.private(uid);
    const posts = (await tx.get(ref)).get("posts") as { day?: string; n?: number } | undefined;
    const today = dayKey();
    const used = posts?.day === today ? (posts.n ?? 0) : 0;
    if (used >= POSTS_PER_DAY) return false;
    tx.set(ref, { posts: { day: today, n: used + 1 } }, { merge: true });
    return true;
  });
}

/** Copies a new post into the owner's feed and every friend's feed, then nudges the friends. */
export const onPostCreated = onDocumentCreated("users/{uid}/posts/{postId}", async (event) => {
  const { uid, postId } = event.params;
  const post = event.data?.data();
  if (!post || !(post.message in MESSAGES)) return;
  if (!(await takePostAllowance(uid))) {
    logger.warn("Post allowance used up; not fanned out", { uid });
    return;
  }

  const [user, friends] = await Promise.all([paths.user(uid).get(), paths.friends(uid).select().get()]);
  const nickname = profileOf(user.data()).nickname;
  const item = {
    ownerUid: uid,
    nickname,
    message: post.message,
    stage: post.stage,
    createdAt: post.createdAt ?? FieldValue.serverTimestamp(),
    expireAt: post.expireAt ?? daysFromNow(FEED_DAYS),
    reactions: {},
  };

  const batch = db.batch();
  batch.set(paths.feed(uid).doc(postId), { ...item, mine: true });
  for (const friend of friends.docs) batch.set(paths.feed(friend.id).doc(postId), { ...item, mine: false });
  await batch.commit();

  const full = post.message === "allThirty";
  const title = full ? `${nickname} filled their balloon!` : `${nickname} did a tiny brave.`;
  await Promise.all(
    friends.docs.map((friend) =>
      trySendPush(friend.id, { title, body: MESSAGES[post.message], data: { type: "post", postId, ownerUid: uid }, fromUid: uid }),
    ),
  );
});

/** Mirrors a reaction into every copy of the post, and tells the owner about new ones. */
export const onReactionWritten = onDocumentWritten("users/{owner}/posts/{postId}/reactions/{reactor}", async (event) => {
  const { owner, postId, reactor } = event.params;
  const before = event.data?.before.data();
  const after = event.data?.after.data();
  const emoji = typeof after?.emoji === "string" && after.emoji in REACTIONS ? after.emoji : null;

  const friends = await paths.friends(owner).get();
  const reactorRow = friends.docs.find((doc) => doc.id === reactor);
  if (emoji && !reactorRow) return;

  const value = emoji ?? FieldValue.delete();
  const recipients = [owner, ...friends.docs.map((doc) => doc.id)];
  // Friends who joined after the post don't have a copy; those updates fail harmlessly.
  await Promise.allSettled(recipients.map((uid) => paths.feed(uid).doc(postId).update({ [`reactions.${reactor}`]: value })));

  if (emoji && !before && reactorRow) {
    const nickname = profileOf(reactorRow.data()).nickname;
    await trySendPush(owner, {
      title: `${nickname} sent ${REACTIONS[emoji]}`,
      body: "for your tiny brave.",
      data: { type: "reaction", postId, uid: reactor },
      fromUid: reactor,
    });
  }
});

/** Keeps the copy of your nickname, count and streak in each friend's circle list up to date. */
export const onProfileWritten = onDocumentWritten("users/{uid}", async (event) => {
  const { uid } = event.params;
  const after = event.data?.after.data();
  if (!after) return;
  const next = profileOf(after);
  const before = event.data?.before.data();
  if (before) {
    const previous = profileOf(before);
    if (previous.nickname === next.nickname && previous.count === next.count && previous.streak === next.streak) return;
  }
  const friends = await paths.friends(uid).select().get();
  await Promise.allSettled(friends.docs.map((friend) => paths.friend(friend.id, uid).update({ ...next })));
});
