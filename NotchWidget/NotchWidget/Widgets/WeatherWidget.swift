import SwiftUI

struct WeatherWidget: View {
    @State private var data = WeatherData.mock

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Text(data.emoji)
                    .font(.system(size: 32))
                    .shadow(color: .yellow.opacity(0.25), radius: 6)

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(data.temperature)°")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white.opacity(0.93))

                    Text("\(data.condition) · \(data.city)")
                        .font(.system(size: 9.5))
                        .foregroundStyle(.white.opacity(0.38))
                }
            }

            HStack(spacing: 1.5) {
                ForEach(data.forecast) { day in
                    VStack(spacing: 2) {
                        Text(day.initial)
                            .font(.system(size: 8.5))
                            .foregroundStyle(.white.opacity(0.26))
                        Text(day.emoji)
                            .font(.system(size: 9))
                        Text("\(day.temp)°")
                            .font(.system(size: 8.5))
                            .foregroundStyle(.white.opacity(0.42))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

struct WeatherData {
    let emoji: String
    let temperature: Int
    let condition: String
    let city: String
    var forecast: [ForecastDay]

    struct ForecastDay: Identifiable {
        let id = UUID()
        let initial: String
        let emoji: String
        let temp: Int
    }

    static let mock = WeatherData(
        emoji: "☀️", temperature: 22, condition: "Clear", city: "SF",
        forecast: [
            ForecastDay(initial: "S", emoji: "☀️",  temp: 22),
            ForecastDay(initial: "M", emoji: "⛅",  temp: 19),
            ForecastDay(initial: "T", emoji: "🌧️", temp: 17),
            ForecastDay(initial: "W", emoji: "☀️",  temp: 24),
            ForecastDay(initial: "T", emoji: "⛅",  temp: 21),
        ]
    )
}
