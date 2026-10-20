import { deleteApp, initializeApp, type FirebaseApp } from "firebase/app";
import { connectAuthEmulator, getAuth, signInAnonymously } from "firebase/auth";
import {
  connectFirestoreEmulator,
  deleteDoc,
  doc,
  getDoc,
  getDocs,
  collection,
  getFirestore,
  serverTimestamp,
  setDoc,
  Timestamp,
  type Firestore,
} from "firebase/firestore";
import { connectFunctionsEmulator, getFunctions, httpsCallable, type Functions } from "firebase/functions";
import { afterAll, describe, expect, it } from "vitest";

const projectId = "demo-tinybrave";
const apps: FirebaseApp[] = [];
let n = 0;

interface Kid {
  uid: string;
  db: Firestore;
  call: <T = Record<string, unknown>>(name: string, data?: unknown) => Promise<T>;
  refresh: () => Promise<void>;
  app: FirebaseApp;
}

async function signIn(): Promise<Kid> {
  const app = initializeApp({ projectId, apiKey: "demo-key", appId: "1:1:web:1" }, `kid${n++}`);
  apps.push(app);
  const auth = getAuth(app);
  connectAuthEmulator(auth, "http://127.0.0.1:9099", { disableWarnings: true });
  const db = getFirestore(app);
  connectFirestoreEmulator(db, "127.0.0.1", 8080);
  const fns: Functions = getFunctions(app, "us-central1");
  connectFunctionsEmulator(fns, "127.0.0.1", 5001);
  const { user } = await signInAnonymously(auth);
  return {
    uid: user.uid,
    db,
    app,
    call: async (name, data) => (await httpsCallable(fns, name)(data ?? {})).data as never,
    refresh: async () => {
      await user.getIdToken(true);
    },
  };
}

/** A signed-in 13-to-15 year old with a profile. */
async function teen(nickname: string): Promise<Kid> {
  const kid = await signIn();
  const result = await kid.call<{ social: boolean }>("setAgeBand", { band: "13to15" });
  expect(result.social).toBe(true);
  await kid.refresh();
  await setDoc(doc(kid.db, `users/${kid.uid}`), { nickname, count: 1, streak: 1 });
  return kid;
}

async function befriend(a: Kid, b: Kid) {
  const { code } = await a.call<{ code: string }>("myCode");
  expect(await b.call("sendRequest", { code })).toEqual({ status: "sent" });
  expect(await a.call("respondRequest", { from: b.uid, accept: true })).toEqual({ status: "friends" });
}

async function eventually<T>(read: () => Promise<T>, ok: (value: T) => boolean, timeoutMs = 15_000): Promise<T> {
  const start = Date.now();
  let last = await read();
  while (!ok(last)) {
    if (Date.now() - start > timeoutMs) throw new Error(`Timed out; last value: ${JSON.stringify(last)}`);
    await new Promise((r) => setTimeout(r, 250));
    last = await read();
  }
  return last;
}

async function reason(promise: Promise<unknown>): Promise<string | undefined> {
  try {
    await promise;
    return undefined;
  } catch (error) {
    const details = (error as { details?: { reason?: string } }).details;
    return details?.reason ?? (error as { code?: string }).code;
  }
}

afterAll(async () => {
  await Promise.all(apps.map((app) => deleteApp(app)));
});

describe("age gate", () => {
  it("keeps under-13s out of circles until a parent consents, even if they answer again", async () => {
    const kid = await signIn();
    expect(await kid.call("setAgeBand", { band: "under13" })).toMatchObject({ social: false, consent: "needed" });
    await kid.refresh();
    expect(await reason(kid.call("myCode"))).toBe("functions/permission-denied");
    expect(await kid.call("setAgeBand", { band: "16plus" })).toMatchObject({ band: "under13", social: false });
  });
});

describe("circle", () => {
  it("adds a friend by code, both ways", async () => {
    const [mia, bo] = [await teen("Mia"), await teen("Bo")];
    const { code } = await mia.call<{ code: string }>("myCode");
    expect(code).toMatch(/^[A-Z]{6}$/);
    expect(await mia.call("myCode")).toEqual({ code });

    expect(await bo.call("sendRequest", { code: code.toLowerCase() })).toEqual({ status: "sent" });
    const request = await getDoc(doc(mia.db, `users/${mia.uid}/requests/${bo.uid}`));
    expect(request.data()).toMatchObject({ fromUid: bo.uid, nickname: "Bo" });

    expect(await mia.call("respondRequest", { from: bo.uid, accept: true })).toEqual({ status: "friends" });
    expect((await getDoc(doc(mia.db, `users/${mia.uid}/friends/${bo.uid}`))).data()).toMatchObject({ nickname: "Bo", count: 1 });
    expect((await getDoc(doc(bo.db, `users/${bo.uid}/friends/${mia.uid}`))).data()).toMatchObject({ nickname: "Mia" });
    expect((await getDoc(doc(mia.db, `users/${mia.uid}/requests/${bo.uid}`))).exists()).toBe(false);
  });

  it("explains bad codes", async () => {
    const mia = await teen("Mia");
    const { code } = await mia.call<{ code: string }>("myCode");
    expect(await reason(mia.call("sendRequest", { code }))).toBe("ownCode");
    expect(await reason(mia.call("sendRequest", { code: "abc" }))).toBe("invalidCode");
    const unused = code === "ZZZZZZ" ? "YYYYYY" : "ZZZZZZ";
    expect(await reason(mia.call("sendRequest", { code: unused }))).toBe("notFound");
  });

  it("becomes friends at once when both people asked", async () => {
    const [mia, bo] = [await teen("Mia"), await teen("Bo")];
    const miaCode = (await mia.call<{ code: string }>("myCode")).code;
    const boCode = (await bo.call<{ code: string }>("myCode")).code;
    expect(await bo.call("sendRequest", { code: miaCode })).toEqual({ status: "sent" });
    expect(await mia.call("sendRequest", { code: boCode })).toEqual({ status: "friends" });
    expect((await getDoc(doc(bo.db, `users/${bo.uid}/friends/${mia.uid}`))).exists()).toBe(true);
  });

  it("caps a circle at six friends", async () => {
    const hub = await teen("Hub");
    for (let i = 0; i < 6; i++) await befriend(hub, await teen(`Pal ${i}`));
    const late = await teen("Late");
    const { code } = await hub.call<{ code: string }>("myCode");
    expect(await reason(late.call("sendRequest", { code }))).toBe("theyFull");
  });

  it("declines quietly", async () => {
    const [mia, bo] = [await teen("Mia"), await teen("Bo")];
    const { code } = await mia.call<{ code: string }>("myCode");
    await bo.call("sendRequest", { code });
    expect(await mia.call("respondRequest", { from: bo.uid, accept: false })).toEqual({ status: "declined" });
    expect((await getDocs(collection(mia.db, `users/${mia.uid}/friends`))).empty).toBe(true);
  });
});

