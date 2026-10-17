import SwiftUI

struct CircleSheet: View {
    @ObservedObject var service: CircleService
    let count: Int
    let streak: Int
    var onClose: () -> Void

    @Environment(\.palette) private var palette
    @State private var joinCode = ""
    @State private var status = ""
    @State private var busy = false

    var body: some View {
        SheetScaffold(eyebrow: "Circle", title: service.state == nil ? "Brave, but together" : "Your circle", onClose: onClose) {
            VStack(alignment: .leading, spacing: 0) {
                if let state = service.state {
                    home(state)
                } else {
                    setup
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
    }

    private var setup: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("A circle is a few friends watching each other's balloons rise. They see counts, streaks and pings. Drawings and recordings never leave your phone.")
                .font(Theme.body(13.4, weight: .regular))
                .foregroundStyle(palette.muted)
                .lineSpacing(4)
                .padding(.bottom, 20)
            Button { create() } label: { Text("create circle") }
                .buttonStyle(BigButtonStyle())
                .disabled(busy)
                .accessibilityIdentifier("createCircle")
            HStack(spacing: 10) {
                Rectangle().fill(palette.line).frame(height: 1)
                Text("or").font(Theme.body(10.7, weight: .heavy)).foregroundStyle(Color(hex: 0x777269))
                Rectangle().fill(palette.line).frame(height: 1)
            }
            .padding(.top, 24)
            .padding(.bottom, 16)
            Text("JOIN WITH A CODE")
                .font(Theme.body(10.4, weight: .black))
                .tracking(0.8)
                .padding(.bottom, 7)
            HStack(spacing: 8) {
                TextField("ABCDEF", text: $joinCode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(Theme.body(16, weight: .black))
                    .tracking(2.2)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 48)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(palette.ink, lineWidth: 2))
                    .onChange(of: joinCode) { _, new in
                        let cleaned = String(new.uppercased().filter { $0.isLetter }.prefix(6))
                        if cleaned != new { joinCode = cleaned }
                    }
                    .accessibilityIdentifier("joinCode")
                Button { join() } label: {
                    Text("join")
                        .font(Theme.body(15, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .frame(minHeight: 48)
                        .background(RoundedRectangle(cornerRadius: 12).fill(palette.ink))
                }
                .buttonStyle(.plain)
                .disabled(busy)
                .accessibilityIdentifier("joinCircle")
            }
        }
    }

    private func home(_ state: CircleState) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(spacing: 0) {
                Text("CIRCLE CODE")
                    .font(Theme.body(9.8, weight: .black))
                    .tracking(1.3)
                Text(state.code)
                    .font(Theme.body(32, weight: .black))
                    .tracking(5.8)
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("circleCode")
                Button {
                    UIPasteboard.general.string = "Join my Tiny Brave circle with the code \(state.code)"
                    status = "invite copied."
                } label: {
                    Text("invite")
                        .font(Theme.body(10.4, weight: .heavy))
                        .padding(.horizontal, 14)
                        .frame(minHeight: 44)
                        .background(Capsule().fill(Color.white))
                        .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("inviteCircle")
            }
            .frame(maxWidth: .infinity)
            .padding(19)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(palette.sun))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(palette.ink, lineWidth: 2))
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(palette.ink).offset(x: 4, y: 5))

            HStack(spacing: 8) {
                Image(systemName: "lock.fill").font(.system(size: 11)).accessibilityHidden(true)
                Text("media stays yours alone").font(Theme.body(11.4, weight: .bold))
            }
            .foregroundStyle(palette.muted)
            .padding(.top, 21)
            .padding(.bottom, 11)

            VStack(spacing: 8) {
                ForEach(Array(state.members.enumerated()), id: \.element.id) { index, member in
                    memberRow(member, index: index)
                }
            }

            Text("pings").font(Theme.body(14.7, weight: .black)).padding(.top, 26).padding(.bottom, 10)
            if state.pings.isEmpty {
                Text("quiet for now. the balloons are listening.")
                    .font(Theme.body(12, weight: .regular))
                    .foregroundStyle(palette.muted)
                    .accessibilityIdentifier("pingsEmpty")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(state.pings) { ping in
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(ping.name) did a tiny brave.").font(Theme.font(13.5, relativeTo: .subheadline))
                            Text(ping.message).font(Theme.body(10.5, weight: .regular)).foregroundStyle(palette.muted)
                        }
                    }
                }
            }
        }
    }

    private func memberRow(_ member: CircleMember, index: Int) -> some View {
        let colors = [palette.blue, palette.pink, palette.green, palette.lavender, palette.sun]
        return HStack(spacing: 12) {
            Text(String(member.name.prefix(1)).uppercased())
                .font(Theme.font(16, relativeTo: .body))
                .frame(width: 38, height: 38)
                .background(Circle().fill(colors[index % colors.count]))
                .overlay(Circle().strokeBorder(palette.ink, lineWidth: 2))
            VStack(alignment: .leading, spacing: 2) {
                Text(member.name).font(Theme.body(13.5, weight: .heavy))
                Text(member.count > 0 ? "balloon in motion" : "warming up")
                    .font(Theme.body(10.5, weight: .regular))
                    .foregroundStyle(palette.muted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(member.count)/\(BraveProgress.goal)").font(Theme.body(13, weight: .black))
                Text(DailyGoal.streakText(member.streak)).font(Theme.body(10, weight: .regular)).foregroundStyle(palette.muted)
            }
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.white))
        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(palette.ink, lineWidth: 1.5))
        .accessibilityElement(children: .combine)
    }

    private func create() {
        busy = true
        status = "inflating a new circle…"
        Task {
            try? await Task.sleep(for: .milliseconds(500))
            service.create(count: count, streak: streak)
            status = "circle made. invite someone brave-ish."
            busy = false
        }
    }

    private func join() {
        guard CircleService.normalize(joinCode) != nil else {
            status = "that code needs six letters."
            return
        }
        busy = true
        status = "looking for that circle…"
        Task {
            try? await Task.sleep(for: .milliseconds(600))
            status = service.join(code: joinCode) ? "you're in. media stays yours alone." : "couldn't find that circle."
            busy = false
        }
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
