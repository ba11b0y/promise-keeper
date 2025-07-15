import WidgetKit
import SwiftUI
import Intents

// MARK: - Promise Widget Extension
struct PromiseWidgetExtension: Widget {
    let kind: String = "PromiseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PromiseProvider()) { entry in
            PromiseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Promise Keeper")
        .description("Keep track of your promises at a glance")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Timeline Provider
struct PromiseProvider: TimelineProvider {
    func placeholder(in context: Context) -> PromiseEntry {
        PromiseEntry(
            date: Date(),
            promises: [
                WidgetPromise(content: "Call mom this weekend", isRecent: true, isFromScreenshot: false),
                WidgetPromise(content: "Send the report by Friday", isRecent: false, isFromScreenshot: true)
            ],
            totalCount: 2,
            recentCount: 1
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PromiseEntry) -> ()) {
        let entry = PromiseEntry(
            date: Date(),
            promises: [
                WidgetPromise(content: "Review project proposal", isRecent: true, isFromScreenshot: false),
                WidgetPromise(content: "Schedule team meeting", isRecent: false, isFromScreenshot: true)
            ],
            totalCount: 2,
            recentCount: 1
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        Task {
            let entries = await fetchPromiseEntries()
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }
    
    private func fetchPromiseEntries() async -> [PromiseEntry] {
        // Load real data from shared storage (populated by main app)
        let promises = SharedDataManager.shared.loadPromises()
        let userInfo = SharedDataManager.shared.loadUserInfo()
        
        let currentDate = Date()
        let recentPromises = promises.filter { $0.isRecent }
        
        let entry = PromiseEntry(
            date: currentDate,
            promises: promises,
            totalCount: promises.count,
            recentCount: recentPromises.count
        )
        
        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
        let nextEntry = PromiseEntry(
            date: nextUpdate,
            promises: entry.promises,
            totalCount: entry.totalCount,
            recentCount: entry.recentCount
        )
        
        return [entry, nextEntry]
    }
}

// MARK: - Timeline Entry
struct PromiseEntry: TimelineEntry {
    let date: Date
    let promises: [WidgetPromise]
    let totalCount: Int
    let recentCount: Int
}

// MARK: - Widget Promise Model
struct WidgetPromise {
    let content: String
    let isRecent: Bool
    let isFromScreenshot: Bool
}

// MARK: - Widget Entry View
struct PromiseWidgetEntryView: View {
    var entry: PromiseProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallPromiseWidget(entry: entry)
        case .systemMedium:
            MediumPromiseWidget(entry: entry)
        case .systemLarge:
            LargePromiseWidget(entry: entry)
        default:
            SmallPromiseWidget(entry: entry)
        }
    }
}

// MARK: - Small Widget (Stats only)
struct SmallPromiseWidget: View {
    let entry: PromiseEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                Spacer()
                Text("Promises")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Main stats
            VStack(spacing: 4) {
                Text("\(entry.totalCount)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("total promises")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Recent indicator
            if entry.recentCount > 0 {
                HStack {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                    Text("\(entry.recentCount) new")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Medium Widget (Stats + Recent promises)
struct MediumPromiseWidget: View {
    let entry: PromiseEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Left side - Stats
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                    Text("Promises")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(entry.totalCount)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("total")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if entry.recentCount > 0 {
                    HStack {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 4, height: 4)
                        Text("\(entry.recentCount) new")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Spacer()
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: 80)
            
            // Right side - Recent promises
            VStack(alignment: .leading, spacing: 6) {
                Text("Recent")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                ForEach(Array(entry.promises.prefix(3).enumerated()), id: \.offset) { index, promise in
                    PromiseWidgetRow(promise: promise, isCompact: true)
                    
                    if index < min(2, entry.promises.count - 1) {
                        Divider()
                    }
                }
                
                if entry.promises.count > 3 {
                    Text("+ \(entry.promises.count - 3) more")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Large Widget (Full list)
struct LargePromiseWidget: View {
    let entry: PromiseEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                Text("Promise Keeper")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(entry.totalCount)")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("promises")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Promises list
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(entry.promises.prefix(6).enumerated()), id: \.offset) { index, promise in
                    PromiseWidgetRow(promise: promise, isCompact: false)
                    
                    if index < min(5, entry.promises.count - 1) {
                        Divider()
                    }
                }
                
                if entry.promises.count > 6 {
                    HStack {
                        Text("+ \(entry.promises.count - 6) more promises")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Open app to see all")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
    }
}

// MARK: - Promise Widget Row
struct PromiseWidgetRow: View {
    let promise: WidgetPromise
    let isCompact: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            // Promise content
            Text(promise.content)
                .font(isCompact ? .caption : .body)
                .lineLimit(isCompact ? 1 : 2)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Indicators
            HStack(spacing: 4) {
                if promise.isFromScreenshot {
                    Image(systemName: "camera.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
                
                if promise.isRecent {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                }
            }
        }
    }
}

// MARK: - Widget Preview
struct PromiseWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEntry = PromiseEntry(
            date: Date(),
            promises: [
                WidgetPromise(content: "Call mom this weekend", isRecent: true, isFromScreenshot: false),
                WidgetPromise(content: "Send the quarterly report by Friday", isRecent: false, isFromScreenshot: true),
                WidgetPromise(content: "Schedule dentist appointment", isRecent: true, isFromScreenshot: false),
                WidgetPromise(content: "Review code changes", isRecent: false, isFromScreenshot: true),
                WidgetPromise(content: "Plan weekend trip", isRecent: false, isFromScreenshot: false)
            ],
            totalCount: 8,
            recentCount: 3
        )
        
        Group {
            PromiseWidgetEntryView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small Widget")
            
            PromiseWidgetEntryView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium Widget")
            
            PromiseWidgetEntryView(entry: sampleEntry)
                .previewContext(WidgetPreviewContext(family: .systemLarge))
                .previewDisplayName("Large Widget")
        }
    }
}