import Foundation

struct SharedFormatters {
    private static var currencyFormatters: [String: NumberFormatter] = [:]
    private static let currencyFormattersQueue = DispatchQueue(label: "com.expendio.currencyFormatters")
    
    static func currencyFormatter(for currencyCode: String, maximumFractionDigits: Int? = nil) -> NumberFormatter {
        let key = maximumFractionDigits != nil ? "\(currencyCode)-\(maximumFractionDigits!)" : currencyCode
        return currencyFormattersQueue.sync {
            if let formatter = currencyFormatters[key] {
                return formatter
            }
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = currencyCode
            if let maxDigits = maximumFractionDigits {
                formatter.maximumFractionDigits = maxDigits
            }
            currencyFormatters[key] = formatter
            return formatter
        }
    }
    
    private static var dateFormatters: [String: DateFormatter] = [:]
    private static let dateFormattersQueue = DispatchQueue(label: "com.expendio.dateFormatters")
    
    static func dateFormatter(format: String) -> DateFormatter {
        return dateFormattersQueue.sync {
            if let formatter = dateFormatters[format] {
                return formatter
            }
            let formatter = DateFormatter()
            formatter.dateFormat = format
            dateFormatters[format] = formatter
            return formatter
        }
    }
    
    static let shortMonthSymbols: [String] = {
        let formatter = DateFormatter()
        return formatter.shortMonthSymbols ?? []
    }()
}