describe("feed", () => {
  it("fans out posts, mirrors reactions and syncs progress", async () => {
    const [mia, bo] = [await teen("Mia"), await teen("Bo")];
    await befriend(mia, bo);

    const postId = `p${Date.now()}`;
    await setDoc(doc(bo.db, `users/${bo.uid}/posts/${postId}`), {
      message: "courageLouder",
      stage: 2,
      createdAt: serverTimestamp(),
      expireAt: Timestamp.fromMillis(Date.now() + 30 * 86_400_000),
    });

    const miaItem = await eventually(() => getDoc(doc(mia.db, `users/${mia.uid}/feed/${postId}`)), (s) => s.exists());
    expect(miaItem.data()).toMatchObject({ ownerUid: bo.uid, nickname: "Bo", message: "courageLouder", stage: 2, mine: false });
    const boItem = await eventually(() => getDoc(doc(bo.db, `users/${bo.uid}/feed/${postId}`)), (s) => s.exists());
    expect(boItem.get("mine")).toBe(true);

    const reaction = doc(mia.db, `users/${bo.uid}/posts/${postId}/reactions/${mia.uid}`);
    await setDoc(reaction, { emoji: "balloon", expireAt: Timestamp.fromMillis(Date.now() + 30 * 86_400_000) });
    await eventually(() => getDoc(doc(bo.db, `users/${bo.uid}/feed/${postId}`)), (s) => s.get(`reactions.${mia.uid}`) === "balloon");
    await eventually(() => getDoc(doc(mia.db, `users/${mia.uid}/feed/${postId}`)), (s) => s.get(`reactions.${mia.uid}`) === "balloon");

    await deleteDoc(reaction);
    await eventually(() => getDoc(doc(bo.db, `users/${bo.uid}/feed/${postId}`)), (s) => s.get(`reactions.${mia.uid}`) === undefined);

    await setDoc(doc(bo.db, `users/${bo.uid}`), { nickname: "Bobo", count: 7, streak: 3 });
    await eventually(
      () => getDoc(doc(mia.db, `users/${mia.uid}/friends/${bo.uid}`)),
      (s) => s.get("count") === 7 && s.get("nickname") === "Bobo",
    );
  });
});

describe("safety", () => {
  it("blocking removes the friend, their feed items, and hides your code from them", async () => {
    const [mia, bo] = [await teen("Mia"), await teen("Bo")];
    await befriend(mia, bo);
    const postId = `p${Date.now()}`;
    await setDoc(doc(bo.db, `users/${bo.uid}/posts/${postId}`), {
      message: "tinyTask",
      stage: 1,
      createdAt: serverTimestamp(),
      expireAt: Timestamp.fromMillis(Date.now() + 30 * 86_400_000),
    });
    await eventually(() => getDoc(doc(mia.db, `users/${mia.uid}/feed/${postId}`)), (s) => s.exists());

    expect(await mia.call("blockUser", { uid: bo.uid })).toEqual({ status: "blocked" });
    expect((await getDoc(doc(mia.db, `users/${mia.uid}/friends/${bo.uid}`))).exists()).toBe(false);
    expect((await getDoc(doc(bo.db, `users/${bo.uid}/friends/${mia.uid}`))).exists()).toBe(false);
    expect((await getDoc(doc(mia.db, `users/${mia.uid}/feed/${postId}`))).exists()).toBe(false);

    const { code } = await mia.call<{ code: string }>("myCode");
    expect(await reason(bo.call("sendRequest", { code }))).toBe("notFound");
  });

  it("a new code retires the old one", async () => {
    const [mia, bo] = [await teen("Mia"), await teen("Bo")];
    const old = (await mia.call<{ code: string }>("myCode")).code;
    const next = (await mia.call<{ code: string }>("resetCode")).code;
    expect(next).not.toBe(old);
    expect(await reason(bo.call("sendRequest", { code: old }))).toBe("notFound");
  });

  it("deleting an account removes you from your friends' circles", async () => {
    const [mia, bo] = [await teen("Mia"), await teen("Bo")];
    await befriend(mia, bo);
    expect(await bo.call("deleteAccount")).toEqual({ status: "deleted" });
    expect((await getDoc(doc(mia.db, `users/${mia.uid}/friends/${bo.uid}`))).exists()).toBe(false);
  });
});
