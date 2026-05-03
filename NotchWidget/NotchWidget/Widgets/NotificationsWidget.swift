import SwiftUI

struct NotificationsWidget: View {
    let notifications: [MockNotification] = MockNotification.sample

    var body: some View {
        VStack(spacing: 7) {
            HStack {
                Text("Notifications")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.70))
                Spacer()
                Text("\(notifications.count) new")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.white.opacity(0.30))
            }

            ForEach(notifications) { n in
                HStack(alignment: .top, spacing: 7) {
                    Circle()
                        .fill(n.dotColor)
                        .frame(width: 5, height: 5)
                        .padding(.top, 3)

                    VStack(alignment: .leading, spacing: 0) {
                        Text(n.app)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.70))
                        Text(n.message)
                            .font(.system(size: 9.5))
                            .foregroundStyle(.white.opacity(0.40))
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }

                    Spacer()

                    Text(n.time)
                        .font(.system(size: 9))
                        .foregroundStyle(.white.opacity(0.24))
                }
            }
        }
    }
}

struct MockNotification: Identifiable {
    let id = UUID()
    let app: String
    let message: String
    let time: String
    let dotColor: Color

    static let sample = [
        MockNotification(app: "Messages", message: "Hey, are you free tonight?",
                         time: "2m",  dotColor: Color(hex: 0x30D158)),
        MockNotification(app: "Mail",     message: "Invoice #2041 from Acme Co.",
                         time: "8m",  dotColor: Color(hex: 0x0A84FF)),
        MockNotification(app: "Slack",    message: "#design: New Figma file shared",
                         time: "14m", dotColor: Color(red: 0.88, green: 0.12, blue: 0.35)),
    ]
}
