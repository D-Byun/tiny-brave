import DeclaredAgeRange
import SwiftUI

struct CircleSheet: View {
    @ObservedObject var service: CircleService
    var onClose: () -> Void

    private enum Tab { case feed, circle }

    @Environment(\.palette) private var palette
    @Environment(\.requestAgeRange) private var requestAgeRange
    @State private var tab: Tab?
    @State private var addCode = ""
    @State private var nickname = ""
    @State private var status = ""
    @State private var busy = false
    @State private var birthMonth: Int?
    @State private var birthYear: Int?
    @State private var askedApple = false
    @State private var confirming: Confirmation?
    @FocusState private var nicknameFocused: Bool

    private enum Confirmation: Identifiable {
        case remove(CircleFriend), block(CircleFriend), deleteData
        var id: String {
            switch self {
            case .remove(let friend): "remove-\(friend.id)"
            case .block(let friend): "block-\(friend.id)"
            case .deleteData: "delete"
            }
        }
    }

    private var title: String {
        switch service.access {
        case .unavailable: "Not here yet"
        case .needsAge: "Brave, but together"
        case .needsConsent: "Ask a grown-up"
        case .ready: "Your circle"
        }
    }

    var body: some View {
        SheetScaffold(eyebrow: "Circle", title: title, onClose: onClose) {
            VStack(alignment: .leading, spacing: 0) {
                switch service.access {
                case .unavailable: unavailable
                case .needsAge: ageGate
                case .needsConsent: consent
                case .ready: ready
                }
                Text(status)
                    .font(Theme.body(11.5, weight: .heavy))
                    .foregroundStyle(Color(hex: 0x337D89))
                    .frame(minHeight: 21, alignment: .leading)
                    .padding(.top, 14)
                    .accessibilityIdentifier("circleStatus")
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 30)
        }
        .onAppear { nickname = service.nickname == CircleService.defaultNickname ? "" : service.nickname }
        .onDisappear { saveNickname() }
        .task { await service.start() }
        .confirmationDialog(confirmTitle, isPresented: Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } }), titleVisibility: .visible, presenting: confirming) { action in
            switch action {
            case .remove(let friend):
                Button("Remove \(friend.nickname)", role: .destructive) { run("removed.") { try await service.remove(friend) } }
            case .block(let friend):
                Button("Block \(friend.nickname)", role: .destructive) { run("blocked. they can't add you again.") { try await service.block(friend) } }
            case .deleteData:
                Button("Delete circle data", role: .destructive) { run("circle data deleted.") { try await service.deleteData() } }
            }
        } message: { action in
            switch action {
            case .remove: Text("You'll leave each other's circles. You can add each other again with a code.")
            case .block: Text("You'll leave each other's circles and they won't be able to send you requests.")
            case .deleteData: Text("Friends, requests, posts and reactions are deleted from the server. Your own braves stay on this phone.")
            }
        }
    }

    private var confirmTitle: String {
        switch confirming {
        case .remove(let friend): "Remove \(friend.nickname)?"
        case .block(let friend): "Block \(friend.nickname)?"
        case .deleteData, nil: "Delete circle data?"
        }
    }

    // MARK: Gates

    private var unavailable: some View {
        note("circles aren't switched on in this version yet. everything else works just the same.")
    }

    private var ageGate: some View {
        VStack(alignment: .leading, spacing: 0) {
            note("a circle is up to six friends cheering each other's balloons. they see your nickname, your count and which brave message you got. drawings and recordings never leave your phone.")
                .padding(.bottom, 20)
            label("WHEN WERE YOU BORN?")
            HStack(spacing: 8) {
                Menu {
                    ForEach(1...12, id: \.self) { month in
                        Button(Calendar.current.monthSymbols[month - 1]) { birthMonth = month }
                    }
                } label: { field(birthMonth.map { Calendar.current.monthSymbols[$0 - 1] } ?? "month") }
                    .accessibilityIdentifier("birthMonth")
                Menu {
                    let thisYear = Calendar.current.component(.year, from: .now)
                    ForEach((thisYear - 25)...(thisYear - 5), id: \.self) { year in
                        Button(String(year)) { birthYear = year }
                    }
                } label: { field(birthYear.map(String.init) ?? "year") }
                    .accessibilityIdentifier("birthYear")
            }
            Text("only your age group goes to the server. the date stays here.")
                .font(Theme.body(10.7, weight: .regular))
                .foregroundStyle(palette.muted)
                .padding(.top, 6)
                .padding(.bottom, 20)
            Button { submitBirthday() } label: { Text("continue") }
                .buttonStyle(BigButtonStyle())
                .disabled(busy || birthMonth == nil || birthYear == nil)
                .accessibilityIdentifier("ageContinue")
        }
        .task { await askApple() }
    }

    private var consent: some View {
        note("circles need a grown-up's ok for anyone under 13. until then your balloon, braves and streaks all work just the same. we'll switch circles on here once they've said yes.")
    }

    // MARK: Ready

    private var ready: some View {
        let shown = tab ?? (service.snapshot.friends.isEmpty ? .circle : .feed)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                tabButton("feed", selected: shown == .feed) { tab = .feed }
                    .accessibilityIdentifier("feedTab")
                tabButton("circle", selected: shown == .circle) { tab = .circle }
                    .accessibilityIdentifier("circleTab")
            }
            .padding(.bottom, 18)
            if shown == .feed { feed } else { circle }
        }
    }

    private func tabButton(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.body(14, weight: .heavy))
                .foregroundStyle(selected ? Color.white : palette.ink)
                .padding(.horizontal, 16)
                .frame(minHeight: 40)
                .background(Capsule().fill(selected ? palette.ink : palette.surface))
                .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 1.8))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: Feed

    @ViewBuilder
    private var feed: some View {
        if service.snapshot.feed.isEmpty {
            note(service.snapshot.friends.isEmpty
                 ? "no one here yet. share your code from the circle tab and your friends' braves show up here."
                 : "quiet for now. the balloons are listening.")
                .accessibilityIdentifier("feedEmpty")
        } else {
            VStack(spacing: 10) {
                ForEach(service.snapshot.feed) { item in feedRow(item) }
            }
        }
    }

    private func feedRow(_ item: FeedItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                avatar(item.mine ? service.nickname : item.nickname, index: colorIndex(for: item.ownerID))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.message == .allThirty
                         ? "\(item.mine ? "you" : item.nickname) filled the balloon!"
                         : "\(item.mine ? "you" : item.nickname) did a tiny brave.")
                        .font(Theme.font(13.5, relativeTo: .subheadline))
                    Text(item.message.text).font(Theme.body(10.5, weight: .regular)).foregroundStyle(palette.muted)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(item.stage)/\(BraveProgress.goal)").font(Theme.body(12, weight: .black))
                    Text(item.date, format: .relative(presentation: .named, unitsStyle: .abbreviated))
                        .font(Theme.body(9.5, weight: .regular))
                        .foregroundStyle(palette.muted)
                }
            }
            .accessibilityElement(children: .combine)
            reactions(item)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(palette.ink, lineWidth: 1.5))
    }

    /// Friends' posts get a tappable row of every reaction; your own just show what came in.
    @ViewBuilder
    private func reactions(_ item: FeedItem) -> some View {
        let tally = Dictionary(uniqueKeysWithValues: item.tally.map { ($0.reaction, $0.count) })
        if item.mine {
            if !tally.isEmpty {
                HStack(spacing: 6) {
                    ForEach(item.tally, id: \.reaction) { entry in chip(entry.reaction, count: entry.count, selected: false) }
                }
                .accessibilityElement(children: .combine)
            }
        } else {
            let picked = service.userID.flatMap(item.reaction(from:))
            HStack(spacing: 6) {
                ForEach(Reaction.allCases) { reaction in
                    Button {
                        run(nil) { try await service.react(reaction, to: item) }
                    } label: {
                        chip(reaction, count: tally[reaction] ?? 0, selected: picked == reaction)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("\(reaction.rawValue), \(tally[reaction] ?? 0)")
                    .accessibilityAddTraits(picked == reaction ? .isSelected : [])
                }
            }
        }
    }

    private func chip(_ reaction: Reaction, count: Int, selected: Bool) -> some View {
        HStack(spacing: 3) {
            Text(reaction.emoji).font(.system(size: 15))
            if count > 0 { Text("\(count)").font(Theme.body(10.5, weight: .black)) }
        }
        .padding(.horizontal, 8)
        .frame(minWidth: 40, minHeight: 32)
        .background(Capsule().fill(selected ? palette.sun : palette.surface))
        .overlay(Capsule().strokeBorder(selected ? palette.ink : palette.line, lineWidth: selected ? 1.8 : 1))
    }

    // MARK: Circle

    private var circle: some View {
        VStack(alignment: .leading, spacing: 0) {
            codeCard
            label("YOUR NICKNAME").padding(.top, 22)
            TextField("friend", text: $nickname)
                .autocorrectionDisabled()
                .font(Theme.body(16, weight: .black))
                .modifier(FieldBox(palette: palette))
                .focused($nicknameFocused)
                .submitLabel(.done)
                .onSubmit(saveNickname)
                .onChange(of: nicknameFocused) { _, focused in if !focused { saveNickname() } }
                .onChange(of: nickname) { _, new in
                    let cleaned = String(new.filter { $0.isLetter || $0.isNumber || $0 == " " }.prefix(CircleService.maxNicknameLength))
                    if cleaned != new { nickname = cleaned }
                }
                .accessibilityIdentifier("nickname")
            Text("a nickname, not your real name.")
                .font(Theme.body(10.7, weight: .regular))
                .foregroundStyle(palette.muted)
                .padding(.top, 6)

            label("ADD A FRIEND'S CODE").padding(.top, 22)
            HStack(spacing: 8) {
                TextField("ABCDEF", text: $addCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(Theme.body(16, weight: .black))
                    .tracking(2.2)
                    .modifier(FieldBox(palette: palette))
                    .onChange(of: addCode) { _, new in
                        let cleaned = String(new.uppercased().filter { $0.isLetter }.prefix(6))
                        if cleaned != new { addCode = cleaned }
                    }
                    .accessibilityIdentifier("addCode")
                Button { add() } label: {
                    Text("add")
                        .font(Theme.body(15, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(palette.ink))
                }
                .buttonStyle(.plain)
                .disabled(busy || service.isFull)
                .accessibilityIdentifier("addFriend")
            }

            if !service.snapshot.requests.isEmpty {
                Text("wants to join").font(Theme.body(14.7, weight: .black)).padding(.top, 26).padding(.bottom, 10)
                VStack(spacing: 8) {
                    ForEach(service.snapshot.requests) { request in requestRow(request) }
                }
            }

            HStack {
                Text("friends").font(Theme.body(14.7, weight: .black))
                Spacer()
                Text("\(service.snapshot.friends.count)/\(CircleLimits.maxFriends)")
                    .font(Theme.body(12, weight: .black))
                    .foregroundStyle(palette.muted)
                    .accessibilityIdentifier("friendCount")
            }
            .padding(.top, 26)
            .padding(.bottom, 10)
            if service.snapshot.friends.isEmpty {
                note("share your code. when a friend adds it, you'll both say yes and land in each other's circle.")
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(service.snapshot.friends.enumerated()), id: \.element.id) { index, friend in
                        friendRow(friend, index: index)
                    }
                }
            }

            HStack(spacing: 8) {
                Image(systemName: "lock.fill").font(.system(size: 11)).accessibilityHidden(true)
                Text("media stays yours alone").font(Theme.body(11.4, weight: .bold))
            }
            .foregroundStyle(palette.muted)
            .padding(.top, 24)

            Button { confirming = .deleteData } label: {
                Text("delete my circle data")
                    .font(Theme.body(11.5, weight: .heavy))
                    .underline()
                    .foregroundStyle(palette.muted)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            .accessibilityIdentifier("deleteCircleData")
        }
    }

    private var codeCard: some View {
        VStack(spacing: 0) {
            Text("YOUR CODE")
                .font(Theme.body(9.8, weight: .black))
                .tracking(1.3)
            Text(service.code ?? "······")
                .font(Theme.body(32, weight: .black))
                .tracking(5.8)
                .padding(.vertical, 8)
                .accessibilityIdentifier("circleCode")
            HStack(spacing: 8) {
                if let code = service.code {
                    ShareLink(item: "Add me on Tiny Brave with the code \(code)") { capsule("invite") }
                        .accessibilityIdentifier("inviteCircle")
                }
                Button { run("new code ready. the old one stops working.") { try await service.resetCode() } } label: { capsule("new code") }
                    .buttonStyle(.plain)
                    .disabled(busy)
                    .accessibilityIdentifier("resetCode")
            }
        }
        .frame(maxWidth: .infinity)
        .padding(19)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(palette.sun))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(palette.ink, lineWidth: 2))
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(palette.ink).offset(x: 4, y: 5))
        .task(id: service.code == nil) {
            if service.code == nil { try? await service.loadCode() }
        }
    }

    private func requestRow(_ request: CircleRequest) -> some View {
        HStack(spacing: 12) {
            avatar(request.nickname, index: colorIndex(for: request.id))
            Text(request.nickname).font(Theme.body(13.5, weight: .heavy))
            Spacer()
            Button { run("\(request.nickname) is in your circle.") { try await service.respond(to: request, accept: true) } } label: { capsule("yes") }
                .buttonStyle(.plain)
                .disabled(busy)
                .accessibilityLabel("Accept \(request.nickname)")
            Button { run(nil) { try await service.respond(to: request, accept: false) } } label: { capsule("no") }
                .buttonStyle(.plain)
                .disabled(busy)
                .accessibilityLabel("Decline \(request.nickname)")
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(palette.ink, lineWidth: 1.5))
    }

    private func friendRow(_ friend: CircleFriend, index: Int) -> some View {
        HStack(spacing: 12) {
            HStack(spacing: 12) {
                avatar(friend.nickname, index: index)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(friend.nickname).font(Theme.body(13.5, weight: .heavy))
                        if friend.muted {
                            Image(systemName: "bell.slash.fill").font(.system(size: 10)).foregroundStyle(palette.muted)
                                .accessibilityLabel("muted")
                        }
                    }
                    Text(friend.count > 0 ? "balloon in motion" : "warming up")
                        .font(Theme.body(10.5, weight: .regular))
                        .foregroundStyle(palette.muted)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(friend.count)/\(BraveProgress.goal)").font(Theme.body(13, weight: .black))
                    Text(DailyGoal.streakText(friend.streak)).font(Theme.body(10, weight: .regular)).foregroundStyle(palette.muted)
                }
            }
            .accessibilityElement(children: .combine)
            Menu {
                Button(friend.muted ? "Unmute" : "Mute", systemImage: friend.muted ? "bell" : "bell.slash") {
                    run(nil) { try await service.setMuted(!friend.muted, friend: friend) }
                }
                Button("Remove", systemImage: "person.badge.minus") { confirming = .remove(friend) }
                Button("Block", systemImage: "hand.raised", role: .destructive) { confirming = .block(friend) }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 32, height: 44)
            }
            .accessibilityLabel("Options for \(friend.nickname)")
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(palette.ink, lineWidth: 1.5))
    }

    // MARK: Pieces

    private func note(_ text: String) -> some View {
        Text(text)
            .font(Theme.body(13.4, weight: .regular))
            .foregroundStyle(palette.muted)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func label(_ text: String) -> some View {
        Text(text)
            .font(Theme.body(10.4, weight: .black))
            .tracking(0.8)
            .padding(.bottom, 7)
    }

    private func field(_ text: String) -> some View {
        Text(text)
            .font(Theme.body(16, weight: .black))
            .foregroundStyle(palette.ink)
            .frame(maxWidth: .infinity, alignment: .leading)
            .modifier(FieldBox(palette: palette))
    }

    private func capsule(_ text: String) -> some View {
        Text(text)
            .font(Theme.body(10.4, weight: .heavy))
            .foregroundStyle(palette.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(Capsule().fill(Color.white))
            .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 1.5))
    }

    private func avatar(_ name: String, index: Int) -> some View {
        let colors = [palette.blue, palette.pink, palette.green, palette.lavender, palette.sun]
        return Text(String(name.prefix(1)).uppercased())
            .font(Theme.font(16, relativeTo: .body))
            .frame(width: 38, height: 38)
            .background(Circle().fill(colors[index % colors.count]))
            .overlay(Circle().strokeBorder(palette.ink, lineWidth: 2))
            .accessibilityHidden(true)
    }

    private func colorIndex(for userID: String) -> Int {
        service.snapshot.friends.firstIndex(where: { $0.id == userID }) ?? CircleLimits.maxFriends
    }

    // MARK: Actions

    private func run(_ success: String?, _ action: @escaping () async throws -> Void) {
        guard !busy else { return }
        busy = true
        Task {
            do {
                try await action()
                if let success { status = success }
            } catch {
                status = (error as? CircleError)?.message ?? CircleError.unavailable.message
            }
            busy = false
        }
    }

    private func saveNickname() {
        service.setNickname(nickname)
    }

    private func add() {
        guard CircleService.normalize(addCode) != nil else {
            status = CircleError.invalidCode.message
            return
        }
        saveNickname()
        let code = addCode
        run(nil) {
            switch try await service.addFriend(code: code) {
            case .sent: status = "asked. once they say yes, you're in each other's circle."
            case .friends: status = "you're in each other's circle now."
            }
            addCode = ""
        }
    }

    private func submitBirthday() {
        guard let birthMonth, let birthYear else { return }
        setBand(AgeBand(birthMonth: birthMonth, year: birthYear))
    }

    private func setBand(_ band: AgeBand) {
        run(nil) { try await service.setAge(band) }
    }

    /// Asks Apple for an age range first; the birthday picker is the fallback if it can't say.
    private func askApple() async {
        guard !askedApple, !ProcessInfo.processInfo.arguments.contains("-localCircles") else { return }
        askedApple = true
        guard case .sharing(let range)? = try? await requestAgeRange(ageGates: 13, 16),
              let band = AgeBand(lowerBound: range.lowerBound, upperBound: range.upperBound) else { return }
        setBand(band)
    }
}

