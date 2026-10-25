# tinyBRAVE

A three-minute-a-day iOS app that helps middle school students practice social-emotional learning, one small brave thing at a time.

[ADD SCREENSHOT HERE]

## What it does

Each day, tinyBRAVE gives you one small real-world challenge. When you finish it, you tap "I did it" and your balloon grows a little. Then you can keep a private reflection by drawing a picture or recording a short voice note. Reflections are optional and stay on your phone.

You can make a private Brave Circle with friends. Friends in your circle can see your streak and the challenges you finished, and they can send you balloon pings. They can never see your drawings or recordings.

The Track section keeps all your reflections and can play them back as a reel. After you finish 30 challenges, a finale screen invites you to watch your reflection reel.

## Features

- **One challenge a day.** 60 challenges in four categories: speak, connect, try, and reset. They come in rounds of 30.
- **Growing balloon.** The Brave-o-Meter balloon grows each time you finish a challenge, up to 30.
- **Skip a challenge.** If a challenge isn't right for you today, you can ask for a different one.
- **Private reflections.** Draw how it felt, or record a short voice note. The microphone only turns on when you tap record.
- **Track progress.** See your streak, your finished challenges, and your saved drawings and recordings.
- **Reflection reel.** Play back your reflections from the round, oldest first, from the Track section. When you finish all 30, a finale screen lets you watch the reel or start a new round.
- **Brave Circles.** Add up to six friends with a code. Friends see each other's progress and streaks, and can send balloon pings and reactions. Drawings and recordings are never shared. You can remove or block a friend, or delete your circle data.
- **Age check for Circles.** Circles ask for your age first. Students under 13 need a grown-up's OK before they can use Circles. Everything else in the app works without Circles.

[ADD SCREENSHOT HERE]

### About the backend

tinyBRAVE does not have a live backend or database right now. Progress and reflections are saved only on the phone, using SwiftData.

The code for a future Circles backend (Firebase) is in this repo. See [BACKEND.md](BACKEND.md), [firestore.rules](firestore.rules), and the [functions/](functions/) folder. It is not deployed. When you run a Debug build in the simulator without a Firebase config file, Circles use a pretend server that runs inside the app, so you can try them out.

## Requirements

- A Mac with Xcode. Your Xcode needs the iOS 26 SDK, because the app's minimum iOS version is **iOS 26.0**.
- An iPhone simulator running iOS 26.0 or later. The app is made for iPhone.
- Swift 5.9 (set in the project).
- An internet connection the first time you open the project, so Xcode can download the [Firebase iOS SDK](https://github.com/firebase/firebase-ios-sdk) (version 13.0.1 or later) with Swift Package Manager.

You do **not** need a Firebase account, an Apple Developer account, or a `GoogleService-Info.plist` file to run the app in the simulator.

## How to run it

1. Clone the repo:

   ```sh
   git clone https://github.com/D-Byun/tiny-brave.git
   cd tiny-brave
   ```

2. Open the project in Xcode:

   ```sh
   open TinyBrave.xcodeproj
   ```

3. Wait for Xcode to finish loading the Swift packages. You can see the progress at the top of the Xcode window.
4. At the top of Xcode, pick the **TinyBrave** scheme and an iPhone simulator.
5. Press **Cmd + R** to build and run.

To run the tests, press **Cmd + U**. The `FirestoreEmulatorTests` skip themselves unless the Firebase emulators are running. [BACKEND.md](BACKEND.md) explains how to run them.

The project file is generated from [project.yml](project.yml) with [XcodeGen](https://github.com/yonaskolb/XcodeGen). You only need XcodeGen if you change `project.yml`.

## Demo

[ADD VIDEO LINK HERE]

## Future improvements

- A live cloud backend and database, so progress and reflections are saved across devices.
- Adding and inviting real friends through the live backend.
- Balloon pings sent to friends' phones when a friend finishes a challenge.
- A way to nudge a friend who has been quiet for a while.

## AI use

I used AI tools while building tinyBRAVE. Claude and Claude Code helped implement my mockups in code and set up the iOS simulator. I designed the features and the UI, tested the app in the simulator, and decided what to keep.

## License

tinyBRAVE is released under the MIT License. See the [LICENSE](LICENSE) file.
