import SwiftUI

struct VolumeWidget: View {
    let state: NotchState
    private let barCount = 12

    var body: some View {
        VStack(spacing: 9) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(Int(state.volume))%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white.opacity(0.90))
                    .monospacedDigit()
                Text("Volume")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.white.opacity(0.36))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .bottom, spacing: 3) {
                ForEach(0..<barCount, id: \.self) { i in
                    let threshold = Double(i + 1) / Double(barCount)
                    let active = threshold <= state.volume / 100
                    let h = 0.30 + (Double(i) / Double(barCount)) * 0.70

                    RoundedRectangle(cornerRadius: 2)
                        .fill(active ? Color.white.opacity(0.70) : Color.white.opacity(0.10))
                        .frame(height: 28 * h)
                        .animation(.easeInOut(duration: 0.2), value: active)
                }
            }
            .frame(height: 28)

            Slider(value: Binding(
                get: { state.volume },
                set: { state.volume = $0 }
            ), in: 0...100)
            .tint(.white.opacity(0.6))
            .frame(height: 3)
        }
    }
}
