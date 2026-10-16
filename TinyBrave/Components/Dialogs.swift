import SwiftUI

private struct ModalDialog<Dialog: View>: ViewModifier {
    @Binding var isPresented: Bool
    var dismissOnBackdrop: Bool
    @ViewBuilder var dialog: () -> Dialog

    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content.overlay {
            if isPresented {
                ZStack {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture { if dismissOnBackdrop { isPresented = false } }
                        .accessibilityHidden(true)
                    dialog()
                        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(palette.surface))
                        .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).strokeBorder(palette.ink, lineWidth: 2.5))
                        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(palette.ink).offset(x: 6, y: 7))
                        .padding(.horizontal, 24)
                        .foregroundStyle(palette.ink)
                        .transition(.scale(scale: 0.9).combined(with: .opacity))
                }
                .accessibilityAddTraits(.isModal)
                .transition(.opacity)
                .zIndex(10)
            }
        }
        .animation(.easeOut(duration: 0.22), value: isPresented)
    }
}

extension View {
    func modalDialog<Dialog: View>(isPresented: Binding<Bool>, dismissOnBackdrop: Bool = true, @ViewBuilder content: @escaping () -> Dialog) -> some View {
        modifier(ModalDialog(isPresented: isPresented, dismissOnBackdrop: dismissOnBackdrop, dialog: content))
    }

    /// A pill that slides up from the bottom, shows `message`, and clears itself after a few seconds.
    func toast(_ message: Binding<String?>) -> some View { modifier(ToastModifier(message: message)) }
}

private struct ToastModifier: ViewModifier {
    @Binding var message: String?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .bottom) {
                if let message {
                    Text(message)
                        .font(Theme.body(12.2, weight: .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Capsule().fill(Palette.standard.ink))
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .accessibilityIdentifier("toast")
                        .task(id: message) {
                            try? await Task.sleep(for: .seconds(2.4))
                            if !Task.isCancelled { withAnimation { self.message = nil } }
                        }
                }
            }
            .animation(.easeOut(duration: 0.25), value: message)
    }
}

/// A small balloon for dialog headers; `sad` squashes it flat.
struct MiniBalloon: View {
    @Environment(\.palette) private var palette
    var sad = false

    var body: some View {
        ZStack(alignment: .top) {
            Path { p in
                p.move(to: CGPoint(x: 34, y: 0))
                p.addQuadCurve(to: CGPoint(x: 31, y: 12), control: CGPoint(x: 38, y: 6))
            }
            .stroke(palette.ink, lineWidth: 2)
            .offset(y: 74)
            Ellipse().fill(palette.sun)
                .overlay(Ellipse().strokeBorder(palette.ink, lineWidth: 2))
                .frame(width: 68, height: 74)
        }
        .frame(width: 68, height: 86, alignment: .top)
        .scaleEffect(y: sad ? 0.58 : 1, anchor: .bottom)
        .accessibilityHidden(true)
    }
}
