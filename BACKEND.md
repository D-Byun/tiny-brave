# Circles backend

Circles let up to six friends cheer each other's balloons. The app talks straight to Firebase and there is no server of our own:

| Piece | What it does |
| --- | --- |
| Firebase Auth (anonymous) | Gives each phone a private ID. No email or real name. |
| Firestore | Stores your profile, friends, requests, feed, posts and reactions. `firestore.rules` decides who can read and write what. |
| Cloud Functions (`functions/`) | Anything that touches two people: codes, requests, accepting, removing, blocking, the age gate, account deletion. It also copies each post into friends' feeds and sends pushes. |
| Cloud Messaging (FCM) | Push notifications. They are capped at 10 a day, muted per friend, and quiet from 9pm to 7am in the reader's time zone. |
| App Check | Only the real app (App Attest) can call the backend. |

Posts, feed entries, reactions and requests expire after 30 days (requests after 14) through Firestore TTL.

## Who can use circles

Everyone gets the solo app. Circles need an age first:

1. The app asks Apple's Declared Age Range for 13 / 16 gates. If that isn't available or the person declines, it asks for a birth month and year. Only the band (`under13`, `13to15`, `16plus`) is sent to the server.
2. `setAgeBand` sets a `social` custom claim for 13+. Rules and functions check that claim.
3. Under-13s stay at `consent: "needed"` and can't reach anything social. Changing the age afterwards doesn't lift the gate. Once verified parental consent exists (see *Later*), the server flips `consent` to `granted`.

"Delete my circle data" removes friends, requests, posts, reactions, codes and the Auth user. Solo progress stays on the phone.

## Running it locally

You need Node 24, Java 21+ and the Firebase CLI (`npm i -g firebase-tools`).

```sh
cd functions && npm install && npm test   # rules + functions tests against the emulators
```

To run the iOS tests, including the end-to-end tests against the real backend code, use:

```sh
(cd functions && npm run build)
firebase emulators:exec --project demo-tinybrave --only auth,firestore,functions \
  "xcodebuild test -project TinyBrave.xcodeproj -scheme TinyBrave -destination 'platform=iOS Simulator,name=iPhone 17 Pro'"
```

`FirestoreEmulatorTests` skip themselves when the emulators aren't running. To run the app itself against the emulators, start `firebase emulators:start --project demo-tinybrave --only auth,firestore,functions` and launch with `-firebaseEmulator`. Use `-localCircles` for a fully in-memory pretend server.

Debug builds without a `GoogleService-Info.plist` also fall back to the in-memory server. Release builds without one show "circles aren't switched on".

## Going live

Use the same Google account for both CLIs (`firebase login`, `gcloud auth login`).

1. **Billing account.** This is a one-time step in the browser at https://console.cloud.google.com/billing and needs a card. Cloud Functions needs the Blaze plan. At this app's size the free tiers cover most of it, typically $0–2 a month.
2. **Project and Firestore.**
   ```sh
   gcloud projects create tiny-brave-app --name="Tiny Brave"
   gcloud billing accounts list                       # note the ACCOUNT_ID
   gcloud billing projects link tiny-brave-app --billing-account=ACCOUNT_ID
   firebase projects:addfirebase tiny-brave-app
   gcloud firestore databases create --project=tiny-brave-app --location=us-central1
   ```
3. **Budget alert at $10.**
   ```sh
   gcloud billing budgets create --billing-account=ACCOUNT_ID --display-name="Tiny Brave" \
     --budget-amount=10USD --threshold-rule=percent=0.5 --threshold-rule=percent=0.9 --threshold-rule=percent=1.0
   ```
4. **Anonymous sign-in.** In the Firebase console, go to Authentication → Get started → Sign-in method → Anonymous → Enable.
5. **Deploy rules, indexes, TTL policies and functions.**
   ```sh
   firebase deploy --project tiny-brave-app --only firestore,functions
   ```
6. **Daily backups** (optional, a few cents a month):
   ```sh
   gcloud firestore backups schedules create --project=tiny-brave-app --database='(default)' --recurrence=daily --retention=7d
   ```
7. **Register the iOS app** and drop its config into the app target:
   ```sh
   firebase apps:create IOS "Tiny Brave" --bundle-id com.tinybrave.app --project tiny-brave-app
   firebase apps:sdkconfig IOS APP_ID --project tiny-brave-app -o TinyBrave/GoogleService-Info.plist
   xcodegen generate
   ```

## Steps that need the Apple Developer account

- **Signing.** Set `DEVELOPMENT_TEAM` in `project.yml`, then turn on Push Notifications, App Attest and Declared Age Range for `com.tinybrave.app`.
- **Push.** Create an APNs auth key at developer.apple.com → Keys. Upload it in Firebase console → Project settings → Cloud Messaging.
- **App Check.** In the Firebase console go to App Check → Apps, and register the iOS app with App Attest. For simulator runs, also add the debug token the app prints. Once real devices show verified requests:
  - set `APP_CHECK_ENFORCED=true` in `functions/.env` and deploy again;
  - turn on enforcement for Firestore in the console.
- **Release builds.** Change `com.apple.developer.devicecheck.appattest-environment` in `TinyBrave/TinyBrave.entitlements` to `production`.

## Later

- Verified parental consent for under-13s, for example with Epic's Kids Web Services (free). Its webhook sets `private/{uid}.consent = "granted"`, and the next `setAgeBand` call turns circles on.
- Sign in with Apple linking, so circles survive a new phone.
- An unblock list, and invites through Universal Links.