private struct FieldBox: ViewModifier {
    let palette: Palette

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 12)
            .frame(minHeight: 48)
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(palette.ink, lineWidth: 2))
    }
}

/// The banner that drops in from the top when a friend finishes a brave.
struct FriendPingBanner: View {
    let ping: CirclePing
    @Environment(\.palette) private var palette
    @State private var bounce = false

    var body: some View {
        HStack(spacing: 12) {
            Ellipse().fill(palette.sun)
                .overlay(Ellipse().strokeBorder(palette.ink, lineWidth: 2))
                .frame(width: 30, height: 36)
                .offset(y: bounce ? -5 : 0)
                .rotationEffect(.degrees(bounce ? 5 : 0))
                .onAppear { withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { bounce = true } }
            VStack(alignment: .leading, spacing: 2) {
                Text("\(ping.name) did a tiny brave.").font(Theme.font(13.8, relativeTo: .subheadline))
                Text(ping.message).font(Theme.body(10.4, weight: .regular)).foregroundStyle(palette.muted)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
        .background(roughRect().fill(palette.surface))
        .overlay(roughRect().strokeBorder(palette.ink, lineWidth: 2))
        .background(roughRect().fill(palette.ink).offset(x: 5, y: 6))
        .foregroundStyle(palette.ink)
        .rotationEffect(.degrees(-0.6))
        .padding(.horizontal, 14)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("friendPing")
    }
}
