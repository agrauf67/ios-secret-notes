import Foundation

enum SortOrder: String, CaseIterable {
    case byName = "BY_NAME"
    case byRating = "BY_RATING"
    case byDate = "BY_DATE"

    var displayName: String {
        switch self {
        case .byName: "Name"
        case .byRating: "Rating"
        case .byDate: "Date"
        }
    }
}

enum SortDirection: String, CaseIterable {
    case ascending = "ASCENDING"
    case descending = "DESCENDING"

    var displayName: String {
        switch self {
        case .ascending: "Ascending"
        case .descending: "Descending"
        }
    }
}
