import SwiftUI
import WidgetKit

private let groupId = "group.com.aykitap.aykitap"

struct ReadingEntry: TimelineEntry {
  let date: Date
  let bookId: Int
  let title: String
  let page: Int
  let total: Int
  let streak: Int
  let bestStreak: Int
  let todayPages: Int
  let todayWeekday: Int
  let weekRead: [Bool]
  let coverPath: String?
}

struct ReadingProvider: TimelineProvider {
  func placeholder(in context: Context) -> ReadingEntry {
    ReadingEntry(
      date: .now, bookId: 1, title: "The Little Prince", page: 82,
      total: 240, streak: 4, bestStreak: 12, todayPages: 18,
      todayWeekday: 5, weekRead: [true, true, false, true, false, false, false],
      coverPath: nil)
  }

  func getSnapshot(in context: Context, completion: @escaping (ReadingEntry) -> Void) {
    completion(entry())
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<ReadingEntry>) -> Void) {
    completion(Timeline(entries: [entry()], policy: .never))
  }

  private func entry() -> ReadingEntry {
    let defaults = UserDefaults(suiteName: groupId)
    let hasBook = defaults?.object(forKey: "book_id") != nil
    let week = defaults?.string(forKey: "week_read") ?? "0000000"
    return ReadingEntry(
      date: .now,
      bookId: hasBook ? defaults?.integer(forKey: "book_id") ?? -1 : -1,
      title: defaults?.string(forKey: "book_title") ?? "Start your reading journey",
      page: (defaults?.integer(forKey: "book_page") ?? 0) + 1,
      total: defaults?.integer(forKey: "book_page_count") ?? 0,
      streak: defaults?.integer(forKey: "streak") ?? 0,
      bestStreak: defaults?.integer(forKey: "best_streak") ?? 0,
      todayPages: defaults?.integer(forKey: "today_pages") ?? 0,
      todayWeekday: defaults?.integer(forKey: "today_weekday") ?? 1,
      weekRead: Array(week).prefix(7).map { $0 == "1" },
      coverPath: defaults?.string(forKey: "book_cover"))
  }
}

private extension View {
  func gilroy(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
    font(.custom("Gilroy-Regular", size: size).weight(weight))
  }
}

