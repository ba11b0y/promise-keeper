import Foundation

/// Converter to transform between app Promise model and WidgetPromise model
public struct PromiseConverter {
    
    /// Convert app Promise to WidgetPromise
    /// This is used when syncing data from the main app to the widget
    public static func toWidgetPromise(from appPromise: AppPromiseConvertible) -> WidgetPromise {
        WidgetPromise(
            id: appPromise.promiseId,
            created_at: appPromise.promiseCreatedAt,
            updated_at: appPromise.promiseUpdatedAt,
            content: appPromise.promiseContent,
            owner_id: appPromise.promiseOwnerId,
            resolved: appPromise.promiseResolved
        )
    }
    
    /// Convert array of app promises to widget promises
    public static func toWidgetPromises<T: AppPromiseConvertible>(from appPromises: [T]) -> [WidgetPromise] {
        appPromises.map { toWidgetPromise(from: $0) }
    }
}

/// Protocol that app's Promise model must conform to for conversion
/// This avoids circular dependencies between the shared framework and app
public protocol AppPromiseConvertible {
    var promiseId: String { get }
    var promiseCreatedAt: Date { get }
    var promiseUpdatedAt: Date { get }
    var promiseContent: String { get }
    var promiseOwnerId: String { get }
    var promiseResolved: Bool { get }
}