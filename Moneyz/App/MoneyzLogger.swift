import Foundation
import OSLog

enum MoneyzLogger {
    static let subsystem = "com.houmam.Moneyz"

    static let bootstrap = Logger(subsystem: subsystem, category: "bootstrap")
    static let persistence = Logger(subsystem: subsystem, category: "persistence")
    static let recurring = Logger(subsystem: subsystem, category: "recurring")
    static let auth = Logger(subsystem: subsystem, category: "auth")
}