struct LastBookWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: ReadingEntry

  private var progress: Double {
    guard entry.total > 0 else { return 0 }
    return min(max(Double(entry.page) / Double(entry.total), 0), 1)
  }

  private var cover: UIImage? {
    guard let path = entry.coverPath else { return nil }
    return UIImage(contentsOfFile: path)
  }

  var body: some View {
    Link(destination: URL(string: entry.bookId >= 0 ? "aykitap://reader/\(entry.bookId)" : "aykitap://")!) {
      HStack(spacing: 13) {
        coverView
        VStack(alignment: .leading, spacing: 6) {
          Text("CONTINUE READING").gilroy(10, weight: .bold).foregroundStyle(.pink)
          Text(entry.title).gilroy(18, weight: .bold).lineLimit(2)
          Text(entry.total > 0 ? "Page \(entry.page) of \(entry.total)" : "Choose your next book")
            .gilroy(11).foregroundStyle(.secondary).lineLimit(1)
          GeometryReader { proxy in
            ZStack(alignment: .leading) {
              Capsule().fill(.purple.opacity(0.12))
              LinearGradient(colors: [.orange, .pink, .purple], startPoint: .leading, endPoint: .trailing)
                .frame(width: proxy.size.width * progress).clipShape(Capsule())
            }
          }.frame(height: 6)
          Text("Tap to continue  →").gilroy(11, weight: .bold).foregroundStyle(.purple)
        }
      }
      .padding(13)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .aykitapBackground()
  }

  @ViewBuilder private var coverView: some View {
    if let cover {
      Image(uiImage: cover).resizable().scaledToFill()
        .frame(width: family == .systemSmall ? 62 : 84)
        .frame(maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    } else {
      LinearGradient(colors: [.orange, .pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        .frame(width: family == .systemSmall ? 62 : 84)
        .frame(maxHeight: .infinity)
        .overlay(alignment: .bottom) {
          Text("AÝ\nKITAP").gilroy(11, weight: .bold).foregroundStyle(.white).padding(10)
        }
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
    }
  }
}

struct StreakWidgetView: View {
  let entry: ReadingEntry
  private let letters = ["M", "T", "W", "T", "F", "S", "S"]

  var body: some View {
    Link(destination: URL(string: "aykitap://streak")!) {
      VStack(spacing: 10) {
        HStack(spacing: 11) {
          Text("🔥")
            .font(.system(size: 30))
            .frame(width: 49, height: 49)
            .background(
              LinearGradient(colors: [.orange.opacity(0.24), .pink.opacity(0.19), .purple.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing),
              in: Circle())
            .shadow(color: .pink.opacity(0.34), radius: 8, y: 3)
          VStack(alignment: .leading, spacing: 2) {
            Text("\(entry.streak) day streak").gilroy(19, weight: .bold)
            Text("Best: \(entry.bestStreak) days").gilroy(11).foregroundStyle(.secondary)
          }
          Spacer()
          VStack(spacing: 1) {
            Text("\(entry.todayPages)").gilroy(17, weight: .bold)
            Text("pages today").gilroy(9, weight: .bold)
          }
          .foregroundStyle(.purple)
          .padding(.horizontal, 11).padding(.vertical, 7)
          .background(.white.opacity(0.68), in: Capsule())
        }

        HStack(spacing: 0) {
          ForEach(0..<7, id: \.self) { index in
            let met = entry.weekRead.indices.contains(index) && entry.weekRead[index]
            let today = index + 1 == entry.todayWeekday
            VStack(spacing: 4) {
              ZStack {
                Circle()
                  .fill(.white.opacity(0.7))
                if met {
                  Circle().fill(
                    LinearGradient(
                      colors: [.orange, .pink, .purple],
                      startPoint: .topLeading,
                      endPoint: .bottomTrailing))
                }
                if today && !met { Circle().stroke(.purple, lineWidth: 2) }
                if met { Text("🔥").font(.system(size: 16)) }
                else if today { Circle().fill(.purple.opacity(0.45)).frame(width: 8, height: 8) }
              }
              .frame(width: 31, height: 31)
              Text(letters[index]).gilroy(9, weight: today ? .bold : .regular)
                .foregroundStyle(today ? Color.purple : Color.secondary)
            }
            .frame(maxWidth: .infinity)
          }
        }
        .padding(.vertical, 6)
        .background(.white.opacity(0.55), in: RoundedRectangle(cornerRadius: 15, style: .continuous))
      }
      .padding(14)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .aykitapBackground()
  }
}

struct AykitapLastBookWidget: Widget {
  let kind = "AykitapLastBookWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ReadingProvider()) { LastBookWidgetView(entry: $0) }
      .configurationDisplayName("Aýkitap · Continue Reading")
      .description("Resume your last book from its cover.")
      .supportedFamilies([.systemMedium, .systemLarge])
  }
}

struct AykitapStreakWidget: Widget {
  let kind = "AykitapStreakWidget"
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: ReadingProvider()) { StreakWidgetView(entry: $0) }
      .configurationDisplayName("Aýkitap · Reading Streak")
      .description("Your seven-day reading streak and today's pages.")
      .supportedFamilies([.systemMedium, .systemLarge])
  }
}

private extension View {
  @ViewBuilder func aykitapBackground() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(
        LinearGradient(
          colors: [Color.orange.opacity(0.14), Color.pink.opacity(0.12), Color.purple.opacity(0.13)],
          startPoint: .topLeading, endPoint: .bottomTrailing),
        for: .widget)
    } else {
      background(Color(.systemBackground))
    }
  }
}
