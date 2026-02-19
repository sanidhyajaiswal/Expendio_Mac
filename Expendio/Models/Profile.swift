import Foundation
import SwiftData

@Model
final class Profile {
    @Attribute(.unique) var id: UUID
    var name: String
    var colorHex: String
    
    init(name: String, colorHex: String = "#7C3AED") {
        self.id = UUID()
        self.name = name
        self.colorHex = colorHex
    }
}
